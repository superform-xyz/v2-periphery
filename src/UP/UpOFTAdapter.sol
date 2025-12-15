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
    address public constant UP_TOKEN = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;

    error NATIVE_TRANSFER_FAILED();
    error UP_TOKEN_NOT_VALID();
    error ADDRESS_NOT_VALID();

    /**
     * @notice Initializes the OFT Adapter with the UP token address and LayerZero endpoint.
     * @param _token The address of the existing UP token (0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33 on Ethereum mainnet)
     * @param _lzEndpoint The LayerZero v2 endpoint address
     * @param _delegate The delegate capable of making OApp configurations (typically the owner)
     */
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    ) OFTAdapter(_token, _lzEndpoint, _delegate) Ownable(_delegate) { 
        // Enforce canonical UP token on Ethereum mainnet to prevent misconfiguration
        if (block.chainid == 1 && _token != UP_TOKEN) {
            revert UP_TOKEN_NOT_VALID();
        }

        if (_lzEndpoint == address(0) || _lzEndpoint.code.length == 0) {
            revert ADDRESS_NOT_VALID();
        }
    }

    function sweepNative(address payable to) external onlyOwner {
        (bool s, ) = to.call{value: address(this).balance}("");
        if(!s) revert NATIVE_TRANSFER_FAILED();
    }
}
