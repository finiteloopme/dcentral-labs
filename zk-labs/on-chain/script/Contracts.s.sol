// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import {NFT} from "../src/nft-erc721.sol";
import {ZKProof} from "../src/zkproof-erc20.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        NFT eggNft = new NFT("EggNFT", 
                            "EGG",
                            "https://storage.googleapis.com/zk-super-dash/egg.json");        
        NFT feaNft = new NFT(
                            "FeatherNFT", 
                            "FEA",
                            "https://storage.googleapis.com/zk-super-dash/feather.json");
        ZKProof token = new ZKProof("ZKProof", "ZKP");

        vm.stopBroadcast();
    }
}
