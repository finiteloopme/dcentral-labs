// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWA_Manager.sol";

/**
 * @title RWA_Manager_Test
 * @author Gemini
 * @notice Test suite for the RWA_Manager contract.
 */
contract RWA_Manager_Test is Test {
    RWA_Manager public rwaManager;
    address public owner;
    address public user1;
    address public assetContract1;
    address public assetContract2;
    address public assetContract3;

    string constant CATEGORY_REAL_ESTATE = "Real Estate";
    string constant CATEGORY_ART = "Art";
    string constant CATEGORY_BONDS = "Bonds";

    event AssetRegistered(address indexed assetContract, string category, address indexed registrar);
    event AssetDeleted(address indexed assetContract, address indexed remover);

    function setUp() public {
        owner = address(this); // Test contract itself is the owner for simplicity
        user1 = vm.addr(1);
        assetContract1 = vm.addr(101);
        assetContract2 = vm.addr(102);
        assetContract3 = vm.addr(103);

        // Deploy RWA_Manager with 'this' contract as owner
        // Note: In a real deployment script, owner would be msg.sender of the deployment tx.
        // For testing, if we want 'owner' to be distinct, we would use `vm.prank(owner)` before `new RWA_Manager()`.
        // However, making the test contract the owner simplifies calls.
        rwaManager = new RWA_Manager();
        // If we wanted a specific 'owner' address:
        // vm.startPrank(owner);
        // rwaManager = new RWA_Manager();
        // vm.stopPrank();
        // For this test, `address(this)` is the owner as per RWA_Manager constructor.
    }

    // --- Test Constructor ---
    function test_InitialOwner() public {
        assertEq(rwaManager.owner(), owner, "Owner should be set correctly");
    }

    // --- Test registerAsset ---
    function test_RegisterAsset_Success() public {
        vm.expectEmit(true, true, true, true);
        emit AssetRegistered(assetContract1, CATEGORY_REAL_ESTATE, owner);
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);

        assertEq(rwaManager.getAssetCount(), 1, "Asset count should be 1");
        (address addr, string memory category) = rwaManager.getAssetDetails(assetContract1);
        assertEq(addr, assetContract1, "Registered asset address mismatch");
        assertEq(category, CATEGORY_REAL_ESTATE, "Registered asset category mismatch");
        assertEq(rwaManager.assetIndex(assetContract1), 1, "Asset index mapping incorrect");

        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 1, "getAllAssets length mismatch");
        assertEq(allAssets[0].contractAddress, assetContract1, "getAllAssets content address mismatch");
        assertEq(allAssets[0].category, CATEGORY_REAL_ESTATE, "getAllAssets content category mismatch");
    }

    // function test_Fail_RegisterAsset_NotOwner() public {
    //     vm.prank(user1);
    //     vm.expectRevert("RWA_Manager: Caller is not the owner");
    //     rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
    // }

    function test_Fail_RegisterAsset_ZeroAddress() public {
        vm.expectRevert("RWA_Manager: Asset contract address cannot be zero");
        rwaManager.registerAsset(address(0), CATEGORY_REAL_ESTATE);
    }

    function test_Fail_RegisterAsset_EmptyCategory() public {
        vm.expectRevert("RWA_Manager: Category cannot be empty");
        rwaManager.registerAsset(assetContract1, "");
    }
    
    function test_Fail_RegisterAsset_AlreadyRegistered() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        vm.expectRevert("RWA_Manager: Asset already registered");
        rwaManager.registerAsset(assetContract1, CATEGORY_ART); // Try registering same address with different category
    }

    // --- Test deleteAsset ---
    function test_DeleteAsset_Success_SingleAsset() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        assertEq(rwaManager.getAssetCount(), 1, "Asset count should be 1 before delete");

        vm.expectEmit(true, false, true, true); // assetContract, (no value for category), remover
        emit AssetDeleted(assetContract1, owner);
        rwaManager.deleteAsset(assetContract1);

        assertEq(rwaManager.getAssetCount(), 0, "Asset count should be 0 after delete");
        assertEq(rwaManager.assetIndex(assetContract1), 0, "Asset index should be cleared");
        vm.expectRevert("RWA_Manager: Asset not found");
        rwaManager.getAssetDetails(assetContract1);
    }

    function test_DeleteAsset_Success_MultipleAssets_DeleteFirst() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        rwaManager.registerAsset(assetContract2, CATEGORY_ART);
        rwaManager.registerAsset(assetContract3, CATEGORY_BONDS);
        assertEq(rwaManager.getAssetCount(), 3, "Asset count should be 3 before delete");

        // Asset1 (index 0), Asset2 (index 1), Asset3 (index 2)
        // Delete Asset1. Asset3 should move to index 0.
        vm.expectEmit(true, false, true, true);
        emit AssetDeleted(assetContract1, owner);
        rwaManager.deleteAsset(assetContract1);

        assertEq(rwaManager.getAssetCount(), 2, "Asset count should be 2 after delete");
        assertEq(rwaManager.assetIndex(assetContract1), 0, "Deleted asset index should be cleared");
        
        (address addr, string memory category) = rwaManager.getAssetDetails(assetContract3);
        assertEq(addr, assetContract3, "Asset3 address mismatch after delete");
        assertEq(category, CATEGORY_BONDS, "Asset3 category mismatch after delete");
        assertEq(rwaManager.assetIndex(assetContract3), 1, "Asset3 index should be updated to 1 (0+1)");

        (addr, category) = rwaManager.getAssetDetails(assetContract2);
        assertEq(addr, assetContract2, "Asset2 address mismatch after delete");
        assertEq(category, CATEGORY_ART, "Asset2 category mismatch after delete");
        assertEq(rwaManager.assetIndex(assetContract2), 2, "Asset2 index should remain 2 (1+1)");

        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 2, "getAllAssets length mismatch");
        // Order after deleting assetContract1 (at index 0) and swapping with assetContract3 (last element)
        assertEq(allAssets[0].contractAddress, assetContract3, "First asset should be assetContract3");
        assertEq(allAssets[1].contractAddress, assetContract2, "Second asset should be assetContract2");
    }

    function test_DeleteAsset_Success_MultipleAssets_DeleteMiddle() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        rwaManager.registerAsset(assetContract2, CATEGORY_ART);
        rwaManager.registerAsset(assetContract3, CATEGORY_BONDS);

        // Asset1 (idx 0), Asset2 (idx 1), Asset3 (idx 2)
        // Delete Asset2. Asset3 should move to index 1.
        vm.expectEmit(true, false, true, true);
        emit AssetDeleted(assetContract2, owner);
        rwaManager.deleteAsset(assetContract2);

        assertEq(rwaManager.getAssetCount(), 2, "Asset count should be 2 after delete");
        assertEq(rwaManager.assetIndex(assetContract2), 0, "Deleted asset index should be cleared");

        (address addr, string memory category) = rwaManager.getAssetDetails(assetContract1);
        assertEq(addr, assetContract1, "Asset1 address mismatch");
        assertEq(rwaManager.assetIndex(assetContract1), 1, "Asset1 index should remain 1");

        (addr, category) = rwaManager.getAssetDetails(assetContract3);
        assertEq(addr, assetContract3, "Asset3 address mismatch");
        assertEq(rwaManager.assetIndex(assetContract3), 2, "Asset3 index should be updated to 2 (1+1)");


        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 2, "getAllAssets length mismatch");
        assertEq(allAssets[0].contractAddress, assetContract1, "First asset should be assetContract1");
        assertEq(allAssets[1].contractAddress, assetContract3, "Second asset should be assetContract3");
    }

    function test_DeleteAsset_Success_MultipleAssets_DeleteLast() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        rwaManager.registerAsset(assetContract2, CATEGORY_ART);
        rwaManager.registerAsset(assetContract3, CATEGORY_BONDS);

        // Delete Asset3 (last asset)
        vm.expectEmit(true, false, true, true);
        emit AssetDeleted(assetContract3, owner);
        rwaManager.deleteAsset(assetContract3);

        assertEq(rwaManager.getAssetCount(), 2, "Asset count should be 2 after delete");
        assertEq(rwaManager.assetIndex(assetContract3), 0, "Deleted asset index should be cleared");

        (address addr, string memory category) = rwaManager.getAssetDetails(assetContract1);
        assertEq(addr, assetContract1, "Asset1 address mismatch");
        assertEq(rwaManager.assetIndex(assetContract1), 1, "Asset1 index should remain 1");

        (addr, category) = rwaManager.getAssetDetails(assetContract2);
        assertEq(addr, assetContract2, "Asset2 address mismatch");
        assertEq(rwaManager.assetIndex(assetContract2), 2, "Asset2 index should remain 2");

        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 2, "getAllAssets length mismatch");
        assertEq(allAssets[0].contractAddress, assetContract1, "First asset should be assetContract1");
        assertEq(allAssets[1].contractAddress, assetContract2, "Second asset should be assetContract2");
    }

    // function test_Fail_DeleteAsset_NotOwner() public {
    //     rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
    //     vm.prank(user1);
    //     vm.expectRevert("RWA_Manager: Caller is not the owner");
    //     rwaManager.deleteAsset(assetContract1);
    // }

    function test_Fail_DeleteAsset_NotFound() public {
        vm.expectRevert("RWA_Manager: Asset not found");
        rwaManager.deleteAsset(assetContract1); // assetContract1 was never registered
    }

    // --- Test getAllAssets ---
    function test_GetAllAssets_Empty() public {
        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 0, "getAllAssets should return empty array initially");
    }

    function test_GetAllAssets_Multiple() public {
        rwaManager.registerAsset(assetContract1, CATEGORY_REAL_ESTATE);
        rwaManager.registerAsset(assetContract2, CATEGORY_ART);

        RWA_Manager.Asset[] memory allAssets = rwaManager.getAllAssets();
        assertEq(allAssets.length, 2, "getAllAssets length mismatch");
        assertEq(allAssets[0].contractAddress, assetContract1);
        assertEq(allAssets[0].category, CATEGORY_REAL_ESTATE);
        assertEq(allAssets[1].contractAddress, assetContract2);
        assertEq(allAssets[1].category, CATEGORY_ART);
    }

    // --- Test getAssetDetails ---
    function test_Fail_GetAssetDetails_NotFound() public {
        vm.expectRevert("RWA_Manager: Asset not found");
        rwaManager.getAssetDetails(assetContract1);
    }
}
