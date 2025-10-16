# Midnight Development Platform - Architecture

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Google Cloud Platform                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Cloud Workstations                     │  │
│  │                                                           │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │  │
│  │  │ Workstation │  │ Workstation │  │ Workstation │      │  │
│  │  │     #1      │  │     #2      │  │     #3      │ ...  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘      │  │
│  │         │                │                │               │  │
│  │         └────────────────┴────────────────┘               │  │
│  │                          │                                │  │
│  └──────────────────────────┼────────────────────────────────┘  │
│                             │                                    │
│  ┌──────────────────────────┼────────────────────────────────┐  │
│  │                     VPC Network                            │  │
│  │                          │                                 │  │
│  │  ┌───────────────────────┴─────────────────────────────┐  │  │
│  │  │              Workstation Subnet                      │  │  │
│  │  │                  10.0.0.0/24                         │  │  │
│  │  └───────────────────────┬─────────────────────────────┘  │  │
│  │                          │                                 │  │
│  │  ┌───────────────────────┴─────────────────────────────┐  │  │
│  │  │                  Cloud NAT                           │  │  │
│  │  │              External IP: X.X.X.X                    │  │  │
│  │  └───────────────────────┬─────────────────────────────┘  │  │
│  └──────────────────────────┼────────────────────────────────┘  │
│                             │                                    │
│  ┌──────────────────────────┼────────────────────────────────┐  │
│  │              Artifact Registry                             │  │
│  │                          │                                 │  │
│  │  ┌───────────────────────┴─────────────────────────────┐  │  │
│  │  │         midnight-workstation-images                  │  │  │
│  │  │    - midnight-workstation:latest                     │  │  │
│  │  │    - midnight-workstation:v0.1.0                     │  │  │
│  │  └───────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                 External Services                         │  │
│  │                                                           │  │
│  │  ┌─────────────────┐  ┌─────────────────┐                │  │
│  │  │  Proof Service  │  │ Midnight Testnet│                │  │
│  │  │  (Port 8080)    │  │                 │                │  │
│  │  └─────────────────┘  └─────────────────┘                │  │
│  └──────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Component Details

### 1. Cloud Workstations

**Purpose**: Managed development environments accessible via browser

**Configuration**:
- Machine Type: e2-standard-4 (4 vCPU, 16 GB RAM)
- Boot Disk: 50 GB SSD
- Persistent Disk: 200 GB for /home
- Idle Timeout: 20 minutes
- Running Timeout: 4 hours
- Container Image: Custom Midnight development image

**Features**:
- Pre-installed Midnight tools
- VS Code (Code OSS) IDE
- OpenCode AI assistant with web terminal (xterm.js)
- Integrated terminal
- Git integration
- NPM/Node.js environment

### 2. VPC Network

**Purpose**: Isolated network for workstations

**Configuration**:
- CIDR: 10.0.0.0/24
- Region: us-central1
- Private Google Access: Enabled
- Flow Logs: Enabled

**Security**:
- Firewall rules for IAP access
- Internal communication only
- NAT for external connectivity

### 3. Cloud NAT

**Purpose**: Outbound internet connectivity for workstations

**Configuration**:
- Static external IP
- Auto-allocated NAT IPs
- Logging: Errors only

### 4. Artifact Registry

**Purpose**: Container image storage

**Configuration**:
- Format: Docker
- Region: us-central1
- Cleanup policies:
  - Keep tagged images for 28 days
  - Delete untagged after 7 days

### 5. Proof Service

**Purpose**: Zero-knowledge proof generation and verification

**Endpoints**:
- `/health` - Service health check
- `/api/proof/generate` - Generate proofs
- `/api/proof/verify` - Verify proofs
- `/api/circuit/compile` - Compile circuits

**Architecture**:
```
┌─────────────────────────────────────┐
│         Proof Service               │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Express Server         │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────┴──────────────────┐   │
│  │     Proof Generator         │   │
│  │   - Groth16                 │   │
│  │   - PLONK                   │   │
│  │   - STARK                   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │     Circuit Compiler        │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Proof Verifier         │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Data Flow

### 1. Development Workflow

```
Developer → Browser → Cloud Workstation → IDE
                           ↓
                    Compile Contract
                           ↓
                    Generate Proof
                           ↓
                    Deploy to Testnet
```

### 2. Proof Generation Flow

```
Contract Code → Compiler → Circuit → Prover → Proof
                                        ↓
                                    Verifier
                                        ↓
                                    Testnet
```

## Security Architecture

### Network Security
- VPC isolation
- Private subnets
- Cloud NAT for egress
- Firewall rules

### Identity & Access
- IAP for workstation access
- Service accounts for resources
- RBAC policies

### Data Protection
- Encryption at rest
- Encryption in transit
- Persistent disk retention

## Scalability Considerations

### Horizontal Scaling
- Multiple workstation instances
- Load-balanced proof service
- Regional deployment options

### Vertical Scaling
- Configurable machine types
- Adjustable disk sizes
- Resource quotas

## Monitoring & Observability

### Metrics
- Workstation utilization
- Proof generation latency
- Network throughput
- Storage usage

### Logging
- Application logs
- System logs
- Audit logs
- Flow logs

### Alerting
- Service health
- Resource limits
- Error rates
- SLA violations

## Disaster Recovery

### Backup Strategy
- Persistent disk snapshots
- Container image versioning
- Configuration backups

### Recovery Procedures
- Workstation restoration
- Network recreation
- Service redeployment

## Future Enhancements

### Phase 2 (Production)
- Multi-region deployment
- Advanced RBAC
- CI/CD integration
- Monitoring dashboard

### Phase 3 (Enterprise)
- Private clusters
- VPN connectivity
- SSO integration
- Compliance controls