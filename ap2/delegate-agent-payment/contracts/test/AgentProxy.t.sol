// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "AgentProxy.sol";
import "TokenUSDC.sol";

/**
 * @title AgentProxyTest
 * @notice Test suite for the AgentProxy contract.
 * @dev Uses Foundry for testing. Tests the core `executePurchase` flow.
 */
contract AgentProxyTest is Test {
    AgentProxy public agentProxy;
    TokenUSDC public usdc;

    // --- Actors ---
    // Define private keys for the different roles in the test scenario.
    // These are standard anvil private keys.
    uint256 constant USER_PK = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant AGENT_PK = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant MERCHANT_PK = 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a;

    // Derive addresses from the private keys.
    address public user;
    address public agent;
    address public merchant;


    /**
     * @notice Sets up the test environment before each test case.
     * @dev Deploys the MockUSDC and AgentProxy contracts and mints tokens for the user.
     */
    function setUp() public {
        user = vm.addr(USER_PK);
        agent = vm.addr(AGENT_PK);
        merchant = vm.addr(MERCHANT_PK);

        // Deploy contracts as the user.
        // The user becomes the `owner` of the AgentProxy contract.
        vm.startPrank(user);
        usdc = new TokenUSDC(0); // No initial supply needed, we mint below.
        agentProxy = new AgentProxy();
        usdc.mint(user, 1000e6); // Mint 1000 USDC (with 6 decimals) for the user.
        vm.stopPrank();
    }

    /**
     * @notice Tests the successful execution of a purchase.
     */
    function testExecutePurchase() public {
        // 1. User gives the AgentProxy contract an allowance to spend their USDC.
        // This is a prerequisite for the `transferFrom` call in `executePurchase`.
        vm.startPrank(user);
        usdc.approve(address(agentProxy), 100e6); // Approve 100 USDC

        // 2. User defines their intent for a purchase off-chain.
        AgentProxy.IntentMandate memory intent = AgentProxy.IntentMandate({
            task: keccak256(bytes("Buy a coffee")),
            token: address(usdc),
            maxPrice: 10e6, // Max price: 10 USDC
            expires: block.timestamp + 3600, // Intent expires in 1 hour
            proxyContract: address(agentProxy), // For EIP-712 domain
            nonce: 123 // Unique nonce to prevent replay attacks
        });

        // 3. User signs the EIP-712 typed data for the intent.
        
        // 3a. Calculate the EIP-712 struct hash.
        bytes32 structHash = keccak256(abi.encode(
            agentProxy.INTENT_MANDATE_TYPEHASH(),
            intent.task,
            intent.token,
            intent.maxPrice,
            intent.expires,
            intent.proxyContract,
            intent.nonce
        ));

        // 3b. Get the EIP-712 domain separator from the contract.
        bytes32 domainSeparator = agentProxy.domainSeparatorV4();

        // 3c. Hash the domain separator and struct hash to get the final digest to sign.
        bytes32 digest = keccak256(abi.encodePacked(
            // \x19\x01 is a standardized prefix required by EIP-712 
            // to ensure that signed structured data is handled securely 
            // and cannot be misused as a regular transaction.
            "\x19\x01",
            domainSeparator,
            structHash
        ));

        // 3d. Sign the digest with the user's private key.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(USER_PK, digest);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.stopPrank(); // End pranking as user.

        // 4. The agent receives the signed intent and prepares the cart for checkout.
        AgentProxy.CartMandate memory cart = AgentProxy.CartMandate({
            merchant: merchant,
            token: address(usdc),
            amount: 5e6 // Actual price: 5 USDC
        });

        // 5. The agent submits the transaction to the AgentProxy contract.
        vm.startPrank(agent);
        agentProxy.executePurchase(intent, cart, signature);
        vm.stopPrank(); // End pranking as agent.

        // 6. Verify the outcome of the transaction.
        assertEq(usdc.balanceOf(user), 995e6, "User balance should be 995 USDC"); // 1000 - 5
        assertEq(usdc.balanceOf(merchant), 5e6, "Merchant balance should be 5 USDC");
        assertEq(usdc.balanceOf(address(agentProxy)), 0, "Proxy balance should be 0");
    }
}
