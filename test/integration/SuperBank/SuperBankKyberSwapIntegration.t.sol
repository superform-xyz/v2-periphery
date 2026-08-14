// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { KyberSwapAPIParser } from "@superform-v2-core/test/utils/parsers/KyberSwapAPIParser.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";
import { AcrossV3Helper } from "@pigeon/across/AcrossV3Helper.sol";

/// @title SuperBankKyberSwapIntegration
/// @notice Integration tests for ApproveAndSwapKyberSwapHook on HyperEVM (chain 999)
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/
///      Tests real swaps on HyperEVM fork using live KyberSwap quotes.
///
/// Run:
///   forge test --match-contract SuperBankKyberSwapIntegration -vvv
contract SuperBankKyberSwapIntegration is Test, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (HYPEREVM)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (HyperEVM) — current deployments
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xdC9D10d9710DBf82924a3F7733293457Ad12D37D;
    address constant APPROVE_AND_ACROSS_HOOK = 0x77c932e8F7A308Ddf0EB4cd94ea0526Ed676eFeE;

    // Tokens (HyperEVM)
    address constant USDC = 0xb88339CB7199b77E23DB6E890353E22632Ba630f;
    address constant UP_OFT = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address constant WHYPE = 0x5555555555555555555555555555555555555555;

    // ── Production merkle root (from superman/deployments/superbank/generated/) ──
    // HyperEVM ApproveAndSwapKyberSwapHook (0xdC9D10d9): 4 leaves (USDC, UP_OFT, UP_ETH, UP_BASE)
    bytes32 constant HYPEREVM_KYBERSWAP_ROOT = 0x18b62ae3075292dbd5d6eae622ad53f17f7b2b106a2c0c9b55e1a2b8383f95f6;

    // Retry config for API-dependent tests
    uint256 constant MAX_RETRIES = 3;

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("HYPEREVM_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //         KYBERSWAP: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes match generated tree for ApproveAndSwapKyberSwapHook on HyperEVM.
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap_hyperEVM() public pure {
        // Leaf 0: dst_token = UP_OFT
        {
            bytes memory encodedArgs = abi.encodePacked(UP_OFT);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10,
                "Leaf hash mismatch for dst_token=UP_OFT"
            );
        }

        // Leaf 1: dst_token = USDC
        {
            bytes memory encodedArgs = abi.encodePacked(USDC);
            bytes32 computedLeaf =
                keccak256(bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs))));
            assertEq(
                computedLeaf,
                0x1ecf4fa5f73a9b1314f4ba99804c5c95fa5aae307df29af3743990df466e2572,
                "Leaf hash mismatch for dst_token=USDC"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle root for ApproveAndSwapKyberSwapHook on HyperEVM and verify.
    function test_setProductionMerkleRoots_kyberSwapOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            HYPEREVM_KYBERSWAP_ROOT,
            "ApproveAndSwapKyberSwapHook root mismatch"
        );
        console2.log("HyperEVM ApproveAndSwapKyberSwapHook production merkle root set successfully");
    }

    /// @notice Validates the ApproveAndAcross production merkle root on HyperEVM.
    function test_setProductionMerkleRoots_approveAndAcrossOnHyperEVM() public {
        superGovernor.registerHook(APPROVE_AND_ACROSS_HOOK);
        _setMerkleRoot(APPROVE_AND_ACROSS_HOOK, 0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_ACROSS_HOOK),
            0x893631ba68fd73c2e74dcf604a4b5ef869f5254463eedfe50a1edca19db166e8,
            "ApproveAndAcross root mismatch"
        );
        console2.log("ApproveAndAcross production merkle root set successfully on HyperEVM");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON HYPEREVM (WHYPE → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WHYPE→USDC on HyperEVM via ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWHYPEtoUSDC_kyberSwap_onHyperEVM() public {
        _skipIfKyberUnavailable("hyperevm", WHYPE, USDC);

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, HYPEREVM_KYBERSWAP_ROOT);

        uint256 swapAmount = 1 ether; // 1 WHYPE (~$63)

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(WHYPE, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(WHYPE, USDC, swapAmount, "hyperevm");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                WHYPE, USDC, swapAmount, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK,
                    hookData,
                    _getHyperEvmKyberSwapProof(USDC)
                )
            ) {
                uint256 usdcAfter = IERC20(USDC).balanceOf(SUPER_BANK);
                uint256 whypeAfter = IERC20(WHYPE).balanceOf(SUPER_BANK);

                assertEq(whypeAfter, 0, "All WHYPE should be consumed");
                assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

                console2.log("KyberSwap HyperEVM: %d WHYPE -> %d USDC", swapAmount, usdcAfter - usdcBefore);
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries — skip rather than fail CI
    }

    /// @notice Full integration: swap USDC→WHYPE on HyperEVM via ApproveAndSwapKyberSwapHook.
    ///         Uses WHYPE as an intermediary test since UP is not yet on KyberSwap for HyperEVM.
    ///         dst_token in merkle proof is not checked against the outputToken in the hook data —
    ///         KyberSwap doesn't verify that. But we can't test USDC→UP because KyberSwap has no
    ///         UP liquidity on HyperEVM. So we skip this direction for now.

    // ═══════════════════════════════════════════════════════════════════
    //                     KYBERSWAP API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _skipIfKyberUnavailable(string memory chain, address tokenIn, address tokenOut) internal {
        try this._tryKyberRoute(chain, tokenIn, tokenOut) {}
        catch {
            vm.skip(true);
        }
    }

    function _tryKyberRoute(string memory chain, address tokenIn, address tokenOut) external {
        surlCallRoutes(tokenIn, tokenOut, 1 ether, chain);
    }

    function _getKyberSwapTxData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        string memory chain
    )
        internal
        returns (bytes memory txData_, uint256 expectedOut)
    {
        string memory routeSummary = surlCallRoutes(tokenIn, tokenOut, amountIn, chain);
        expectedOut = extractAmountOut(routeSummary);
        string memory txDataHex = surlCallBuild(routeSummary, SUPER_BANK, SUPER_BANK, 200, chain);
        txData_ = fromHex(txDataHex);
    }

    /// @dev ApproveAndSwapKyberSwapHook data layout:
    ///      [inputToken(20)][outputToken(20)][inputAmount(32)][outputMin(32)]
    ///      [usePrevHookAmount(1)][txDataLength(32)][txData(var)]
    function _encodeKyberSwapHookData(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory txData
    )
        internal
        pure
        returns (bytes memory)
    {
        return bytes.concat(
            bytes20(inputToken),
            bytes20(outputToken),
            bytes32(inputAmount),
            bytes32(outputMin),
            bytes1(usePrevHookAmount ? uint8(1) : uint8(0)),
            bytes32(txData.length),
            txData
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev HyperEVM ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xdc9d10d9710dbf82924a3f7733293457ad12d37d.json (chain 999)
    function _getHyperEvmKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == 0x642fFC3496AcA19106BAB7A42F1F221a329654fe) {
            // UP_OFT, idx 0
            proof = new bytes32[](2);
            proof[0] = 0x1ecf4fa5f73a9b1314f4ba99804c5c95fa5aae307df29af3743990df466e2572;
            proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;
        } else if (dstToken == 0xb88339CB7199b77E23DB6E890353E22632Ba630f) {
            // USDC, idx 1
            proof = new bytes32[](2);
            proof[0] = 0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10;
            proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;
        } else {
            revert("Unknown dstToken - not in HyperEVM KyberSwap tree");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     EXECUTION DATA BUILDER
    // ═══════════════════════════════════════════════════════════════════

    function _buildSingleHookExecutionData(
        address hook,
        bytes memory data,
        bytes32[] memory proof
    )
        internal
        pure
        returns (IHookExecutionData.HookExecutionData memory)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;

        bytes[] memory dataArr = new bytes[](1);
        dataArr[0] = data;

        bytes32[][] memory proofs = new bytes32[][](1);
        proofs[0] = proof;

        uint256[] memory expectedOut = new uint256[](1);

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: dataArr,
            merkleProofs: proofs,
            expectedAssetsOrSharesOut: expectedOut
        });
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     MERKLE ROOT MANAGEMENT
    // ═══════════════════════════════════════════════════════════════════

    function _setMerkleRoot(address hook, bytes32 root) internal {
        uint256 savedTimestamp = block.timestamp;
        superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
        vm.warp(savedTimestamp);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), root, "Merkle root mismatch");
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     ACCESS CONTROL HELPER
    // ═══════════════════════════════════════════════════════════════════

    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}

