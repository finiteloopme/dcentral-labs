use anyhow::{anyhow, Result};
use ring::signature::{EcdsaKeyPair, KeyPair, ECDSA_P256_SHA256_FIXED_SIGNING};
use ring::rand::SystemRandom;
use serde::{Deserialize, Serialize};
use sha2::{Sha256, Sha384, Digest};


// TDX TDCALL Leaf Functions
const TDG_VP_INFO: u64 = 0x1;
const TDG_MR_REPORT: u64 = 0x4;
const TDG_VP_VERIFYMR: u64 = 0x5;

// TDX Module Constants
const TDX_MODULE_CALL: u64 = 0x0;
const TDX_REPORT_SIZE: usize = 1024;
const TDX_REPORTDATA_SIZE: usize = 64;
const TDX_REPORT_TYPE_SIZE: usize = 16;

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct TdReport {
    pub report_type: [u8; TDX_REPORT_TYPE_SIZE],
    pub reserved1: [u8; 12],
    pub cpu_svn: [u8; 16],
    pub tee_tcb_info_hash: [u8; 48],
    pub tee_info_hash: [u8; 48],
    pub report_data: [u8; TDX_REPORTDATA_SIZE],
    pub reserved2: [u8; 32],
    pub mac: [u8; 32],
}

#[repr(C, packed)]
#[derive(Debug, Clone, Copy)]
pub struct TdInfo {
    pub attributes: u64,
    pub xfam: u64,
    pub mrtd: [u8; 48],
    pub mrconfigid: [u8; 48],
    pub mrowner: [u8; 48],
    pub mrownerconfig: [u8; 48],
    pub rtmr: [[u8; 48]; 4],
    pub reserved: [u8; 112],
}

#[derive(Debug, Clone)]
pub struct RawTdxQuote {
    // Quote Header (48 bytes)
    pub version: u16,
    pub att_key_type: u16,
    pub tee_type: u32,
    pub reserved1: u16,
    pub vendor_id: [u8; 16],
    pub user_data: [u8; 20],
    
    // Quote Body (584 bytes minimum)
    pub tee_tcb_svn: [u8; 16],
    pub mrseam: [u8; 48],
    pub mrsignerseam: [u8; 48],
    pub seam_attributes: u64,
    pub td_attributes: u64,
    pub xfam: u64,
    pub mrtd: [u8; 48],
    pub mrconfigid: [u8; 48],
    pub mrowner: [u8; 48],
    pub mrownerconfig: [u8; 48],
    pub rtmr0: [u8; 48],
    pub rtmr1: [u8; 48],
    pub rtmr2: [u8; 48],
    pub rtmr3: [u8; 48],
    pub report_data: [u8; 64],
    
    // Signature Section
    pub sig_algo: u32,
    pub signature: Vec<u8>,
    pub attest_pub_key: Vec<u8>,
    pub qe_report: Vec<u8>,
    pub qe_cert_data: Vec<u8>,
}

pub struct RawTdxAttestation {
    rng: SystemRandom,
    attestation_key: Option<EcdsaKeyPair>,
}

impl RawTdxAttestation {
    pub fn new() -> Result<Self> {
        let rng = SystemRandom::new();
        
        // Generate an attestation key pair (in real TDX, this comes from Intel's PCK)
        let pkcs8_bytes = EcdsaKeyPair::generate_pkcs8(
            &ECDSA_P256_SHA256_FIXED_SIGNING,
            &rng,
        ).map_err(|_| anyhow!("Failed to generate key pair"))?;
        
        let key_pair = EcdsaKeyPair::from_pkcs8(
            &ECDSA_P256_SHA256_FIXED_SIGNING,
            pkcs8_bytes.as_ref(),
            &rng,
        ).map_err(|_| anyhow!("Failed to parse key pair"))?;
        
        Ok(Self {
            rng,
            attestation_key: Some(key_pair),
        })
    }
    
