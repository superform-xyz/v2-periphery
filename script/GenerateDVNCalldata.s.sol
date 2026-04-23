// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { Script } from "forge-std/Script.sol";
import { console2 } from "forge-std/console2.sol";

import { SetConfigParam } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import { UlnConfig } from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

/// @notice Generate setConfig calldata for updating DVNs on Ethereum (send-only) - outputs to markdown file
contract GenerateDVNCalldataETH is Script {
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant UP_OFT_ADAPTER = 0x722ff7C0665F4b1823c9C4cFcDF73A43de5865BD;
    address internal constant SEND_LIB = 0xbB2Ea70C9E858123480642Cf96acbcCE1372dCe1;

    uint32 internal constant BASE_EID = 30184;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // DVNs on Ethereum (sorted ascending)
    address internal constant DVN_LZ = 0x589dEDbD617e0CBcB916A9223F4d1300c294236b;
    address internal constant DVN_SUPERFORM = 0x7518f30bd5867b5fA86702556245Dead173afE46;
    address internal constant DVN_NETHERMIND = 0xa59BA433ac34D2927232918Ef5B2eaAfcF130BA5;
    address internal constant DVN_GOOGLE = 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc;

    string internal outputPath;

    function run() public {
        require(DVN_LZ < DVN_SUPERFORM && DVN_SUPERFORM < DVN_NETHERMIND && DVN_NETHERMIND < DVN_GOOGLE, "DVNs not sorted");

        outputPath = string.concat(vm.projectRoot(), "/script/output/dvn-calldata-ethereum.md");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_LZ;
        dvns[1] = DVN_SUPERFORM;
        dvns[2] = DVN_NETHERMIND;
        dvns[3] = DVN_GOOGLE;

        _writeHeader(dvns);
        _writeSendConfig("Base", BASE_EID, dvns, 15);
        _writeSendConfig("HyperEVM", HYPEREVM_EID, dvns, 15);
        _writeSendConfig("Flare", FLARE_EID, dvns, 15);

        console2.log("Written to:", outputPath);
    }

    function _writeHeader(address[] memory dvns) internal {
        vm.writeFile(outputPath, "# DVN Update Calldata - Ethereum (Send Only)\n\n");
        _append("## How to Execute on Etherscan\n\n");
        _append(string.concat("1. Go to LZ Endpoint on Etherscan: `", vm.toString(LZ_ENDPOINT), "`\n"));
        _append("2. Navigate to **Contract** > **Write as Proxy** tab\n");
        _append("3. Connect your wallet\n");
        _append("4. Find function **`setConfig`** (function #12)\n");
        _append("5. For each transaction below, paste the parameters into the form fields\n");
        _append("6. Alternatively, use the **Write Contract** tab and paste the **Full calldata** directly\n\n");
        _append("---\n\n");
        _append(string.concat("**Target:** LZ Endpoint [`", vm.toString(LZ_ENDPOINT), "`](https://etherscan.io/address/", vm.toString(LZ_ENDPOINT), "#writeProxyContract)\n\n"));
        _append(string.concat("**OApp:** UpOFTAdapter `", vm.toString(UP_OFT_ADAPTER), "`\n\n"));
        _append(string.concat("**Send Library:** `", vm.toString(SEND_LIB), "`\n\n"));
        _append("**DVNs (4 required, sorted ascending):**\n\n");
        _append("| # | DVN | Address |\n|---|-----|-------|\n");
        _append(string.concat("| 1 | LayerZero Labs | `", vm.toString(dvns[0]), "` |\n"));
        _append(string.concat("| 2 | Superform | `", vm.toString(dvns[1]), "` |\n"));
        _append(string.concat("| 3 | Nethermind | `", vm.toString(dvns[2]), "` |\n"));
        _append(string.concat("| 4 | Google Cloud | `", vm.toString(dvns[3]), "` |\n\n---\n\n"));
    }

    function _writeSendConfig(string memory name, uint32 remoteEid, address[] memory dvns, uint64 confirmations)
        internal
    {
        UlnConfig memory uln = _makeUlnConfig(confirmations, dvns);
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));
        bytes memory cd = abi.encodeWithSignature(
            "setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT_ADAPTER, SEND_LIB, params
        );

        _append(string.concat("## TX: ETH -> ", name, " Send Config\n\n"));
        _append(string.concat("Sets send-side DVNs for the ETH -> ", name, " pathway (", vm.toString(uint256(confirmations)), " ETH block confirmations)\n\n"));
        _append("### Etherscan `setConfig` form fields\n\n");
        _append(string.concat("**`_oapp` (address):**\n```\n", vm.toString(UP_OFT_ADAPTER), "\n```\n\n"));
        _append(string.concat("**`_lib` (address):**\n```\n", vm.toString(SEND_LIB), "\n```\n\n"));
        _append(string.concat("**`_params` (tuple[]):** paste this JSON into the field:\n```\n[[", vm.toString(uint256(remoteEid)), ",2,\"", vm.toString(abi.encode(uln)), "\"]]\n```\n\n"));
        _append(string.concat("**Full calldata (alternative - paste into raw tx input):**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));
    }

    function _append(string memory data) internal {
        vm.writeLine(outputPath, data);
    }

    function _makeUlnConfig(uint64 confirmations, address[] memory dvns) internal pure returns (UlnConfig memory) {
        return UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });
    }
}

