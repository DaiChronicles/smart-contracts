// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// OpenZeppelin Imports
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Interfaces for the DAC ecosystem
import {IDACToken} from "./IDACToken.sol";
import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";

// ================================================================
// │                           ERRORS                             │
// ================================================================

/**
 * @dev Thrown when the address is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACRewardSplitter__InvalidAddress(address invalidAddress);
/**
 * @dev Throws when the transfer of DAC tokens fails.
 * @param from the address of the sender.
 * @param to the address of the receiver.
 * @param expectedAmount the amount of DAC tokens expected to be transferred.
 */
error DACRewardSplitter__DACTransferFailed(address from, address to, uint256 expectedAmount);
/**
 * @dev Throws when the contract's DAC balance does not match the expected value.
 * @param contractBalance the actual DAC balance of the contract.
 * @param totalOpenToClaim the total DAC tokens open to claim.
 * @param totalOpenReward the total DAC tokens open for rewards.
 * @param amount the amount of DAC tokens to be added.
 */
error DACRewardSplitter__ContractBalanceMismatch(
    uint256 contractBalance, uint256 totalOpenToClaim, uint256 totalOpenReward, uint256 amount
);
/**
 * @dev Throws when an array does not have at least one element.
 */
error DACRewardSplitter__ArrayMustHaveAtLeastOneElement();
/**
 * @dev Throws when two arrays do not have the same length.
 */
error DACRewardSplitter__ArraysMustHaveSameLength();
/**
 * @dev Throws when the value is not greater than zero.
 */
error DACRewardSplitter__ValueMustBeGreaterThanZero();
/**
 * @dev Throws when rewarding winners and the total open rewards are not greater than zero.
 */
error DACRewardSplitter__TotalOpenRewardsMustBeGreaterThanZero();
/**
 * @dev Throws when the total shares do not equal TOTAL_BASIS_POINTS.
 */
error DACRewardSplitter__TotalSharesMustEqualTotalBasisPoints();
/**
 * @dev Throws when the total rewarded exceeds the open rewards.
 */
error DACRewardSplitter__TotalRewardedExceedsOpenRewards();

/**
 * @title DACRewardSplitter
 * @dev Contract to manage DAC Token rewards for users in the DAC Ecosystem.
 * Implements a pull payment model where winners can claim their rewards.
 */
