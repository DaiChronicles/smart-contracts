// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title IERC721DelegatedActions
 * @dev Interface for delegated actions related to ERC721 tokens, such as minting
 * and setting metadata. This interface provides functions for managing nonces
 * and supports EIP-712 domain separation for signature verification.
 */
interface IERC721DelegatedActions {
    /**
     * @notice Returns the current nonce for a specific ERC721 token.
     * @dev This nonce must be included whenever a signature is generated for
     * delegated actions like {_delegateSafeMint} or {_delegateSetTokenURI}.
     *
     * Every successful call to {_delegateSafeMint} or {_delegateSetTokenURI}
     * increments the token's nonce by one, preventing replay attacks.
     * @param tokenId The ID of the ERC721 token.
     * @return The current nonce of the token.
     */
    function nonces(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Returns the domain separator for EIP-712 signature encoding.
     * @dev The domain separator is used in the encoding of signatures
     * for {_delegateSafeMint} and {_delegateSetTokenURI}.
     * @return The EIP-712 domain separator.
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
