// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {ERC721DelegatedActions} from "./ERC721DelegatedActions.sol";
import {IDAChronicle} from "./IDAChronicle.sol";

//    ____    ______  ______   ____     __                                       ___                    
//   /\  _`\ /\  _  \/\__  _\ /\  _`\  /\ \                           __        /\_ \                   
//   \ \ \/\ \ \ \L\ \/_/\ \/ \ \ \/\_\\ \ \___   _ __   ___     ___ /\_\    ___\//\ \      __    ____  
//    \ \ \ \ \ \  __ \ \ \ \  \ \ \/_/_\ \  _ `\/\`'__\/ __`\ /' _ `\/\ \  /'___\\ \ \   /'__`\ /',__\ 
//     \ \ \_\ \ \ \/\ \ \_\ \__\ \ \L\ \\ \ \ \ \ \ \//\ \L\ \/\ \/\ \ \ \/\ \__/ \_\ \_/\  __//\__, `\
//      \ \____/\ \_\ \_\/\_____\\ \____/ \ \_\ \_\ \_\\ \____/\ \_\ \_\ \_\ \____\/\____\ \____\/\____/
//       \/___/  \/_/\/_/\/_____/ \/___/   \/_/\/_/\/_/ \/___/  \/_/\/_/\/_/\/____/\/____/\/____/\/___/  

// ================================================================
// │                           ERRORS                             │
// ================================================================
/**
 * @dev Thrown when a cooldown period is still active for the specified token.
 * @param tokenId The ID of the token that is under cooldown.
 */
error DAChronicle__CooldownActive(uint256 tokenId);

/**
 * @dev Thrown when an invalid base cooldown argument is provided.
 * @param newBaseCooldown The invalid base cooldown value.
 */
error DAChronicle__InvalidBaseCooldownArgument(uint16 newBaseCooldown);

/**
 * @title DAChronicle
 * @dev ERC721 contract that adds cooldowns for updating token metadata via `setTokenURI`.
 * Each token has its own independent cooldown, which increases exponentially
 * after each use, until it reaches a cap. The cooldown is reset when a new
 * NFT is minted.
 * Extends delegated action functionality with signature-based authorization.
 */
