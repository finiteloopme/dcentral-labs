mod attestation;
mod raw_attestation;
mod tdx_ioctl;

use anyhow::Result;
use dashmap::DashMap;
use lazy_static::lazy_static;
use serde::{Deserialize, Serialize};
use shared::{
    AttestationRequest, AttestationResponse, CryptoUtils, EncryptedPayload,
    SalaryData, SalaryRequest, SalaryResponse, SalaryStatistics, LocationStats,
};
use std::{
    collections::HashMap,
    convert::Infallible,
    fs,
    net::SocketAddr,
    sync::Arc,
};
use tracing::{error, info, warn};
use uuid::Uuid;
use warp::{http::StatusCode, Filter, Rejection, Reply};
use attestation::{TdxAttestationService, parse_tdx_quote};
use raw_attestation::RawTdxAttestation;

lazy_static! {
    static ref SALARY_DATABASE: Arc<DashMap<String, Vec<SalaryData>>> = Arc::new(DashMap::new());
    static ref SESSION_KEYS: Arc<DashMap<String, Vec<u8>>> = Arc::new(DashMap::new());
    static ref ATTESTATION_SERVICE: TdxAttestationService = TdxAttestationService::new();
    static ref RAW_ATTESTATION: RawTdxAttestation = RawTdxAttestation::new().unwrap();
}



