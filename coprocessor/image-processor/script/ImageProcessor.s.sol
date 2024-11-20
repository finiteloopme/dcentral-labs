// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ImageProcessor} from "../src/ImageProcessor.sol";

contract ImageProcessorScript is Script {
    ImageProcessor public imageProcessor;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        imageProcessor = new ImageProcessor();
        console.log("ImageProcessor deployed at:", address(imageProcessor));

        vm.stopBroadcast();
    }
}