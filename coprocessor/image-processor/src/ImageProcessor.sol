// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title ImageProcessor
/// @notice A contract for using GenAI to generate icons and storing them onchain
/// @dev This contract allows users to upload pompts for generating an icon and store the icon onchain
contract ImageProcessor {

    /// @notice Emitted when a generate icon request is received
    /// @param imagePrompt The prompt for generating an icon
    /// @param uploader The address of the user who requested the icon
    event GenerateIcon(string imagePrompt, address uploader);

    /// @notice Mapping to store icons for each uploader
    /// @dev Key is the uploader's address, value is the icon
    mapping(address => string) public icons; 

    /// @notice Receives a request to generate an icon
    /// @param imagePrompt The prompt for generating an icon
    /// @dev Emits an ImageUploaded event
    function createIcon(string memory imagePrompt) public {
        emit GenerateIcon(imagePrompt, msg.sender);
    }

    /// @notice Stores the generated icon onchain
    /// @param uploader The address of the user who uploaded the image
    /// @param iconData file content representing the generated icon
    /// @dev This function should be called by an authorized coprocessor
    function submitIcon(address uploader, string memory iconData) public {
        // Add authentication or authorization here to ensure only the 
        // coprocessor can call this function
        icons[uploader] = iconData;
    }
}