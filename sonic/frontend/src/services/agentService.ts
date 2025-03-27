import axios from 'axios';
import { Signer } from 'ethers';
import { config } from '../config';

const apiClient = axios.create({
    baseURL: config.agentApiBaseUrl,
    headers: {
        "Content-Type": "application/json",
    },
});

// Function to sign payload and make authenticated request
async function makeSignedRequest(signer: Signer, endpoint: string, method: 'post' | 'get' = 'post', payload?: any) {
    if (!signer) throw new Error("Signer not available");

    let signature: string | null = null;
    let payloadString: string | null = null;

    if (payload) {
        // Consistent serialization for signing
        payloadString = JSON.stringify(payload, Object.keys(payload).sort());
        signature = await signer.signMessage(payloadString);
    }

    try {
        const response = await apiClient({
            method: method,
            url: endpoint,
            data: payload, // Send original payload
            headers: signature ? { 'X-User-Signature': signature } : {},
        });
        return response.data;
    } catch (error: any) {
        console.error(`API Error calling ${endpoint}:`, error.response?.data || error.message);
        throw new Error(error.response?.data?.error || `Failed request to ${endpoint}`);
    }
}

// --- API Functions ---

export async function startSession(userAddress: string): Promise<{ sessionId: string }> {
    // This endpoint in backend doesn't require signing
    try {
        const data = "{\"userAddress\": \"" + userAddress + "\"}"; // Add userAddress
        console.log("body msg new: " + data);
        // JSON.stringify(userAddress) ;
         const response = await apiClient.post("session", data);
         console.log("Response from /session:", response.data);
         return response.data;
    } catch (error: any) {
        console.error(`API Error calling /session:`, error.response?.data || error.message);
        throw new Error(error.response?.data?.error || `Failed request to /session`);
    }
}

export async function sendChatMessage(signer: Signer, sessionId: string, message: string): Promise<{ response: string }> {
    const payload = { sessionId, message };
    return makeSignedRequest(signer, '/chat', 'post', payload);
}

export async function submitDobGuess(signer: Signer, sessionId: string, dobGuess: string): Promise<{ correct: boolean; rewardTxHash: string | null }> {
    const payload = { sessionId, dobGuess };
    return makeSignedRequest(signer, '/guess', 'post', payload);
}

export async function getAttestationReport(): Promise<any> { // Define specific report type later
     try {
         const response = await apiClient.get('/attest_report');
         return response.data;
    } catch (error: any) {
        console.error(`API Error calling /attest_report:`, error.response?.data || error.message);
        throw new Error(error.response?.data?.error || `Failed request to /attest_report`);
    }
}

export async function getMessageFromHash(hash: string): Promise<{ message: string }> {
     try {
         const response = await apiClient.get(`/message_from_hash/${hash}`);
         return response.data;
    } catch (error: any) {
        console.error(`API Error calling /message_from_hash:`, error.response?.data || error.message);
        throw new Error(error.response?.data?.error || `Failed request to /message_from_hash`);
    }
}