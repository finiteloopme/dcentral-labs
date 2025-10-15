# Confidential Salary Analyzer

An end-to-end demonstration of **Confidential Computing** using **Intel TDX** (Trust Domain Extensions) on **Google Cloud Confidential VMs**, implemented entirely in **Rust**.

## 🎯 Project Overview

The Confidential Salary Analyzer showcases how sensitive data can be processed securely in the cloud using Trusted Execution Environments (TEEs). Users submit salary information that is:

1. **Attested** - Cryptographically verified to be running in a genuine Intel TDX environment
2. **Encrypted** - Protected in transit using session keys derived from attestation
3. **Processed Confidentially** - Analyzed within the TEE, protecting data from the cloud provider
4. **Aggregated Privately** - Returns only statistical insights, never exposing individual data

## 🔒 What is a TEE (Trusted Execution Environment)?

A **Trusted Execution Environment (TEE)** is a secure area of a processor that guarantees code and data loaded inside are protected with respect to confidentiality and integrity. Think of it as a **"black box"** where sensitive computations happen in complete isolation.

### The Problem TEEs Solve in Our Salary Analyzer

**Without TEE (Traditional Cloud):**
```
Your Salary Data → Cloud Server → 😱 Visible to:
                                    - Cloud Provider Admin
                                    - Malicious Insiders
                                    - Compromised OS
                                    - Other VMs (side-channels)
                                    - Government Requests
```

**With TEE (Confidential Computing):**
```
Your Salary Data → [🔒 TEE Black Box] → Only Statistics Out
                    ├─ Encrypted Memory
                    ├─ Isolated from OS
                    ├─ No Admin Access
                    └─ Cryptographic Proof
```

### How TEEs Protect Salary Data

#### 1. **Hardware-Level Isolation**
```
┌──────────────────────────────────────────┐
│           Physical Server                 │
├──────────────────────────────────────────┤
│  ┌────────────────┐  ┌────────────────┐ │
│  │   Regular VM   │  │  🔒 TEE (TDX)  │ │
│  │                │  │                │ │
│  │ ❌ Can't see → │  │ Salary: $120k  │ │
│  │                │  │ Role: Engineer │ │
│  │                │  │ Location: SF   │ │
│  └────────────────┘  └────────────────┘ │
│                                          │
│  Host OS/Hypervisor ❌ Can't Access TEE  │
└──────────────────────────────────────────┘
```

#### 2. **Memory Encryption**
- All salary data in TEE memory is **encrypted with hardware keys**
- Even with physical access to RAM, data appears as random bytes
- Each TEE has unique encryption keys unknown to anyone

#### 3. **Attestation - "Proof of Protection"**
Before you send your salary:
```
You: "Prove you're a real TEE!"
TEE: "Here's my cryptographic proof signed by Intel"
You: "Let me verify... ✓ Confirmed! Now I'll send my salary"
```

### Real-World Analogy

Imagine a **Swiss Bank Vault** with these properties:

🏦 **Traditional Cloud** = Regular Bank
- Bank employees can open your safety deposit box
- Security cameras watch you deposit items
- Government can subpoena access
- You trust the bank's policies

🔐 **TEE (Our Demo)** = Magic Transparent Vault
- Once you put items in, they become invisible to everyone (including bank staff)
- The vault proves it's genuine with unforgeable certificate
- Only computed results (statistics) can leave, never raw data
- Not even the bank owner can override this

### Why This Matters for Salary Data

**Scenario**: You want to know if you're paid fairly compared to peers, but:
- 😟 You don't trust the company collecting data
- 😟 You worry about data breaches
- 😟 You fear discrimination if salary is leaked
- 😟 You want privacy from the cloud provider

**Solution with TEE**:
```python
# What happens in the TEE:
def process_salary_in_tee(encrypted_salary):
    # 1. Decrypt (only possible inside TEE)
    salary = decrypt(encrypted_salary)
    
    # 2. Add to statistics (never stored in plaintext)
    update_average(salary.role, salary.amount)
    
    # 3. Return ONLY aggregate data
    return {
        "average": calculate_average(salary.role),
        "median": calculate_median(salary.role),
        # Individual salary NEVER leaves TEE
    }
```

