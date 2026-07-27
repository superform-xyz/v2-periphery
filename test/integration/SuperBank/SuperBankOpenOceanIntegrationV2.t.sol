// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Test, Vm } from "forge-std/Test.sol";
import { console2 } from "forge-std/console2.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import { Strings } from "openzeppelin-contracts/contracts/utils/Strings.sol";

import { SuperBank } from "../../../src/SuperBank.sol";
import { SuperGovernor } from "../../../src/SuperGovernor.sol";
import { IHookExecutionData } from "../../../src/interfaces/IHookExecutionData.sol";
import { Surl } from "@surl/Surl.sol";
import { strings } from "@stringutils/strings.sol";

/// @title SuperBankOpenOceanIntegrationV2
/// @notice Integration tests for the redeployed (standardized) ApproveAndSwapOpenOceanHook on Flare (chain 14)
/// @dev Validates production merkle root from superman/deployments/superbank/generated/prod/14/
///      hook_0x88832253c5bfbd07d37a02e6edfaa28f6e280227.json
///
///      The redeployed hook uses the standardized swap calldata layout
///      (52-byte zero header + Layer 1 + Layer 2 payload = abi.encode(txData)) and its
///      inspect() returns abi.encodePacked(outputToken) instead of dstReceiver, so the
///      merkle tree is an output-token whitelist: [WFLR, SPRK].
///
/// Run:
///   forge test --match-contract SuperBankOpenOceanIntegrationV2 -vvv
contract SuperBankOpenOceanIntegrationV2 is Test {
    using Surl for *;
    using strings for *;
    using Strings for uint256;
    using Strings for address;

    // ═══════════════════════════════════════════════════════════════════
    //                    PRODUCTION ADDRESSES
    // ═══════════════════════════════════════════════════════════════════

    address constant SUPER_BANK = 0x6fCc6a6A825FC14e6e56Fd14978FC6B97ACB5d15;
    address constant SUPER_GOVERNOR_ADDR = 0xB5396ef2bF8CA360cEB4166b77AFb2bed20e74d4;

    // ── Flare (14) hooks — redeployed (v2-core script/output/prod/14/Flare-latest.json) ──
    address constant FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK = 0x88832253c5BFBD07d37A02E6EDFaa28F6e280227;

    // ── Flare tokens ──
    address constant WFLR = 0x1D80c49BbBCd1C0911346656B529DF9E5c2F783d;
    address constant SPRK = 0x657097cC15fdEc9e383dB8628B57eA4a763F2ba0;

    // ── OpenOcean referrer (immutable in the deployed hook) ──
    address constant OPENOCEAN_REFERRER = 0x0E24b0F342F034446Ec814281AD1a7653cBd85e9;

    // ── Production merkle root (from superman/deployments/superbank/generated/prod/14/) ──
    // Flare ApproveAndSwapOpenOceanHook: 2 leaves (outputToken = WFLR, SPRK)
    bytes32 constant FLARE_OPENOCEAN_ROOT = 0x5acc43860cfc8545ae8e8acaee108f5330385af7fec2dae444827016848bfc5a;

    // Leaf hashes (leaves sorted ascending by hash: WFLR = idx 0, SPRK = idx 1)
    bytes32 constant WFLR_LEAF = 0xaaad9588c108079188c7ef88cf8381c980f86ac4af656ba9b5f164293ad1e999;
    bytes32 constant SPRK_LEAF = 0xbaca9b94fd69fd2b6a1ad29b69556c7873d3e9a1b4fe12f21b47d0b671cf1c51;

    // OpenOcean API
    string constant OPENOCEAN_SWAP_URL = "https://open-api-pro.openocean.finance/v4/14/swap";

    // Contracts
    SuperBank superBank;
    SuperGovernor superGovernor;

    // ═══════════════════════════════════════════════════════════════════
    //                              SETUP
    // ═══════════════════════════════════════════════════════════════════

    function setUp() public {
        vm.createSelectFork(vm.envString("FLARE_RPC_URL"));

        superBank = SuperBank(payable(SUPER_BANK));
        superGovernor = SuperGovernor(SUPER_GOVERNOR_ADDR);

        _forceGrantRole(superGovernor.GOVERNOR_ROLE(), address(this));
        _forceGrantRole(superGovernor.BANK_MANAGER_ROLE(), address(this));
    }

    // ═══════════════════════════════════════════════════════════════════
    //        OPENOCEAN: LEAF HASH VERIFICATION (PURE — NO FORK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Verify computed leaf hashes match the generated tree for ApproveAndSwapOpenOceanHook on Flare.
    /// @dev inspect() returns abi.encodePacked(outputToken)
    ///      Leaf = keccak256(bytes.concat(keccak256(abi.encode(hook, encodedArgs))))
    function test_inspectAndVerifyLeaf_approveAndSwapOpenOcean_flare() public pure {
        // Leaf 0: outputToken = WFLR
        {
            bytes memory encodedArgs = abi.encodePacked(WFLR);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK, encodedArgs)))
            );
            assertEq(computedLeaf, WFLR_LEAF, "Leaf hash mismatch for Flare OpenOcean outputToken=WFLR");
        }
        // Leaf 1: outputToken = SPRK
        {
            bytes memory encodedArgs = abi.encodePacked(SPRK);
            bytes32 computedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK, encodedArgs)))
            );
            assertEq(computedLeaf, SPRK_LEAF, "Leaf hash mismatch for Flare OpenOcean outputToken=SPRK");
        }
        // 2-leaf tree: root = keccak(sorted pair)
        bytes32 computedRoot = keccak256(abi.encodePacked(WFLR_LEAF, SPRK_LEAF));
        assertEq(computedRoot, FLARE_OPENOCEAN_ROOT, "Root mismatch for Flare OpenOcean tree");
    }

    // ═══════════════════════════════════════════════════════════════════
    //              OPENOCEAN: MERKLE ROOT VERIFICATION
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Set production merkle root for the redeployed ApproveAndSwapOpenOceanHook on Flare and verify.
    function test_setProductionMerkleRoots_openOceanOnFlare() public {
        superGovernor.registerHook(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK);
        _setMerkleRoot(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK, FLARE_OPENOCEAN_ROOT);

        assertEq(
            superGovernor.getSuperBankHookMerkleRoot(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK),
            FLARE_OPENOCEAN_ROOT,
            "Flare OpenOcean root mismatch"
        );
        console2.log("Flare ApproveAndSwapOpenOceanHook (redeployed) production merkle root set successfully");
    }

    // ═══════════════════════════════════════════════════════════════════
    //           OPENOCEAN: REAL SWAP ON FLARE (WFLR → SPRK)
    // ═══════════════════════════════════════════════════════════════════

    /// @notice Full integration: swap WFLR→SPRK on Flare via the redeployed ApproveAndSwapOpenOceanHook
    ///         with production merkle tree.
    function test_executeHooks_swapWFLRtoSPRK_openOcean_onFlare() public {
        _skipIfOpenOceanUnavailable();
        superGovernor.registerHook(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK);
        _setMerkleRoot(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK, FLARE_OPENOCEAN_ROOT);

        uint256 swapAmount = 100 ether; // 100 WFLR
        // WFLR on Flare has historical balance tracking; deal() breaks its internal accounting.
        // Instead, give SuperBank native FLR and deposit into WFLR.
        vm.deal(SUPER_BANK, swapAmount);
        vm.prank(SUPER_BANK);
        (bool ok,) = WFLR.call{ value: swapAmount }("");
        require(ok, "WFLR deposit failed");
        assertEq(IERC20(WFLR).balanceOf(SUPER_BANK), swapAmount);

        // Fetch live OpenOcean quote
        (bytes memory txData, uint256 minOutAmount) = _getOpenOceanSwapData(WFLR, SPRK, swapAmount, SUPER_BANK);

        // Encode hook data (standardized layout, payload = abi.encode(txData))
        bytes memory hookData = _encodeOpenOceanHookData(
            WFLR, SPRK, swapAmount, minOutAmount, minOutAmount / 2, false, txData
        );

        // Execute with the SPRK output-token production proof (sibling = WFLR leaf)
        uint256 sprkBefore = IERC20(SPRK).balanceOf(SUPER_BANK);
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = WFLR_LEAF;

        superBank.executeHooks(
            _buildSingleHookExecutionData(FLARE_APPROVE_AND_SWAP_OPENOCEAN_HOOK, hookData, proof)
        );

        uint256 sprkAfter = IERC20(SPRK).balanceOf(SUPER_BANK);
        uint256 wflrAfter = IERC20(WFLR).balanceOf(SUPER_BANK);

        assertEq(wflrAfter, 0, "All WFLR should be consumed by the swap");
        assertGt(sprkAfter - sprkBefore, 0, "SuperBank should have received SPRK tokens");

        console2.log("OpenOcean swap result: %d WFLR -> %d SPRK", swapAmount, sprkAfter - sprkBefore);
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     OPENOCEAN API HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _skipIfOpenOceanUnavailable() internal {
        string memory url = string.concat(
            OPENOCEAN_SWAP_URL,
            "?chain=14",
            "&inTokenAddress=", _toChecksumString(WFLR),
            "&outTokenAddress=", _toChecksumString(SPRK),
            "&amount=1",
            "&gasPrice=100.00",
            "&slippage=1",
            "&account=", _toChecksumString(SUPER_BANK),
            "&referrer=", _toChecksumString(OPENOCEAN_REFERRER),
            "&enabledDexIds=6"
        );
        (uint256 status,) = url.get();
        if (status != 200) {
            vm.skip(true);
        }
    }

    function _getOpenOceanSwapData(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address account
    )
        internal
        returns (bytes memory txData_, uint256 minOutAmount_)
    {
        string memory url = string.concat(
            OPENOCEAN_SWAP_URL,
            "?chain=14",
            "&inTokenAddress=", _toChecksumString(tokenIn),
            "&outTokenAddress=", _toChecksumString(tokenOut),
            "&amount=", _uintToDecimalString(amountIn, 18),
            "&gasPrice=100.00",
            "&slippage=1",
            "&account=", _toChecksumString(account),
            "&referrer=", _toChecksumString(OPENOCEAN_REFERRER),
            "&enabledDexIds=6"
        );

        (uint256 status, bytes memory data) = url.get();
        require(status == 200, "OpenOcean API call failed");

        string memory json = string(data);
        txData_ = _fromHex(_extractQuotedString(json, '"data":"'));
        minOutAmount_ = _stringToUint(_extractQuotedString(json, '"minOutAmount":"'));
    }

    // ═══════════════════════════════════════════════════════════════════
    //                     HOOK DATA ENCODING
    // ═══════════════════════════════════════════════════════════════════

    /// @dev Standardized swap hook data layout (see v2-core SwapCalldataLayout.sol):
    ///      [52-byte zero header][inputToken(20)][outputToken(20)][inputAmount(32)]
    ///      [outputQuote(32)][outputMin(32)][usePrevHookAmount(1)][payloadLength(32)][payload(var)]
    ///      Payload for OpenOcean: abi.encode(bytes txData)
    function _encodeOpenOceanHookData(
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

    // ═══════════════════════════════════════════════════════════════════
    //                     STRING / PARSING HELPERS
    // ═══════════════════════════════════════════════════════════════════

    function _toChecksumString(address addr) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(addr)), 20);
    }

    function _extractQuotedString(string memory json, string memory key) internal pure returns (string memory) {
        strings.slice memory jsonSlice = json.toSlice();
        strings.slice memory keySlice = key.toSlice();
        strings.slice memory afterKey = jsonSlice.find(keySlice).beyond(keySlice);
        strings.slice memory value = afterKey.split('"'.toSlice());
        return value.toString();
    }

    function _stringToUint(string memory s) internal pure returns (uint256 result) {
        bytes memory b = bytes(s);
        for (uint256 i; i < b.length; ++i) {
            require(uint8(b[i]) >= 48 && uint8(b[i]) <= 57, "not a digit");
            result = result * 10 + (uint8(b[i]) - 48);
        }
    }

    function _fromHex(string memory s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(s);
        require(ss.length >= 2 && ss[0] == "0" && (ss[1] == "x" || ss[1] == "X"), "must start with 0x");
        bytes memory r = new bytes((ss.length - 2) / 2);
        for (uint256 i = 0; i < r.length; ++i) {
            r[i] = bytes1(_fromHexChar(uint8(ss[2 * i + 2])) * 16 + _fromHexChar(uint8(ss[2 * i + 3])));
        }
        return r;
    }

    function _fromHexChar(uint8 c) private pure returns (uint8) {
        if (c >= 48 && c <= 57) return c - 48;
        if (c >= 97 && c <= 102) return 10 + c - 97;
        if (c >= 65 && c <= 70) return 10 + c - 65;
        revert("invalid hex char");
    }

    /// @dev Convert wei amount to decimal string (e.g. 100e18 -> "100")
    function _uintToDecimalString(uint256 value, uint8 decimals) internal pure returns (string memory) {
        uint256 divisor = 10 ** decimals;
        uint256 whole = value / divisor;
        uint256 fraction = value % divisor;
        if (fraction == 0) return whole.toString();
        // Build fraction string with leading zeros
        string memory fractionStr = fraction.toString();
        bytes memory padded = new bytes(decimals);
        bytes memory fracBytes = bytes(fractionStr);
        uint256 leadingZeros = decimals - fracBytes.length;
        for (uint256 i; i < decimals; ++i) {
            padded[i] = i < leadingZeros ? bytes1("0") : fracBytes[i - leadingZeros];
        }
        // Trim trailing zeros
        uint256 lastNonZero = decimals;
        for (uint256 i = decimals; i > 0; --i) {
            if (padded[i - 1] != "0") {
                lastNonZero = i;
                break;
            }
        }
        bytes memory trimmed = new bytes(lastNonZero);
        for (uint256 i; i < lastNonZero; ++i) {
            trimmed[i] = padded[i];
        }
        return string.concat(whole.toString(), ".", string(trimmed));
    }
}
