// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title StockERC1155
 * @dev Implementation of an ERC1155 token to represent shares of a stock.
 * The stock is represented by a single token ID (0).
 */
contract StockERC1155 is ERC1155, Ownable {
    using Strings for uint256;

    // --- Constants ---
    uint256 public constant STOCK_TOKEN_ID = 0; // Token ID for the stock shares

    // --- State Variables ---
    string public stockName;
    string public stockSymbol;
    uint256 public totalSupply; // Total supply of the stock shares
    uint256 public stockPrice; // Price per share in wei

    // --- Events ---
    event StockIssued(uint256 indexed tokenId, address indexed to, uint256 amount);
    event StockPriceChanged(uint256 oldPrice, uint256 newPrice);


    /**
     * @dev Constructor to initialize the stock token.
     * @param _name The name of the stock (e.g., "Acme Corp").
     * @param _symbol The symbol of the stock (e.g., "ACME").
     * @param _initialSupply The total number of shares to be issued.
     * @param _initialOwner The address that will receive the initial supply of shares.
     * @param _initialPrice The initial price per share in wei.
     *
     * The URI is set to a placeholder. In a production environment, this should point
     * to a metadata JSON file compliant with the ERC1155 metadata URI JSON Schema.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _initialOwner,
        uint256 _initialPrice
    ) ERC1155("ipfs://placeholder/{id}.json") Ownable(_initialOwner) { // Ownable's initialOwner is set here
        require(_initialOwner != address(0), "StockERC1155: Initial owner cannot be the zero address");
        require(_initialSupply > 0, "StockERC1155: Initial supply must be greater than zero");
        require(_initialPrice > 0, "StockERC1155: Initial price must be greater than zero");

        stockName = _name;
        stockSymbol = _symbol;
        totalSupply = _initialSupply;
        stockPrice = _initialPrice;

        // Mint the initial supply of stock tokens (ID 0) to the initial owner
        _mint(_initialOwner, STOCK_TOKEN_ID, _initialSupply, "");

        emit StockIssued(STOCK_TOKEN_ID, _initialOwner, _initialSupply);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     * Returns the URI for a given token ID.
     * For this stock contract, we only have one token type (STOCK_TOKEN_ID).
     * This implementation returns a basic URI. For production, consider a more robust
     * metadata solution (e.g., IPFS, dedicated API).
     * @param _id The token ID.
     * @return The URI string for the token ID.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        require(_id == STOCK_TOKEN_ID, "StockERC1155: URI query for nonexistent token id");
        // Example: "data:application/json;base64,eyJuYW1lIjogIkFjbWUgQ29ycCBTaGFyZXMiLCAiZGVzY3JpcHRpb24iOiAiQSBzaGFyZSBvZiBBY21lIENvcnAuIiwgImltYWdlIjogImlwZnM6Ly9RbVhoc0tqZUpXY0dENUpkM0M0U1hER0U5VzZuYnBtcXlDemRtcHpYc0VoVkoiLCAicHJvcGVydGllcyI6IHsic3ltYm9sIjogIkFDTUUiLCAidG90YWxTdXBwbHkiOiAxMDAwfX0="
        // This is a simple placeholder. A real implementation would serve richer metadata.
        // You can build a JSON string dynamically or point to an off-chain resource.
        string memory baseURI = super.uri(_id); // Gets the base URI set in the ERC1155 constructor
        if (bytes(baseURI).length > 0) {
            // If a base URI like "ipfs://<CID>/" is set, append the token ID.
            // Example: "ipfs://Qm.../{id}.json" -> "ipfs://Qm.../0.json"
            // For ERC1155, it's common to have {id} replaced by the hex representation of the ID.
            // However, OpenZeppelin's default ERC1155 constructor takes a URI that might already contain {id}.
            // If the base URI is meant to be a folder, you might append _id.toString().
            // If the base URI is a template, it might already be correct.
            // For simplicity, if super.uri(_id) returns the template, we use it.
            // If it's empty or not a template, we construct a basic one.

            // This basic example just returns the URI passed to the constructor.
            // A more dynamic approach:
            // string memory json = string(abi.encodePacked(
            //     '{"name": "', stockName, ' Share (', stockSymbol, ')", ',
            //     '"description": "A share of ', stockName, '.", ',
            //     '"image": "ipfs://your_image_cid_here", ', // Replace with actual image URI
            //     '"properties": {"symbol": "', stockSymbol, '", "totalSupply": ', totalSupply.toString(), '}}'
            // ));
            // return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
            // For now, we stick to the URI set in the constructor.
            // The OpenZeppelin ERC1155 constructor takes a URI string that can contain "{id}".
            // It will replace "{id}" with the hexadecimal representation of the token ID.
            // So, "ipfs://placeholder/{id}.json" becomes "ipfs://placeholder/0000000000000000000000000000000000000000000000000000000000000000.json" (for ID 0)
            // or simply "ipfs://placeholder/0.json" depending on the library's formatting for {id}.
            // Let's assume the default OZ behavior is sufficient if a template URI is provided.
            return super.uri(_id);
        }
        // Fallback if no base URI is set or if we want a very simple on-chain URI
        return string(abi.encodePacked("data:text/plain;charset=utf-8,StockTokenID:", _id.toString()));
    }

    /**
     * @dev Mints new stock shares. Only callable by the owner.
     * This is an example function if more shares need to be issued after initial deployment.
     * Depending on the stock's nature, this might be disabled or have more complex governance.
     * @param _to The address to mint shares to.
     * @param _amount The number of shares to mint.
     * @param _data Additional data with no specified format.
     */
    function mintShares(address _to, uint256 _amount, bytes memory _data) public payable onlyOwner {
        require(_to != address(0), "StockERC1155: Mint to the zero address");
        require(msg.value == _amount * stockPrice, "StockERC1155: Incorrect payment amount");
        require(_amount > 0, "StockERC1155: Mint amount must be greater than zero");

        _mint(_to, STOCK_TOKEN_ID, _amount, _data);
        totalSupply += _amount; // Update total supply

        emit StockIssued(STOCK_TOKEN_ID, _to, _amount);
    }

    /**
     * @dev Burns existing stock shares from the caller's account.
     * @param _amount The number of shares to burn.
     * @param _data Additional data with no specified format (not used here).
     */
    function burnShares(uint256 _amount, bytes memory _data) public {
        require(_amount > 0, "StockERC1155: Burn amount must be greater than zero");
        // _burn already checks if msg.sender has enough balance
        _burn(msg.sender, STOCK_TOKEN_ID, _amount);
        totalSupply -= _amount; // Update total supply
    }

    /**
     * @dev Burns existing stock shares from a specific account, if approved or operator.
     * @param _from The address to burn shares from.
     * @param _amount The number of shares to burn.
     * @param _data Additional data with no specified format (not used here).
     */
    function burnSharesFrom(address _from, uint256 _amount, bytes memory _data) public {
        require(_from != address(0), "StockERC1155: Burn from the zero address");
        require(_amount > 0, "StockERC1155: Burn amount must be greater than zero");

        // Requires msg.sender to be _from or approved for _from
        if (msg.sender != _from && !isApprovedForAll(_from, msg.sender)) {
            revert("StockERC1155: Caller is not owner nor approved");
        }
        _burn(_from, STOCK_TOKEN_ID, _amount);
        totalSupply -= _amount; // Update total supply
    }

    // --- Owner Functions ---

    /**
     * @dev Sets a new price for the stock shares. Only callable by the owner.
     * @param _newPrice The new price per share in wei.
     */
    function setPrice(uint256 _newPrice) public onlyOwner {
        require(_newPrice > 0, "StockERC1155: Price must be greater than zero");
        uint256 oldPrice = stockPrice;
        stockPrice = _newPrice;
        emit StockPriceChanged(oldPrice, _newPrice);
    }

    /**
     * @dev Allows the owner to withdraw accumulated Ether from stock sales.
     */
    function withdrawFunds() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "StockERC1155: No funds to withdraw");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = owner().call{value: balance}("");
        require(success, "StockERC1155: Withdrawal failed");
    }



    // --- ERC1155 Overrides ---

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Requirements:
     *
     * - When minting/transferring (`from` == address(0)):
     * - `to` cannot be the zero address.
     * - When burning/transferring (`to` == address(0)):
     * - `from` cannot be the zero address.
     * - `ids` and `values` must have the same length.
     * - `ids` must only contain `STOCK_TOKEN_ID` or transfers must be reverted.
     * - If `to` is a contract, it must implement {IERC1155Receiver-onERC1155Received}
     * or {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual { //} override {
        //super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // Additional check: ensure only STOCK_TOKEN_ID is being transferred
        for (uint256 i = 0; i < ids.length; ++i) {
            require(ids[i] == STOCK_TOKEN_ID, "StockERC1155: Can only transfer stock tokens (ID 0)");
        }
    }

    // --- Helper Functions ---

    /**
     * @dev Returns the name of the stock.
     */
    function name() public view returns (string memory) {
        return stockName;
    }

    /**
     * @dev Returns the symbol of the stock.
     */
    function symbol() public view returns (string memory) {
        return stockSymbol;
    }
}
