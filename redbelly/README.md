
# Actors

| Name | Role | Key | Description |
|---|---|---|---|
| Ashley | Owner Asset Manager Contract | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | Deploys the Asset Manager Contract |
| James Bond | Owner Sovereign Bonds Contract | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | Deploys the Sovereign Bonds |
| Sam Stocks | Owner Stocks Bond Contract | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | Deploys the Stocks |
| Steve Koins | Owner Stable Coin Contract | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | Deploys the Stable Coins |

# Steps

1. `make start-chain`
2. `make deploy-rwa`
3. Copy the address of RWA contract into `script/DeploySovereginBondERC1155.s.sol`
4. `make deploy-sovereign`
5. 