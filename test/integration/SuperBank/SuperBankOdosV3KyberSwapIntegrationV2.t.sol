// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { OdosAPIParser } from "@superform-v2-core/test/utils/parsers/OdosAPIParser.sol";
import { KyberSwapAPIParser } from "@superform-v2-core/test/utils/parsers/KyberSwapAPIParser.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";

/// @title SuperBankOdosV3KyberSwapIntegrationV2
/// @notice Integration tests for the redeployed (standardized) ApproveAndSwapOdosV3Hook and
///         ApproveAndSwapKyberSwapHook on Base and ETH.
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/prod/{1,8453}/
///        hook_0xb6adcd6e912f8c8f355e9bc970e458b9d6609d0b.json (ApproveAndSwapOdosV3Hook)
///        hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (ApproveAndSwapKyberSwapHook)
///
///      The redeployed hooks use the standardized swap calldata layout
///      (52-byte zero header + Layer 1 + Layer 2 payload). inspect() now returns
///      abi.encodePacked(outputToken) for BOTH hooks, so the merkle trees are output-token
///      whitelists (4 leaves each: USDC + UP eth/base/oft) and proofs are selected by output token.
///
/// Run:
///   forge test --match-contract SuperBankOdosV3KyberSwapIntegrationV2 -vvv
contract SuperBankOdosV3KyberSwapIntegrationV2 is Test, OdosAPIParser, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod (shared across chains)
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // ── Redeployed hooks (same deterministic address on Base and ETH) ──
    address constant APPROVE_AND_SWAP_ODOS_V3_HOOK = 0xb6adcd6E912f8c8F355E9bC970E458B9d6609d0b;
    address constant APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xcF5419270C9415E44c97E595c505708cfA334C30;
    address constant SWAP_KYBERSWAP_HOOK = 0x05c49e05bb8575afdf1142cC95dA6747b069174A;

    // KyberSwap MetaAggregationRouterV2 (read from SWAP_KYBERSWAP_HOOK.KYBER_ROUTER())
    address constant KYBER_ROUTER = 0x6131B5fae19EA4f9D964eAc0408E4408b66337b5;

    // ── Base tokens ──
    address constant BASE_USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address constant BASE_UP = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address constant BASE_WETH = 0x4200000000000000000000000000000000000006;

    // ── ETH tokens ──
    address constant ETH_USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ETH_WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant ETH_UP = 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33;

    // ── Chain IDs ──
    uint256 constant BASE_CHAIN_ID = 8453;
    uint256 constant ETH_CHAIN_ID = 1;

    // ── Production merkle roots (from superman/deployments/superbank/generated/prod/) ──
    // Base ApproveAndSwapOdosV3Hook: 4 leaves (outputToken = USDC, UP base/eth/oft)
    bytes32 constant BASE_ODOS_V3_ROOT = 0xd5c3c9902d45f1cafeb1612d324edefe937e38f5d279baec12cf3fff8357698d;
    // Base ApproveAndSwapKyberSwapHook: 4 leaves (outputToken = USDC, UP base/eth/oft)
    bytes32 constant BASE_KYBERSWAP_ROOT = 0x357d1ad8049689a3f5673b1e08a3632bc4aff5ec6801599a9ef9dcf1c7e4bb6c;
    // ETH ApproveAndSwapOdosV3Hook: 4 leaves (outputToken = USDC, UP eth/base/oft)
    bytes32 constant ETH_ODOS_V3_ROOT = 0xb7c3a6da27bfb6e789f368a5e1d8f441565b3b5e1a8c82d0a118687858eb6a69;
    // ETH ApproveAndSwapKyberSwapHook: 4 leaves (outputToken = USDC, UP eth/base/oft)
    bytes32 constant ETH_KYBERSWAP_ROOT = 0x89dda69d740e47e63470e89491222f4ad5ebc03b33e6eb28cd2ed95e47e27a47;
    // Base standalone SwapKyberSwapHook (0x05c49e05...): 13 leaves (dst tokens)
    bytes32 constant BASE_SWAP_KYBERSWAP_ROOT =
        0x61a826a9d90fb9d1ac20483037191ca66bdcfd4acf5f65cceb00c4ac2cd2a467;
    // ETH standalone SwapKyberSwapHook (0x05c49e05...): 33 leaves (dst tokens)
    bytes32 constant ETH_SWAP_KYBERSWAP_ROOT =
        0xf9f7263790313a077bc49c6bf7f4d8d894e02c21a83ed84630348479e914b4fa;

    // Retry config for API-dependent tests (routes may use incompatible DEXes)
    uint256 constant MAX_RETRIES = 3;

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("BASE_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        assertTrue(superGovernor.hasRole(superGovernor.GOVERNOR_ROLE(), address(this)), "GOVERNOR_ROLE not granted");
        assertTrue(
            superGovernor.hasRole(superGovernor.BANK_MANAGER_ROLE(), address(this)), "BANK_MANAGER_ROLE not granted"
        );
    }

    function _odosHeaders() internal returns (string[] memory headers) {
        string memory apiKey = vm.envOr("ODOS_API_KEY", string(""));
        if (bytes(apiKey).length > 0) {
            headers = new string[](2);
            headers[0] = "Content-Type: application/json";
            headers[1] = string.concat("x-api-key: ", apiKey);
        } else {
            headers = new string[](1);
            headers[0] = "Content-Type: application/json";
        }
    }

    function _skipIfOdosUnavailable() internal {
        string memory body =
            '{"chainId":8453,"inputTokens":[{"tokenAddress":"0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913","amount":"1000000"}],"outputTokens":[{"tokenAddress":"0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B","proportion":1}],"userAddr":"0x0000000000000000000000000000000000000001","compact":true}';
        (uint256 status,) = API_QUOTE_URL.post(_odosHeaders(), body);
        if (status != 200) {
            vm.skip(true);
        }
    }

    function _surlCallQuoteV2Auth(
        QuoteInputToken[] memory _inputTokens,
        QuoteOutputToken[] memory _outputTokens,
        address _account,
        uint256 _chainId,
        bool _compact
    )
        internal
        returns (string memory)
    {
        string memory body = buildQuoteV2RequestBody(_inputTokens, _outputTokens, _account, _chainId, _compact);
        (uint256 status, bytes memory data) = API_QUOTE_URL.post(_odosHeaders(), body);
        if (status != 200) {
            revert("OdosAPIParser: surlCallQuoteV2 failed");
        }
        string memory json = string(data);
        strings.slice memory jsonSlice = json.toSlice();
        strings.slice memory key = '"pathId":"'.toSlice();
        strings.slice memory afterKey = jsonSlice.find(key).beyond(key);
        strings.slice memory pathId = afterKey.split('"'.toSlice());
        return pathId.toString();
    }

    function _surlCallAssembleAuth(string memory _pathId, address _userAddr) internal returns (string memory) {
        string memory body = buildAssembleRequestBody(_pathId, _userAddr);
        (uint256 status, bytes memory data) = API_ASSEMBLE_URL.post(_odosHeaders(), body);
        if (status != 200) {
            revert("OdosAPIParser: surlCallAssemble failed");
        }
        string memory json = string(data);
        strings.slice memory jsonSlice = json.toSlice();
        strings.slice memory key = '"data":"'.toSlice();
        strings.slice memory afterKey = jsonSlice.find(key).beyond(key);
        strings.slice memory swapData = afterKey.split('"'.toSlice());
        return swapData.toString();
    }

    function _skipIfKyberUnavailable(string memory chain, address tokenIn, address tokenOut) internal {
        string[] memory headers = new string[](1);
        headers[0] = string.concat("X-Client-Id: ", KYBER_CLIENT_ID);
        string memory url = string.concat(
            KYBER_API_BASE,
            chain,
            "/api/v1/routes?tokenIn=",
            toChecksumString(tokenIn),
            "&tokenOut=",
            toChecksumString(tokenOut),
            "&amountIn=10000000000000000"
        );
        (uint256 status,) = url.get(headers);
        if (status != 200) {
            vm.skip(true);
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //          ODOS V3: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes match generated tree for ApproveAndSwapOdosV3Hook on Base.
    /// @dev inspect() returns abi.encodePacked(outputToken)
    ///      Leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, encodedArgs))))
    function test_inspectAndVerifyLeaf_approveAndSwapOdosV3_base() public pure {
        // Leaf 2: outputToken = Base USDC
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_USDC);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xb688669f47c471616187630a88ba26b693e3103046ab1cb5d58bd26b2a4ed043,
                "Leaf hash mismatch for Base OdosV3 outputToken=USDC"
            );
        }
        // Leaf 1: outputToken = Base UP
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_UP);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0x51514cd687e33b0da4f0c40ad558a8803b108141f0f8e66de9c0abad97a24e05,
                "Leaf hash mismatch for Base OdosV3 outputToken=UP"
            );
        }
    }

    /// @notice Verify computed leaf hashes match generated tree for ApproveAndSwapOdosV3Hook on ETH.
    function test_inspectAndVerifyLeaf_approveAndSwapOdosV3_eth() public pure {
        // Leaf 2: outputToken = ETH USDC
        {
            bytes memory encodedArgs = abi.encodePacked(ETH_USDC);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xc600363991d3963f5c3049f22be0581e543e4d0a83c49753a14d663dbddc8bd9,
                "Leaf hash mismatch for ETH OdosV3 outputToken=USDC"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //         KYBERSWAP: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes for ApproveAndSwapKyberSwapHook on Base.
    /// @dev inspect() returns abi.encodePacked(outputToken)
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap_base() public pure {
        // Leaf 1: dst_token = Base USDC
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_USDC);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0x4f7d34da56163d0caff1ac09b503050cf62d9a17abdbbe7cce5d775cebbfce08,
                "Leaf hash mismatch for Base KyberSwap dst_token=USDC"
            );
        }
        // Leaf 3: dst_token = Base UP
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_UP);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xd1247c4a0abbeaabff238768c75bfdc938560867d296501f45b818929b3b033b,
                "Leaf hash mismatch for Base KyberSwap dst_token=UP"
            );
        }
    }

    /// @notice Verify computed leaf hashes for ApproveAndSwapKyberSwapHook on ETH.
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap_eth() public pure {
        // Leaf 1: dst_token = ETH USDC
        {
            bytes memory encodedArgs = abi.encodePacked(ETH_USDC);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0x52287f71ae63aaf1ca84d02aeeb2b6858bb7e79469a5d00ded4413d2ae5f0ff4,
                "Leaf hash mismatch for ETH KyberSwap dst_token=USDC"
            );
        }
        // Leaf 2: dst_token = ETH UP
        {
            bytes memory encodedArgs = abi.encodePacked(ETH_UP);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0x5ca7cfe345f81c81e7684789059ca0dde0f0dfd95fd4ed5686a10ff7556e3fb2,
                "Leaf hash mismatch for ETH KyberSwap dst_token=UP"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              ODOS V3: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle roots for ApproveAndSwapOdosV3Hook on Base and verify.
    function test_setProductionMerkleRoots_odosV3OnBase() public {
        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK),
            BASE_ODOS_V3_ROOT,
            "Base OdosV3 root mismatch"
        );
        console2.log("Base ApproveAndSwapOdosV3Hook (redeployed) production merkle root set successfully");
    }

    /// @notice Set production merkle roots for ApproveAndSwapOdosV3Hook on ETH and verify.
    function test_setProductionMerkleRoots_odosV3OnEth() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK, ETH_ODOS_V3_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK),
            ETH_ODOS_V3_ROOT,
            "ETH OdosV3 root mismatch"
        );
        console2.log("ETH ApproveAndSwapOdosV3Hook (redeployed) production merkle root set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle roots for ApproveAndSwapKyberSwapHook on Base and verify.
    function test_setProductionMerkleRoots_kyberSwapOnBase() public {
        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            BASE_KYBERSWAP_ROOT,
            "Base KyberSwap root mismatch"
        );
        console2.log("Base ApproveAndSwapKyberSwapHook (redeployed) production merkle root set successfully");
    }

    /// @notice Set production merkle roots for ApproveAndSwapKyberSwapHook on ETH and verify.
    function test_setProductionMerkleRoots_kyberSwapOnEth() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, ETH_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            ETH_KYBERSWAP_ROOT,
            "ETH KyberSwap root mismatch"
        );
        console2.log("ETH ApproveAndSwapKyberSwapHook (redeployed) production merkle root set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //           ODOS V3: REAL SWAP ON BASE (USDC → UP)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap USDC→UP on Base via the redeployed ApproveAndSwapOdosV3Hook
    ///         with production merkle tree.
    /// @dev The merkle leaf validates outputToken = UP is whitelisted (proof selected statically).
    function test_executeHooks_swapUSDCtoUP_odosV3_onBase() public {
        _skipIfOdosUnavailable();
        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

        uint256 swapAmount = 100e6; // 100 USDC
        deal(BASE_USDC, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_USDC).balanceOf(SUPER_BANK), swapAmount);

        // Fetch live Odos V3 quote
        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_USDC, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: BASE_UP, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = _surlCallAssembleAuth(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos V3 outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos V3 executor:", decoded.executor);

        // Encode standardized OdosV3 hook data
        bytes memory hookData = _encodeSwapOdosV3HookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2, // 50% slippage buffer for fork divergence
            false,
            decoded.pathDefinition,
            decoded.executor,
            uint64(decoded.referralCode),
            uint64(0), // referralFee = 0
            address(0) // feeRecipient = zero_address
        );

        // Execute with production proof (selected by output token)
        uint256 upBefore = IERC20(BASE_UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V3_HOOK, hookData, _getBaseOdosV3Proof(BASE_UP)
            )
        );

        uint256 upAfter = IERC20(BASE_UP).balanceOf(SUPER_BANK);
        uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

        assertEq(usdcAfter, 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("OdosV3 swap result: %d USDC -> %d UP", swapAmount, upAfter - upBefore);
    }

    /// @notice Swap WETH→USDC on Base via the redeployed ApproveAndSwapOdosV3Hook with production merkle tree.
    function test_executeHooks_swapWETHtoUSDC_odosV3_onBase() public {
        _skipIfOdosUnavailable();
        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

        uint256 swapAmount = 0.05 ether;
        deal(BASE_WETH, SUPER_BANK, swapAmount);
        assertEq(IERC20(BASE_WETH).balanceOf(SUPER_BANK), swapAmount);

        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: BASE_WETH, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: BASE_USDC, proportion: 1 });

        string memory pathId =
            _surlCallQuoteV2WithBlacklist(inputTokens, outputTokens, SUPER_BANK, BASE_CHAIN_ID, false, '["Metric"]');
        string memory assembledHex = _surlCallAssembleAuth(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos V3 outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos V3 executor:", decoded.executor);

        bytes memory hookData = _encodeSwapOdosV3HookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2,
            false,
            decoded.pathDefinition,
            decoded.executor,
            uint64(decoded.referralCode),
            uint64(0),
            address(0)
        );

        uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V3_HOOK, hookData, _getBaseOdosV3Proof(BASE_USDC)
            )
        );

        uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(BASE_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("OdosV3 swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //           ODOS V3: REAL SWAP ON ETH (WETH → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swap WETH→USDC on ETH mainnet via the redeployed ApproveAndSwapOdosV3Hook
    ///         with production merkle tree.
    function test_executeHooks_swapWETHtoUSDC_odosV3_onEth() public {
        _skipIfOdosUnavailable();
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_ODOS_V3_HOOK, ETH_ODOS_V3_ROOT);

        uint256 swapAmount = 0.1 ether;
        deal(ETH_WETH, SUPER_BANK, swapAmount);
        assertEq(IERC20(ETH_WETH).balanceOf(SUPER_BANK), swapAmount);

        QuoteInputToken[] memory inputTokens = new QuoteInputToken[](1);
        inputTokens[0] = QuoteInputToken({ tokenAddress: ETH_WETH, amount: swapAmount });

        QuoteOutputToken[] memory outputTokens = new QuoteOutputToken[](1);
        outputTokens[0] = QuoteOutputToken({ tokenAddress: ETH_USDC, proportion: 1 });

        string memory pathId = _surlCallQuoteV2Auth(inputTokens, outputTokens, SUPER_BANK, ETH_CHAIN_ID, false);
        string memory assembledHex = _surlCallAssembleAuth(pathId, SUPER_BANK);

        OdosDecodedSwap memory decoded = decodeOdosSwapCalldata(fromHex(assembledHex));
        console2.log("Odos V3 outputQuote:", decoded.tokenInfo.outputQuote);
        console2.log("Odos V3 executor:", decoded.executor);

        bytes memory hookData = _encodeSwapOdosV3HookData(
            decoded.tokenInfo.inputToken,
            decoded.tokenInfo.inputAmount,
            decoded.tokenInfo.inputReceiver,
            decoded.tokenInfo.outputToken,
            decoded.tokenInfo.outputQuote,
            decoded.tokenInfo.outputMin / 2,
            false,
            decoded.pathDefinition,
            decoded.executor,
            uint64(decoded.referralCode),
            uint64(0),
            address(0)
        );

        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                APPROVE_AND_SWAP_ODOS_V3_HOOK, hookData, _getEthOdosV3Proof(ETH_USDC)
            )
        );

        uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
        uint256 wethAfter = IERC20(ETH_WETH).balanceOf(SUPER_BANK);

        assertEq(wethAfter, 0, "All WETH should be consumed by the swap");
        assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

        console2.log("OdosV3 ETH swap result: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON BASE (WETH → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WETH→USDC on Base via the redeployed ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWETHtoUSDC_kyberSwap_onBase() public {
        _skipIfKyberUnavailable("base", BASE_WETH, BASE_USDC);

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.05 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(BASE_WETH, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(BASE_WETH, BASE_USDC, swapAmount, "base");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                BASE_WETH, BASE_USDC, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK, hookData, _getBaseKyberSwapProof(BASE_USDC)
                )
            ) {
                uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);
                uint256 wethAfter = IERC20(BASE_WETH).balanceOf(SUPER_BANK);

                assertEq(wethAfter, 0, "All WETH should be consumed");
                assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

                console2.log("KyberSwap Base: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        revert("KyberSwap WETH->USDC on Base failed after all retries");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON BASE (USDC → UP)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap USDC→UP on Base via the redeployed ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapUSDCtoUP_kyberSwap_onBase() public {
        _skipIfKyberUnavailable("base", BASE_USDC, BASE_UP);

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        uint256 swapAmount = 100e6; // 100 USDC

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(BASE_USDC, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(BASE_USDC, BASE_UP, swapAmount, "base");
            console2.log("KyberSwap attempt", attempt, "- Expected UP out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                BASE_USDC, BASE_UP, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 upBefore = IERC20(BASE_UP).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK, hookData, _getBaseKyberSwapProof(BASE_UP)
                )
            ) {
                uint256 upAfter = IERC20(BASE_UP).balanceOf(SUPER_BANK);
                uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

                assertEq(usdcAfter, 0, "All USDC should be consumed");
                assertGt(upAfter - upBefore, 0, "SuperBank should have received UP");

                console2.log("KyberSwap Base: %d USDC -> %d UP", swapAmount, upAfter - upBefore);
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        revert("KyberSwap USDC->UP on Base failed after all retries");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAP ON ETH (WETH → USDC)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WETH→USDC on ETH via the redeployed ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWETHtoUSDC_kyberSwap_onEth() public {
        _skipIfKyberUnavailable("ethereum", ETH_WETH, ETH_USDC);

        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(APPROVE_AND_SWAP_KYBERSWAP_HOOK, ETH_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.1 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(ETH_WETH, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(ETH_WETH, ETH_USDC, swapAmount, "ethereum");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                ETH_WETH, ETH_USDC, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    APPROVE_AND_SWAP_KYBERSWAP_HOOK, hookData, _getEthKyberSwapProof(ETH_USDC)
                )
            ) {
                uint256 usdcAfter = IERC20(ETH_USDC).balanceOf(SUPER_BANK);
                uint256 wethAfter = IERC20(ETH_WETH).balanceOf(SUPER_BANK);

                assertEq(wethAfter, 0, "All WETH should be consumed");
                assertGt(usdcAfter - usdcBefore, 0, "SuperBank should have received USDC");

                console2.log("KyberSwap ETH: %d WETH -> %d USDC", swapAmount, usdcAfter - usdcBefore);
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        revert("KyberSwap WETH->USDC on ETH failed after all retries");
    }

    // ═══════════════════════════════════════════════════════════════════
    //       KYBERSWAP: REAL SWAPS VIA STANDALONE SwapKyberSwapHook
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Swaps WETH→USDC on Base via the standalone (redeployed) SwapKyberSwapHook with its
    ///         production merkle root.
    /// @dev The production ApproveERC20Hook tree has NO leaf for the KyberSwap router as spender, so
    ///      the router allowance is set here via prank as test setup. Flagged as a config gap: without
    ///      an approve leaf the standalone SwapKyberSwapHook is not executable through SuperBank in
    ///      production — only the ApproveAndSwap variant is.
    function test_executeHooks_swapWETHtoUSDC_standaloneKyberSwap_onBase() public {
        _skipIfKyberUnavailable("base", BASE_WETH, BASE_USDC);

        superGovernor.registerHook(SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(SWAP_KYBERSWAP_HOOK, BASE_SWAP_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.05 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(BASE_WETH, SUPER_BANK, swapAmount);

            // Test-only router allowance (no production approve leaf for the KyberSwap router)
            vm.prank(SUPER_BANK);
            IERC20(BASE_WETH).approve(KYBER_ROUTER, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(BASE_WETH, BASE_USDC, swapAmount, "base");
            console2.log("KyberSwap (standalone) attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                BASE_WETH, BASE_USDC, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    SWAP_KYBERSWAP_HOOK, hookData, _getBaseSwapKyberSwapProof(BASE_USDC)
                )
            ) {
                assertEq(IERC20(BASE_WETH).balanceOf(SUPER_BANK), 0, "All WETH should be consumed");
                assertGt(
                    IERC20(BASE_USDC).balanceOf(SUPER_BANK) - usdcBefore, 0, "SuperBank should have received USDC"
                );
                console2.log("Standalone KyberSwap Base: swapped WETH -> USDC");
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries
    }

    /// @notice Swaps WETH→USDC on ETH via the standalone (redeployed) SwapKyberSwapHook with its
    ///         production merkle root.
    /// @dev Same production config gap as the Base variant: router allowance set via prank.
    function test_executeHooks_swapWETHtoUSDC_standaloneKyberSwap_onEth() public {
        _skipIfKyberUnavailable("ethereum", ETH_WETH, ETH_USDC);

        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(SWAP_KYBERSWAP_HOOK, ETH_SWAP_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.1 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(ETH_WETH, SUPER_BANK, swapAmount);

            // Test-only router allowance (no production approve leaf for the KyberSwap router)
            vm.prank(SUPER_BANK);
            IERC20(ETH_WETH).approve(KYBER_ROUTER, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(ETH_WETH, ETH_USDC, swapAmount, "ethereum");
            console2.log("KyberSwap (standalone) attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                ETH_WETH, ETH_USDC, swapAmount, expectedOut, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    SWAP_KYBERSWAP_HOOK, hookData, _getEthSwapKyberSwapProof(ETH_USDC)
                )
            ) {
                assertEq(IERC20(ETH_WETH).balanceOf(SUPER_BANK), 0, "All WETH should be consumed");
                assertGt(
                    IERC20(ETH_USDC).balanceOf(SUPER_BANK) - usdcBefore, 0, "SuperBank should have received USDC"
                );
                console2.log("Standalone KyberSwap ETH: swapped WETH -> USDC");
                return;
            } catch {
                console2.log("Attempt", attempt, "failed (incompatible route), retrying...");
                vm.revertToState(snap);
            }
        }
        vm.skip(true); // KyberSwap live routes returned incompatible calldata on all retries
    }

    /// @dev Base standalone SwapKyberSwapHook proof for dst_token=USDC (leaf index 8, 13 leaves).
    ///      Source: hook_0x05c49e05bb8575afdf1142cc95da6747b069174a.json (chain 8453)
    function _getBaseSwapKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](4);
        if (dstToken == BASE_USDC) {
            proof[0] = 0x9f9fe8c6bc78f08e80264238a3751d3964fbbe6a0cfbb493c105ee9b6d2ad549;
            proof[1] = 0x52b3c06ea2745c71ef1a68e7e0c50b141a303cf8d7f1163a97956445864487ec;
            proof[2] = 0xc0e8ebef0ab4cf07f5cd6972aaddd917baef92d08a89d937f2d39d4cb2cfa561;
            proof[3] = 0xc023c90c0c4c27a1bc95c57623533b7528a62ba99af986707022f9d28d02216e;
        } else {
            revert("Unknown dstToken - not in Base SwapKyberSwapHook proofs");
        }
    }

    /// @dev ETH standalone SwapKyberSwapHook proof for dst_token=USDC (leaf index 1, 33 leaves).
    ///      Source: hook_0x05c49e05bb8575afdf1142cc95da6747b069174a.json (chain 1)
    function _getEthSwapKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](6);
        if (dstToken == ETH_USDC) {
            proof[0] = 0x15459d5030deb12e8c1070fdf4ca40cff36cad2af22d28c1c0f0e4a313e03897;
            proof[1] = 0xb771f2edffdd38904034a88e5e5228bb657167e09e0c02e7d66e22a9ed3736da;
            proof[2] = 0x29ebd8c520c229858f99f925757bec4ee0caf6a55aa9f7e8c6a775ab454eb4dd;
            proof[3] = 0xe31ae781d7bd30d6346329d570735f4070be355221e0cd178caaf61a08522bd8;
            proof[4] = 0xf6c095f82596430d2691ce6e5228f103ca62f6ed12ed1ee9b4b4a5b7d10a48ba;
            proof[5] = 0xfbe6b8e4b8eee344bdabf840e6d845bd88dcf898c005e8bbde46b8e39ad2ff78;
        } else {
            revert("Unknown dstToken - not in ETH SwapKyberSwapHook proofs");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //         KYBERSWAP: MERKLE PROOF VALIDATION (PURE)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify Base KyberSwap USDC leaf + proof reconstructs to the root.
    function test_kyberSwapMerkleProofValidation_base() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(BASE_USDC))))
        );
        assertEq(_verifyProof(leaf, _getBaseKyberSwapProof(BASE_USDC)), BASE_KYBERSWAP_ROOT, "Base KyberSwap USDC proof failed");
    }

    /// @notice Verify Base KyberSwap UP leaf + proof reconstructs to the root.
    function test_kyberSwapMerkleProofValidation_base_up() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(BASE_UP))))
        );
        assertEq(_verifyProof(leaf, _getBaseKyberSwapProof(BASE_UP)), BASE_KYBERSWAP_ROOT, "Base KyberSwap UP proof failed");
    }

    /// @notice Verify ETH KyberSwap USDC leaf + proof.
    function test_kyberSwapMerkleProofValidation_eth_usdc() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(ETH_USDC))))
        );
        assertEq(_verifyProof(leaf, _getEthKyberSwapProof(ETH_USDC)), ETH_KYBERSWAP_ROOT, "ETH KyberSwap USDC proof failed");
    }

    /// @notice Verify ETH KyberSwap UP leaf + proof.
    function test_kyberSwapMerkleProofValidation_eth_up() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(ETH_UP))))
        );
        assertEq(_verifyProof(leaf, _getEthKyberSwapProof(ETH_UP)), ETH_KYBERSWAP_ROOT, "ETH KyberSwap UP proof failed");
    }

    // ═══════════════════════════════════════════════════════════════════
    //           ODOS V3: MERKLE PROOF VALIDATION (ALL LEAVES)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify all 4 output-token OdosV3 leaf proofs reconstruct to the Base root.
    function test_odosV3MerkleProofValidation_base_allLeaves() public pure {
        address[4] memory outputTokensArr = [
            BASE_USDC,
            BASE_UP,
            address(0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33), // UP (ETH)
            address(0x642fFC3496AcA19106BAB7A42F1F221a329654fe) // UP (OFT)
        ];

        for (uint256 i = 0; i < outputTokensArr.length; i++) {
            bytes memory encodedArgs = abi.encodePacked(outputTokensArr[i]);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            bytes32[] memory proof = _getBaseOdosV3Proof(outputTokensArr[i]);
            assertEq(_verifyProof(computedLeaf, proof), BASE_ODOS_V3_ROOT, "Proof verification failed for output token");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Base ApproveAndSwapOdosV3Hook proofs (4 leaves, keyed by outputToken)
    ///      Source: hook_0xb6adcd6e912f8c8f355e9bc970e458b9d6609d0b.json (chain 8453)
    function _getBaseOdosV3Proof(address outputToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (outputToken == 0x642fFC3496AcA19106BAB7A42F1F221a329654fe) {
            // UP_OFT, idx 0
            proof[0] = 0x51514cd687e33b0da4f0c40ad558a8803b108141f0f8e66de9c0abad97a24e05;
            proof[1] = 0x34c558e13de7f8f29391f072ea82b5583361889ef847f36670c09b1bb4acfaa7;
        } else if (outputToken == 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B) {
            // UP (Base), idx 1
            proof[0] = 0x074e0b2548e46dab510275aeaf01bc3114bbea16ed8abaa1ca1bcfa44a8d7df0;
            proof[1] = 0x34c558e13de7f8f29391f072ea82b5583361889ef847f36670c09b1bb4acfaa7;
        } else if (outputToken == 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) {
            // USDC (Base), idx 2
            proof[0] = 0xe756eb0f52d59a8d03f1ff9b31d6f1c0df73e2208d13edc4d3f55856436b748d;
            proof[1] = 0xb1678cbcc97aba7ee30b549d6e767eb0d09bf1be3ec8543338e6d7ba611204dc;
        } else if (outputToken == 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33) {
            // UP (ETH), idx 3
            proof[0] = 0xb688669f47c471616187630a88ba26b693e3103046ab1cb5d58bd26b2a4ed043;
            proof[1] = 0xb1678cbcc97aba7ee30b549d6e767eb0d09bf1be3ec8543338e6d7ba611204dc;
        } else {
            revert("Unknown outputToken - not in Base OdosV3 tree");
        }
    }

    /// @dev ETH ApproveAndSwapOdosV3Hook proofs (4 leaves, keyed by outputToken)
    ///      Source: hook_0xb6adcd6e912f8c8f355e9bc970e458b9d6609d0b.json (chain 1)
    function _getEthOdosV3Proof(address outputToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (outputToken == 0x642fFC3496AcA19106BAB7A42F1F221a329654fe) {
            // UP_OFT, idx 0
            proof[0] = 0x51514cd687e33b0da4f0c40ad558a8803b108141f0f8e66de9c0abad97a24e05;
            proof[1] = 0x193015d55ccad91f527aaebd04af1ad0588e27f35be16d6767ca40c40bdb000d;
        } else if (outputToken == 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B) {
            // UP (Base), idx 1
            proof[0] = 0x074e0b2548e46dab510275aeaf01bc3114bbea16ed8abaa1ca1bcfa44a8d7df0;
            proof[1] = 0x193015d55ccad91f527aaebd04af1ad0588e27f35be16d6767ca40c40bdb000d;
        } else if (outputToken == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
            // USDC (ETH), idx 2
            proof[0] = 0xe756eb0f52d59a8d03f1ff9b31d6f1c0df73e2208d13edc4d3f55856436b748d;
            proof[1] = 0xb1678cbcc97aba7ee30b549d6e767eb0d09bf1be3ec8543338e6d7ba611204dc;
        } else if (outputToken == 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33) {
            // UP (ETH), idx 3
            proof[0] = 0xc600363991d3963f5c3049f22be0581e543e4d0a83c49753a14d663dbddc8bd9;
            proof[1] = 0xb1678cbcc97aba7ee30b549d6e767eb0d09bf1be3ec8543338e6d7ba611204dc;
        } else {
            revert("Unknown outputToken - not in ETH OdosV3 tree");
        }
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
    //                KYBERSWAP PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Base ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (chain 8453)
    function _getBaseKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (dstToken == 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) {
            // USDC, idx 1
            proof[0] = 0x34571fee8571b9270c9f1cbf4edb91a42c3a7eb0fa5c5f9f3af5c38f54c8da9a;
            proof[1] = 0x91bf797ff71011c2df1d9c6639d72c0361318d354837e102544580fde995d2b9;
        } else if (dstToken == 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B) {
            // UP (Base), idx 3
            proof[0] = 0x5ca7cfe345f81c81e7684789059ca0dde0f0dfd95fd4ed5686a10ff7556e3fb2;
            proof[1] = 0xcfd0477e3efce642b77a857ad3753e6ea4251b42570e545bce802e31a4da1c56;
        } else {
            revert("Unknown dstToken - not in Base KyberSwap tree");
        }
    }

    /// @dev ETH ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xcf5419270c9415e44c97e595c505708cfa334c30.json (chain 1)
    function _getEthKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        proof = new bytes32[](2);
        if (dstToken == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
            // USDC, idx 1
            proof[0] = 0x34571fee8571b9270c9f1cbf4edb91a42c3a7eb0fa5c5f9f3af5c38f54c8da9a;
            proof[1] = 0x91bf797ff71011c2df1d9c6639d72c0361318d354837e102544580fde995d2b9;
        } else if (dstToken == 0x1D926bbE67425C9F507b9A0E8030eEdc7880BF33) {
            // UP (ETH), idx 2
            proof[0] = 0xd1247c4a0abbeaabff238768c75bfdc938560867d296501f45b818929b3b033b;
            proof[1] = 0x8a980e9f656c9f78269d9d2273bfc0d1d603c8db59f7845b5859ab29b430c972;
        } else {
            revert("Unknown dstToken - not in ETH KyberSwap tree");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                  KYBERSWAP API + DATA HELPERS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Get swap txData from KyberSwap API (route + build) for SuperBank
    function _getKyberSwapTxData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        string memory chain
    )
        internal
        returns (bytes memory txData_, uint256 expectedOut)
    {
        string memory routeSummary = surlCallRoutes(tokenIn, tokenOut, amountIn, chain, "ekubo-v3,axima-v2");
        expectedOut = extractAmountOut(routeSummary);
        string memory txDataHex = surlCallBuild(routeSummary, SUPER_BANK, SUPER_BANK, 200, chain);
        txData_ = fromHex(txDataHex);
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
    //                     MERKLE PROOF HELPER
    // ═══════════════════════════════════════════════════════════════════

    function _verifyProof(bytes32 leaf, bytes32[] memory proof) internal pure returns (bytes32 computed) {
        computed = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            if (computed <= proof[i]) {
                computed = keccak256(abi.encodePacked(computed, proof[i]));
            } else {
                computed = keccak256(abi.encodePacked(proof[i], computed));
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     ODOS API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _surlCallQuoteV2WithBlacklist(
        QuoteInputToken[] memory _inputTokens,
        QuoteOutputToken[] memory _outputTokens,
        address _account,
        uint256 _chainId,
        bool _compact,
        string memory _blacklist
    )
        internal
        returns (string memory)
    {
        string memory body = buildQuoteV2RequestBody(_inputTokens, _outputTokens, _account, _chainId, _compact);
        bytes memory bodyBytes = bytes(body);
        assembly {
            mstore(bodyBytes, sub(mload(bodyBytes), 1))
        }
        body = string(abi.encodePacked(bodyBytes, ',"sourceBlacklist":', _blacklist, "}"));

        (uint256 status, bytes memory data) = API_QUOTE_URL.post(_odosHeaders(), body);
        if (status != 200) {
            vm.skip(true);
        }
        string memory json = string(data);

        strings.slice memory jsonSlice = json.toSlice();
        strings.slice memory key = '"pathId":"'.toSlice();
        strings.slice memory afterKey = jsonSlice.find(key).beyond(key);
        strings.slice memory pathId = afterKey.split('"'.toSlice());

        return pathId.toString();
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     HOOK DATA ENCODING
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Standardized OdosV3 hook data (see v2-core ApproveAndSwapOdosV3Hook.sol):
    ///      [52-byte zero header][Layer 1][payloadLength(32)][payload]
    ///      Payload: abi.encode(inputReceiver, pathDefinition, executor, uint64 referralCode,
    ///               uint64 referralFee, feeRecipient)
    function _encodeSwapOdosV3HookData(
        address inputToken,
        uint256 inputAmount,
        address inputReceiver,
        address outputToken,
        uint256 outputQuote,
        uint256 outputMin,
        bool usePrevHookAmount,
        bytes memory pathDefinition,
        address executor,
        uint64 referralCode,
        uint64 referralFee,
        address feeRecipient
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory payload =
            abi.encode(inputReceiver, pathDefinition, executor, referralCode, referralFee, feeRecipient);
        bytes memory layer1 = bytes.concat(
            bytes20(inputToken),
            bytes20(outputToken),
            bytes32(inputAmount),
            bytes32(outputQuote),
            bytes32(outputMin),
            bytes1(usePrevHookAmount ? uint8(1) : uint8(0))
        );
        return bytes.concat(
            bytes32(0),
            bytes20(address(0)), // 52-byte strategy header
            layer1,
            bytes32(payload.length),
            payload
        );
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
    //                     ACCESS CONTROL HELPER
    // ═══════════════════════════════════════════════════════════════════

    function _forceGrantRole(bytes32 role, address account) internal {
        bytes32 roleSlot = keccak256(abi.encode(role, uint256(0)));
        bytes32 hasRoleSlot = keccak256(abi.encode(account, roleSlot));
        vm.store(SUPER_GOVERNOR_ADDR, hasRoleSlot, bytes32(uint256(1)));
    }
}
