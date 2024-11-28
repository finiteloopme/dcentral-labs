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

    /// @notice Test uploading an image URL
    function testUploadImage() public {
        string memory imageUrl = "https://example.com/image1.jpg";
        
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageUrl, user1);
        imageProcessor.uploadImage(imageUrl);
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

    /// @notice Test uploading multiple image URLs from the same user
    function testMultipleUploadsFromSameUser() public {
        string memory imageUrl1 = "https://example.com/image1.jpg";
        string memory imageUrl2 = "https://example.com/image2.jpg";
        
        vm.startPrank(user1);
        
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageUrl1, user1);
        imageProcessor.uploadImage(imageUrl1);
        
        vm.expectEmit(true, true, false, true);
        emit ImageProcessor.ImageUploaded(imageUrl2, user1);
        imageProcessor.uploadImage(imageUrl2);
        
        vm.stopPrank();
    }
}