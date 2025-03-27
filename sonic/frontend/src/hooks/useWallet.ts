import { useState, useEffect, useCallback } from 'react';
import { ethers, BrowserProvider, Signer } from 'ethers';

declare global {
    interface Window {
        ethereum?: any;
    }
}

export function useWallet() {
    const [provider, setProvider] = useState<BrowserProvider | null>(null);
    const [signer, setSigner] = useState<Signer | null>(null);
    const [address, setAddress] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [isConnected, setIsConnected] = useState(false);

    const connectWallet = useCallback(async () => {
        setError(null);
        if (window.ethereum) {
            try {
                const browserProvider = new ethers.BrowserProvider(window.ethereum);
                await browserProvider.send("eth_requestAccounts", []); // Request connection
                const currentSigner = await browserProvider.getSigner();
                const currentAddress = await currentSigner.getAddress();

                setProvider(browserProvider);
                setSigner(currentSigner);
                setAddress(currentAddress);
                setIsConnected(true);
                console.log("Wallet connected:", currentAddress);

                // Listen for account changes
                window.ethereum.on('accountsChanged', (accounts: string[]) => {
                    console.log("Accounts changed:", accounts);
                    if (accounts.length > 0) {
                        // Re-initialize signer/address
                        connectWallet(); // Reconnect to get new signer state
                    } else {
                        disconnectWallet();
                    }
                });

                 // Listen for chain changes
                window.ethereum.on('chainChanged', (chainId: string) => {
                    console.log("Chain changed:", chainId);
                     // Reload or prompt user to switch? Forcing reload is simplest.
                    window.location.reload();
                });


            } catch (err: any) {
                console.error("Failed to connect wallet:", err);
                setError(err.message || "Failed to connect wallet.");
                setIsConnected(false);
            }
        } else {
            setError("MetaMask (or other EIP-1193 provider) not detected. Please install it.");
            setIsConnected(false);
        }
    }, []); // Added empty dependency array

    const disconnectWallet = useCallback(() => {
        setProvider(null);
        setSigner(null);
        setAddress(null);
        setIsConnected(false);
        setError(null);
         // Remove listeners? Depends on desired behavior.
        if (window.ethereum?.removeListener) {
            // window.ethereum.removeListener('accountsChanged', ...); // Requires storing function reference
        }
        console.log("Wallet disconnected");
    }, []);

    // Optional: Auto-connect on load if previously connected? (Requires localStorage)

    return { provider, signer, address, isConnected, error, connectWallet, disconnectWallet };
}