// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ComplianceRegistry.sol";

contract DeFiVault {
    IERC20 public usdcToken;
    ComplianceRegistry public complianceRegistry;
    
    uint256 public totalValueLocked;
    mapping(address => uint256) public userDeposits;
    
    address public owner;
    
    event Deposit(address indexed user, uint256 amount, bytes32 proofHash);
    event Withdrawal(address indexed user, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor(address _usdcToken, address _complianceRegistry) {
        usdcToken = IERC20(_usdcToken);
        complianceRegistry = ComplianceRegistry(_complianceRegistry);
        owner = msg.sender;
    }
    
    // For MVP, we accept any proof format but validate structure
    function deposit(uint256 amount, bytes calldata zkProof) external {
        require(amount > 0, "Amount must be > 0");
        require(zkProof.length > 0, "ZK proof required");
        
        // Check compliance (this would normally be done off-chain by TEE)
        require(
            complianceRegistry.checkCompliance(msg.sender), 
            "User not compliant"
        );
        
        // Transfer USDC from user to vault
        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
        
        // Update state
        userDeposits[msg.sender] += amount;
        totalValueLocked += amount;
        
        emit Deposit(msg.sender, amount, keccak256(zkProof));
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(userDeposits[msg.sender] >= amount, "Insufficient balance");
        
        // Update state
        userDeposits[msg.sender] -= amount;
        totalValueLocked -= amount;
        
        // Transfer USDC back to user
        require(
            usdcToken.transfer(msg.sender, amount),
            "Transfer failed"
        );
        
        emit Withdrawal(msg.sender, amount);
    }
    
    // Emergency functions for owner
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(usdcToken.transfer(owner, balance), "Transfer failed");
    }
    
    function updateComplianceRegistry(address _newRegistry) external onlyOwner {
        complianceRegistry = ComplianceRegistry(_newRegistry);
    }
}