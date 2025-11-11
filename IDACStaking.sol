// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// ================================================================
// │                           ERRORS                             │
// ================================================================
/**
 * @dev Thrown when the token address is not allowed.
 * @param token The address of the token that is not allowed.
 */
error DACStaking__TokenNotAllowed(address token);
/**
 * @dev Thrown when the multiplier is less than or equal to 1.
 */
error DACStaking__NeedsMultiplierMoreThanOne();
/**
 * @dev Thrown when the amount is less than or equal to 0.
 */
error DACStaking__NeedsAmountMoreThanZero();
/**
 * @dev Thrown when the staked amount is less than the amount to unstake or when the user tries to set a political bias without any stake.
 */
error DACStaking__InsufficientStakedAmount();
/**
 * @dev Thrown when a transfer fails.
 * @param from The address from which the transfer failed.
 * @param to The address to which the transfer failed.
 * @param token The address of the token that failed to transfer.
 * @param amount The amount that failed to transfer.
 */
error DACStaking__TransferFailed(address from, address to, address token, uint256 amount);
/**
 * @dev Thrown when attempting to set a bias that is not one of the enum values.
 */
error DACStaking__InvalidBias();
/**
 * @dev Thrown when a user tries to set bias before cooldown expires.
 */
error DACStaking__BiasCooldownActive();

/**
 * @title IDACStaking
 * @notice Interface for interacting with the DACStaking contract, central to staking within DAC Ecosystem.
 * @dev Interface for the DACStaking contract.
 */
interface IDACStaking {
    // ================================================================
    // │                     Type declarations                        │
    // ================================================================

    /// @dev Struct representing a stake
    struct Stake {
        uint256 amount; // Amount of tokens staked
        uint256 timestamp; // Timestamp when the stake was created
    }

    /**
     * @dev Enum representing political bias levels.
     * ‒ Neutral = 0 (default)
     * ‒ Left    = 1
     * ‒ Right   = 2
     */
    enum Bias {
        Neutral,
        Left,
        Right
    }

    // ================================================================
    // │                           Events                             │
    // ================================================================

    /// @dev Emitted when a user stakes tokens
    event Staked(address indexed user, uint256 amount, uint256 timestamp);

    /// @dev Emitted when a user unstakes tokens
    event Unstaked(address indexed user, uint256 amount, uint256 timestamp);

    /// @dev Emitted when the minimum lock period is updated
    event MinimumLockPeriodUpdated(uint16 newMinimumLockPeriod);

    /// @dev Emitted when the warmup period is updated
    event WarmupPeriodUpdated(uint16 newWarmupPeriod);

    /// @dev Emitted when the eligibility for reward scaling is updated
    event EligibilityForRewardScalingUpdated(bool isEligible);

    /// @dev Emitted when the hot period is updated
    event HotPeriodUpdated(uint16 newHotPeriod);

    /// @dev Emitted when the maximum reward multiplier is updated
    event MaxRewardMultiplierUpdated(uint8 newMaxRewardMultiplier);

    /// @dev Emitted when a user updates their political bias.
    event BiasUpdated(address indexed user, Bias oldBias, Bias newBias);

    /// @dev Emitted when the cooldown feature is enabled or disabled
    event CooldownEnabledUpdated(bool isEnabled);

    /// @dev Emitted when the cooldown period is updated
    event CooldownPeriodUpdated(uint16 newCooldownPeriod);

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    /**
     * @dev Allows users to stake a specific amount of the staking token.
     * @param amount Amount of tokens to stake.
     */
    function stake(uint256 amount) external;

    /**
     * @dev Allows users to unstake a specific amount of the staking token.
     * @param amount Amount of tokens to unstake.
     */
    function unstake(uint256 amount) external;

    /**
     * @dev Retrieves the raw total amount staked by a user without considering reward multipliers.
     * @param user Address of the user.
     * @return totalStaked Raw total staked amount.
     */
    function getTotalStaked(address user) external view returns (uint256);

    /**
     * @dev Retrieves the total amount staked by a user, considering current reward multipliers.
     * @param user Address of the user.
     * @return totalWithMultipliers Total staked amount with multipliers applied.
     */
    function getTotalStakedWithMultipliers(address user) external view returns (uint256);

    /**
     * @dev Retrieves all stakes of a user.
     * @param user Address of the user.
     * @return userStakes Array of Stake structs representing the user's stakes.
     */
    function getUserStakes(address user) external view returns (Stake[] memory);

    /**
     * @dev Allows the admin to update the minimum lock period.
     * @param periodInDays New minimum lock period in days.
     */
    function setMinimumLockPeriod(uint16 periodInDays) external;

    /**
     * @dev Allows the admin to update the warmup period.
     * @param periodInDays New warmup period in days.
     */
    function setWarmupPeriod(uint16 periodInDays) external;

    /**
     * @dev Allows the admin to enable or disable reward eligibility.
     * @param isEligible New eligibility status for rewards.
     */
    function setEligibilityForRewards(bool isEligible) external;

    /**
     * @dev Allows the admin to update the hot period.
     * @param periodInDays New hot period in days.
     */
    function setHotPeriod(uint16 periodInDays) external;

    /**
     * @dev Allows the admin to update the maximum reward multiplier.
     * @param multiplier New maximum reward multiplier.
     */
    function setMaxRewardMultiplier(uint8 multiplier) external;

    /**
     * @dev Allows the admin to enable or disable the bias cooldown feature.
     * @param isEnabled New status for the bias cooldown (true = enabled, false = disabled).
     */
    function setCooldownEnabled(bool isEnabled) external;

    /**
     * @dev Allows the admin to update the bias cooldown period.
     * @param periodInDays New cooldown period in days.
     */
    function setCooldownPeriod(uint16 periodInDays) external;

    /**
     * @dev Allows a user to set their political bias for all their stakes.
     * @param bias The new political bias (Neutral/Left/Right).
     */
    function setBias(Bias bias) external;

    /**
     * @dev Retrieves the political bias of a user.
     * @param user Address of the user.
     * @return bias The political bias of the user.
     */
    function getBias(address user) external view returns (Bias);

    /**
     * @dev Returns the last bias cooldown timestamp for a specific user.
     * @param user The user to check the cooldown for.
     * @return The last bias cooldown timestamp for the user.
     */
    function getLastBiasTimestamp(address user) external view returns (uint256);
}
