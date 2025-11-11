// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @dev Provides tracking nonces for ERC721 tokens. Nonces will only increment.
 */
abstract contract ERC721Nonces {
    /**
     * @dev The nonce used for an `account` is not the expected current nonce.
     */
    error InvalidTokenNonce(uint256 tokenId, uint256 currentNonce);

    mapping(uint256 tokenId => uint256) private s_nonces;

    /**
     * @dev Returns the next unused nonce for a token.
     */
    function nonces(uint256 tokenId) public view virtual returns (uint256) {
        return s_nonces[tokenId];
    }

    /**
     * @dev Consumes a nonce.
     *
     * Returns the current value and increments nonce.
     */
    function _useNonce(uint256 tokenId) internal virtual returns (uint256) {
        // For each token, the nonce has an initial value of 0, can only be incremented by one, and cannot be
        // decremented or reset. This guarantees that the nonce never overflows.
        unchecked {
            // It is important to do x++ and not ++x here.
            return s_nonces[tokenId]++;
        }
    }

    /**
     * @dev Same as {_useNonce} but checking that `nonce` is the next valid for `owner`.
     */
    function _useCheckedNonce(uint256 tokenId, uint256 nonce) internal virtual {
        uint256 current = _useNonce(tokenId);
        if (nonce != current) {
            revert InvalidTokenNonce(tokenId, current);
        }
    }
}
