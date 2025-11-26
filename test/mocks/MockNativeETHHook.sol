// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

// Superform
import { BaseHook } from "../../lib/v2-core/src/hooks/BaseHook.sol";
import { HookSubTypes } from "../../lib/v2-core/src/libraries/HookSubTypes.sol";
import { HookDataDecoder } from "../../lib/v2-core/src/libraries/HookDataDecoder.sol";
import {
    ISuperHookResult,
    ISuperHookContextAware,
    ISuperHookInspector,
    Execution
} from "../../lib/v2-core/src/interfaces/ISuperHook.sol";
import { ISuperHook } from "../../lib/v2-core/src/interfaces/ISuperHook.sol";

/// @title MockNativeETHHook
/// @author Superform Labs
/// @notice Mock hook for testing native ETH handling in SuperVaultStrategy
/// @dev This hook simulates operations that require native ETH value
contract MockNativeETHHook is BaseHook, ISuperHookContextAware {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Target contract that will receive the ETH
    address public immutable ETH_RECEIVER;

    /// @notice Amount of ETH to send in the execution
    uint256 public ethAmount;

    /// @notice Whether this hook should use previous hook amount
    bool public usePrevAmount;

    /// @notice Event emitted when ETH is received
    event ETHReceived(address sender, uint256 amount);

    /// @notice Event emitted when execution is built
    event ExecutionBuilt(address target, uint256 value, bytes callData);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error ZERO_ADDRESS();
    error INVALID_ETH_AMOUNT();

    constructor(address ethReceiver_) BaseHook(ISuperHook.HookType.OUTFLOW, HookSubTypes.MISC) {
        if (ethReceiver_ == address(0)) revert ZERO_ADDRESS();
        ETH_RECEIVER = ethReceiver_;
    }

    /*//////////////////////////////////////////////////////////////
                            CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the ETH amount for the next execution
    /// @param amount_ Amount of ETH to send
    function setETHAmount(uint256 amount_) external {
        ethAmount = amount_;
    }

    /// @notice Set whether to use previous hook amount
    /// @param usePrev_ Whether to use previous hook amount
    function setUsePrevAmount(bool usePrev_) external {
        usePrevAmount = usePrev_;
    }

    /*//////////////////////////////////////////////////////////////
                            HOOK IMPLEMENTATION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc BaseHook
    function _buildHookExecutions(
        address prevHook,
        address account,
        bytes calldata data
    )
        internal
        view
        override
        returns (Execution[] memory executions)
    {
        // Extract yield source from the standard position (bytes 32-52)
        address yieldSource = HookDataDecoder.extractYieldSource(data);

        // Extract ETH value from the calldata (bytes 52-84)
        uint256 ethValue = 0;
        if (data.length >= 84) {
            assembly {
                ethValue := calldataload(add(data.offset, 52))
            }
        }

        // Use configured amount as fallback
        if (ethValue == 0) {
            ethValue = ethAmount;
        }

        // Check if we should use previous hook amount
        if (usePrevAmount && prevHook != address(0)) {
            ethValue = ISuperHookResult(prevHook).getOutAmount(account);
        }

        // Note: Cannot emit events in view function

        executions = new Execution[](1);
        executions[0] =
            Execution({ target: yieldSource, value: ethValue, callData: abi.encodeWithSignature("execute()") });
    }

    /// @inheritdoc ISuperHookContextAware
    function decodeUsePrevHookAmount(bytes memory) external pure returns (bool) {
        return false; // For simplicity, always return false in mock
    }

    /// @inheritdoc ISuperHookInspector
    function inspect(bytes calldata data) external pure override returns (bytes memory) {
        // Extract yield source from the standard position
        address yieldSource = HookDataDecoder.extractYieldSource(data);
        return abi.encodePacked(yieldSource);
    }

    /// @notice Decode the amount from hook data
    /// @param data The hook data to decode
    /// @return The amount value
    function decodeAmount(bytes memory data) external pure returns (uint256) {
        // Extract amount from bytes 52-84 (after oracle ID and yield source)
        if (data.length >= 84) {
            uint256 amount;
            assembly {
                amount := mload(add(data, 84)) // Load 32 bytes starting at position 52 (32 + 20 + 32)
            }
            return amount;
        }
        return 0;
    }

    /// @notice Replace the amount in hook calldata
    /// @param data The original hook data
    /// @param newAmount The new amount to replace with
    /// @return The updated hook data
    function replaceCalldataAmount(bytes memory data, uint256 newAmount) external pure returns (bytes memory) {
        if (data.length >= 84) {
            // Replace the amount at bytes 52-84
            assembly {
                mstore(add(data, 84), newAmount)
            }
        }
        return data;
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/

    function _preExecute(address, address account, bytes calldata) internal override {
        // Set initial balance for tracking
        _setOutAmount(account.balance, account);
    }

    function _postExecute(address, address account, bytes calldata) internal override {
        // Calculate difference between final and initial balance
        uint256 initialBalance = getOutAmount(account);
        uint256 finalBalance = account.balance;
        _setOutAmount(initialBalance - finalBalance, account);
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Allows the hook to receive ETH
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
}
