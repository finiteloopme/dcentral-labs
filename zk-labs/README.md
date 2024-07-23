
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

- [Super dash] game is hardcoded as web only.  This web app gets deployed on firebase hosting platform.
- [game_bloc.dart] is used to update the score.  We have updated this logic to send a request to the backend that player has collected an item (coins, egg, feather, etc).
- [item-collected] is deployed as a cloud run instance which recieves the notification from [game_bloc.dart].  It writes the request to a pubsub topic.  This component uses websockets to communivate with [game_bloc.dart]

------
[Super Dash]: ./super_dash
[Smart contracts]: ./on-chain
[Backend services]: ./backend-services
[game_bloc.dart]: ./super_dash/lib/game/bloc/game_bloc.dart
[item-collected]: ./backend-services/send-to-chain
