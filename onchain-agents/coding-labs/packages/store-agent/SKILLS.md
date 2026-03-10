# Store Agent Skills Reference

This document describes the Store Agent's capabilities for the mock stationery web store.

## Overview

The Store Agent manages a catalog of stationery items and handles the purchase flow using the x402 payment protocol.

## Skills

### browse
Browse and search the stationery catalog. Supports category filtering and text search.
- Categories: notebooks, pens, pencils, erasers, markers, paper, accessories
- Returns formatted table with item names, prices, and stock status

### item-detail
Get detailed information about a specific item including full description, price, and availability.

### purchase
Initiate a purchase. Creates an order and returns x402 PaymentRequired information including:
- Network (CAIP-2 format, e.g., eip155:84532 for Base Sepolia)
- Scheme (exact)
- Payment destination address
- USDC asset contract address
- Amount in USDC

### confirm
Confirm a purchase after payment. Requires order ID and transaction hash.

## x402 Payment Integration

The store uses the x402 protocol (HTTP 402 Payment Required) for payments:
1. User requests a purchase → store returns PaymentRequired with USDC payment details
2. User pays via the Payment Agent → receives transaction hash
3. User confirms purchase with transaction hash → store verifies and confirms order

## Catalog

The store maintains a hardcoded catalog of stationery items with prices in USDC (6 decimal stablecoin).
