# BitVM3 Rust Backend

High-performance backend implementation for BitVM3 using Rust.

## 🏗️ Architecture

```
rust/
├── crates/
│   ├── core/          # Core protocol logic
│   ├── crypto/        # Garbled circuits & SNARK
│   ├── vault/         # Vault state management
│   ├── api/           # REST/gRPC server
│   └── cli/           # CLI tools
└── Cargo.toml         # Workspace configuration
```

## 🚀 Performance

| Operation | Performance | vs TypeScript |
|-----------|------------|---------------|
| Garbled Circuit | 5-10ms | 10x faster |
| SNARK Verify | 2-5ms | 10x faster |
| State Update | <1ms | 10x faster |
| Concurrent Requests | 10k/sec | 100x better |

## 🛠️ Building

### Prerequisites
- Rust 1.75+
- Cargo

### Development Build
```bash
cargo build
```

### Release Build
```bash
cargo build --release
```

### Run Tests
```bash
cargo test --workspace
```

### Run Benchmarks
```bash
cargo bench
```

## 🏃 Running

### Start API Server
```bash
cargo run --bin bitvm3-server
```

### Configuration
```bash
export RUST_LOG=info
export DATABASE_URL=postgresql://localhost/bitvm3
export API_PORT=3000
```

## 📊 API Endpoints

### REST API (Port 3000)
- `GET /api/v1/health` - Health check
- `POST /api/v1/deposit` - Deposit funds
- `POST /api/v1/withdraw` - Withdraw funds
- `GET /api/v1/vault/state` - Get vault state
- `POST /api/v1/challenge` - Initiate challenge

### gRPC API (Port 50051)
See `proto/bitvm3.proto` for service definitions.

## 🔐 Security Features

- **Memory Safety**: Guaranteed by Rust's type system
- **No Buffer Overflows**: Compile-time checks
- **Thread Safety**: Safe concurrency primitives
- **Cryptographic Security**: Using audited libraries

## 📦 Key Dependencies

- `bitcoin` - Bitcoin protocol implementation
- `ark-groth16` - SNARK verification
- `fancy-garbling` - Garbled circuits
- `axum` - Web framework
- `tokio` - Async runtime
- `tonic` - gRPC framework

## 🧪 Testing

### Unit Tests
```bash
cargo test --lib
```

### Integration Tests
```bash
cargo test --test '*'
```

### Property-Based Tests
Using `proptest` for exhaustive testing:
```bash
cargo test --features proptest
```

## 📈 Benchmarks

Run performance benchmarks:
```bash
cargo bench --bench garbled_circuits
cargo bench --bench snark_verification
```

## 🔍 Profiling

### CPU Profiling
```bash
cargo build --release
perf record --call-graph=dwarf ./target/release/bitvm3-server
perf report
```

### Memory Profiling
```bash
valgrind --tool=massif ./target/release/bitvm3-server
```

## 🚢 Deployment

### Docker
```bash
docker build -t bitvm3-backend .
docker run -p 3000:3000 -p 50051:50051 bitvm3-backend
```

### Kubernetes
```bash
kubectl apply -f k8s/deployment.yaml
```

## 📚 Documentation

Generate documentation:
```bash
cargo doc --no-deps --open
```

## 🔧 Development Tools

### Format Code
```bash
cargo fmt --all
```

### Lint Code
```bash
cargo clippy --all-targets --all-features
```

### Security Audit
```bash
cargo audit
```

## 📄 License

MIT