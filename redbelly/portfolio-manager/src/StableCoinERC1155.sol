// File: src/StableCoin.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title StableCoin
 * @dev Implementation of an ERC1155 stablecoin.
 * This contract represents a fungible token pegged to a specific fiat currency.
 * The token ID 0 is used to represent the stablecoin.
 */
contract StableCoin is ERC1155, Ownable {
    // --- State Variables ---

    /// @notice The unique identifier for the stablecoin within this ERC1155 contract.
    uint256 public constant STABLECOIN_ID = 0;

    /// @notice The name of the stablecoin (e.g., "Tether USD").
    string public name;

    /// @notice The symbol of the stablecoin (e.g., "USDT").
    string public symbol;

    /// @notice The fiat currency this stablecoin is pegged to (e.g., "USD", "EUR").
    string public fiatPeggedTo;

    /// @notice The number of decimals the stablecoin uses.
    uint8 public constant decimals = 18; // Common practice, similar to Ether

    /// @dev Tracks the total supply of the stablecoin.
    uint256 private _totalSupply;

    // --- Events ---

    /**
     * @dev Emitted when new stablecoins are minted.
     * @param to The address that received the new tokens.
     * @param amount The amount of tokens minted.
     */
    event TokensMinted(address indexed to, uint256 amount);

    /**
     * @dev Emitted when stablecoins are burned.
     * @param from The address whose tokens were burned.
     * @param amount The amount of tokens burned.
     */
    event TokensBurned(address indexed from, uint256 amount);

    // --- Constructor ---

    /**
     * @dev Sets the initial values for the stablecoin.
     * @param initialOwner The initial owner of the contract, who will have minting/burning rights.
     * @param _name The name of the stablecoin.
     * @param _symbol The symbol of the stablecoin.
     * @param _fiatPeggedTo The fiat currency it is pegged to (e.g., "USD").
     * @param _uri The URI for the token metadata (can be updated later if needed).
     */
    constructor(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        string memory _fiatPeggedTo,
        string memory _uri
    ) ERC1155(_uri) Ownable(initialOwner) {
        name = _name;
        symbol = _symbol;
        fiatPeggedTo = _fiatPeggedTo;
    }

    // --- URI Management ---

    /**
     * @dev Overrides the default URI function to provide token-specific metadata.
     * For a stablecoin, the metadata might be the same for all tokens (as there's only one type).
     * You can customize this to return a JSON pointing to details like name, symbol, decimals, and peg.
     * @param _id The ID of the token (should be STABLECOIN_ID).
     * @return The URI string for the token metadata.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(_id == STABLECOIN_ID, "StableCoin: invalid token ID");
        // Example: "data:application/json;base64,eyJuYW1lIjogIlN0YWJsZUNvaW4iLCAiZGVzY3JpcHRpb24iOiAiQSBzdGFibGUgY29pbiBwZWdnZWQgdG8gVVNEIiwgImltYWdlIjogImlwZnM6Ly9RblahblahIn0="
        // For simplicity, we return the base URI set in the constructor.
        // In a real scenario, you might construct a more dynamic URI or have it point to off-chain metadata.
        return super.uri(_id);
    }

    /**
     * @dev Allows the owner to update the base URI for the token metadata.
     * @param newuri The new URI string.
     */
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    // --- Minting ---

    /**
     * @dev Mints new stablecoins and assigns them to an account.
     * Can only be called by the owner.
     * @param _to The address to mint tokens to.
     * @param _amount The amount of stablecoins to mint (in the smallest unit, considering decimals).
     * @param _data Additional data with no specified format (as per ERC1155).
     */
    function mint(address _to, uint256 _amount, bytes memory _data) public onlyOwner {
        require(_to != address(0), "StableCoin: mint to the zero address");
        require(_amount > 0, "StableCoin: mint amount must be greater than zero");
        _mint(_to, STABLECOIN_ID, _amount, _data);
        _totalSupply += _amount;
        emit TokensMinted(_to, _amount);
    }

    // --- Burning ---

    /**
     * @dev Burns stablecoins from an account.
     * Can only be called by the owner for now (e.g., for redemption).
     * For user-initiated burns, you'd need to adjust permissions or use `burnFrom`.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of stablecoins to burn (in the smallest unit).
     */
    function burn(address _from, uint256 _amount) public onlyOwner {
        require(_from != address(0), "StableCoin: burn from the zero address");
        require(balanceOf(_from, STABLECOIN_ID) >= _amount, "StableCoin: insufficient balance to burn");
        _burn(_from, STABLECOIN_ID, _amount);
        _totalSupply -= _amount;
        emit TokensBurned(_from, _amount);
    }

    /**
     * @dev Burns stablecoins from an account, requires prior approval if caller is not the owner.
     * This function allows a designated operator or the token holder themselves to burn tokens.
     * @param _from The address to burn tokens from.
     * @param _amount The amount of stablecoins to burn.
     */
    function burnFrom(address _from, uint256 _amount) public {
        require(_from != address(0), "StableCoin: burn from the zero address");
        uint256 fromBalance = balanceOf(_from, STABLECOIN_ID);
        require(fromBalance >= _amount, "StableCoin: insufficient balance to burn");
        require(_amount > 0, "StableCoin: burn amount must be greater than zero");


        // Check if the caller is the owner or is approved
        require(
            msg.sender == _from || isApprovedForAll(_from, msg.sender),
            "ERC1155: caller is not owner nor approved" // Using OpenZeppelin's standard error message
        );

        _burn(_from, STABLECOIN_ID, _amount);
        _totalSupply -= _amount;
        emit TokensBurned(_from, _amount);
    }

    // --- ERC1155 Overrides and Hooks ---

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     * For a single fungible token, `ids` will contain only STABLECOIN_ID and `amounts` will contain the corresponding amount.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        // You can add checks here to ensure all IDs in the batch are STABLECOIN_ID
        for (uint256 i = 0; i < ids.length; ++i) {
            require(ids[i] == STABLECOIN_ID, "StableCoin: batch transfer contains invalid ID(s)");
        }
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

     /**
     * @dev Hook that is called before any token transfer. This includes minting, burning, and transfers.
     * @param operator The address performing the transfer.
     * @param from The address tokens are transferred from.
     * @param to The address tokens are transferred to.
     * @param ids Array of token IDs being transferred.
     * @param amounts Array of token amounts being transferred.
     * @param data Additional data with no specified format.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {// override {
        // super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Additional logic can be added here if needed for all transfers.
        // For example, if you wanted to ensure only STABLECOIN_ID is ever transferred.
        if (from != address(0) && to != address(0)) { // Only for actual transfers, not mint/burn
            for (uint256 i = 0; i < ids.length; i++) {
                require(ids[i] == STABLECOIN_ID, "StableCoin: can only transfer STABLECOIN_ID");
            }
        }
    }


    // --- View Functions ---

    /**
     * @dev Returns the total supply of the stablecoin.
     * @return The total number of stablecoins in circulation.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
