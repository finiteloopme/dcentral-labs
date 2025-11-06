# Frontend Security & TEE Attestation

The frontend implements comprehensive security measures to ensure it's communicating with a genuine TEE service running in a secure enclave.

## 🔐 TEE Attestation Verification

### Production Mode
When running in production (not localhost), the frontend:

1. **Requests TEE Attestation** on startup
2. **Verifies TEE Type** (Intel TDX required)
3. **Validates PCR Values** against expected hashes
4. **Checks Quote Signature** authenticity
5. **Disables Application** if attestation fails

### Development Mode
When running on localhost, attestation is skipped for development convenience.

## 🛡️ Security Features

### 1. Attestation Structure
```json
{
  "tee_type": "intel-tdx",
  "quote_version": "1.0",
  "pcrs": [
    {"index": 0, "value": "expected_pcr0_hash"},
    {"index": 1, "value": "expected_pcr1_hash"},
    ...
  ],
  "quote_signature": "authentic_signature",
  "timestamp": "2025-01-06T12:00:00Z",
  "measurement": "tee_service_image_hash"
}
```

### 2. PCR Validation
- **PCR0**: BIOS/UEFI measurement
- **PCR1**: Bootloader measurement  
- **PCR2**: Kernel measurement
- **PCR3**: Initial RAM disk measurement
- **PCR4**: Application measurement

### 3. Frontend Security Checks

#### Connection Security
- **HTTPS Only** in production
- **Certificate Validation**
- **CORS Protection**

#### Data Validation
- **Input Sanitization**
- **Amount Limits**
- **Address Validation**

#### Session Security
- **Bearer Token Authentication**
- **Session Expiration**
- **CSRF Protection**

## 🔧 Implementation Details

### Attestation Request
```javascript
const response = await fetch(`${TEE_SERVICE_URL}/healthz`, {
    method: 'GET',
    headers: {
        'X-Verify-Attestation': 'true'
    }
});
```

### Attestation Display
The frontend displays detailed attestation information:
- TEE type and version
- PCR values (truncated for display)
- Quote signature status
- Verification timestamp

### Application Lockout
If attestation fails:
- Form is disabled
- Visual error indicators
- Clear error messages
- No API calls allowed

## 🚀 Production Deployment

### Required Environment Variables
```bash
# Frontend
REACT_APP_TEE_SERVICE_URL=https://tee-service.privacy-defi.com
REACT_APP_ENV=production

# TEE Service
TEE_ATTESTATION_ENABLED=true
TEE_PCR_VALUES_FILE=/etc/tee/expected-pcrs.json
```

### Expected PCR Values
Production requires actual PCR values from the trusted TEE image:
```json
{
  "pcr0": "actual_bios_measurement_hash",
  "pcr1": "actual_bootloader_measurement_hash",
  "pcr2": "actual_kernel_measurement_hash",
  "pcr3": "actual_initrd_measurement_hash",
  "pcr4": "actual_application_measurement_hash"
}
```

## 🔒 Security Best Practices

### 1. Certificate Pinning
```javascript
// Pin TEE service certificate
const TEE_CERTIFICATE = 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
```

### 2. Content Security Policy
```html
<meta http-equiv="Content-Security-Policy" 
      content="default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';">
```

### 3. Subresource Integrity
```html
<script src="https://tee-service.privacy-defi.com/api.js"
        integrity="sha384-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA">
</script>
```

## 🧪 Testing

### Development Testing
```bash
# Start with mock attestation
npm run dev:mock-attestation

# Test attestation failure
npm run dev:attestation-fail
```

### Production Testing
```bash
# Verify real attestation
npm run test:attestation

# Security audit
npm run audit:security
```

## 📊 Monitoring

### Attestation Metrics
- Success/failure rates
- Verification time
- PCR mismatch details
- Geographic distribution

### Security Events
- Failed attestation attempts
- Invalid PCR values
- Signature verification failures
- Unexpected TEE types

This comprehensive security model ensures users can trust that their private financial data is being processed in a genuine, secure TEE environment.