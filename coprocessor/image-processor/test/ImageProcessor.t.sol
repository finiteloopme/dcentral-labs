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

    /// @notice Test uploading an image
    function testUploadImage() public {
        string memory imageData = "base64encodedimagedata";
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageData, user1);
        imageProcessor.uploadImage(imageData);
    }

    /// @notice Test submitting a result for an uploaded image
    function testSubmitResult() public {
        string memory result = "Analysis result for user1's image";
        
        vm.prank(coprocessor);
        imageProcessor.submitResult(user1, result);
        
        assertEq(imageProcessor.results(user1), result, "Result not correctly stored");
    }

    /// @notice Test submitting results for multiple users
    function testSubmitMultipleResults() public {
        string memory result1 = "Analysis result for user1's image";
        string memory result2 = "Analysis result for user2's image";
        
        vm.startPrank(coprocessor);
        imageProcessor.submitResult(user1, result1);
        imageProcessor.submitResult(user2, result2);
        vm.stopPrank();
        
        assertEq(imageProcessor.results(user1), result1, "Result for user1 not correctly stored");
        assertEq(imageProcessor.results(user2), result2, "Result for user2 not correctly stored");
    }

    /// @notice Test overwriting an existing result
    function testOverwriteResult() public {
        string memory result1 = "Initial analysis result";
        string memory result2 = "Updated analysis result";
        
        vm.startPrank(coprocessor);
        imageProcessor.submitResult(user1, result1);
        imageProcessor.submitResult(user1, result2);
        vm.stopPrank();
        
        assertEq(imageProcessor.results(user1), result2, "Result not correctly overwritten");
    }

    /// @notice Test uploading multiple images from the same user
    function testMultipleUploadsFromSameUser() public {
        string memory imageData1 = "base64encodedimagedata1";
        string memory imageData2 = "base64encodedimagedata2";
        
        vm.startPrank(user1);
        
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageData1, user1);
        imageProcessor.uploadImage(imageData1);
        
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageData2, user1);
        imageProcessor.uploadImage(imageData2);
        
        vm.stopPrank();
    }
}