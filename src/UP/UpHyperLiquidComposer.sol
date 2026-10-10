// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { HyperLiquidComposer } from "lib/devtools/packages/hyperliquid-composer/contracts/HyperLiquidComposer.sol";
import {
    RecoverableComposer
} from "lib/devtools/packages/hyperliquid-composer/contracts/extensions/RecoverableComposer.sol";

/**
 * @title UpHyperLiquidComposer
 * @author Superform Foundation
 * @notice HyperLiquid Composer for UP token enabling direct bridging to HyperCore spot trading.
 * @dev Extends RecoverableComposer for emergency fund recovery capabilities.
 *      Receives composed messages from LayerZero OFT transfers and forwards tokens to HyperCore.
 *
 *      Message Flow:
 *      Source Chain (Base/Ethereum) -> OFT.send() with composeMsg -> HyperEVM OFT -> lzCompose() ->
 *      UpHyperLiquidComposer -> HyperCore Spot Trading
 */
contract UpHyperLiquidComposer is RecoverableComposer {
    /**
     * @notice Initializes the composer with UP OFT configuration.
     * @param _oft The UP OFT contract address on HyperEVM
     * @param _coreIndexId The HyperCore token index ID for UP (from HIP-1 deployment)
     * @param _assetDecimalDiff The decimal difference: EVM_decimals - Core_decimals
     *                          (e.g., 0 if both use 18 decimals, 10 if Core uses 8 decimals)
     * @param _recoveryAddress The address authorized to perform emergency recovery operations (MPC wallet)
     */
    constructor(
        address _oft,
        uint64 _coreIndexId,
        int8 _assetDecimalDiff,
        address _recoveryAddress
    )
        RecoverableComposer(_recoveryAddress)
        HyperLiquidComposer(_oft, _coreIndexId, _assetDecimalDiff)
    { }
}
