// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

// Compatible with OpenZeppelin Contracts ^5.0.0
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";

// Uniswap V2
import {IUniswapV2Router02} from "@uniswap/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswapcore/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswapcore/contracts/interfaces/IUniswapV2Pair.sol";
import {IWETH} from "@uniswap/contracts/interfaces/IWETH.sol";

// Interfaces for the DAC ecosystem
import {IDACSwapper} from "./IDACSwapper.sol";
import {IDACToken} from "./IDACToken.sol";
import {IDAChronicle} from "./IDAChronicle.sol";
import {IDACAuthority} from "./IDACAuthority.sol";
import {DACAccessManaged} from "./DACAccessManaged.sol";
import {DACRewardSplitter} from "./DACRewardSplitter.sol";
import {
    IDACTreasury,
    DACTreasury__InvalidDacToken,
    DACTreasury__InvalidDaChronicle,
    DACTreasury__InvalidUniswapRouter,
    DACTreasury__InvalidUniswapFactory,
    DACTreasury__InvalidUniswapPair,
    DACTreasury__InvalidUniswapPairTokensMismatch,
    DACTreasury__InvalidProjectOpsWallet,
    DACTreasury__InvalidFounderWallet,
    DACTreasury__InvalidExchangeAddress,
    DACTreasury__InvalidAirdropAddress,
    DACTreasury__AirdropCapExceeded,
    DACTreasury__ProjectOpsCapExceeded,
    DACTreasury__FounderCapExceeded,
    DACTreasury__ExchangeCapExceeded,
    DACTreasury__InsufficientEthAmount,
    DACTreasury__DACTransferFailed,
    DACTreasury__SlippageToleranceInvalid,
    DACTreasury__RewardSplitInvalid,
    DACTreasury__DiscountPriceInvalid,
    DACTreasury__CallerDoesNotOwnNFT,
    DACTreasury__DACApprovalFailed,
    DACTreasury__LiquidityApprovalFailed,
    DACTreasury__InvalidFromTokenAddress,
    DACTreasury__InvalidToTokenAddress,
    DACTreasury__InvalidSwapperAddress,
    DACTreasury__DeadlineExpired,
    DACTreasury__TokenSwapBelowMinAmount,
    DACTreasury__InsufficientTokenBalance
} from "./IDACTreasury.sol";