    /// Simulate TDCALL instruction to get TD Report
    pub fn tdcall_get_report(&self, report_data: &[u8]) -> Result<TdReport> {
        // In real hardware, this would be inline assembly:
        // asm!("tdcall", 
        //      in("rax") TDG_MR_REPORT,
        //      in("rcx") report_struct_ptr,
        //      out("rax") status);
        
        let mut report = TdReport {
            report_type: *b"TDX_REPORT_TYPE\0",
            reserved1: [0; 12],
            cpu_svn: [0x01; 16], // CPU security version
            tee_tcb_info_hash: [0; 48],
            tee_info_hash: [0; 48],
            report_data: [0; 64],
            reserved2: [0; 32],
            mac: [0; 32],
        };
        
        // Hash the nonce and put it in report_data (TDX standard)
        use sha2::{Sha256, Digest};
        let mut hasher = Sha256::new();
        hasher.update(report_data);
        let nonce_hash = hasher.finalize();
        report.report_data[..32].copy_from_slice(&nonce_hash[..32]);
        
        // Generate hashes
        let mut hasher = Sha384::new();
        hasher.update(b"TCB_INFO");
        hasher.update(&report.cpu_svn);
        let tcb_hash = hasher.finalize();
        report.tee_tcb_info_hash[..48].copy_from_slice(&tcb_hash[..48]);
        
        hasher = Sha384::new();
        hasher.update(b"TEE_INFO");
        hasher.update(&report.report_data);
        let info_hash = hasher.finalize();
        report.tee_info_hash[..48].copy_from_slice(&info_hash[..48]);
        
        // Generate MAC (simplified - real TDX uses hardware keys)
        let mut mac_hasher = Sha256::new();
        mac_hasher.update(&report.tee_tcb_info_hash);
        mac_hasher.update(&report.tee_info_hash);
        mac_hasher.update(&report.report_data);
        let mac = mac_hasher.finalize();
        report.mac.copy_from_slice(&mac);
        
        Ok(report)
    }
    
    /// Get TD Information including measurements
    pub fn tdcall_get_td_info(&self) -> Result<TdInfo> {
        // In real hardware: TDCALL[TDG_VP_INFO]
        
        let mut info = TdInfo {
            attributes: 0x0000000000000001, // INIT=1, DEBUG=0
            xfam: 0x00000000000001E7,       // Extended features
            mrtd: [0; 48],
            mrconfigid: [0; 48],
            mrowner: [0; 48],
            mrownerconfig: [0; 48],
            rtmr: [[0; 48]; 4],
            reserved: [0; 112],
        };
        
        // Generate MRTD (Measurement of Trust Domain)
        // In real TDX, this is SHA-384 of initial TD memory
        let mut hasher = Sha384::new();
        hasher.update(b"TD_INITIAL_MEMORY");
        hasher.update(b"TD_CONFIGURATION");
        let mrtd = hasher.finalize();
        info.mrtd[..48].copy_from_slice(&mrtd[..48]);
        
        // Generate RTMRs (Runtime Measurement Registers)
        for i in 0..4 {
            hasher = Sha384::new();
            hasher.update(format!("RTMR_{}", i).as_bytes());
            let rtmr = hasher.finalize();
            info.rtmr[i][..48].copy_from_slice(&rtmr[..48]);
        }
        
        Ok(info)
    }
    
