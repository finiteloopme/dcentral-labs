
# Overview

Aim of this project is to record a player's in game activity like collection of coins and other artefacts as ERC20 (token) and ERC721 (NFT) assets on a blockchain.  

This player activity will create live traffic on the chain.  Type1 ZK proofs are generated for each block created on the network.

# Components

1. [Super Dash]: Game developed using Flutter
   > **Credit**: We have repurposed [this game](https://github.com/flutter/super_dash) for the demo.  
2. [Smart contracts]: ERC20 and ERC721 smart contracts to represent assets on the chain
3. [Backend services]: logic to (a) account/wallet management for players, (b) gateway to interact with the smart contracts, and (c) orchestrate interaction between in-game actions to on-chain activity

## Wiring the pieces

This section provides details of how all the components hang togther.

- [Super Dash] game is hardcoded as web only.  This web app gets deployed on firebase hosting platform.
- [account-mgmt] is used for manage wallet (publikey, ETH address, and privatekey) for each player.  It creates a wallet for each player if one doesn't exist.  And write the private key to Secret Manager.
- [game_bloc.dart] is used to update the score.  We have updated this logic to send a request to the backend that player has collected an item (coins, egg, feather, etc).
- [item-collected] is deployed as a cloud run instance which recieves the notification from [game_bloc.dart].  It writes the request to a pubsub topic `item-collected-topic`.  This component uses websockets to communivate with [game_bloc.dart]
- [orchestrator] is a golang orchestration microservice which is triggered by a message on `item-collected-topic`.  Orchestration logic used id:
   1. Use [account-mgmt] service to get ETH address for the required player
   2. Write an updated message with the players ETH address to pubsub topic `player-transfer-topic`
   3. Message on `player-transfer-topic` triggers [orchestrator] to actually transfer on-chain assets by invoking the [Smart contracts]

## Configuration & Setup

### Environment Variables

```bash
# Default GCP Project to use
export GCP_PROJECT=kunal-scratch
# User repository/collection in Firestore
export USER_REPO=users
export ITEM_COLLECTED_TOPIC=item-collected-topic
```

------
[Super Dash]: ./super_dash
[Smart contracts]: ./on-chain
[Backend services]: ./backend-services
[game_bloc.dart]: ./super_dash/lib/game/bloc/game_bloc.dart
[item-collected]: ./backend-services/send-to-chain
[orchestrator]: ./on-chain/go
[account-mgmt]: ./backend-services/account-mgmt
