// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ================================================================
// │                           ERRORS                             │
// ================================================================

/**
 * @dev Thrown when the DAC Token is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidDacToken(address invalidAddress);

/**
 * @dev Thrown when the DAChronicle is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidDaChronicle(address invalidAddress);

/**
 * @dev Thrown when the UniswapRouter is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidUniswapRouter(address invalidAddress);

/**
 * @dev Thrown when the UniswapFactory is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidUniswapFactory(address invalidAddress);

/**
 * @dev Thrown when the UniswapPair is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidUniswapPair(address invalidAddress);

/**
 * @dev Thrown when the pair tokens do not match the expected tokens.
 * @param invalidToken0 The invalid token address.
 */
error DACTreasury__InvalidUniswapPairTokensMismatch(address invalidToken0);

/**
 * @dev Thrown when the ProjectOpsWallet is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidProjectOpsWallet(address invalidAddress);

/**
 * @dev Thrown when the FounderWallet is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidFounderWallet(address invalidAddress);

/**
 * @dev Thrown when the ExchangeAddress is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidExchangeAddress(address invalidAddress);

/**
 * @dev Thrown when the AirdropAddress is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidAirdropAddress(address invalidAddress);

/**
 * @dev Thrown when the swapping from token is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidFromTokenAddress(address invalidAddress);

/**
 * @dev Thrown when the swapping to token is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidToTokenAddress(address invalidAddress);

/**
 * @dev Thrown when the SwapperAddress is not a valid address (e.g., `address(0)`).
 * @param invalidAddress The invalid address.
 */
error DACTreasury__InvalidSwapperAddress(address invalidAddress);

/**
 * @dev Thrown when the airdrop cap is exceeded.
 * @param airdropMinted The amount of tokens already minted for airdrops.
 * @param amountToMint The amount of tokens to mint.
 * @param cap The cap for airdrop minting.
 */
error DACTreasury__AirdropCapExceeded(uint256 airdropMinted, uint256 amountToMint, uint256 cap);

/**
 * @dev Thrown when the project operations cap is exceeded.
 * @param projectOpsMinted The amount of tokens already minted for project operations.
 * @param amountToMint The amount of tokens to mint.
 * @param cap The cap for project operations minting.
 */
error DACTreasury__ProjectOpsCapExceeded(uint256 projectOpsMinted, uint256 amountToMint, uint256 cap);

/**
 * @dev Thrown when the founder cap is exceeded.
 * @param founderMinted The amount of tokens already minted for founder.
 * @param amountToMint The amount of tokens to mint.
 * @param cap The cap for founder minting.
 */
error DACTreasury__FounderCapExceeded(uint256 founderMinted, uint256 amountToMint, uint256 cap);

/**
 * @dev Thrown when the exchange liquidity cap is exceeded.
 * @param exchangeMinted The amount of tokens already minted for exchanges.
 * @param amountToMint The amount of tokens to mint.
 * @param cap The cap for exchange liquidity minting.
 */
error DACTreasury__ExchangeCapExceeded(uint256 exchangeMinted, uint256 amountToMint, uint256 cap);

/**
 * @dev Thrown when the user sends insufficient amount of Eth.
 * @param from The address of the sender.
 * @param sentAmount The amount of wei sent.
 * @param expectedAmount The amount of wei expected.
 */
error DACTreasury__InsufficientEthAmount(address from, uint256 sentAmount, uint256 expectedAmount);

/**
 * @dev Throws when the transfer of DAC tokens fails.
 * @param from The address of the sender.
 * @param to The address of the receiver.
 * @param expectedAmount The amount of DAC tokens expected to be transferred.
 */
error DACTreasury__DACTransferFailed(address from, address to, uint256 expectedAmount);

/**
 * @dev hrown when the admin tries to set the slippage tolerance higher than the maximum.
 * @param newSlippageTolerance The new slippage tolerance.
 */
error DACTreasury__SlippageToleranceInvalid(uint256 newSlippageTolerance);

/**
 * @dev hrown when the admin tries to set the reward split percentage higher than the maximum.
 * @param newRewardSplitPercentage The new reward split percentage.
 */
error DACTreasury__RewardSplitInvalid(uint256 newRewardSplitPercentage);

/**
 * @dev Thrown when the admin tries to set the discount price higher than the normal price.
 * @param normalPrice The normal price of the perspective change.
 * @param discountPrice The discounted price of the perspective change.
 */
error DACTreasury__DiscountPriceInvalid(uint256 normalPrice, uint256 discountPrice);

/**
 * @dev Thrown when the caller does not own the NFT and tries to change its perspective.
 * @param caller The address of the caller.
 * @param tokenId The ID of the NFT.
 */
error DACTreasury__CallerDoesNotOwnNFT(address caller, uint256 tokenId);