contract DACTreasury is IDACTreasury, DACAccessManaged, ReentrancyGuard {
    using SafeERC20 for IERC20; // It should be for WETH and other tokens other than DAC...

    // ================================================================
    // │                           CONSTANTS                          │
    // ================================================================

    // Allocation Caps (Percentages) in basis points (1% = 100 basis points)
    uint16 public constant AIRDROP_CAP_PERCENT = 500;
    uint16 public constant PROJECT_OPS_CAP_PERCENT = 500;
    uint16 public constant EXCHANGE_LIQUIDITY_CAP_PERCENT = 500;
    uint16 public constant FOUNDER_CAP_PERCENT = 500;

    // Allocation Vesting Periods
    uint64 public constant PROJECT_OPS_VESTING_PERIOD = 365 days * 10; // 10 years
    uint64 public constant FOUNDER_VESTING_PERIOD = 365 days * 3; // 3 years
    uint64 public constant FOUNDER_CLIFF = 180 days; // 6 months

    // Total basis points used for calculations (100% = 10,000 basis points)
    uint256 public constant TOTAL_BASIS_POINTS = 10000;
    // Maximum slippage tolerance expressed in basis points (10% = 1000 basis points)
    uint256 public constant MAX_SLIPPAGE_BASIS_POINTS = 1000;

    // The highest token ID eligible to receive early adopter royalty rewards
    uint256 public constant EARLY_REWARD_TOKEN_ID_CAP = 3650;

    // ================================================================
    // │                      State variables                         │
    // ================================================================

    // ERC20 DAC Token
    IDACToken public immutable i_dacToken;
    address public immutable i_dacTokenAddress;

    // DAChronicle NFT Contract
    IDAChronicle public immutable i_daChronicle;

    // Uniswap V2 and WETH
    IUniswapV2Router02 public immutable i_uniswapRouter;
    address public immutable i_uniswapRouterAddress;
    IWETH public immutable i_weth;
    address public immutable i_wethAddress;
    IUniswapV2Pair public immutable i_uniPair;
    // Immutable flag to indicate if DAC is token0 in the pair
    bool public immutable i_isDACToken0;

    // Vesting Wallets for Project Operations and Founder
    VestingWallet public immutable i_projectOpsVestingWallet;
    VestingWallet public immutable i_founderVestingWallet;

    // Reward Splitter Contract
    DACRewardSplitter public immutable i_rewardSplitter;

    // Allocation Tracking
    uint256 public s_airdropMinted;
    uint256 public s_projectOpsMinted;
    uint256 public s_exchangeLiquidityMinted;
    uint256 public s_founderMinted;

    // Reward Splitting the split percentage that goes to the users from the NFT perspective change (initialized 20% = 2000 basis points)
    uint256 public s_rewardSplitPercentage = 2000;
    bool public s_rewardSplitEnabled = false;

    // Slippage tolerance expressed in basis points (initialized 1% = 100 basis points)
    uint256 public s_slippageToleranceBP = 100;

    // NFT Sale Prices (Can be updated by Admin)
    uint256 public s_nftSalePriceWEI;
    uint256 public s_nftPerspectivePriceDAC;
    uint256 public s_nftPerspectiveDiscountPriceDAC;

    // ================================================================
    // │                        Constructor                           │
    // ================================================================

    /**
     * @dev Constructor to initialize the DACTreasury contract.
     * @param initialAuthority The address of the initial authority managing access controls.
     * @param dacToken The address of the DAC ERC-20 token contract.
     * @param daChronicle The address of the DAChronicle ERC-721 NFT contract.
     * @param uniswapRouter The address of the Uniswap V2 Router.
     * @param nftSalePriceWEI The sale price of DAChronicle NFT in WEI.
     * @param nftPerspectivePriceDAC The price of changing DAChronicle NFT perspective in DAC tokens.
     * @param nftPerspectiveDiscountPriceDAC The discounted price of changing DAChronicle NFT perspective in DAC tokens.
     * @param projectOpsWallet The address designated for project operations funds.
     * @param founderWallet The address designated for founder allocations.
     */
    constructor(
        address initialAuthority,
        address dacToken,
        address daChronicle,
        address uniswapRouter,
        uint256 nftSalePriceWEI,
        uint256 nftPerspectivePriceDAC,
        uint256 nftPerspectiveDiscountPriceDAC,
        address projectOpsWallet,
        address founderWallet
    ) DACAccessManaged(IDACAuthority(initialAuthority)) {
        if (dacToken == address(0)) {
            revert DACTreasury__InvalidDacToken(address(0));
        }
        if (daChronicle == address(0)) {
            revert DACTreasury__InvalidDaChronicle(address(0));
        }
        if (uniswapRouter == address(0)) {
            revert DACTreasury__InvalidUniswapRouter(address(0));
        }
        if (projectOpsWallet == address(0)) {
            revert DACTreasury__InvalidProjectOpsWallet(address(0));
        }
        if (founderWallet == address(0)) {
            revert DACTreasury__InvalidFounderWallet(address(0));
        }

        i_dacToken = IDACToken(dacToken);
        i_dacTokenAddress = dacToken;
        i_daChronicle = IDAChronicle(daChronicle);
        i_uniswapRouter = IUniswapV2Router02(uniswapRouter);
        i_uniswapRouterAddress = uniswapRouter;
        i_weth = IWETH(i_uniswapRouter.WETH());
        i_wethAddress = i_uniswapRouter.WETH();

        // Get the pair address from the Uniswap Factory
        address factory = i_uniswapRouter.factory();
        if (factory == address(0)) {
            revert DACTreasury__InvalidUniswapFactory(address(0));
        }

        address uniPair = IUniswapV2Factory(factory).getPair(dacToken, i_wethAddress);
        if (uniPair == address(0)) {
            revert DACTreasury__InvalidUniswapPair(address(0));
        }

        i_uniPair = IUniswapV2Pair(uniPair);

        // Determine the order of tokens in the pair
        address token0 = i_uniPair.token0();
        if (token0 != dacToken && token0 != i_wethAddress) {
            revert DACTreasury__InvalidUniswapPairTokensMismatch(token0);
        }

        i_isDACToken0 = (token0 == dacToken);

        s_nftSalePriceWEI = nftSalePriceWEI;
        s_nftPerspectivePriceDAC = nftPerspectivePriceDAC;
        s_nftPerspectiveDiscountPriceDAC = nftPerspectiveDiscountPriceDAC;

        // Deploy Vesting Wallets
        // Project Operations: Vesting over 10 years
        i_projectOpsVestingWallet =
            new VestingWallet(projectOpsWallet, uint64(block.timestamp), PROJECT_OPS_VESTING_PERIOD);

        // Founder: Cliff of 6 months, vesting over 3 years
        i_founderVestingWallet =
            new VestingWallet(founderWallet, uint64(block.timestamp) + FOUNDER_CLIFF, FOUNDER_VESTING_PERIOD);

        // Reward Splitter
        i_rewardSplitter = new DACRewardSplitter(initialAuthority, dacToken);

        // Initialize Allocation Tracking
        s_airdropMinted = 0;
        s_projectOpsMinted = 0;
        s_exchangeLiquidityMinted = 0;
        s_founderMinted = 0;
    }

    // ================================================================
    // │                         Functions                            │
    // ================================================================

    // ================================
    // ===== Allocation Functions =====
    // ================================

    /**
     * @inheritdoc IDACTreasury
     */
    function mintAirdrop(address to, uint256 amount) external override onlyAdmin {
        if (to == address(0)) {
            revert DACTreasury__InvalidAirdropAddress(address(0));
        }
        uint256 totalSupply = getTotalSupply();
        uint256 cap = (totalSupply * AIRDROP_CAP_PERCENT) / TOTAL_BASIS_POINTS;
        if (s_airdropMinted + amount > cap) {
            revert DACTreasury__AirdropCapExceeded(s_airdropMinted, amount, cap);
        }
        s_airdropMinted += amount;
        emit AirdropMinted(to, amount);
        i_dacToken.mint(to, amount);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function mintProjectOps(uint256 amount) external override onlyAdmin {
        uint256 totalSupply = getTotalSupply();
        uint256 cap = (totalSupply * PROJECT_OPS_CAP_PERCENT) / TOTAL_BASIS_POINTS;
        if (s_projectOpsMinted + amount > cap) {
            revert DACTreasury__ProjectOpsCapExceeded(s_projectOpsMinted, amount, cap);
        }
        s_projectOpsMinted += amount;
        emit ProjectOpsMinted(address(i_projectOpsVestingWallet), amount);
        i_dacToken.mint(address(i_projectOpsVestingWallet), amount);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function mintFounder(uint256 amount) external override onlyAdmin {
        uint256 totalSupply = getTotalSupply();
        uint256 cap = (totalSupply * FOUNDER_CAP_PERCENT) / TOTAL_BASIS_POINTS;
        if (s_founderMinted + amount > cap) {
            revert DACTreasury__FounderCapExceeded(s_founderMinted, amount, cap);
        }
        s_founderMinted += amount;
        emit FounderMinted(address(i_founderVestingWallet), amount);
        i_dacToken.mint(address(i_founderVestingWallet), amount);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function mintExchange(address to, uint256 amount) external override onlyAdmin {
        if (to == address(0)) {
            revert DACTreasury__InvalidExchangeAddress(address(0));
        }
        uint256 totalSupply = getTotalSupply();
        uint256 cap = (totalSupply * EXCHANGE_LIQUIDITY_CAP_PERCENT) / TOTAL_BASIS_POINTS;
        if (s_exchangeLiquidityMinted + amount > cap) {
            revert DACTreasury__ExchangeCapExceeded(s_exchangeLiquidityMinted, amount, cap);
        }
        s_exchangeLiquidityMinted += amount;
        emit ExchangeLiquidityMinted(to, amount);
        i_dacToken.mint(to, amount);
    }

    // ================================
    // ========= NFT Functions ========
    // ================================

    /**
     * @inheritdoc IDACTreasury
     */
    function mintNFT(
        bool isSale,
        address to,
        uint256 tokenId,
        string calldata uri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override nonReentrant {
        if (isSale && msg.value < s_nftSalePriceWEI) {
            revert DACTreasury__InsufficientEthAmount(msg.sender, msg.value, s_nftSalePriceWEI);
        }

        // Verify that the tokenId is within the early royalty reward range
        address beneficiary = tokenId <= EARLY_REWARD_TOKEN_ID_CAP
            ? to
            : i_founderVestingWallet.owner();

        // Call DAChronicle's delegateSafeMint
        i_daChronicle.delegateSafeMint(isSale, to, tokenId, uri, deadline, v, r, s, beneficiary);
        emit NFTMinted(msg.sender, to, tokenId, isSale, msg.value);

        if (isSale) {
            // Wrap ETH to WETH
            i_weth.deposit{value: address(this).balance}();
        }
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function updateNFTPerspectiveWithDAC(
        bool applyDiscount,
        uint256 tokenId,
        string calldata newUri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override nonReentrant {
        // Verify ownership of the NFT
        if (i_daChronicle.ownerOf(tokenId) != msg.sender) {
            revert DACTreasury__CallerDoesNotOwnNFT(msg.sender, tokenId);
        }

        uint256 nftSalePriceDAC = applyDiscount ? s_nftPerspectiveDiscountPriceDAC : s_nftPerspectivePriceDAC;

        // Transfer DAC tokens from user to Treasury
        bool success = i_dacToken.transferFrom(msg.sender, address(this), nftSalePriceDAC);
        if (!success) {
            revert DACTreasury__DACTransferFailed(msg.sender, address(this), nftSalePriceDAC);
        }

        // Call DAChronicle's delegateSetTokenURI
        i_daChronicle.delegateSetTokenURI(applyDiscount, tokenId, newUri, deadline, v, r, s);
        emit PerspectiveUpdatedWithDAC(msg.sender, tokenId, nftSalePriceDAC, newUri);

        // calculate the reward split and burn the remaining amount
        uint256 rewardSplitAmount =
            s_rewardSplitEnabled ? (nftSalePriceDAC * s_rewardSplitPercentage) / TOTAL_BASIS_POINTS : 0;
        uint256 burnAmount = nftSalePriceDAC - rewardSplitAmount;

        if (rewardSplitAmount > 0) {
            success = i_dacToken.transfer(address(i_rewardSplitter), rewardSplitAmount);
            if (!success) {
                revert DACTreasury__DACTransferFailed(address(this), address(i_rewardSplitter), rewardSplitAmount);
            }
            i_rewardSplitter.addToOpenReward(rewardSplitAmount);
            emit AddedToRewardSplit(rewardSplitAmount);
        }

        if (burnAmount > 0) {
            emit DACBurned(burnAmount);
            i_dacToken.burn(burnAmount);
        }
    }

    // ================================
    // ======= Agent Functions ========
    // ================================

    /**
     * @inheritdoc IDACTreasury
     */
    function provideLiquidity(uint256 amountDAC, uint256 amountOutMin, uint256 deadline)
        external
        override
        onlyLiquidityAgent
        nonReentrant
    {
        _swapDACForWETH(amountDAC, amountOutMin, deadline);
        _addLiquidity(deadline);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function buyBackAndBurn(uint256 liquidityAmount, uint256 minAmountDAC, uint256 minAmountWETH, uint256 deadline)
        external
        override
        onlyLiquidityAgent
        nonReentrant
    {
        // Remove liquidity from Uniswap
        (, uint256 amountWETHReceived) = _removeLiquidity(liquidityAmount, minAmountDAC, minAmountWETH, deadline);

        // Swap WETH back to DAC
        _swapWETHForDAC(amountWETHReceived, deadline);

        // Burn the DAC tokens
        uint256 dacTreasuryBalance = i_dacToken.balanceOf(address(this));
        emit DACBurned(dacTreasuryBalance);
        i_dacToken.burn(dacTreasuryBalance);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function swapTreasuryTokens(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address swapper
    ) external override onlyTreasurerAgent nonReentrant onlySwapper(swapper) {
        if (fromToken == address(0)) {
            revert DACTreasury__InvalidFromTokenAddress(address(0));
        }
        if (toToken == address(0)) {
            revert DACTreasury__InvalidToTokenAddress(address(0));
        }
        if (swapper == address(0)) {
            revert DACTreasury__InvalidSwapperAddress(address(0));
        }
        if (block.timestamp > deadline) {
            revert DACTreasury__DeadlineExpired(deadline, block.timestamp);
        }

        // Ensure treasury has enough balance of the fromToken
        uint256 treasuryBalance = IERC20(fromToken).balanceOf(address(this));
        if (treasuryBalance < amountIn) {
            revert DACTreasury__InsufficientTokenBalance(fromToken, treasuryBalance, amountIn);
        }

        // Approve the swapper contract to spend treasury's fromToken
        IERC20(fromToken).safeIncreaseAllowance(address(swapper), amountIn);

        // Swap tokens via the swapper contract
        uint256 amountOut = IDACSwapper(swapper).swapTokens(fromToken, toToken, amountIn, amountOutMin);

        // Validate the swap and ensure the target tokens are received
        if (amountOut < amountOutMin) {
            revert DACTreasury__TokenSwapBelowMinAmount(amountOut, amountOutMin);
        }

        emit TokensSwapped(swapper, fromToken, toToken, amountIn, amountOut, amountOutMin);

        // Transfer the swapped target tokens back to the treasury
        // slither-disable-next-line arbitrary-send-erc20
        IERC20(toToken).safeTransferFrom(address(swapper), address(this), amountOut);

        // Decrease the allowance of the swapper contract
        uint256 currentAllownce = IERC20(fromToken).allowance(address(this), address(swapper));
        if (currentAllownce > 0) {
            IERC20(fromToken).safeDecreaseAllowance(address(swapper), currentAllownce);
        }
    }

    // ================================
    // ======== Admin Functions =======
    // ================================

    /**
     * @inheritdoc IDACTreasury
     */
    function updateSlippageTolerance(uint256 newSlippageToleranceBP) external override onlyAdmin {
        if (newSlippageToleranceBP > MAX_SLIPPAGE_BASIS_POINTS) {
            revert DACTreasury__SlippageToleranceInvalid(newSlippageToleranceBP);
        }
        s_slippageToleranceBP = newSlippageToleranceBP;
        emit SlippageToleranceUpdated(newSlippageToleranceBP);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function updateNFTSalePriceETH(uint256 newPrice) external override onlyAdmin {
        s_nftSalePriceWEI = newPrice;
        emit NFTSalePriceWEIUpdated(newPrice);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function updateNFTSalePriceDAC(uint256 newPrice) external override onlyAdmin {
        if (newPrice < s_nftPerspectiveDiscountPriceDAC) {
            revert DACTreasury__DiscountPriceInvalid(newPrice, s_nftPerspectiveDiscountPriceDAC);
        }
        s_nftPerspectivePriceDAC = newPrice;
        emit NFTPerspectivePriceDACUpdated(newPrice);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function updateNFTSaleDiscountPriceDAC(uint256 newPrice) external override onlyAdmin {
        if (newPrice > s_nftPerspectivePriceDAC) {
            revert DACTreasury__DiscountPriceInvalid(s_nftPerspectivePriceDAC, newPrice);
        }
        s_nftPerspectiveDiscountPriceDAC = newPrice;
        emit NFTPerspectiveDiscountPriceDACUpdated(newPrice);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function updateRewardSplitPercentage(uint256 newRewardSplitPercentage) external override onlyAdmin {
        if (newRewardSplitPercentage > TOTAL_BASIS_POINTS) {
            revert DACTreasury__RewardSplitInvalid(newRewardSplitPercentage);
        }
        s_rewardSplitPercentage = newRewardSplitPercentage;
        emit RewardSplitPercentageUpdated(newRewardSplitPercentage);
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function enableRewardSplit(bool enabled) external override onlyAdmin {
        s_rewardSplitEnabled = enabled;
        emit RewardSplitEnabled(enabled);
    }

    // ================================
    // ======= Helper Functions =======
    // ================================

    /**
     * @inheritdoc IDACTreasury
     */
    function getTotalSupply() public view override returns (uint256) {
        return i_dacToken.totalSupply();
    }

    /**
     * @inheritdoc IDACTreasury
     */
    function calculateSlippageTolerance(uint256 amount) public view override returns (uint256) {
        return (amount * (TOTAL_BASIS_POINTS - s_slippageToleranceBP)) / TOTAL_BASIS_POINTS;
    }

    /**
     * @notice Swaps DAC tokens for WETH using Uniswap.
     * @param amountDAC The amount of DAC tokens to mint and to swap.
     * @param amountOutMin The minimum amount of WETH to receive.
     * @param deadline The deadline timestamp for the swap.
     *
     * Emits a {SwappedDACForWETH} event.
     */
    function _swapDACForWETH(uint256 amountDAC, uint256 amountOutMin, uint256 deadline) private {
        // Initialize the liquidity path as [DAC, WETH]
        address[] memory path = new address[](2);
        path[0] = i_dacTokenAddress;
        path[1] = i_wethAddress;
        uint256 dacTreasuryBalance = i_dacToken.balanceOf(address(this));
        uint256 amountToMint = dacTreasuryBalance < amountDAC ? amountDAC - dacTreasuryBalance : 0;

        if (amountToMint > 0) {
            emit DACMinted(amountToMint);
            i_dacToken.mint(address(this), amountToMint);
        }

        // Approve Uniswap Router to spend DAC
        if (!i_dacToken.approve(i_uniswapRouterAddress, amountDAC)) {
            revert DACTreasury__DACApprovalFailed(i_uniswapRouterAddress, amountDAC);
        }

        // Swap DAC to WETH
        uint256[] memory amountsOut = i_uniswapRouter.swapExactTokensForTokens({
            amountIn: amountDAC,
            amountOutMin: amountOutMin,
            path: path,
            to: address(this),
            deadline: deadline
        });

        emit SwappedDACForWETH(amountDAC, amountOutMin, amountsOut[1]);
    }

    /**
     * @notice Swaps WETH tokens for DAC using Uniswap.
     * @param amountWETH The amount of WETH tokens to swap.
     * @param deadline The deadline timestamp for the swap.
     *
     * Emits a {SwappedWETHForDAC} event.
     */
    function _swapWETHForDAC(uint256 amountWETH, uint256 deadline) private {
        // Initialize the liquidity path as [DAC, WETH]
        address[] memory path = new address[](2);
        path[0] = i_wethAddress;
        path[1] = i_dacTokenAddress;

        // Get the estimated amount of DAC tokens for the input WETH
        uint256[] memory estimatedAmountsOut = i_uniswapRouter.getAmountsOut(amountWETH, path);
        uint256 estimatedDAC = estimatedAmountsOut[1];

        // Safely increase WETH allowance using SafeERC20
        IERC20(address(i_weth)).safeIncreaseAllowance(i_uniswapRouterAddress, amountWETH);

        // Swap WETH to DAC
        uint256[] memory amountsOut = i_uniswapRouter.swapExactTokensForTokens({
            amountIn: amountWETH,
            amountOutMin: calculateSlippageTolerance(estimatedDAC),
            path: path,
            to: address(this),
            deadline: deadline
        });

        emit SwappedWETHForDAC(amountWETH, estimatedDAC, amountsOut[1]);
    }

    /**
     * @notice Gets the required DAC amount to maintain the reserve ratio in the Uniswap pair.
     * @param availableWETH The amount of WETH tokens available to provide liquidity.
     */
    function _getRequiredDAC(uint256 availableWETH) private view returns (uint256 requiredDAC) {
        // Fetch reserves from the pair contract
        (uint112 reserve0, uint112 reserve1,) = i_uniPair.getReserves();

        uint256 reserveDAC;
        uint256 reserveWETH;

        if (i_isDACToken0) {
            reserveDAC = uint256(reserve0);
            reserveWETH = uint256(reserve1);
        } else {
            reserveDAC = uint256(reserve1);
            reserveWETH = uint256(reserve0);
        }

        // Calculate the required DAC amount to maintain the reserve ratio
        requiredDAC = (availableWETH * reserveDAC) / reserveWETH;
    }

    /**
     * @notice Adds liquidity to the Uniswap DAC/WETH pair.
     * @param deadline The deadline timestamp for adding liquidity.
     *
     * Emits a {LiquidityProvided} event.
     */
    function _addLiquidity(uint256 deadline) private {
        uint256 availableWETH = IERC20(i_wethAddress).balanceOf(address(this));
        uint256 requiredDAC = _getRequiredDAC(availableWETH);

        // Ensure the contract has enough DAC to provide liquidity
        emit DACMinted(requiredDAC);
        i_dacToken.mint(address(this), requiredDAC);

        // Approve Uniswap Router to spend DAC
        if (!i_dacToken.approve(i_uniswapRouterAddress, requiredDAC)) {
            revert DACTreasury__DACApprovalFailed(i_uniswapRouterAddress, requiredDAC);
        }

        // Safely increase WETH allowance using SafeERC20
        IERC20(i_wethAddress).safeIncreaseAllowance(i_uniswapRouterAddress, availableWETH);

        (uint256 amountDACAdded, uint256 amountETHAdded, uint256 liquidityReceived) = i_uniswapRouter.addLiquidity({
            tokenA: i_dacTokenAddress,
            tokenB: i_wethAddress,
            amountADesired: requiredDAC,
            amountBDesired: availableWETH,
            amountAMin: calculateSlippageTolerance(requiredDAC),
            amountBMin: calculateSlippageTolerance(availableWETH),
            to: address(this),
            deadline: deadline
        });

        emit LiquidityProvided(amountDACAdded, amountETHAdded, liquidityReceived);

        // Decrease the allowance for WETH allowance of the uniswap contract, if there is any...
        uint256 currentWethAllownce = IERC20(i_wethAddress).allowance(address(this), i_uniswapRouterAddress);
        if (currentWethAllownce > 0) {
            IERC20(i_wethAddress).safeDecreaseAllowance(i_uniswapRouterAddress, currentWethAllownce);
        }
    }

    /**
     * @notice Removes liquidity from the Uniswap DAC/WETH pair.
     * @param liquidityAmount The amount of liquidity tokens to remove.
     * @param minAmountDAC The minimum amount of DAC to receive from removing liquidity.
     * @param minAmountWETH The minimum amount of WETH to receive from removing liquidity.
     * @param deadline The deadline timestamp for the Uniswap transaction.
     *
     * Emits a {LiquidityRemoved} event.
     */
    function _removeLiquidity(uint256 liquidityAmount, uint256 minAmountDAC, uint256 minAmountWETH, uint256 deadline)
        private
        returns (uint256 amountDACReceived, uint256 amountWETHReceived)
    {
        // Approve Uniswap Router to spend liquidity tokens
        if (!i_uniPair.approve(i_uniswapRouterAddress, liquidityAmount)) {
            revert DACTreasury__LiquidityApprovalFailed(i_uniswapRouterAddress, liquidityAmount);
        }

        // Remove liquidity from Uniswap
        (amountDACReceived, amountWETHReceived) = i_uniswapRouter.removeLiquidity({
            tokenA: i_dacTokenAddress,
            tokenB: i_wethAddress,
            liquidity: liquidityAmount,
            amountAMin: minAmountDAC,
            amountBMin: minAmountWETH,
            to: address(this),
            deadline: deadline
        });

        emit LiquidityRemoved(amountDACReceived, amountWETHReceived, liquidityAmount);
    }

    // ================================
    // ====== Receive Functions =======
    // ================================
    // Note: We accept donations to the Treasury contract.
    // Any ETH sent to the contract will be used for liquidity operations.

    /**
     * @dev Allows the contract to receive ETH.
     */
    receive() external payable {}

    /**
     * @dev Fallback function to receive ETH.
     */
    fallback() external payable {}
}
