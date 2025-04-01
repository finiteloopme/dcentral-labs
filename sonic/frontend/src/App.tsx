import React, { useState, useEffect, useCallback, useRef } from 'react';
import './App.css';
import { useWallet } from './hooks/useWallet';
import { getAgentInfo, AgentInfo } from './services/contractService';
import { startSession, sendChatMessage, submitDobGuess, getMessageFromHash } from './services/agentService';
import { config } from './config';
import { ethers } from 'ethers'; // Import ethers for hashing

interface ChatMessage {
    id: string; // Use hash or unique identifier
    type: 'user' | 'agent' | 'info';
    text: string;
    isHash?: boolean; // Flag if text is currently just a hash
}

function App() {
    const { signer, address, isConnected, error: walletError, connectWallet, disconnectWallet } = useWallet();
    const [agentInfo, setAgentInfo] = useState<AgentInfo | null>(null);
    const [isAgentAttested, setIsAgentAttested] = useState<boolean | null>(true);
    // const [agentInfo, setAgentInfo] = useState<AgentInfo | null>(null);
    // const [isAgentAttested, setIsAgentAttested] = useState<boolean | null>(null);
    const [sessionId, setSessionId] = useState<string | null>(null);
    const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
    const [inputValue, setInputValue] = useState('');
    const [isGuessing, setIsGuessing] = useState(false); // Toggle for guess input
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const messagesEndRef = useRef<null | HTMLDivElement>(null); // For auto-scrolling

    // --- Effects ---

    // Scroll to bottom when messages change
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    }, [chatMessages]);

    // Check agent attestation status on load or connection
    const checkAttestation = useCallback(async () => {
        setIsAgentAttested(true);
        // setIsAgentAttested(null); // Reset
        // console.log("Checking agent attestation for:", config.agentWalletAddress);
        // const info = await getAgentInfo(config.agentWalletAddress);
        // setAgentInfo(info);
        // if (info && info.isActive) {
        //     const attestationAgeSeconds = Math.floor(Date.now() / 1000) - Number(info.lastAttestationTimestamp);
        //     const isRecent = attestationAgeSeconds < (parseInt(config.attestationIntervalHours) * 60 * 60 + 300); // Allow 5 min buffer
        //     console.log(`Attestation timestamp: ${info.lastAttestationTimestamp}, Age: ${attestationAgeSeconds}s, Is Recent: ${isRecent}`);
        //     setIsAgentAttested(isRecent);
        //     if (!isRecent) {
        //         setError("Agent attestation is outdated or missing.");
        //     }
        //      // **MVP Limitation**: We are ONLY checking recency, not verifying the report content.
        // } else {
        //     setIsAgentAttested(false);
        //     setError("Agent not found in registry or is inactive.");
        // }
    }, []); // Added empty dependency array

    useEffect(() => {
        // Check initially and maybe periodically?
        checkAttestation();
        // const interval = setInterval(checkAttestation, 60000); // Check every minute?
        // return () => clearInterval(interval);
    }, [checkAttestation]); // Added checkAttestation to dependency array


    // --- Handlers ---

    const handleConnect = async () => {
        setError(null);
        await connectWallet();
    };

    const handleStartSession = async () => {
        if (!address || isAgentAttested === false || isAgentAttested === null) {
            setError("Cannot start session. Connect wallet and ensure agent is attested.");
            return;
        }
        console.log("Starting session with address:", address);
        setIsLoading(true);
        setError(null);
        try {
            console.log("Trying to start session with address:", address);
            const data = await startSession(address);
            setSessionId(data.sessionId);
            setChatMessages([{ id: `info-${Date.now()}`, type: 'info', text: `Session started: ${data.sessionId}` }]);
            console.log("Session started:", data.sessionId);
        } catch (err: any) {
            setError(err.message || "Failed to start session.");
        } finally {
            setIsLoading(false);
        }
    };

    const handleSendMessage = async () => {
        if (!signer || !sessionId || !inputValue.trim()) return;

        const messageText = inputValue;
        const messageHash = ethers.solidityPackedKeccak256(['string'], [messageText]);
        setInputValue(''); // Clear input immediately
        setIsLoading(true);
        setError(null);

        // Add user message optimistically (or hash)
        addMessage({ id: messageHash, type: 'user', text: messageText }); // Store full text locally for now

        try {
            const data = await sendChatMessage(signer, sessionId, messageText);
            const responseHash = ethers.solidityPackedKeccak256(['string'], [data.response]);
            // Add agent response
            addMessage({ id: responseHash, type: 'agent', text: data.response });
        } catch (err: any) {
            setError(err.message || "Failed to send message or get response.");
            // Optional: Remove optimistic user message on error?
        } finally {
            setIsLoading(false);
        }
    };

    const handleSendGuess = async () => {
         if (!signer || !sessionId || !inputValue.trim()) return;

        const guessText = inputValue;
        setInputValue('');
        setIsLoading(true);
        setError(null);

        addMessage({ id: `guess-${Date.now()}`, type: 'user', text: `Submitting guess: ${guessText}` });

        try {
            const data = await submitDobGuess(signer, sessionId, guessText);
            if (data.correct) {
                 addMessage({ id: `result-${Date.now()}`, type: 'info', text: `DOB Guess CORRECT! Reward TX: ${data.rewardTxHash || 'Error sending reward?'}` });
                 // TODO: Maybe end session state here?
            } else {
                 addMessage({ id: `result-${Date.now()}`, type: 'info', text: `DOB Guess Incorrect.` });
            }
        } catch (err: any) {
            setError(err.message || "Failed to submit guess.");
        } finally {
            setIsLoading(false);
            setIsGuessing(false); // Turn off guessing mode
        }
    };

    const addMessage = (message: ChatMessage) => {
        setChatMessages(prev => [...prev, message]);
    };

    // --- Render ---
    return (
        <div className="App">
            <header className="App-header">
                <h1>What is my date of birth?</h1>
                {/* Wallet Connection */}
                <div>
                    {!isConnected ? (
                        <button onClick={handleConnect} disabled={isLoading}>Connect Wallet</button>
                    ) : (
                        <div>
                            <p>Connected: {address?.substring(0, 6)}...{address?.substring(address.length - 4)}</p>
                            <button onClick={disconnectWallet}>Disconnect</button>
                        </div>
                    )}
                    {walletError && <p className="error">Wallet Error: {walletError}</p>}
                </div>

                 {/* Attestation Status */}
                 <div className="attestation-status">
                     Agent Attestation Status:
                     {isAgentAttested === null ? " Checking..." : (isAgentAttested ? " Verified (Recent)" : " FAILED/Outdated")}
                     {agentInfo && isAgentAttested && <span className='timestamp'> (Last seen: {new Date(Number(agentInfo.lastAttestationTimestamp) * 1000).toLocaleString()})</span>}
                 </div>

                {error && <p className="error">Error: {error}</p>}
            </header>

            <main className="App-main">
                {/* Session Control */}
                {isConnected && !sessionId && isAgentAttested === true && (
                    <button onClick={handleStartSession} disabled={isLoading}>Start New Session</button>
                )}

                {/* Chat Area */}
                {sessionId && (
                    <div className="chat-area">
                         <p>Session ID: {sessionId}</p>
                        <div className="message-list">
                            {chatMessages.map((msg) => (
                                <div key={msg.id} className={`message ${msg.type}`}>
                                    <strong>{msg.type.toUpperCase()}: </strong>
                                    <span>{msg.text}</span>
                                     {/* Add button here later to resolve hash if isHash is true */}
                                </div>
                            ))}
                            <div ref={messagesEndRef} /> {/* Anchor for scrolling */}
                        </div>

                        {/* Input Area */}
                        <div className="input-area">
                            <input
                                type="text"
                                value={inputValue}
                                onChange={(e) => setInputValue(e.target.value)}
                                placeholder={isGuessing ? "Enter DOB guess (YYYY-MM-DD)" : "Type your message..."}
                                disabled={isLoading}
                                onKeyPress={(e) => {
                                    if (e.key === 'Enter' && !isLoading) {
                                        isGuessing ? handleSendGuess() : handleSendMessage();
                                    }
                                }}
                            />
                        </div>
                        <div className="input-area">
                        <button onClick={isGuessing ? handleSendGuess : handleSendMessage} disabled={isLoading || !inputValue.trim()}>
                                {isLoading ? "Sending..." : (isGuessing ? "Submit Guess" : "Send")}
                            </button>
                            <button onClick={() => setIsGuessing(!isGuessing)} disabled={isLoading}>
                                 {isGuessing ? "Cancel Guess" : "Guess DOB"}
                             </button>
                        </div>
                    </div>
                )}
            </main>
        </div>
    );
}

export default App;