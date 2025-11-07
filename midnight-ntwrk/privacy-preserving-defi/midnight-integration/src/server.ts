/**
 * Midnight Integration Server
 * 
 * Express server that provides REST API for Midnight proof generation
 * using our direct proof server integration.
 */

import express from 'express';
import cors from 'cors';
import { 
  generateConcentrationProof,
  generateBalanceUpdateProof,
  generateTvlMirrorProof,
  verifyConcentrationProof,
  verifyBalanceUpdateProof,
  verifyTvlMirrorProof,
  midnightProofIntegration,
  MidnightProofResponse
} from './midnight-proof-integration.js';

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'midnight-integration',
    version: '1.0.0'
  });
});

// Proof generation endpoints
app.post('/generate-concentration-proof', async (req, res) => {
  try {
    const { userPubkey, depositAmount, currentTvl } = req.body;
    
    if (!userPubkey || !depositAmount || !currentTvl) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userPubkey, depositAmount, currentTvl'
      });
    }

    const result = await generateConcentrationProof(userPubkey, depositAmount, currentTvl);
    res.json(result);
  } catch (error) {
    console.error('Concentration proof generation failed:', error);
    res.status(500).json({
      success: false,
      error: `Concentration proof generation failed: ${error}`
    });
  }
});

app.post('/generate-balance-update-proof', async (req, res) => {
  try {
    const { userPubkey, depositAmount, newTvl } = req.body;
    
    if (!userPubkey || !depositAmount || !newTvl) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userPubkey, depositAmount, newTvl'
      });
    }

    const result = await generateBalanceUpdateProof(userPubkey, depositAmount, newTvl);
    res.json(result);
  } catch (error) {
    console.error('Balance update proof generation failed:', error);
    res.status(500).json({
      success: false,
      error: `Balance update proof generation failed: ${error}`
    });
  }
});

app.post('/generate-tvl-mirror-proof', async (req, res) => {
  try {
    const { newTvl, teeSignature } = req.body;
    
    if (!newTvl || !teeSignature) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: newTvl, teeSignature'
      });
    }

    const result = await generateTvlMirrorProof(newTvl, teeSignature);
    res.json(result);
  } catch (error) {
    console.error('TVL mirror proof generation failed:', error);
    res.status(500).json({
      success: false,
      error: `TVL mirror proof generation failed: ${error}`
    });
  }
});

// Complete deposit flow endpoint
app.post('/process-deposit', async (req, res) => {
  try {
    const { userAddress, userPubkey, amount, currentTvl } = req.body;
    
    if (!userAddress || !userPubkey || !amount || !currentTvl) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: userAddress, userPubkey, amount, currentTvl'
      });
    }

    console.log(`Processing deposit: ${amount} to ${userAddress}`);

    // Step 1: Generate concentration limit proof
    const concentrationResult = await generateConcentrationProof(userPubkey, amount.toString(), currentTvl.toString());
    
    if (!concentrationResult.success) {
      return res.status(400).json({
        success: false,
        error: `Concentration proof generation failed: ${concentrationResult.error}`
      });
    }

    // Step 2: Verify concentration proof
    const concentrationValid = await verifyConcentrationProof(
      concentrationResult.proof,
      concentrationResult.publicInputs,
      concentrationResult.verificationKey
    );

    if (!concentrationValid) {
      return res.status(400).json({
        success: false,
        error: 'Concentration limit check failed'
      });
    }

    // Step 3: Generate balance update proof
    const newTvl = currentTvl + amount;
    const balanceResult = await generateBalanceUpdateProof(userPubkey, amount.toString(), newTvl.toString());
    
    if (!balanceResult.success) {
      return res.status(400).json({
        success: false,
        error: `Balance update proof generation failed: ${balanceResult.error}`
      });
    }

    // Step 4: Verify balance update proof
    const balanceValid = await verifyBalanceUpdateProof(
      balanceResult.proof,
      balanceResult.publicInputs,
      balanceResult.verificationKey
    );

    if (!balanceValid) {
      return res.status(400).json({
        success: false,
        error: 'Balance update proof verification failed'
      });
    }

    console.log(`Deposit processed successfully: ${amount} to ${userAddress}`);

    res.json({
      success: true,
      concentrationProof: {
        proof: Array.from(concentrationResult.proof),
        publicInputs: concentrationResult.publicInputs,
        verificationKey: Array.from(concentrationResult.verificationKey),
      },
      balanceUpdateProof: {
        proof: Array.from(balanceResult.proof),
        publicInputs: balanceResult.publicInputs,
        verificationKey: Array.from(balanceResult.verificationKey),
      },
      transactionHash: `0x${Date.now().toString(16)}`,
      midnightTx: `midnight_proof_${Date.now().toString(16)}`
    });
  } catch (error) {
    console.error('Deposit processing failed:', error);
    res.status(500).json({
      success: false,
      error: `Deposit processing failed: ${error}`
    });
  }
});

// TVL mirror update endpoint
app.post('/update-tvl-mirror', async (req, res) => {
  try {
    const { newTvl, teeSignature } = req.body;
    
    if (!newTvl || !teeSignature) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: newTvl, teeSignature'
      });
    }

    const result = await generateTvlMirrorProof(newTvl.toString(), teeSignature);
    
    if (!result.success) {
      return res.status(400).json({
        success: false,
        error: `TVL mirror proof generation failed: ${result.error}`
      });
    }

    res.json({
      success: true,
      proof: {
        proof: Array.from(result.proof),
        publicInputs: result.publicInputs,
        verificationKey: Array.from(result.verificationKey),
      },
      newTvl,
      teeSignature
    });
  } catch (error) {
    console.error('TVL mirror update failed:', error);
    res.status(500).json({
      success: false,
      error: `TVL mirror update failed: ${error}`
    });
  }
});

// Proof verification endpoints
app.post('/verify-proof', async (req, res) => {
  try {
    const { circuitName, proof, publicInputs, verificationKey } = req.body;
    
    if (!circuitName || !proof || !publicInputs || !verificationKey) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: circuitName, proof, publicInputs, verificationKey'
      });
    }

    let isValid = false;
    
    switch (circuitName) {
      case 'check_concentration_limit':
        isValid = await verifyConcentrationProof(
          new Uint8Array(proof),
          publicInputs,
          new Uint8Array(verificationKey)
        );
        break;
      case 'update_balance':
        isValid = await verifyBalanceUpdateProof(
          new Uint8Array(proof),
          publicInputs,
          new Uint8Array(verificationKey)
        );
        break;
      case 'update_tvl_mirror':
        isValid = await verifyTvlMirrorProof(
          new Uint8Array(proof),
          publicInputs,
          new Uint8Array(verificationKey)
        );
        break;
      default:
        return res.status(400).json({
          success: false,
          error: `Unknown circuit: ${circuitName}`
        });
    }

    res.json({
      valid: isValid,
      circuitName,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Proof verification failed:', error);
    res.status(500).json({
      success: false,
      error: `Proof verification failed: ${error}`
    });
  }
});

// Status endpoint
app.get('/status', async (req, res) => {
  try {
    const proofServerStatus = await midnightProofIntegration.getStatus();
    
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      service: 'midnight-integration',
      proofServer: proofServerStatus,
      circuits: [
        'check_concentration_limit',
        'update_balance',
        'update_tvl_mirror'
      ]
    });
  } catch (error) {
    res.status(500).json({
      status: 'error',
      error: `Status check failed: ${error}`
    });
  }
});

// Error handling middleware
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error('Unhandled error:', err);
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
  console.log(`Midnight Integration Service running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Status: http://localhost:${PORT}/status`);
});

export default app;