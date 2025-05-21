// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SovereignBond
 * @dev An ERC1155 contract representing a specific series of sovereign bonds.
 * Each instance of this contract represents one type of bond with unique characteristics.
 * The bond is represented by a single token ID (BOND_TOKEN_ID = 0).
 */
contract SovereignBond is ERC1155, Ownable {
    /**
     * @dev The unique token ID for this specific bond series within this contract.
     */
    uint256 public constant BOND_TOKEN_ID = 0;

    /**
     * @dev Name of the bond series, e.g., "UK Gilt 2.5% 2030".
     */
    string public name;

    /**
     * @dev Annual interest rate of the bond, expressed in basis points (1% = 100 bps).
     * For example, 250 means 2.50%.
     */
    uint256 public immutable rate;

    /**
     * @dev Face value per unit of the bond, in the smallest unit of the currency.
     * For example, 1000 could represent $1000.00 if the currency has 2 decimal places.
     */
    uint256 public immutable faceValue;

    /**
     * @dev Unix timestamp when the bond expires and can be redeemed.
     */
    uint256 public immutable expiryDate;

    /**
     * @dev The country that issued this bond series, e.g., "United Kingdom".
     */
    string public issuingCountry;

    /**
     * @dev Stores the specific metadata URI for the BOND_TOKEN_ID.
     * This URI should point to a JSON file conforming to the ERC1155 Metadata URI JSON Schema.
     */
    string private _tokenMetadataURI;

    /**
     * @dev Emitted when bonds are successfully redeemed by a holder after expiry.
     * @param redeemer The address that redeemed the bonds.
     * @param tokenId The ID of the bond token redeemed (always BOND_TOKEN_ID).
     * @param amountRedeemed The quantity of bonds redeemed.
     */
    event BondsRedeemed(address indexed redeemer, uint256 indexed tokenId, uint256 amountRedeemed);

    /**
     * @dev Contract constructor.
     * @param bondName The descriptive name of the bond (e.g., "Gov Treasury Note 5Y").
     * @param bondRateBps The interest rate in basis points (e.g., 300 for 3.00%).
     * @param bondFaceValue The face value of one unit of the bond.
     * @param bondExpiryTermSeconds The duration in seconds from deployment until the bond expires.
     * @param countryOfIssue The name of the country issuing the bond.
     * @param initialTokenURI The direct metadata URI for this bond (for BOND_TOKEN_ID).
     */
    constructor(
        string memory bondName,
        uint256 bondRateBps,
        uint256 bondFaceValue,
        uint256 bondExpiryTermSeconds,
        string memory countryOfIssue,
        string memory initialTokenURI
    ) ERC1155("") Ownable(msg.sender) { // Initialize ERC1155 with an empty base URI as we override uri()
        name = bondName;
        rate = bondRateBps;
        faceValue = bondFaceValue;
        expiryDate = block.timestamp + bondExpiryTermSeconds;
        issuingCountry = countryOfIssue;
        _tokenMetadataURI = initialTokenURI; // Store the specific URI for BOND_TOKEN_ID
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     * Returns the metadata URI for the specific bond token ID (BOND_TOKEN_ID).
     * @param tokenId The ID of the token. Must be BOND_TOKEN_ID.
     * @return The metadata URI string.
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(tokenId == BOND_TOKEN_ID, "SovereignBond: Token ID does not exist for this bond series");
        return _tokenMetadataURI;
    }

    /**
     * @dev Allows the contract owner (e.g., treasury) to update the metadata URI for the bond.
     * This might be used if the location of the metadata JSON file changes.
     * Emits an {URI} event, as per ERC1155 standard.
     * @param newURI The new metadata URI for BOND_TOKEN_ID.
     */
    function setTokenMetadataURI(string memory newURI) public onlyOwner {
        _tokenMetadataURI = newURI;
        emit URI(newURI, BOND_TOKEN_ID); // ERC1155 standard event
    }

    /**
     * @dev Mints new bonds of this series to a specified account.
     * This function is callable only by the contract owner (typically the issuing treasury).
     * @param to The address to mint bonds to.
     * @param amount The quantity of bond units to mint.
     * @param data Additional data with no specified format by ERC1155, can be empty.
     */
    function issueBonds(address to, uint256 amount, bytes memory data) public onlyOwner {
        _mint(to, BOND_TOKEN_ID, amount, data);
    }

    /**
     * @dev Allows a bondholder to redeem their bonds after the expiry date.
     * This function burns the specified amount of bonds from the caller's account.
     * Note: The actual financial settlement (payout of face value + interest)
     * is assumed to be handled by an off-chain process or requires further smart contract
     * logic for payments, which is beyond the scope of this ERC1155 representation.
     * @param amount The quantity of bond units to redeem.
     */
    function redeemBonds(uint256 amount) public {
        require(block.timestamp >= expiryDate, "SovereignBond: Bond has not yet expired");
        
        address redeemer = _msgSender();
        require(balanceOf(redeemer, BOND_TOKEN_ID) >= amount, "SovereignBond: Insufficient bond balance for redemption");

        _burn(redeemer, BOND_TOKEN_ID, amount);
        emit BondsRedeemed(redeemer, BOND_TOKEN_ID, amount);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     * Overrides to make it compatible with Ownable if Ownable also implemented supportsInterface.
     * As of OpenZeppelin 5.x, Ownable does not, so we primarily override ERC1155's.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
