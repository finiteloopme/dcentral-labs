# Foundry Project

A smart contract project built with Foundry.

## Getting Started

### Build

```shell
forge build
```

### Test

```shell
forge test
```

### Format

```shell
forge fmt
```

### Gas Snapshots

```shell
forge snapshot
```

### Deploy

```shell
# Set your private key
export PRIVATE_KEY=0x...

# Deploy to local node
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to network (replace with your RPC URL)
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast --verify
```

## Documentation

- [Foundry Book](https://book.getfoundry.sh/)
