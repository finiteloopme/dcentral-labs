# DeFi Admin - AI-Powered DeFi Protocol Management Platform

## Overview

DeFi Admin is a comprehensive platform for discovering, analyzing, and interacting with DeFi protocols across EVM-compatible blockchains. It features AI-powered agents that can autonomously interact with protocols to earn yield through lending, arbitrage, and other DeFi strategies.

### Key Features

- **Protocol Discovery**: Find and explore top DeFi protocols across multiple EVM chains
- **Comprehensive Analysis**: Deep analysis of protocol metrics, risks, and yield opportunities
- **AI Agent Generation**: Create autonomous agents tailored to specific protocols
- **Strategy Execution**: Simulate and execute various DeFi strategies (lending, liquidity provision, yield farming, arbitrage)
- **Multi-Chain Support**: Supports 15+ EVM chains including Ethereum, BSC, Polygon, Arbitrum, Base, Sonic, and more
- **Risk Assessment**: Advanced risk scoring and security analysis
- **Chain Configuration**: Centralized chain management via TOML configuration file

## Project Structure

```
defi-admin/
├── backend/                    # Python FastAPI backend
│   ├── api/                   # API endpoints
│   │   ├── protocols.py       # Protocol discovery endpoints
│   │   ├── agents.py          # Agent management endpoints
│   │   └── analysis.py        # Analysis endpoints
│   ├── protocols/             # Protocol modules
│   │   ├── discovery.py       # Protocol discovery logic
│   │   └── analyzer.py        # Protocol analysis engine
│   ├── agents/                # Agent modules
│   │   └── agent_generator.py # AI agent creation
│   ├── config/                # Configuration
│   │   └── settings.py        # Application settings
│   ├── tests/                 # Unit tests
│   ├── main.py               # FastAPI application
│   └── requirements.txt      # Python dependencies
├── frontend/                  # TypeScript React frontend
│   ├── src/
│   │   ├── components/       # React components
│   │   │   ├── ProtocolCard.tsx
│   │   │   ├── SearchBar.tsx
│   │   │   ├── RiskAssessment.tsx
│   │   │   ├── AnalysisChart.tsx
│   │   │   └── AgentCard.tsx
│   │   ├── pages/           # Application pages
│   │   │   ├── ProtocolDiscovery.tsx
│   │   │   ├── ProtocolAnalysis.tsx
│   │   │   └── AgentDashboard.tsx
│   │   ├── services/        # API services
│   │   ├── types/           # TypeScript types
│   │   ├── utils/           # Utility functions
│   │   └── App.tsx          # Main application
│   ├── public/              # Static assets
│   ├── package.json         # NPM dependencies
│   └── tsconfig.json        # TypeScript configuration
├── docs/                    # Documentation
├── Makefile                # Build automation
└── README.md              # This file
```

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Frontend (React)                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Protocol   │  │   Protocol   │  │    Agent     │      │
│  │  Discovery   │  │   Analysis   │  │  Dashboard   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                     Backend API (FastAPI)                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Protocols   │  │   Analysis   │  │    Agents    │      │
│  │     API      │  │     API      │  │     API      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                      Core Services                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Protocol   │  │   Protocol   │  │    Agent     │      │
│  │  Discovery   │  │   Analyzer   │  │  Generator   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                    External Services                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  DefiLlama   │  │  Blockchain  │  │   OpenAI     │      │
│  │     API      │  │     RPCs     │  │     API      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Installation & Setup

### Prerequisites

- Python 3.8+
- Node.js 16+
- npm or yarn
- Git

### Quick Start with Virtual Environment

#### Automatic Setup (Recommended)

**Linux/Mac:**
```bash
git clone https://github.com/yourusername/defi-admin.git
cd defi-admin
chmod +x setup.sh
./setup.sh
```

**Windows:**
```bash
git clone https://github.com/yourusername/defi-admin.git
cd defi-admin
setup.bat
```

#### Manual Setup with Make

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/defi-admin.git
cd defi-admin
```

2. **Create virtual environment and install dependencies**
```bash
make install  # Creates venv and installs all dependencies
```

3. **Configure environment**
```bash
make setup-env  # Creates .env from template
# Edit backend/.env with your API keys
```

4. **Run the application**
```bash
make run  # Automatically uses virtual environment
```

The backend will be available at `http://localhost:8000` and the frontend at `http://localhost:3000`.

