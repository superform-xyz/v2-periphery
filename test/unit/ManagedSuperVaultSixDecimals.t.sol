// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { ManagedSuperVaultTestBase } from "../utils/ManagedSuperVaultTestBase.sol";
import { ManagedSuperVault } from "../../src/ManagedSuperVault/ManagedSuperVault.sol";
import { ManagedSuperVaultStrategy } from "../../src/ManagedSuperVault/ManagedSuperVaultStrategy.sol";
import { ManagedSuperVaultDepositQueue } from "../../src/ManagedSuperVault/ManagedSuperVaultDepositQueue.sol";
import { SuperVaultEscrow } from "../../src/SuperVault/SuperVaultEscrow.sol";
import { IManagedSuperVaultAggregator } from "../../src/interfaces/ManagedSuperVault/IManagedSuperVaultAggregator.sol";
import { MockERC20 } from "../mocks/MockERC20.sol";

/// @notice 6-decimal (USDC-like) asset coverage: PPS/PRECISION scale to ASSET decimals, so the whole
///         lifecycle — queue deposit -> claim -> attested NAV -> native redeem -> withdraw — must be
///         exact at 1e6 scale. Restores the 6-decimal round-trip coverage the prior suite had.
contract ManagedSuperVaultSixDecimalsTest is ManagedSuperVaultTestBase {
    using Math for uint256;

    MockERC20 internal usdc;
    ManagedSuperVault internal vault6;
    ManagedSuperVaultStrategy internal strategy6;
    SuperVaultEscrow internal escrow6;
    ManagedSuperVaultDepositQueue internal queue6;

    uint256 internal constant PRECISION_6 = 1e6; // PPS scale for a 6-decimal asset
    uint256 internal constant USER_USDC = 1_000_000e6;

    function setUp() public override {
        super.setUp();

        usdc = new MockERC20("USD Coin", "USDC", 6);

        IManagedSuperVaultAggregator.VaultCreationParams memory params = _defaultParams();
        params.asset = address(usdc);
        params.name = "Managed USDC Vault";
        params.symbol = "mUSDC";

        (address vault_, address strategy_, address escrow_, address queue_) = _createManagedVault(params);
        vault6 = ManagedSuperVault(vault_);
        strategy6 = ManagedSuperVaultStrategy(payable(strategy_));
        escrow6 = SuperVaultEscrow(escrow_);
        queue6 = ManagedSuperVaultDepositQueue(queue_);

        usdc.mint(user, USER_USDC);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev _pushNAV in the base is keyed to the default (18-decimal) vault's strategy;
    ///      this is the same propose+attest flow keyed by the 6-decimal vault's strategy
    function _pushNAV6(uint256 newPPS) internal {
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);

        vm.prank(manager);
        uint256 proposalId =
            navOracle.proposeNAVUpdate(address(strategy6), newPPS, block.timestamp, EVIDENCE_HASH, "ipfs://evidence");

        vm.prank(attestor);
        navOracle.attestNAVUpdate(address(strategy6), proposalId);
    }

    function _request6(address depositor, uint256 assets) internal {
        vm.startPrank(depositor);
        usdc.approve(address(queue6), assets);
        queue6.requestDeposit(assets, depositor, depositor);
        vm.stopPrank();
    }

    function _fulfill6(address controller) internal {
        address[] memory controllers = new address[](1);
        controllers[0] = controller;
        vm.prank(manager);
        queue6.fulfillDepositRequests(controllers);
    }

    /*//////////////////////////////////////////////////////////////
                                TESTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Inception PPS and PRECISION are 1e6 for a 6-decimal asset (never 1e18)
    function test_SixDecimals_InceptionScale() public view {
        assertEq(vault6.PRECISION(), PRECISION_6, "PRECISION = 10^assetDecimals");
        assertEq(aggregator.getPPS(address(strategy6)), PRECISION_6, "initial PPS = 1.0 in 1e6 scale");
        assertEq(strategy6.getStoredPPS(), PRECISION_6, "strategy mirrors the aggregator PPS");
        assertEq(vault6.decimals(), 6, "share token uses asset decimals");
    }

    /// @notice Full 6-decimal lifecycle: queue deposit -> claim (partial + remainder) -> NAV 1.05e6
    ///         -> native requestRedeem -> exact fulfill -> withdraw; every amount exact at 1e6 scale
    function test_SixDecimals_FullLifecycle_DepositToRedeem() public {
        uint256 amount = 1_000e6;

        // --- request: queue takes custody of pending assets ---
        _request6(user, amount);
        assertEq(queue6.pendingDepositRequest(0, user), amount, "pending assets");
        assertEq(usdc.balanceOf(address(queue6)), amount, "queue holds pending assets");
        assertEq(usdc.balanceOf(user), USER_USDC - amount, "user debited");

        // --- fulfill at inception PPS 1e6: shares = net * 1e6 / pps (zero mgmt fee => net == gross) ---
        _fulfill6(user);
        uint256 expectedShares = amount.mulDiv(PRECISION_6, PRECISION_6); // = 1_000e6 shares
        assertEq(queue6.claimableDepositRequest(0, user), amount, "claimable assets == net == gross");
        assertEq(queue6.maxMint(user), expectedShares, "shares = net * 1e6 / pps");
        assertEq(queue6.getAverageDepositPrice(user), PRECISION_6, "average deposit price in 1e6 scale");
        assertEq(vault6.balanceOf(address(queue6)), expectedShares, "queue custodies pre-minted shares");
        assertEq(usdc.balanceOf(address(strategy6)), amount, "gross forwarded to the strategy");

        // --- claim native shares: one partial claim + the remainder (pro-rata, exact) ---
        uint256 a1 = 400e6;
        uint256 expectedS1 = expectedShares.mulDiv(a1, amount); // floor pro-rata
        vm.prank(user);
        uint256 s1 = queue6.deposit(a1, user, user);
        assertEq(s1, expectedS1, "partial claim pro-rata at 6 decimals");
        assertEq(queue6.maxDeposit(user), amount - a1, "remaining claimable assets");
        assertEq(queue6.maxMint(user), expectedShares - s1, "remaining claimable shares");

        vm.prank(user);
        uint256 s2 = queue6.deposit(amount - a1, user, user);
        assertEq(s1 + s2, expectedShares, "partials sum exactly to minted shares");
        assertEq(vault6.balanceOf(user), expectedShares, "user holds native 6-decimal shares");
        assertEq(vault6.balanceOf(address(queue6)), 0, "queue fully drained");
        assertEq(queue6.maxDeposit(user), 0);
        assertEq(queue6.maxMint(user), 0);

        // --- push an attested NAV of 1.05 in 1e6 scale ---
        _pushNAV6(1.05e6);
        assertEq(strategy6.getStoredPPS(), 1.05e6, "attested PPS stored in 1e6 scale");

        // --- native requestRedeem: shares locked in escrow ---
        vm.prank(user);
        vault6.requestRedeem(expectedShares, user, user);
        assertEq(vault6.balanceOf(user), 0, "all shares escrowed");
        assertEq(vault6.balanceOf(address(escrow6)), expectedShares, "escrow custodies shares");

        // --- manager fulfills at the exact theoretical value: assets = shares * pps / 1e6 ---
        uint256 theoretical = expectedShares.mulDiv(1.05e6, PRECISION_6);
        assertEq(theoretical, 1_050e6, "1000 shares at 1.05 -> 1050 USDC");

        // Realize the attested 5% gain into the strategy so fulfillment is solvent
        usdc.mint(address(strategy6), theoretical - usdc.balanceOf(address(strategy6)));

        address[] memory controllers = new address[](1);
        controllers[0] = user;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = theoretical;
        vm.prank(manager);
        strategy6.fulfillRedeemRequests(controllers, amounts);

        assertEq(vault6.maxWithdraw(user), theoretical, "claimable withdrawal at 1e6 scale");
        assertEq(strategy6.getAverageWithdrawPrice(user), 1.05e6, "average withdraw price in 1e6 scale");
        assertEq(usdc.balanceOf(address(escrow6)), theoretical, "assets moved to escrow at fulfill");
        assertEq(vault6.balanceOf(address(escrow6)), 0, "escrowed shares burned");
        assertEq(vault6.totalSupply(), 0, "full redemption burns all supply");

        // --- withdraw: exact assets from escrow ---
        vm.prank(user);
        vault6.withdraw(theoretical, user, user);

        assertEq(usdc.balanceOf(user), USER_USDC + 50e6, "user realized exactly the 5% NAV gain");
        assertEq(vault6.maxWithdraw(user), 0, "claimable zeroed");
        assertEq(usdc.balanceOf(address(escrow6)), 0, "escrow drained");
    }

    /// @notice Odd gross amount fulfilled at PPS 1.05e6: floor share mint, derived average price,
    ///         and pro-rata partial claims stay exact and conserve at 6-decimal scale
    function test_SixDecimals_ProRataClaims_OddAmounts() public {
        _pushNAV6(1.05e6);

        uint256 gross = 1_000_000_007; // 1000.000007 USDC — forces floor rounding everywhere
        _request6(user, gross);
        _fulfill6(user);

        uint256 assetsTotal = queue6.maxDeposit(user);
        uint256 sharesTotal = queue6.maxMint(user);
        assertEq(assetsTotal, gross, "net == gross with zero mgmt fee");
        assertEq(sharesTotal, gross.mulDiv(PRECISION_6, 1.05e6), "shares = gross * 1e6 / pps (floor)");
        assertEq(sharesTotal, 952_380_959, "pinned 6-decimal share amount");
        assertEq(queue6.getAverageDepositPrice(user), 1.05e6, "derived average price in 1e6 scale");

        // Partial claim: pro-rata floor over the exact claimable balances
        uint256 a1 = 333_333_333;
        uint256 expectedS1 = sharesTotal.mulDiv(a1, assetsTotal);
        assertEq(expectedS1, 317_460_317, "pinned pro-rata partial");
        vm.prank(user);
        uint256 s1 = queue6.deposit(a1, user, user);
        assertEq(s1, expectedS1, "partial claim floors pro-rata");
        assertEq(queue6.maxDeposit(user), assetsTotal - a1);
        assertEq(queue6.maxMint(user), sharesTotal - s1);
        assertEq(
            queue6.getAverageDepositPrice(user),
            (assetsTotal - a1).mulDiv(PRECISION_6, sharesTotal - s1),
            "average price re-derived from remaining balances"
        );

        // Remainder claim exhausts both balances exactly — no dust stranded, none over-distributed
        vm.prank(user);
        uint256 s2 = queue6.deposit(assetsTotal - a1, user, user);
        assertEq(s1 + s2, sharesTotal, "claims conserve the full share mint");
        assertEq(queue6.maxDeposit(user), 0);
        assertEq(queue6.maxMint(user), 0);
        assertEq(vault6.balanceOf(user), sharesTotal);
        assertEq(vault6.balanceOf(address(queue6)), 0, "queue holds nothing after full claim");
    }
}
