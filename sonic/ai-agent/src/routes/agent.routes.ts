import express from 'express';
import { ethers } from 'ethers';
import { config } from '../config';
import { SessionData, SessionStore, ChatRequestBody, GuessRequestBody } from '../types';
import { verifyUserSignature } from '../utils/auth';
import { getAiResponse } from '../services/ai.service';
import { generateAttestationReport } from '../services/attestation.service';
import { contract, sendAgentTx, sendRewardTx, hashMessage, getLogKey, storeOffChain, retrieveFromOffChain } from '../services/web3.service';

export const agentRouter = express.Router();

// --- Simple In-Memory Session Store ---
const sessions: SessionStore = {}; // Replace with persistent storage

// --- Middleware (Example - could be more robust) ---
// Authentication middleware (applied selectively below)
const authenticateUser = (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const signature = req.headers['x-user-signature'] as string;
    const payload = req.body; // Assumes body contains necessary data for verification
    const sessionId = req.body.sessionId || req.params.sessionId;

    if (!sessionId || !sessions[sessionId]) {
        res.status(404).json({ error: "Session not found" });
    }
    const expectedUserAddress = sessions[sessionId].userAddress;

    if (!signature) {
        res.status(401).json({ error: "Missing signature" });
    }

    if (!verifyUserSignature(payload, signature, expectedUserAddress)) {
        console.warn(`Auth failed: Invalid signature for session ${sessionId}, user ${expectedUserAddress}`);
        res.status(403).json({ error: "Invalid signature" });
    }

    // Attach userAddress for convenience
    (req as any).userAddress = expectedUserAddress;
    next();
};


// --- Routes ---
const sessionHandler: express.RequestHandler = (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const { userAddress } = req.body; // Frontend needs to send user's address
    console.log("What have we received from the frontend? ", req.body);  
    if (!userAddress) {
        res.status(400).json({ error: "userAddress is required" });
    }
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    sessions[sessionId] = { userAddress: userAddress, history: [] };
    console.log(`Session started: ${sessionId} for user ${userAddress}`);
    res.status(201).json({ sessionId });    
}
// Endpoint to start a session (could be implicit on first /chat)
// agentRouter.post('/session', authenticateUser,sessionHandler);
agentRouter.post('/session', sessionHandler);


// Chat endpoint
agentRouter.post('/chat', authenticateUser, async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const { sessionId, message } = req.body as ChatRequestBody;
    const userAddress = (req as any).userAddress; // From middleware

    console.log(`[Session ${sessionId}] Received message from ${userAddress}: ${message}`);

    try {
        const session = sessions[sessionId];
        if (!session) res.status(404).json({ error: "Session not found" }); // Should be caught by middleware but belts and braces

        // Add user message to history
        session.history.push({ role: 'user', parts: [{ text: message }] });

        // Get AI response
        const aiResponseText = await getAiResponse(message, session.history);
        console.log(`[Session ${sessionId}] AI Response: ${aiResponseText}`);

         // Add model response to history
         session.history.push({ role: 'model', parts: [{ text: aiResponseText }] });

        // Store messages off-chain (simulation)
        const promptHash = hashMessage(message);
        const responseHash = hashMessage(aiResponseText);
        storeOffChain(promptHash, message);
        storeOffChain(responseHash, aiResponseText);

        // Record Hashes On-Chain (fire and forget for API response speed)
        // TODO: Record on-chain
        const logKey = getLogKey(sessionId);
        console.log(`Prompt hash: ${promptHash}, response hash: ${responseHash}`),
        sendAgentTx(
            contract.recordInteraction(logKey, userAddress, promptHash, responseHash),
            `Record Interaction session ${sessionId}`
        ).catch(e => console.error("Error submitting interaction TX:", e)); // Log async error

        // Return response to frontend
        res.status(200).json({ response: aiResponseText });

    } catch (error: any) {
        console.error(`[Session ${sessionId}] Error processing chat:`, error);
        res.status(500).json({ error: error.message || "Failed to process chat message" });
    } 
});

// Guess endpoint
agentRouter.post('/guess', authenticateUser, async (req: express.Request, res: express.Response, next: express.NextFunction) => {
    const { sessionId, dobGuess } = req.body as GuessRequestBody;
    const userAddress = (req as any).userAddress;

    console.log(`[Session ${sessionId}] Received DOB guess from ${userAddress}: ${dobGuess}`);

    try {
        const session = sessions[sessionId]; // Ensure session exists via middleware

        let wasCorrect = (dobGuess === config.agentDob);
        let rewardTxHash: string | null = null;

        console.log(`[Session ${sessionId}] Guess is ${wasCorrect ? 'Correct' : 'Incorrect'}`);

        // Record guess result On-Chain (fire and forget)
        // TODO: Record on-chain
        // const logKey = getLogKey(sessionId);
        // sendAgentTx(
        //     contract.recordGuessResult(logKey, userAddress, wasCorrect),
        //     `Record Guess session ${sessionId}`
        // ).catch(e => console.error("Error submitting guess record TX:", e));

        // If correct, send reward
        if (wasCorrect) {
            try {
                // Amount needs to be BigInt in wei
                const amountWei = ethers.parseUnits("200", 18); // Assuming 18 decimals for Sonic token
                // TODO: Record on-chain
                // const rewardTx = await sendRewardTx(userAddress, amountWei);
                // rewardTxHash = rewardTx?.hash ?? null;
                // if (!rewardTxHash) {
                //     console.error(`[Session ${sessionId}] Reward transfer FAILED!`);
                //     // How to handle? User might lose reward. Maybe mark wasCorrect as false?
                //     // For MVP, we just log the error. Needs robust handling.
                //     wasCorrect = false; // Revert correctness if reward failed? Risky.
                // }
            } catch (rewardError) {
                console.error(`[Session ${sessionId}] Reward transfer threw error:`, rewardError);
                wasCorrect = false; // Revert?
            }
        }

         // Clean up session after guess? Maybe keep for logs?
         // delete sessions[sessionId];
        res.json({ correct: wasCorrect, rewardTxHash: "{TBC: Placeholder Txn Hash}" });
        // res.json({ correct: wasCorrect, rewardTxHash: rewardTxHash });

    } catch (error: any) {
        console.error(`[Session ${sessionId}] Error processing guess:`, error);
        res.status(500).json({ error: error.message || "Failed to process guess" });
    }
});

// Endpoint to get raw attestation report
agentRouter.get('/attest_report', async (req: express.Request, res: express.Response) => {
    try {
        const report = await generateAttestationReport();
        res.json(report);
    } catch (error: any) {
        console.error("Error generating attestation report:", error);
        res.status(500).json({ error: error.message || "Failed to generate report" });
    }
});

// Endpoint to retrieve full message from hash
agentRouter.get('/message_from_hash/:hash', (req: express.Request, res: express.Response) => {
    // Add AuthN/AuthZ if needed - should anyone be able to resolve hashes?
    const hash = req.params.hash;
    const message = retrieveFromOffChain(hash);
    if (message) {
        res.json({ message: message });
    } else {
        res.status(404).json({ error: "Message not found for this hash" });
    }
});