/**
 * @dev Thrown when the DAC approval fails.
 * @param spender The address of the spender.
 * @param dacAmount The amount of DAC tokens.
 */
error DACTreasury__DACApprovalFailed(address spender, uint256 dacAmount);

/**
 * @dev Thrown when the Uniswap v2 liquidity approval fails.
 * @param spender The address of the spender.
 * @param liquidityAmount The amount of DAC tokens.
 */
error DACTreasury__LiquidityApprovalFailed(address spender, uint256 liquidityAmount);

/**
 * @dev Thrown when the deadline for a transaction has expired.
 * @param expiredDeadline The deadline timestamp.
 * @param currentBlockTimestamp The current block timestamp.
 */
error DACTreasury__DeadlineExpired(uint256 expiredDeadline, uint256 currentBlockTimestamp);

/**
 * @dev Thrown when the swap amount is below the minimum amount.
 * @param amountOut The amount of tokens swapped.
 * @param amountOutMin The minimum amount of tokens to receive.
 */
error DACTreasury__TokenSwapBelowMinAmount(uint256 amountOut, uint256 amountOutMin);

/**
 * @dev Thrown when the token balance is insufficient for the swap.
 * @param token The address of the token.
 * @param currentBalance The current balance of the token.
 * @param expectedBalance The expected balance of the token.
 */
error DACTreasury__InsufficientTokenBalance(address token, uint256 currentBalance, uint256 expectedBalance);

/**
 * @title IDACTreasury
 * @dev Interface for the DACTreasury smart contract, including errors, events, and external/public functions.
 */
interface IDACTreasury {
    // ================================================================
    // │                           EVENTS                             │
    // ================================================================

    /**
     * @dev Emitted when airdrop tokens are minted.
     * @param to The address receiving the airdropped tokens.
     * @param amount The amount of tokens minted.
     */
    event AirdropMinted(address indexed to, uint256 amount);

    /**
     * @dev Emitted when project operations tokens are minted.
     * @param vestingWallet The vesting wallet receiving the tokens.
     * @param amount The amount of tokens minted.
     */
    event ProjectOpsMinted(address indexed vestingWallet, uint256 amount);

    /**
     * @dev Emitted when exchange liquidity tokens are minted.
     * @param to The address receiving the tokens.
     * @param amount The amount of tokens minted.
     */
    event ExchangeLiquidityMinted(address indexed to, uint256 amount);

    /**
     * @dev Emitted when founder tokens are minted.
     * @param vestingWallet The vesting wallet receiving the tokens.
     * @param amount The amount of tokens minted.
     */
    event FounderMinted(address indexed vestingWallet, uint256 amount);

    /**
     * @dev Emitted when an NFT is minted.
     * @param buyer The address initiating the mint.
     * @param to The address receiving the NFT.
     * @param tokenId The ID of the NFT minted.
     * @param isSale Indicates if the mint is part of a sale.
     * @param amountWEI The amount of wei involved in the mint.
     */
    event NFTMinted(address indexed buyer, address indexed to, uint256 tokenId, bool isSale, uint256 amountWEI);

    /**
     * @dev Emitted when the perspective of an NFT is updated with DAC tokens.
     * @param owner The owner of the NFT.
     * @param tokenId The ID of the NFT.
     * @param amountDAC The amount of DAC tokens used.
     * @param newTokenURI The new token URI of the NFT.
     */
    event PerspectiveUpdatedWithDAC(address indexed owner, uint256 tokenId, uint256 amountDAC, string newTokenURI);

    /**
     * @dev Emitted when liquidity is provided to Uniswap.
     * @param amountDAC The amount of DAC tokens provided.
     * @param amountWETH The amount of WETH provided.
     * @param liquidityReceived The amount of liquidity tokens received.
     */
    event LiquidityProvided(uint256 amountDAC, uint256 amountWETH, uint256 liquidityReceived);

    /**
     * @dev Emitted when liquidity is removed from Uniswap.
     * @param amountDACReceived The amount of DAC tokens received.
     * @param amountETHReceived The amount of ETH received.
     * @param liquidityRemoved The amount of liquidity tokens removed.
     */
    event LiquidityRemoved(uint256 amountDACReceived, uint256 amountETHReceived, uint256 liquidityRemoved);

    /**
     * @dev Emitted when DAC tokens are swapped for WETH.
     * @param amountDAC The amount of DAC tokens swapped.
     * @param minAmountWETH The minimum amount of WETH expected.
     * @param amountWETHOut The amount of WETH received.
     */
    event SwappedDACForWETH(uint256 amountDAC, uint256 minAmountWETH, uint256 amountWETHOut);

