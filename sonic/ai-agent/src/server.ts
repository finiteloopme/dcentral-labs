import express from 'express';
import cors from 'cors';
import { config } from './config';
import { agentRouter } from './routes/agent.routes';
import { contract, sendAgentRegistration, sendAgentTx, agentWallet } from './services/web3.service';
import { generateAttestationReport } from './services/attestation.service';
import { hashMessage } from './services/web3.service';
// import schedule from 'node-schedule'; // Use for background tasks

const app = express();

// --- Middleware ---
app.use(cors()); // Configure CORS properly for production
app.use(express.json()); // Body parser

// Simple request logger
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});

// --- Routes ---
app.use('/api/agent', agentRouter);

// --- Health Check ---
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

// --- Background Task (Example: Periodic Attestation Submission) ---
async function submitAttestation() {
    console.log("Background task: Submitting attestation hash...");
    try {
        const report = await generateAttestationReport();
        // Hash the report consistently (e.g., hash the base64 quote)
        const reportHash = hashMessage(report.quote); // Or hash the whole JSON object string

        await sendAgentTx(
            contract.submitAttestationHash(reportHash),
            "Submit Attestation Hash"
        );
        console.log("Background task: Attestation hash submitted successfully.");
    } catch (error) {
        console.error("Background task: Error submitting attestation:", error);
    }
}

// Run once on startup and then periodically
// TODO: need a better way to register agent including endpoint url
async function setupAgent() {
    // await sendAgentRegistration(config.agentDeveloperWalletAddress, `http://0.0.0.0:${config.port}/api/agent`); 
    await submitAttestation(); // Initial submission
    setInterval(submitAttestation, config.attestationIntervalHours * 60 * 60 * 1000);
    // Using setInterval is simple; for production consider node-schedule or external cron jobs        
}
setupAgent();

// --- Start Server ---
console.log(`AI Agent backend server will be running at http://localhost:${config.port}`);
app.listen(config.port, () => {
    console.log(`AI Agent backend server running at http://localhost:${config.port}`);
    // Display current date/time context
    console.log(`Current time: ${new Date().toString()}`); // Added based on user context request
});

// --- Graceful Shutdown (Optional but Recommended) ---
process.on('SIGTERM', () => {
    console.log('SIGTERM signal received: closing HTTP server');
    // Perform cleanup if needed
    process.exit(0);
});
process.on('SIGINT', () => {
    console.log('SIGINT signal received: closing HTTP server');
    // Perform cleanup
    process.exit(0);
});