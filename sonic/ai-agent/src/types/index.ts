// Add request/response body types if desired
export interface ChatRequestBody {
    sessionId: string;
    message: string;
}

export interface GuessRequestBody {
    sessionId: string;
    dobGuess: string;
}

// Simple in-memory store types
export interface SessionData {
    userAddress: string;
    history: { role: string; parts: { text: string }[] }[];
}
export type SessionStore = Record<string, SessionData>;
export type OffChainMessageStore = Record<string, string>; // hash -> message