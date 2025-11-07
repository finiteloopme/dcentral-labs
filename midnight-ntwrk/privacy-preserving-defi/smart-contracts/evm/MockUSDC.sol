// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {
        // Mint 1 billion USDC to deployer
        _mint(msg.sender, 1_000_000_000 * 10**6);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    // Mint function for testing
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}