async fn handle_attestation(
    request: AttestationRequest,
) -> Result<warp::reply::WithHeader<warp::reply::Json>, Rejection> {
    info!("Received attestation request with nonce: {} bytes", request.nonce.len());
    
    let use_raw_attestation = std::env::var("USE_RAW_ATTESTATION").is_ok();
    
    if use_raw_attestation {
        info!("Using raw TDX attestation (building quote from ground)");
        return handle_raw_attestation_impl(request).await;
    }
    
    if !ATTESTATION_SERVICE.is_tdx_available() {
        warn!("TDX is not available - running in simulation mode");
    }
    
    let session_id = Uuid::new_v4().to_string();
    let session_key = CryptoUtils::derive_session_key(&request.nonce, session_id.as_bytes());
    
    SESSION_KEYS.insert(session_id.clone(), session_key.clone());
    
    let report = match ATTESTATION_SERVICE.get_tdx_report(&request.nonce) {
        Ok(r) => r,
        Err(e) => {
            error!("Failed to get TDX report: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    let quote = match ATTESTATION_SERVICE.get_td_quote(&report, &request.nonce) {
        Ok(q) => q,
        Err(e) => {
            error!("Failed to get TD quote: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    let eventlog = match ATTESTATION_SERVICE.get_ccel_eventlog() {
        Ok(e) => e,
        Err(e) => {
            error!("Failed to get event log: {}", e);
            vec![]
        }
    };
    
    let attestation_token = match ATTESTATION_SERVICE.get_google_attestation_token(&report).await {
        Ok(t) => t,
        Err(e) => {
            warn!("Failed to get Google attestation token: {}", e);
            ATTESTATION_SERVICE.generate_simulated_token(&report)
        }
    };
    
    let quote_info = match parse_tdx_quote(&quote) {
        Ok(info) => info,
        Err(e) => {
            error!("Failed to parse TDX quote: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    let certificates = vec![
        attestation_token.signature.clone(),
        base64::encode(serde_json::to_string(&attestation_token.header).unwrap()),
        base64::encode(serde_json::to_string(&attestation_token.payload).unwrap()),
    ];
    
    let response = AttestationResponse {
        quote,
        eventlog,
        mrenclave: quote_info.mrtd,
        mrsigner: quote_info.rtmr0,
        product_id: 1,
        svn: 1,
        attributes: 0x0000000000000007,
        certificate_chain: certificates,
    };
    
    info!("Generated attestation response for session: {}", session_id);
    info!("MRTD: {}", response.mrenclave);
    info!("RTMR0: {}", response.mrsigner);
    
    Ok(warp::reply::with_header(
        warp::reply::json(&response),
        "X-Session-Id",
        session_id,
    ))
}

async fn handle_raw_attestation_impl(
    request: AttestationRequest,
) -> Result<warp::reply::WithHeader<warp::reply::Json>, Rejection> {
    info!("Building TDX quote from ground up without cloud service");
    
    let session_id = Uuid::new_v4().to_string();
    let session_key = CryptoUtils::derive_session_key(&request.nonce, session_id.as_bytes());
    
    SESSION_KEYS.insert(session_id.clone(), session_key.clone());
    
    // Get TD Report using raw TDCALL
    let report = match RAW_ATTESTATION.tdcall_get_report(&request.nonce) {
        Ok(r) => r,
        Err(e) => {
            error!("Failed to get TD report via TDCALL: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    info!("Got TD Report with MAC: {}", hex::encode(&report.mac[..8]));
    
    // Build complete quote from scratch
    let quote = match RAW_ATTESTATION.build_quote(&report, &request.nonce) {
        Ok(q) => q,
        Err(e) => {
            error!("Failed to build TDX quote: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    info!("Built raw TDX quote: {} bytes", quote.len());
    
    // Get extended report with full TD context
    let extended = match RAW_ATTESTATION.generate_extended_report(&request.nonce) {
        Ok(e) => e,
        Err(e) => {
            error!("Failed to generate extended report: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    // Parse our self-built quote
    let quote_info = match parse_tdx_quote(&quote) {
        Ok(info) => info,
        Err(e) => {
            error!("Failed to parse self-built quote: {}", e);
            return Err(warp::reject::custom(AttestationError));
        }
    };
    
    // Generate event log from extended report
    let mut eventlog = Vec::new();
    eventlog.extend_from_slice(b"RAWATTEST");
    eventlog.extend_from_slice(&(extended.timestamp as u32).to_le_bytes());
    eventlog.extend_from_slice(&extended.platform_info.tdx_module_version);
    
    // Create self-signed certificate chain
    let certificates = vec![
        base64::encode("RAW_ATTESTATION_KEY"),
        base64::encode(serde_json::to_string(&extended.platform_info).unwrap()),
        base64::encode(&quote[quote.len()-100..]), // Last 100 bytes as "signature"
    ];
    
    let response = AttestationResponse {
        quote,
        eventlog,
        mrenclave: hex::encode(&extended.td_info.mrtd[..32]),
        mrsigner: hex::encode(&extended.td_info.rtmr[0][..32]),
        product_id: 1,
        svn: extended.platform_info.qe_svn,
        attributes: extended.td_info.attributes,
        certificate_chain: certificates,
    };
    
    info!("Raw attestation response generated for session: {}", session_id);
    info!("MRTD: {}", response.mrenclave);
    info!("TD Attributes: 0x{:016x}", response.attributes);
    info!("Platform: CPU {}/{}/{}, Microcode: 0x{:x}", 
        extended.platform_info.cpu_family,
        extended.platform_info.cpu_model,
        extended.platform_info.cpu_stepping,
        extended.platform_info.microcode_version
    );
    
    Ok(warp::reply::with_header(
        warp::reply::json(&response),
        "X-Session-Id",
        session_id,
    ))
}

async fn handle_salary_submission(
    request: SalaryRequest,
) -> Result<impl Reply, Rejection> {
    info!("Received salary submission for session: {}", request.session_id);
    
    let session_key = SESSION_KEYS.get(&request.session_id)
        .ok_or_else(|| {
            warn!("Invalid session ID: {}", request.session_id);
            warp::reject::custom(InvalidSession)
        })?;
    
    let decrypted_data = CryptoUtils::decrypt_data(&request.encrypted_data, &session_key)
        .map_err(|e| {
            error!("Failed to decrypt data: {}", e);
            warp::reject::custom(DecryptionError)
        })?;
    
    let salary_data: SalaryData = serde_json::from_slice(&decrypted_data)
        .map_err(|e| {
            error!("Failed to parse salary data: {}", e);
            warp::reject::custom(InvalidData)
        })?;
    
    info!("Processing salary data for role: {}", salary_data.role);
    
    SALARY_DATABASE
        .entry(salary_data.role.clone())
        .or_insert_with(Vec::new)
        .push(salary_data.clone());
    
    let statistics = calculate_statistics(&salary_data.role);
    
    let response = SalaryResponse {
        success: true,
        message: format!("Salary data processed successfully in TEE"),
        statistics,
    };
    
    Ok(warp::reply::json(&response))
}

fn calculate_statistics(role: &str) -> Option<SalaryStatistics> {
    SALARY_DATABASE.get(role).map(|entries| {
        let salaries: Vec<u64> = entries.iter().map(|e| e.salary).collect();
        let mut sorted_salaries = salaries.clone();
        sorted_salaries.sort();
        
        let average = salaries.iter().sum::<u64>() as f64 / salaries.len() as f64;
        let median = if salaries.len() % 2 == 0 {
            let mid = salaries.len() / 2;
            (sorted_salaries[mid - 1] + sorted_salaries[mid]) as f64 / 2.0
        } else {
            sorted_salaries[salaries.len() / 2] as f64
        };
        
        let mut location_map: HashMap<String, Vec<u64>> = HashMap::new();
        for entry in entries.iter() {
            location_map
                .entry(entry.location.clone())
                .or_insert_with(Vec::new)
                .push(entry.salary);
        }
        
        let location_breakdown: Vec<LocationStats> = location_map
            .into_iter()
            .map(|(location, salaries)| {
                let avg = salaries.iter().sum::<u64>() as f64 / salaries.len() as f64;
                LocationStats {
                    location,
                    average_salary: avg,
                    count: salaries.len(),
                }
            })
            .collect();
        
        SalaryStatistics {
            role: role.to_string(),
            average_salary: average,
            median_salary: median,
            min_salary: *sorted_salaries.first().unwrap(),
            max_salary: *sorted_salaries.last().unwrap(),
            sample_size: salaries.len(),
            location_breakdown,
        }
    })
}

async fn health_check() -> Result<impl Reply, Rejection> {
    let status = if ATTESTATION_SERVICE.is_tdx_available() {
        "TDX Enabled - Running in Confidential VM"
    } else {
        "TDX Not Detected - Running in Simulation Mode"
    };
    
    let report = ATTESTATION_SERVICE.get_tdx_report(b"health-check")
        .unwrap_or_else(|_| vec![0u8; 1024]);
    
    let quote = ATTESTATION_SERVICE.get_td_quote(&report, b"health-nonce")
        .unwrap_or_else(|_| vec![0u8; 1024]);
    
    let quote_info = parse_tdx_quote(&quote).ok();
    
    // Calculate our own binary's measurement
    let self_measurement = calculate_self_measurement();
    
    Ok(warp::reply::json(&serde_json::json!({
        "status": "healthy",
        "tee_status": status,
        "tdx_available": ATTESTATION_SERVICE.is_tdx_available(),
        "mrtd": quote_info.as_ref().map(|q| &q.mrtd).unwrap_or(&"unavailable".to_string()),
        "rtmr0": quote_info.as_ref().map(|q| &q.rtmr0).unwrap_or(&"unavailable".to_string()),
        "self_measurement": self_measurement,
        "build_info": {
            "version": env!("CARGO_PKG_VERSION"),
            "profile": if cfg!(debug_assertions) { "debug" } else { "release" },
            "target": std::env::consts::ARCH,
        }
    })))
}

fn calculate_self_measurement() -> String {
    use sha2::{Sha384, Digest};
    use std::fs;
    
    // Try to read our own binary
    if let Ok(exe_path) = std::env::current_exe() {
        if let Ok(binary_data) = fs::read(&exe_path) {
            let mut hasher = Sha384::new();
            hasher.update(&binary_data);
            let hash = hasher.finalize();
            // Return first 48 bytes (96 hex chars) like real MRTD
            return hex::encode(&hash[..48]);
        }
    }
    
    // Fallback to a deterministic value based on build
    let mut hasher = Sha384::new();
    hasher.update(env!("CARGO_PKG_VERSION").as_bytes());
    hasher.update(std::env::consts::ARCH.as_bytes());
    let hash = hasher.finalize();
    hex::encode(&hash[..48])
}

#[derive(Debug)]
struct InvalidSession;
impl warp::reject::Reject for InvalidSession {}

#[derive(Debug)]
struct DecryptionError;
impl warp::reject::Reject for DecryptionError {}

#[derive(Debug)]
struct InvalidData;
impl warp::reject::Reject for InvalidData {}

#[derive(Debug)]
struct AttestationError;
impl warp::reject::Reject for AttestationError {}

async fn handle_rejection(err: Rejection) -> Result<impl Reply, Infallible> {
    let code;
    let message;

    if err.is_not_found() {
        code = StatusCode::NOT_FOUND;
        message = "Not Found";
    } else if let Some(_) = err.find::<InvalidSession>() {
        code = StatusCode::UNAUTHORIZED;
        message = "Invalid or expired session";
    } else if let Some(_) = err.find::<DecryptionError>() {
        code = StatusCode::BAD_REQUEST;
        message = "Failed to decrypt data";
    } else if let Some(_) = err.find::<InvalidData>() {
        code = StatusCode::BAD_REQUEST;
        message = "Invalid data format";
    } else if let Some(_) = err.find::<AttestationError>() {
        code = StatusCode::INTERNAL_SERVER_ERROR;
        message = "Attestation generation failed";
    } else if let Some(_) = err.find::<warp::reject::MethodNotAllowed>() {
        code = StatusCode::METHOD_NOT_ALLOWED;
        message = "Method Not Allowed";
    } else {
        code = StatusCode::INTERNAL_SERVER_ERROR;
        message = "Internal Server Error";
    }

    let json = warp::reply::json(&serde_json::json!({
        "error": message,
    }));

    Ok(warp::reply::with_status(json, code))
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter("server=info,warp=info")
        .init();

    info!("===========================================");
    info!("Confidential Salary Analyzer Server");
    info!("===========================================");
    info!("TDX Available: {}", ATTESTATION_SERVICE.is_tdx_available());
    
    if ATTESTATION_SERVICE.is_tdx_available() {
        let report = ATTESTATION_SERVICE.get_tdx_report(b"init").unwrap_or_else(|_| vec![]);
        let quote = ATTESTATION_SERVICE.get_td_quote(&report, b"init-nonce").unwrap_or_else(|_| vec![]);
        
        if let Ok(quote_info) = parse_tdx_quote(&quote) {
            info!("MRTD: {}", quote_info.mrtd);
            info!("RTMR0: {}", quote_info.rtmr0);
            info!("RTMR1: {}", quote_info.rtmr1);
            info!("RTMR2: {}", quote_info.rtmr2);
            info!("RTMR3: {}", quote_info.rtmr3);
        }
    } else {
        info!("Running in simulation mode - TDX device not available");
    }
    
    info!("===========================================");

    let cors = warp::cors()
        .allow_any_origin()
        .allow_headers(vec!["content-type", "x-session-id"])
        .allow_methods(vec!["GET", "POST", "OPTIONS"]);

    let health = warp::path("health")
        .and(warp::get())
        .and_then(health_check);

    let attest = warp::path("attest")
        .and(warp::post())
        .and(warp::body::json())
        .and_then(handle_attestation);

    let submit = warp::path("submit")
        .and(warp::post())
        .and(warp::body::json())
        .and_then(handle_salary_submission);

    let routes = health
        .or(attest)
        .or(submit)
        .recover(handle_rejection)
        .with(cors)
        .with(warp::trace::request());

    let addr: SocketAddr = ([0, 0, 0, 0], 8080).into();
    info!("Server listening on {}", addr);
    
    warp::serve(routes).run(addr).await;

    Ok(())
}