### Intel TDX - The TEE Technology We Use

**Intel TDX (Trust Domain Extensions)** is the specific TEE technology in our demo:

| Feature | What It Does | Benefit for Salary Analyzer |
|---------|-------------|----------------------------|
| **CPU-Level Isolation** | Hardware-enforced boundaries | Cloud admin can't access salary data |
| **Memory Encryption** | AES encryption of all TD memory | RAM dumps won't reveal salaries |
| **Remote Attestation** | Cryptographic proof of TEE state | Verify server before sending salary |
| **MRTD Measurement** | Hash of exact code running | Ensure no backdoors in analyzer |
| **Secure I/O** | Encrypted channels only | Network sniffing won't work |

### Trust Model

With our TEE-based Salary Analyzer, you only need to trust:
✅ **Intel CPU Hardware** (not the cloud provider)
✅ **The open-source code** (which you can audit)
✅ **Cryptographic proofs** (math, not promises)

You DON'T need to trust:
❌ Google Cloud administrators
❌ The operating system
❌ Other software on the server
❌ Network administrators
❌ Physical datacenter staff

## 🎬 Demo Walkthrough: What Actually Happens

Let's trace through exactly what happens when you submit your salary data:

### Step 1: Initial Connection
```
You: "Hi server, I have salary data to submit"
Server: "I'm running in a TEE. Let me prove it to you first!"
```

### Step 2: Attestation (Proving TEE is Real)
```
You: "Here's a random number (nonce): 12345"
Server: "I'll include that in my proof..."
        [TEE Hardware generates unforgeable quote]
Server: "Here's my proof with your nonce + Intel's signature"
You: "Let me verify... ✓ Real TEE! ✓ Correct code! ✓ My nonce!"
```

### Step 3: Secure Channel Establishment
```
You + Server: "Let's derive encryption keys from the nonce"
Result: AES-256 encryption channel that no one else can decrypt
```

### Step 4: Submit Encrypted Salary
```
You: Encrypt("Software Engineer, $120k, San Francisco, 5 years")
     → [Encrypted blob] →
Server: [Inside TEE only] Decrypt → Process → Store in memory
```

### Step 5: Receive Statistics
```
Server: "For Software Engineers: Average=$115k, Median=$110k"
You: "Thanks! My individual salary never left the TEE"
```

### What Could Go Wrong Without TEE?

**Scenario 1: Malicious Cloud Admin** 🔴
```
Without TEE:
Admin: *Reads database* "Oh, John makes $120k"
Admin: *Sells data on dark web*

With TEE:
Admin: *Tries to access TEE memory*
Hardware: "ACCESS DENIED"
Admin: *Sees only encrypted gibberish*
```

**Scenario 2: Compromised Operating System** 🔴
```
Without TEE:
Hacker: *Compromises Linux kernel*
Hacker: *Dumps all process memory*
Hacker: "Got all salary data!"

With TEE:
Hacker: *Compromises Linux kernel*
Hacker: *Can't access TEE memory*
Hacker: "It's all encrypted hardware-level!"
```

**Scenario 3: Physical Server Access** 🔴
```
Without TEE:
Attacker: *Installs RAM sniffer*
Attacker: *Reads all memory contents*

With TEE:
Attacker: *Installs RAM sniffer*
Attacker: *Sees only AES-encrypted data*
Attacker: "Need CPU's hardware key... impossible!"
```

## 🏗️ Architecture

```
┌─────────────────┐                     ┌──────────────────────────────┐
│                 │                     │   GCP Confidential VM         │
│  Client App     │                     │  ┌────────────────────────┐  │
│  (Rust CLI)     │◄────────────────────┼──┤   Intel TDX TEE        │  │
│                 │                     │  │                        │  │
│ 1. Request      │                     │  │  Server Application    │  │
│    Attestation  ├────────────────────►│  │  - Attestation Service │  │
│                 │                     │  │  - Salary Database     │  │
│ 2. Verify Quote │◄────────────────────┤  │  - Statistics Engine   │  │
│                 │   TDX Quote +       │  │                        │  │
│ 3. Send         │   Certificates      │  └────────────────────────┘  │
│    Encrypted    ├────────────────────►│                              │
│    Salary Data  │                     │  Protected from:              │
│                 │◄────────────────────┤  - Cloud Provider            │
│ 4. Receive      │   Aggregated        │  - Host OS                   │
│    Statistics   │   Statistics        │  - Other VMs                 │
│                 │                     │                              │
└─────────────────┘                     └──────────────────────────────┘

         User's Machine                        Google Cloud Platform
```

