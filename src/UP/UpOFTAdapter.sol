// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { OFTAdapter } from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";

/**
 * @title UpOFTAdapter
 * @author Superform Foundation
 * @notice OFT Adapter for the UP token on Ethereum mainnet.
 * @dev Locks UP tokens on Ethereum when bridging out, unlocks when bridging in.
 *      Deploy this ONLY on Ethereum where the canonical UP token exists.
 */
contract UpOFTAdapter is OFTAdapter {
    /**
     * @notice Initializes the OFT Adapter with the UP token address and LayerZero endpoint.
     * @param _token The address of the existing UP token (0x1d926bbe67425c9f507b9a0e8030eedc7880bf33 on mainnet)
     * @param _lzEndpoint The LayerZero v2 endpoint address
     * @param _delegate The delegate capable of making OApp configurations (typically the owner)
     */
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    ) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate) { }
}
