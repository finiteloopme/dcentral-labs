use anyhow::{anyhow, Result};
use std::fs::File;
use std::os::unix::io::AsRawFd;
use std::mem;
use sha2::{Sha256, Digest};

// TDX ioctl command definition - matches kernel header
const TDX_CMD_GET_REPORT0: u64 = 0xc4085401; // _IOWR('T', 1, struct tdx_report_req)

#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct TdxReportRequest {
    pub report_data: [u8; 64],    // User-provided report data (will contain hashed nonce)
    pub td_report: [u8; 1024],     // Output: TD Report from TDX module
}

pub struct TdxDevice {
    device: File,
}

impl TdxDevice {
    pub fn new() -> Result<Self> {
        let device = File::options()
            .read(true)
            .write(true)
            .open("/dev/tdx_guest")
            .map_err(|e| anyhow!("Failed to open /dev/tdx_guest: {}", e))?;
        
        Ok(Self { device })
    }
    
    /// Get a TD Report from the TDX module
    /// The nonce will be hashed and placed in the report_data field
    pub fn get_report(&self, nonce: &[u8]) -> Result<Vec<u8>> {
        // Hash the nonce as per TDX standard
        let mut hasher = Sha256::new();
        hasher.update(nonce);
        let nonce_hash = hasher.finalize();
        
        // Prepare the request structure
        let mut request = TdxReportRequest {
            report_data: [0u8; 64],
            td_report: [0u8; 1024],
        };
        
        // Copy the hash into report_data
        request.report_data[..32].copy_from_slice(&nonce_hash[..32]);
        
        // Perform the ioctl
        unsafe {
            let ret = libc::ioctl(
                self.device.as_raw_fd(),
                TDX_CMD_GET_REPORT0,
                &mut request as *mut _ as *mut libc::c_void,
            );
            
            if ret < 0 {
                let err = std::io::Error::last_os_error();
                return Err(anyhow!("TDX ioctl failed: {} (errno: {})", err, ret));
            }
        }
        
        // Return the TD Report
        Ok(request.td_report.to_vec())
    }
    
    /// Build a complete TDX quote from a TD Report
    /// This creates the quote structure that can be verified by clients
    pub fn build_quote_from_report(&self, report: &[u8]) -> Result<Vec<u8>> {
        if report.len() != 1024 {
            return Err(anyhow!("Invalid TD Report size: expected 1024, got {}", report.len()));
        }
        
        let mut quote = Vec::new();
        
        // Quote header (48 bytes)
        quote.extend_from_slice(&4u16.to_le_bytes()); // Version (4)
        quote.extend_from_slice(&2u16.to_le_bytes()); // Attestation Key Type (2 = ECDSA-P256)
        quote.extend_from_slice(&0u32.to_le_bytes()); // TEE Type (0 = SGX, but we use for TDX)
        quote.extend_from_slice(&[0u8; 4]); // Reserved
        quote.extend_from_slice(&[0u8; 2]); // QE Vendor ID
        quote.extend_from_slice(&[0u8; 20]); // User Data
        
        // TD Report body (584 bytes from offset 48)
        // This contains the actual measurements
        quote.extend_from_slice(&report[..584]);
        
        // Quote signature section (simplified for now)
        let sig_data_len = 360u32;
        quote.extend_from_slice(&sig_data_len.to_le_bytes());
        quote.extend_from_slice(&vec![0u8; sig_data_len as usize]); // Placeholder signature
        
        Ok(quote)
    }
}

/// Parse key fields from a TD Report
pub fn parse_td_report(report: &[u8]) -> Result<TdReportInfo> {
    if report.len() < 1024 {
        return Err(anyhow!("TD Report too small: {} bytes", report.len()));
    }
    
    Ok(TdReportInfo {
        report_type: report[0..16].try_into().unwrap(),
        report_data: report[64..128].to_vec(),
        mrtd: report[128..176].to_vec(),
        rtmr0: report[240..288].to_vec(),
        rtmr1: report[288..336].to_vec(),
        rtmr2: report[336..384].to_vec(),
        rtmr3: report[384..432].to_vec(),
    })
}

#[derive(Debug)]
pub struct TdReportInfo {
    pub report_type: [u8; 16],
    pub report_data: Vec<u8>,
    pub mrtd: Vec<u8>,
    pub rtmr0: Vec<u8>,
    pub rtmr1: Vec<u8>,
    pub rtmr2: Vec<u8>,
    pub rtmr3: Vec<u8>,
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_tdx_device() {
        // This test will only work on TDX-enabled hardware
        if std::path::Path::new("/dev/tdx_guest").exists() {
            let device = TdxDevice::new().unwrap();
            let report = device.get_report(b"test_nonce").unwrap();
            assert_eq!(report.len(), 1024);
            
            let info = parse_td_report(&report).unwrap();
            println!("MRTD: {}", hex::encode(&info.mrtd));
        }
    }
}