// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title IDACSwapper
 * @notice Interface for swapping tokens within the DAC Treasury, facilitating asset backing swaps for the DAC ecosystem.
 * @dev Defines the required functions for DAC Swapper contracts.
 */
interface IDACSwapper {
    /**
     * @notice Performs a token swap from `fromToken` to `toToken` and transfers the resulting tokens back to the caller (the DAC Treasury).
     * @dev The caller must have approved the contract to spend `amountIn` of `fromToken`.
     * @dev Only callable by the DAC Treasury.
     * @param fromToken The address of the ERC-20 token to swap (e.g., the treasury's token).
     * @param toToken The address of the ERC-20 token to receive after the swap.
     * @param amountIn The amount of `fromToken` to swap.
     * @param amountOutMin The minimum acceptable amount of `toToken` to receive.
     * @return amountOut The actual amount of `toToken` received from the swap.
     */
    function swapTokens(address fromToken, address toToken, uint256 amountIn, uint256 amountOutMin)
        external
        returns (uint256 amountOut);
}
