// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";

// ================================================================
// │                           ERRORS                             │
// ================================================================

/**
 * @dev Thrown when the admin is not a valid admin account (e.g., `address(0)`).
 * @param adminAccount The invalid admin account.
 */
error DACAuthority__InvalidAdmin(address adminAccount);
/**
 * @dev Thrown when the Chronicles Agent is not a valid Chronicles Agent account (e.g., `address(0)`).
 * @param chroniclesAgentAccount The invalid Chronicles Agent account.
 */
error DACAuthority__InvalidChroniclesAgent(address chroniclesAgentAccount);
/**
 * @dev Thrown when the Liquidity Manager Agent is not a valid Liquidity Manager Agent account (e.g., `address(0)`).
 * @param liquidityAgentAccount The invalid Liquidity Manager Agent account.
 */
error DACAuthority__InvalidLiquidityAgent(address liquidityAgentAccount);
/**
 * @dev Thrown when the Treasurer Agent is not a valid Treasurer Agent account (e.g., `address(0)`).
 * @param treasurerAgentAccount The invalid Treasurer Agent account.
 */
error DACAuthority__InvalidTreasurerAgent(address treasurerAgentAccount);
/**
 * @dev Thrown when the treasury is not a valid treasury contract (e.g., `address(0)`).
 * @param treasury The invalid treasury account.
 */
error DACAuthority__InvalidTreasury(address treasury);
/**
 * @dev Thrown when trying to whitelist an invalid swapper account.
 * @param swapper The invalid swapper account.
 */
error DACAuthority__InvalidSwapper(address swapper);
/**
 * @dev Thrown when trying to whitelist a swapper that's already whitelisted.
 * @param swapper The swapper account already whitelisted.
 */
error DACAuthority__SwapperAlreadyWhitelisted(address swapper);
/**
 * @dev Thrown when trying to disable a swapper that's not whitelisted.
 * @param swapper The swapper account not whitelisted.
 */
error DACAuthority__SwapperNotWhitelisted(address swapper);

/**
 * @title DACAuthority
 * @dev Manages roles and permissions for the DAC (Decentralized AI Chronicles) ecosystem.
 * This contract serves as the central authority to manage access control across various
 * components of the DAC ecosystem. It allows for role management
 * and validation of permissions required by other contracts in the ecosystem.
 */
