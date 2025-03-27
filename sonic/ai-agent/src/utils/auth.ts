import { ethers } from 'ethers';

export function verifyUserSignature(
    payload: any, // The data that was signed
    signature: string,
    expectedSignerAddress: string
): boolean {
    try {
        // Ensure consistent serialization matching the frontend
        const messageString = JSON.stringify(payload, Object.keys(payload).sort());
        const signerAddress = ethers.verifyMessage(messageString, signature);
        return signerAddress.toLowerCase() === expectedSignerAddress.toLowerCase();
    } catch (error: any) {
        console.error("Signature verification error:", error.message);
        return false;
    }
}