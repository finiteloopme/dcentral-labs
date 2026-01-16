// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Counter
/// @notice A simple counter contract for demonstration
contract Counter {
    uint256 public number;

    event NumberChanged(uint256 oldNumber, uint256 newNumber);

    /// @notice Set the counter to a specific value
    /// @param newNumber The new value for the counter
    function setNumber(uint256 newNumber) public {
        uint256 oldNumber = number;
        number = newNumber;
        emit NumberChanged(oldNumber, newNumber);
    }

    /// @notice Increment the counter by 1
    function increment() public {
        uint256 oldNumber = number;
        number++;
        emit NumberChanged(oldNumber, number);
    }

    /// @notice Decrement the counter by 1
    function decrement() public {
        require(number > 0, "Counter: cannot decrement below zero");
        uint256 oldNumber = number;
        number--;
        emit NumberChanged(oldNumber, number);
    }
}
