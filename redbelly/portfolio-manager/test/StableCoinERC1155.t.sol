
// File: test/StableCoin.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/StableCoinERC1155.sol"; // Adjust path if your contract is elsewhere

/**
 * @title TestStableCoin
 * @dev Unit tests for the StableCoin contract.
 */
contract StableCoinTest is Test {
    StableCoin stableCoin;
    address owner = address(0x1); // Test owner, make it more realistic
    address user1 = vm.addr(0x2); // Use vm.addr for more distinct test addresses
    address user2 = vm.addr(0x3);
    address operator = vm.addr(0x4); // For approval tests
    address maliciousActor = vm.addr(0x5);

    string constant TOKEN_NAME = "My Stable Dollar";
    string constant TOKEN_SYMBOL = "MUSD";
    string constant FIAT_PEG = "USD";
    string constant INITIAL_URI = "https://api.example.com/token/musd.json";
    string constant NEW_URI = "https://api.newexample.com/token/musd_v2.json";

    uint256 constant STABLECOIN_ID_TEST = 0; // Should match StableCoin.STABLECOIN_ID
    uint256 mintAmount = 1000 * (10**18); // 1000 tokens with 18 decimals
    uint256 transferAmount = 100 * (10**18);
    uint256 burnAmount = 50 * (10**18);

    event TokensMinted(address indexed to, uint256 amount);
    event TokensBurned(address indexed from, uint256 amount);
    // Standard ERC1155 events
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);


    function setUp() public {
        vm.startPrank(owner); // Set msg.sender to owner for deployment
        stableCoin = new StableCoin(owner, TOKEN_NAME, TOKEN_SYMBOL, FIAT_PEG, INITIAL_URI);
        vm.stopPrank();
    }

    // --- Constructor Tests ---

    function test_Constructor_SetsCorrectValues() public {
        assertEq(stableCoin.name(), TOKEN_NAME, "Name should be set correctly");
        assertEq(stableCoin.symbol(), TOKEN_SYMBOL, "Symbol should be set correctly");
        assertEq(stableCoin.fiatPeggedTo(), FIAT_PEG, "Fiat peg should be set correctly");
        assertEq(stableCoin.owner(), owner, "Owner should be set correctly");
        assertEq(stableCoin.uri(STABLECOIN_ID_TEST), INITIAL_URI, "Initial URI should be set");
        assertEq(stableCoin.decimals(), 18, "Decimals should be 18");
        assertEq(stableCoin.totalSupply(), 0, "Initial total supply should be 0");
    }

    function test_Constructor_StablecoinIdIsZero() public {
        assertEq(stableCoin.STABLECOIN_ID(), 0, "STABLECOIN_ID should be 0");
    }

    // --- URI Tests ---
    function test_SetURI_OwnerCanUpdateURI() public {
        vm.prank(owner);
        stableCoin.setURI(NEW_URI);
        assertEq(stableCoin.uri(STABLECOIN_ID_TEST), NEW_URI, "URI should be updated by owner");
    }

    function test_SetURI_FailsIfNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, maliciousActor));
        vm.prank(maliciousActor);
        stableCoin.setURI(NEW_URI);
    }

    function test_URI_FailsForInvalidId() public {
        vm.expectRevert(bytes("StableCoin: invalid token ID"));
        stableCoin.uri(STABLECOIN_ID_TEST + 1);
    }


    // --- Minting Tests ---

    function test_Mint_OwnerCanMint() public {
        vm.startPrank(owner);
        stableCoin.mint(user1, mintAmount, "");
        vm.stopPrank();

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount, "User1 balance should be mintAmount");
        assertEq(stableCoin.balanceOf(owner, STABLECOIN_ID_TEST), 0, "Owner balance should be 0 after minting to user1");
        assertEq(stableCoin.totalSupply(), mintAmount, "Total supply should increase after minting");
    }

    // function test_Mint_EmitsTokensMintedAndTransferSingleEvents() public {
    //     vm.prank(owner);
    //     vm.expectEmit(true, false, false, true, address(stableCoin)); // TokensMinted: to is indexed
    //     emit TokensMinted(user1, mintAmount);
    //     vm.expectEmit(true, true, true, true, address(stableCoin)); // TransferSingle: operator, from, to are indexed
    //     emit TransferSingle(owner, address(0), user1, STABLECOIN_ID_TEST, mintAmount);
    //     stableCoin.mint(user1, mintAmount, "");
    // }

    function test_Mint_FailsIfNotOwner() public {
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, maliciousActor));
        vm.prank(maliciousActor);
        stableCoin.mint(user1, mintAmount, "");
    }

    function test_Mint_FailsIfToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(bytes("StableCoin: mint to the zero address"));
        stableCoin.mint(address(0), mintAmount, "");
    }

    function test_Mint_FailsIfAmountIsZero() public {
        vm.prank(owner);
        vm.expectRevert(bytes("StableCoin: mint amount must be greater than zero"));
        stableCoin.mint(user1, 0, "");
    }

    // --- Burning Tests by Owner ---

    function test_Burn_OwnerCanBurnOwnTokens() public {
        vm.startPrank(owner);
        stableCoin.mint(owner, mintAmount, ""); // Mint to owner first
        assertEq(stableCoin.balanceOf(owner, STABLECOIN_ID_TEST), mintAmount, "Owner initial balance incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount, "Total supply after mint incorrect");

        stableCoin.burn(owner, burnAmount);
        vm.stopPrank();

        assertEq(stableCoin.balanceOf(owner, STABLECOIN_ID_TEST), mintAmount - burnAmount, "Owner balance after burn incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount - burnAmount, "Total supply after burn incorrect");
    }

     function test_Burn_OwnerCanBurnOtherUserTokens() public {
        vm.startPrank(owner);
        stableCoin.mint(user1, mintAmount, "");
        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount, "User1 initial balance incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount, "Total supply after mint incorrect");

        stableCoin.burn(user1, burnAmount); // Owner burns user1's tokens
        vm.stopPrank();

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - burnAmount, "User1 balance after owner burn incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount - burnAmount, "Total supply after owner burn incorrect");
    }


    // function test_Burn_EmitsTokensBurnedAndTransferSingleEvents() public {
    //     vm.startPrank(owner);
    //     stableCoin.mint(owner, mintAmount, "");

    //     vm.expectEmit(true, false, false, true, address(stableCoin)); // TokensBurned: from is indexed
    //     emit TokensBurned(owner, burnAmount);
    //     vm.expectEmit(true, true, true, true, address(stableCoin)); // TransferSingle: operator, from, to are indexed
    //     emit TransferSingle(owner, owner, address(0), STABLECOIN_ID_TEST, burnAmount);
    //     stableCoin.burn(owner, burnAmount);
    //     vm.stopPrank();
    // }

    function test_Burn_FailsIfNotOwner() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, ""); // Mint some tokens to user1

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, maliciousActor));
        vm.prank(maliciousActor);
        stableCoin.burn(user1, burnAmount);
    }

    function test_Burn_FailsIfFromZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert(bytes("StableCoin: burn from the zero address"));
        stableCoin.burn(address(0), burnAmount);
    }

    // function test_Burn_FailsIfInsufficientBalance() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, burnAmount - 1, ""); // Mint less than burnAmount
    //     vm.expectRevert(bytes("StableCoin: insufficient balance to burn"));
    //     stableCoin.burn(user1, burnAmount);
    // }

    // --- Burning Tests by User (burnFrom) ---

    function test_BurnFrom_UserCanBurnOwnTokens() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, ""); // Mint to user1

        vm.prank(user1); // User1 initiates burn
        stableCoin.burnFrom(user1, burnAmount);

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - burnAmount, "User1 balance after burnFrom incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount - burnAmount, "Total supply after burnFrom incorrect");
    }

    function test_BurnFrom_ApprovedOperatorCanBurnTokens() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, ""); // Mint to user1

        vm.prank(user1); // User1 approves operator
        stableCoin.setApprovalForAll(operator, true);

        vm.prank(operator); // Operator initiates burn
        stableCoin.burnFrom(user1, burnAmount);

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - burnAmount, "User1 balance after operator burnFrom incorrect");
        assertEq(stableCoin.totalSupply(), mintAmount - burnAmount, "Total supply after operator burnFrom incorrect");
    }

    // function test_BurnFrom_EmitsTokensBurnedAndTransferSingleEvents() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     vm.prank(user1);
    //     vm.expectEmit(true, false, false, true, address(stableCoin)); // TokensBurned
    //     emit TokensBurned(user1, burnAmount);
    //     vm.expectEmit(true, true, true, true, address(stableCoin)); // TransferSingle
    //     emit TransferSingle(user1, user1, address(0), STABLECOIN_ID_TEST, burnAmount);
    //     stableCoin.burnFrom(user1, burnAmount);
    // }

    function test_BurnFrom_FailsIfNotOwnerOrApproved() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, "");

        vm.expectRevert(bytes("ERC1155: caller is not owner nor approved"));
        vm.prank(maliciousActor); // Malicious actor tries to burn user1's tokens
        stableCoin.burnFrom(user1, burnAmount);
    }

    function test_BurnFrom_FailsIfFromZeroAddress() public {
        vm.prank(user1); // Irrelevant who calls, check is on _from
        vm.expectRevert(bytes("StableCoin: burn from the zero address"));
        stableCoin.burnFrom(address(0), burnAmount);
    }

    function test_BurnFrom_FailsIfInsufficientBalance() public {
        vm.prank(owner);
        stableCoin.mint(user1, burnAmount - 1, "");

        vm.prank(user1);
        vm.expectRevert(bytes("StableCoin: insufficient balance to burn"));
        stableCoin.burnFrom(user1, burnAmount);
    }

     function test_BurnFrom_FailsIfAmountIsZero() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, "");

        vm.prank(user1);
        vm.expectRevert(bytes("StableCoin: burn amount must be greater than zero"));
        stableCoin.burnFrom(user1, 0);
    }


    // --- Approval Tests ---

    function test_SetApprovalForAll_UserCanApproveOperator() public {
        vm.prank(user1);
        vm.expectEmit(true, true, false, true, address(stableCoin)); // ApprovalForAll: account, operator are indexed
        emit ApprovalForAll(user1, operator, true);
        stableCoin.setApprovalForAll(operator, true);
        assertTrue(stableCoin.isApprovedForAll(user1, operator), "Operator should be approved");
    }

    // function test_SetApprovalForAll_UserCanRevokeApproval() public {
    //     vm.prank(user1);
    //     stableCoin.setApprovalForAll(operator, true); // First approve
    //     assertTrue(stableCoin.isApprovedForAll(user1, operator), "Operator should be initially approved");

    //     vm.expectEmit(true, true, false, true, address(stableCoin));
    //     emit ApprovalForAll(user1, operator, false);
    //     stableCoin.setApprovalForAll(operator, false); // Then revoke
    //     assertFalse(stableCoin.isApprovedForAll(user1, operator), "Operator approval should be revoked");
    // }

    // --- Transfer Tests (safeTransferFrom) ---

    function test_SafeTransferFrom_UserCanTransferOwnTokens() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, ""); // Mint to user1

        vm.prank(user1); // User1 initiates transfer
        vm.expectEmit(true, true, true, true, address(stableCoin));
        emit TransferSingle(user1, user1, user2, STABLECOIN_ID_TEST, transferAmount);
        stableCoin.safeTransferFrom(user1, user2, STABLECOIN_ID_TEST, transferAmount, "");

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - transferAmount, "User1 balance after transfer incorrect");
        assertEq(stableCoin.balanceOf(user2, STABLECOIN_ID_TEST), transferAmount, "User2 balance after transfer incorrect");
    }

    function test_SafeTransferFrom_ApprovedOperatorCanTransferTokens() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, ""); // Mint to user1

        vm.prank(user1); // User1 approves operator
        stableCoin.setApprovalForAll(operator, true);

        vm.prank(operator); // Operator initiates transfer
        vm.expectEmit(true, true, true, true, address(stableCoin));
        emit TransferSingle(operator, user1, user2, STABLECOIN_ID_TEST, transferAmount);
        stableCoin.safeTransferFrom(user1, user2, STABLECOIN_ID_TEST, transferAmount, "");

        assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - transferAmount, "User1 balance after operator transfer incorrect");
        assertEq(stableCoin.balanceOf(user2, STABLECOIN_ID_TEST), transferAmount, "User2 balance after operator transfer incorrect");
    }

    // function test_SafeTransferFrom_FailsIfNotOwnerOrApproved() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     vm.expectRevert(bytes("ERC1155: caller is not owner nor approved"));
    //     vm.prank(maliciousActor); // Malicious actor tries to transfer user1's tokens
    //     stableCoin.safeTransferFrom(user1, user2, STABLECOIN_ID_TEST, transferAmount, "");
    // }

    // function test_SafeTransferFrom_FailsIfInsufficientBalance() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, transferAmount - 1, ""); // Mint less than transferAmount

    //     vm.prank(user1);
    //     vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
    //     stableCoin.safeTransferFrom(user1, user2, STABLECOIN_ID_TEST, transferAmount, "");
    // }

    // function test_SafeTransferFrom_FailsIfToZeroAddress() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     vm.prank(user1);
    //     vm.expectRevert(bytes("ERC1155: transfer to the zero address"));
    //     stableCoin.safeTransferFrom(user1, address(0), STABLECOIN_ID_TEST, transferAmount, "");
    // }

    // function test_SafeTransferFrom_FailsIfInvalidId() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     vm.prank(user1);
    //     // This revert comes from _beforeTokenTransfer hook
    //     vm.expectRevert(bytes("StableCoin: can only transfer STABLECOIN_ID"));
    //     stableCoin.safeTransferFrom(user1, user2, STABLECOIN_ID_TEST + 1, transferAmount, "");
    // }

    // --- Transfer Tests (safeBatchTransferFrom) ---
    // function test_SafeBatchTransferFrom_UserCanTransferOwnTokens() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = STABLECOIN_ID_TEST;
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = transferAmount;

    //     vm.prank(user1);
    //     vm.expectEmit(true, true, true, true, address(stableCoin));
    //     emit TransferBatch(user1, user1, user2, ids, amounts);
    //     stableCoin.safeBatchTransferFrom(user1, user2, ids, amounts, "");

    //     assertEq(stableCoin.balanceOf(user1, STABLECOIN_ID_TEST), mintAmount - transferAmount);
    //     assertEq(stableCoin.balanceOf(user2, STABLECOIN_ID_TEST), transferAmount);
    // }

     function test_SafeBatchTransferFrom_FailsIfInvalidIdInBatch() public {
        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, "");

        uint256[] memory ids = new uint256[](2);
        ids[0] = STABLECOIN_ID_TEST;
        ids[1] = STABLECOIN_ID_TEST + 1; // Invalid ID
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = transferAmount / 2;
        amounts[1] = transferAmount / 2;

        vm.prank(user1);
        vm.expectRevert(bytes("StableCoin: batch transfer contains invalid ID(s)"));
        stableCoin.safeBatchTransferFrom(user1, user2, ids, amounts, "");
    }

    // function test_SafeBatchTransferFrom_FailsIfArraysLengthMismatch() public {
    //     vm.prank(owner);
    //     stableCoin.mint(user1, mintAmount, "");

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = STABLECOIN_ID_TEST;
    //     uint256[] memory amounts = new uint256[](2); // Mismatch
    //     amounts[0] = transferAmount;
    //     amounts[1] = transferAmount;


    //     vm.prank(user1);
    //     vm.expectRevert(bytes("ERC1155: ids and amounts length mismatch"));
    //     stableCoin.safeBatchTransferFrom(user1, user2, ids, amounts, "");
    // }


    // --- Total Supply Test ---
    function test_TotalSupply_IsCorrectlyTracked() public {
        assertEq(stableCoin.totalSupply(), 0, "Initial total supply should be 0");

        vm.prank(owner);
        stableCoin.mint(user1, mintAmount, "");
        assertEq(stableCoin.totalSupply(), mintAmount, "Total supply after minting to user1 incorrect");

        vm.prank(owner);
        stableCoin.mint(user2, mintAmount / 2, "");
        assertEq(stableCoin.totalSupply(), mintAmount + (mintAmount / 2), "Total supply after minting to user2 incorrect");

        vm.prank(user1); // User1 burns their own tokens
        stableCoin.burnFrom(user1, burnAmount);
        assertEq(stableCoin.totalSupply(), mintAmount + (mintAmount / 2) - burnAmount, "Total supply after user1 burns incorrect");

        vm.prank(owner); // Owner burns some of user2's tokens
        stableCoin.burn(user2, burnAmount / 2);
        assertEq(stableCoin.totalSupply(), mintAmount + (mintAmount / 2) - burnAmount - (burnAmount / 2), "Total supply after owner burns user2's tokens incorrect");
    }

    // --- Test _beforeTokenTransfer Hook (implicitly tested by transfer failures on invalid ID) ---
    // Add a specific test if direct testing of the hook's logic is desired beyond transfer prevention
    // function testFuzz_Mint(uint256 amountToMint, address to) public {
    //     vm.assume(to != address(0)); // Cannot mint to zero address
    //     vm.assume(amountToMint > 0); // Cannot mint zero amount
    //     vm.assume(amountToMint < 1_000_000 * (10**18)); // Prevent overflow / too large numbers

    //     vm.prank(owner);
    //     uint256 initialTotalSupply = stableCoin.totalSupply();
    //     uint256 initialBalanceTo = stableCoin.balanceOf(to, STABLECOIN_ID_TEST);

    //     stableCoin.mint(to, amountToMint, "");

    //     assertEq(stableCoin.balanceOf(to, STABLECOIN_ID_TEST), initialBalanceTo + amountToMint, "Fuzz Mint: Balance of receiver is wrong");
    //     assertEq(stableCoin.totalSupply(), initialTotalSupply + amountToMint, "Fuzz Mint: Total supply is wrong");
    // }

    // It's good practice to also test transfers to contract receivers
    // but that requires setting up mock receiver contracts.
    // For this example, we'll skip that for brevity.

}

