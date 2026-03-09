# Payment Agent Skills Reference

This document describes the Payment Agent's capabilities for x402 protocol-based payments.

## Overview

The Payment Agent handles crypto payments using the x402 protocol. It serves dual roles:
1. **Facilitator**: HTTP endpoints for payment verification and settlement
2. **Buyer-side agent**: Conversational A2A skills for handling payments on behalf of users

## Skills

### pay
Execute a payment for a store order. Reads x402 PaymentRequired details, creates an EIP-3009
transferWithAuthorization signature request, and submits to the facilitator for settlement.

### verify-payment
Verify payment details without settling. Checks:
- Network is supported
- Payment scheme is supported
- PayTo address is valid
- Price is non-zero
- Wallet is connected

### payment-status
Check the status of a specific payment or view all payment history.

### supported
List supported blockchain networks, payment schemes, and facilitator configuration.

## x402 Protocol

The x402 protocol uses HTTP 402 Payment Required to enable programmatic payments:
1. Client requests resource → Server returns 402 with PaymentRequired
2. Client signs payment authorization (EIP-3009 transferWithAuthorization)
3. Client retries with PAYMENT-SIGNATURE header
4. Server verifies via facilitator → settles payment → returns resource

## Supported Networks
- Base Sepolia (eip155:84532) — Testnet, via x402.org facilitator
- Base Mainnet (eip155:8453) — Production, via x402.org facilitator
- Ethereum Mainnet (eip155:1) — Production, via Primev facilitator (preconfirmations)

## Facilitator Endpoints
- POST /x402/verify — Verify payment payload
- POST /x402/settle — Settle payment on-chain
- GET /x402/supported — List supported networks and schemes
