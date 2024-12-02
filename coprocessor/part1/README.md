# How to run this sample code

## Pre-requisites

1. [The Rust Toolchain][1]
1. [Foundry][2]
   - **Anvil**: local node for testing contracts and interacting over RPC
   - **Cast**: command-line tool for performing Ethereum RPC calls
   - **Forge**: testing, building, and deploying smart contracts

## Steps

1. Build the code

   ```bash
   git clone https://github.com/finiteloopme/dcentral-labs/
   git checkout -b coprocessor-part1
   cd dcentral-labs/coprocessor/part1
   make test
   ```

2. Open 3 terminal windows

   1. Start the local chain

      ```bash
      # Terminal 1
      make start-chain
      ```

   2. Deploy the contract

      ```bash
      # Terminal 2
      make deploy
      ```

   3. Run the listener (coprocessor routine)

      ```bash
      # Terminal 3
      make run-listener
      ```

   4. Observe _Terminal 1_ shows only 1 transaction for contract deployment
   5. Upload an image to the contract

      ```bash
      # Terminal 2
      make upload-image
      ```

   6. Observe:
      - Terminal 1: a second transaction is recorded for image being uploaded to the contract
      - Terminal 1: a third transaction will soon follow.  Which is the coprocessor submiting the result of the analysis back onchain
      - Terminal 3: lists the image URL that will be analysed by the coprocessor

### Futher analysis

- `cast tx $TXN_ID` can be used to inspect input data for the transaction
- `cast pretty-calldata $INPUT_DATA` can be used to inspect the function call on the contract
- `cast calldata-decode $FUNCTION_SIGNATURE $INPUT_CALLDATA` can be used to decode the inputs used during function call

---
[1]: https://rustup.rs/
[2]: https://book.getfoundry.sh/
