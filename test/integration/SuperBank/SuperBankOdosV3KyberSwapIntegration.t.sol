// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { ISuperHookInspector } from "@superform-v2-core/src/interfaces/ISuperHook.sol";
import { OdosAPIParser } from "@superform-v2-core/test/utils/parsers/OdosAPIParser.sol";
import { KyberSwapAPIParser } from "@superform-v2-core/test/utils/parsers/KyberSwapAPIParser.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";

/// @title SuperBankOdosV3KyberSwapIntegration
/// @notice Integration tests for ApproveAndSwapOdosV3Hook and ApproveAndSwapKyberSwapHook
/// @dev Validates production merkle roots from superman/deployments/superbank/generated/
///      Tests real swaps on Base and ETH forks using live Odos V3 quotes and KyberSwap calldata.
///
/// Run:
///   forge test --match-contract SuperBankOdosV3KyberSwapIntegration -vvv
contract SuperBankOdosV3KyberSwapIntegration is Test, OdosAPIParser, KyberSwapAPIParser {
    using Surl for *;
    using strings for *;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES
    // ═══════════════════════════════════════════════════════════════════

    // v2-periphery prod (shared across chains)
    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // ── Base (8453) hooks ──
    address constant BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK = 0x6Fa4B7a931c53Fd2944646311fe5a71CA2C9112A;
    address constant BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xdC9D10d9710DBf82924a3F7733293457Ad12D37D;

    // ── ETH (1) hooks ──
    address constant ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK = 0xFb11a0cf304103312475F2512d7B3EAE66747A68;
    address constant ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK = 0xdC9D10d9710DBf82924a3F7733293457Ad12D37D;

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

    // ── Production merkle roots (from superman/deployments/superbank/generated/) ──
    // Base ApproveAndSwapOdosV3Hook: 25 leaves (5 inputReceivers × 5 executors × zero_address)
    bytes32 constant BASE_ODOS_V3_ROOT = 0xd64155ff12bbcef440eff1d3832432971b6e59c5a1a5500e4c6a210e94a34870;
    // Base ApproveAndSwapKyberSwapHook: 4 leaves (USDC, UP_base, UP_eth, UP_hyper)
    bytes32 constant BASE_KYBERSWAP_ROOT = 0x310c92fb1baa09b328034cdcf0a4b27bc1bfc094364c19b081a199570f5a7af9;
    // ETH ApproveAndSwapOdosV3Hook: 16 leaves (4 inputReceivers × 4 executors × zero_address)
    bytes32 constant ETH_ODOS_V3_ROOT = 0x72b7f0bcd338b2b0d2b4b4dca406faa21955908efc3502ad77c0c98f8431d306;
    // ETH ApproveAndSwapKyberSwapHook: 4 leaves (USDC, UP_base, UP_eth, UP_hyper)
    bytes32 constant ETH_KYBERSWAP_ROOT = 0xd7c434feb5bbebce16bf93855700d935a2aed5499523aebf61c2b1e92e9b7ae1;

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
    /// @dev inspect() returns abi.encodePacked(inputReceiver, executor, feeRecipient)
    ///      Leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, encodedArgs))))
    ///      Diagonal entries: inputReceiver == executor (what Odos API returns)
    function test_inspectAndVerifyLeaf_approveAndSwapOdosV3_base() public pure {
        // Diagonal: inputReceiver == executor == 0xe615... (idx 21)
        {
            address exec = 0xe6151691FF20684426d5DC017c0a3C4E1e533dee;
            bytes memory encodedArgs = abi.encodePacked(exec, exec, address(0));
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xe6d95cd3fe282ac2f69bd0ec4003d24f6645695122be53d8321b9da3b9fd0938,
                "Leaf hash mismatch for Base OdosV3 diagonal=0xe615"
            );
        }
        // Diagonal: inputReceiver == executor == 0x19cE... (idx 13)
        {
            address exec = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;
            bytes memory encodedArgs = abi.encodePacked(exec, exec, address(0));
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0x99ca9378b620f65deff339194801e7fbc55ff0cbabfb9396031047b98250e648,
                "Leaf hash mismatch for Base OdosV3 diagonal=0x19cE"
            );
        }
    }

    /// @notice Verify computed leaf hashes match generated tree for ApproveAndSwapOdosV3Hook on ETH.
    function test_inspectAndVerifyLeaf_approveAndSwapOdosV3_eth() public pure {
        // Diagonal: inputReceiver == executor == 0x3650... (idx 15)
        {
            address exec = 0x365084B05Fa7d5028346bD21D842eD0601bAB5b8;
            bytes memory encodedArgs = abi.encodePacked(exec, exec, address(0));
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xf82cf38c3bf481a230171d0fbe4475da57322d2f261da1182cc294a3b118c429,
                "Leaf hash mismatch for ETH OdosV3 diagonal=0x3650"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //         KYBERSWAP: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes for ApproveAndSwapKyberSwapHook on Base.
    /// @dev inspect() returns abi.encodePacked(dstToken)
    function test_inspectAndVerifyLeaf_approveAndSwapKyberSwap_base() public pure {
        // Leaf 3: dst_token = Base USDC
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_USDC);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xe2829cd8085e6da02b81f538ffe41f6481dc2be708500fee93db44de5e7c7ecf,
                "Leaf hash mismatch for Base KyberSwap dst_token=USDC"
            );
        }
        // Leaf 2: dst_token = Base UP
        {
            bytes memory encodedArgs = abi.encodePacked(BASE_UP);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xd71a49a1d982f4b3cc3e0e6250edf019aefcfc29d803d798a1312f48e1afea58,
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
                bytes.concat(keccak256(abi.encode(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xa828cefb1642476f1eb906eae5e7bd95b4a3439472591bbd58eaa4eb85c29a98,
                "Leaf hash mismatch for ETH KyberSwap dst_token=USDC"
            );
        }
        // Leaf 2: dst_token = ETH UP
        {
            bytes memory encodedArgs = abi.encodePacked(ETH_UP);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, encodedArgs)))
            );
            assertEq(
                computedLeaf,
                0xba3474af728a283cdd3fa473f18b1e8f0e0839801de4c8edbd40e07ce568e5b5,
                "Leaf hash mismatch for ETH KyberSwap dst_token=UP"
            );
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //              ODOS V3: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle roots for ApproveAndSwapOdosV3Hook on Base and verify.
    function test_setProductionMerkleRoots_odosV3OnBase() public {
        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK),
            BASE_ODOS_V3_ROOT,
            "Base OdosV3 root mismatch"
        );
        console2.log("Base ApproveAndSwapOdosV3Hook production merkle root set successfully");
    }

    /// @notice Set production merkle roots for ApproveAndSwapOdosV3Hook on ETH and verify.
    function test_setProductionMerkleRoots_odosV3OnEth() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK, ETH_ODOS_V3_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK),
            ETH_ODOS_V3_ROOT,
            "ETH OdosV3 root mismatch"
        );
        console2.log("ETH ApproveAndSwapOdosV3Hook production merkle root set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              KYBERSWAP: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle roots for ApproveAndSwapKyberSwapHook on Base and verify.
    function test_setProductionMerkleRoots_kyberSwapOnBase() public {
        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            BASE_KYBERSWAP_ROOT,
            "Base KyberSwap root mismatch"
        );
        console2.log("Base ApproveAndSwapKyberSwapHook production merkle root set successfully");
    }

    /// @notice Set production merkle roots for ApproveAndSwapKyberSwapHook on ETH and verify.
    function test_setProductionMerkleRoots_kyberSwapOnEth() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, ETH_KYBERSWAP_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK),
            ETH_KYBERSWAP_ROOT,
            "ETH KyberSwap root mismatch"
        );
        console2.log("ETH ApproveAndSwapKyberSwapHook production merkle root set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //           ODOS V3: REAL SWAP ON BASE (USDC → UP)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap USDC→UP on Base via ApproveAndSwapOdosV3Hook with production merkle tree.
    /// @dev OdosV3 inspect() = abi.encodePacked(inputReceiver, executor, feeRecipient)
    ///      The hook handles approve internally (combined approve+swap).
    function test_executeHooks_swapUSDCtoUP_odosV3_onBase() public {
        _skipIfOdosUnavailable();
        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

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

        // Encode OdosV3 hook data (same layout as V2 but with extra referralFee + feeRecipient tail fields)
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
            decoded.referralCode,
            uint64(0), // referralFee = 0
            address(0) // feeRecipient = zero_address
        );

        // Execute with production proof
        uint256 upBefore = IERC20(BASE_UP).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK,
                hookData,
                _getBaseOdosV3Proof(decoded.tokenInfo.inputReceiver, decoded.executor)
            )
        );

        uint256 upAfter = IERC20(BASE_UP).balanceOf(SUPER_BANK);
        uint256 usdcAfter = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

        assertEq(usdcAfter, 0, "All USDC should be consumed by the swap");
        assertGt(upAfter - upBefore, 0, "SuperBank should have received UP tokens");

        console2.log("OdosV3 swap result: %d USDC -> %d UP", swapAmount, upAfter - upBefore);
    }

    /// @notice Swap WETH→USDC on Base via ApproveAndSwapOdosV3Hook with production merkle tree.
    function test_executeHooks_swapWETHtoUSDC_odosV3_onBase() public {
        _skipIfOdosUnavailable();
        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, BASE_ODOS_V3_ROOT);

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
            decoded.referralCode,
            uint64(0),
            address(0)
        );

        uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK,
                hookData,
                _getBaseOdosV3Proof(decoded.tokenInfo.inputReceiver, decoded.executor)
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

    /// @notice Swap WETH→USDC on ETH mainnet via ApproveAndSwapOdosV3Hook with production merkle tree.
    function test_executeHooks_swapWETHtoUSDC_odosV3_onEth() public {
        _skipIfOdosUnavailable();
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK);
        _setMerkleRoot(ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK, ETH_ODOS_V3_ROOT);

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
            decoded.referralCode,
            uint64(0),
            address(0)
        );

        uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

        superBank.executeHooks(
            _buildSingleHookExecutionData(
                ETH_APPROVE_AND_SWAP_ODOS_V3_HOOK,
                hookData,
                _getEthOdosV3Proof(decoded.tokenInfo.inputReceiver, decoded.executor)
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

    /// @notice Full integration: swap WETH→USDC on Base via ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    /// @dev KyberSwap inspect() extracts dstToken from the router calldata.
    ///      Merkle leaf validates dst_token = USDC is whitelisted.
    function test_executeHooks_swapWETHtoUSDC_kyberSwap_onBase() public {
        _skipIfKyberUnavailable("base", BASE_WETH, BASE_USDC);

        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.05 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(BASE_WETH, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(BASE_WETH, BASE_USDC, swapAmount, "base");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                BASE_WETH, BASE_USDC, swapAmount, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(BASE_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK,
                    hookData,
                    _getBaseKyberSwapProof(BASE_USDC)
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

    /// @notice Full integration: swap USDC→UP on Base via ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapUSDCtoUP_kyberSwap_onBase() public {
        _skipIfKyberUnavailable("base", BASE_USDC, BASE_UP);

        superGovernor.registerHook(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, BASE_KYBERSWAP_ROOT);

        uint256 swapAmount = 100e6; // 100 USDC

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(BASE_USDC, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(BASE_USDC, BASE_UP, swapAmount, "base");
            console2.log("KyberSwap attempt", attempt, "- Expected UP out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                BASE_USDC, BASE_UP, swapAmount, expectedOut / 2, false, txData
            );

            uint256 upBefore = IERC20(BASE_UP).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK,
                    hookData,
                    _getBaseKyberSwapProof(BASE_UP)
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

    /// @notice Full integration: swap WETH→USDC on ETH via ApproveAndSwapKyberSwapHook
    ///         with production merkle tree through superBank.executeHooks().
    function test_executeHooks_swapWETHtoUSDC_kyberSwap_onEth() public {
        _skipIfKyberUnavailable("ethereum", ETH_WETH, ETH_USDC);

        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"));
        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));

        superGovernor.registerHook(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK);
        _setMerkleRoot(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, ETH_KYBERSWAP_ROOT);

        uint256 swapAmount = 0.1 ether;

        for (uint256 attempt = 0; attempt < MAX_RETRIES; attempt++) {
            uint256 snap = vm.snapshotState();
            deal(ETH_WETH, SUPER_BANK, swapAmount);

            (bytes memory txData, uint256 expectedOut) =
                _getKyberSwapTxData(ETH_WETH, ETH_USDC, swapAmount, "ethereum");
            console2.log("KyberSwap attempt", attempt, "- Expected USDC out:", expectedOut);

            bytes memory hookData = _encodeKyberSwapHookData(
                ETH_WETH, ETH_USDC, swapAmount, expectedOut / 2, false, txData
            );

            uint256 usdcBefore = IERC20(ETH_USDC).balanceOf(SUPER_BANK);

            try superBank.executeHooks(
                _buildSingleHookExecutionData(
                    ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK,
                    hookData,
                    _getEthKyberSwapProof(ETH_USDC)
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
    //         KYBERSWAP: MERKLE PROOF VALIDATION (PURE)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify Base KyberSwap USDC leaf + proof reconstructs to the root.
    function test_kyberSwapMerkleProofValidation_base() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(BASE_USDC))))
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xd71a49a1d982f4b3cc3e0e6250edf019aefcfc29d803d798a1312f48e1afea58;
        proof[1] = 0xf5e64f89d6be6a69a54bc3aab8b73109368f737edefd5870cf39f608a5eb583b;

        assertEq(_verifyProof(leaf, proof), BASE_KYBERSWAP_ROOT, "Base KyberSwap USDC proof failed");
    }

    /// @notice Verify Base KyberSwap UP leaf + proof reconstructs to the root.
    function test_kyberSwapMerkleProofValidation_base_up() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(BASE_UP))))
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xe2829cd8085e6da02b81f538ffe41f6481dc2be708500fee93db44de5e7c7ecf;
        proof[1] = 0xf5e64f89d6be6a69a54bc3aab8b73109368f737edefd5870cf39f608a5eb583b;

        assertEq(_verifyProof(leaf, proof), BASE_KYBERSWAP_ROOT, "Base KyberSwap UP proof failed");
    }

    /// @notice Verify ETH KyberSwap USDC leaf + proof.
    function test_kyberSwapMerkleProofValidation_eth_usdc() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(ETH_USDC))))
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10;
        proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;

        assertEq(_verifyProof(leaf, proof), ETH_KYBERSWAP_ROOT, "ETH KyberSwap USDC proof failed");
    }

    /// @notice Verify ETH KyberSwap UP leaf + proof.
    function test_kyberSwapMerkleProofValidation_eth_up() public pure {
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(ETH_APPROVE_AND_SWAP_KYBERSWAP_HOOK, abi.encodePacked(ETH_UP))))
        );
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0xd71a49a1d982f4b3cc3e0e6250edf019aefcfc29d803d798a1312f48e1afea58;
        proof[1] = 0xc4056fd3b6d0257f5af34e2f819fbc8ee04ce8dde42925723a930e93a35238d7;

        assertEq(_verifyProof(leaf, proof), ETH_KYBERSWAP_ROOT, "ETH KyberSwap UP proof failed");
    }

    // ═══════════════════════════════════════════════════════════════════
    //           ODOS V3: MERKLE PROOF VALIDATION (ALL LEAVES)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify all 5 diagonal OdosV3 leaf proofs reconstruct to the Base root.
    /// @dev Diagonal entries = inputReceiver == executor (what Odos API returns in practice).
    function test_odosV3MerkleProofValidation_base_allDiagonalLeaves() public pure {
        address[5] memory executors = [
            address(0x19cEeAd7105607Cd444F5ad10dd51356436095a1),
            address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D),
            address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5),
            address(0xe6151691FF20684426d5DC017c0a3C4E1e533dee),
            address(0xbF44De8fc9EEEED8615b0b3bc095CB0ddef35e09)
        ];

        bytes32[5] memory leafHashes = [
            bytes32(0x99ca9378b620f65deff339194801e7fbc55ff0cbabfb9396031047b98250e648),
            bytes32(0xc9c9de0fa08d1294602ca6eda5603fd56aa89507d47686b15dd909c1279b27d9),
            bytes32(0xdd92f52d4d1930000309ed16774f9be04a6530fd2a3c690add611ea9c29e385e),
            bytes32(0xe6d95cd3fe282ac2f69bd0ec4003d24f6645695122be53d8321b9da3b9fd0938),
            bytes32(0xecd21380adfaaf0997abe8e970e1de9f6a61e0d874049732a95c4c05a54b79de)
        ];

        for (uint256 i = 0; i < executors.length; i++) {
            bytes memory encodedArgs = abi.encodePacked(executors[i], executors[i], address(0));
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(BASE_APPROVE_AND_SWAP_ODOS_V3_HOOK, encodedArgs)))
            );
            assertEq(computedLeaf, leafHashes[i], "Leaf hash mismatch for diagonal executor");

            // Verify proof via tree reconstruction
            bytes32[] memory proof = _getBaseOdosV3Proof(executors[i], executors[i]);
            assertEq(_verifyProof(computedLeaf, proof), BASE_ODOS_V3_ROOT, "Proof verification failed for diagonal executor");
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     PRODUCTION MERKLE PROOFS
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Base ApproveAndSwapOdosV3Hook proofs (25 leaves, keyed by inputReceiver + executor)
    ///      Source: hook_0x6fa4b7a931c53fd2944646311fe5a71ca2c9112a.json (chain 8453)
    ///      inspect() = abi.encodePacked(inputReceiver, executor, feeRecipient=0x0)
    ///      Only diagonal entries (inputReceiver == executor) are included since Odos API returns these.
    function _getBaseOdosV3Proof(address inputReceiver, address executor)
        internal
        pure
        returns (bytes32[] memory proof)
    {
        bytes32 key = keccak256(abi.encodePacked(inputReceiver, executor));

        // inputReceiver == executor == 0x19cEeAd (idx 13)
        if (key == keccak256(abi.encodePacked(address(0x19cEeAd7105607Cd444F5ad10dd51356436095a1), address(0x19cEeAd7105607Cd444F5ad10dd51356436095a1)))) {
            proof = new bytes32[](5);
            proof[0] = 0x7d4ed3806e83fefb3518b08e718ae467cd6145c5d3c9d7f653028d1f86902fa2;
            proof[1] = 0x95c8d95fa355ea80d9a3b4184726582f37fc91b3d7f18e255a617171c7447935;
            proof[2] = 0x713a43fbd4bfe6d888652f7997efe154258b816588f876cb7a62378ef55db890;
            proof[3] = 0xf6dda1f6f7dde6b4623fc55d06b8c6f97beecf519c07acdc22a875213c109414;
            proof[4] = 0x487a91a82e35c26e6cfb5f0edf1d094e5e9d30e78fb0bbbd2d9ca3daa1c2f67f;
        }
        // inputReceiver == executor == 0xd4F480 (idx 16)
        else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            proof = new bytes32[](5);
            proof[0] = 0xd882ed5663f07aaa94eb52f0db206940ec3ff6dbdb8fcdac4af779523bfdfa5c;
            proof[1] = 0x05f8f12ee834fe8974bf797d65780fd13796cb173a840b614bc5da418a9d4d1d;
            proof[2] = 0x026b860cacdde2b71f394a9a8addaca8618b2f9d1926d7e5bdee94d9070070ed;
            proof[3] = 0xfc913779d83c642d41f1caf272e504a21a629733f13268d94815e9acdc7b8e75;
            proof[4] = 0x216fd7b457244ca83fcdeb99a19e10d9e3a12efafa454ca62829d8a3b080c79a;
        }
        // inputReceiver == executor == 0x6131B5 (idx 19)
        else if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            proof = new bytes32[](5);
            proof[0] = 0xd9e473567d23533e4a69d864346a12c33197bf867f8b468b5e81b1c60da4f795;
            proof[1] = 0x26e587410d873466ac95f898a4c9896cec51fbccab427121595bca3e3794c3e0;
            proof[2] = 0x026b860cacdde2b71f394a9a8addaca8618b2f9d1926d7e5bdee94d9070070ed;
            proof[3] = 0xfc913779d83c642d41f1caf272e504a21a629733f13268d94815e9acdc7b8e75;
            proof[4] = 0x216fd7b457244ca83fcdeb99a19e10d9e3a12efafa454ca62829d8a3b080c79a;
        }
        // inputReceiver == executor == 0xe61516 (idx 21)
        else if (key == keccak256(abi.encodePacked(address(0xe6151691FF20684426d5DC017c0a3C4E1e533dee), address(0xe6151691FF20684426d5DC017c0a3C4E1e533dee)))) {
            proof = new bytes32[](5);
            proof[0] = 0xdfc1da52694791ebf55ca900b85f05dc15e07e9abe05a1b627f724e59aa634f0;
            proof[1] = 0xcea66cb7b9b12e156fb5d7a8e3cbf69650055248f7627f971d9fbd1e69801a9b;
            proof[2] = 0xe02bb838a1a4a004e9d122775cbeaca8f4535103c67eb87f7b1c3a02591a98fe;
            proof[3] = 0xfc913779d83c642d41f1caf272e504a21a629733f13268d94815e9acdc7b8e75;
            proof[4] = 0x216fd7b457244ca83fcdeb99a19e10d9e3a12efafa454ca62829d8a3b080c79a;
        }
        // inputReceiver == executor == 0xbF44De (idx 23)
        else if (key == keccak256(abi.encodePacked(address(0xbF44De8fc9EEEED8615b0b3bc095CB0ddef35e09), address(0xbF44De8fc9EEEED8615b0b3bc095CB0ddef35e09)))) {
            proof = new bytes32[](5);
            proof[0] = 0xe82df115ef38632dc63cd6e99e9864d67c38f37bda8094ef7b8802dce823139e;
            proof[1] = 0xb2f0a058d8c871e790b66a08bf80dc575a8978959fcba066a4e94cc5004bb030;
            proof[2] = 0xe02bb838a1a4a004e9d122775cbeaca8f4535103c67eb87f7b1c3a02591a98fe;
            proof[3] = 0xfc913779d83c642d41f1caf272e504a21a629733f13268d94815e9acdc7b8e75;
            proof[4] = 0x216fd7b457244ca83fcdeb99a19e10d9e3a12efafa454ca62829d8a3b080c79a;
        } else {
            revert("Unknown (inputReceiver, executor) combo - not in Base OdosV3 tree");
        }
    }

    /// @dev ETH ApproveAndSwapOdosV3Hook proofs (16 leaves, keyed by inputReceiver + executor)
    ///      Source: hook_0xfb11a0cf304103312475f2512d7b3eae66747a68.json (chain 1)
    ///      Only diagonal entries (inputReceiver == executor) are included.
    function _getEthOdosV3Proof(address inputReceiver, address executor)
        internal
        pure
        returns (bytes32[] memory proof)
    {
        bytes32 key = keccak256(abi.encodePacked(inputReceiver, executor));

        // inputReceiver == executor == 0x6131B5 (idx 2)
        if (key == keccak256(abi.encodePacked(address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5), address(0x6131B5fae19EA4f9D964eAc0408E4408b66337b5)))) {
            proof = new bytes32[](4);
            proof[0] = 0x5dfef15cdb41fda81d6c6647a6d7fff97d6326ee2ef69cd1516e24feeaea52df;
            proof[1] = 0xbb0c814759303220b4a142681fbda3040e139332d5e96d050a303ded3e386333;
            proof[2] = 0x76c000bb1d7c96d809a6b610dd158bae5bee928171fa992d87d24c3997261313;
            proof[3] = 0x0b30da4d75c5255a15298fbe63f0f64f17066fa2fa89f5e63cdf164ce9106668;
        }
        // inputReceiver == executor == 0xd4F480 (idx 10)
        else if (key == keccak256(abi.encodePacked(address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D), address(0xd4F480965D2347d421F1bEC7F545682E5Ec2151D)))) {
            proof = new bytes32[](4);
            proof[0] = 0xddd4d352c76330991ff53fd001727f871ab3dd94412d9e1859328842be9c7338;
            proof[1] = 0x82238d26f984b9be9a8600eb5cba1d38562456f8685d6f3d19308537707ef3d4;
            proof[2] = 0x687b6808f11f405821c7b27b7c48b2cc759382b2ac0c84b86d191ee52c1b4876;
            proof[3] = 0xe2bbe076fb94f87703900620398854e5fd0aa199c73e8d027b6eaa1e96e63ef6;
        }
        // inputReceiver == executor == 0xCf5540 (idx 11)
        else if (key == keccak256(abi.encodePacked(address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559)))) {
            proof = new bytes32[](4);
            proof[0] = 0xd011bd8fa563f62cedf7707bc0236765e61b8b06df39fb568b0a3d5da1926238;
            proof[1] = 0x82238d26f984b9be9a8600eb5cba1d38562456f8685d6f3d19308537707ef3d4;
            proof[2] = 0x687b6808f11f405821c7b27b7c48b2cc759382b2ac0c84b86d191ee52c1b4876;
            proof[3] = 0xe2bbe076fb94f87703900620398854e5fd0aa199c73e8d027b6eaa1e96e63ef6;
        }
        // inputReceiver == executor == 0x365084 (idx 15)
        else if (key == keccak256(abi.encodePacked(address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8), address(0x365084B05Fa7d5028346bD21D842eD0601bAB5b8)))) {
            proof = new bytes32[](4);
            proof[0] = 0xf36d5168771e2d697499e9a14bd3d1e244d2104df17fa2bb7a2b969e10199fef;
            proof[1] = 0xe3dedeb31901fbe8b4c8be9dafaafc140f1fdb50d7d08123cfe4a5abf72f3915;
            proof[2] = 0x74c95e8df7335fab03d4edc5f4f3f06ed0362de3fdaad379a94bdc1d5f423a9a;
            proof[3] = 0xe2bbe076fb94f87703900620398854e5fd0aa199c73e8d027b6eaa1e96e63ef6;
        } else {
            revert("Unknown (inputReceiver, executor) combo - not in ETH OdosV3 tree");
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
    ///      Source: hook_0xdc9d10d9710dbf82924a3f7733293457ad12d37d.json (chain 8453)
    function _getBaseKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913) {
            // USDC, idx 3
            proof = new bytes32[](2);
            proof[0] = 0xd71a49a1d982f4b3cc3e0e6250edf019aefcfc29d803d798a1312f48e1afea58;
            proof[1] = 0xf5e64f89d6be6a69a54bc3aab8b73109368f737edefd5870cf39f608a5eb583b;
        } else if (dstToken == 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B) {
            // UP (Base), idx 2
            proof = new bytes32[](2);
            proof[0] = 0xe2829cd8085e6da02b81f538ffe41f6481dc2be708500fee93db44de5e7c7ecf;
            proof[1] = 0xf5e64f89d6be6a69a54bc3aab8b73109368f737edefd5870cf39f608a5eb583b;
        } else {
            revert("Unknown dstToken - not in Base KyberSwap tree");
        }
    }

    /// @dev ETH ApproveAndSwapKyberSwapHook proofs (4 leaves)
    ///      Source: hook_0xdc9d10d9710dbf82924a3f7733293457ad12d37d.json (chain 1)
    function _getEthKyberSwapProof(address dstToken) internal pure returns (bytes32[] memory proof) {
        if (dstToken == 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) {
            // USDC, idx 1
            proof = new bytes32[](2);
            proof[0] = 0x0691d5cc4c6f90159bb4601b754daa4349df3499f31281ef46a3fa1183676a10;
            proof[1] = 0x525c770369ef74c0ca23581b12c97f61a4bc7dc1dca7cbb4c99a429d07354974;
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

    /// @dev ApproveAndSwapOdosV3Hook data layout (see ApproveAndSwapOdosV3Hook.sol):
    ///      [inputToken(20)][inputAmount(32)][inputReceiver(20)][outputToken(20)]
    ///      [outputQuote(32)][outputMin(32)][usePrevHookAmount(1)]
    ///      [pathDefinition_paramLength(32)][pathDefinition(var)]
    ///      [executor(20)][referralCode(8)][referralFee(8)][feeRecipient(20)]
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
        uint32 referralCode,
        uint64 referralFee,
        address feeRecipient
    )
        internal
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            inputToken,
            inputAmount,
            inputReceiver,
            outputToken,
            outputQuote,
            outputMin,
            usePrevHookAmount,
            pathDefinition.length,
            pathDefinition,
            executor,
            uint64(referralCode), // referralCode is uint64 in V3
            referralFee,
            feeRecipient
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
