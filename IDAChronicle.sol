// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IDAChronicle
 * @dev Interface for the DAChronicle NFT contract, enabling token minting and metadata updates
 * via signatures, as defined in EIP-2612. This interface allows delegated actions on behalf of
 * the Chronicles Agent without requiring direct transactions from the Chronicles Agent account.
 */
interface IDAChronicle is IERC721 {
    /**
     * @notice Mints an ERC721 token with the specified `tokenId` and `uri` on behalf of the Chronicles Agent.
     * @dev Requires a valid signature from the Chronicles Agent for authorization.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     * - `to` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - The provided signature must be valid and signed by the Chronicles Agent.
     *
     * @param isSale Whether the mint is part of a sale.
     * @param to The address to mint the token to.
     * @param tokenId The ID of the token to mint.
     * @param uri The metadata URI for the token.
     * @param deadline The expiration time for the signature.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     * @param beneficiary The address to receive royalties from the token.
     */
    function delegateSafeMint(
        bool isSale,
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address beneficiary
    ) external;

    /**
     * @notice Updates the metadata URI of a token on behalf of the Chronicles Agent.
     * @dev Requires a valid signature from the Chronicles Agent for authorization.
     *
     * Emits a {TokenURIUpdated} event.
     *
     * Requirements:
     * - The caller must provide a valid signature.
     * - `tokenId` must exist.
     * - `deadline` must be a timestamp in the future.
     *
     * @param applyDiscount Whether to apply a discount to the token URI update.
     * @param tokenId The ID of the token to update.
     * @param uri The new metadata URI for the token.
     * @param deadline The expiration time for the signature.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     */
    function delegateSetTokenURI(
        bool applyDiscount,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
