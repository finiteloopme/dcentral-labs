// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ComplianceRegistry {
    mapping(address => bool) public isCompliant;
    address public owner;
    
    event ComplianceStatusChanged(address indexed user, bool compliant);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Add some default compliant users for testing
        isCompliant[0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266] = true;
        isCompliant[0x70997970C51812dc3A010C7d01b50e0d17dc79C8] = true;
    }
    
    function setCompliant(address user, bool compliant) external onlyOwner {
        isCompliant[user] = compliant;
        emit ComplianceStatusChanged(user, compliant);
    }
    
    function checkCompliance(address user) external view returns (bool) {
        return isCompliant[user];
    }
}