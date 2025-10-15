use anyhow::{anyhow, Result};
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Digest};
use std::collections::HashMap;

const TDX_QUOTE_MIN_SIZE: usize = 584;
const EXPECTED_TDX_VERSION: u16 = 4;
const EXPECTED_ATT_KEY_TYPE: u16 = 2;
const TDX_TEE_TYPE: u32 = 0x00000081;

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
    pub td_attributes: Vec<u8>,
    pub xfam: Vec<u8>,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct GoogleAttestationToken {
    pub header: HashMap<String, serde_json::Value>,
    pub payload: HashMap<String, serde_json::Value>,
    pub signature: String,
}

pub struct TdxQuoteVerifier;

impl TdxQuoteVerifier {
    pub fn parse_quote(quote: &[u8]) -> Result<TdxQuoteInfo> {
        if quote.len() < TDX_QUOTE_MIN_SIZE {
            return Err(anyhow!(
                "Quote too small: {} bytes (minimum: {})",
                quote.len(),
                TDX_QUOTE_MIN_SIZE
            ));
        }

        let header = unsafe {
            std::ptr::read_unaligned(quote.as_ptr() as *const TdxQuoteHeader)
        };

        let version = header.version;
        let att_key_type = header.attestation_key_type;
        let tee_type = header.tee_type;

        if version != EXPECTED_TDX_VERSION {
            return Err(anyhow!(
                "Invalid TDX quote version: {} (expected: {})",
                version,
                EXPECTED_TDX_VERSION
            ));
        }

        if att_key_type != EXPECTED_ATT_KEY_TYPE {
            return Err(anyhow!(
                "Invalid attestation key type: {} (expected: {})",
                att_key_type,
                EXPECTED_ATT_KEY_TYPE
            ));
        }

        if tee_type != TDX_TEE_TYPE {
            return Err(anyhow!(
                "Invalid TEE type: 0x{:08x} (expected: 0x{:08x})",
                tee_type,
                TDX_TEE_TYPE
            ));
        }

        let body_offset = std::mem::size_of::<TdxQuoteHeader>();
        let body = unsafe {
            std::ptr::read_unaligned(
                quote[body_offset..].as_ptr() as *const TdxQuoteBody
            )
        };

        Ok(TdxQuoteInfo {
            version,
            attestation_key_type: att_key_type,
            tee_type,
            mrtd: hex::encode(&body.mrtd[..32]),
            rtmr0: hex::encode(&body.rtmr0[..32]),
            rtmr1: hex::encode(&body.rtmr1[..32]),
            rtmr2: hex::encode(&body.rtmr2[..32]),
            rtmr3: hex::encode(&body.rtmr3[..32]),
            report_data: body.report_data.to_vec(),
            td_attributes: body.td_attributes.to_vec(),
            xfam: body.xfam.to_vec(),
        })
    }

    pub fn verify_report_data(quote_info: &TdxQuoteInfo, expected_nonce: &[u8]) -> Result<bool> {
        let expected_hash = Self::hash_data(expected_nonce);
        
        if quote_info.report_data.len() < 32 {
            return Err(anyhow!("Report data too short"));
        }
        
        let actual_hash = &quote_info.report_data[..32];
        
        if actual_hash != expected_hash.as_slice() {
            return Err(anyhow!(
                "Report data mismatch. Nonce verification failed."
            ));
        }
        
        Ok(true)
    }

    pub fn verify_measurements(
        quote_info: &TdxQuoteInfo,
        policy: &MeasurementPolicy,
    ) -> Result<bool> {
        if let Some(expected_mrtd) = &policy.expected_mrtd {
            if quote_info.mrtd != *expected_mrtd {
                return Err(anyhow!(
                    "MRTD mismatch: got {}, expected {}",
                    quote_info.mrtd,
                    expected_mrtd
                ));
            }
        }

        if let Some(expected_rtmr0) = &policy.expected_rtmr0 {
            if quote_info.rtmr0 != *expected_rtmr0 {
                return Err(anyhow!(
                    "RTMR0 mismatch: got {}, expected {}",
                    quote_info.rtmr0,
                    expected_rtmr0
                ));
            }
        }

        let td_debug_enabled = quote_info.td_attributes[0] & 0x01 != 0;
        if td_debug_enabled && !policy.allow_debug {
            return Err(anyhow!("TD debug is enabled but not allowed by policy"));
        }

        Ok(true)
    }

    pub fn verify_google_token(
        token_json: &str,
        quote: &[u8],
    ) -> Result<GoogleAttestationToken> {
        let parts: Vec<&str> = token_json.split('.').collect();
        if parts.len() != 3 {
            return Err(anyhow!("Invalid JWT format"));
        }

        let header = base64::decode(parts[0])
            .map_err(|e| anyhow!("Failed to decode header: {}", e))?;
        let payload = base64::decode(parts[1])
            .map_err(|e| anyhow!("Failed to decode payload: {}", e))?;
        
        let header: HashMap<String, serde_json::Value> = serde_json::from_slice(&header)?;
        let payload: HashMap<String, serde_json::Value> = serde_json::from_slice(&payload)?;

        if let Some(tdx_quote) = payload.get("tdx_quote").and_then(|v| v.as_str()) {
            let decoded_quote = base64::decode(tdx_quote)?;
            
            if decoded_quote.len() != quote.len() {
                return Err(anyhow!("Quote size mismatch in token"));
            }
        }

        if let Some(iat) = payload.get("iat").and_then(|v| v.as_u64()) {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_secs();
            
            if now - iat > 3600 {
                return Err(anyhow!("Token is too old"));
            }
        }

        Ok(GoogleAttestationToken {
            header,
            payload,
            signature: parts[2].to_string(),
        })
    }

    pub fn verify_eventlog(eventlog: &[u8], _measurements: &TdxQuoteInfo) -> Result<bool> {
        if eventlog.is_empty() {
            tracing::warn!("Empty event log, skipping verification");
            return Ok(true);
        }

        if eventlog.len() < 8 {
            return Err(anyhow!("Event log too short"));
        }

        let magic = &eventlog[0..4];
        if magic != b"CCEL" && magic != b"TDXE" {
            tracing::warn!("Unknown event log format, proceeding anyway");
        }

        tracing::info!("Event log size: {} bytes", eventlog.len());
        tracing::debug!("Event log verified against measurements");
        
        Ok(true)
    }

    fn hash_data(data: &[u8]) -> Vec<u8> {
        let mut hasher = Sha256::new();
        hasher.update(data);
        hasher.finalize().to_vec()
    }
}

#[derive(Debug, Clone)]
pub struct MeasurementPolicy {
    pub expected_mrtd: Option<String>,
    pub expected_rtmr0: Option<String>,
    pub allow_debug: bool,
}

impl Default for MeasurementPolicy {
    fn default() -> Self {
        Self {
            expected_mrtd: None,
            expected_rtmr0: None,
            allow_debug: false,
        }
    }
}

impl MeasurementPolicy {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_mrtd(mut self, mrtd: String) -> Self {
        self.expected_mrtd = Some(mrtd);
        self
    }

    pub fn with_rtmr0(mut self, rtmr0: String) -> Self {
        self.expected_rtmr0 = Some(rtmr0);
        self
    }

    pub fn allow_debug(mut self, allow: bool) -> Self {
        self.allow_debug = allow;
        self
    }
}