    /// Build a complete TDX Quote from TD Report
    pub fn build_quote(&self, report: &TdReport, user_data: &[u8]) -> Result<Vec<u8>> {
        let td_info = self.tdcall_get_td_info()?;
        
        let mut quote = Vec::new();
        
        // Build Quote Header (48 bytes)
        quote.extend_from_slice(&4u16.to_le_bytes());  // Version 4
        quote.extend_from_slice(&2u16.to_le_bytes());  // ECDSA-P256
        quote.extend_from_slice(&0x00000081u32.to_le_bytes()); // TDX TEE Type
        quote.extend_from_slice(&[0u8; 2]); // Reserved
        quote.extend_from_slice(b"GenuineIntel    "); // Vendor ID (16 bytes)
        
        // User data (20 bytes)
        let mut user_data_padded = [0u8; 20];
        let len = user_data.len().min(20);
        user_data_padded[..len].copy_from_slice(&user_data[..len]);
        quote.extend_from_slice(&user_data_padded);
        
        // Build Quote Body (584 bytes)
        // TEE TCB SVN
        quote.extend_from_slice(&[0x00; 16]);
        
        // MRSEAM (48 bytes) - Measurement of SEAM module
        let mut hasher = Sha384::new();
        hasher.update(b"INTEL_TDX_SEAM_MODULE");
        let mrseam = hasher.finalize();
        quote.extend_from_slice(&mrseam[..48]);
        
        // MRSIGNERSEAM (48 bytes)
        hasher = Sha384::new();
        hasher.update(b"INTEL_TDX_SIGNER");
        let mrsigner = hasher.finalize();
        quote.extend_from_slice(&mrsigner[..48]);
        
        // SEAM Attributes
        quote.extend_from_slice(&0x0000000000000007u64.to_le_bytes());
        
        // TD Attributes
        quote.extend_from_slice(&td_info.attributes.to_le_bytes());
        
        // XFAM
        quote.extend_from_slice(&td_info.xfam.to_le_bytes());
        
        // Measurements from TD Info
        quote.extend_from_slice(&td_info.mrtd);
        quote.extend_from_slice(&td_info.mrconfigid);
        quote.extend_from_slice(&td_info.mrowner);
        quote.extend_from_slice(&td_info.mrownerconfig);
        
        // RTMRs
        for rtmr in &td_info.rtmr {
            quote.extend_from_slice(rtmr);
        }
        
        // Report Data from TD Report
        quote.extend_from_slice(&report.report_data);
        
        // Sign the quote
        let signature = self.sign_quote(&quote)?;
        
        // Add signature section
        quote.extend_from_slice(&3u32.to_le_bytes()); // ECDSA_P256_SHA256
        quote.extend_from_slice(&(signature.len() as u32).to_le_bytes());
        quote.extend_from_slice(&signature);
        
        // Add attestation public key
        if let Some(ref key) = self.attestation_key {
            let pub_key = key.public_key().as_ref();
            quote.extend_from_slice(&(pub_key.len() as u32).to_le_bytes());
            quote.extend_from_slice(pub_key);
        }
        
        // Add PCK certificate chain (simplified)
        let cert_data = self.generate_pck_cert_chain()?;
        quote.extend_from_slice(&(cert_data.len() as u32).to_le_bytes());
        quote.extend_from_slice(&cert_data);
        
        Ok(quote)
    }
    
    /// Sign quote data using attestation key
    fn sign_quote(&self, data: &[u8]) -> Result<Vec<u8>> {
        if let Some(ref key) = self.attestation_key {
            let signature = key.sign(&self.rng, data)
                .map_err(|_| anyhow!("Failed to sign quote"))?;
            Ok(signature.as_ref().to_vec())
        } else {
            Err(anyhow!("No attestation key available"))
        }
    }
    
