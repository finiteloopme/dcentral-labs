# MRTD (MRENCLAVE) Verification Guide

## Overview

MRTD (Measurement of Trust Domain) in Intel TDX is equivalent to MRENCLAVE in Intel SGX. It's a cryptographic measurement (SHA-384 hash) that uniquely identifies the exact code and initial state of a Trust Domain. This guide explains how to verify MRTD and ensure deterministic builds.

## What is MRTD?

MRTD is a 384-bit (48-byte) cryptographic hash that represents:

1. **Initial TD Memory**: All code and data pages loaded at TD creation
2. **TD Configuration**: Attributes, CPU features, security settings
3. **Memory Layout**: Page addresses, permissions, and types
4. **Build Artifacts**: The exact binary being executed

## Why MRTD Verification Matters

```
┌──────────────────────────────────────────────────────┐
│                  Trust Decision Flow                  │
├──────────────────────────────────────────────────────┤
│                                                       │
│   Client                            Server (TD)       │
│     │                                  │              │
│     │  1. Request Attestation          │              │
│     ├─────────────────────────────────►│              │
│     │                                  │              │
│     │  2. Quote with MRTD=X           │              │
│     │◄─────────────────────────────────┤              │
│     │                                  │              │
│     │  3. Check: MRTD == Expected?    │              │
│     ├──┐                               │              │
│     │  │ if (X != Expected) REJECT    │              │
│     │  │ if (X == Expected) TRUST     │              │
│     │◄─┘                               │              │
│     │                                  │              │
│     │  4. Send Sensitive Data         │              │
│     ├─────────────────────────────────►│              │
│                                                       │
└──────────────────────────────────────────────────────┘
```

## The Challenge: Deterministic Builds

For MRTD verification to work, builds must be **reproducible**:

### Non-Deterministic Factors to Eliminate

1. **Timestamps**: Build dates embedded in binaries
2. **Random Seeds**: RNG initialization in compiler
3. **File Paths**: Absolute paths in debug info
4. **Build Order**: Parallel compilation randomness
5. **Linker Variations**: Different link orders
6. **Compiler Versions**: Different optimizations

### Solution: Deterministic Build Process

```bash
# Use our deterministic build script
./scripts/deterministic_build.sh

# This ensures:
# - Fixed timestamps (SOURCE_DATE_EPOCH)
# - Single codegen unit
# - No debug info
# - Stable link order
# - Docker container for consistent environment
```

## Step-by-Step MRTD Verification

### 1. Build Deterministically

```bash
# Build with deterministic settings
cd server
cargo build --profile release-deterministic

# Or use Docker for full reproducibility
docker run --rm -v $PWD:/build tdx-deterministic-builder \
    cargo build --profile release-deterministic
```

### 2. Calculate Expected MRTD

```bash
# Method 1: From binary file
python3 scripts/calculate_mrtd.py server/target/release/server

# Output:
# Calculated MRTD: a4f3b2c1d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8

# Method 2: From build measurements
cat measurements.json | jq -r .mrtd
```

### 3. Configure Client Verification

```rust
// client/src/main.rs
const EXPECTED_MRTD: &str = "a4f3b2c1d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b3c2d1e0f9a8b7c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8";

// Or via environment variable
export EXPECTED_MRTD="a4f3b2c1d9e8f7a6..."
```

### 4. Verify During Attestation

```rust
// Client verification code
pub fn verify_mrtd(quote: &TdxQuote) -> Result<()> {
    let actual_mrtd = &quote.body.mrtd;
    let expected_mrtd = EXPECTED_MRTD;
    
    if actual_mrtd != expected_mrtd {
        return Err(anyhow!(
            "MRTD mismatch!\n\
             Expected: {}\n\
             Actual:   {}\n\
             This means the server is running different code!",
            expected_mrtd, actual_mrtd
        ));
    }
    
    Ok(())
}
```

## MRTD Calculation Deep Dive

### How TDX Calculates MRTD

```python
# Simplified MRTD calculation
hasher = SHA384()

# 1. Measure TD configuration
hasher.update(td_attributes)      # 8 bytes
hasher.update(xfam)              # 8 bytes (CPU features)
hasher.update(max_vcpus)         # 4 bytes

# 2. For each memory page loaded:
for page in td_pages:
    hasher.update(page.gpa)      # Guest Physical Address
    hasher.update(page.type)     # Normal, SEPT, etc.
    hasher.update(page.content)  # 4KB page data

# 3. Final MRTD
mrtd = hasher.finalize()[:48]    # First 48 bytes
```

### Memory Layout Impact

Different memory layouts produce different MRTDs:

```
Configuration A:                 Configuration B:
┌─────────────────┐             ┌─────────────────┐
│ Code @ 0x400000 │             │ Code @ 0x401000 │  ← Different
├─────────────────┤             ├─────────────────┤
│ Data @ 0x500000 │             │ Data @ 0x500000 │
├─────────────────┤             ├─────────────────┤
│ Stack @ 0x7FF00 │             │ Stack @ 0x7FF00 │
└─────────────────┘             └─────────────────┘
MRTD: abc123...                 MRTD: def456...     ← Different!
```