### Virtual Environment Management

All Python dependencies are installed in an isolated virtual environment at `backend/venv/`.

**Key Commands:**
```bash
make venv          # Create virtual environment
make install       # Install all dependencies
make run          # Run with venv activated
make clean-venv   # Remove virtual environment
make freeze       # Update requirements.txt
make verify       # Verify installation
make diagnose     # Diagnose environment issues
```

**Troubleshooting Installation Issues:**

If you encounter errors during `make install`, try these solutions:

1. **Use core dependencies first:**
```bash
make install-backend-compat  # Install with compatibility mode
```

2. **Clear pip cache:**
```bash
make clean-cache  # Clear pip cache
make clean-venv   # Remove and recreate venv
make install      # Try installing again
```

3. **Check your Python version:**
```bash
make diagnose     # Shows Python version and import status
# Python 3.8-3.11 recommended for best compatibility
```

4. **Install core dependencies only:**
```bash
cd backend
venv/bin/pip install -r requirements-core.txt
```

**Manual Activation:**
```bash
# Linux/Mac
source backend/venv/bin/activate

# Windows
backend\venv\Scripts\activate

# Deactivate
deactivate
```

### Manual Installation

#### Backend Setup with Virtual Environment
```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
python main.py
```

#### Frontend Setup
```bash
cd frontend
npm install
npm start
```

## Configuration

### Environment Variables

Create a `.env` file in the `backend` directory with the following variables:

```env
# API Configuration
OPENAI_API_KEY=your_openai_api_key

# Database
DATABASE_URL=sqlite:///./defi_admin.db

# Redis (optional)
REDIS_URL=redis://localhost:6379
```

### Chain Configuration

All blockchain configurations are managed via `backend/config/chains.toml`. This file includes:

- **15+ EVM Chains**: Ethereum, BSC, Polygon, Arbitrum, Optimism, Avalanche, Base, Sonic, Fantom, and more
- **RPC Endpoints**: Multiple RPC URLs per chain for redundancy
- **Chain Metadata**: Chain IDs, native tokens, block times, gas limits
- **Categories**: Chains grouped by layer (L1/L2), throughput, and ecosystem
- **Testnet Support**: Includes testnet configurations for development

#### Supported Chains:
- **Layer 1**: Ethereum, BSC, Avalanche, Fantom, Sonic, Gnosis, Celo
- **Layer 2**: Arbitrum, Optimism, Base, Polygon
- **New Chains**: Base (Coinbase L2) and Sonic (high-speed chain)

To add a new chain, edit `backend/config/chains.toml`:

```toml
[chains.newchain]
name = "New Chain"
chain_id = 12345
symbol = "NEW"
rpc_urls = ["https://rpc.newchain.io"]
explorer = "https://explorer.newchain.io"
native_token = "NEW"
is_testnet = false
block_time = 3
gas_limit = 30000000
```

## Usage Guide

### Step 1: Discover Protocols

1. Navigate to the Protocol Discovery page
2. Use filters to search by chain or category
3. View top protocols by TVL

### Step 2: Analyze Protocols

1. Click "Analyze Protocol" on any protocol card
2. Review comprehensive analysis including:
   - Key metrics (TVL, market cap, changes)
   - Risk assessment and security score
   - Yield opportunities
   - Strategic recommendations

### Step 3: Create AI Agents

1. From the analysis page, click "Create AI Agent"
2. Agent will be configured based on protocol capabilities
3. View agent in the Agent Dashboard

### Step 4: Execute Strategies

1. Go to Agent Dashboard
2. Select an agent and open Control Panel
3. Choose strategy and parameters
4. Execute in simulation mode

### Step 5: Generate Standalone Code

1. From Agent Dashboard, click "Generate Code"
2. Download Python code for standalone agent
3. Customize and deploy as needed

## API Documentation

### Protocol Endpoints

- `GET /api/protocols/discover` - Discover protocols
- `GET /api/protocols/search` - Search protocols
- `GET /api/protocols/{protocol_id}` - Get protocol details
- `GET /api/protocols/{protocol_id}/analyze` - Analyze protocol
- `POST /api/protocols/compare` - Compare multiple protocols

### Agent Endpoints

