use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use std::fs::{self, File};
use std::io::{Read, Write};
use std::os::unix::io::AsRawFd;
use std::path::Path;

const TDX_GUEST_DEVICE: &str = "/dev/tdx_guest";
const TDX_REPORT_DATA_SIZE: usize = 64;
const TDX_REPORT_SIZE: usize = 1024;

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct TdxReportRequest {
    report_data: [u8; TDX_REPORT_DATA_SIZE],
    tdx_report: [u8; TDX_REPORT_SIZE],
}

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct TdxQuoteHeader {
    version: u16,
    attestation_key_type: u16,
    tee_type: u32,
    reserved: [u8; 2],
    vendor_id: [u8; 16],
    user_data: [u8; 20],
}

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct TdxQuoteBody {
    tee_tcb_svn: [u8; 16],
    mrseam: [u8; 48],
    mrsignerseam: [u8; 48],
    seam_attributes: [u8; 8],
    td_attributes: [u8; 8],
    xfam: [u8; 8],
    mrtd: [u8; 48],
    mrconfigid: [u8; 48],
    mrowner: [u8; 48],
    mrownerconfig: [u8; 48],
    rtmr0: [u8; 48],
    rtmr1: [u8; 48],
    rtmr2: [u8; 48],
    rtmr3: [u8; 48],
    report_data: [u8; 64],
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GoogleAttestationToken {
    pub header: AttestationTokenHeader,
    pub payload: AttestationTokenPayload,
    pub signature: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttestationTokenHeader {
    pub alg: String,
    pub typ: String,
    pub kid: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttestationTokenPayload {
    pub iss: String,
    pub iat: u64,
    pub exp: u64,
    pub tdx_quote: String,
    pub tdx_eventlog: String,
    pub gce_tcb_version: String,
    pub platform_challenges: Vec<String>,
}

pub struct TdxAttestationService {
    device_available: bool,
    gcp_attestation_endpoint: String,
}

impl TdxAttestationService {
    pub fn new() -> Self {
        let device_available = Path::new(TDX_GUEST_DEVICE).exists();
        
        if !device_available {
            tracing::warn!("TDX guest device not available at {}", TDX_GUEST_DEVICE);
        }

        Self {
            device_available,
            gcp_attestation_endpoint: "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token".to_string(),
        }
    }

    pub fn is_tdx_available(&self) -> bool {
        self.device_available
    }

    pub fn get_tdx_report(&self, report_data: &[u8]) -> Result<Vec<u8>> {
        if !self.device_available {
            tracing::warn!("TDX device not available, using simulation");
            return self.generate_simulated_report(report_data);
        }

        // Use our new TDX ioctl module
        use crate::tdx_ioctl::TdxDevice;
        match TdxDevice::new() {
            Ok(device) => {
                tracing::info!("Using real TDX device for attestation");
                device.get_report(report_data)
            }
            Err(e) => {
                tracing::error!("Failed to open TDX device: {}, falling back to simulation", e);
                self.generate_simulated_report(report_data)
            }
        }
    }

    pub async fn get_google_attestation_token(&self, tdx_report: &[u8]) -> Result<GoogleAttestationToken> {
        if !self.device_available {
            return Ok(self.generate_simulated_token(tdx_report));
        }

        let client = reqwest::Client::new();
        
        let metadata_token = client
            .get(&self.gcp_attestation_endpoint)
            .header("Metadata-Flavor", "Google")
            .send()
            .await?
            .text()
            .await?;

        let attestation_request = serde_json::json!({
            "tdx_report": base64::encode(tdx_report),
            "runtime_data": {
                "timestamp": std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)?
                    .as_secs(),
            }
        });

        let response = client
            .post("https://confidentialcomputing.googleapis.com/v1/projects/-/locations/global/challenges:createToken")
            .bearer_auth(metadata_token)
            .json(&attestation_request)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            return Err(anyhow!("Failed to get attestation token: {}", error_text));
        }

        let token: GoogleAttestationToken = response.json().await?;
        Ok(token)
    }

    pub fn get_ccel_eventlog(&self) -> Result<Vec<u8>> {
        let ccel_path = "/sys/firmware/acpi/tables/data/CCEL";
        
        if Path::new(ccel_path).exists() {
            fs::read(ccel_path).map_err(|e| anyhow!("Failed to read CCEL: {}", e))
        } else {
            Ok(self.generate_simulated_eventlog())
        }
    }

    pub fn get_td_quote(&self, report: &[u8], nonce: &[u8]) -> Result<Vec<u8>> {
        if !self.device_available {
            return Ok(self.generate_simulated_quote(report, nonce));
        }

        // Build a quote from the TD Report
        use crate::tdx_ioctl::TdxDevice;
        let device = TdxDevice::new()?;
        device.build_quote_from_report(report)
    }

    fn generate_simulated_report(&self, report_data: &[u8]) -> Result<Vec<u8>> {
        let mut report = vec![0u8; TDX_REPORT_SIZE];
        
        report[0..2].copy_from_slice(&4u16.to_le_bytes());
        report[2..4].copy_from_slice(&2u16.to_le_bytes());
        
        let hash = shared::CryptoUtils::hash_data(report_data);
        report[32..64].copy_from_slice(&hash);
        
        report[64..96].copy_from_slice(&shared::CryptoUtils::hash_data(b"simulated-mrtd"));
        report[96..128].copy_from_slice(&shared::CryptoUtils::hash_data(b"simulated-mrconfig"));
        
        Ok(report)
    }

    pub fn generate_simulated_token(&self, tdx_report: &[u8]) -> GoogleAttestationToken {
        GoogleAttestationToken {
            header: AttestationTokenHeader {
                alg: "RS256".to_string(),
                typ: "JWT".to_string(),
                kid: "simulation-key-id".to_string(),
            },
            payload: AttestationTokenPayload {
                iss: "https://confidentialcomputing.googleapis.com".to_string(),
                iat: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs(),
                exp: std::time::SystemTime::now()
                    .duration_since(std::time::UNIX_EPOCH)
                    .unwrap()
                    .as_secs() + 3600,
                tdx_quote: base64::encode(tdx_report),
                tdx_eventlog: base64::encode(self.generate_simulated_eventlog()),
                gce_tcb_version: "1.0.0".to_string(),
                platform_challenges: vec![],
            },
            signature: base64::encode(shared::CryptoUtils::hash_data(tdx_report)),
        }
    }

    fn generate_simulated_eventlog(&self) -> Vec<u8> {
        let mut eventlog = Vec::new();
        
        eventlog.extend_from_slice(b"CCEL");
        eventlog.extend_from_slice(&1u32.to_le_bytes());
        
        let event1 = b"EV_NO_ACTION: UEFI Boot";
        eventlog.extend_from_slice(&(event1.len() as u32).to_le_bytes());
        eventlog.extend_from_slice(event1);
        
        let event2 = b"EV_PLATFORM_CONFIG_FLAGS: TDX_ENABLED";
        eventlog.extend_from_slice(&(event2.len() as u32).to_le_bytes());
        eventlog.extend_from_slice(event2);
        
        let event3 = b"EV_EFI_VARIABLE_BOOT: SecureBoot=1";
        eventlog.extend_from_slice(&(event3.len() as u32).to_le_bytes());
        eventlog.extend_from_slice(event3);
        
        eventlog
    }

    fn generate_simulated_quote(&self, _report: &[u8], nonce: &[u8]) -> Vec<u8> {
        let mut quote = Vec::new();
        
        let header = TdxQuoteHeader {
            version: 4,
            attestation_key_type: 2,
            tee_type: 0x00000081,
            reserved: [0; 2],
            vendor_id: *b"GenuineIntel    ",
            user_data: {
                let mut data = [0u8; 20];
                let len = nonce.len().min(20);
                data[..len].copy_from_slice(&nonce[..len]);
                data
            },
        };
        
        unsafe {
            let header_bytes = std::slice::from_raw_parts(
                &header as *const _ as *const u8,
                std::mem::size_of::<TdxQuoteHeader>(),
            );
            quote.extend_from_slice(header_bytes);
        }
        
        let body = TdxQuoteBody {
            tee_tcb_svn: [1; 16],
            mrseam: [0xaa; 48],
            mrsignerseam: [0xbb; 48],
            seam_attributes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x07],
            td_attributes: [0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01],
            xfam: [0xff, 0xff, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
            mrtd: {
                let mut mrtd = [0u8; 48];
                let hash = shared::CryptoUtils::hash_data(b"demo-mrtd");
                mrtd[..32].copy_from_slice(&hash);
                mrtd
            },
            mrconfigid: [0xcc; 48],
            mrowner: [0xdd; 48],
            mrownerconfig: [0xee; 48],
            rtmr0: [0x11; 48],
            rtmr1: [0x22; 48],
            rtmr2: [0x33; 48],
            rtmr3: [0x44; 48],
            report_data: {
                let mut data = [0u8; 64];
                let hash = shared::CryptoUtils::hash_data(nonce);
                data[..32].copy_from_slice(&hash);
                data
            },
        };
        
        unsafe {
            let body_bytes = std::slice::from_raw_parts(
                &body as *const _ as *const u8,
                std::mem::size_of::<TdxQuoteBody>(),
            );
            quote.extend_from_slice(body_bytes);
        }
        
        let signature = shared::CryptoUtils::hash_data(&quote);
        quote.extend_from_slice(&signature);
        
        quote
    }
}

pub fn parse_tdx_quote(quote: &[u8]) -> Result<TdxQuoteInfo> {
    if quote.len() < std::mem::size_of::<TdxQuoteHeader>() {
        return Err(anyhow!("Quote too small for header"));
    }

    let header = unsafe {
        std::ptr::read_unaligned(quote.as_ptr() as *const TdxQuoteHeader)
    };

    let version = header.version;
    if version != 4 {
        return Err(anyhow!("Unsupported quote version: {}", version));
    }

    let body_offset = std::mem::size_of::<TdxQuoteHeader>();
    if quote.len() < body_offset + std::mem::size_of::<TdxQuoteBody>() {
        return Err(anyhow!("Quote too small for body"));
    }

    let body = unsafe {
        std::ptr::read_unaligned(
            quote[body_offset..].as_ptr() as *const TdxQuoteBody
        )
    };

    Ok(TdxQuoteInfo {
        version: header.version,
        attestation_key_type: header.attestation_key_type,
        tee_type: header.tee_type,
        mrtd: hex::encode(&body.mrtd[..32]),
        rtmr0: hex::encode(&body.rtmr0[..32]),
        rtmr1: hex::encode(&body.rtmr1[..32]),
        rtmr2: hex::encode(&body.rtmr2[..32]),
        rtmr3: hex::encode(&body.rtmr3[..32]),
        report_data: body.report_data.to_vec(),
    })
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TdxQuoteInfo {
    pub version: u16,
    pub attestation_key_type: u16,
    pub tee_type: u32,
    pub mrtd: String,
    pub rtmr0: String,
    pub rtmr1: String,
    pub rtmr2: String,
    pub rtmr3: String,
    pub report_data: Vec<u8>,
}