## 🔐 How Remote Attestation Works

This implementation provides **two attestation modes**:

### Mode 1: Google Cloud Attestation Service (Default)
Uses Google's attestation infrastructure to validate and sign quotes.

### Mode 2: Raw TDX Attestation (Ground-Up Implementation)
Builds TDX quotes from scratch using direct TDCALL instructions, demonstrating the low-level attestation process without cloud dependencies.

### Detailed Attestation Flow

#### 1. **Client Initiates Attestation**
```rust
// Client generates cryptographic nonce
let nonce = CryptoUtils::generate_nonce(); // 12 random bytes
```

#### 2. **Server Generates TD Report** 

**Mode 1 - Via Cloud Service:**
```rust
// Uses /dev/tdx_guest device
let report = ATTESTATION_SERVICE.get_tdx_report(&nonce);
```

**Mode 2 - Raw TDCALL:**
```rust
// Direct TDCALL instruction (simulated in userspace)
let report = RAW_ATTESTATION.tdcall_get_report(&nonce);
// Includes: CPU SVN, TCB hash, TEE info hash, MAC
```

#### 3. **Quote Generation**

**Mode 1 - Google Cloud:**
- Sends report to Google's attestation service
- Receives signed quote with Google's certificate chain

**Mode 2 - Built from Ground:**
```rust
// Build quote structure manually
let quote = RAW_ATTESTATION.build_quote(&report, &nonce);
// Includes:
// - Header: Version(4), KeyType(ECDSA-P256), TEE Type(0x81)
// - Body: MRTD, RTMRs, Report Data, TD Attributes
// - Signature: Self-signed with generated key
```

#### 4. **Quote Structure** (584+ bytes)
```
┌─────────────────────────────┐
│      Quote Header (48B)      │
├─────────────────────────────┤
│ Version         │ 2B  │ 0x04 │
│ Att Key Type    │ 2B  │ 0x02 │
│ TEE Type        │ 4B  │ 0x81 │
│ Reserved        │ 2B  │      │
│ Vendor ID       │ 16B │ Intel│
│ User Data       │ 20B │ Nonce│
├─────────────────────────────┤
│      Quote Body (584B)       │
├─────────────────────────────┤
│ TEE TCB SVN     │ 16B │      │
│ MRSEAM          │ 48B │ SHA384│
│ MRSIGNERSEAM    │ 48B │ SHA384│
│ SEAM Attributes │ 8B  │      │
│ TD Attributes   │ 8B  │ Flags│
│ XFAM            │ 8B  │      │
│ MRTD            │ 48B │ *Key*│
│ MRCONFIGID      │ 48B │      │
│ MROWNER         │ 48B │      │
│ MROWNERCONFIG   │ 48B │      │
│ RTMR[0]         │ 48B │ Boot │
│ RTMR[1]         │ 48B │ OS   │
│ RTMR[2]         │ 48B │ App  │
│ RTMR[3]         │ 48B │ Future│
│ Report Data     │ 64B │SHA256│
├─────────────────────────────┤
│    Signature Section         │
├─────────────────────────────┤
│ Algorithm       │ 4B  │      │
│ Signature       │ Var │ECDSA │
│ Public Key      │ Var │ P256 │
│ Certificates    │ Var │ Chain│
└─────────────────────────────┘
```

#### 5. **Client Verification**
```rust
// Parse and verify quote
let quote_info = TdxQuoteVerifier::parse_quote(&quote)?;

// Verify nonce (prevents replay)
TdxQuoteVerifier::verify_report_data(&quote_info, &nonce)?;

// Verify measurements
TdxQuoteVerifier::verify_measurements(&quote_info, &policy)?;

// Check TD attributes (debug disabled, etc.)
if quote_info.td_attributes[0] & 0x01 != 0 {
    return Err("Debug mode enabled!");
}
```