contract DACRewardSplitter is DACAccessManaged, ReentrancyGuard {
    // ================================================================
    // │                           CONSTANTS                          │
    // ================================================================

    /// @dev Total basis points used for calculations (100% = 10,000 basis points)
    uint256 public constant TOTAL_BASIS_POINTS = 10000;

    // ================================================================
    // │                      State Variables                        │
    // ================================================================

    /// @dev The DAC ERC-20 token contract
    IDACToken public immutable i_dacToken;

    /// @dev Total DAC tokens received for rewards that are still open to determine winners
    uint256 private s_totalOpenReward;

    /// @dev Total DAC tokens that are determined for winners but are yet to be claimed
    uint256 private s_totalOpenToClaim;

    /// @dev Total DAC tokens that have been released to winners
    uint256 private s_totalReleased;

    /// @dev Mapping from winner address to their claimable DAC token balance
    mapping(address => uint256) private s_balancesToClaim;

    // ================================================================
    // │                           EVENTS                             │
    // ================================================================

    /**
     * @dev Emitted when excess DAC tokens are added to the open rewards pool.
     * @param sender The address of the sender.
     * @param excessAmount The amount of excess DAC tokens added.
     */
    event ExcessDAC(address indexed sender, uint256 excessAmount);
    /**
     * @dev Emitted when DAC tokens are added to the open rewards pool.
     * @param sender The address of the sender.
     * @param amount The amount of DAC tokens added.
     */
    event OpenRewardAdded(address indexed sender, uint256 amount);

    /**
     * @dev Emitted when winners are rewarded.
     * @param winners The array of winner addresses.
     * @param shares The array of shares corresponding to each winner.
     * @param totalRewarded The total amount of DAC tokens rewarded.
     */
    event WinnersRewarded(address[] winners, uint256[] shares, uint256 totalRewarded);

    /**
     * @dev Emitted when a winner releases their reward.
     * @param winner The address of the winner.
     * @param amount The amount of DAC tokens released.
     */
    event RewardReleased(address indexed winner, uint256 amount);

    // ================================================================
    // │                         Modifiers                            │
    // ================================================================

    /**
     * @dev Modifier to check that the contract has open rewards.
     */
    modifier mustHaveOpenReward() {
        if (s_totalOpenReward == 0) {
            revert DACRewardSplitter__TotalOpenRewardsMustBeGreaterThanZero();
        }
        _;
    }

    /**
     * @dev Modifier to check that an array has at least one element.
     * @param array The array to check.
     */
    modifier nonEmptyArray(uint256[] calldata array) {
        if (array.length == 0) {
            revert DACRewardSplitter__ArrayMustHaveAtLeastOneElement();
        }
        _;
    }

    /**
     * @dev Modifier to check that two arrays have the same length.
     * @param winners The first array.
     * @param shares The second array.
     */
    modifier sameLength(address[] calldata winners, uint256[] calldata shares) {
        if (winners.length != shares.length) {
            revert DACRewardSplitter__ArraysMustHaveSameLength();
        }
        _;
    }

    // ================================================================
    // │                       Constructor                            │
    // ================================================================

    /**
     * @notice Initializes the DACRewardSplitter contract.
     * @param initialAuthority The address of the initial authority managing access controls.
     * @param dacToken The address of the DAC ERC-20 token contract.
     */
    constructor(address initialAuthority, address dacToken) DACAccessManaged(IDACAuthority(initialAuthority)) {
        if (dacToken == address(0)) {
            revert DACRewardSplitter__InvalidAddress(dacToken);
        }

        i_dacToken = IDACToken(dacToken);
    }

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @notice Adds DAC tokens to the open rewards pool.
     * @dev The DAC tokens must be transferred to this contract before calling.
     *      Validates that the contract's DAC balance equals s_totalOpenToClaim + s_totalOpenReward + amount.
     * @param amount The amount of DAC tokens to add to the open rewards.
     *
     * Note: Anyone can call this function to add DAC tokens to the open rewards pool.
     * And any excess DAC tokens in the contract will be added to the open rewards pool.
     *
     * Emits an {OpenRewardAdded} event.
     *
     * Requirements:
     * - Contract's DAC balance should equal s_totalOpenToClaim + s_totalOpenReward + amount.
     */
    function addToOpenReward(uint256 amount) external {
        if (amount == 0) {
            revert DACRewardSplitter__ValueMustBeGreaterThanZero();
        }

        uint256 _contractBalance = i_dacToken.balanceOf(address(this));
        uint256 _totalOpenToClaim = s_totalOpenToClaim;
        uint256 _totalOpenReward = s_totalOpenReward;
        uint256 _expectedContractBalance = _totalOpenToClaim + _totalOpenReward + amount;

        if (_contractBalance < _expectedContractBalance) {
            revert DACRewardSplitter__ContractBalanceMismatch(
                _contractBalance, _totalOpenToClaim, _totalOpenReward, amount
            );
        } else if (_contractBalance > _expectedContractBalance) {
            // The contract has more DAC tokens than expected, so we will add the difference to the open rewards
            uint256 excessAmount = _contractBalance - _totalOpenToClaim - _totalOpenReward - amount;
            amount += excessAmount;
            emit ExcessDAC(msg.sender, excessAmount);
        }

        s_totalOpenReward += amount;

        emit OpenRewardAdded(msg.sender, amount);
    }

    /**
     * @notice Rewards winners by allocating their shares.
     * @param winners The array of winner addresses.
     * @param shares The array of shares corresponding to each winner.
     *
     * Requirements:
     * - Caller must be the DAC Treasurer Agent.
     * - Both arrays must have the same length and contain at least one element.
     * - s_totalOpenReward must be greater than zero.
     * - Total shares must equal TOTAL_BASIS_POINTS.
     * - Total amount rewarded must be less than or equal to s_totalOpenReward.
     */
    function rewardWinners(address[] calldata winners, uint256[] calldata shares)
        external
        onlyTreasurerAgent
        mustHaveOpenReward
        nonEmptyArray(shares)
        sameLength(winners, shares)
    {
        uint256 totalShares = 0;
        uint256 totalRewarded = 0;

        for (uint256 i = 0; i < winners.length; i++) {
            address winner = winners[i];
            uint256 share = shares[i];

            totalShares += share;

            uint256 rewardedAmount = _addWinner(winner, share);
            totalRewarded += rewardedAmount;
        }

        if (totalShares != TOTAL_BASIS_POINTS) {
            revert DACRewardSplitter__TotalSharesMustEqualTotalBasisPoints();
        }
        if (totalRewarded > s_totalOpenReward) {
            revert DACRewardSplitter__TotalRewardedExceedsOpenRewards();
        }

        s_totalOpenReward -= totalRewarded;

        emit WinnersRewarded(winners, shares, totalRewarded);
    }

    /**
     * @notice Releases the rewarded DAC tokens to a winner.
     * @param winner The address of the winner to release rewards to.
     *
     * Requirements:
     * - Winner must have a balance greater than zero.
     */
    function release(address winner) external nonReentrant {
        if (winner == address(0)) {
            revert DACRewardSplitter__InvalidAddress(winner);
        }

        uint256 amount = s_balancesToClaim[winner];

        if (amount == 0) {
            revert DACRewardSplitter__ValueMustBeGreaterThanZero();
        }

        s_balancesToClaim[winner] = 0;
        s_totalReleased += amount;
        s_totalOpenToClaim -= amount;
        emit RewardReleased(winner, amount);

        // Transfer DAC tokens to the winner
        bool success = i_dacToken.transfer(winner, amount);
        if (!success) {
            revert DACRewardSplitter__DACTransferFailed(address(this), winner, amount);
        }
    }

    // ================================================================
    // │                        Getter Functions                      │
    // ================================================================

    /**
     * @notice Returns the claimable balance of a winner.
     * @param winner The address of the winner.
     * @return The amount of DAC tokens the winner can claim.
     */
    function balanceToClaim(address winner) external view returns (uint256) {
        return s_balancesToClaim[winner];
    }

    /**
     * @notice Returns the total DAC tokens available for rewards.
     * @return The total open rewards.
     */
    function totalOpenReward() external view returns (uint256) {
        return s_totalOpenReward;
    }

    /**
     * @notice Returns the total DAC tokens available to be claimed.
     * @return The total open to claim.
     */
    function totalOpenToClaim() external view returns (uint256) {
        return s_totalOpenToClaim;
    }

    /**
     * @notice Returns the total DAC tokens that have been released.
     * @return The total released.
     */
    function totalReleased() external view returns (uint256) {
        return s_totalReleased;
    }

    // ================================================================
    // │                        Private Functions                     │
    // ================================================================

    /**
     * @dev Adds a winner and calculates their reward based on shares.
     * @param winner The address of the winner.
     * @param shares The share of the total rewards allocated to the winner.
     * @return The amount of DAC tokens rewarded to the winner.
     */
    function _addWinner(address winner, uint256 shares) private returns (uint256) {
        if (winner == address(0)) {
            revert DACRewardSplitter__InvalidAddress(winner);
        }
        if (shares == 0) {
            revert DACRewardSplitter__ValueMustBeGreaterThanZero();
        }

        uint256 rewardedAmount = (s_totalOpenReward * shares) / TOTAL_BASIS_POINTS;
        s_balancesToClaim[winner] += rewardedAmount;
        s_totalOpenToClaim += rewardedAmount;
        return rewardedAmount;
    }
}