    /// Generate PCK (Provisioning Certification Key) certificate chain
    fn generate_pck_cert_chain(&self) -> Result<Vec<u8>> {
        // In real TDX, this comes from Intel's Provisioning Certification Service
        // Here we simulate a certificate chain
        
        let mut cert_chain = Vec::new();
        
        // PCK Leaf Certificate
        cert_chain.extend_from_slice(b"-----BEGIN CERTIFICATE-----\n");
        cert_chain.extend_from_slice(b"PCK_LEAF_CERT_DATA\n");
        cert_chain.extend_from_slice(b"-----END CERTIFICATE-----\n");
        
        // PCK Intermediate CA
        cert_chain.extend_from_slice(b"-----BEGIN CERTIFICATE-----\n");
        cert_chain.extend_from_slice(b"PCK_INTERMEDIATE_CA\n");
        cert_chain.extend_from_slice(b"-----END CERTIFICATE-----\n");
        
        // Intel Root CA
        cert_chain.extend_from_slice(b"-----BEGIN CERTIFICATE-----\n");
        cert_chain.extend_from_slice(b"INTEL_SGX_ROOT_CA\n");
        cert_chain.extend_from_slice(b"-----END CERTIFICATE-----\n");
        
        Ok(cert_chain)
    }
    
    /// Extended report generation with full TD context
    pub fn generate_extended_report(&self, user_data: &[u8]) -> Result<ExtendedTdReport> {
        let report = self.tdcall_get_report(user_data)?;
        let td_info = self.tdcall_get_td_info()?;
        
        // Get additional platform info
        let platform_info = self.get_platform_info()?;
        
        Ok(ExtendedTdReport {
            base_report: report,
            td_info,
            platform_info,
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap()
                .as_secs(),
        })
    }
    
    fn get_platform_info(&self) -> Result<PlatformInfo> {
        Ok(PlatformInfo {
            cpu_family: 6,
            cpu_model: 143,
            cpu_stepping: 4,
            microcode_version: 0x2b000181,
            tdx_module_version: [1, 5, 0, 0],
            pce_id: 0,
            pce_svn: 12,
            qe_svn: 7,
        })
    }
}

#[derive(Debug)]
pub struct ExtendedTdReport {
    pub base_report: TdReport,
    pub td_info: TdInfo,
    pub platform_info: PlatformInfo,
    pub timestamp: u64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct PlatformInfo {
    pub cpu_family: u32,
    pub cpu_model: u32,
    pub cpu_stepping: u32,
    pub microcode_version: u32,
    pub tdx_module_version: [u8; 4],
    pub pce_id: u16,
    pub pce_svn: u16,
    pub qe_svn: u16,
}

/// Direct hardware interface for TDX operations (requires root/special permissions)
pub mod hardware {
    use super::*;
    use std::arch::asm;
    
    #[cfg(target_arch = "x86_64")]
    pub unsafe fn tdcall(
        leaf: u64,
        input: *const u8,
        output: *mut u8,
    ) -> Result<u64> {
        let mut rax = leaf;
        let rcx = input as u64;
        let rdx = output as u64;
        
        // Note: This is simplified - real TDCALL has more complex register usage
        // and requires specific CPU state
        asm!(
            "tdcall",
            inout("rax") rax,
            in("rcx") rcx,
            in("rdx") rdx,
            clobber_abi("C"),
        );
        
        if rax == 0 {
            Ok(rax)
        } else {
            Err(anyhow!("TDCALL failed with status: 0x{:x}", rax))
        }
    }
    
    #[cfg(not(target_arch = "x86_64"))]
    pub unsafe fn tdcall(_: u64, _: *const u8, _: *mut u8) -> Result<u64> {
        Err(anyhow!("TDCALL only available on x86_64"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn test_quote_generation() {
        let attestation = RawTdxAttestation::new().unwrap();
        let user_data = b"test_nonce_123";
        let report = attestation.tdcall_get_report(user_data).unwrap();
        let quote = attestation.build_quote(&report, user_data).unwrap();
        
        assert!(quote.len() > 584); // Minimum quote size
        assert_eq!(&quote[0..2], &4u16.to_le_bytes()); // Version 4
    }
    
    #[test]
    fn test_td_info() {
        let attestation = RawTdxAttestation::new().unwrap();
        let info = attestation.tdcall_get_td_info().unwrap();
        
        assert_eq!(info.attributes & 1, 1); // INIT bit set
        assert_ne!(info.mrtd, [0; 48]); // MRTD should be populated
    }
}