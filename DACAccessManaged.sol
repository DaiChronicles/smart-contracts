// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IDACAuthority} from "./IDACAuthority.sol";

// ================================================================
// │                           ERRORS                             │
// ================================================================

/**
 * @dev Thrown when the authority is not a authority contract (e.g., `address(0)`).
 * @param authority The invalid authority contract.
 */
error DACAuthority__InvalidAuthority(address authority);
/**
 * @dev Thrown when the caller is not authorized to perform an admin operation.
 * @param account The address of the unauthorized caller.
 */
error DACAccessManaged__AdminUnauthorizedAccount(address account);
/**
 * @dev Thrown when the caller is not authorized to perform a chronicles agent operation.
 * @param account The address of the unauthorized caller.
 */
error DACAccessManaged__ChroniclesAgentUnauthorizedAccount(address account);
/**
 * @dev Thrown when the caller is not authorized to perform a liquidity manager agent operation.
 * @param account The address of the unauthorized caller.
 */
error DACAccessManaged__LiquidityAgentUnauthorizedAccount(address account);
/**
 * @dev Thrown when the caller is not authorized to perform a treasurer agent operation.
 * @param account The address of the unauthorized caller.
 */
error DACAccessManaged__TreasurerAgentUnauthorizedAccount(address account);
/**
 * @dev Thrown when the caller is not authorized to perform a treasury operation.
 * @param treasury The address of the unauthorized caller.
 */
error DACAccessManaged__TreasuryUnauthorizedAccount(address treasury);
/**
 * @dev Thrown when the provided address is not authorized to perform a swapper operation.
 * @param account The address of the unauthorized swapper.
 */
error DACAccessManaged__SwapperUnauthorizedAccount(address account);
/**
 * @dev Thrown when a new authority is not yet proposed.
 */
error DACAuthority__NewAuthorityNotProposed();
/**
 * @dev Thrown when trying to activate an authority before the timelock has passed.
 * @param authority The authority address.
 * @param activationTime The required activation time.
 */
error DACAuthority__AuthorityTimelockNotPassed(address authority, uint256 activationTime);

/**
 * @title DACAccessManaged
 * @dev Abstract contract that provides access control mechanisms for contracts
 * in the DAC (Decentralized AI Chronicles) ecosystem. This contract acts as a
 * base for managing access permissions for different roles such as admin, chronicles agent,
 * liquidity manager agent, treasurer agent, treasury, and swapper.
 */
