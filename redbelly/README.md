
# Actors

| Name | Role | Key | Description |
|---|---|---|---|
| Ashley | Owner Asset Manager Contract | `0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80` | Deploys the Asset Manager Contract |
| James Bond | Owner Sovereign Bonds Contract | `0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d` | Deploys the Sovereign Bonds |
| Sam Stocks | Owner Stocks Bond Contract | `0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a` | Deploys the Stocks |
| Steve Koins | Owner Stable Coin Contract | `0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6` | Deploys the Stable Coins |

# Steps

Open 3 terminals:

1. To start the chain: `cd porfolio-manager; make start-chain`
2. To deploy the contracts: `cd porfolio-manager; make deploy-all`
3. To start the agent: `cd ai-manager/app; make run-agent`
4. Open frontend at http://localhost:8000


# User stories

1. Ashley deploys a contract for Asset Manager - Super Fund
2. Sam uses wallet (key) to subscribe to Super Fund
3. Sam selects risk profile for the agent: low, medium, high
4. Sam can list assets registered in Super Fund
5. Sam can buy or sell specific assets registered in Super
6. Sam can view current portfolio
7. Sam can rebalance the portfolio based on the selected risk profile
8. When a new asset is registered, Sam is notified
9. Sam's portfolio is automatically rebalanced when a new asset is registered