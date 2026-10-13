// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import { Test, console2 } from "forge-std/Test.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { ISuperGovernor } from "../../../src/interfaces/ISuperGovernor.sol";
import { ISuperOracle } from "../../../src/interfaces/oracles/ISuperOracle.sol";
import { ISuperVaultAggregator } from "../../../src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import { ISuperVaultStrategy } from "../../../src/interfaces/SuperVault/ISuperVaultStrategy.sol";
import { ISuperVault } from "../../../src/interfaces/SuperVault/ISuperVault.sol";
import { IECDSAPPSOracle } from "../../../src/interfaces/oracles/IECDSAPPSOracle.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

interface IGasFeed {
    function latestAnswer() external view returns (int256);
}

interface IAggregatorUpkeepView {
    function claimableUpkeep() external view returns (uint256);
}

/// @title BSCDeploymentForkTest
/// @notice End-to-end check of the BNB Chain (56) SuperVaults periphery deployment of 2026-09-10:
///         wiring of the live contracts, then a real vault lifecycle through the production
///         SuperVaultAggregator - createVault -> deposit -> requestRedeem -> fulfil -> redeem - and the
///         upkeep economics now that gasPerEntry is set: signed PPS update debits the strategy's UP
///         upkeep balance by exactly the quoted cost, insufficient upkeep auto-pauses, governance
///         claims spent upkeep into SuperBank, and the manager can withdraw after the 24h timelock.
/// @dev Fork of BSC mainnet. Set BSC_RPC_URL for a private endpoint; falls back to the public
///      dataseed (rate-limited but sufficient for this suite).
contract BSCDeploymentForkTest is Test {
    /*//////////////////////////////////////////////////////////////
                    PRODUCTION ADDRESSES (BNB CHAIN, 56)
    //////////////////////////////////////////////////////////////*/
    // Periphery (script/output/prod/56/BNB-latest.json) - CREATE2, identical to Ethereum/Base
    address constant SUPER_GOVERNOR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;
    address constant AGGREGATOR = 0x10AC0b33e1C4501CF3ec1cB1AE51ebfdbd2d4698;
    address constant SUPER_ORACLE = 0x673ec4771F86Ddc9E6fDc47Ab44B91a8231De5eC;
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant ECDSA_PPS_ORACLE = 0x366d88F03B8EF34eb49F32a927ff6e1609F694F2;
    address constant FIXED_PRICE_ORACLE = 0x66b30A0Dda7F868796ADC3d70232950D65F3565c;
    address constant SUPER_VAULT_IMPL = 0x303834cd8681BD6Bd31ce7508822b12E2f38D9f2;
    address constant STRATEGY_IMPL = 0x770abd170404B8ed8182c04f380E567e647b457D;
    address constant ESCROW_IMPL = 0x8982cf48eaB6616f2892888410afad9b0CD2BC9B;
    address constant EXECUTOR = 0x183e3171EEf801cE2A29FD48B3b21188f241875d;
    address constant BATCH_OPERATOR = 0x73d3f46d3a9f98C55C512DEca29993D28F93817c;
    address constant SUPERFORM_GAS_ORACLE = 0x473b88f017dE39d85a102DA01A35a1b3507eBcFc;
    address constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;

    // Chain-native feeds / assets
    address constant CHAINLINK_BNB_USD = 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE; // 8 decimals
    address constant USDC_BSC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d; // Binance-Peg USDC, 18 decimals

    // SuperOracle pseudo-tokens (ConfigBase)
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant USD_TOKEN = 0x0000000000000000000000000000000000000348;
    address constant GAS_QUOTE = address(uint160(uint256(keccak256("GAS_QUOTE"))));
    address constant WEI_QUOTE = address(uint160(uint256(keccak256("WEI_QUOTE"))));
    bytes32 constant AVERAGE_PROVIDER = keccak256("AVERAGE_PROVIDER");

    uint256 constant EXPECTED_HOOKS = 59; // ConfigureV2Periphery._hookKeys() as registered 2026-09-10
    uint256 constant PRECISION = 1e18;
    uint256 constant GAS_PER_ENTRY = 135_000; // SetGasInfo (toolbox) applied on BSC 2026-09-10, same as Ethereum
    uint256 constant UP_USD_PRICE = 0.09e18; // FixedPriceOracle
    uint256 constant MIN_UPDATE_INTERVAL = 3600;

    // OZ AccessControl role ids (SuperGovernor)
    bytes32 constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");

    // GOVERNOR_ROLE candidates on BSC: deployer until the Safe handover, Safe afterwards
    address constant DEPLOYER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;
    address constant SUPERFORM_SAFE = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;

    // Test-only PPS validator (swapped into the governor's validator set on the fork)
    uint256 constant TEST_VALIDATOR_KEY = 0xB5C;

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/
    ISuperGovernor internal governor = ISuperGovernor(SUPER_GOVERNOR);
    ISuperVaultAggregator internal aggregator = ISuperVaultAggregator(AGGREGATOR);
    ISuperOracle internal superOracle = ISuperOracle(SUPER_ORACLE);
    IERC20 internal usdc = IERC20(USDC_BSC);

    address internal manager = makeAddr("bsc-vault-manager");
    address internal treasury = makeAddr("bsc-fee-recipient");
    address internal alice = makeAddr("alice");
    address internal keeper = makeAddr("pps-keeper"); // any EOA may submit signed updates
    address internal testValidator;

    IECDSAPPSOracle internal ppsOracle = IECDSAPPSOracle(ECDSA_PPS_ORACLE);
    IERC20 internal up = IERC20(UP_OFT);

    function setUp() public {
        vm.createSelectFork(vm.envOr("BSC_RPC_URL", string("https://bsc-dataseed.binance.org")));
        assertEq(block.chainid, 56, "not a BSC fork");
        testValidator = vm.addr(TEST_VALIDATOR_KEY);
    }

    /*//////////////////////////////////////////////////////////////
                        1. DEPLOYMENT WIRING
    //////////////////////////////////////////////////////////////*/

    function test_Fork_BSC_AllContractsHaveCode() public view {
        address[13] memory deployed = [
            SUPER_GOVERNOR,
            AGGREGATOR,
            SUPER_ORACLE,
            SUPER_BANK,
            ECDSA_PPS_ORACLE,
            FIXED_PRICE_ORACLE,
            SUPER_VAULT_IMPL,
            STRATEGY_IMPL,
            ESCROW_IMPL,
            EXECUTOR,
            BATCH_OPERATOR,
            SUPERFORM_GAS_ORACLE,
            UP_OFT
        ];
        for (uint256 i; i < deployed.length; ++i) {
            assertGt(deployed[i].code.length, 0, "missing code");
        }
    }

    function test_Fork_BSC_GovernorWiring() public view {
        assertEq(governor.getAddress(governor.SUPER_VAULT_AGGREGATOR()), AGGREGATOR, "aggregator");
        assertEq(governor.getAddress(governor.SUPER_ORACLE()), SUPER_ORACLE, "super oracle");
        assertEq(governor.getAddress(governor.SUPER_BANK()), SUPER_BANK, "super bank");
        assertEq(governor.getAddress(governor.UP()), UP_OFT, "UP token");
        assertEq(governor.getAddress(governor.UPKEEP_TOKEN()), UP_OFT, "UPKEEP token");
        assertEq(governor.getActivePPSOracle(), ECDSA_PPS_ORACLE, "active PPS oracle");
        assertGe(governor.getRegisteredHooks().length, EXPECTED_HOOKS, "hooks registered");
        assertTrue(governor.isUpkeepPaymentsEnabled(), "upkeep payments enabled (prod)");
    }

    /// @dev Native/USD via Chainlink BNB/USD, UP/USD via the FixedPriceOracle ($0.09), and the
    ///      GAS->WEI feed (SuperformGasOracle) must all answer through the live SuperOracle
    function test_Fork_BSC_OracleFeedsAnswer() public view {
        (uint256 bnbUsd,, uint256 total, uint256 available) =
            superOracle.getQuoteFromProvider(1e18, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        assertGt(bnbUsd, 100e18, "BNB/USD implausibly low");
        assertLt(bnbUsd, 100_000e18, "BNB/USD implausibly high");
        assertEq(total, available, "BNB/USD provider unavailable");

        (uint256 upUsd,,,) = superOracle.getQuoteFromProvider(1e18, UP_OFT, USD_TOKEN, AVERAGE_PROVIDER);
        assertEq(upUsd, 0.09e18, "UP/USD fixed price");

        // GAS -> WEI (SuperformGasOracle, wei per gas unit) must be quotable and non-zero
        (uint256 weiFor135kGas,,,) = superOracle.getQuoteFromProvider(135_000, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        assertGt(weiFor135kGas, 0, "GAS->WEI feed answers");

        // gasPerEntry is set on BSC (SetGasInfo, 2026-09-10) so the full gas -> BNB -> USD -> UP
        // conversion answers. Detailed reconciliation in test_Fork_BSC_UpkeepCostMatchesFeeds.
        assertEq(governor.getGasInfo(ECDSA_PPS_ORACLE), GAS_PER_ENTRY, "gasPerEntry configured on BSC");
        assertGt(governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE), 0, "upkeep cost quotable");
    }

    /*//////////////////////////////////////////////////////////////
                    2. VAULT LIFECYCLE ON THE LIVE AGGREGATOR
    //////////////////////////////////////////////////////////////*/

    function _createVault() internal returns (address vault, address strategy, address escrow) {
        (vault, strategy, escrow) = aggregator.createVault(
            ISuperVaultAggregator.VaultCreationParams({
                asset: USDC_BSC,
                name: "BSC Fork Test SuperVault USDC",
                symbol: "tsvUSDC-bsc",
                mainManager: manager,
                secondaryManagers: new address[](0),
                minUpdateInterval: 3600,
                maxStaleness: 86_400,
                feeConfig: ISuperVaultStrategy.FeeConfig({
                    performanceFeeBps: 1000, managementFeeBps: 0, recipient: treasury
                })
            })
        );
    }

    function test_Fork_BSC_CreateVault() public {
        (address vault, address strategy, address escrow) = _createVault();

        assertGt(vault.code.length, 0, "vault clone");
        assertGt(strategy.code.length, 0, "strategy clone");
        assertGt(escrow.code.length, 0, "escrow clone");
        assertEq(IERC4626(vault).asset(), USDC_BSC, "asset");
        assertEq(aggregator.getMainManager(strategy), manager, "main manager seated");
        assertEq(aggregator.getPPS(strategy), 10 ** 18, "initial PPS = 1.0 in asset decimals (USDC on BSC has 18)");
        assertEq(IERC4626(vault).totalAssets(), 0, "fresh vault is empty");
    }

    function test_Fork_BSC_CreateVaultAndDeposit() public {
        (address vault, address strategy,) = _createVault();
        uint256 amount = 1000e18; // 1,000 USDC (18 decimals on BSC)

        deal(USDC_BSC, alice, amount);
        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        vm.stopPrank();

        // PPS is 1.0 and managementFee is 0 -> 1:1 shares, assets land in the strategy
        assertEq(shares, amount, "1:1 shares at initial PPS");
        assertEq(IERC20(vault).balanceOf(alice), shares, "alice holds the shares");
        assertEq(usdc.balanceOf(strategy), amount, "strategy holds the deposit");
        assertEq(usdc.balanceOf(alice), 0, "alice paid");
        assertEq(IERC4626(vault).totalAssets(), amount, "totalAssets");
        assertEq(IERC4626(vault).convertToAssets(shares), amount, "convertToAssets");
        assertEq(IERC4626(vault).totalSupply(), shares, "totalSupply");
    }

    /// @notice Deposit, then the async exit: user requests redeem, manager fulfils from idle
    ///         liquidity, user claims. Exercises the production strategy/escrow clones end to end.
    function test_Fork_BSC_DepositRequestRedeemFulfillAndRedeem() public {
        (address vault, address strategy, address escrow) = _createVault();
        uint256 amount = 2500e18;

        deal(USDC_BSC, alice, amount);
        vm.startPrank(alice);
        usdc.approve(vault, amount);
        uint256 shares = IERC4626(vault).deposit(amount, alice);
        ISuperVault(vault).requestRedeem(shares, alice, alice);
        vm.stopPrank();
        assertEq(IERC20(vault).balanceOf(alice), 0, "shares escrowed on request");

        // Manager fulfils the exact pending amount (PPS still 1.0, no gain -> no performance fee)
        address[] memory controllers = new address[](1);
        controllers[0] = alice;
        uint256[] memory assetsOut = new uint256[](1);
        assetsOut[0] = amount;
        vm.prank(manager);
        ISuperVaultStrategy(strategy).fulfillRedeemRequests(controllers, assetsOut);

        assertEq(usdc.balanceOf(escrow), amount, "net assets parked in escrow");
        assertEq(ISuperVault(vault).claimableRedeemRequest(0, alice), shares, "claimable shares");

        vm.prank(alice);
        uint256 assetsBack = IERC4626(vault).redeem(shares, alice, alice);

        assertEq(assetsBack, amount, "full principal back at PPS 1.0");
        assertEq(usdc.balanceOf(alice), amount, "alice made whole");
        assertEq(IERC4626(vault).totalSupply(), 0, "all shares burned");
        assertEq(usdc.balanceOf(escrow), 0, "escrow drained");
    }

    /// @notice A second, unrelated user depositing after the first keeps 1:1 accounting
    function test_Fork_BSC_TwoDepositorsShareProRata() public {
        (address vault,,) = _createVault();
        address bob = makeAddr("bob");
        deal(USDC_BSC, alice, 100e18);
        deal(USDC_BSC, bob, 300e18);

        vm.startPrank(alice);
        usdc.approve(vault, 100e18);
        IERC4626(vault).deposit(100e18, alice);
        vm.stopPrank();
        vm.startPrank(bob);
        usdc.approve(vault, 300e18);
        IERC4626(vault).deposit(300e18, bob);
        vm.stopPrank();

        assertEq(IERC4626(vault).totalAssets(), 400e18);
        assertLe(IERC4626(vault).maxWithdraw(alice) + IERC4626(vault).maxWithdraw(bob), 400e18, "no over-claim");
        assertEq(IERC4626(vault).convertToAssets(IERC20(vault).balanceOf(bob)), 300e18, "bob pro-rata");
    }

    /*//////////////////////////////////////////////////////////////
                    3. UPKEEP ECONOMICS (LIVE ORACLES + FEEDS)
    //////////////////////////////////////////////////////////////*/

    /// @notice The governor's UP quote per PPS update must equal the composition of the three live
    ///         feeds: 135k gas x SuperformGasOracle (wei/gas) -> Chainlink BNB/USD -> UP at $0.09.
    function test_Fork_BSC_UpkeepCostMatchesFeeds() public view {
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);

        uint256 weiPerGas = uint256(IGasFeed(SUPERFORM_GAS_ORACLE).latestAnswer());
        assertGt(weiPerGas, 0, "gas oracle answers");
        (uint256 weiForUpdate,,,) =
            superOracle.getQuoteFromProvider(GAS_PER_ENTRY, GAS_QUOTE, WEI_QUOTE, AVERAGE_PROVIDER);
        assertEq(weiForUpdate, GAS_PER_ENTRY * weiPerGas, "GAS->WEI is linear in the oracle answer");

        (uint256 usdForUpdate,,,) =
            superOracle.getQuoteFromProvider(weiForUpdate, NATIVE_TOKEN, USD_TOKEN, AVERAGE_PROVIDER);
        uint256 expected = usdForUpdate * PRECISION / UP_USD_PRICE;

        assertApproxEqRel(cost, expected, 1e12, "UP cost = usd(gas) / usd(UP)");
        // Sanity band: BSC gas is 0.05 gwei, so an update costs a few cents -> well under 1 UP
        assertLt(cost, 1e18, "cost below 1 UP");
        console2.log("BSC upkeep cost per PPS update (UP wei):", cost);
    }

    /// @notice Happy path: manager funds upkeep in UP, keeper submits a validator-signed PPS,
    ///         the aggregator stores the new PPS and debits exactly the quoted cost.
    function test_Fork_BSC_PPSUpdateDebitsUpkeep() public {
        (address vault, address strategy,) = _createVault();
        _seedDeposit(vault, alice, 1000e18);
        _installTestValidator();

        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        uint256 funded = 10 * cost;
        _fundUpkeep(strategy, funded);
        assertEq(aggregator.getUpkeepBalance(strategy), funded, "upkeep credited to strategy");
        assertEq(up.balanceOf(AGGREGATOR), funded, "UP held by aggregator");

        uint256 claimableBefore = IAggregatorUpkeepView(AGGREGATOR).claimableUpkeep();
        uint256 nonceBefore = ppsOracle.noncePerStrategy(strategy);
        uint256 newPPS = 1.01e18; // +1%, well inside the default deviation threshold

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectEmit(true, false, false, true, AGGREGATOR);
        emit ISuperVaultAggregator.UpkeepSpent(strategy, cost, funded, claimableBefore + cost);
        vm.expectEmit(true, false, false, true, AGGREGATOR);
        emit ISuperVaultAggregator.PPSUpdated(strategy, newPPS, block.timestamp);
        _submitPPS(strategy, newPPS);

        assertEq(aggregator.getPPS(strategy), newPPS, "PPS stored");
        assertEq(aggregator.getUpkeepBalance(strategy), funded - cost, "upkeep decreased by exactly one update");
        assertEq(
            IAggregatorUpkeepView(AGGREGATOR).claimableUpkeep(),
            claimableBefore + cost,
            "spent upkeep becomes claimable"
        );
        assertEq(ppsOracle.noncePerStrategy(strategy), nonceBefore + 1, "nonce consumed");
        assertFalse(aggregator.isStrategyPaused(strategy), "strategy live");
        assertFalse(aggregator.isPPSStale(strategy), "PPS fresh");
        // Depositors' claim on assets follows the new PPS
        assertEq(IERC4626(vault).convertToAssets(1e18), newPPS, "1 share = 1.01 USDC");
    }

    /// @notice Two consecutive paid updates: each debits the then-current quote, and a replayed
    ///         signature (old nonce) is rejected without touching the balance.
    function test_Fork_BSC_ConsecutiveUpdatesAndReplayRejected() public {
        (, address strategy,) = _createVault();
        _installTestValidator();
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        _fundUpkeep(strategy, 3 * cost);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        bytes memory firstSig = _signPPS(strategy, 1.01e18, block.timestamp);
        uint256 firstTs = block.timestamp;
        _submitSigned(strategy, 1.01e18, firstTs, firstSig);
        assertEq(aggregator.getUpkeepBalance(strategy), 2 * cost, "first debit");

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _submitPPS(strategy, 1.02e18);
        assertEq(aggregator.getUpkeepBalance(strategy), cost, "second debit");
        assertEq(aggregator.getPPS(strategy), 1.02e18);

        // Replay of the first signature: nonce moved on, so proof validation fails inside the
        // oracle (emits ProofValidationFailed*, forwards nothing). No debit, PPS unchanged.
        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _submitSigned(strategy, 1.01e18, firstTs, firstSig);
        assertEq(aggregator.getUpkeepBalance(strategy), cost, "replay not charged");
        assertEq(aggregator.getPPS(strategy), 1.02e18, "replay ignored");
    }

    /// @notice Unfunded strategy: the update is refused, the strategy is auto-paused and its PPS
    ///         flagged stale, and nothing is debited. Deposits are then blocked until unpaused.
    function test_Fork_BSC_InsufficientUpkeepPausesStrategy() public {
        (address vault, address strategy,) = _createVault();
        _installTestValidator();
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        _fundUpkeep(strategy, cost - 1); // one wei short

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        vm.expectEmit(true, true, false, true, AGGREGATOR);
        emit ISuperVaultAggregator.InsufficientUpkeep(strategy, strategy, cost - 1, cost);
        _submitPPS(strategy, 1.01e18);

        assertTrue(aggregator.isStrategyPaused(strategy), "auto-paused");
        assertTrue(aggregator.isPPSStale(strategy), "PPS stale");
        assertEq(aggregator.getPPS(strategy), 1e18, "PPS unchanged");
        assertEq(aggregator.getUpkeepBalance(strategy), cost - 1, "nothing debited");

        deal(USDC_BSC, alice, 1e18);
        vm.startPrank(alice);
        usdc.approve(vault, 1e18);
        vm.expectRevert();
        IERC4626(vault).deposit(1e18, alice);
        vm.stopPrank();
    }

    /// @notice Spent upkeep is swept by governance into SuperBank (protocol revenue).
    function test_Fork_BSC_GovernanceClaimsSpentUpkeepToSuperBank() public {
        (, address strategy,) = _createVault();
        _installTestValidator();
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        _fundUpkeep(strategy, 2 * cost);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _submitPPS(strategy, 1.01e18);

        uint256 claimable = IAggregatorUpkeepView(AGGREGATOR).claimableUpkeep();
        assertGe(claimable, cost, "at least this update is claimable");
        uint256 bankBefore = up.balanceOf(SUPER_BANK);

        // Non-governor cannot pull
        vm.prank(alice);
        vm.expectRevert();
        governor.executeUpkeepClaim(claimable);
        vm.prank(alice);
        vm.expectRevert();
        aggregator.claimUpkeep(claimable);

        address gov = _governorRoleHolder();
        vm.prank(gov);
        vm.expectEmit(true, false, false, true, AGGREGATOR);
        emit ISuperVaultAggregator.UpkeepClaimed(SUPER_BANK, claimable);
        governor.executeUpkeepClaim(claimable);

        assertEq(up.balanceOf(SUPER_BANK), bankBefore + claimable, "UP landed in SuperBank");
        assertEq(IAggregatorUpkeepView(AGGREGATOR).claimableUpkeep(), 0, "claimable drained");
        assertEq(aggregator.getUpkeepBalance(strategy), cost, "strategy's remaining upkeep untouched");
        assertEq(up.balanceOf(AGGREGATOR), cost, "aggregator holds only the unspent remainder");
    }

    /// @notice Manager exit: propose -> 24h timelock -> execute returns the unspent UP to the
    ///         main manager (not the caller).
    function test_Fork_BSC_ManagerWithdrawsUnspentUpkeepAfterTimelock() public {
        (, address strategy,) = _createVault();
        _installTestValidator();
        uint256 cost = governor.getUpkeepCostPerSingleUpdate(ECDSA_PPS_ORACLE);
        _fundUpkeep(strategy, 5 * cost);

        vm.warp(block.timestamp + MIN_UPDATE_INTERVAL + 1);
        _submitPPS(strategy, 1.01e18);
        uint256 remaining = aggregator.getUpkeepBalance(strategy);
        assertEq(remaining, 4 * cost);

        vm.prank(alice);
        vm.expectRevert();
        aggregator.proposeWithdrawUpkeep(strategy);

        vm.prank(manager);
        aggregator.proposeWithdrawUpkeep(strategy);

        vm.prank(manager);
        vm.expectRevert();
        aggregator.executeWithdrawUpkeep(strategy); // timelock not elapsed

        vm.warp(block.timestamp + 24 hours + 1);
        vm.prank(alice); // permissionless once ready, funds still go to the main manager
        aggregator.executeWithdrawUpkeep(strategy);

        assertEq(up.balanceOf(manager), remaining, "manager refunded");
        assertEq(aggregator.getUpkeepBalance(strategy), 0, "balance cleared");
    }

    /*//////////////////////////////////////////////////////////////
                              HELPERS: UPKEEP
    //////////////////////////////////////////////////////////////*/

    function _seedDeposit(address vault, address who, uint256 amount) internal {
        deal(USDC_BSC, who, amount);
        vm.startPrank(who);
        usdc.approve(vault, amount);
        IERC4626(vault).deposit(amount, who);
        vm.stopPrank();
    }

    /// @dev Manager funds the strategy's upkeep in UP (UpOFT is a plain OZ ERC20 under the hood,
    ///      so `deal` works even though live supply on BSC is 0 until bridged).
    function _fundUpkeep(address strategy, uint256 amount) internal {
        deal(UP_OFT, manager, amount);
        vm.startPrank(manager);
        up.approve(AGGREGATOR, amount);
        aggregator.depositUpkeep(strategy, amount);
        vm.stopPrank();
    }

    /// @dev The live GOVERNOR_ROLE holder (deployer until the Safe handover, Safe afterwards).
    ///      SuperGovernor is plain AccessControl (no enumeration), so probe the known candidates.
    function _governorRoleHolder() internal view returns (address) {
        IAccessControl ac = IAccessControl(SUPER_GOVERNOR);
        if (ac.hasRole(GOVERNOR_ROLE, SUPERFORM_SAFE)) return SUPERFORM_SAFE;
        if (ac.hasRole(GOVERNOR_ROLE, DEPLOYER)) return DEPLOYER;
        revert("no known GOVERNOR_ROLE holder on this fork");
    }

    /// @dev Swap the production validator set for a key we control, via the real governor path.
    function _installTestValidator() internal {
        address[] memory validators = new address[](1);
        validators[0] = testValidator;
        bytes[] memory pubKeys = new bytes[](1);
        pubKeys[0] = "";
        vm.prank(_governorRoleHolder());
        governor.setValidatorConfig(1, validators, pubKeys, 1, "");
        assertTrue(governor.isValidator(testValidator), "test validator installed");
        assertEq(governor.getPPSOracleQuorum(), 1, "quorum 1");
    }

    function _signPPS(address strategy, uint256 pps, uint256 ts) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encodePacked(ppsOracle.UPDATE_PPS_TYPEHASH(), strategy, pps, ts, ppsOracle.noncePerStrategy(strategy))
        );
        bytes32 digest = MessageHashUtils.toTypedDataHash(ppsOracle.domainSeparator(), structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(TEST_VALIDATOR_KEY, digest);
        return abi.encodePacked(r, s, v);
    }

    function _submitPPS(address strategy, uint256 pps) internal {
        _submitSigned(strategy, pps, block.timestamp, _signPPS(strategy, pps, block.timestamp));
    }

    function _submitSigned(address strategy, uint256 pps, uint256 ts, bytes memory sig) internal {
        address[] memory strategies = new address[](1);
        strategies[0] = strategy;
        bytes[][] memory proofs = new bytes[][](1);
        proofs[0] = new bytes[](1);
        proofs[0][0] = sig;
        uint256[] memory ppss = new uint256[](1);
        ppss[0] = pps;
        uint256[] memory timestamps = new uint256[](1);
        timestamps[0] = ts;

        vm.prank(keeper);
        ppsOracle.updatePPS(
            IECDSAPPSOracle.UpdatePPSArgs({
                strategies: strategies, proofsArray: proofs, ppss: ppss, timestamps: timestamps
            })
        );
    }
}