contract DAChronicle is ERC721DelegatedActions, IDAChronicle {
    // ================================================================
    // │                     Type declarations                        │
    // ================================================================

    /// @dev Struct representing a cooldown for a specific token.
    struct Cooldown {
        uint256 count; // The number of times the URI has been updated
        uint256 timestamp; // Timestamp when the cooldown expires
    }

    // ================================================================
    // │                      State variables                         │
    // ================================================================

    bool public s_cooldownEnabled; // Whether cooldowns are enabled
    uint16 public s_baseCooldownDays; // Base cooldown in days
    uint16 public s_maxCooldownDays; // Maximum cooldown cap in days
    uint256 public s_maxCooldownSeconds; // Maximum cooldown cap in seconds

    mapping(uint256 tokenId => Cooldown cooldown) private s_tokenCooldowns; // Token-specific cooldowns

    // ================================================================
    // │                           Events                             │
    // ================================================================

    /**
     * @dev Emitted when the cooldown is set for a token.
     * @param tokenId The ID of the token for which the cooldown is set.
     * @param cooldown The cooldown period applied to the token (i.e. the update count and cooldown end timestamp).
     */
    event CooldownSet(uint256 indexed tokenId, Cooldown cooldown);

    /**
     * @dev Emitted when the cooldowns are enabled or disabled.
     * @param enabled True if the cooldowns are enabled, false otherwise.
     */
    event CooldownEnabled(bool enabled);

    /**
     * @dev Emitted when the base cooldown is updated.
     * @param previousBaseCooldown The previous base cooldown value in days.
     * @param newBaseCooldown The new base cooldown value in days.
     */
    event BaseCooldownUpdated(uint16 previousBaseCooldown, uint16 newBaseCooldown);

    /**
     * @dev Emitted when the max cooldown is updated.
     * @param previousMaxCooldown The previous max cooldown value in days.
     * @param newMaxCooldown The new max cooldown value in days.
     */
    event MaxCooldownUpdated(uint16 previousMaxCooldown, uint16 newMaxCooldown);

    // ================================================================
    // │                         Modifiers                            │
    // ================================================================

    /**
     * @dev Modifier to ensure the cooldown period for a token has elapsed.
     * Reverts if the cooldown is still active.
     * @param tokenId The ID of the token being checked.
     */
    modifier cooldownElapsed(uint256 tokenId) {
        if (s_cooldownEnabled) {
            _checkAndUpdateCooldown(tokenId);
        }
        _;
    }

    // ================================================================
    // │                        Constructor                           │
    // ================================================================
    /**
     * @param initialAuthority The address of the initial authority of the contract
     * @param baseCooldown The base cooldown in days for the first `setTokenURI`
     * @param maxCooldown The maximum cooldown cap in days
     */
    constructor(address initialAuthority, bool cooldownEnabled, uint16 baseCooldown, uint16 maxCooldown)
        ERC721DelegatedActions("DAC Chronicles", "CHRON", initialAuthority)
    {
        s_cooldownEnabled = cooldownEnabled;
        s_baseCooldownDays = baseCooldown;
        s_maxCooldownDays = maxCooldown;
        s_maxCooldownSeconds = uint256(maxCooldown) * 1 days;
        emit CooldownEnabled(cooldownEnabled);
        emit BaseCooldownUpdated(0, baseCooldown);
        emit MaxCooldownUpdated(0, maxCooldown);
    }

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @inheritdoc IDAChronicle
     * @dev Can only be called by the treasury.
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
    ) external override onlyTreasury {
        s_tokenCooldowns[tokenId] = Cooldown(0, block.timestamp); // Reset the cooldown for the token
        _delegateSafeMint(isSale, to, tokenId, uri, deadline, v, r, s, beneficiary);
    }

    /**
     * @inheritdoc IDAChronicle
     * @dev Throws if the token has an active cooldown.
     * Can only be called by the treasury.
     */
    function delegateSetTokenURI(
        bool applyDiscount,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override onlyTreasury cooldownElapsed(tokenId) {
        _delegateSetTokenURI(applyDiscount, tokenId, uri, deadline, v, r, s);
    }

    /**
     * @dev Mints a new token and resets the cooldown for that token.
     * Only the Chronicles Agent can call this method.
     * @param to The address to mint the token to.
     * @param tokenId The tokenId of the new token.
     * @param uri The URI to set for the token.
     * @param beneficiary The address to receive royalties from the token.
     */
    function safeMint(address to, uint256 tokenId, string calldata uri, address beneficiary)
        public
        onlyChroniclesAgent
    {
        s_tokenCooldowns[tokenId] = Cooldown(0, block.timestamp); // Reset the cooldown for the token
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _setTokenRoyalty(tokenId, beneficiary, ROYALTY_FEE);
    }

    /**
     * @dev Sets a new URI for a given token. If a cooldown is active, it prevents
     * setting a new URI until the cooldown period has passed. Only the Chronicles Agent can call this method.
     * @param tokenId The tokenId for which the URI is being updated.
     * @param uri The new URI to set.
     */
    function setTokenURI(uint256 tokenId, string calldata uri) public onlyChroniclesAgent cooldownElapsed(tokenId) {
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Enables or disables the cooldowns for updating token URIs.
     * @param enabled True to enable the cooldowns, false to disable them.
     *
     * Emits a {CooldownEnabled} event.
     */
    function enableCooldowns(bool enabled) public onlyAdmin {
        s_cooldownEnabled = enabled;
        emit CooldownEnabled(enabled);
    }

    /**
     * @dev Allows the owner to update the base cooldown value.
     * @param newBaseCooldownDays The new base cooldown value in days.
     */
    function updateBaseCooldown(uint16 newBaseCooldownDays) public onlyAdmin {
        if (newBaseCooldownDays == 0) {
            revert DAChronicle__InvalidBaseCooldownArgument(newBaseCooldownDays);
        }
        uint16 previousBaseCooldownDays = s_baseCooldownDays;
        s_baseCooldownDays = newBaseCooldownDays;
        emit BaseCooldownUpdated(previousBaseCooldownDays, newBaseCooldownDays);
    }

    /**
     * @dev Allows the owner to update the max cooldown cap value.
     * @param newMaxCooldownDays The new max cooldown value in days.
     *
     * Emits a {MaxCooldownUpdated} event.
     */
    function updateMaxCooldown(uint16 newMaxCooldownDays) public onlyAdmin {
        uint16 previousMaxCooldownDays = s_maxCooldownDays;
        s_maxCooldownDays = newMaxCooldownDays;
        s_maxCooldownSeconds = uint256(newMaxCooldownDays) * 1 days;
        emit MaxCooldownUpdated(previousMaxCooldownDays, newMaxCooldownDays);
    }

    /**
     * @dev Returns the current cooldown for a specific token.
     * @param tokenId The tokenId to check the cooldown for.
     * @return The current cooldown for the token.
     */
    function getCooldown(uint256 tokenId) public view returns (Cooldown memory) {
        return s_tokenCooldowns[tokenId];
    }

    /**
     * @dev Throws if the token has an active cooldown.
     * @param tokenId The tokenId to check the cooldown for.
     * Then updates the cooldown. Note: Update cooldown: increment by the baseCooldown raised to the power of the number of updates
     *
     * Emits a {CooldownSet} event.
     */
    function _checkAndUpdateCooldown(uint256 tokenId) private {
        Cooldown storage cooldown = s_tokenCooldowns[tokenId];

        if (cooldown.timestamp > block.timestamp) {
            revert DAChronicle__CooldownActive(tokenId);
        }

        // Update cooldown: increment by the baseCooldown raised to the power of the number of updates
        uint256 nextCooldownSeconds = uint256(s_baseCooldownDays) ** (cooldown.count + 1) * 1 days;

        // Apply the cap if necessary
        nextCooldownSeconds = nextCooldownSeconds > s_maxCooldownSeconds ? s_maxCooldownSeconds : nextCooldownSeconds;

        // Set the new cooldown for the token
        cooldown.count += 1;
        cooldown.timestamp = block.timestamp + nextCooldownSeconds;
        emit CooldownSet(tokenId, cooldown);
    }
}
