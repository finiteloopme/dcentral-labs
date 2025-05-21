// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SovereignBond} from "../src/SovereignBondERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol"; // For OwnableUnauthorizedAccount error

// ERC1155 Events for assertions
interface IERC1155Events {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
}

contract SovereignBondTest is Test, IERC1155Events {
    SovereignBond internal bond;

    // Default Bond parameters for testing
    string constant BOND_NAME = "Test Gov Bond 5% 2030";
    uint256 constant BOND_RATE_BPS = 500; // 5.00%
    uint256 constant BOND_FACE_VALUE = 1000; // e.g., $1000
    uint256 constant BOND_EXPIRY_TERM_SECONDS = 365 days; // Expires in 1 year
    string constant ISSUING_COUNTRY = "Testland";
    string constant INITIAL_URI = "https://api.example.com/bonds/testbond_v0.json";
    uint256 constant BOND_ID = 0 ; //SovereignBond.BOND_TOKEN_ID; // Should be 0

    address internal owner;   // Contract deployer and owner
    address internal alice = vm.addr(0x1); // User Alice
    address internal bob = vm.addr(0x2);   // User Bob
    address internal operator = vm.addr(0x3); // Operator for Alice

    // Custom event from SovereignBond
    event BondsRedeemed(address indexed redeemer, uint256 indexed tokenId, uint256 amountRedeemed);

    function setUp() public {
        owner = address(this); // Test contract itself will be the deployer/owner
        // Deploy the SovereignBond contract as the 'owner'
        vm.prank(owner);
        bond = new SovereignBond(
            BOND_NAME,
            BOND_RATE_BPS,
            BOND_FACE_VALUE,
            BOND_EXPIRY_TERM_SECONDS,
            ISSUING_COUNTRY,
            INITIAL_URI
        );
    }

    function test_NewInstance_Constructor_Initialization() public {
        // Deploy a new instance to precisely check constructor logic against current block.timestamp
        uint256 deployTime = block.timestamp;
        vm.prank(owner); // Ensure owner is consistent for ownership check
        SovereignBond newBond = new SovereignBond(
            BOND_NAME,
            BOND_RATE_BPS,
            BOND_FACE_VALUE,
            BOND_EXPIRY_TERM_SECONDS,
            ISSUING_COUNTRY,
            INITIAL_URI
        );

        assertEq(newBond.name(), BOND_NAME, "Bond name mismatch");
        assertEq(newBond.rate(), BOND_RATE_BPS, "Bond rate mismatch");
        assertEq(newBond.faceValue(), BOND_FACE_VALUE, "Bond face value mismatch");
        assertEq(newBond.issuingCountry(), ISSUING_COUNTRY, "Issuing country mismatch");
        assertEq(newBond.expiryDate(), deployTime + BOND_EXPIRY_TERM_SECONDS, "Expiry date calculation incorrect");
        assertEq(newBond.owner(), owner, "Contract owner mismatch");
        assertEq(newBond.uri(BOND_ID), INITIAL_URI, "Initial URI mismatch");
        assertEq(newBond.BOND_TOKEN_ID(), 0, "BOND_TOKEN_ID should be 0");
    }
    
    function test_SetupInstance_Constructor_Values() public {
        assertEq(bond.name(), BOND_NAME, "Bond name mismatch (setup instance)");
        assertEq(bond.rate(), BOND_RATE_BPS, "Bond rate mismatch (setup instance)");
        assertEq(bond.faceValue(), BOND_FACE_VALUE, "Bond face value mismatch (setup instance)");
        assertEq(bond.issuingCountry(), ISSUING_COUNTRY, "Issuing country mismatch (setup instance)");
        assertEq(bond.owner(), owner, "Owner mismatch (setup instance)");
        assertEq(bond.uri(BOND_ID), INITIAL_URI, "Initial URI mismatch (setup instance)");
    }


    function test_SetTokenMetadataURI_AsOwner() public {
        string memory newURI = "https://api.example.com/bonds/testbond_v1.json";
        vm.prank(owner); // Act as owner
        
        vm.expectEmit(true, false, false, true); // Check topic1 (id), skip topic2/3, check data (value)
        emit URI(newURI, BOND_ID);
        bond.setTokenMetadataURI(newURI);
        
        assertEq(bond.uri(BOND_ID), newURI, "URI was not updated correctly");
    }

    function test_SetTokenMetadataURI_AsNonOwner_ShouldRevert() public {
        string memory newURI = "https://api.example.com/bonds/testbond_fail.json";
        vm.prank(alice); // Act as Alice (non-owner)
        
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        bond.setTokenMetadataURI(newURI);
    }

    function test_IssueBonds_AsOwner() public {
        uint256 issueAmount = 100;
        vm.prank(owner); // Act as owner

        // Expect TransferSingle event: operator, from, to are indexed; id, value are in data
        vm.expectEmit(true, true, true, true); 
        emit TransferSingle(owner, address(0), alice, BOND_ID, issueAmount);
        bond.issueBonds(alice, issueAmount, ""); // Mint to Alice

        assertEq(bond.balanceOf(alice, BOND_ID), issueAmount, "Alice's balance mismatch after minting");
    }

    function test_IssueBonds_AsNonOwner_ShouldRevert() public {
        uint256 issueAmount = 100;
        vm.prank(alice); // Act as Alice (non-owner)

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, alice));
        bond.issueBonds(bob, issueAmount, ""); // Try to mint to Bob
    }

    function test_SafeTransferFrom_HolderToRecipient() public {
        uint256 initialAmount = 100;
        uint256 transferAmount = 30;
        
        // Owner issues bonds to Alice
        vm.prank(owner);
        bond.issueBonds(alice, initialAmount, "");

        // Alice transfers to Bob
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, alice, bob, BOND_ID, transferAmount);
        bond.safeTransferFrom(alice, bob, BOND_ID, transferAmount, "");

        assertEq(bond.balanceOf(alice, BOND_ID), initialAmount - transferAmount, "Alice's balance incorrect after transfer");
        assertEq(bond.balanceOf(bob, BOND_ID), transferAmount, "Bob's balance incorrect after transfer");
    }
    
    // function test_SafeBatchTransferFrom_HolderToRecipient() public {
    //     uint256 initialAmount = 100;
    //     uint256 transferAmount = 30;
        
    //     vm.prank(owner);
    //     bond.issueBonds(alice, initialAmount, "");

    //     uint256[] memory ids = new uint256[](1);
    //     ids[0] = BOND_ID;
    //     uint256[] memory amounts = new uint256[](1);
    //     amounts[0] = transferAmount;

    //     vm.prank(alice);
    //     vm.expectEmit(true, true, true, true); // operator, from, to are indexed; ids, values are in data
    //     emit TransferBatch(alice, alice, bob, ids, amounts);
    //     bond.safeBatchTransferFrom(alice, bob, ids, amounts, "");

    //     assertEq(bond.balanceOf(alice, BOND_ID), initialAmount - transferAmount, "Alice's balance incorrect after batch transfer");
    //     assertEq(bond.balanceOf(bob, BOND_ID), transferAmount, "Bob's balance incorrect after batch transfer");
    // }

    function test_Approval_SetApprovalForAll_And_OperatorTransfer() public {
        uint256 initialAmount = 100;
        uint256 transferAmount = 40;

        vm.prank(owner);
        bond.issueBonds(alice, initialAmount, "");

        // Alice approves 'operator'
        vm.prank(alice);
        vm.expectEmit(true, true, false, true); // account, operator indexed; approved in data
        emit ApprovalForAll(alice, operator, true);
        bond.setApprovalForAll(operator, true);
        assertTrue(bond.isApprovedForAll(alice, operator), "Operator should be approved for Alice");
        
        // 'operator' transfers from Alice to Bob
        vm.prank(operator);
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(operator, alice, bob, BOND_ID, transferAmount);
        bond.safeTransferFrom(alice, bob, BOND_ID, transferAmount, "");

        assertEq(bond.balanceOf(alice, BOND_ID), initialAmount - transferAmount, "Alice's balance incorrect post-operator transfer");
        assertEq(bond.balanceOf(bob, BOND_ID), transferAmount, "Bob's balance incorrect post-operator transfer");

        // Alice revokes 'operator'
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(alice, operator, false);
        bond.setApprovalForAll(operator, false);
        assertFalse(bond.isApprovedForAll(alice, operator), "Operator should be revoked for Alice");
    }

    function test_RedeemBonds_BeforeExpiry_ShouldRevert() public {
        uint256 issueAmount = 50;
        vm.prank(owner);
        bond.issueBonds(alice, issueAmount, "");

        // Ensure current time is before expiry (expiry is 1 year from setUp)
        assertTrue(block.timestamp < bond.expiryDate(), "Test assumption failed: Bond should not be expired yet.");

        vm.prank(alice);
        vm.expectRevert(bytes("SovereignBond: Bond has not yet expired"));
        bond.redeemBonds(issueAmount);
    }

    function test_RedeemBonds_AfterExpiry_InsufficientBalance_ShouldRevert() public {
        uint256 issueAmount = 50;
        vm.prank(owner);
        bond.issueBonds(alice, issueAmount, ""); // Alice has 50 bonds

        // Warp time to after bond expiry
        vm.warp(bond.expiryDate() + 1 days); // Move time to 1 day after expiry

        vm.prank(alice);
        vm.expectRevert(bytes("SovereignBond: Insufficient bond balance for redemption"));
        bond.redeemBonds(issueAmount + 10); // Try to redeem more than available
    }

    function test_RedeemBonds_AfterExpiry_SufficientBalance_PartialRedeem() public {
        uint256 issueAmount = 50;
        uint256 redeemAmount = 20;
        vm.prank(owner);
        bond.issueBonds(alice, issueAmount, "");

        vm.warp(bond.expiryDate() + 1 days);

        vm.prank(alice);
        // Expect TransferSingle for the burn operation (to address(0))
        vm.expectEmit(true, true, true, true);
        emit TransferSingle(alice, alice, address(0), BOND_ID, redeemAmount);
        // Expect custom BondsRedeemed event
        vm.expectEmit(true, true, false, true); // redeemer, tokenId indexed; amountRedeemed in data
        emit BondsRedeemed(alice, BOND_ID, redeemAmount);
        
        bond.redeemBonds(redeemAmount);

        assertEq(bond.balanceOf(alice, BOND_ID), issueAmount - redeemAmount, "Alice's balance incorrect after partial redemption");
    }
    
    function test_RedeemBonds_AfterExpiry_SufficientBalance_FullRedeem() public {
        uint256 issueAmount = 50;
        vm.prank(owner);
        bond.issueBonds(alice, issueAmount, "");

        vm.warp(bond.expiryDate() + 1 days);

        vm.prank(alice);
        vm.expectEmit(true, true, true, true); // Burn event
        emit TransferSingle(alice, alice, address(0), BOND_ID, issueAmount);
        vm.expectEmit(true, true, false, true); // BondsRedeemed event
        emit BondsRedeemed(alice, BOND_ID, issueAmount);
        
        bond.redeemBonds(issueAmount);

        assertEq(bond.balanceOf(alice, BOND_ID), 0, "Alice's balance should be zero after full redemption");
    }
    
    function test_URI_InvalidTokenId_ShouldRevert() public {
        uint256 invalidTokenId = BOND_ID + 1; // Any ID other than BOND_TOKEN_ID (0)
        vm.expectRevert(bytes("SovereignBond: Token ID does not exist for this bond series"));
        bond.uri(invalidTokenId);
    }
}
