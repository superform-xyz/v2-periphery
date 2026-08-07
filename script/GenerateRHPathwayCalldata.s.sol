// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";
import { ExecutorConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/SendLibBase.sol";
import { OptionsBuilder } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OptionsBuilder.sol";
import { EnforcedOptionParam } from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";

/// @notice Generate multisig calldata for configuring ETH, Base, Flare, HyperEVM → RH pathways
contract GenerateRHPathwayCalldata is Script {
    using OptionsBuilder for bytes;

    // ─── Endpoints ───────────────────────────────────────────────────
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant LZ_ENDPOINT_HYPEREVM = 0x3A73033C0b1407574C76BdBAc67f126f6b4a9AA9;
    address internal constant LZ_ENDPOINT_RH = 0x6F475642a6e85809B1c36Fa62763669b1b48DD5B;

    // ─── EIDs ────────────────────────────────────────────────────────
    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;
    uint32 internal constant RH_EID = 30416;

    // ─── OApp addresses ──────────────────────────────────────────────
    address internal constant UP_OFT_ADAPTER_ETH = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant UP_OFT_BASE = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant UP_OFT_HYPEREVM = 0x642fFC3496AcA19106BAB7A42F1F221a329654fe;
    address internal constant UP_OFT_FLARE = 0xe030A89fd2b7f858c8aA47725679CA25D467dFD1;
    address internal constant UP_OFT_RH = 0xA85abEf37c7e812ACA761b2BEC62fFF7f3728F1E;

    // ─── Multisig ────────────────────────────────────────────────────
    address internal constant MULTISIG = 0x89226a5Fd572f380991Bb17c20c96ba91F98aD2e;
    address internal constant DEPLOYER = 0x6E3dadcAf328ebB58753e89a3e589F5C5e988dF8;

    // ─── ETH libraries & DVNs ────────────────────────────────────────
    address internal constant SEND_LIB_ETH = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;
    address internal constant RECEIVE_LIB_ETH = 0xc02Ab410f0734EFa3F14628780e6e695156024C2;
    address internal constant EXECUTOR_ETH = 0x173272739Bd7Aa6e4e214714048a9fE699453059;
    address internal constant DVN_LZ_ETH = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address internal constant DVN_SUPERFORM_ETH = 0x7518f30bd5867b5fA86702556245Dead173afE46;
    address internal constant DVN_NETHERMIND_ETH = 0xa4fE5A5B9A846458a70Cd0748228aED3bF65c2cd;
    address internal constant DVN_HORIZEN_ETH = 0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;

    // ─── Base libraries & DVNs ───────────────────────────────────────
    address internal constant SEND_LIB_BASE = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;
    address internal constant RECEIVE_LIB_BASE = 0xc70AB6f32772f59fBfc23889Caf4Ba3376C84bAf;
    address internal constant EXECUTOR_BASE = 0x2CCA08ae69E0C44b18a57Ab2A87644234dAebaE4;
    address internal constant DVN_LZ_BASE = 0x9e059a54699a285714207b43B055483E78FAac25;
    address internal constant DVN_NETHERMIND_BASE = 0x554833698Ae0FB22ECC90B01222903fD62CA4B47;
    address internal constant DVN_HORIZEN_BASE = 0xcd37CA043f8479064e10635020c65FfC005d36f6;
    address internal constant DVN_SUPERFORM_BASE = 0xEb62f578497Bdc351dD650853a751135212fAF49;

    // ─── HyperEVM libraries & DVNs ───────────────────────────────────
    address internal constant SEND_LIB_HYPEREVM = 0xfd76d9CB0Bac839725aB79127E7411fe71b1e3CA;
    address internal constant RECEIVE_LIB_HYPEREVM = 0x7cacBe439EaD55fa1c22790330b12835c6884a91;
    address internal constant EXECUTOR_HYPEREVM = 0x41Bdb4aa4A63a5b2Efc531858d3118392B1A1C3d;
    address internal constant DVN_LZ_HYPEREVM = 0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f;

    // ─── Flare libraries & DVNs ──────────────────────────────────────
    address internal constant SEND_LIB_FLARE = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address internal constant RECEIVE_LIB_FLARE = 0x2367325334447C5E1E0f1b3a6fB947b262F58312;
    address internal constant EXECUTOR_FLARE = 0xcCE466a522984415bC91338c232d98869193D46e;
    address internal constant DVN_LZ_FLARE = 0x9C061c9A4782294eeF65ef28Cb88233A987F4bdD;

    // ─── RH libraries & DVNs ─────────────────────────────────────────
    address internal constant SEND_LIB_RH = 0xC39161c743D0307EB9BCc9FEF03eeb9Dc4802de7;
    address internal constant RECEIVE_LIB_RH = 0xe1844c5D63a9543023008D332Bd3d2e6f1FE1043;
    address internal constant EXECUTOR_RH = 0x4208D6E27538189bB48E603D6123A94b8Abe0A0b;
    address internal constant DVN_LZ_RH = 0xd01ae6905d48315f7bE10C7330aeCF8360Ef5b12;
    address internal constant DVN_NETHERMIND_RH = 0x0Ffe02DF012299A370D5dd69298A5826EAcaFdF8;
    address internal constant DVN_CANARY_RH = 0x8D77D35604A9f37f488E41D1d916b2A0088F82Dd;

    // ─── Options ─────────────────────────────────────────────────────
    uint16 internal constant SEND = 1;
    uint16 internal constant SEND_AND_CALL = 2;
    uint128 internal constant GAS_LIMIT = 300_000;
    uint128 internal constant COMPOSE_GAS_LIMIT = 1_000_000;
    uint32 internal constant EXECUTOR_CONFIG_TYPE = 1;
    uint32 internal constant ULN_CONFIG_TYPE = 2;
    uint32 internal constant GRACE_PERIOD = 0;

    string internal outputDir;

    function run() public {
        outputDir = string.concat(vm.projectRoot(), "/script/output/rh-pathway-calldata");

        _generateEthereumMd();
        _generateBaseMd();
        _generateHyperEVMMd();
        _generateFlareMd();
        _generateRHMd();

        console2.log("All files written to:", outputDir);
    }

    // ═══════════════════════════════════════════════════════════════
    //  ETHEREUM (multisig = owner + delegate)
    // ═══════════════════════════════════════════════════════════════
    function _generateEthereumMd() internal {
        string memory path = string.concat(outputDir, "/ethereum-to-rh.md");
        vm.writeFile(path, "# Ethereum UpOFTAdapter -> RH Configuration\n\n");
        _a(path, "**Chain:** Ethereum (Chain ID: 1)\n");
        _a(path, string.concat("**Multisig (owner & delegate):** `", vm.toString(MULTISIG), "`\n"));
        _a(path, string.concat("**OApp:** UpOFTAdapter `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("**LZ Endpoint:** `", vm.toString(LZ_ENDPOINT), "`\n\n"));
        _a(path, "---\n\n");

        // TX 1: setPeer
        bytes32 rhPeer = bytes32(uint256(uint160(UP_OFT_RH)));
        _a(path, "## TX 1: Set Peer (RH)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_ADAPTER_ETH), "` (UpOFTAdapter)\n"));
        _a(path, "**Function:** `setPeer(uint32 _eid, bytes32 _peer)`\n\n");
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "` (RH EID)\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(rhPeer), "`\n\n"));
        bytes memory cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", RH_EID, rhPeer);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 2: setSendLibrary
        _a(path, "## TX 2: Set Send Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setSendLibrary(address _oapp, uint32 _eid, address _newLib)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_ETH), "`\n\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_ADAPTER_ETH, RH_EID, SEND_LIB_ETH);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 3: setReceiveLibrary
        _a(path, "## TX 3: Set Receive Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_ETH), "`\n"));
        _a(path, string.concat("- `_gracePeriod`: `", vm.toString(uint256(GRACE_PERIOD)), "`\n\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_ADAPTER_ETH, RH_EID, RECEIVE_LIB_ETH, GRACE_PERIOD);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 4: setConfig (send - executor + ULN)
        address[] memory dvnsEth = new address[](4);
        dvnsEth[0] = DVN_LZ_ETH;
        dvnsEth[1] = DVN_SUPERFORM_ETH;
        dvnsEth[2] = DVN_NETHERMIND_ETH;
        dvnsEth[3] = DVN_HORIZEN_ETH;

        UlnConfig memory sendUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEth,
            optionalDVNs: new address[](0)
        });

        ExecutorConfig memory sendExec = ExecutorConfig({
            maxMessageSize: 10_000,
            executor: EXECUTOR_ETH
        });

        SetConfigParam[] memory sendParams = new SetConfigParam[](2);
        sendParams[0] = SetConfigParam(RH_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParams[1] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));

        _a(path, "## TX 4: Set Send Config (Executor + ULN DVNs)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setConfig(address _oapp, address _lib, SetConfigParam[] _params)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_ETH), "` (Send Library)\n"));
        _a(path, "- Send ULN Config: 20 confirmations, 4 required DVNs\n");
        _a(path, string.concat("  - DVN 1 (LZ): `", vm.toString(DVN_LZ_ETH), "`\n"));
        _a(path, string.concat("  - DVN 2 (Superform): `", vm.toString(DVN_SUPERFORM_ETH), "`\n"));
        _a(path, string.concat("  - DVN 3 (Nethermind): `", vm.toString(DVN_NETHERMIND_ETH), "`\n"));
        _a(path, string.concat("  - DVN 4 (Horizen): `", vm.toString(DVN_HORIZEN_ETH), "`\n"));
        _a(path, string.concat("- Executor: `", vm.toString(EXECUTOR_ETH), "` (maxMessageSize: 10000)\n\n"));
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_ADAPTER_ETH, SEND_LIB_ETH, sendParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 5: setConfig (receive - ULN only)
        UlnConfig memory recvUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsEth,
            optionalDVNs: new address[](0)
        });

        SetConfigParam[] memory recvParams = new SetConfigParam[](1);
        recvParams[0] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(recvUln));

        _a(path, "## TX 5: Set Receive Config (ULN DVNs)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setConfig(address _oapp, address _lib, SetConfigParam[] _params)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_ETH), "` (Receive Library)\n"));
        _a(path, "- Receive ULN Config: 20 confirmations, 4 required DVNs (same as send)\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_ADAPTER_ETH, RECEIVE_LIB_ETH, recvParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 6: setEnforcedOptions
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND, options: sendOptions });
        enforcedOptions[1] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 6: Set Enforced Options\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_ADAPTER_ETH), "` (UpOFTAdapter)\n"));
        _a(path, "**Function:** `setEnforcedOptions(EnforcedOptionParam[] _enforcedOptions)`\n\n");
        _a(path, string.concat("- SEND (msgType 1): gas limit ", vm.toString(uint256(GAS_LIMIT)), "\n"));
        _a(path, string.concat("- SEND_AND_CALL (msgType 2): gas limit ", vm.toString(uint256(GAS_LIMIT)), " + compose gas ", vm.toString(uint256(COMPOSE_GAS_LIMIT)), "\n\n"));
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedOptions);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 7: Pin Receive Library for Flare pathway (currently using default, not pinned)
        _a(path, "## TX 7: Pin Receive Library (Flare pathway - currently NOT pinned)\n\n");
        _a(path, "> **IMPORTANT:** The receive library for the Flare pathway (EID 30295) on Ethereum is currently using the default library and is NOT pinned. This TX pins it.\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_ADAPTER_ETH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(FLARE_EID)), "` (Flare EID)\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_ETH), "`\n"));
        _a(path, string.concat("- `_gracePeriod`: `", vm.toString(uint256(GRACE_PERIOD)), "`\n\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_ADAPTER_ETH, FLARE_EID, RECEIVE_LIB_ETH, GRACE_PERIOD);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n"));

        console2.log("Written:", path);
    }

    // ═══════════════════════════════════════════════════════════════
    //  BASE (multisig = owner, deployer = delegate)
    // ═══════════════════════════════════════════════════════════════
    function _generateBaseMd() internal {
        string memory path = string.concat(outputDir, "/base-to-rh.md");
        vm.writeFile(path, "# Base UpOFT -> RH Configuration\n\n");
        _a(path, "**Chain:** Base (Chain ID: 8453)\n");
        _a(path, string.concat("**Multisig (owner):** `", vm.toString(MULTISIG), "`\n"));
        _a(path, string.concat("**Deployer (delegate):** `", vm.toString(DEPLOYER), "`\n"));
        _a(path, string.concat("**OApp:** UpOFT `", vm.toString(UP_OFT_BASE), "`\n"));
        _a(path, string.concat("**LZ Endpoint:** `", vm.toString(LZ_ENDPOINT), "`\n\n"));
        _a(path, "> **Note:** setPeer and setEnforcedOptions require **owner** (multisig).\n");
        _a(path, "> setConfig and setLibrary require **delegate** (deployer) OR can be called by owner if delegate is changed.\n\n");
        _a(path, "---\n\n");

        bytes32 rhPeer = bytes32(uint256(uint160(UP_OFT_RH)));

        // TX 1: setPeer (owner)
        _a(path, "## TX 1: Set Peer (RH) [Owner/Multisig]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_BASE), "` (UpOFT)\n"));
        _a(path, "**Function:** `setPeer(uint32 _eid, bytes32 _peer)`\n\n");
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(rhPeer), "`\n\n"));
        bytes memory cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", RH_EID, rhPeer);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 2: setSendLibrary (delegate)
        _a(path, "## TX 2: Set Send Library [Delegate/Deployer]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setSendLibrary(address _oapp, uint32 _eid, address _newLib)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_BASE), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_BASE), "`\n\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_BASE, RH_EID, SEND_LIB_BASE);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 3: setReceiveLibrary (delegate)
        _a(path, "## TX 3: Set Receive Library [Delegate/Deployer]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setReceiveLibrary(address _oapp, uint32 _eid, address _newLib, uint256 _gracePeriod)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_BASE), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_BASE), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_BASE, RH_EID, RECEIVE_LIB_BASE, GRACE_PERIOD);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 4: setConfig send (delegate)
        address[] memory dvnsBase = new address[](4);
        dvnsBase[0] = DVN_NETHERMIND_BASE;
        dvnsBase[1] = DVN_LZ_BASE;
        dvnsBase[2] = DVN_HORIZEN_BASE;
        dvnsBase[3] = DVN_SUPERFORM_BASE;

        UlnConfig memory sendUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBase,
            optionalDVNs: new address[](0)
        });

        ExecutorConfig memory sendExec = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_BASE });

        SetConfigParam[] memory sendParams = new SetConfigParam[](2);
        sendParams[0] = SetConfigParam(RH_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParams[1] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));

        _a(path, "## TX 4: Set Send Config [Delegate/Deployer]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setConfig(address _oapp, address _lib, SetConfigParam[] _params)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_BASE), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_BASE), "`\n"));
        _a(path, "- Send ULN: 20 confirmations, 4 DVNs (sorted ascending)\n");
        _a(path, string.concat("  - DVN 1 (Nethermind): `", vm.toString(DVN_NETHERMIND_BASE), "`\n"));
        _a(path, string.concat("  - DVN 2 (LZ): `", vm.toString(DVN_LZ_BASE), "`\n"));
        _a(path, string.concat("  - DVN 3 (Horizen): `", vm.toString(DVN_HORIZEN_BASE), "`\n"));
        _a(path, string.concat("  - DVN 4 (Superform): `", vm.toString(DVN_SUPERFORM_BASE), "`\n"));
        _a(path, string.concat("- Executor: `", vm.toString(EXECUTOR_BASE), "`\n\n"));
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_BASE, SEND_LIB_BASE, sendParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 5: setConfig receive (delegate)
        UlnConfig memory recvUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsBase,
            optionalDVNs: new address[](0)
        });

        SetConfigParam[] memory recvParams = new SetConfigParam[](1);
        recvParams[0] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(recvUln));

        _a(path, "## TX 5: Set Receive Config [Delegate/Deployer]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, "**Function:** `setConfig(address _oapp, address _lib, SetConfigParam[] _params)`\n\n");
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_BASE), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_BASE), "`\n"));
        _a(path, "- Receive ULN: 20 confirmations, 4 DVNs (same as send)\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_BASE, RECEIVE_LIB_BASE, recvParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 6: setEnforcedOptions (owner)
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);

        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND, options: sendOptions });
        enforcedOptions[1] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 6: Set Enforced Options [Owner/Multisig]\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_BASE), "` (UpOFT)\n"));
        _a(path, "**Function:** `setEnforcedOptions(EnforcedOptionParam[] _enforcedOptions)`\n\n");
        _a(path, string.concat("- SEND (msgType 1): gas limit ", vm.toString(uint256(GAS_LIMIT)), "\n"));
        _a(path, string.concat("- SEND_AND_CALL (msgType 2): gas limit ", vm.toString(uint256(GAS_LIMIT)), " + compose gas ", vm.toString(uint256(COMPOSE_GAS_LIMIT)), "\n\n"));
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedOptions);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n"));

        console2.log("Written:", path);
    }

    // ═══════════════════════════════════════════════════════════════
    //  HYPEREVM (multisig = owner + delegate)
    // ═══════════════════════════════════════════════════════════════
    function _generateHyperEVMMd() internal {
        string memory path = string.concat(outputDir, "/hyperevm-to-rh.md");
        vm.writeFile(path, "# HyperEVM UpOFT -> RH Configuration\n\n");
        _a(path, "**Chain:** HyperEVM (Chain ID: 999)\n");
        _a(path, string.concat("**Multisig (owner & delegate):** `", vm.toString(MULTISIG), "`\n"));
        _a(path, string.concat("**OApp:** UpOFT `", vm.toString(UP_OFT_HYPEREVM), "`\n"));
        _a(path, string.concat("**LZ Endpoint:** `", vm.toString(LZ_ENDPOINT_HYPEREVM), "`\n\n"));
        _a(path, "> **Note:** HyperEVM uses a different LZ endpoint than ETH/Base/Flare.\n");
        _a(path, "> HyperEVM has only 1 DVN (LZ Labs) for its pathways.\n\n");
        _a(path, "---\n\n");

        bytes32 rhPeer = bytes32(uint256(uint160(UP_OFT_RH)));
        address[] memory dvnsHyper = new address[](1);
        dvnsHyper[0] = DVN_LZ_HYPEREVM;

        // TX 1: setPeer
        _a(path, "## TX 1: Set Peer (RH)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_HYPEREVM), "` (UpOFT)\n"));
        _a(path, "**Function:** `setPeer(uint32 _eid, bytes32 _peer)`\n\n");
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(rhPeer), "`\n\n"));
        bytes memory cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", RH_EID, rhPeer);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 2: setSendLibrary
        _a(path, "## TX 2: Set Send Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_HYPEREVM), "` (LZ Endpoint)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_HYPEREVM, RH_EID, SEND_LIB_HYPEREVM);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_HYPEREVM), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_HYPEREVM), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 3: setReceiveLibrary
        _a(path, "## TX 3: Set Receive Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_HYPEREVM), "` (LZ Endpoint)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_HYPEREVM, RH_EID, RECEIVE_LIB_HYPEREVM, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_HYPEREVM), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_HYPEREVM), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 4: setConfig send
        UlnConfig memory sendUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyper,
            optionalDVNs: new address[](0)
        });
        ExecutorConfig memory sendExec = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_HYPEREVM });
        SetConfigParam[] memory sendParams = new SetConfigParam[](2);
        sendParams[0] = SetConfigParam(RH_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParams[1] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));

        _a(path, "## TX 4: Set Send Config\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_HYPEREVM), "` (LZ Endpoint)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_HYPEREVM), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_HYPEREVM), "`\n"));
        _a(path, string.concat("- Send ULN: 20 confirmations, 1 DVN (LZ Labs: `", vm.toString(DVN_LZ_HYPEREVM), "`)\n"));
        _a(path, string.concat("- Executor: `", vm.toString(EXECUTOR_HYPEREVM), "`\n\n"));
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_HYPEREVM, SEND_LIB_HYPEREVM, sendParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 5: setConfig receive (20 confirmations - must match RH send confirmations)
        UlnConfig memory recvUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsHyper,
            optionalDVNs: new address[](0)
        });
        SetConfigParam[] memory recvParams = new SetConfigParam[](1);
        recvParams[0] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(recvUln));

        _a(path, "## TX 5: Set Receive Config\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_HYPEREVM), "` (LZ Endpoint)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_HYPEREVM), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_HYPEREVM), "`\n"));
        _a(path, "- Receive ULN: 20 confirmations (must match RH send), 1 DVN (LZ Labs)\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_HYPEREVM, RECEIVE_LIB_HYPEREVM, recvParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 6: setEnforcedOptions
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);
        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND, options: sendOptions });
        enforcedOptions[1] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 6: Set Enforced Options\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_HYPEREVM), "` (UpOFT)\n"));
        _a(path, "**Function:** `setEnforcedOptions(EnforcedOptionParam[] _enforcedOptions)`\n\n");
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedOptions);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n"));

        console2.log("Written:", path);
    }

    // ═══════════════════════════════════════════════════════════════
    //  FLARE (deployer EOA = owner + delegate - NOT multisig!)
    // ═══════════════════════════════════════════════════════════════
    function _generateFlareMd() internal {
        string memory path = string.concat(outputDir, "/flare-to-rh.md");
        vm.writeFile(path, "# Flare UpOFT -> RH Configuration\n\n");
        _a(path, "**Chain:** Flare (Chain ID: 14)\n");
        _a(path, string.concat("**Current Owner & Delegate:** `", vm.toString(0x0f0Db7CEDD49587D78d67175Ff59Ed7069A35874), "` (deployer EOA, NOT multisig!)\n"));
        _a(path, string.concat("**OApp:** UpOFT `", vm.toString(UP_OFT_FLARE), "`\n"));
        _a(path, string.concat("**LZ Endpoint:** `", vm.toString(LZ_ENDPOINT), "`\n\n"));
        _a(path, "> **WARNING:** Flare UpOFT is owned by deployer EOA `0x0f0D...`, not the multisig.\n");
        _a(path, "> These transactions must be sent from that EOA, or ownership must be transferred first.\n");
        _a(path, "> Flare has only 1 DVN (LZ Labs) for its pathways.\n\n");
        _a(path, "---\n\n");

        bytes32 rhPeer = bytes32(uint256(uint160(UP_OFT_RH)));
        address[] memory dvnsFlare = new address[](1);
        dvnsFlare[0] = DVN_LZ_FLARE;

        // TX 1: setPeer
        _a(path, "## TX 1: Set Peer (RH)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_FLARE), "` (UpOFT)\n"));
        bytes memory cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", RH_EID, rhPeer);
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(rhPeer), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 2: setSendLibrary
        _a(path, "## TX 2: Set Send Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_FLARE, RH_EID, SEND_LIB_FLARE);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_FLARE), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_FLARE), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 3: setReceiveLibrary
        _a(path, "## TX 3: Set Receive Library\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_FLARE, RH_EID, RECEIVE_LIB_FLARE, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_FLARE), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(RH_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_FLARE), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 4: setConfig send (1 DVN)
        UlnConfig memory sendUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });
        ExecutorConfig memory sendExec = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_FLARE });
        SetConfigParam[] memory sendParams = new SetConfigParam[](2);
        sendParams[0] = SetConfigParam(RH_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParams[1] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));

        _a(path, "## TX 4: Set Send Config\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_FLARE), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_FLARE), "`\n"));
        _a(path, string.concat("- Send ULN: 20 confirmations, 1 DVN (LZ Labs: `", vm.toString(DVN_LZ_FLARE), "`)\n"));
        _a(path, string.concat("- Executor: `", vm.toString(EXECUTOR_FLARE), "`\n\n"));
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_FLARE, SEND_LIB_FLARE, sendParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 5: setConfig receive (20 confirmations - must match RH send confirmations)
        UlnConfig memory recvUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 1,
            optionalDVNCount: type(uint8).max,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsFlare,
            optionalDVNs: new address[](0)
        });
        SetConfigParam[] memory recvParams = new SetConfigParam[](1);
        recvParams[0] = SetConfigParam(RH_EID, ULN_CONFIG_TYPE, abi.encode(recvUln));

        _a(path, "## TX 5: Set Receive Config\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT), "` (LZ Endpoint)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_FLARE), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_FLARE), "`\n"));
        _a(path, "- Receive ULN: 20 confirmations (must match RH send), 1 DVN (LZ Labs)\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_FLARE, RECEIVE_LIB_FLARE, recvParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 6: setEnforcedOptions
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);
        EnforcedOptionParam[] memory enforcedOptions = new EnforcedOptionParam[](2);
        enforcedOptions[0] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND, options: sendOptions });
        enforcedOptions[1] = EnforcedOptionParam({ eid: RH_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 6: Set Enforced Options\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_FLARE), "` (UpOFT)\n"));
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedOptions);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n"));

        console2.log("Written:", path);
    }

    // ═══════════════════════════════════════════════════════════════
    //  RH (deployer EOA = owner + delegate)
    // ═══════════════════════════════════════════════════════════════
    function _generateRHMd() internal {
        string memory path = string.concat(outputDir, "/rh-to-others.md");
        vm.writeFile(path, "# RH UpOFT -> ETH/Base/HyperEVM/Flare Configuration\n\n");
        _a(path, "**Chain:** Robinhood (Chain ID: 4663)\n");
        _a(path, string.concat("**Current Owner & Delegate:** `", vm.toString(DEPLOYER), "` (deployer EOA)\n"));
        _a(path, string.concat("**OApp:** UpOFT `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("**LZ Endpoint:** `", vm.toString(LZ_ENDPOINT_RH), "`\n\n"));
        _a(path, "> **Note:** RH UpOFT already has peers set for ETH and Base.\n");
        _a(path, "> Send/receive libraries and configs were set during deployment.\n");
        _a(path, "> Below are the additional peer + config transactions needed for HyperEVM and Flare.\n\n");
        _a(path, "---\n\n");

        // HyperEVM peer
        bytes32 hyperPeer = bytes32(uint256(uint160(UP_OFT_HYPEREVM)));
        _a(path, "## TX 1: Set Peer (HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_RH), "` (UpOFT)\n"));
        bytes memory cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", HYPEREVM_EID, hyperPeer);
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(HYPEREVM_EID)), "`\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(hyperPeer), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Flare peer
        bytes32 flarePeer = bytes32(uint256(uint160(UP_OFT_FLARE)));
        _a(path, "## TX 2: Set Peer (Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_RH), "` (UpOFT)\n"));
        cd = abi.encodeWithSignature("setPeer(uint32,bytes32)", FLARE_EID, flarePeer);
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(FLARE_EID)), "`\n"));
        _a(path, string.concat("- `_peer`: `", vm.toString(flarePeer), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // HyperEVM send library
        _a(path, "## TX 3: Set Send Library (HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_RH, HYPEREVM_EID, SEND_LIB_RH);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(HYPEREVM_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_RH), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // HyperEVM receive library
        _a(path, "## TX 4: Set Receive Library (HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_RH, HYPEREVM_EID, RECEIVE_LIB_RH, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(HYPEREVM_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Flare send library
        _a(path, "## TX 5: Set Send Library (Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_RH, FLARE_EID, SEND_LIB_RH);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(FLARE_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_RH), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Flare receive library
        _a(path, "## TX 6: Set Receive Library (Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_RH, FLARE_EID, RECEIVE_LIB_RH, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(FLARE_EID)), "`\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        _generateRHMdPart2(path);
    }

    function _generateRHMdPart2(string memory path) internal {
        address[] memory dvnsRH = new address[](3);
        dvnsRH[0] = DVN_NETHERMIND_RH;
        dvnsRH[1] = DVN_CANARY_RH;
        dvnsRH[2] = DVN_LZ_RH;

        UlnConfig memory sendUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsRH,
            optionalDVNs: new address[](0)
        });
        ExecutorConfig memory sendExec = ExecutorConfig({ maxMessageSize: 10_000, executor: EXECUTOR_RH });

        // TX 7: Send config for HyperEVM
        SetConfigParam[] memory sendParams = new SetConfigParam[](2);
        sendParams[0] = SetConfigParam(HYPEREVM_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParams[1] = SetConfigParam(HYPEREVM_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));

        _a(path, "## TX 7: Set Send Config (RH -> HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_RH), "`\n"));
        _a(path, "- 20 confirmations, 3 DVNs, Executor RH\n\n");
        bytes memory cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_RH, SEND_LIB_RH, sendParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 8: Receive config for HyperEVM (20 confirmations - must match HyperEVM send)
        UlnConfig memory recvFromHyperUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsRH,
            optionalDVNs: new address[](0)
        });
        SetConfigParam[] memory recvParams = new SetConfigParam[](1);
        recvParams[0] = SetConfigParam(HYPEREVM_EID, ULN_CONFIG_TYPE, abi.encode(recvFromHyperUln));
        _a(path, "## TX 8: Set Receive Config (RH <- HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- 20 confirmations (must match HyperEVM send), 3 DVNs\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_RH, RECEIVE_LIB_RH, recvParams);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        _generateRHMdPart3(path, sendUln, sendExec, dvnsRH);
    }

    function _generateRHMdPart3(
        string memory path,
        UlnConfig memory sendUln,
        ExecutorConfig memory sendExec,
        address[] memory dvnsRH
    ) internal {
        // TX 9: Send config for Flare
        SetConfigParam[] memory sendParamsFlare = new SetConfigParam[](2);
        sendParamsFlare[0] = SetConfigParam(FLARE_EID, EXECUTOR_CONFIG_TYPE, abi.encode(sendExec));
        sendParamsFlare[1] = SetConfigParam(FLARE_EID, ULN_CONFIG_TYPE, abi.encode(sendUln));
        _a(path, "## TX 9: Set Send Config (RH -> Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(SEND_LIB_RH), "`\n"));
        _a(path, "- 20 confirmations, 3 DVNs, Executor RH\n\n");
        bytes memory cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_RH, SEND_LIB_RH, sendParamsFlare);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 10: Receive config for Flare (20 confirmations - must match Flare send)
        UlnConfig memory recvFromFlareUln = UlnConfig({
            confirmations: 20,
            requiredDVNCount: 3,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvnsRH,
            optionalDVNs: new address[](0)
        });
        SetConfigParam[] memory recvParamsFlare = new SetConfigParam[](1);
        recvParamsFlare[0] = SetConfigParam(FLARE_EID, ULN_CONFIG_TYPE, abi.encode(recvFromFlareUln));
        _a(path, "## TX 10: Set Receive Config (RH <- Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_lib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- 20 confirmations (must match Flare send), 3 DVNs\n\n");
        cd = abi.encodeWithSignature("setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_RH, RECEIVE_LIB_RH, recvParamsFlare);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // TX 11 + 12: Enforced options for HyperEVM and Flare
        bytes memory sendOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0);
        bytes memory sendAndCallOptions = OptionsBuilder.newOptions().addExecutorLzReceiveOption(GAS_LIMIT, 0)
            .addExecutorLzComposeOption(0, COMPOSE_GAS_LIMIT, 0);

        EnforcedOptionParam[] memory enforcedHyper = new EnforcedOptionParam[](2);
        enforcedHyper[0] = EnforcedOptionParam({ eid: HYPEREVM_EID, msgType: SEND, options: sendOptions });
        enforcedHyper[1] = EnforcedOptionParam({ eid: HYPEREVM_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 11: Set Enforced Options (RH -> HyperEVM)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_RH), "` (UpOFT)\n"));
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedHyper);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        EnforcedOptionParam[] memory enforcedFlare = new EnforcedOptionParam[](2);
        enforcedFlare[0] = EnforcedOptionParam({ eid: FLARE_EID, msgType: SEND, options: sendOptions });
        enforcedFlare[1] = EnforcedOptionParam({ eid: FLARE_EID, msgType: SEND_AND_CALL, options: sendAndCallOptions });

        _a(path, "## TX 12: Set Enforced Options (RH -> Flare)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(UP_OFT_RH), "` (UpOFT)\n"));
        cd = abi.encodeWithSignature("setEnforcedOptions((uint32,uint16,bytes)[])", enforcedFlare);
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // ── Pin existing ETH/Base libs if not already pinned ──
        _a(path, "## VERIFY: Pin Existing Libraries (ETH & Base pathways)\n\n");
        _a(path, "> **Check on-chain first!** Run `getReceiveLibrary(oapp, eid)` and `isDefaultSendLibrary(oapp, eid)` on RH endpoint.\n");
        _a(path, "> If `isDefault=true`, the library is NOT pinned and needs these TXs.\n");
        _a(path, "> ETH/Base pathways were configured during deployment - they may already be pinned.\n\n");

        // Pin send lib ETH
        _a(path, "### TX 13 (if needed): Pin Send Library (ETH)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_RH, ETH_EID, SEND_LIB_RH);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(ETH_EID)), "` (ETH)\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_RH), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Pin recv lib ETH
        _a(path, "### TX 14 (if needed): Pin Receive Library (ETH)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_RH, ETH_EID, RECEIVE_LIB_RH, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(ETH_EID)), "` (ETH)\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Pin send lib Base
        _a(path, "### TX 15 (if needed): Pin Send Library (Base)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setSendLibrary(address,uint32,address)", UP_OFT_RH, BASE_EID, SEND_LIB_RH);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(BASE_EID)), "` (Base)\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(SEND_LIB_RH), "`\n\n"));
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));

        // Pin recv lib Base
        _a(path, "### TX 16 (if needed): Pin Receive Library (Base)\n\n");
        _a(path, string.concat("**Target:** `", vm.toString(LZ_ENDPOINT_RH), "` (LZ Endpoint RH)\n"));
        cd = abi.encodeWithSignature("setReceiveLibrary(address,uint32,address,uint256)", UP_OFT_RH, BASE_EID, RECEIVE_LIB_RH, GRACE_PERIOD);
        _a(path, string.concat("- `_oapp`: `", vm.toString(UP_OFT_RH), "`\n"));
        _a(path, string.concat("- `_eid`: `", vm.toString(uint256(BASE_EID)), "` (Base)\n"));
        _a(path, string.concat("- `_newLib`: `", vm.toString(RECEIVE_LIB_RH), "`\n"));
        _a(path, "- `_gracePeriod`: `0`\n\n");
        _a(path, string.concat("**Calldata:**\n```\n", vm.toString(cd), "\n```\n\n"));

        console2.log("Written:", path);
    }

    function _a(string memory path, string memory data) internal {
        vm.writeLine(path, data);
    }
}