contract DACAuthority is IDACAuthority, DACAccessManaged {
    // ================================================================
    // │                           CONSTANTS                          │
    // ================================================================

    // Time period for which a swapper is timelocked
    uint256 public constant SWAPPER_TIMELOCK = 7 days;

    // ================================================================
    // │                      State variables                         │
    // ================================================================

    address private s_admin;
    address private s_chroniclesAgent;
    address private s_liquidityAgent;
    address private s_treasurerAgent;
    address private s_treasury;

    // Mapping from swapper address to activation timestamp
    mapping(address => uint256) private s_swappers;

    // Array to keep track of all swappers for enumeration
    address[] private s_swapperList;

    // ================================================================
    // │                        Constructor                           │
    // ================================================================

    constructor(
        address initialAdmin,
        address initialChroniclesAgent,
        address initialLiquidityAgent,
        address initialTreasurerAgent
    ) DACAccessManaged(IDACAuthority(address(this))) {
        if (initialAdmin == address(0)) {
            revert DACAuthority__InvalidAdmin(address(0));
        }
        if (initialChroniclesAgent == address(0)) {
            revert DACAuthority__InvalidChroniclesAgent(address(0));
        }
        if (initialLiquidityAgent == address(0)) {
            revert DACAuthority__InvalidLiquidityAgent(address(0));
        }
        if (initialTreasurerAgent == address(0)) {
            revert DACAuthority__InvalidTreasurerAgent(address(0));
        }
        _setAdmin(initialAdmin);
        _setChroniclesAgent(initialChroniclesAgent);
        _setLiquidityAgent(initialLiquidityAgent);
        _setTreasurerAgent(initialTreasurerAgent);
    }

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @dev Set the new DAC Admin.
     * Can only be called by the current admin.
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        if (newAdmin == address(0)) {
            revert DACAuthority__InvalidAdmin(address(0));
        }
        _setAdmin(newAdmin);
    }

    /**
     * @dev Set the new DAC Chronicles Agent.
     * Can only be called by the current admin.
     */
    function setChroniclesAgent(address newChroniclesAgent) external onlyAdmin {
        if (newChroniclesAgent == address(0)) {
            revert DACAuthority__InvalidChroniclesAgent(address(0));
        }
        _setChroniclesAgent(newChroniclesAgent);
    }

    /**
     * @dev Set the new Liquidity Manager Agent.
     * Can only be called by the current admin.
     */
    function setLiquidityAgent(address newLiquidityAgent) external onlyAdmin {
        if (newLiquidityAgent == address(0)) {
            revert DACAuthority__InvalidLiquidityAgent(address(0));
        }
        _setLiquidityAgent(newLiquidityAgent);
    }

    /**
     * @dev Set the new Treasurer Agent.
     * Can only be called by the current admin.
     */
    function setTreasurerAgent(address newTreasurerAgent) external onlyAdmin {
        if (newTreasurerAgent == address(0)) {
            revert DACAuthority__InvalidTreasurerAgent(address(0));
        }
        _setTreasurerAgent(newTreasurerAgent);
    }

    /**
     * @dev Set the new DAC Treasury.
     * Can only be called by the current admin.
     */
    function setTreasury(address newTreasury) external onlyAdmin {
        if (newTreasury == address(0)) {
            revert DACAuthority__InvalidTreasury(address(0));
        }
        _setTreasury(newTreasury);
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function admin() external view override returns (address) {
        return s_admin;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function chroniclesAgent() external view override returns (address) {
        return s_chroniclesAgent;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function liquidityManagerAgent() external view override returns (address) {
        return s_liquidityAgent;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function treasurerAgent() external view override returns (address) {
        return s_treasurerAgent;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function treasury() external view override returns (address) {
        return s_treasury;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function isSwapper(address account) external view override returns (bool) {
        uint256 activationTime = s_swappers[account];
        return activationTime != 0 && block.timestamp >= activationTime;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function getSwappers() external view override returns (address[] memory) {
        return s_swapperList;
    }

    /**
     * @inheritdoc IDACAuthority
     */
    function getSwapperActivationTime(address account) external view override returns (uint256) {
        return s_swappers[account];
    }

    /**
     * @dev Whitelists a new swapper with a 7-day activation timelock.
     * Can only be called by the admin.
     * @param swapper The address to be whitelisted as a swapper.
     */
    function whitelistSwapper(address swapper) external onlyAdmin {
        if (swapper == address(0)) {
            revert DACAuthority__InvalidSwapper(swapper);
        }
        if (s_swappers[swapper] != 0) {
            revert DACAuthority__SwapperAlreadyWhitelisted(swapper);
        }
        uint256 activationTime = block.timestamp + SWAPPER_TIMELOCK;
        s_swappers[swapper] = activationTime;
        s_swapperList.push(swapper);
        emit SwapperWhitelisted(swapper, activationTime);
    }

    /**
     * @dev Disables a swapper immediately.
     * Can only be called by the admin.
     * @param swapper The address of the swapper to disable.
     */
    function disableSwapper(address swapper) external onlyAdmin {
        if (s_swappers[swapper] == 0) {
            revert DACAuthority__SwapperNotWhitelisted(swapper);
        }
        delete s_swappers[swapper];
        // Remove from swapperList
        for (uint256 i = 0; i < s_swapperList.length; i++) {
            if (s_swapperList[i] == swapper) {
                s_swapperList[i] = s_swapperList[s_swapperList.length - 1];
                s_swapperList.pop();
                break;
            }
        }
        emit SwapperDisabled(swapper);
    }

    /**
     * @dev Set the new DAChronicle Admin.
     * Private function without access restriction.
     */
    function _setAdmin(address newAdmin) private {
        address oldAdmin = s_admin;
        s_admin = newAdmin;
        emit AdminSet(oldAdmin, newAdmin);
    }

    /**
     * @dev Set the new DAC Chronicles Agent.
     * Private function without access restriction.
     */
    function _setChroniclesAgent(address newChroniclesAgent) private {
        address oldChroniclesAgent = s_chroniclesAgent;
        s_chroniclesAgent = newChroniclesAgent;
        emit ChroniclesAgentSet(oldChroniclesAgent, newChroniclesAgent);
    }

    /**
     * @dev Set the new DAC Liquidity Manager Agent.
     * Private function without access restriction.
     */
    function _setLiquidityAgent(address newLiquidityAgent) private {
        address oldLiquidityAgent = s_liquidityAgent;
        s_liquidityAgent = newLiquidityAgent;
        emit LiquidityAgentSet(oldLiquidityAgent, newLiquidityAgent);
    }

    /**
     * @dev Set the new DAC Treasurer Agent.
     * Private function without access restriction.
     */
    function _setTreasurerAgent(address newTreasurerAgent) private {
        address oldTreasurerAgent = s_treasurerAgent;
        s_treasurerAgent = newTreasurerAgent;
        emit TreasurerAgentSet(oldTreasurerAgent, newTreasurerAgent);
    }

    /**
     * @dev Set the new DAC Treasury.
     * Private function without access restriction.
     */
    function _setTreasury(address newTreasury) private {
        address oldTreasury = s_treasury;
        s_treasury = newTreasury;
        emit TreasurySet(oldTreasury, newTreasury);
    }
}