abstract contract DACAccessManaged {
    // ================================================================
    // │                           CONSTANTS                          │
    // ================================================================

    // Time period for which a new authority is timelocked
    uint256 public constant AUTHORITY_TIMELOCK = 7 days;

    // ================================================================
    // │                      State variables                         │
    // ================================================================

    /**
     * @dev The DACAuthority contract that manages roles and permissions for the DAC ecosystem.
     */
    IDACAuthority private s_authority;

    // Proposed authority change
    IDACAuthority private s_proposedAuthority;
    uint256 private s_authorityChangeExecutionTime;

    // ================================================================
    // │                           Events                             │
    // ================================================================

    /**
     * @dev Emitted when a proposed authority change is executed.
     * @param previousAuthority The address of the previous DACAuthority contract.
     * @param newAuthority The address of the new DACAuthority contract.
     */
    event AuthorityChangeExecuted(address indexed previousAuthority, address indexed newAuthority);

    /**
     * @dev Emitted when a new authority change is proposed.
     * @param proposedAuthority The address of the proposed new authority.
     * @param executionTime The timestamp when the authority change can be executed.
     */
    event AuthorityChangeProposed(address indexed proposedAuthority, uint256 executionTime);

    // ================================================================
    // │                         Modifiers                            │
    // ================================================================

    /**
     * @dev Modifier to restrict access to admin operations.
     * Reverts if the caller is not authorized.
     */
    modifier onlyAdmin() {
        if (s_authority.admin() != msg.sender) {
            revert DACAccessManaged__AdminUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to restrict access to chronicles agent operations.
     * Reverts if the caller is not authorized.
     */
    modifier onlyChroniclesAgent() {
        if (s_authority.chroniclesAgent() != msg.sender) {
            revert DACAccessManaged__ChroniclesAgentUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to restrict access to Liquidity Manager Agent operations.
     * Reverts if the caller is not authorized.
     */
    modifier onlyLiquidityAgent() {
        if (s_authority.liquidityManagerAgent() != msg.sender) {
            revert DACAccessManaged__LiquidityAgentUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to restrict access to Treasurer Agent operations.
     * Reverts if the caller is not authorized.
     */
    modifier onlyTreasurerAgent() {
        if (s_authority.treasurerAgent() != msg.sender) {
            revert DACAccessManaged__TreasurerAgentUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to restrict access to treasury operations.
     * Reverts if the caller is not authorized.
     */
    modifier onlyTreasury() {
        if (s_authority.treasury() != msg.sender) {
            revert DACAccessManaged__TreasuryUnauthorizedAccount(msg.sender);
        }
        _;
    }

    /**
     * @dev Modifier to restrict access to swapper operations.
     * @param swapper The address of the swapper to check.
     * Reverts if the caller is not an active swapper.
     */
    modifier onlySwapper(address swapper) {
        if (!s_authority.isSwapper(swapper)) {
            revert DACAccessManaged__SwapperUnauthorizedAccount(swapper);
        }
        _;
    }

    // ================================================================
    // │                        Constructor                           │
    // ================================================================

    /**
     * @notice Initializes the contract with the specified DACAuthority instance.
     * @param authority The address of the DACAuthority contract.
     */
    constructor(IDACAuthority authority) {
        if (address(authority) == address(0)) {
            revert DACAuthority__InvalidAuthority(address(0));
        }
        s_authority = authority;
        emit AuthorityChangeExecuted(address(0), address(authority));
    }

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @notice Returns the address of the current DACAuthority contract.
     * @return The current DACAuthority contract.
     */
    function getAuthority() public view returns (IDACAuthority) {
        return s_authority;
    }

    /**
     * @notice Proposes a new DACAuthority contract with a 7-day timelock.
     * @dev Can only be called by the admin.
     * Emits an {AuthorityChangeProposed} event.
     * @param newAuthority The address of the new DACAuthority contract.
     */
    function proposeAuthorityChange(IDACAuthority newAuthority) external onlyAdmin {
        if (address(newAuthority) == address(0)) {
            revert DACAuthority__InvalidAuthority(address(0));
        }
        s_proposedAuthority = newAuthority;
        s_authorityChangeExecutionTime = block.timestamp + AUTHORITY_TIMELOCK;
        emit AuthorityChangeProposed(address(newAuthority), s_authorityChangeExecutionTime);
    }

    /**
     * @notice Executes the previously proposed authority change after the timelock.
     * @dev Can only be called by the admin.
     * Emits an {AuthorityChangeExecuted} event.
     */
    function executeAuthorityChange() external onlyAdmin {
        if (address(s_proposedAuthority) == address(0)) {
            revert DACAuthority__NewAuthorityNotProposed();
        }
        if (block.timestamp < s_authorityChangeExecutionTime) {
            revert DACAuthority__AuthorityTimelockNotPassed(
                address(s_proposedAuthority), s_authorityChangeExecutionTime
            );
        }
        address oldAuthority = address(s_authority);
        s_authority = s_proposedAuthority;
        s_proposedAuthority = IDACAuthority(address(0));
        s_authorityChangeExecutionTime = 0;
        emit AuthorityChangeExecuted(address(oldAuthority), address(s_authority));
    }

    /**
     * @notice Returns the address of the proposed new authority.
     * @return The proposed authority address.
     */
    function getProposedAuthority() external view returns (address) {
        return address(s_proposedAuthority);
    }

    /**
     * @notice Returns the timestamp when the authority change can be executed.
     * @return The execution timestamp.
     */
    function getAuthorityChangeExecutionTime() external view returns (uint256) {
        return s_authorityChangeExecutionTime;
    }
}