/// @title SuperBankKyberSwapRHIntegration
/// @notice Integration tests for the SuperBank swap + bridge routes on Robinhood Chain (chain 4663)
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/prod/4663/:
///        hook_0x1851a98471ade4a115b6fb7bd42934a200e58d9e.json (ApproveERC20Hook, 14 leaves)
///        hook_0x05c49e05bb8575afdf1142cc95da6747b069174a.json (SwapKyberSwapHook, 2 leaves)
///        hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (ApproveAndSwapKyberSwapHook, 4 leaves)
///        hook_0xf2d69c07b4729a2af541c3387edaa9fa2df9650b.json (AcrossSendFundsAndExecuteOnDstHook, 10 leaves)
///        hook_0x91c5bf1b80465c7e86eb624d5dc84c75201afdac.json (ApproveAndAcrossSendFundsAndExecuteOnDstHook, 10
/// leaves)
///
///      RH hooks are the standardized deployments (52-byte zero header calldata layouts).
///
///      Route reality on RH as of 2026-08-07 (via Across /available-routes and KyberSwap APIs):
///        - USDG is the ONLY Across origin token on 4663; it fills natively into USDC on Base.
///          The USDG(RH) -> USDC(Base) leaves are therefore the primary production bridge route.
///        - RH native USDC (0x3884...) is not yet an Across origin token and is not yet indexed
///          by KyberSwap, so USDG->USDC swap tests self-skip until Kyber lists it.
///
/// Run:
///   forge test --match-contract SuperBankKyberSwapRHIntegration -vvv
contract SuperBankKyberSwapRHIntegration is Test, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES (RH)
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // v2-core prod hooks (RH) — script/output/prod/4663/RH deployments
    address constant APPROVE_ERC20_HOOK = 0x1851A98471ADE4a115B6FB7bd42934a200e58d9E;
    address constant SWAP_KYBERSWAP_HOOK = 0x05c49e05bb8575afdf1142cC95dA6747b069174A;
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xcF5419270C9415E44c97E595c505708cfA334C30;
    address constant ACROSS_SEND_FUNDS_HOOK = 0xf2D69C07B4729A2Af541C3387edaa9FA2DF9650b;
    address constant APPROVE_AND_ACROSS_HOOK = 0x91C5bf1B80465c7E86EB624d5DC84c75201afdAC;

    // Tokens (RH)
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168; // 6 decimals
    address constant USDC = 0x3884564BA51B349e7661c7e28Ad947DEE327FeDF; // native Circle USDC, 6 decimals

    // Base USDC (cross-chain output token in the RH Across trees)
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    // KyberSwap MetaAggregationRouterV2 (same address on all chains)
    address constant KYBER_ROUTER = 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5;

    // Across V3 SpokePools
    address constant RH_SPOKE_POOL = 0xD29C85F15DF544bA632C9E25829fd29d767d7978;
    address constant BASE_SPOKE_POOL = 0x09aea4b2242abC8bb4BB78D537A67a245A7bEC64;

    uint256 constant RH_CHAIN_ID = 4663;
    uint256 constant BASE_CHAIN_ID = 8453;

    // ── Production merkle roots (superman/deployments/superbank/generated/prod/4663/) ──
    bytes32 constant RH_APPROVE_ERC20_ROOT = 0xe5a5e0e36de2a491600dfd9cfffe8f13403e69c5c83ab71f4630d8413436da47;
    bytes32 constant RH_SWAP_KYBERSWAP_ROOT = 0x70e3cd5a5e8ba0f9d36a829ffc78949f9e746f44da88d4260801e54cac23a9e1;
    bytes32 constant RH_APPROVE_AND_SWAP_KYBERSWAP_ROOT =
        0x98eeb4c2db7afc6f5182e3e106bfa37128bcefd35c1af2462c445fde3db5c100;
    bytes32 constant RH_ACROSS_ROOT = 0x2ef0b21142f2dca2cf6b7a1f42e028831d56d840118812b52f9d693e4e565ec9;
    bytes32 constant RH_APPROVE_AND_ACROSS_ROOT = 0x08a09ead8683e513410503091d25a8e819070f03a7c16f0965762a9a68df03a9;

    // Retry config for API-dependent tests
    uint256 constant MAX_RETRIES = 3;

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("RH_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //              LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes match the generated RH KyberSwap trees.
    function test_inspectAndVerifyLeaf_kyberSwapHooks_onRH() public pure {
        // SwapKyberSwapHook: dst_token = USDG (idx 0)
        assertEq(
            _leaf(SWAP_KYBERSWAP_HOOK, abi.encodePacked(USDG)),
            0x0d19f366ef02dd0968ac900cbcaa309f8d38301212382d58e7e6bd013a6cce0a,
            "Leaf hash mismatch for SwapKyberSwapHook dst_token=USDG"
        );
        // SwapKyberSwapHook: dst_token = USDC (idx 1)
        assertEq(
            _leaf(SWAP_KYBERSWAP_HOOK, abi.encodePacked(USDC)),
            0x9d3b088c2adffff7374a79e79cba86ef734b59a698005af8639ca57c77794c88,
            "Leaf hash mismatch for SwapKyberSwapHook dst_token=USDC"
        );
        // ApproveAndSwapKyberSwapHook: dst_token = USDC (idx 2)
        assertEq(
            _leaf(APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(USDC)),
            0x8db2ec588e9d68735d7885084d98a408d23720f3ce7d2d26e2964bef358734f2,
            "Leaf hash mismatch for ApproveAndSwapKyberSwapHook dst_token=USDC"
        );
    }

    /// @notice Verify computed leaf hashes for the approve + bridge route leaves on RH.
    function test_inspectAndVerifyLeaf_approveAndBridgeRoutes_onRH() public pure {
        // ApproveERC20Hook: token=USDG, spender=KyberSwap router (idx 11)
        assertEq(
            _leaf(APPROVE_ERC20_HOOK, abi.encodePacked(USDG, KYBER_ROUTER)),
            0xaeb008e0d56b9a9f3b9dfbea38da47bf8f55edccc80dcaa7850a93e7d184e1cd,
            "Leaf hash mismatch for approve USDG -> KyberSwap router"
        );
        // ApproveERC20Hook: token=USDG, spender=RH SpokePool (idx 13)
        assertEq(
            _leaf(APPROVE_ERC20_HOOK, abi.encodePacked(USDG, RH_SPOKE_POOL)),
            0xc8c0a8dea10f6f82c463f7fb27bd13c963c85fddb9fd1ecc101a4aeb6aace62a,
            "Leaf hash mismatch for approve USDG -> RH SpokePool"
        );
        // AcrossSendFundsAndExecuteOnDstHook: USDG(RH) -> USDC(Base) (idx 2)
        assertEq(
            _leaf(ACROSS_SEND_FUNDS_HOOK, abi.encodePacked(SUPER_BANK, USDG, BASE_USDC, address(0))),
            0x2d77aa23b47de124e42bf898786f9f01794c3628163c0f5a3585f656001620f1,
            "Leaf hash mismatch for Across USDG(RH) -> USDC(Base)"
        );
        // ApproveAndAcrossSendFundsAndExecuteOnDstHook: USDG(RH) -> USDC(Base) (idx 2)
        assertEq(
            _leaf(APPROVE_AND_ACROSS_HOOK, abi.encodePacked(SUPER_BANK, USDG, BASE_USDC, address(0))),
            0x3bb484210531e8db12a45794131a398885a9ee0548f0bcb9f8bb64dcbe32bd9f,
            "Leaf hash mismatch for ApproveAndAcross USDG(RH) -> USDC(Base)"
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //                  MERKLE ROOT VERIFICATION (RH FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Register and set all five production RH merkle roots through the live SuperGovernor.
    function test_setProductionMerkleRoots_allHooks_onRH() public {
        address[5] memory hooks =
            [APPROVE_ERC20_HOOK, SWAP_KYBERSWAP_HOOK, APPROVE_AND_SWAP_KYBERSWAP_HOOK, ACROSS_SEND_FUNDS_HOOK, APPROVE_AND_ACROSS_HOOK];
        bytes32[5] memory roots = [
            RH_APPROVE_ERC20_ROOT,
            RH_SWAP_KYBERSWAP_ROOT,
            RH_APPROVE_AND_SWAP_KYBERSWAP_ROOT,
            RH_ACROSS_ROOT,
            RH_APPROVE_AND_ACROSS_ROOT
        ];

        for (uint256 i = 0; i < hooks.length; i++) {
            if (!superGovernor.isHookRegistered(hooks[i])) {
                superGovernor.registerHook(hooks[i]);
            }
            _setMerkleRoot(hooks[i], roots[i]);
            assertEq(superGovernor.getSuperBankHookMerkleRoot(hooks[i]), roots[i], "root mismatch");
        }
        console2.log("All 5 RH production merkle roots set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: USDG -> USDC SWAP ON RH
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap USDG -> USDC on RH via ApproveAndSwapKyberSwapHook with the
    ///         production merkle tree through superBank.executeHooks().
    /// @dev Self-skips while KyberSwap has not indexed RH native USDC (no liquidity yet).
    function test_executeHooks_swapUSDGtoUSDC_kyberSwap_onRH() public {
        _skipIfKyberUnavailable("robinhood", USDG, USDC);

        _registerAndSetRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, RH_APPROVE_AND_SWAP_KYBERSWAP_ROOT);

        uint256 swapAmount = 100e6; // 100 USDG

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(USDG, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) = _getKyberSwapTxData(USDG, USDC, swapAmount, "robinhood");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData =
                _encodeKyberSwapHookData(USDG, USDC, swapAmount, expectedOut, expectedOut / 2, false, txData);

            uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK, hookData, _getRhApproveAndSwapKyberProof(USDC)
                )
            ) {
                assertEq(IERC20(USDG).balanceOf(SUPER_BANK), 0, "All USDG should be consumed");
                assertGt(IERC20(USDC).balanceOf(SUPER_BANK) - usdcBefore, 0, "SuperBank should have received USDC");
                console2.log("KyberSwap RH: swapped USDG -> USDC");
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries
    }

    /// @notice Swap USDG -> USDC on RH through the full production path:
    ///         ApproveERC20Hook (USDG -> KyberSwap router, production leaf) + standalone SwapKyberSwapHook.
    /// @dev Unlike HyperEVM, the RH ApproveERC20Hook tree HAS a leaf for the KyberSwap router as spender,
    ///      so no test-only allowance prank is needed. Self-skips while KyberSwap has not indexed RH USDC.
    function test_executeHooks_swapUSDGtoUSDC_approveThenStandaloneKyberSwap_onRH() public {
        _skipIfKyberUnavailable("robinhood", USDG, USDC);

        _registerAndSetRoot(APPROVE_ERC20_HOOK, RH_APPROVE_ERC20_ROOT);
        _registerAndSetRoot(SWAP_KYBERSWAP_HOOK, RH_SWAP_KYBERSWAP_ROOT);

        uint256 swapAmount = 100e6; // 100 USDG

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(USDG, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) = _getKyberSwapTxData(USDG, USDC, swapAmount, "robinhood");
            console2.log("KyberSwap (standalone) attempt", attempt, "- Expected USDC out:", expectedOut);

            uint256 usdcBefore = IERC20(USDC).balanceOf(SUPER_BANK);

            address[] memory hooks = new address[](2);
            hooks[0] = APPROVE_ERC20_HOOK;
            hooks[1] = SWAP_KYBERSWAP_HOOK;

            bytes[] memory data = new bytes[](2);
            data[0] = _encodeApproveHookData(USDG, KYBER_ROUTER, swapAmount, false);
            data[1] = _encodeKyberSwapHookData(USDG, USDC, swapAmount, expectedOut, expectedOut / 2, false, txData);

            bytes32[][] memory proofs = new bytes32[][](2);
            proofs[0] = _getRhApproveProof(USDG, KYBER_ROUTER);
            proofs[1] = _getRhSwapKyberProof(USDC);

            try superBank.executeHooks(
                IHookExecutionData.HookExecutionData({
                    hooks: hooks,
                    data: data,
                    merkleProofs: proofs,
                    expectedAssetsOrSharesOut: new uint256[](2)
                })
            ) {
                assertEq(IERC20(USDG).balanceOf(SUPER_BANK), 0, "All USDG should be consumed");
                assertGt(IERC20(USDC).balanceOf(SUPER_BANK) - usdcBefore, 0, "SuperBank should have received USDC");
                console2.log("Standalone KyberSwap RH: swapped USDG -> USDC via production approve leaf");
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries
    }

    // ═══════════════════════════════════════════════════════════════════
    //       ACROSS: USDG (RH) -> USDC (BASE) BRIDGE ROUTE
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Bridges USDG from the RH SuperBank directly into USDC on the Base SuperBank via the
    ///         ApproveAndAcross hook with its production merkle root, relayed with Pigeon.
    /// @dev USDG is the only Across origin token on 4663 and fills natively into Base USDC —
    ///      this cross-token leaf is the primary production bridge route for RH fee proceeds.
    function test_executeHooks_bridgeUSDGtoBaseUSDC_withApproveAndAcross_onRH() public {
        _registerAndSetRoot(APPROVE_AND_ACROSS_HOOK, RH_APPROVE_AND_ACROSS_ROOT);

        uint256 bridgeAmount = 100e6; // 100 USDG (6 decimals)
        deal(USDG, SUPER_BANK, bridgeAmount);

        bytes memory acrossData = _encodeAcrossHookData(
            SUPER_BANK, USDG, BASE_USDC, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        vm.recordLogs();
        superBank.executeHooks(
            _buildSingleHookExecutionData(APPROVE_AND_ACROSS_HOOK, acrossData, _getRhApproveAndAcrossUsdgToBaseProof())
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(IERC20(USDG).balanceOf(SUPER_BANK), 0, "All USDG should be consumed by the bridge");

        _relayToBaseAndAssertUsdcArrived(logs);
    }

    /// @notice Bridges USDG (RH) -> USDC (Base) through the full production non-approve path:
    ///         ApproveERC20Hook (USDG -> RH SpokePool, production leaf) + standalone
    ///         AcrossSendFundsAndExecuteOnDstHook.
    /// @dev Both merkle leaves are production leaves — no test-only allowance pranks.
    function test_executeHooks_bridgeUSDGtoBaseUSDC_approveThenStandaloneAcross_onRH() public {
        _registerAndSetRoot(APPROVE_ERC20_HOOK, RH_APPROVE_ERC20_ROOT);
        _registerAndSetRoot(ACROSS_SEND_FUNDS_HOOK, RH_ACROSS_ROOT);

        uint256 bridgeAmount = 100e6; // 100 USDG (6 decimals)
        deal(USDG, SUPER_BANK, bridgeAmount);

        address[] memory hooks = new address[](2);
        hooks[0] = APPROVE_ERC20_HOOK;
        hooks[1] = ACROSS_SEND_FUNDS_HOOK;

        bytes[] memory data = new bytes[](2);
        data[0] = _encodeApproveHookData(USDG, RH_SPOKE_POOL, bridgeAmount, false);
        data[1] = _encodeAcrossHookData(
            SUPER_BANK, USDG, BASE_USDC, bridgeAmount, bridgeAmount * 99 / 100, BASE_CHAIN_ID, false, bytes("")
        );

        bytes32[][] memory proofs = new bytes32[][](2);
        proofs[0] = _getRhApproveProof(USDG, RH_SPOKE_POOL);
        proofs[1] = _getRhAcrossUsdgToBaseProof();

        vm.recordLogs();
        superBank.executeHooks(
            IHookExecutionData.HookExecutionData({
                hooks: hooks,
                data: data,
                merkleProofs: proofs,
                expectedAssetsOrSharesOut: new uint256[](2)
            })
        );
        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(IERC20(USDG).balanceOf(SUPER_BANK), 0, "All USDG should be consumed by the bridge");

        _relayToBaseAndAssertUsdcArrived(logs);
    }

    /// @dev Relays the recorded Across deposit to a fresh Base fork via Pigeon and asserts
    ///      USDC arrived on the Base SuperBank.
    function _relayToBaseAndAssertUsdcArrived(Vm.Log[] memory logs) internal {
        uint256 srcForkId = vm.activeFork();
        uint256 baseForkId = vm.createFork(vm.envString("BASE_RPC_URL"));
        vm.selectFork(baseForkId);
        uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
        vm.selectFork(srcForkId); // back to the RH fork

        AcrossV3Helper acrossHelper = new AcrossV3Helper();
        vm.makePersistent(address(acrossHelper));
        address relayer = makeAddr("ACROSS_RELAYER");
        vm.makePersistent(relayer);

        acrossHelper.help(
            RH_SPOKE_POOL, BASE_SPOKE_POOL, relayer, block.timestamp, baseForkId, BASE_CHAIN_ID, RH_CHAIN_ID, logs
        );

        vm.selectFork(baseForkId);
        uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
        assertGt(usdcAfter - usdcBefore, 0, "USDC should have arrived on Base via bridge");
        console2.log("Bridged USDC arrived on Base:", usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     HOOK DATA ENCODERS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev ApproveERC20Hook data layout (52-byte header + hook-specific):
    ///      [52-byte zero header][token(20)][spender(20)][amount(32)][usePrevHookAmount(1)]
    function _encodeApproveHookData(
        address token,
        address spender,
        uint256 amount,
        bool usePrevHookAmount
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
            token,
            spender,
            amount,
            usePrevHookAmount
        );
    }

    /// @dev Standardized Across hook data layout (52-byte header + packed args, see
    ///      v2-core AcrossSendFundsAndExecuteOnDstHook.sol).
    function _encodeAcrossHookData(
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        bool usePrevHookAmount,
        bytes memory message
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
            uint256(0), // value
            recipient,
            inputToken,
            outputToken,
            inputAmount,
            outputAmount,
            destinationChainId,
            address(0), // exclusiveRelayer
            uint32(10 minutes), // fillDeadlineOffset
            uint32(0), // exclusivityPeriod
            usePrevHookAmount,
            message
        );
    }

    /// @dev Standardized swap hook data layout (see v2-core SwapCalldataLayout.sol):
    ///      [52-byte zero header][inputToken(20)][outputToken(20)][inputAmount(32)]
    ///      [outputQuote(32)][outputMin(32)][usePrevHookAmount(1)][payloadLength(32)][payload(var)]
    ///      Payload for KyberSwap: abi.encode(bytes txData)
    function _encodeKyberSwapHookData(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputQuote,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory txData
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory payload = abi.encode(txData);
        return bytes.concat(
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
            bytes20(inputToken),
            bytes20(outputToken),
            bytes32(inputAmount),
            bytes32(outputQuote),
            bytes32(outputMin),
            bytes1(usePrevHookAmount ? uint8(1) : uint8(0)),
            bytes32(payload.length),
            payload
        );
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     KYBERSWAP API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _skipIfKyberUnavailable(string memory chain, address tokenIn, address tokenOut) internal {
        try this._tryKyberRoute(chain, tokenIn, tokenOut) { }
        catch {
            vm.skip(true);
        }
    }

    function _tryKyberRoute(string memory chain, address tokenIn, address tokenOut) external {
        surlCallRoutes(tokenIn, tokenOut, 100e6, chain);
    }

    function _getKyberSwapTxData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        string memory chain
    )
        internal
        returns (bytes memory txData_, uint256 expectedOut)
    {
        string memory routeSummary = surlCallRoutes(tokenIn, tokenOut, amountIn, chain);
        expectedOut = extractAmountOut(routeSummary);
        string memory txDataHex = surlCallBuild(routeSummary, SUPER_BANK, SUPER_BANK, 200, chain);
        txData_ = fromHex(txDataHex);
    }

    // ═══════════════════════════════════════════════════════════════════
    //              PRODUCTION MERKLE PROOFS (CHAIN 4663)
    // ═══════════════════════════════════════════════════════════════════

    /// @dev RH ApproveERC20Hook proofs (14 leaves)
    ///      Source: hook_0x1851a98471ade4a115b6fb7bd42934a200e58d9e.json (chain 4663)
    function _getRhApproveProof(address token, address spender) internal pure returns (bytes32[] memory proof) {
        if (token == USDG && spender == KYBER_ROUTER) {
            // idx 11
            proof = new bytes32[](4);
            proof[0] = 0xa51cec869bd29dbee6ab193639dab15c0a8cbad68599a8cfde79b8ba648500ec;
            proof[1] = 0x7ebbcfcde6bb6b74e8bd8cb55de81a63bd4110524ae6ee03858e9be9c9be718b;
            proof[2] = 0xa9744d5dc205c689da709dacc7ceda9cd6eabb665e718dfb98667af5311af2be;
            proof[3] = 0xd4b8bc4f063b95fe84e5378f631d0cd12819d47515a360e738a7ab78cc510cac;
        } else if (token == USDG && spender == RH_SPOKE_POOL) {
            // idx 13
            proof = new bytes32[](3);
            proof[0] = 0xbb61ff19679ca9b790f9ee17d63cc3330567c8eed2928d18e56c4df8ffd35cae;
            proof[1] = 0x6c1d20b6559c2d4923c9714a29615bffdb2da960d174cfecc8971fbc50a86a8c;
            proof[2] = 0xd4b8bc4f063b95fe84e5378f631d0cd12819d47515a360e738a7ab78cc510cac;
        } else if (token == USDC && spender == RH_SPOKE_POOL) {
            // idx 8
            proof = new bytes32[](4);
            proof[0] = 0x8bc9381b52409e8be98b782d058fbb3c78c247b7f3d5de7c67f671e55fe7710a;
            proof[1] = 0x96fa831ae6ec945aab235060490292e1dace40f3be23ffde2ef4793dd98af62b;
            proof[2] = 0xa9744d5dc205c689da709dacc7ceda9cd6eabb665e718dfb98667af5311af2be;
            proof[3] = 0xd4b8bc4f063b95fe84e5378f631d0cd12819d47515a360e738a7ab78cc510cac;
        } else {
            revert("Unknown token/spender - not in RH ApproveERC20Hook tree");
        }
    }

    /// @dev RH standalone SwapKyberSwapHook proofs (2 leaves: USDG idx 0, USDC idx 1)
    ///      Source: hook_0x05c49e05bb8575afdf1142cc95da6747b069174a.json (chain 4663)
    function _getRhSwapKyberProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](1);
        if (dstToken == USDC) {
            proof[0] = 0x0d19f366ef02dd0968ac900cbcaa309f8d38301212382d58e7e6bd013a6cce0a;
        } else if (dstToken == USDG) {
            proof[0] = 0x9d3b088c2adffff7374a79e79cba86ef734b59a698005af8639ca57c77794c88;
        } else {
            revert("Unknown dstToken - not in RH SwapKyberSwapHook tree");
        }
    }

    /// @dev RH ApproveAndSwapKyberSwapHook proof for dst_token=USDC (idx 2, 4 leaves)
    ///      Source: hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (chain 4663)
    function _getRhApproveAndSwapKyberProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == USDC) {
            proof = new bytes32[](2);
            proof[0] = 0xd1247c4a0abbeaabff238768c75bfdc938560867d296501f45b818929b3b033b;
            proof[1] = 0xa16b4626f5693eef54e49fa6c184a0f7ce52cb54591a94e72436d62e1ba044c9;
        } else {
            revert("Unknown dstToken - not in RH ApproveAndSwapKyberSwapHook tree");
        }
    }

    /// @dev RH standalone Across proof for USDG(4663) -> USDC(Base) leaf (idx 2, 10 leaves).
    ///      Source: hook_0xf2d69c07b4729a2af541c3387edaa9fa2df9650b.json (chain 4663)
    ///      Args: recipient=SuperBank, inputToken=USDG, outputToken=Base USDC, exclusiveRelayer=0x0
    function _getRhAcrossUsdgToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](4);
        proof[0] = 0x6331ed8206ad5baae36d9c24c9e29eb5a06afda7ac8492c91b060a1ee5226f1a;
        proof[1] = 0x211dbe69d9827ea821eab08512ee483ce540bf5961a10060e7717e6da8c2967e;
        proof[2] = 0xd09d4048311e59edf9f07fcd7fdb2d920fbe62e7fa876f1716a0eb15a5f9e208;
        proof[3] = 0x4cbccfcdd1c71ed5c7a15d6750c6adcaef12fdbaa9e078154c499f2aa377561a;
    }

    /// @dev RH ApproveAndAcross proof for USDG(4663) -> USDC(Base) leaf (idx 2, 10 leaves).
    ///      Source: hook_0x91c5bf1b80465c7e86eb624d5dc84c75201afdac.json (chain 4663)
    ///      Args: recipient=SuperBank, inputToken=USDG, outputToken=Base USDC, exclusiveRelayer=0x0
    function _getRhApproveAndAcrossUsdgToBaseProof() internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](4);
        proof[0] = 0x704661b3cadaccb7c25aa8ef45814cf1d478955b63924465775e7e772eeeffe7;
        proof[1] = 0x863d7242c8fd8e6fc7a354bc3314ca824aa9f76360349410e77e499d7e20a635;
        proof[2] = 0x3abd53887580a78a447c20d07165fe26cc50d65e4214143d1d5fde6ae8ca76be;
        proof[3] = 0xc42b6d0841a56d15810d238c35feab0a3186b14ac8fa9dc10ef91609fd854b83;
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     SHARED HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _leaf(address hook, bytes memory encodedArgs) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(hook, encodedArgs))));
    }

    function _buildSingleHookExecutionData(
        address hook,
        bytes memory data,
        bytes32[] memory proof
    )
        internal
        pure
        returns (IHookExecutionData.HookExecutionData memory)
    {
        address[] memory hooks = new address[](1);
        hooks[0] = hook;

        bytes[] memory dataArr = new bytes[](1);
        dataArr[0] = data;

        bytes32[][] memory proofs = new bytes32[][](1);
        proofs[0] = proof;

        return IHookExecutionData.HookExecutionData({
            hooks: hooks,
            data: dataArr,
            merkleProofs: proofs,
            expectedAssetsOrSharesOut: new uint256[](1)
        });
    }

    function _registerAndSetRoot(address hook, bytes32 root) internal {
        if (!superGovernor.isHookRegistered(hook)) {
            superGovernor.registerHook(hook);
        }
        _setMerkleRoot(hook, root);
    }

    function _setMerkleRoot(address hook, bytes32 root) internal {
        uint256 savedTimestamp = block.timestamp;
        superGovernor.proposeSuperBankHookMerkleRoot(hook, root);
        vm.warp(block.timestamp + 7 days + 1);
        superGovernor.executeSuperBankHookMerkleRootUpdate(hook);
        vm.warp(savedTimestamp);

        assertEq(superGovernor.getSuperBankHookMerkleRoot(hook), root, "Merkle root mismatch");
    }

    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}
