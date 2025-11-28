// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

// External
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

// Superform
import { ISuperBank } from "./interfaces/ISuperBank.sol";
import { ISuperGovernor, FeeType } from "./interfaces/ISuperGovernor.sol";
import { Bank } from "./Bank.sol";

/// @title SuperBank
/// @notice Compounds protocol revenue into UP and distributes it to sUP and treasury.
contract SuperBank is ISuperBank, Bank {
    using SafeERC20 for IERC20;
    using Math for uint256;

    uint256 private constant BPS_PRECISION = 10_000;
    ISuperGovernor public immutable SUPER_GOVERNOR;

    constructor(address superGovernor_) {
        if (superGovernor_ == address(0)) revert INVALID_ADDRESS();
        SUPER_GOVERNOR = ISuperGovernor(superGovernor_);
    }

    modifier onlyBankManager() {
        _onlyBankManager();
        _;
    }

    function _onlyBankManager() internal view {
        if (!IAccessControl(address(SUPER_GOVERNOR)).hasRole(SUPER_GOVERNOR.BANK_MANAGER_ROLE(), msg.sender)) {
            revert INVALID_BANK_MANAGER();
        }
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // Receive function to accept direct ETH transfers if needed for hooks/executions
    receive() external payable { }

    /// @inheritdoc ISuperBank
    function distribute(uint256 upAmount) external onlyBankManager {
        if (upAmount == 0) revert ZERO_AMOUNT();

        // Cache SUPER_GOVERNOR reference to reduce external calls
        ISuperGovernor gov = SUPER_GOVERNOR;

        // Get UP token address from SuperGovernor
        address upToken = gov.getAddress(gov.UP());

        // Validate early before fetching more addresses
        if (IERC20(upToken).balanceOf(address(this)) < upAmount) revert INVALID_UP_AMOUNT_TO_DISTRIBUTE();

        // Get revenue share percentage from SuperGovernor
        uint256 revenueShare = gov.getFee(FeeType.REVENUE_SHARE);

        // Validate revenue share is within bounds
        if (revenueShare > BPS_PRECISION) revert INVALID_REVENUE_SHARE();

        // Get remaining addresses after validation
        address supStrategyVault = gov.getAddress(gov.SUP_STRATEGY());
        address treasury = gov.getAddress(gov.TREASURY());

        // Calculate amounts for sUP and Treasury
        uint256 supAmount = upAmount.mulDiv(revenueShare, BPS_PRECISION, Math.Rounding.Ceil);
        uint256 treasuryAmount = upAmount - supAmount;

        // Direct usage instead of intermediate IERC20 variable
        if (supAmount > 0) {
            IERC20(upToken).safeTransfer(supStrategyVault, supAmount);
        }

        if (treasuryAmount > 0) {
            IERC20(upToken).safeTransfer(treasury, treasuryAmount);
        }

        emit RevenueDistributed(upToken, supStrategyVault, treasury, supAmount, treasuryAmount);
    }

    /// @inheritdoc ISuperBank
    function executeHooks(ISuperBank.HookExecutionData calldata executionData) external payable onlyBankManager {
        _executeHooks(executionData);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function _getMerkleRootForHook(address hookAddress) internal view override returns (bytes32) {
        return SUPER_GOVERNOR.getSuperBankHookMerkleRoot(hookAddress);
    }

    function _isHookRegistered(address hookAddress) internal view override returns (bool) {
        return SUPER_GOVERNOR.isHookRegistered(hookAddress);
    }
}