    /**
     * @dev Emitted when WETH is swapped for DAC tokens.
     * @param amountWETH The amount of WETH swapped.
     * @param estimatedAmountDAC The estimated amount of DAC tokens.
     * @param amountDACOut The actual amount of DAC tokens received.
     */
    event SwappedWETHForDAC(uint256 amountWETH, uint256 estimatedAmountDAC, uint256 amountDACOut);

    /**
     * @dev Emitted when DAC tokens are minted to the treasury.
     * @param amountDAC The amount of DAC tokens minted to the treasury.
     */
    event DACMinted(uint256 amountDAC);

    /**
     * @dev Emitted when DAC tokens are burned from the treasury.
     * @param amountDAC The amount of DAC tokens burned from the treasury.
     */
    event DACBurned(uint256 amountDAC);

    /**
     * @dev Emitted when tokens are swapped via a swapper contract.
     * @param swapper The address of the swapper contract.
     * @param fromToken The address of the token being swapped from.
     * @param toToken The address of the token being swapped to.
     * @param amountIn The amount of fromToken being swapped.
     * @param amountOut The amount of toToken received.
     * @param amountOutMin The minimum amount of toToken expected.
     */
    event TokensSwapped(
        address indexed swapper,
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutMin
    );

    /**
     * @dev Emitted when the slippage tolerance is updated.
     * @param newSlippageToleranceBP The new slippage tolerance in basis points.
     */
    event SlippageToleranceUpdated(uint256 newSlippageToleranceBP);

    /**
     * @dev Emitted when the NFT sale price in ETH is updated.
     * @param newPrice The new sale price in wei.
     */
    event NFTSalePriceWEIUpdated(uint256 newPrice);

    /**
     * @dev Emitted when the NFT perspective price in DAC tokens is updated.
     * @param newPrice The new perspective price in DAC tokens.
     */
    event NFTPerspectivePriceDACUpdated(uint256 newPrice);

    /**
     * @dev Emitted when the NFT perspective discount price in DAC tokens is updated.
     * @param newPrice The new perspective discount price in DAC tokens.
     */
    event NFTPerspectiveDiscountPriceDACUpdated(uint256 newPrice);

    /**
     * @dev Emitted when an amount is added to the reward split.
     * @param amount The amount added to the reward split.
     */
    event AddedToRewardSplit(uint256 amount);

    /**
     * @dev Emitted when the reward split percentage is updated.
     * @param newRewardSplitPercentage The new reward split percentage in basis points.
     */
    event RewardSplitPercentageUpdated(uint256 newRewardSplitPercentage);

    /**
     * @dev Emitted when the reward split is enabled or disabled.
     * @param enabled True if the reward split is enabled, false otherwise.
     */
    event RewardSplitEnabled(bool enabled);

    // ================================================================
    // │                         FUNCTIONS                            │
    // ================================================================

    // ================================
    // ===== Allocation Functions =====
    // ================================

    /**
     * @notice Mint DAC tokens for strategic airdrops up to a 5% hard cap.
     * @param to The address to receive the airdropped tokens.
     * @param amount The amount of DAC tokens to mint for the airdrop.
     *
     * Emits a {AirdropMinted} event.
     */
    function mintAirdrop(address to, uint256 amount) external;

    /**
     * @notice Mint DAC tokens for project operations up to a % hard cap with vesting.
     * @param amount The amount of DAC tokens to mint for project operations.
     *
     * Emits a {ProjectOpsMinted} event.
     */
    function mintProjectOps(uint256 amount) external;

    /**
     * @notice Mint DAC tokens for the founder up to a % hard cap with vesting.
     * @param amount The amount of DAC tokens to mint for the founder.
     *
     * Emits a {FounderMinted} event.
     */
    function mintFounder(uint256 amount) external;

    /**
     * @notice Mint DAC tokens for the exchanges up to a 5% hard cap.
     * @param to The address to receive the minted tokens.
     * @param amount The amount of DAC tokens to mint.
     *
     * Emits a {ExchangeLiquidityMinted} event.
     */
    function mintExchange(address to, uint256 amount) external;

    // ================================
    // ========= NFT Functions ========
    // ================================

