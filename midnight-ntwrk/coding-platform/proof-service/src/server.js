const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 8080;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

// Logging middleware
app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
    next();
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({
        status: 'healthy',
        service: 'midnight-proof-service',
        version: '0.1.0-mvp',
        timestamp: new Date().toISOString()
    });
});

// Get service info
app.get('/api/info', (req, res) => {
    res.json({
        name: 'Midnight Proof Service',
        version: '0.1.0-mvp',
        capabilities: [
            'proof-generation',
            'proof-verification',
            'circuit-compilation'
        ],
        supportedProtocols: ['groth16', 'plonk', 'stark'],
        endpoints: {
            health: '/health',
            info: '/api/info',
            generate: '/api/proof/generate',
            verify: '/api/proof/verify',
            compile: '/api/circuit/compile'
        }
    });
});

// Generate proof endpoint
app.post('/api/proof/generate', async (req, res) => {
    try {
        const { contract, inputs, protocol = 'groth16' } = req.body;
        
        console.log(`Generating ${protocol} proof for contract: ${contract || 'unknown'}`);
        
        // Simulate proof generation delay
        await new Promise(resolve => setTimeout(resolve, 1500));
        
        // Generate mock proof data
        const proof = {
            pi_a: [
                '0x' + crypto.randomBytes(32).toString('hex'),
                '0x' + crypto.randomBytes(32).toString('hex')
            ],
            pi_b: [
                [
                    '0x' + crypto.randomBytes(32).toString('hex'),
                    '0x' + crypto.randomBytes(32).toString('hex')
                ],
                [
                    '0x' + crypto.randomBytes(32).toString('hex'),
                    '0x' + crypto.randomBytes(32).toString('hex')
                ]
            ],
            pi_c: [
                '0x' + crypto.randomBytes(32).toString('hex'),
                '0x' + crypto.randomBytes(32).toString('hex')
            ],
            protocol: protocol
        };
        
        const publicSignals = inputs?.publicSignals || [
            '0x' + crypto.randomBytes(32).toString('hex')
        ];
        
        res.json({
            success: true,
            proof: proof,
            publicSignals: publicSignals,
            verificationKey: '0x' + crypto.randomBytes(64).toString('hex'),
            metadata: {
                contract: contract || 'unknown',
                protocol: protocol,
                timestamp: new Date().toISOString(),
                prover: 'midnight-prover-0.1.0',
                gasEstimate: Math.floor(Math.random() * 100000) + 50000
            }
        });
    } catch (error) {
        console.error('Proof generation error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Verify proof endpoint
app.post('/api/proof/verify', async (req, res) => {
    try {
        const { proof, publicSignals, verificationKey } = req.body;
        
        console.log('Verifying proof...');
        
        // Simulate verification delay
        await new Promise(resolve => setTimeout(resolve, 500));
        
        // Mock verification (always returns true for MVP)
        const isValid = proof && (
            proof.pi_a?.length === 2 &&
            proof.pi_b?.length === 2 &&
            proof.pi_c?.length === 2
        );
        
        res.json({
            success: true,
            valid: isValid,
            metadata: {
                verifier: 'midnight-verifier-0.1.0',
                timestamp: new Date().toISOString(),
                gasUsed: Math.floor(Math.random() * 50000) + 20000
            }
        });
    } catch (error) {
        console.error('Proof verification error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Compile circuit endpoint
app.post('/api/circuit/compile', async (req, res) => {
    try {
        const { source, optimization = true } = req.body;
        
        console.log('Compiling circuit...');
        
        // Simulate compilation delay
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        // Generate mock circuit data
        const circuit = {
            constraints: Math.floor(Math.random() * 10000) + 1000,
            publicInputs: Math.floor(Math.random() * 10) + 1,
            privateInputs: Math.floor(Math.random() * 20) + 5,
            outputs: Math.floor(Math.random() * 5) + 1,
            r1cs: '0x' + crypto.randomBytes(64).toString('hex'),
            wasm: '0x' + crypto.randomBytes(128).toString('hex')
        };
        
        res.json({
            success: true,
            circuit: circuit,
            metadata: {
                compiler: 'midnight-compiler-0.1.0',
                optimization: optimization,
                timestamp: new Date().toISOString()
            }
        });
    } catch (error) {
        console.error('Circuit compilation error:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get supported curves
app.get('/api/curves', (req, res) => {
    res.json({
        curves: [
            {
                name: 'bn128',
                description: 'Barreto-Naehrig curve',
                security: 128
            },
            {
                name: 'bls12-381',
                description: 'BLS12-381 curve',
                security: 128
            },
            {
                name: 'grumpkin',
                description: 'Grumpkin curve',
                security: 128
            }
        ]
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        success: false,
        error: 'Internal server error'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        success: false,
        error: 'Endpoint not found'
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🔐 Midnight Proof Service running on http://localhost:${PORT}`);
    console.log(`   Health check: http://localhost:${PORT}/health`);
    console.log(`   API info: http://localhost:${PORT}/api/info`);
});

module.exports = app;