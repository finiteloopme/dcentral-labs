// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TokenUSDC
 * @author Your Name
 * @notice A simple ERC20 token used for demonstration purposes within this project.
 * @dev This contract inherits from OpenZeppelin's standard `ERC20` implementation
 * for token functionality and `Ownable` for access control on the minting function.
 */
contract TokenUSDC is ERC20, Ownable {
    /**
     * @notice The constructor initializes the ERC20 token with a name and symbol,
     * sets the deployer as the owner, and mints an initial supply of tokens
     * to the owner's address.
     * @param initialSupply The amount of tokens to mint to the contract deployer upon creation.
     */
    constructor(
        uint256 initialSupply
    ) ERC20("Token USDC", "tUSDC") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    /**
     * @notice Allows the owner of the contract to mint new tokens.
     * @dev This is a privileged function restricted to the `onlyOwner`.
     * @param to The address to which new tokens will be minted.
     * @param amount The amount of new tokens to mint.
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
