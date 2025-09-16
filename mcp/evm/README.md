# DeFi Trader

This project contains a MCP server `defi-trader` that can be used with the Gemini CLI.

## Project Structure

- `defi-trader`: A MCP server written in Rust that provides tools for swapping tokens on Uniswap V2, Curve, Balancer, and SushiSwap.

## Setup

### defi-trader

To run the `defi-trader` server, you need to have Rust installed. You can install it from [here](https://www.rust-lang.org/tools/install).

Once you have Rust installed, you can run the server using the following command:

```
make build-trader
make run-trader
```

The server will be running on `http://127.0.0.1:8000`.

You can then use the Gemini CLI to interact with the `defi-trader` server to get quotes and perform swaps.

## Available Tools

### `get_quote`

Returns a quote for a swap from a specific protocol.

#### Arguments

- `protocol`: The protocol to use for the swap. Can be `uniswap_v2`, `curve`, `balancer`, or `sushiswap`.
- `from_token`: The address of the token to swap from.
- `to_token`: The address of the token to swap to.
- `amount`: The amount of the `from_token` to swap.

### `swap`

Performs a swap on a specific protocol.

#### Arguments

- `protocol`: The protocol to use for the swap. Can be `uniswap_v2`, `curve`, `balancer`, or `sushiswap`.
- `from_token`: The address of the token to swap from.
- `to_token`: The address of the token to swap to.
- `amount`: The amount of the `from_token` to swap.