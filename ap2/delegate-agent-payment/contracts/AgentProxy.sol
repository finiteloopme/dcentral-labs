// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title AgentProxy
 * @author Your Name
 * @notice This contract acts as a user-specific proxy that holds an ERC20 allowance
 * and executes purchases on the user's behalf. It is a core component of the
 * delegated agent payment flow, providing the on-chain security layer.
 *
 * It is designed to be called by a "facilitator" or "agent" who pays the gas for
 * the final transaction, but it only executes the payment if the call includes a
 * valid `IntentMandate` that has been signed off-chain by the `owner` (the user).
 */
contract AgentProxy is EIP712 {
    // --- State Variables ---

    // @notice The user who deployed this contract and is authorized to sign intents.
    address public owner;

    // @notice A mapping to store used nonces (specifically, the hash of the intent).
    // This is a critical security measure to prevent replay attacks where an agent
    // could try to execute the same valid purchase multiple times.
    mapping(bytes32 => bool) public usedNonces;

    // --- EIP-712 Type Hashes ---
    // This section defines the EIP-712 structure for signing. It's crucial that
    // these definitions match exactly across the Solidity contract, the Go backend,
    // and any other client that needs to create or verify a signature.

    // @notice The EIP-712 type hash for the IntentMandate struct.
    // This is the keccak256 hash of the struct's definition string.
    // keccak256("IntentMandate(bytes32 task,address token,uint256 maxPrice,uint256 expires,address proxyContract,uint256 nonce)")
    bytes32 public constant INTENT_MANDATE_TYPEHASH =
        0x19ac96c45d832fdcb558cba6b351903a6e8ceed3234926732e8d5bdf7c0d5800;

    // --- Structs ---

    /**
     * @notice Represents the user's off-chain signed instructions.
     * This struct defines the "rules" or "permission slip" that the user gives
     * to the agent. The agent can only act within these predefined boundaries.
     */
    struct IntentMandate {
        bytes32 task; // A hash of the human-readable description of the task.
        address token; // The token address for the purchase (e.g., USDC).
        uint256 maxPrice; // The maximum amount the agent is allowed to spend.
        uint256 expires; // Unix timestamp when this intent is no longer valid.
        address proxyContract; // This contract's address, for EIP-712 domain separation.
        uint256 nonce; // A unique random number to prevent replay attacks.
    }

    /**
     * @notice Represents the merchant's "bill" or "offer" that the agent presents.
     * This contains the actual details of the purchase to be executed.
     */
    struct CartMandate {
        address merchant; // The address to pay.
        address token; // The token to pay with (must match the intent).
        uint256 amount; // The exact amount to pay (must be <= maxPrice).
    }

    // --- Events ---

    event SignerRecovered(bytes32 intentHash);
    event SignerAddress(address signer);
    event StructHash(bytes32 structHash);
    event PurchaseExecuted(
        address indexed merchant,
        address indexed token,
        uint256 amount,
        bytes32 indexed intentNonce
    );

    // --- Errors ---

    error InvalidSignature(); // The signature does not match the owner.
    error IntentExpired(); // The current block timestamp is past the intent's expiration.
    error PriceTooHigh(); // The cart amount exceeds the intent's maxPrice.
    error NonceAlreadyUsed(); // The intent's nonce has already been used.
    error InvalidToken(); // The cart token does not match the intent token.

    /**
     * @notice The constructor sets the contract owner and the EIP-712 domain.
     * @dev The EIP712 constructor takes the domain `name` and `version`, which
     * are critical for creating the domain separator. These must match the values
     * used by the off-chain signing client (Go backend in this case).
     */
    constructor() EIP712("AgentProxy", "1") {
        owner = msg.sender;
    }

    /**
     * @notice The main function called by the agent/facilitator to execute a payment.
     * @dev This function performs all security checks:
     *      1. Recovers the signer from the signature to verify it's the owner.
     *      2. Validates the intent against on-chain rules (expiration, price, nonce).
     *      3. Marks the nonce as used.
     *      4. Executes the ERC20 `transferFrom` call.
     * @param intent The user's signed IntentMandate.
     * @param cart The merchant's cart/offer.
     * @param signature The EIP-712 signature from the user.
     */
    function executePurchase(
        IntentMandate calldata intent,
        CartMandate calldata cart,
        bytes calldata signature
    ) external {
        // 1. Verify the signature to ensure the intent was authorized by the owner.
        bytes32 intentHash = _hashIntentMandate(intent);
        address signer = ECDSA.recover(intentHash, signature);
        emit SignerRecovered(intentHash);
        emit SignerAddress(signer);

        // This struct hash is for debugging and comparison with off-chain logs.
        bytes32 structHash = keccak256(
            abi.encode(
                INTENT_MANDATE_TYPEHASH,
                intent.task,
                intent.token,
                intent.maxPrice,
                intent.expires,
                intent.proxyContract,
                intent.nonce
            )
        );
        emit StructHash(structHash);

        if (signer != owner) {
            revert InvalidSignature();
        }

        // 2. Check the on-chain rules against the intent and cart.
        if (block.timestamp > intent.expires) {
            revert IntentExpired();
        }
        if (cart.amount > intent.maxPrice) {
            revert PriceTooHigh();
        }
        if (cart.token != intent.token) {
            revert InvalidToken();
        }
        if (usedNonces[intentHash]) {
            revert NonceAlreadyUsed();
        }

        // 3. Mark the intent's hash as used to prevent replay attacks.
        usedNonces[intentHash] = true;

        // 4. Execute the payment.
        // This call will only succeed if the user (owner) has previously called
        // `approve(address(this), amount)` on the token contract. This is the
        // crucial on-chain pre-approval step that gives this proxy contract
        // permission to move funds on the user's behalf.
        IERC20(cart.token).transferFrom(owner, cart.merchant, cart.amount);

        // 5. Emit an event to log the successful purchase.
        emit PurchaseExecuted(cart.merchant, cart.token, cart.amount, intentHash);
    }

    /**
     * @notice An internal helper function to compute the full EIP-712 hash for the IntentMandate.
     * @dev This function first calculates the hash of the struct data and then combines
     * it with the domain separator to produce the final digest that gets signed.
     * This MUST be kept in sync with the off-chain signing logic.
     */
    function _hashIntentMandate(
        IntentMandate calldata intent
    ) internal view returns (bytes32) {
        // First, hash the struct data itself.
        bytes32 structHash = keccak256(
            abi.encode(
                INTENT_MANDATE_TYPEHASH,
                intent.task,
                intent.token,
                intent.maxPrice,
                intent.expires,
                intent.proxyContract,
                intent.nonce
            )
        );

        // Then, use the EIP712 standard to combine it with the domain separator.
        return _hashTypedDataV4(structHash);
    }

    /**
     * @notice A helper function to get the domain separator for testing.
     * @dev This is exposed for testing purposes only to allow test suites to
     * easily reconstruct the EIP-712 digest without re-implementing the domain logic.
     */
    function domainSeparatorV4() public view returns (bytes32) {
        return _domainSeparatorV4();
    }
}

