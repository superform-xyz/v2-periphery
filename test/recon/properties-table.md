# Properties Table

## SuperVault 
| # | Property | Description | Comments | Implemented | Passes |
| --- | --- | --- | --- | --- | --- |
| 1 | `doomsday_maxRedeemResetsAfterFullRedemption` | `maxRedeem` is reset to 0 after full redemption |  | ❌ |  |
| 2 | `doomsday_maxWithdrawResetsAfterFullWithdrawal` | `maxWithdraw` is reset to 0 after full withdrawal |  | ✅ | ✅ |
| 3 | `doomsday_fulfillDoesntOverRedeemMultipleActors` | fulfillRedeemRequests doesn't redeem more than requested for multiple actors |  | ✅ | ✅ |
| 4 | `property_maxRedeemMaxWithdrawSymmetry` | `maxRedeem` and `maxWithdraw` should always be equivalent  |  | ❌ |  |
| 5 | `property_erc7540_redeem` | `maxRedeem` value is correct |  | ✅ | ✅ |
| 6 | `property_totalSharesDontDecreaseOnRedemptionRequest` | `requestRedeem` should never reduce `SuperVault` shares  |  | ✅ | ✅ |
| 7 | `superVault_cancelRedeem` | `pendingRedeemRequest` should be 0 after a user calls `cancelRedeem`  |  | ✅ | ✅ |
| 8 | `superVault_cancelRedeem` | `averageRequestPPS` should be 0 after a user calls `cancelRedeem`  |  | ✅ | ✅ |
| 9 | `superVault_cancelRedeem` | user shouldn't receive more than convertToAssets(pendingRedeemRequest) after cancelRedeem |  | ✅ | ✅ |
| 10 | `property_shareSolvency` | `SuperVault::totalSupply` == SUM(user balances) + balanceOf(escrow)  (solvency) |  | ❌ |  |
| 11 | `property_escrowBalance` | balanceOf(escrow) >= SUM(controllers.pendingRedeemRequest) |  | ❌ |  |
| 12 | `property_fulfillOnlyBurnsRequestedAmount` | redemptions only burn the requested amount of shares (within tolerance range) |  | ❌ |  |
| 13 | `property_maxMintZeroWhenPaused` | `maxMint` should be 0 when aggregator is paused |  | ❌ |  |
| 14 | `property_maxDepositZeroWhenPaused` | `maxDeposit` should be 0 when strategy is paused |  | ❌ |  |
| 15 | `property_cannotClaimMoreThanRequested` | user cannot claim more assets than requested in redemption |  | ❌ |  |
| 16 | `property_cancelDoesntChangeTotalSupply` | `cancelRedeem()` should never alter the supply of SuperVault tokens (calculated by summing user share balances) |  | ❌ |  |
| 17 | `property_assetBacking` | if `totalSupply()` > 0, then `totalAssets()` > 0  |  | ✅ | ✅ |
| 18 | `property_x` | users shouldn't get a favorable exchange rate on loss on withdrawal in a yield vault |  | ❌ |  |
| 19 | `property_x` | user shouldn't be able to frontrun an oracle update to get a favorable exchange when there's a loss (TODO: determine how to test this) |  |  |  |
| 20 | `property_totalAssets` | SUM(shares) * PPS == totalAssets |  | ❌ |  |
| 21 | `superVault_transfer`, `superVault_transferFrom` | `_update` should never revert |  | ❌ |  |
| 22 | `superVault_deposit` | `previewDeposit` returns the correct amounts compared to executing a deposit |  | ✅ | ✅ |
| 23 | `superVault_mint` | `previewMint` returns the correct amounts compared to executing a redemption |  | ❌ |  |
| 24 | `doomsday_previewEquivalenceFromShares`, `doomsday_previewEquivalenceFromAssets` | `previewMint` and `previewDeposit` equivalence |  | ✅ | ✅ |
| 25 | `property_avgPPSDoesntDecrease` | When a user requests a redemption and the PPS is >= the user PPS, user `averageRequestPPS` must not decrease |  | ❌ |  |
| 26 | `property_sumOfClaimable` | After all redemptions are processed, the sum of all claimable is <= balance available |  | ✅ | ✅ |
| 27 | `property_sumOfAssetsMaxWithdrawable` | If the sum of assets in `SuperVaultStrategy` and yield strategies is 0, `maxWithdraw` should be 0 | Related to dust issue described [here](https://github.com/superform-xyz/v2-periphery/pull/43) | ❌ |  |
| 28 | `doomsday_redemptionsNeverReverts` | When claiming redemption, it should never revert with `INVALID_REDEEM_CLAIM` (doomsday) | Related to second doomsday property outlined [here](https://github.com/Recon-Fuzz/superform-review/issues/20#issue-3405662380) | ✅ | ✅ |
| 29 | `property_avgPPSMonotonicity` | `averageWithdrawPrice` should never decrease when new redemptions are fulfilled at a higher PPS |  | ❌ |  |
| 30 | `doomsday_allUsersCanWithdraw` | all users can withdraw (solvency) |  | ✅ | ✅ |
| 31 | `doomsday_mintRedeemSymmetrical` | mint/redeem doesn't cause loss to user |  | ✅ |  |
| 32 | `doomsday_depositWithdrawSymmetrical` | deposit/withdraw doesn't cause loss to user |  | ❌ |  |
| 33 | `property_comparePreviewMintAndConvertToAssets` | previewMint is >= convertToAssets |  | ✅ | ✅ |
| 34 | `property_comparePreviewDepositAndConvertToShares` | convertToShares is >= previewDepositShares (equivalent without fees) |  | ❌ |  |
| 35 | `superVaultStrategy_fulfillRedeemRequests` | superVaultStrategy does not incur loss on fulfillment | this should catch any issues related to loss on withdrawal from a yield strategy | ✅ | ✅ |
| 36 | `property_maxRedeemShouldNotRevert` | redeeming maxRedeem shouldn't revert |  | ❌ |  |
| 37 | `property_maxWithdrawShouldNotRevert` | withdrawing maxWithdraw shouldn't revert |  | ✅ | ✅ |

## SuperVaultAggregator 
| # | Property | Description | Comments | Implemented | Tested |
| --- | --- | --- | --- | --- | --- |
| 1 | `doomsday_primaryManagerAlwaysChangeable` | primary manager can always be replaced by governance via `changePrimaryManager` |  | ❌ | |