#### 6. **Session Establishment**
- Derive session key from nonce + session ID
- All future communication encrypted with AES-256-GCM

## 📋 Prerequisites

- **Rust** (1.70 or later)
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  ```

- **Google Cloud Account** with billing enabled
- **gcloud CLI** installed and configured
  ```bash
  curl https://sdk.cloud.google.com | bash
  gcloud init
  ```

- **GCP Project** with Confidential Computing API enabled
  ```bash
  gcloud services enable confidentialcomputing.googleapis.com
  ```

### ⚠️ Important TDX VM Requirements

- **Machine Type**: Must use C3 series (e.g., `c3-standard-4`)
- **Maintenance Policy**: Must be `TERMINATE` (live migration not supported)
- **Zone**: Must be in a zone that supports C3 machines with TDX
- **OS**: Ubuntu 22.04 LTS or later recommended

## 🚀 Setup & Deployment

### Step 1: Create a GCP Confidential VM

```bash
# Set your project ID
export PROJECT_ID="your-project-id"
gcloud config set project $PROJECT_ID

# Create the Confidential VM with Intel TDX
# Note: TDX VMs require maintenance-policy=TERMINATE (no live migration)
gcloud compute instances create salary-analyzer-vm \
    --zone=us-central1-a \
    --machine-type=c3-standard-4 \
    --maintenance-policy=TERMINATE \
    --confidential-compute-type=TDX \
    --image-family=ubuntu-2204-lts \
    --image-project=ubuntu-os-cloud \
    --tags=http-server,https-server,ssh

# Create firewall rule for the application
gcloud compute firewall-rules create allow-salary-analyzer \
    --allow tcp:8080 \
    --source-ranges 0.0.0.0/0 \
    --target-tags http-server
```

### Step 2: Deploy the Server Application

```bash
# SSH into the Confidential VM
gcloud compute ssh salary-analyzer-vm --zone=us-central1-a

# Inside the VM, install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Clone this repository (or copy files)
git clone <your-repo-url> confidential-salary-analyzer
cd confidential-salary-analyzer

# Build the applications
make build

# Option 1: Start server with Google Cloud attestation (default)
TDX_ENABLED=1 make run-server

# Option 2: Start server with raw TDX attestation (ground-up)
TDX_ENABLED=1 USE_RAW_ATTESTATION=1 make run-server
```

### Step 3: Run the Client Application

On your local machine:

```bash
# Clone the repository
git clone <your-repo-url> confidential-salary-analyzer
cd confidential-salary-analyzer

# Build the client
make build

