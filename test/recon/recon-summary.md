# Summary 

Over the course of 4 weeks an invariant testing suite was built to test 51 properties. The implemented properties are outlined in the [properties-table](https://github.com/superform-xyz/v2-periphery/blob/recon-invariants/test/recon/properties-table.md) file. 

After running Echidna for 100 million+ runs the following issues were discovered.

## Findings

1. [`previewMint` return value with 100% fees](https://github.com/Recon-Fuzz/superform-review/issues/49)
2. [`previewDeposit` and `previewMint` divergence](https://github.com/Recon-Fuzz/superform-review/issues/55)
3. [Donations to yield source cause a loss on withdrawal for users](https://github.com/Recon-Fuzz/superform-review/issues/61)
4. [`fulfillRedeemRequests` can cause `accumulatorShares` and `accumulatorCostBasis` to not decrease correctly](https://github.com/Recon-Fuzz/superform-review/issues/62)
5. [Attempting to withdraw `maxWithdraw` reverts](https://github.com/Recon-Fuzz/superform-review/issues/66)
6. [Insolvency in `SuperVaultStrategy`](https://github.com/Recon-Fuzz/superform-review/issues/67)
7. [Unbacked shares remain on withdrawal](https://github.com/Recon-Fuzz/superform-review/issues/68)
8. [Users can lose value on mint/redeem](https://github.com/Recon-Fuzz/superform-review/issues/70)

## Recommendations

1. Mocking yield sources that use swapping and rewards would provide more realistic testing as the current yield source mocks only mock 4626, 7540 and 5115 vaults. Given that swapping and rewards yield sources only expect to be interacted with via `executeHooks` this may cause inconsistencies if there's logic that normally gets executed in a redemption fulfillment that doesn't get executed via `executeHooks`.
2. An optimization test adressing the issue outlined [here](https://github.com/Recon-Fuzz/superform-review/issues/34) would be valuable in helping to determine the maximum possible impact of rounding down in the cost basis ratio calculation. From manual review and modeling in excel it seems like the impact is limited but an optimization test would give greater insight, the primary difficulty is in determining how to implement the optimization.
3. Checking `redeem`/`withdraw` never revert due to underflow. In the currently handler setup these can easily revert due to overflow with large share values and a high price. This would therefore be best tested with a stateless fuzz test to determine that it doesn't revert due to underflow for valid values.
4. Identifying the source of `maxWithdraw` issue [here](https://github.com/Recon-Fuzz/superform-review/issues/66) would allow determining if this poses real risk of loss of funds or is only an inconsistent calculation issue. 

## Admin Mistakes

The following identify issues that an admin can make that lead to breaking system properties:

1. After a redemption is fulfilled and the funds are transferred to the `SuperVaultStrategy` from the yield strategy in which they were invested in an admin can prevent users calling `withdraw`/`redeem` by reinvesting the funds via `executeHooks`. This leaves users with a claimable amount but no way to claim it unless the admin calls `executeHooks` again to transfer funds back to the `SuperVaultStrategy`. For this reason the `_claimableMoreThanInvested` function checks the amount `superVaultStrategy_executeHooks_clamped` can deposit into a yield strategy, otherwise a significant number of properties break.
2. If an admin fulfills a redemption at a high price it can lock in insolvency. See the issue [here](https://github.com/Recon-Fuzz/superform-review/issues/67) 

The following properties would be good candidates for live monitoring to ensure that the above admin mistakes can't cause issues in production: 
- `doomsday_allUsersCanRedeem` 
- `property_sumOfClaimable` 
- `property_superVaultStrategySolvency`
- `crytic_erc7540_7_withdraw`
- `crytic_erc7540_7_redeem`
- `property_assetBacking`
- `doomsday_mintRedeemSymmetrical`