- `POST /api/agents/create` - Create new agent
- `GET /api/agents/list` - List all agents
- `POST /api/agents/{agent_id}/execute` - Execute strategy
- `GET /api/agents/{agent_id}/capabilities` - Get agent capabilities
- `POST /api/agents/generate-code` - Generate agent code

### Analysis Endpoints

- `POST /api/analysis/yield-opportunities` - Find yield opportunities
- `POST /api/analysis/risk-assessment` - Assess portfolio risk
- `GET /api/analysis/market-overview` - Get market overview

### Chain Endpoints

- `GET /api/chains/list` - List all supported chains
- `GET /api/chains/categories` - Get chain categories
- `GET /api/chains/{chain_name}` - Get chain information
- `GET /api/chains/{chain_name}/rpc` - Get RPC URL for chain
- `GET /api/chains/{chain_name}/explorer` - Get explorer URL
- `GET /api/chains/category/{category}` - Get chains by category
- `POST /api/chains/reload` - Reload chain configuration

## Development

### Virtual Environment

The project uses Python virtual environments to isolate dependencies and ensure consistency across different development environments.

**Benefits:**
- Isolated Python dependencies
- No conflicts with system packages
- Consistent environment across team members
- Easy dependency management

**Virtual Environment Commands:**
```bash
make venv         # Create virtual environment
make verify       # Verify installation
make shell        # Python shell with venv
make ipython      # IPython shell with venv
make check-deps   # Check for outdated packages
make upgrade-deps # Upgrade all packages
make freeze       # Update requirements.txt
make clean-venv   # Remove virtual environment
```

**Development Workflow:**
```bash
# Initial setup
make dev-setup    # Complete development setup

# Daily development
make dev          # Start both backend and frontend
make dev-backend  # Backend with auto-reload
make dev-frontend # Frontend development server

# Testing and quality
make test         # Run all tests
make lint         # Lint code
make format       # Format code
```

### Running Tests
```bash
make test         # Run all tests
make test-backend # Backend tests only
make test-frontend # Frontend tests only
```

### Code Quality
```bash
make lint         # Check code style
make format       # Auto-format code
```

### Building for Production
```bash
make build        # Build both backend and frontend
make docker-build # Build Docker images
```

## Docker Support

### Build Docker containers
```bash
make docker-build
```

### Run with Docker
```bash
make docker-run
```

## Demo Execution Plan

### Prerequisites
1. Install Python 3.8+ and Node.js 16+
2. Clone the repository
3. Set up environment variables

### Step-by-Step Demo

1. **Setup** (5 minutes)
```bash
make dev-setup
# Edit backend/.env with API keys
make run
```

2. **Protocol Discovery** (3 minutes)
- Open browser to `http://localhost:3000`
- Browse protocols on Ethereum
- Search for "Uniswap" or "Aave"
- Filter by lending category

3. **Protocol Analysis** (5 minutes)
- Click "Analyze Protocol" on Aave
- Review risk assessment (Low risk, high security)
- Check yield opportunities (2-15% APY)
- Read strategic recommendations

4. **Agent Creation** (3 minutes)
- Click "Create AI Agent" button
- Confirm agent creation
- Navigate to Agent Dashboard

5. **Strategy Simulation** (5 minutes)
- Select created agent
- Open Control Panel
- Choose "lending" strategy
- Set amount to 1000 USDC
- Execute simulation
- Review results

6. **Code Generation** (2 minutes)
- Click "Generate Code"
- Download Python agent file
- Open and review generated code

Total demo time: ~25 minutes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## Security Considerations

- Never commit API keys or private keys
- Use environment variables for sensitive data
- Implement proper input validation
- Use secure RPC endpoints
- Audit smart contract interactions
- Test thoroughly in simulation mode

## Future Enhancements

- [ ] Real transaction execution
- [ ] Advanced portfolio management
- [ ] ML-based yield prediction
- [ ] Cross-chain bridging
- [ ] Automated rebalancing
- [ ] Social trading features
- [ ] Mobile application
- [ ] WebSocket real-time updates

## License

MIT License - see LICENSE file for details

## Support

For issues, questions, or suggestions:
- Open an issue on GitHub
- Contact: support@defiadmin.io
- Documentation: https://docs.defiadmin.io

## Acknowledgments

- DefiLlama for protocol data
- OpenAI for AI capabilities
- React and FastAPI communities
- Web3 ecosystem contributors