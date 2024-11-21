// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ImageProcessor.sol";

contract ImageProcessorTest is Test {
    ImageProcessor public imageProcessor;
    address public user1;
    address public user2;
    address public coprocessor;

    function setUp() public {
        imageProcessor = new ImageProcessor();
        user1 = address(0x1);
        user2 = address(0x2);
        coprocessor = address(0x3);
    }

    function testCreateIcon() public {
        string memory prompt = "A beautiful sunset over the ocean";
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.GenerateIcon(prompt, user1);
        imageProcessor.createIcon(prompt);
    }

    function testSubmitIcon() public {
        string memory iconData = "base64encodedicondata";
        
        vm.prank(coprocessor);
        imageProcessor.submitIcon(user1, iconData);
        
        assertEq(imageProcessor.icons(user1), iconData, "Icon not correctly stored");
    }

    function testMultipleUsersCreateIcons() public {
        string memory prompt1 = "A majestic mountain range";
        string memory prompt2 = "A serene lake at dawn";
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.GenerateIcon(prompt1, user1);
        imageProcessor.createIcon(prompt1);
        
        vm.prank(user2);
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.GenerateIcon(prompt2, user2);
        imageProcessor.createIcon(prompt2);
    }

    function testSubmitMultipleIcons() public {
        string memory iconData1 = "base64encodedicondata1";
        string memory iconData2 = "base64encodedicondata2";
        
        vm.startPrank(coprocessor);
        imageProcessor.submitIcon(user1, iconData1);
        imageProcessor.submitIcon(user2, iconData2);
        vm.stopPrank();
        
        assertEq(imageProcessor.icons(user1), iconData1, "Icon for user1 not correctly stored");
        assertEq(imageProcessor.icons(user2), iconData2, "Icon for user2 not correctly stored");
    }

    function testOverwriteIcon() public {
        string memory iconData1 = "base64encodedicondata1";
        string memory iconData2 = "base64encodedicondata2";
        
        vm.prank(coprocessor);
        imageProcessor.submitIcon(user1, iconData1);
        
        assertEq(imageProcessor.icons(user1), iconData1, "Initial icon not correctly stored");
        
        vm.prank(coprocessor);
        imageProcessor.submitIcon(user1, iconData2);
        
        assertEq(imageProcessor.icons(user1), iconData2, "Icon not correctly overwritten");
    }
}