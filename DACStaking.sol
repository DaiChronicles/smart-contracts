// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Import OpenZeppelin Contracts for security management
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// Import interfaces from the DAC ecosystem
import {DACToken} from "./DACToken.sol";
import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";
import {
    IDACStaking,
    DACStaking__TokenNotAllowed,
    DACStaking__NeedsMultiplierMoreThanOne,
    DACStaking__NeedsAmountMoreThanZero,
    DACStaking__InsufficientStakedAmount,
    DACStaking__TransferFailed,
    DACStaking__InvalidBias,
    DACStaking__BiasCooldownActive
} from "./IDACStaking.sol";

/**
 * @title DACStaking
 * @dev A staking contract for DAC ecosystem allowing users to stake, unstake, and earn rewards based on staking duration.
 */
contract DACStaking is ReentrancyGuard, DACAccessManaged, IDACStaking {
    // ================================================================
    // │                      State variables                         │
    // ================================================================

    /// @dev Multiplier scaling factor for precision
    uint256 private constant MULTIPLIER_PRECISION = 1e18;

    /// @dev Mapping from user address to their array of stakes
    mapping(address => Stake[]) private s_stakes;

    /// @dev Mapping to store each user’s political bias
    mapping(address => Bias) private s_userBias;

    /// @dev When a user last set their bias
    mapping(address => uint256) private s_lastBiasTimestamp;

    /// @dev Flag to enable/disable political bias cooldown
    bool public s_isCooldownEnabled;

    /// @dev The cooldown period in days before a user can set their bias again
    uint16 public s_cooldownPeriod;

    /// @dev The DAC token being staked
    DACToken public immutable i_dacToken;

    /// @dev Staking parameters
    bool public s_isEligibleForRewardScaling; // Flag to enable or disable reward scaling eligibility
    uint16 public s_minimumLockPeriod; // Minimum lock period in days before eligibility for rewards
    uint16 public s_warmupPeriod; // Warmup period in days for reward potential to reach 1x
    uint16 public s_hotPeriod; // Hot period in days for reward multiplier to reach maximum
    uint8 public s_maxRewardMultiplier; // Maximum reward multiplier (e.g., 10 for 10x)

    // ================================================================
    // │                        constructor                           │
    // ================================================================

    /**
     * @dev Constructor to initialize the staking contract with required parameters.
     * @param initialAuthority The address of the initial authority of the contract.
     * @param tokenAddress Address of the token to be staked.
     * @param isEligibleForRewardScaling Flag to set eligibility for reward scaling.
     * @param minimumLockPeriod Minimum lock period in days.
     * @param warmupPeriod Warmup period in days.
     * @param hotPeriod Hot period in days.
     * @param maxRewardMultiplier Maximum reward multiplier.
     */
    constructor(
        address initialAuthority,
        address tokenAddress,
        bool isEligibleForRewardScaling,
        uint16 minimumLockPeriod,
        uint16 warmupPeriod,
        uint16 hotPeriod,
        uint8 maxRewardMultiplier
    ) DACAccessManaged(IDACAuthority(initialAuthority)) {
        if (tokenAddress == address(0)) {
            revert DACStaking__TokenNotAllowed(tokenAddress);
        }
        i_dacToken = DACToken(tokenAddress);
        s_minimumLockPeriod = minimumLockPeriod;
        s_warmupPeriod = warmupPeriod;
        s_isEligibleForRewardScaling = isEligibleForRewardScaling;
        s_hotPeriod = hotPeriod;
        s_maxRewardMultiplier = maxRewardMultiplier;

        // By default, bias‐setting cooldown is disabled and set to 3 days
        s_isCooldownEnabled = false;
        s_cooldownPeriod = 3;
    }

    // ================================================================
    // │                         functions                            │
    // ================================================================

    /**
     * @inheritdoc IDACStaking
     */
    function setEligibilityForRewards(bool isEligible) external override onlyAdmin {
        s_isEligibleForRewardScaling = isEligible;
        emit EligibilityForRewardScalingUpdated(isEligible);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function setMinimumLockPeriod(uint16 periodInDays) external override onlyAdmin {
        s_minimumLockPeriod = periodInDays;
        emit MinimumLockPeriodUpdated(periodInDays);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function setWarmupPeriod(uint16 periodInDays) external override onlyAdmin {
        s_warmupPeriod = periodInDays;
        emit WarmupPeriodUpdated(periodInDays);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function setHotPeriod(uint16 periodInDays) external override onlyAdmin {
        s_hotPeriod = periodInDays;
        emit HotPeriodUpdated(periodInDays);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function setMaxRewardMultiplier(uint8 multiplier) external override onlyAdmin {
        if (multiplier <= 1) {
            revert DACStaking__NeedsMultiplierMoreThanOne();
        }
        s_maxRewardMultiplier = multiplier;
        emit MaxRewardMultiplierUpdated(multiplier);
    }

    /**
     * @notice Enables or disables the bias cooldown feature.
     * @param isEnabled New status for the bias cooldown feature.
     */
    function setCooldownEnabled(bool isEnabled) external onlyAdmin {
        s_isCooldownEnabled = isEnabled;
        emit CooldownEnabledUpdated(isEnabled);
    }

    /**
     * @notice Updates the cooldown period for setting bias.
     * @param periodInDays New cooldown period in days.
     */
    function setCooldownPeriod(uint16 periodInDays) external onlyAdmin {
        s_cooldownPeriod = periodInDays;
        emit CooldownPeriodUpdated(periodInDays);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function stake(uint256 amount) external override nonReentrant {
        if (amount == 0) {
            revert DACStaking__NeedsAmountMoreThanZero();
        }

        // Create a new stake entry
        Stake memory newStake = Stake({amount: amount, timestamp: block.timestamp});

        // Add the stake to the user's array of stakes
        s_stakes[msg.sender].push(newStake);

        emit Staked(msg.sender, amount, block.timestamp);

        // Transfer tokens from the user to the contract
        bool success = i_dacToken.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert DACStaking__TransferFailed(msg.sender, address(this), address(i_dacToken), amount);
        }
    }

    /**
     * @inheritdoc IDACStaking
     */
    function unstake(uint256 amount) external override nonReentrant {
        if (amount == 0) {
            revert DACStaking__NeedsAmountMoreThanZero();
        }

        uint256 totalStaked = getTotalStaked(msg.sender);

        if (totalStaked < amount) {
            revert DACStaking__InsufficientStakedAmount();
        }

        uint256 remaining = amount;
        uint256 len = s_stakes[msg.sender].length;

        // Iterate from the last stake (latest) to the first
        for (uint256 i = len; i > 0 && remaining > 0; i--) {
            Stake storage currentStake = s_stakes[msg.sender][i - 1];
            if (currentStake.amount <= remaining) {
                // If the current stake amount is less than or equal to the remaining amount to unstake
                uint256 currentStakeAmt = currentStake.amount;
                remaining -= currentStakeAmt;
                s_stakes[msg.sender].pop(); // Remove the stake
                emit Unstaked(msg.sender, currentStakeAmt, block.timestamp);
            } else {
                // If the current stake amount is greater than the remaining amount to unstake
                currentStake.amount -= remaining;
                emit Unstaked(msg.sender, remaining, block.timestamp);
                remaining = 0;
            }
        }

        // Transfer the unstaked tokens back to the user
        bool success = i_dacToken.transfer(msg.sender, amount);
        if (!success) {
            revert DACStaking__TransferFailed(address(this), msg.sender, address(i_dacToken), amount);
        }
    }

    /**
     * @inheritdoc IDACStaking
     */
    function setBias(Bias newBias) external override {
        //  Check if the bias is one of the enum values
        //  Neutral = 0 (default), Left = 1, Right = 2
        if ((uint8(newBias) > 2)) {
            revert DACStaking__InvalidBias();
        }

        // Prevent users with no stakes from setting a bias
        if (getTotalStaked(msg.sender) == 0) {
            revert DACStaking__InsufficientStakedAmount();
        }

        // If cooldown is enabled, ensure user waited long enough since last bias change
        uint256 lastSet = s_lastBiasTimestamp[msg.sender];
        if (s_isCooldownEnabled && lastSet != 0) {
            uint256 daysSince = (block.timestamp - lastSet) / 1 days;
            if (daysSince < s_cooldownPeriod) {
                revert DACStaking__BiasCooldownActive();
            }
        }

        Bias currentBias = s_userBias[msg.sender];
        s_userBias[msg.sender] = newBias;
        s_lastBiasTimestamp[msg.sender] = block.timestamp;

        emit BiasUpdated(msg.sender, currentBias, newBias);
    }

    /**
     * @inheritdoc IDACStaking
     */
    function getBias(address user) external view override returns (Bias) {
        return s_userBias[user];
    }

    /**
     * @inheritdoc IDACStaking
     */
    function getLastBiasTimestamp(address user) external view override returns (uint256) {
        return s_lastBiasTimestamp[user];
    }

    /**
     * @inheritdoc IDACStaking
     */
    function getTotalStakedWithMultipliers(address user) external view override returns (uint256) {
        uint256 total = 0;
        uint256 len = s_stakes[user].length;
        Stake[] storage userStakes = s_stakes[user];

        for (uint256 i = 0; i < len; i++) {
            Stake storage userStake = userStakes[i];
            uint256 multiplier = _getMultiplier(userStake.timestamp);
            total += (userStake.amount * multiplier) / MULTIPLIER_PRECISION;
        }

        return total;
    }

    /**
     * @inheritdoc IDACStaking
     */
    function getUserStakes(address user) external view override returns (Stake[] memory) {
        return s_stakes[user];
    }

    /**
     * @dev Retrieves the raw total amount staked by a user without considering reward multipliers.
     * @param user Address of the user.
     * @return totalStaked Raw total staked amount.
     */
    function getTotalStaked(address user) public view override returns (uint256) {
        uint256 total = 0;
        uint256 len = s_stakes[user].length;
        Stake[] storage userStakes = s_stakes[user];

        for (uint256 i = 0; i < len; i++) {
            total += userStakes[i].amount;
        }

        return total;
    }

    /**
     * @dev private function to calculate the current multiplier based on staking duration.
     * @param stakeTimestamp Timestamp when the stake was created.
     * @return multiplier Current reward multiplier scaled by MULTIPLIER_PRECISION for precision.
     */
    function _getMultiplier(uint256 stakeTimestamp) private view returns (uint256) {
        if (!s_isEligibleForRewardScaling) {
            return MULTIPLIER_PRECISION; // No multiplier if rewards are disabled
        }

        uint256 stakingDuration = (block.timestamp - stakeTimestamp) / 1 days;
        uint256 minimumLockPeriod = s_minimumLockPeriod;
        uint256 warmupPeriod = s_warmupPeriod;
        uint256 hotPeriod = s_hotPeriod;
        uint256 maxRewardMultiplier = s_maxRewardMultiplier;

        if (stakingDuration < minimumLockPeriod) {
            return 0; // Not eligible for rewards yet
        } else if (stakingDuration < minimumLockPeriod + warmupPeriod) {
            // Linear increase from 0 to 1x
            uint256 elapsed = stakingDuration - minimumLockPeriod;
            uint256 multiplier = (elapsed * MULTIPLIER_PRECISION) / warmupPeriod;
            return multiplier;
        } else if (stakingDuration < minimumLockPeriod + warmupPeriod + hotPeriod) {
            // Linear increase from 1x to maxMultiplier
            uint256 elapsed = stakingDuration - minimumLockPeriod - warmupPeriod;
            uint256 multiplierIncrease = (elapsed * (maxRewardMultiplier - 1) * MULTIPLIER_PRECISION) / hotPeriod;
            return MULTIPLIER_PRECISION + multiplierIncrease;
        } else {
            // Max multiplier reached
            return maxRewardMultiplier * MULTIPLIER_PRECISION;
        }
    }
}
