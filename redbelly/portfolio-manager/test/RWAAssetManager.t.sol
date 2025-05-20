// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWAAssetManager.sol"; // Adjust path if your contract is elsewhere

/**
 * @title RWAAssetManagerTest
 * @author Gemini
 * @notice Test suite for the RWAAssetManager contract.
 */
contract RWAAssetManagerTest is Test {
    // --- Test State Variables ---
    RWAAssetManager internal rwaManager;
    address internal owner;
    address internal user1;
    address internal user2;
    address internal asset1;
    address internal asset2;
    address internal asset3;

    // --- Events for Testing ---
    event AssetRegistered(address indexed assetContract, address indexed registeredBy);
    event AssetDeleted(address indexed assetContract, address indexed deletedBy);

    // --- Setup ---
    /**
     * @notice Sets up the testing environment before each test case.
     */
    function setUp() public {
        // Create test users
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        // Create mock asset contract addresses
        asset1 = makeAddr("asset1");
        asset2 = makeAddr("asset2");
        asset3 = makeAddr("asset3");

        // Deploy the RWAAssetManager contract with 'owner' as the initial owner
        vm.startPrank(owner); // All subsequent calls will be from 'owner'
        rwaManager = new RWAAssetManager(owner);
        vm.stopPrank();
    }

    // --- Test Constructor and Ownership ---

    /**
     * @notice Tests if the contract deployer is set as the initial owner.
     */
    function test_InitialOwnerIsSet() public {
        assertEq(rwaManager.owner(), owner, "Initial owner should be the deployer.");
    }

    // --- Test registerAsset ---

    /**
     * @notice Tests successful registration of a single asset by the owner.
     */
    function test_RegisterAsset_Success() public {
        vm.prank(owner); // Simulate call from owner
        vm.expectEmit(true, true, false, true); // Check indexed and non-indexed params for AssetRegistered
        emit AssetRegistered(asset1, owner);
        rwaManager.registerAsset(asset1);

        assertTrue(rwaManager.isAsset(asset1), "Asset1 should be registered.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 1, "Registered assets count should be 1.");
        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 1, "Listed assets length should be 1.");
        assertEq(assets[0], asset1, "Listed asset should be asset1.");
    }

    /**
     * @notice Tests registration of multiple assets.
     */
    function test_RegisterMultipleAssets_Success() public {
        vm.prank(owner);
        rwaManager.registerAsset(asset1);
        vm.prank(owner); // Need to prank for each state-changing call if not using startPrank/stopPrank block
        rwaManager.registerAsset(asset2);
        vm.prank(owner);
        rwaManager.registerAsset(asset3);

        assertTrue(rwaManager.isAsset(asset1), "Asset1 should be registered.");
        assertTrue(rwaManager.isAsset(asset2), "Asset2 should be registered.");
        assertTrue(rwaManager.isAsset(asset3), "Asset3 should be registered.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 3, "Registered assets count should be 3.");

        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 3, "Listed assets length should be 3.");
        assertEq(assets[0], asset1, "First listed asset should be asset1.");
        assertEq(assets[1], asset2, "Second listed asset should be asset2.");
        assertEq(assets[2], asset3, "Third listed asset should be asset3.");
    }

    // /**
    //  * @notice Tests that only the owner can register an asset.
    //  */
    // function test_RegisterAsset_Fail_NotOwner() public {
    //     vm.startPrank(owner); // Simulate call from owner
    //     rwaManager.registerAsset(asset1);
    //     vm.stopPrank();

    //     vm.prank(user1); // Simulate call from a non-owner
    //     vm.expectRevert(bytes("Ownable: caller is not the owner")); // OpenZeppelin's Ownable revert message
    //     rwaManager.registerAsset(asset1);
    // }

    /**
     * @notice Tests that registering a zero address asset fails.
     */
    function test_RegisterAsset_Fail_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("RWAAssetManager: Asset contract cannot be zero address");
        rwaManager.registerAsset(address(0));
    }

    /**
     * @notice Tests that registering an already registered asset fails.
     */
    function test_RegisterAsset_Fail_AlreadyRegistered() public {
        vm.prank(owner);
        rwaManager.registerAsset(asset1); // Register asset1 first

        vm.prank(owner); // Attempt to register asset1 again
        vm.expectRevert("RWAAssetManager: Asset already registered");
        rwaManager.registerAsset(asset1);
    }

    // --- Test listRegisteredAssets ---

    /**
     * @notice Tests listing assets when none are registered.
     */
    function test_ListAssets_Empty() public {
        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 0, "Listed assets should be empty.");
    }

    // --- Test deleteAsset ---

    /**
     * @notice Tests successful deletion of an asset by the owner.
     */
    function test_DeleteAsset_Success_SingleAsset() public {
        vm.startPrank(owner);
        rwaManager.registerAsset(asset1);

        vm.expectEmit(true, true, false, true); // Check indexed and non-indexed params for AssetDeleted
        emit AssetDeleted(asset1, owner);
        rwaManager.deleteAsset(asset1);
        vm.stopPrank();

        assertFalse(rwaManager.isAsset(asset1), "Asset1 should be deleted.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 0, "Registered assets count should be 0.");
        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 0, "Listed assets should be empty after deletion.");
    }

    /**
     * @notice Tests the "swap and pop" logic when deleting an asset that is not the last one.
     * Assets: A, B, C. Delete B. Expected: A, C.
     */
    function test_DeleteAsset_Success_SwapAndPop_Middle() public {
        vm.startPrank(owner);
        rwaManager.registerAsset(asset1); // A
        rwaManager.registerAsset(asset2); // B
        rwaManager.registerAsset(asset3); // C

        // Delete asset2 (B)
        rwaManager.deleteAsset(asset2);
        vm.stopPrank();

        assertFalse(rwaManager.isAsset(asset2), "Asset2 should be deleted.");
        assertTrue(rwaManager.isAsset(asset1), "Asset1 should still be registered.");
        assertTrue(rwaManager.isAsset(asset3), "Asset3 should still be registered.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 2, "Count should be 2 after deleting middle asset.");

        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 2, "Listed assets length should be 2.");
        assertEq(assets[0], asset1, "First asset should be asset1 (A)."); // asset1 was at index 0
        assertEq(assets[1], asset3, "Second asset should be asset3 (C)."); // asset3 moved to asset2's old spot
    }

    /**
     * @notice Tests deleting the first asset in a list.
     * Assets: A, B, C. Delete A. Expected: C, B. (C moves to A's spot)
     */
    function test_DeleteAsset_Success_SwapAndPop_First() public {
        vm.startPrank(owner);
        rwaManager.registerAsset(asset1); // A
        rwaManager.registerAsset(asset2); // B
        rwaManager.registerAsset(asset3); // C

        // Delete asset1 (A)
        rwaManager.deleteAsset(asset1);
        vm.stopPrank();

        assertFalse(rwaManager.isAsset(asset1), "Asset1 should be deleted.");
        assertTrue(rwaManager.isAsset(asset2), "Asset2 should still be registered.");
        assertTrue(rwaManager.isAsset(asset3), "Asset3 should still be registered.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 2, "Count should be 2 after deleting first asset.");

        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 2, "Listed assets length should be 2.");
        assertEq(assets[0], asset3, "First asset should be asset3 (C)."); // asset3 moved to asset1's old spot
        assertEq(assets[1], asset2, "Second asset should be asset2 (B).");
    }

    /**
     * @notice Tests deleting the last asset in a list.
     * Assets: A, B, C. Delete C. Expected: A, B.
     */
    function test_DeleteAsset_Success_SwapAndPop_Last() public {
        vm.startPrank(owner);
        rwaManager.registerAsset(asset1); // A
        rwaManager.registerAsset(asset2); // B
        rwaManager.registerAsset(asset3); // C

        // Delete asset3 (C)
        rwaManager.deleteAsset(asset3);
        vm.stopPrank();

        assertFalse(rwaManager.isAsset(asset3), "Asset3 should be deleted.");
        assertTrue(rwaManager.isAsset(asset1), "Asset1 should still be registered.");
        assertTrue(rwaManager.isAsset(asset2), "Asset2 should still be registered.");
        assertEq(rwaManager.getRegisteredAssetsCount(), 2, "Count should be 2 after deleting last asset.");

        address[] memory assets = rwaManager.listRegisteredAssets();
        assertEq(assets.length, 2, "Listed assets length should be 2.");
        assertEq(assets[0], asset1, "First asset should be asset1 (A).");
        assertEq(assets[1], asset2, "Second asset should be asset2 (B).");
    }


    // /**
    //  * @notice Tests that only the owner can delete an asset.
    //  */
    // function test_DeleteAsset_Fail_NotOwner() public {
    //     vm.startPrank(owner);
    //     rwaManager.registerAsset(asset1);
    //     vm.stopPrank();

    //     vm.prank(user1); // Simulate call from a non-owner
    //     vm.expectRevert(bytes("Ownable: caller is not the owner"));
    //     rwaManager.deleteAsset(asset1);
    // }

    /**
     * @notice Tests that deleting a non-existent asset fails.
     */
    function test_DeleteAsset_Fail_NotRegistered() public {
        vm.prank(owner);
        // asset1 is not registered
        vm.expectRevert("RWAAssetManager: Asset not registered");
        rwaManager.deleteAsset(asset1);
    }

    /**
     * @notice Tests that deleting a zero address asset fails (it wouldn't be registered anyway).
     */
    function test_DeleteAsset_Fail_ZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert("RWAAssetManager: Asset not registered"); // It cannot be registered, so this check comes first.
        rwaManager.deleteAsset(address(0));
    }

    // --- Test isAsset ---
    /**
     * @notice Tests isAsset for a registered and non-registered asset.
     */
    function test_IsAsset() public {
        vm.prank(owner);
        rwaManager.registerAsset(asset1);

        assertTrue(rwaManager.isAsset(asset1), "isAsset(asset1) should be true.");
        assertFalse(rwaManager.isAsset(asset2), "isAsset(asset2) should be false for non-registered asset.");
        assertFalse(rwaManager.isAsset(address(0)), "isAsset(zero_address) should be false.");
    }

    // --- Test getRegisteredAssetsCount ---
    /**
     * @notice Tests getRegisteredAssetsCount.
     */
    function test_GetRegisteredAssetsCount() public {
        assertEq(rwaManager.getRegisteredAssetsCount(), 0, "Initial count should be 0.");

        vm.prank(owner);
        rwaManager.registerAsset(asset1);
        assertEq(rwaManager.getRegisteredAssetsCount(), 1, "Count should be 1 after one registration.");

        vm.prank(owner);
        rwaManager.registerAsset(asset2);
        assertEq(rwaManager.getRegisteredAssetsCount(), 2, "Count should be 2 after two registrations.");

        vm.prank(owner);
        rwaManager.deleteAsset(asset1);
        assertEq(rwaManager.getRegisteredAssetsCount(), 1, "Count should be 1 after one deletion.");
    }
}