# Get the external IP of your VM
export SERVER_IP=$(gcloud compute instances describe salary-analyzer-vm \
    --zone=us-central1-a \
    --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Run the client demo
SERVER_URL="http://$SERVER_IP:8080" make run-client
```

## 📖 Execution Flow

### Using the Makefile

```bash
# Build all components
make build

# Start the server (in the Confidential VM)
make run-server

# Run client in demo mode (from local machine)
make run-client

# Clean build artifacts
make clean
```

### Client Modes

The client supports multiple interaction modes:

```bash
# Demo mode - automated demonstration
./client/target/release/client --server http://server:8080 demo

# Interactive mode - guided prompts
./client/target/release/client --server http://server:8080 interactive

# Direct submission
./client/target/release/client --server http://server:8080 submit \
    --role "DevOps Engineer" \
    --salary 130000 \
    --location "Seattle" \
    --years 7

# Health check
./client/target/release/client --server http://server:8080 health
```

## 💡 Understanding the Security Guarantees

### What TEE Guarantees ✅

| Guarantee | How It Works | What It Means for You |
|-----------|--------------|------------------------|
| **Confidentiality** | Hardware memory encryption | Your salary is never in plaintext outside TEE |
| **Integrity** | Measured boot + attestation | Code can't be tampered with |
| **Isolation** | CPU access controls | Even root/admin can't access |
| **Freshness** | Nonce in attestation | No replay attacks |
| **Authenticity** | Intel's signature | Not a fake TEE |

### What TEE Does NOT Protect ❌

| Not Protected | Why | Mitigation |
|---------------|-----|------------|
| **Side Channels** | Timing/power analysis | Constant-time algorithms |
| **Availability** | Server can go offline | Multiple TEE providers |
| **Input Privacy** | You choose to send data | Only send if attested |
| **Code Bugs** | TEE runs the code as-is | Open source + audits |
| **Result Privacy** | Statistics are output | Differential privacy |

## 🎯 Perfect Use Cases for TEEs

Our salary analyzer demonstrates ideal TEE use cases:

### 1. **Multi-Party Computation**
- Multiple people contribute sensitive data
- No single party should see all raw data
- Only aggregated results should be visible

### 2. **Regulatory Compliance**
- GDPR: "Data minimization" - only process what's needed
- CCPA: "Can't sell what you can't see"
- HIPAA: Medical data never exposed to cloud provider

### 3. **Competitive Intelligence**
- Companies share data for benchmarking
- No company sees competitors' raw data
- Industry gets useful aggregate insights

### 4. **Whistleblower Systems**
- Employees report misconduct
- Company can't identify reporters
- Statistics reveal systemic issues

## 🚀 Beyond the Demo: Real-World Applications

While our demo uses salary data, the same pattern applies to:

| Industry | Sensitive Data | TEE Benefit |
|----------|---------------|-------------|
| **Healthcare** | Patient records | Analyze without exposing |
| **Finance** | Transaction patterns | Fraud detection privately |
| **Government** | Tax records | Statistics without leaks |
| **Retail** | Purchase history | Trends without tracking |
| **Telecom** | Location data | Mobility without surveillance |

## 📊 Expected Output

### Successful Attestation - Cloud Service Mode

```
Confidential Salary Analyzer Client
Server: http://35.224.100.50:8080

=== Remote Attestation Process ===
✓ [████████████████████████████████████████] Attestation successful!

✓ Attestation Verified Successfully!
  MRTD: a4f3b2c1d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2
  RTMR0: 1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c
  RTMR1: 2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d
  RTMR2: 3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e
  RTMR3: 4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f
  Session ID: f47ac10b-58cc-4372-a567-0e02b2c3d479
```

### Successful Attestation - Raw TDX Mode

```
Server: http://35.224.100.50:8080

[Server Logs]
INFO: Building TDX quote from ground up without cloud service
INFO: Got TD Report with MAC: a1b2c3d4
INFO: Built raw TDX quote: 1248 bytes
INFO: Raw attestation response generated
INFO: MRTD: 5f4e3d2c1b0a9f8e7d6c5b4a3928176
INFO: TD Attributes: 0x0000000000000001
INFO: Platform: CPU 6/143/4, Microcode: 0x2b000181

[Client Output]
=== Remote Attestation Process ===
✓ Parsing TDX quote structure...
✓ Verifying report data (nonce)...
✓ Verifying measurements against policy...
✓ Verifying event log...
✓ [████████████████████████████████████████] Attestation successful!

✓ Attestation Verified Successfully!
  MRTD: 5f4e3d2c1b0a9f8e7d6c5b4a39281765
  RTMR0: 6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d
  Session ID: a567-0e02b2c3d479

→ Submitting sample 1 of 3...
  Role: Software Engineer, Salary: $120000, Location: San Francisco
  Salary data processed successfully in TEE

→ Submitting sample 2 of 3...
  Role: Software Engineer, Salary: $95000, Location: Austin
  Salary data processed successfully in TEE

→ Submitting sample 3 of 3...
  Role: Software Engineer, Salary: $150000, Location: San Francisco
  Salary data processed successfully in TEE

=== Salary Statistics ===
Role: Software Engineer
Sample Size: 3
Average Salary: $121666.67
Median Salary: $120000.00
Min Salary: $95000
Max Salary: $150000

Location Breakdown:
  San Francisco - Avg: $135000.00 (n=2)
  Austin - Avg: $95000.00 (n=1)

Demo completed successfully!
```

### Failed Attestation (Untrusted Environment)

```
Confidential Salary Analyzer Client
Server: http://untrusted-server:8080

=== Remote Attestation Process ===
✗ [████████────────────────────────────────] Quote verification failed!

Error: Quote verification failed
Details: MRENCLAVE mismatch - server is not running expected code
```

## 🆕 Raw Attestation Mode (Building Quote from Ground)

When running with `USE_RAW_ATTESTATION=1`, the server builds TDX quotes from scratch:

### Raw Implementation Features

1. **Direct TDCALL Interface**
   - Simulates TDCALL CPU instructions
   - Generates TD Reports without kernel dependencies
   - Builds quote byte-by-byte according to TDX spec

2. **Manual Quote Construction**
   ```rust
   // Generate TD Report via TDCALL
   let report = RAW_ATTESTATION.tdcall_get_report(&nonce);
   
   // Get TD measurements
   let td_info = RAW_ATTESTATION.tdcall_get_td_info();
   
   // Build complete quote
   let quote = RAW_ATTESTATION.build_quote(&report, &nonce);
   ```

3. **Self-Signed Attestation**
   - Generates ECDSA-P256 key pair
   - Signs quote with generated key
   - Creates mock PCK certificate chain

4. **Platform Information**
   - CPU family, model, stepping
   - Microcode version
   - TDX module version
   - PCE/QE SVN values

### Comparing Attestation Modes

| Aspect | Google Cloud Service | Raw TDX (Ground-Up) |
|--------|---------------------|---------------------|
| **Dependencies** | Google APIs, /dev/tdx_guest | None (pure Rust) |
| **Quote Signing** | Google's PCK | Self-generated key |
| **Certificate Chain** | Intel → Google → Quote | Self-signed chain |
| **Production Ready** | ✅ Yes | ❌ Educational only |
| **Hardware Required** | TDX-enabled CPU | Works in simulation |
| **Quote Size** | ~4KB with certs | ~1KB base + certs |

### When to Use Each Mode

- **Google Cloud Service**: Production deployments, real attestation
- **Raw TDX Mode**: Education, debugging, understanding TDX internals

## 🔧 Technical Details

### Project Structure

```
confidential-salary-analyzer/
├── client/                 # Client application
│   ├── Cargo.toml
│   └── src/
│       └── main.rs        # CLI interface, attestation logic
├── server/                # Server application  
│   ├── Cargo.toml
│   └── src/
│       └── main.rs        # TEE service, attestation provider
├── shared/                # Shared library
│   ├── Cargo.toml
│   └── src/
│       └── lib.rs         # Common types, crypto utilities
├── scripts/               # Deployment scripts
│   ├── build.sh
│   ├── run_server.sh
│   └── attest_and_run_client.sh
├── Makefile              # Build automation
└── README.md             # This file
```

### Key Components

1. **Attestation Module**: Handles TDX quote generation and verification
2. **Crypto Module**: AES-GCM encryption, SHA-256 hashing, key derivation
3. **Statistics Engine**: Computes aggregates without exposing individual data
4. **Session Manager**: Maintains encrypted channels per client

### Security Guarantees

- **Code Integrity**: MRENCLAVE ensures only authorized code runs
- **Data Confidentiality**: AES-256-GCM encryption for all sensitive data
- **Attestation Freshness**: Nonce prevents replay attacks
- **Forward Secrecy**: Unique session keys per connection
- **Side-Channel Protection**: Intel TDX hardware mitigations

## 🧪 Testing

Run the test suite:

```bash
# Unit tests
cargo test --all

# Integration test with local server
TDX_ENABLED=0 make run-server &
sleep 2
make run-client
```

## 📚 Additional Resources

- [Intel TDX Architecture Specification](https://www.intel.com/content/www/us/en/developer/articles/technical/intel-trust-domain-extensions.html)
- [Google Cloud Confidential Computing](https://cloud.google.com/confidential-computing)
- [Remote Attestation Concepts](https://www.intel.com/content/www/us/en/developer/articles/technical/quote-verification-attestation-with-intel-sgx-dcap.html)

## 📝 License

This is an educational demonstration project. Use at your own risk in production environments.

## 🤝 Contributing

Contributions are welcome! Please ensure all tests pass and follow Rust best practices.

## ⚠️ Disclaimer

This demo simplifies certain aspects of TDX attestation for educational purposes. Production deployments should:
- Use actual TDX hardware attestation APIs
- Implement complete certificate chain validation
- Include comprehensive error handling
- Add persistent storage with encryption at rest
- Implement rate limiting and DDoS protection