## Practical MRTD Management

### Development vs Production

```yaml
# mrtd-policy.yaml
development:
  allow_debug: true
  expected_mrtd: null  # Don't check in dev
  
staging:
  allow_debug: false
  expected_mrtd: "dev_build_mrtd_here"
  
production:
  allow_debug: false
  expected_mrtd: "prod_build_mrtd_here"
  enforce_strict: true
```

### CI/CD Integration

```yaml
# .github/workflows/deterministic-build.yml
name: Deterministic Build
on:
  release:
    types: [created]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deterministic Build
        run: ./scripts/deterministic_build.sh
      
      - name: Calculate MRTD
        run: |
          MRTD=$(python3 scripts/calculate_mrtd.py server/target/release/server)
          echo "MRTD=$MRTD" >> $GITHUB_OUTPUT
      
      - name: Update Expected MRTD
        run: |
          echo "$MRTD" > expected_mrtd.txt
          git commit -am "Update MRTD for release"
```

## Troubleshooting MRTD Mismatches

### Common Causes

1. **Different Compiler Versions**
   ```bash
   # Check Rust version
   rustc --version
   # Solution: Use same version in Dockerfile
   ```

2. **Build Flags Mismatch**
   ```bash
   # Check build flags
   cargo build --verbose
   # Solution: Use .cargo/config.toml
   ```

3. **Dependencies Changed**
   ```bash
   # Check Cargo.lock
   diff Cargo.lock Cargo.lock.expected
   # Solution: Commit Cargo.lock
   ```

4. **Non-Deterministic Code**
   ```rust
   // Bad: Timestamp in binary
   const BUILD_TIME: &str = env!("BUILD_TIME");
   
   // Good: Fixed value
   const BUILD_TIME: &str = "2024-01-01";
   ```

### Debugging Tools

```bash
# Compare two binaries
diff <(hexdump -C binary1) <(hexdump -C binary2)

# Find non-deterministic sections
objdump -s binary | grep -E "2024|$(date +%Y)"

# Strip and compare
strip --strip-all -o binary1.stripped binary1
strip --strip-all -o binary2.stripped binary2
sha384sum binary1.stripped binary2.stripped
```

## Security Considerations

### MRTD Pinning Strategy

```rust
pub struct MRTDPolicy {
    // Strict: Exact match required
    strict_mrtd: Option<String>,
    
    // Flexible: Accept multiple versions
    allowed_mrtds: Vec<String>,
    
    // Time-based: MRTD valid until date
    mrtd_expiry: HashMap<String, DateTime>,
    
    // Gradual rollout
    canary_mrtd: Option<String>,
    canary_percentage: f32,
}
```

### Attack Scenarios

1. **Binary Substitution**: Attacker replaces binary
   - **Defense**: MRTD changes, client rejects

2. **Configuration Tampering**: Attacker modifies TD config
   - **Defense**: Config included in MRTD

3. **Rollback Attack**: Attacker uses old vulnerable version
   - **Defense**: Maintain MRTD blocklist

4. **Build Injection**: Attacker injects code during build
   - **Defense**: Reproducible builds + multiple builders

## Best Practices

### 1. Multi-Party Verification

```bash
# Builder A
./scripts/deterministic_build.sh
echo "Builder A MRTD: $(cat measurements.json | jq -r .mrtd)"

# Builder B (different machine)
./scripts/deterministic_build.sh
echo "Builder B MRTD: $(cat measurements.json | jq -r .mrtd)"

# Should match exactly!
```

### 2. MRTD Transparency

```json
// Publish MRTDs publicly
{
  "version": "1.0.0",
  "mrtd": "a4f3b2c1...",
  "build_date": "2024-01-01",
  "builder": "CI System",
  "signature": "..."
}
```

### 3. Gradual MRTD Updates

```rust
// Support both old and new during transition
const OLD_MRTD: &str = "old_mrtd_value";
const NEW_MRTD: &str = "new_mrtd_value";
const TRANSITION_END: i64 = 1234567890;

fn verify_mrtd(actual: &str) -> bool {
    if actual == NEW_MRTD {
        return true;
    }
    
    // Accept old MRTD during transition
    if actual == OLD_MRTD && timestamp() < TRANSITION_END {
        log::warn!("Using old MRTD, please update client");
        return true;
    }
    
    false
}
```

## Summary

MRTD verification is the cornerstone of TDX security:

- **MRTD = Identity**: Uniquely identifies code and configuration
- **Deterministic Builds**: Required for reproducible MRTDs
- **Client Verification**: Must check MRTD before trusting
- **Transparency**: Publish expected MRTDs publicly
- **Multiple Builders**: Verify builds are reproducible

Without proper MRTD verification, attestation is meaningless!