/**
 * BitVM3 TypeScript SDK Client
 * Connects to the Rust backend API
 */

import axios, { AxiosInstance } from 'axios';

export interface ClientConfig {
  endpoint: string;
  apiKey?: string;
  timeout?: number;
}

export interface DepositRequest {
  participant: string;
  amount: number;
  currency: 'BTC' | 'USDT';
}

export interface WithdrawRequest {
  participant: string;
  amount: number;
  currency: 'BTC' | 'USDT';
}

export interface VaultState {
  totalBtc: number;
  totalUsdt: number;
  blockHeight: number;
  stateRoot: string;
  activePositions: number;
}

export interface ChallengeRequest {
  challenger: string;
  disputedTx: string;
  evidence: string;
}

export class BitVM3Client {
  private client: AxiosInstance;

  constructor(config: ClientConfig) {
    this.client = axios.create({
      baseURL: `${config.endpoint}/api/v1`,
      timeout: config.timeout || 30000,
      headers: {
        'Content-Type': 'application/json',
        ...(config.apiKey && { 'X-API-Key': config.apiKey })
      }
    });

    // Add request interceptor for logging
    this.client.interceptors.request.use(
      (config) => {
        console.log(`🚀 ${config.method?.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        console.error('❌ Request error:', error);
        return Promise.reject(error);
      }
    );

    // Add response interceptor for error handling
    this.client.interceptors.response.use(
      (response) => {
        console.log(`✅ Response:`, response.status);
        return response;
      },
      (error) => {
        console.error('❌ Response error:', error.response?.data || error.message);
        return Promise.reject(error);
      }
    );
  }

  /**
   * Check API health
   */
  async health(): Promise<{ status: string; version: string }> {
    const response = await this.client.get('/health');
    return response.data;
  }

  /**
   * Deposit funds to vault
   */
  async deposit(request: DepositRequest): Promise<{
    success: boolean;
    newBalance: number;
    txId: string;
    stateRoot: string;
  }> {
    const response = await this.client.post('/deposit', request);
    return response.data;
  }

  /**
   * Withdraw funds from vault
   */
  async withdraw(request: WithdrawRequest): Promise<{
    success: boolean;
    proof: string;
    newBalance: number;
    computationTimeMs: number;
  }> {
    const response = await this.client.post('/withdraw', request);
    return response.data;
  }

  /**
   * Get current vault state
   */
  async getVaultState(): Promise<VaultState> {
    const response = await this.client.get('/vault/state');
    return response.data;
  }

  /**
   * Initiate a challenge
   */
  async challenge(request: ChallengeRequest): Promise<{
    challengeId: string;
    status: string;
    deadline: number;
  }> {
    const response = await this.client.post('/challenge', request);
    return response.data;
  }

  /**
   * Get participant information
   */
  async getParticipant(name: string): Promise<{
    name: string;
    address: string;
    balance: {
      btc: number;
      usdt: number;
    };
  }> {
    const response = await this.client.get(`/participant/${name}`);
    return response.data;
  }

  /**
   * Subscribe to WebSocket events
   */
  subscribeToEvents(onMessage: (event: any) => void): WebSocket {
    const wsUrl = this.client.defaults.baseURL!.replace('http', 'ws').replace('/api/v1', '/ws');
    const ws = new WebSocket(wsUrl);

    ws.onopen = () => {
      console.log('🔌 WebSocket connected');
    };

    ws.onmessage = (event) => {
      try {
        const data = JSON.parse(event.data);
        onMessage(data);
      } catch (error) {
        console.error('Failed to parse WebSocket message:', error);
      }
    };

    ws.onerror = (error) => {
      console.error('❌ WebSocket error:', error);
    };

    ws.onclose = () => {
      console.log('🔌 WebSocket disconnected');
    };

    return ws;
  }

  /**
   * Create a lending position
   */
  async createLendingPosition(request: {
    lender: string;
    borrower: string;
    amountUsdt: number;
    collateralBtc: number;
  }): Promise<{ positionId: string; status: string }> {
    const response = await this.client.post('/lending/create', request);
    return response.data;
  }

  /**
   * Repay a loan
   */
  async repayLoan(positionId: string, amount: number): Promise<{
    success: boolean;
    remainingDebt: number;
  }> {
    const response = await this.client.post(`/lending/${positionId}/repay`, { amount });
    return response.data;
  }

  /**
   * Check for liquidations
   */
  async checkLiquidations(): Promise<string[]> {
    const response = await this.client.post('/lending/liquidate');
    return response.data;
  }
}