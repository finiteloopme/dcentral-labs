// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title PaymentFacilitator
 * @author DCentral Labs
 * @notice This contract is the core of the delegated agent payment flow.
 * It is a user-specific contract that holds an ERC20 allowance and executes purchases
 * on the user's behalf, but only when authorized by a valid, user-signed EIP-712 message.
 * This allows a third-party "agent" to submit transactions on behalf of the user,
 * paying the gas fees, without having direct control over the user's funds.
 */
contract PaymentFacilitator is EIP712 {
    // --- State Variables ---

    // @notice The user who deployed this contract and is authorized to sign intents.
    // Only signatures from this address will be considered valid.
    address public owner;

    // @notice A mapping to store used nonces (specifically, the hash of the intent).
    // This is a critical security measure to prevent replay attacks, where an agent
    // could try to execute the same valid purchase multiple times.
    mapping(bytes32 => bool) public usedNonces;

    // --- EIP-712 Type Hashes ---
    // This section defines the EIP-712 structure for signing. It's crucial that
    // these definitions match exactly across the Solidity contract, the Go backend,
    // and any other client that needs to create or verify a signature.

    // @notice The EIP-712 type hash for the IntentMandate struct.
    // This is the keccak256 hash of the struct's definition string.
    bytes32 public constant INTENT_MANDATE_TYPEHASH = keccak256(
        "IntentMandate(bytes32 task,address token,uint256 maxPrice,uint256 expires,uint256 nonce)"
    );

    // @notice The EIP-712 type hash for the CartMandate struct.
    bytes32 public constant CART_MANDATE_TYPEHASH = keccak256(
        "CartMandate(address merchant,address token,uint256 amount)"
    );

    // --- Structs ---

    /**
     * @notice Represents the user's off-chain signed instructions.
     * This struct defines the "rules" or "permission slip" that the user gives
     * to the agent. The agent can only act within these predefined boundaries.
     */
    struct IntentMandate {
        bytes32 task;       // A hash of the human-readable description of the task.
        address token;      // The token address for the purchase (e.g., USDC).
        uint256 maxPrice;   // The maximum amount the agent is allowed to spend.
        uint256 expires;    // Unix timestamp when this intent is no longer valid.
        uint256 nonce;      // A unique random number to prevent replay attacks.
    }

    /**
     * @notice Represents the merchant's "bill" or "offer" that the agent presents.
     * This contains the actual details of the purchase to be executed.
     */
    struct CartMandate {
        address merchant;   // The address to pay.
        address token;      // The token to pay with (must match the intent).
        uint256 amount;     // The exact amount to pay (must be <= maxPrice).
    }

    // --- Events ---

    /**
     * @notice Emitted when a purchase is successfully executed.
     * @param merchant The address of the merchant that was paid.
     * @param token The address of the token used for payment.
     * @param amount The amount of the token that was transferred.
     * @param intentNonce The nonce of the intent that was executed.
     */
    event PurchaseExecuted(
        address indexed merchant,
        address indexed token,
        uint256 amount,
        bytes32 indexed intentNonce
    );

    // --- Errors ---

    error InvalidSignature();     // The user's signature does not match the owner.
    error InvalidCartSignature(); // The cart signature is not from the merchant.
    error IntentExpired();        // The current block timestamp is past the intent's expiration.
    error PriceTooHigh();         // The cart amount exceeds the intent's maxPrice.
    error NonceAlreadyUsed();     // The intent's nonce has already been used.
    error InvalidToken();         // The cart token does not match the intent token.

    /**
     * @notice The constructor sets the contract owner and the EIP-712 domain.
     * @dev The EIP712 constructor takes the domain `name` and `version`, which
     * are critical for creating the domain separator. These must match the values
     * used by the off-chain signing client (Go backend in this case).
     */
    constructor() EIP712("PaymentFacilitator", "1") {
        owner = msg.sender;
    }

    /**
     * @notice The main function called by the agent to execute a payment.
     * @dev This function performs all security checks:
     *      1. Verifies the user's signature to authorize the intent.
     *      2. Verifies the merchant's signature to authenticate the cart.
     *      3. Validates the intent against on-chain rules (expiration, price, nonce).
     *      4. Marks the nonce as used to prevent replay attacks.
     *      5. Executes the ERC20 `transferFrom` call to make the payment.
     * @param intent The user's signed IntentMandate.
     * @param cart The merchant's signed CartMandate.
     * @param userSignature The EIP-712 signature from the user for the intent.
     * @param cartSignature The EIP-712 signature from the merchant for the cart.
     */
    function executePurchase(
        IntentMandate calldata intent,
        CartMandate calldata cart,
        bytes calldata userSignature,
        bytes calldata cartSignature
    ) external {
        // 1. Verify the user's signature to ensure the intent was authorized by the owner.
        bytes32 intentHash = _hashIntentMandate(intent);
        address userSigner = ECDSA.recover(intentHash, userSignature);
        if (userSigner != owner) {
            revert InvalidSignature();
        }

        // 2. Verify the merchant's signature to ensure the cart is authentic.
        bytes32 cartHash = _hashCartMandate(cart);
        address merchantSigner = ECDSA.recover(cartHash, cartSignature);
        if (merchantSigner != cart.merchant) {
            revert InvalidCartSignature();
        }

        // 3. Check the on-chain rules against the intent and cart.
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

        // 4. Mark the intent's hash as used to prevent replay attacks.
        usedNonces[intentHash] = true;

        // 5. Execute the payment.
        // This call will only succeed if the user (owner) has previously called
        // `approve(address(this), amount)` on the token contract.
        IERC20(cart.token).transferFrom(owner, cart.merchant, cart.amount);

        // 6. Emit an event to log the successful purchase.
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
        bytes32 structHash = keccak256(
            abi.encode(
                INTENT_MANDATE_TYPEHASH,
                intent.task,
                intent.token,
                intent.maxPrice,
                intent.expires,
                intent.nonce
            )
        );
        return _hashTypedDataV4(structHash);
    }

    /**
     * @notice An internal helper function to compute the full EIP-712 hash for the CartMandate.
     * @dev This follows the same EIP-712 hashing process as `_hashIntentMandate`.
     */
    function _hashCartMandate(
        CartMandate calldata cart
    ) internal view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                CART_MANDATE_TYPEHASH,
                cart.merchant,
                cart.token,
                cart.amount
            )
        );
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