/// @notice Generate setConfig calldata for updating DVNs on Base (send-only) - outputs to markdown file
contract GenerateDVNCalldataBase is Script {
    address internal constant LZ_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address internal constant UP_OFT = 0x5b2193fDc451C1f847bE09CA9d13A4Bf60f8c86B;
    address internal constant SEND_LIB = 0xB5320B0B3a13cC860893E2Bd79FCd7e13484Dda2;

    uint32 internal constant ETH_EID = 30101;
    uint32 internal constant HYPEREVM_EID = 30367;
    uint32 internal constant FLARE_EID = 30295;
    uint32 internal constant ULN_CONFIG_TYPE = 2;

    // DVNs on Base (sorted ascending)
    address internal constant DVN_LZ = 0x9e059a54699a285714207b43B055483E78FAac25;
    address internal constant DVN_NETHERMIND = 0xcd37CA043f8479064e10635020c65FfC005d36f6;
    address internal constant DVN_GOOGLE = 0xD56e4eAb23cb81f43168F9F45211Eb027b9aC7cc;
    address internal constant DVN_SUPERFORM = 0xEb62f578497Bdc351dD650853a751135212fAF49;

    string internal outputPath;

    function run() public {
        require(DVN_LZ < DVN_NETHERMIND && DVN_NETHERMIND < DVN_GOOGLE && DVN_GOOGLE < DVN_SUPERFORM, "DVNs not sorted");

        outputPath = string.concat(vm.projectRoot(), "/script/output/dvn-calldata-base.md");

        address[] memory dvns = new address[](4);
        dvns[0] = DVN_LZ;
        dvns[1] = DVN_NETHERMIND;
        dvns[2] = DVN_GOOGLE;
        dvns[3] = DVN_SUPERFORM;

        _writeHeader(dvns);
        _writeSendConfig("ETH", ETH_EID, dvns, 10);
        _writeSendConfig("HyperEVM", HYPEREVM_EID, dvns, 10);
        _writeSendConfig("Flare", FLARE_EID, dvns, 10);

        console2.log("Written to:", outputPath);
    }

    function _writeHeader(address[] memory dvns) internal {
        vm.writeFile(outputPath, "# DVN Update Calldata - Base (Send Only)\n\n");
        _append("## How to Execute on Basescan\n\n");
        _append(string.concat("1. Go to LZ Endpoint on Basescan: `", vm.toString(LZ_ENDPOINT), "`\n"));
        _append("2. Navigate to **Contract** > **Write as Proxy** tab\n");
        _append("3. Connect your wallet\n");
        _append("4. Find function **`setConfig`** (function #12)\n");
        _append("5. For each transaction below, paste the parameters into the form fields\n");
        _append("6. Alternatively, use the **Write Contract** tab and paste the **Full calldata** directly\n\n");
        _append("---\n\n");
        _append(string.concat("**Target:** LZ Endpoint [`", vm.toString(LZ_ENDPOINT), "`](https://basescan.org/address/", vm.toString(LZ_ENDPOINT), "#writeProxyContract)\n\n"));
        _append(string.concat("**OApp:** UpOFT `", vm.toString(UP_OFT), "`\n\n"));
        _append(string.concat("**Send Library:** `", vm.toString(SEND_LIB), "`\n\n"));
        _append("**DVNs (4 required, sorted ascending):**\n\n");
        _append("| # | DVN | Address |\n|---|-----|-------|\n");
        _append(string.concat("| 1 | LayerZero Labs | `", vm.toString(dvns[0]), "` |\n"));
        _append(string.concat("| 2 | Nethermind | `", vm.toString(dvns[1]), "` |\n"));
        _append(string.concat("| 3 | Google Cloud | `", vm.toString(dvns[2]), "` |\n"));
        _append(string.concat("| 4 | Superform | `", vm.toString(dvns[3]), "` |\n\n---\n\n"));
    }

    function _writeSendConfig(string memory name, uint32 remoteEid, address[] memory dvns, uint64 confirmations)
        internal
    {
        UlnConfig memory uln = _makeUlnConfig(confirmations, dvns);
        SetConfigParam[] memory params = new SetConfigParam[](1);
        params[0] = SetConfigParam(remoteEid, ULN_CONFIG_TYPE, abi.encode(uln));
        bytes memory cd = abi.encodeWithSignature(
            "setConfig(address,address,(uint32,uint32,bytes)[])", UP_OFT, SEND_LIB, params
        );

        _append(string.concat("## TX: Base -> ", name, " Send Config\n\n"));
        _append(string.concat("Sets send-side DVNs for the Base -> ", name, " pathway (", vm.toString(uint256(confirmations)), " Base block confirmations)\n\n"));
        _append("### Basescan `setConfig` form fields\n\n");
        _append(string.concat("**`_oapp` (address):**\n```\n", vm.toString(UP_OFT), "\n```\n\n"));
        _append(string.concat("**`_lib` (address):**\n```\n", vm.toString(SEND_LIB), "\n```\n\n"));
        _append(string.concat("**`_params` (tuple[]):** paste this JSON into the field:\n```\n[[", vm.toString(uint256(remoteEid)), ",2,\"", vm.toString(abi.encode(uln)), "\"]]\n```\n\n"));
        _append(string.concat("**Full calldata (alternative - paste into raw tx input):**\n```\n", vm.toString(cd), "\n```\n\n---\n\n"));
    }

    function _append(string memory data) internal {
        vm.writeLine(outputPath, data);
    }

    function _makeUlnConfig(uint64 confirmations, address[] memory dvns) internal pure returns (UlnConfig memory) {
        return UlnConfig({
            confirmations: confirmations,
            requiredDVNCount: 4,
            optionalDVNCount: 0,
            optionalDVNThreshold: 0,
            requiredDVNs: dvns,
            optionalDVNs: new address[](0)
        });
    }
}
