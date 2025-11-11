// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {ERC721Nonces} from "./ERC721Nonces.sol";
import {IERC721DelegatedActions} from "./IERC721DelegatedActions.sol";
import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";

/**
 * @dev Thrown when the provided signature has expired.
 * @param deadline The expiration time of the signature.
 */
error ERC721DelegatedActions__ERC2612ExpiredSignature(uint256 deadline);

/**
 * @dev Thrown when the provided signature is invalid.
 * @param signer The address of the signer.
 * @param owner The expected owner of the token.
 */
error ERC721DelegatedActions__ERC2612InvalidSigner(address signer, address owner);

/**
 * @title ERC721DelegatedActions
 * @dev Abstract contract enabling delegated actions for ERC721 tokens, such as minting and updating metadata,
 * using off-chain signatures for authorization. Extends functionality from OpenZeppelin's ERC721 contracts.
 */
abstract contract ERC721DelegatedActions is
    ERC721,
    ERC721URIStorage,
    ERC2981,
    EIP712,
    ERC721Nonces,
    IERC721DelegatedActions,
    DACAccessManaged
{
    bytes32 private constant DELEGATE_SAFE_MINT_TYPEHASH =
        keccak256("_delegateSafeMint(bool isSale,address to,uint256 tokenId,string uri,uint256 nonce,uint256 deadline)");
    bytes32 private constant DELEGATE_SET_TOEKN_URI_TYPEHASH =
        keccak256("_delegateSetTokenURI(bool applyDiscount,uint256 tokenId,string uri,uint256 nonce,uint256 deadline)");
    uint96 internal constant ROYALTY_FEE = 200; // 2%

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC-721 token name.
     */
    constructor(string memory name, string memory symbol, address initialAuthority)
        ERC721(name, symbol)
        EIP712(name, "1")
        DACAccessManaged(IDACAuthority(initialAuthority))
    {}

    /**
     * @notice Delegates the safe minting of an ERC721 token to another party.
     * @dev Requires an off-chain signature from the authorized party.
     * @param isSale Whether the mint is part of a sale.
     * @param to The address to mint the token to.
     * @param tokenId The ID of the token to be minted.
     * @param uri The URI of the token metadata.
     * @param deadline The deadline until when the signature is valid.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     * @param beneficiary The address to receive royalties from the token.
     */
    function _delegateSafeMint(
        bool isSale,
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        address beneficiary
    ) internal virtual {
        if (block.timestamp > deadline) {
            revert ERC721DelegatedActions__ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash =
            keccak256(abi.encode(DELEGATE_SAFE_MINT_TYPEHASH, isSale, to, tokenId, uri, _useNonce(tokenId), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        address owner = getAuthority().chroniclesAgent(); // The owner of generating NFTs is the Chronicles Agent
        if (signer != owner) {
            revert ERC721DelegatedActions__ERC2612InvalidSigner(signer, owner);
        }

        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _setTokenRoyalty(tokenId, beneficiary, ROYALTY_FEE);
    }

    /**
     * @notice Delegates the update of a token's metadata URI.
     * @dev Requires an off-chain signature from the authorized party.
     * @param applyDiscount Whether to apply a discount to the token URI update.
     * @param tokenId The ID of the token to update.
     * @param uri The new metadata URI for the token.
     * @param deadline The deadline until when the signature is valid.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     * @notice Once a signature is generated, it must be used before another signature is generated for the same token; otherwise, it will become obsolete.
     */
    function _delegateSetTokenURI(
        bool applyDiscount,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal virtual {
        if (block.timestamp > deadline) {
            revert ERC721DelegatedActions__ERC2612ExpiredSignature(deadline);
        }

        bytes32 structHash = keccak256(
            abi.encode(DELEGATE_SET_TOEKN_URI_TYPEHASH, applyDiscount, tokenId, uri, _useNonce(tokenId), deadline)
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        address owner = getAuthority().chroniclesAgent(); // The owner of generating NFTs is the Chronicles Agent
        if (signer != owner) {
            revert ERC721DelegatedActions__ERC2612InvalidSigner(signer, owner);
        }

        _setTokenURI(tokenId, uri);
    }

    /**
     * @inheritdoc IERC721DelegatedActions
     */
    function nonces(uint256 tokenId)
        public
        view
        virtual
        override(IERC721DelegatedActions, ERC721Nonces)
        returns (uint256)
    {
        return super.nonces(tokenId);
    }

    /**
     * @inheritdoc IERC721DelegatedActions
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
