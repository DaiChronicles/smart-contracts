// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IDACToken
 * @notice Interface for interacting with the DACToken contract, the central ERC-20 token of the DAC Ecosystem.
 * @dev Provides a function for minting new tokens, intended to be used by the contract owner, typically representing the ecosystem's treasury.
 */
interface IDACToken is IERC20 {
    /**
     * @notice Mints new tokens to a specified address.
     * @dev
     * - This function can only be called by the contract owner.
     * - The owner is expected to be the DAC Ecosystem treasury, ensuring responsible issuance of tokens.
     * - Refer to {DACAuthority} for details on ownership and access control.
     * @param to The address that will receive the newly minted tokens.
     * @param amount The amount of tokens to mint, denominated in the smallest unit of the token.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Destroys a `value` amount of tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external;
}
