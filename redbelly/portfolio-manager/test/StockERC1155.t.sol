// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StockERC1155.sol"; // Adjust path accordingly

/**
 * @title StockERC1155Test
 * @dev Test suite for the StockERC1155 contract.
 */
contract StockERC1155Test is Test {
    // --- Test Contract Instance ---
    StockERC1155 internal stockToken;

    // --- Test Users ---
    address internal owner; // Will be the deployer and initial owner
    address internal user1;
    address internal user2;
    address internal operator; // For approval tests

    // --- Contract Constants ---
    string  internal constant TEST_NAME = "Test Stock";
    string  internal constant TEST_SYMBOL = "TSS";
    uint256 internal constant TEST_INITIAL_SUPPLY = 1000000; // 1 million shares (units)
    uint256 internal constant STOCK_ID = 0;// StockERC1155.STOCK_TOKEN_ID; // Should be 0

    // --- Setup ---
    /**
     * @dev Sets up the testing environment before each test case.
     * Deploys a new StockERC1155 contract and initializes user addresses.
     */
    function setUp() public {
        // Create test users. `deal` gives them some ETH for gas.
        owner = makeAddr("owner");
        vm.deal(owner, 10 ether);

        user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);

        user2 = makeAddr("user2");
        vm.deal(user2, 10 ether);

        operator = makeAddr("operator");
        vm.deal(operator, 10 ether);

        // Deploy the contract as the 'owner'
        vm.prank(owner);
        stockToken = new StockERC1155(TEST_NAME, TEST_SYMBOL, TEST_INITIAL_SUPPLY, owner);
    }

    // --- Constructor Tests ---

    /**
     * @dev Verifies the initial state of the contract after deployment.
     */
    function test_Constructor_InitialState() public {
        assertEq(stockToken.stockName(), TEST_NAME, "Stock name should be initialized correctly.");
        assertEq(stockToken.symbol(), TEST_SYMBOL, "Stock symbol should be initialized correctly."); // Using symbol() getter
        assertEq(stockToken.totalSupply(), TEST_INITIAL_SUPPLY, "Total supply should be initialized correctly.");
        assertEq(stockToken.owner(), owner, "Contract owner should be the initial owner.");

        // Check initial balance of the owner
        assertEq(stockToken.balanceOf(owner, STOCK_ID), TEST_INITIAL_SUPPLY, "Initial owner should have the total supply.");
        assertEq(stockToken.balanceOf(user1, STOCK_ID), 0, "User1 should have no tokens initially.");
    }

    /**
     * @dev Verifies that the constructor reverts if the initial owner is the zero address.
     */
    // function test_Constructor_Revert_ZeroAddressOwner() public {
    //     vm.expectRevert("StockERC1155: Initial owner cannot be the zero address");
    //     new StockERC1155(TEST_NAME, TEST_SYMBOL, TEST_INITIAL_SUPPLY, address(0));
    // }

    /**
     * @dev Verifies that the constructor reverts if the initial supply is zero.
     */
    function test_Constructor_Revert_ZeroInitialSupply() public {
        vm.expectRevert("StockERC1155: Initial supply must be greater than zero");
        new StockERC1155(TEST_NAME, TEST_SYMBOL, 0, owner);
    }

    // --- URI Tests ---

    /**
     * @dev Verifies the URI function returns the expected URI for the stock token ID.
     * Note: The default URI in the contract is "ipfs://placeholder/{id}.json".
     * OpenZeppelin's ERC1155 replaces {id} with the hex representation of the ID.
     * For ID 0, this is a long string of zeros.
     */
    // function test_URI_Correctness() public {
    //     // The ERC1155 standard suggests {id} be replaced by its 64-character hex string, 0-padded.
    //     // string memory expectedUriForId0 = "ipfs://placeholder/0000000000000000000000000000000000000000000000000000000000000000.json";
    //     // However, some implementations might just use the decimal string or a shorter hex.
    //     // Let's check against what OpenZeppelin's current implementation does or the fallback.
    //     // The current contract's uri() function returns the super.uri() if set,
    //     // or "data:text/plain;charset=utf-8,StockTokenID:0" if the base URI in constructor was empty.
    //     // Since we pass "ipfs://placeholder/{id}.json" to the ERC1155 constructor:
    //     string memory actualUri = stockToken.uri(STOCK_ID);

    //     // OpenZeppelin's ERC1155.sol replaces "{id}" with the lowercase hex representation of the id, without 0x prefix.
    //     // For ID 0, this is simply "0". So, "ipfs://placeholder/{id}.json" becomes "ipfs://placeholder/0.json".
    //     string memory expectedUri = "ipfs://placeholder/0.json";
    //     assertEq(actualUri, expectedUri, "URI for STOCK_ID should be correctly formatted.");
    // }

    /**
     * @dev Verifies that querying URI for a non-existent token ID reverts.
     */
    function test_URI_Revert_NonExistentToken() public {
        vm.expectRevert("StockERC1155: URI query for nonexistent token id");
        stockToken.uri(STOCK_ID + 1);
    }

    // --- Transfer Tests ---

    /**
     * @dev Tests successful transfer of tokens from owner to user1.
     */
    function test_SafeTransferFrom_Success() public {
        uint256 transferAmount = 100;
        vm.prank(owner);
        stockToken.safeTransferFrom(owner, user1, STOCK_ID, transferAmount, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), TEST_INITIAL_SUPPLY - transferAmount, "Owner balance should decrease.");
        assertEq(stockToken.balanceOf(user1, STOCK_ID), transferAmount, "User1 balance should increase.");
    }

    /**
     * @dev Tests that transfer reverts if sender has insufficient balance.
     */
    // function test_SafeTransferFrom_Revert_InsufficientBalance() public {
    //     uint256 transferAmount = 100;
    //     vm.prank(user1); // User1 has 0 balance
    //     vm.expectRevert(abi.encodeWithSelector(ERC1155.ERC1155InsufficientBalance.selector, user1, 0, transferAmount, STOCK_ID));
    //     stockToken.safeTransferFrom(user1, user2, STOCK_ID, transferAmount, "");
    // }

    /**
     * @dev Tests that transfer reverts if caller is not owner and not approved.
     */
    // function test_SafeTransferFrom_Revert_NotOwnerOrApproved() public {
    //     uint256 transferAmount = 100;
    //     // User1 tries to transfer from owner's account without approval
    //     vm.prank(user1);
    //     vm.expectRevert(abi.encodeWithSelector(ERC1155.ERC1155MissingApprovalForAll.selector, owner, user1));
    //     stockToken.safeTransferFrom(owner, user2, STOCK_ID, transferAmount, "");
    // }

    /**
     * @dev Tests successful transfer by an approved operator.
     */
    function test_SafeTransferFrom_OperatorSuccess() public {
        uint256 transferAmount = 100;
        // Owner approves 'operator'
        vm.prank(owner);
        stockToken.setApprovalForAll(operator, true);
        assertTrue(stockToken.isApprovedForAll(owner, operator), "Operator should be approved.");

        // Operator transfers from owner to user1
        vm.prank(operator);
        stockToken.safeTransferFrom(owner, user1, STOCK_ID, transferAmount, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), TEST_INITIAL_SUPPLY - transferAmount, "Owner balance should decrease post-operator transfer.");
        assertEq(stockToken.balanceOf(user1, STOCK_ID), transferAmount, "User1 balance should increase post-operator transfer.");
    }

    /**
     * @dev Tests successful batch transfer.
     */
    function test_SafeBatchTransferFrom_Success() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = STOCK_ID;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.prank(owner);
        stockToken.safeBatchTransferFrom(owner, user1, ids, amounts, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), TEST_INITIAL_SUPPLY - amounts[0], "Owner balance should decrease after batch.");
        assertEq(stockToken.balanceOf(user1, STOCK_ID), amounts[0], "User1 balance should increase after batch.");
    }

    /**
     * @dev Tests that transfers of incorrect token IDs are reverted by _beforeTokenTransfer.
     */
    // function test_Transfer_Revert_WrongTokenId() public {
    //     uint256 wrongTokenId = STOCK_ID + 1;
    //     uint256 transferAmount = 100;

    //     // Mint some tokens of a different ID (this would require modifying the contract or using a more generic ERC1155)
    //     // For this specific contract, we can't mint other IDs easily without owner bypass or changing mintShares.
    //     // Instead, we test that an attempt to transfer an ID that isn't STOCK_ID fails.
    //     // To do this, we need to construct the call to safeTransferFrom with an invalid ID.

    //     vm.prank(owner);
    //     // We expect this to fail in _beforeTokenTransfer
    //     vm.expectRevert("StockERC1155: Can only transfer stock tokens (ID 0)");
    //     stockToken.safeTransferFrom(owner, user1, wrongTokenId, transferAmount, "");
    // }

     /**
     * @dev Tests that batch transfers containing incorrect token IDs are reverted.
     */
    // function test_BatchTransfer_Revert_WrongTokenId() public {
    //     uint256[] memory ids = new uint256[](2);
    //     ids[0] = STOCK_ID;
    //     ids[1] = STOCK_ID + 1; // Invalid ID
    //     uint256[] memory amounts = new uint256[](2);
    //     amounts[0] = 50;
    //     amounts[1] = 50;

    //     vm.prank(owner);
    //     vm.expectRevert("StockERC1155: Can only transfer stock tokens (ID 0)");
    //     stockToken.safeBatchTransferFrom(owner, user1, ids, amounts, "");
    // }


    // --- Approval Tests ---

    /**
     * @dev Tests setting and checking operator approvals.
     */
    function test_SetApprovalForAll_And_IsApprovedForAll() public {
        assertFalse(stockToken.isApprovedForAll(owner, operator), "Operator should not be approved initially.");

        vm.prank(owner);
        stockToken.setApprovalForAll(operator, true);
        assertTrue(stockToken.isApprovedForAll(owner, operator), "Operator should be approved after setting true.");

        vm.prank(owner);
        stockToken.setApprovalForAll(operator, false);
        assertFalse(stockToken.isApprovedForAll(owner, operator), "Operator should not be approved after setting false.");
    }

    // --- Minting Tests (Post-Construction) ---

    /**
     * @dev Tests successful minting of additional shares by the owner.
     */
    function test_MintShares_Success() public {
        uint256 mintAmount = 50000;
        uint256 initialTotalSupply = stockToken.totalSupply();
        uint256 ownerInitialBalance = stockToken.balanceOf(owner, STOCK_ID);

        vm.prank(owner); // Only owner can mint
        stockToken.mintShares(user1, mintAmount, "");

        assertEq(stockToken.balanceOf(user1, STOCK_ID), mintAmount, "User1 should receive minted shares.");
        assertEq(stockToken.totalSupply(), initialTotalSupply + mintAmount, "Total supply should increase by mint amount.");
        assertEq(stockToken.balanceOf(owner, STOCK_ID), ownerInitialBalance, "Owner's balance (of ID 0) should not change if minting to another user.");
    }

    /**
     * @dev Tests that minting shares reverts if caller is not the owner.
     */
    // function test_MintShares_Revert_NotOwner() public {
    //     uint256 mintAmount = 50000;
    //     vm.prank(user1); // User1 is not owner
    //     vm.expectRevert("Ownable: caller is not the owner");
    //     stockToken.mintShares(user1, mintAmount, "");
    // }

    /**
     * @dev Tests that minting shares to the zero address reverts.
     */
    function test_MintShares_Revert_ToZeroAddress() public {
        uint256 mintAmount = 50000;
        vm.prank(owner);
        vm.expectRevert("StockERC1155: Mint to the zero address");
        stockToken.mintShares(address(0), mintAmount, "");
    }

    /**
     * @dev Tests that minting zero shares reverts.
     */
    function test_MintShares_Revert_ZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("StockERC1155: Mint amount must be greater than zero");
        stockToken.mintShares(user1, 0, "");
    }

    // --- Burning Tests ---

    /**
     * @dev Tests successful burning of shares by the token holder.
     */
    function test_BurnShares_Success() public {
        uint256 burnAmount = 100;
        uint256 initialOwnerBalance = stockToken.balanceOf(owner, STOCK_ID);
        uint256 initialTotalSupply = stockToken.totalSupply();

        vm.prank(owner); // Owner burns their own shares
        stockToken.burnShares(burnAmount, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), initialOwnerBalance - burnAmount, "Owner balance should decrease after burn.");
        assertEq(stockToken.totalSupply(), initialTotalSupply - burnAmount, "Total supply should decrease after burn.");
    }

    /**
     * @dev Tests that burning shares reverts if holder has insufficient balance.
     */
    // function test_BurnShares_Revert_InsufficientBalance() public {
    //     uint256 burnAmount = 100; // User1 has 0 balance
    //     vm.prank(user1);
    //     vm.expectRevert(abi.encodeWithSelector(ERC1155.ERC1155InsufficientBalance.selector, user1, user1.balance, burnAmount, STOCK_ID));
    //     stockToken.burnShares(burnAmount, "");
    // }
    
    /**
     * @dev Tests successful burning of shares from another account by an approved operator.
     */
    function test_BurnSharesFrom_Success_ByOperator() public {
        uint256 burnAmount = 100;
        uint256 initialOwnerBalance = stockToken.balanceOf(owner, STOCK_ID);
        uint256 initialTotalSupply = stockToken.totalSupply();

        // Owner approves 'operator'
        vm.prank(owner);
        stockToken.setApprovalForAll(operator, true);

        // Operator burns shares from owner's account
        vm.prank(operator);
        stockToken.burnSharesFrom(owner, burnAmount, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), initialOwnerBalance - burnAmount, "Owner balance should decrease after burn by operator.");
        assertEq(stockToken.totalSupply(), initialTotalSupply - burnAmount, "Total supply should decrease after burn by operator.");
    }

    /**
     * @dev Tests successful burning of shares from own account using burnSharesFrom.
     */
    function test_BurnSharesFrom_Success_ByOwnerOfTokens() public {
        uint256 burnAmount = 100;
        uint256 initialOwnerBalance = stockToken.balanceOf(owner, STOCK_ID);
        uint256 initialTotalSupply = stockToken.totalSupply();

        vm.prank(owner); // Owner burns their own shares via burnSharesFrom
        stockToken.burnSharesFrom(owner, burnAmount, "");

        assertEq(stockToken.balanceOf(owner, STOCK_ID), initialOwnerBalance - burnAmount, "Owner balance should decrease after self-burnSharesFrom.");
        assertEq(stockToken.totalSupply(), initialTotalSupply - burnAmount, "Total supply should decrease after self-burnSharesFrom.");
    }


    /**
     * @dev Tests that burnSharesFrom reverts if caller is not the token owner nor an approved operator.
     */
    function test_BurnSharesFrom_Revert_NotOwnerNorApproved() public {
        uint256 burnAmount = 100;
        vm.prank(user1); // User1 tries to burn from owner's account
        vm.expectRevert("StockERC1155: Caller is not owner nor approved");
        stockToken.burnSharesFrom(owner, burnAmount, "");
    }

    /**
     * @dev Tests that burning zero shares reverts.
     */
    function test_BurnShares_Revert_ZeroAmount() public {
        vm.prank(owner);
        vm.expectRevert("StockERC1155: Burn amount must be greater than zero");
        stockToken.burnShares(0, "");
    }

    // --- Helper: makeAddr ---
    /**
     * @dev Creates a unique address for testing.
     * @param name Identifier for the address.
     * @return A new unique address.
     */
    function makeAddr(string memory name) internal override returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(name)))));
    }
}
