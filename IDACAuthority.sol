// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title IDACAuthority
 * @dev Interface for the DACAuthority contract, which defines events and functions
 * that other contracts in the DAC (Decentralized AI Chronicles) ecosystem can interact with.
 */
interface IDACAuthority {
    // ================================================================
    // │                           Events                             │
    // ================================================================

    /**
     * @dev Emitted when the admin account is updated.
     * @param previousAdmin The address of the previous admin.
     * @param newAdmin The address of the new admin.
     */
    event AdminSet(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Emitted when the chronicles agent account is updated.
     * @param previousChroniclesAgent The address of the previous chronicles agent.
     * @param newChroniclesAgent The address of the new chronicles agent.
     */
    event ChroniclesAgentSet(address indexed previousChroniclesAgent, address indexed newChroniclesAgent);

    /**
     * @dev Emitted when the liquidity manager agent account is updated.
     * @param previousLiquidityAgent The address of the previous liquidity manager agent.
     * @param liquidityAgent The address of the new liquidity manager agent.
     */
    event LiquidityAgentSet(address indexed previousLiquidityAgent, address indexed liquidityAgent);

    /**
     * @dev Emitted when the treasurer agent account is updated.
     * @param previousTreasurerAgent The address of the previous treasurer agent.
     * @param treasurerAgent The address of the new treasurer agent.
     */
    event TreasurerAgentSet(address indexed previousTreasurerAgent, address indexed treasurerAgent);

    /**
     * @dev Emitted when the treasury contract is updated.
     * @param previousTreasury The address of the previous treasury contract.
     * @param newTreasury The address of the new treasury contract.
     */
    event TreasurySet(address indexed previousTreasury, address indexed newTreasury);

    /**
     * @dev Emitted when a new swapper is proposed to be whitelisted.
     * @param swapper The address of the swapper proposed to be whitelisted.
     * @param activationTime The timestamp when the swapper becomes active.
     */
    event SwapperWhitelisted(address indexed swapper, uint256 activationTime);

    /**
     * @dev Emitted when a swapper is disabled.
     * @param swapper The address of the swapper that has been disabled.
     */
    event SwapperDisabled(address indexed swapper);

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @notice Returns the address of the admin account.
     * @return The current admin address.
     */
    function admin() external view returns (address);

    /**
     * @notice Returns the address of the chronicles agent account.
     * @return The current chronicles agent address.
     */
    function chroniclesAgent() external view returns (address);

    /**
     * @notice Returns the address of the liquidity manager agent account.
     * @return The current liquidity manager agent address.
     */
    function liquidityManagerAgent() external view returns (address);

    /**
     * @notice Returns the address of the treasurer agent account.
     * @return The current treasurer agent address.
     */
    function treasurerAgent() external view returns (address);

    /**
     * @notice Returns the address of the treasury contract.
     * @return The current treasury contract address.
     */
    function treasury() external view returns (address);

    /**
     * @notice Checks if an address is an active swapper.
     * @param account The address to check.
     * @return True if the address is an active swapper, false otherwise.
     */
    function isSwapper(address account) external view returns (bool);

    /**
     * @notice Returns a list of all whitelisted swappers.
     * @return An array of swapper addresses.
     */
    function getSwappers() external view returns (address[] memory);

    /**
     * @notice Returns the activation timestamp of a swapper.
     * @param account The swapper address.
     * @return The timestamp when the swapper becomes active.
     */
    function getSwapperActivationTime(address account) external view returns (uint256);
}