    /**
     * @notice Purchase a DAChronicle NFT using ETH or claims the right to mint a rewarded NFT.
     * @param isSale Whether the NFT is being purchased/minted from the sale or from the reward program.
     * @param to The destination address to mint the token.
     * @param tokenId The ID of the NFT to mint.
     * @param uri The metadata URI of the NFT.
     * @param deadline The deadline timestamp for the Chronicles Agent signature.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     *
     * Emits a {NFTMinted} event.
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
    ) external payable;

    /**
     * @notice Update the perspective (token URI) of a DAChronicle NFT using DAC tokens.
     * @param applyDiscount Whether to apply a discount to the token URI update.
     * @param tokenId The ID of the NFT to update.
     * @param newUri The new metadata URI for the NFT.
     * @param deadline The deadline timestamp for the Chronicles Agent signature.
     * @param v Signature recovery ID.
     * @param r Signature parameter.
     * @param s Signature parameter.
     *
     * Emits a {PerspectiveUpdatedWithDAC} event.
     * Emits a {AddedToRewardSplit} event.
     * Emits a {DACBurned} event.
     */
    function updateNFTPerspectiveWithDAC(
        bool applyDiscount,
        uint256 tokenId,
        string calldata newUri,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ================================
    // ======= Agent Functions ========
    // ================================

    /**
     * @notice Provide liquidity by minting and adding DAC/ETH to Uniswap in a controlled manner.
     * @dev Only callable by the liquidity manager agent address.
     * @param amountDAC The amount of DAC tokens to mint and add as liquidity.
     * @param amountOutMin The minimum amount of WETH to receive from the swap.
     * @param deadline The deadline timestamp for the Uniswap transaction.
     */
    function provideLiquidity(uint256 amountDAC, uint256 amountOutMin, uint256 deadline) external;

    /**
     * @notice Buy back DAC tokens from Uniswap and burn them to stabilize the token's price.
     * @dev Only callable by the liquidity manager agent address.
     * @param liquidityAmount The amount of liquidity tokens to remove.
     * @param minAmountDAC The minimum amount of DAC to receive from removing liquidity.
     * @param minAmountWETH The minimum amount of WETH to receive from removing liquidity.
     * @param deadline The deadline timestamp for the Uniswap transaction.
     *
     * Emits a {DACBurned} event.
     */
    function buyBackAndBurn(uint256 liquidityAmount, uint256 minAmountDAC, uint256 minAmountWETH, uint256 deadline)
        external;

    /**
     * @notice Swaps ERC-20 tokens from the treasury for another token and validates the amount received.
     * @dev Only callable by the treasurer agent address.
     * @param fromToken The address of the ERC-20 token to swap (e.g., treasury's token).
     * @param toToken The address of the ERC-20 token to receive after the swap.
     * @param amountIn The amount of `fromToken` to swap.
     * @param amountOutMin The minimum amount of `toToken` expected from the swap.
     * @param deadline The deadline timestamp for the transaction.
     * @param swapper The address of the swapper contract to use for the swap.
     *
     * Emits a {TokensSwapped} event.
     */
    function swapTreasuryTokens(
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        address swapper
    ) external;

    // ================================
    // ======== Admin Functions =======
    // ================================

    /**
     * @notice Update the slippage tolerance for Uniswap transactions.
     * @param newSlippageToleranceBP The new slippage tolerance in basis points.
     * @dev The new slippage tolerance must be less than or equal to MAX_SLIPPAGE_BASIS_POINTS (i.e. 1000 (10%)).
     *
     * Emits a {SlippageToleranceUpdated} event.
     */
    function updateSlippageTolerance(uint256 newSlippageToleranceBP) external;

    /**
     * @notice Update the sale price of DAChronicle NFTs in ETH.
     * @param newPrice The new sale price in wei.
     *
     * Emits a {NFTSalePriceWEIUpdated} event.
     */
    function updateNFTSalePriceETH(uint256 newPrice) external;

    /**
     * @notice Update the sale price of updating DAChronicle NFTs perspective in DAC tokens.
     * @param newPrice The new sale price in DAC tokens.
     *
     * Emits a {NFTPerspectivePriceDACUpdated} event.
     */
    function updateNFTSalePriceDAC(uint256 newPrice) external;

    /**
     * @notice Update the sale discounted price of updating DAChronicle NFTs perspective in DAC tokens.
     * @param newPrice The new sale discounted price in DAC tokens.
     *
     * Emits a {NFTPerspectiveDiscountPriceDACUpdated} event.
     */
    function updateNFTSaleDiscountPriceDAC(uint256 newPrice) external;

    /**
     * @notice Update the reward split percentage for NFT perspective changes.
     * @param newRewardSplitPercentage The new reward split percentage in basis points.
     *
     * Emits a {RewardSplitPercentageUpdated} event.
     */
    function updateRewardSplitPercentage(uint256 newRewardSplitPercentage) external;

    /**
     * @notice Enable or disable the reward split for NFT perspective changes.
     * @param enabled Whether to enable or disable the reward split.
     *
     * Emits a {RewardSplitEnabled} event.
     */
    function enableRewardSplit(bool enabled) external;

    // ================================
    // ======= Helper Functions =======
    // ================================

    /**
     * @notice Retrieve the total supply of DAC tokens.
     * @return The total supply of DAC tokens.
     */
    function getTotalSupply() external view returns (uint256);

    /**
     * @notice Calculate the slippage tolerance for a given amount.
     * @param amount The amount of tokens.
     * @return The slippage tolerance for the given amount.
     */
    function calculateSlippageTolerance(uint256 amount) external view returns (uint256);
}
