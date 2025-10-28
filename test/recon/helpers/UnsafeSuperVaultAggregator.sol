// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { SuperVaultAggregator } from "src/SuperVault/SuperVaultAggregator.sol";

/// @dev inherits from aggregator to override hook validation
contract UnsafeSuperVaultAggregator is SuperVaultAggregator {
    constructor(
        address superGovernor_,
        address vaultImpl_,
        address strategyImpl_,
        address escrowImpl_
    )
        SuperVaultAggregator(superGovernor_, vaultImpl_, strategyImpl_, escrowImpl_)
    { }

    function validateHook(
        address strategy,
        ValidateHookArgs calldata args
    )
        external
        pure
        override
        returns (bool isValid)
    {
        return true;
    }
}
