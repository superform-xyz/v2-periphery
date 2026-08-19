// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.30;

import { DeployV2Base } from "./DeployV2Base.s.sol";
import { SuperGovernor } from "../src/SuperGovernor.sol";
import { SuperOracle } from "../src/oracles/SuperOracle.sol";
import { BasefeeGasOracle } from "../src/oracles/BasefeeGasOracle.sol";
import { AggregatorV3Interface } from "../src/vendor/chainlink/AggregatorV3Interface.sol";
import { console2 } from "forge-std/console2.sol";

/// @title UpdateGasOracle
/// @notice Governance script migrating the upkeep gas pricing off the deprecated Chainlink
///         Fast Gas feed: registers BasefeeGasOracle for GAS_QUOTE -> WEI_QUOTE under the
///         SUPERFORM provider (additive - the CHAINLINK slot is untouched and drops out of
///         the AVERAGE automatically once the feed freezes and exceeds staleness).
/// @dev Mainnet only. Flow (1-week SuperOracle timelock between the two steps):
///        1. runQueue(env, 1)                      - queues via SuperGovernor.queueOracleUpdate
///        2. runFinalize(env, 1, queueTimestamp)   - executes after the timelock
///      Safety rails (see specs/basefee-gas-oracle):
///        - queue: on-chain unit-parity check of the new oracle vs the live Fast Gas feed
///        - queue: logs the pending-update timestamp; SuperOracle has ONE global pending slot
///          with no collision guard, so no other queueOracleUpdate may happen until finalize
///        - finalize: requires pendingUpdate.timestamp still matches the recorded queue
///          timestamp (detects a clobbered slot), then post-verifies the registration and
///          that the upkeep cost stays within the [0.2x, 3x] acceptance band
///      Caller must hold ORACLE_MANAGER_ROLE; if the broadcaster has DEFAULT_ADMIN_ROLE
///      instead, the role is granted temporarily and revoked after (SetGasInfo pattern).
///
///      PRODUCTION NOTE (verified on-chain 2026-08-19): on mainnet SuperGovernor
///      (0xB5396ef2...74d4) DEFAULT_ADMIN_ROLE has been renounced and ORACLE_MANAGER_ROLE
///      is held solely by the Fireblocks-managed signer configured in v2-toolbox. The
///      temp-grant fallback therefore CANNOT work on prod. Use this script for check and
///      simulation rehearsal; broadcast the real queue/execute via v2-toolbox's
///      `queue_oracle_update` / `execute_oracle_update` scripts (Fireblocks signing).
contract UpdateGasOracle is DeployV2Base {
    /*//////////////////////////////////////////////////////////////
                            MAIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Queue the BasefeeGasOracle registration (step 1 of 2)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    function runQueue(uint256 env, uint64 chainId) external broadcast(env) {
        (SuperGovernor governor, SuperOracle superOracle, address basefeeOracle,) = _setup(env, chainId);

        console2.log("=== Queue BasefeeGasOracle registration ===");

        // Pre-checks on the new oracle
        require(basefeeOracle.code.length > 0, "BASEFEE_ORACLE_NOT_DEPLOYED");
        require(BasefeeGasOracle(basefeeOracle).decimals() == 0, "DECIMALS_MISMATCH");
        _checkUnitParity(basefeeOracle);

        // The SUPERFORM slot for the pair must be empty (this is an additive registration;
        // a non-empty slot means something already lives there - investigate before queueing)
        try superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM) returns (address existing) {
            console2.log("[WARNING] SUPERFORM gas slot already registered:", existing);
            require(existing == basefeeOracle, "SUPERFORM_SLOT_OCCUPIED_BY_OTHER_FEED");
            console2.log("[WARNING] Slot already holds BasefeeGasOracle - re-queue will refresh it");
        } catch {
            console2.log("SUPERFORM gas slot empty (expected) - proceeding");
        }

        // Warn if another update is already pending - queueing OVERWRITES it silently
        uint256 existingPending = superOracle.pendingUpdate();
        if (existingPending != 0) {
            console2.log("[WARNING] A pending oracle update already exists (timestamp):", existingPending);
            console2.log("[WARNING] Queueing now will silently DISCARD it. Aborting.");
            revert("PENDING_UPDATE_SLOT_OCCUPIED");
        }

        bool hadRole = _ensureOracleManagerRole(governor);

        // Queue the additive registration
        address[] memory bases = new address[](1);
        address[] memory quotes = new address[](1);
        bytes32[] memory providers = new bytes32[](1);
        address[] memory feeds = new address[](1);
        bases[0] = GAS_QUOTE;
        quotes[0] = WEI_QUOTE;
        providers[0] = PROVIDER_SUPERFORM;
        feeds[0] = basefeeOracle;

        governor.queueOracleUpdate(bases, quotes, providers, feeds);

        uint256 queuedAt = superOracle.pendingUpdate();
        require(queuedAt != 0, "QUEUE_FAILED");

        _restoreOracleManagerRole(governor, hadRole);

        console2.log("");
        console2.log("=== Queued successfully ===");
        console2.log("Queue timestamp (SAVE THIS for runFinalize):", queuedAt);
        console2.log("Executable after:", queuedAt + 1 weeks);
        console2.log("");
        console2.log("[RUNBOOK] Until finalize, NO other queueOracleUpdate may be submitted -");
        console2.log("[RUNBOOK] the pending slot is global and overwrites without reverting.");
    }

    /// @notice Execute the queued registration after the timelock (step 2 of 2)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    /// @param queueTimestamp The timestamp logged by runQueue (0 skips the clobber guard - discouraged)
    function runFinalize(uint256 env, uint64 chainId, uint256 queueTimestamp) external broadcast(env) {
        (SuperGovernor governor, SuperOracle superOracle, address basefeeOracle, address ppsOracle) =
            _setup(env, chainId);

        console2.log("=== Finalize BasefeeGasOracle registration ===");

        // Clobber guard: the pending slot must still hold OUR queue
        uint256 pendingTs = superOracle.pendingUpdate();
        require(pendingTs != 0, "NO_PENDING_UPDATE");
        if (queueTimestamp == 0) {
            console2.log("[WARNING] Clobber guard skipped (queueTimestamp = 0)");
            console2.log("[WARNING] Pending timestamp is:", pendingTs);
        } else {
            require(pendingTs == queueTimestamp, "PENDING_UPDATE_CLOBBERED");
            console2.log("Clobber guard passed - pending update is ours (timestamp):", pendingTs);
        }
        require(block.timestamp >= pendingTs + 1 weeks, "TIMELOCK_NOT_ELAPSED_YET");

        // Acceptance baseline: upkeep cost before the swap (Fast-Gas-driven or free if already dead)
        uint256 costBefore = _tryUpkeepCost(governor, ppsOracle);
        console2.log("Upkeep cost before execute (UP, 0 = reverting):", costBefore);

        bool hadRole = _ensureOracleManagerRole(governor);
        governor.executeOracleUpdate();
        _restoreOracleManagerRole(governor, hadRole);

        // Post-verify the registration landed
        address registered = superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, PROVIDER_SUPERFORM);
        require(registered == basefeeOracle, "REGISTRATION_MISMATCH");
        console2.log("SUPERFORM gas slot now:", registered);

        // Acceptance band: [0.2x, 3x] of the pre-execute cost (skip if it was reverting/free -
        // then the only requirement is that charging works again)
        uint256 costAfter = _tryUpkeepCost(governor, ppsOracle);
        console2.log("Upkeep cost after execute (UP):", costAfter);
        require(costAfter > 0, "UPKEEP_COST_ZERO_AFTER_MIGRATION");
        if (costBefore > 0) {
            require(costAfter <= costBefore * 3, "COST_ABOVE_3X_BAND");
            require(costAfter * 5 >= costBefore, "COST_BELOW_0_2X_BAND");
            console2.log("Cost within [0.2x, 3x] acceptance band");
        } else {
            console2.log("Pre-execute cost was zero/reverting (Fast Gas dead) - charging restored");
        }

        console2.log("");
        console2.log("=== Migration complete ===");
        console2.log("[RUNBOOK] Fill ConfigBase.ORACLE_BASEFEE_GAS_MAINNET with:", basefeeOracle);
    }

    /// @notice Read-only status of the migration (no roles required)
    /// @param env Environment (0 = production, 2 = staging)
    /// @param chainId Chain ID (must be mainnet = 1)
    function runCheck(uint256 env, uint64 chainId) external broadcast(env) {
        (SuperGovernor governor, SuperOracle superOracle, address basefeeOracle, address ppsOracle) =
            _setup(env, chainId);

        console2.log("=== BasefeeGasOracle migration status ===");

        console2.log("CHAINLINK gas slot:", _slotOrZero(superOracle, PROVIDER_CHAINLINK));
        console2.log("SUPERFORM gas slot:", _slotOrZero(superOracle, PROVIDER_SUPERFORM));
        console2.log("Expected BasefeeGasOracle:", basefeeOracle);
        console2.log("BasefeeGasOracle deployed:", basefeeOracle.code.length > 0);

        uint256 pendingTs = superOracle.pendingUpdate();
        if (pendingTs == 0) {
            console2.log("Pending oracle update: none");
        } else {
            console2.log("Pending oracle update queued at:", pendingTs);
            uint256 executableAt = pendingTs + 1 weeks;
            if (block.timestamp >= executableAt) {
                console2.log("Timelock ELAPSED - executable now");
            } else {
                console2.log("Timelock remaining (seconds):", executableAt - block.timestamp);
            }
        }

        // Live feed comparison
        (, int256 fastGasAnswer,, uint256 fastGasUpdatedAt,) =
            AggregatorV3Interface(ORACLE_GAS_TO_ETH).latestRoundData();
        console2.log("Fast Gas answer (wei/gas):", uint256(fastGasAnswer));
        console2.log("Fast Gas age (seconds):", block.timestamp - fastGasUpdatedAt);
        if (basefeeOracle.code.length > 0) {
            console2.log("BasefeeGasOracle answer (wei/gas):", uint256(BasefeeGasOracle(basefeeOracle).latestAnswer()));
            console2.log("(0-basefee note: real answer only visible on-chain / in fork context)");
        }

        console2.log("Upkeep cost per single update (UP, 0 = reverting):", _tryUpkeepCost(governor, ppsOracle));
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Shared setup: validates mainnet, resolves all contract addresses from output JSON
    function _setup(
        uint256 env,
        uint64 chainId
    )
        internal
        returns (SuperGovernor governor, SuperOracle superOracle, address basefeeOracle, address ppsOracle)
    {
        _setBaseConfiguration(env, "");
        require(chainId == MAINNET_CHAIN_ID, "GAS_ORACLE_MIGRATION_MAINNET_ONLY");

        string memory peripheryJson = _readPeripheryContractsFromOutput(chainId, env);
        require(bytes(peripheryJson).length > 0, "DEPLOYMENT_FILE_NOT_FOUND");

        address governorAddr = _safeParseJsonAddress(peripheryJson, ".SuperGovernor");
        address superOracleAddr = _safeParseJsonAddress(peripheryJson, ".SuperOracle");
        basefeeOracle = _safeParseJsonAddress(peripheryJson, ".BasefeeGasOracle");
        ppsOracle = _safeParseJsonAddress(peripheryJson, ".ECDSAPPSOracle");

        require(governorAddr != address(0), "SUPER_GOVERNOR_NOT_FOUND");
        require(superOracleAddr != address(0), "SUPER_ORACLE_NOT_FOUND");
        require(basefeeOracle != address(0), "BASEFEE_ORACLE_NOT_IN_OUTPUT_JSON");
        require(ppsOracle != address(0), "ECDSA_PPS_ORACLE_NOT_FOUND");

        governor = SuperGovernor(governorAddr);
        superOracle = SuperOracle(superOracleAddr);

        console2.log("SuperGovernor:", governorAddr);
        console2.log("SuperOracle:", superOracleAddr);
        console2.log("BasefeeGasOracle:", basefeeOracle);
        console2.log("");
    }

    /// @notice On-chain unit-parity guard: the new oracle must be in the same unit as Fast Gas.
    ///         A 1e9 wei/gwei confusion in either direction fails the [0.2x, 5x] band.
    ///         Enforced only while the Fast Gas feed is fresh; warns once it has frozen.
    function _checkUnitParity(address basefeeOracle) internal view {
        (, int256 fastGasAnswer,, uint256 updatedAt,) = AggregatorV3Interface(ORACLE_GAS_TO_ETH).latestRoundData();
        int256 ourAnswer = BasefeeGasOracle(basefeeOracle).latestAnswer();
        console2.log("Fast Gas answer (wei/gas):", uint256(fastGasAnswer));
        console2.log("BasefeeGasOracle answer (wei/gas):", uint256(ourAnswer));

        if (block.timestamp - updatedAt > 1 days) {
            console2.log("[WARNING] Fast Gas feed is stale (deprecated?) - unit parity check skipped");
            return;
        }
        require(fastGasAnswer > 0 && ourAnswer > 0, "NON_POSITIVE_ANSWER");
        require(uint256(ourAnswer) <= uint256(fastGasAnswer) * 5, "UNIT_PARITY_FAILED_TOO_HIGH");
        require(uint256(ourAnswer) * 5 >= uint256(fastGasAnswer), "UNIT_PARITY_FAILED_TOO_LOW");
        console2.log("Unit parity check passed");
    }

    /// @notice Ensure the broadcaster can call the ORACLE_MANAGER_ROLE-gated functions,
    ///         temporarily granting the role via DEFAULT_ADMIN_ROLE if needed
    /// @return hadRole Whether the broadcaster already held the role (skip revoke if so)
    function _ensureOracleManagerRole(SuperGovernor governor) internal returns (bool hadRole) {
        bytes32 role = governor.ORACLE_MANAGER_ROLE();
        hadRole = governor.hasRole(role, configuration.deployer);
        if (!hadRole) {
            require(
                governor.hasRole(governor.DEFAULT_ADMIN_ROLE(), configuration.deployer),
                "BROADCASTER_LACKS_ORACLE_MANAGER_AND_ADMIN"
            );
            console2.log("Temporarily granting ORACLE_MANAGER_ROLE to broadcaster");
            governor.grantRole(role, configuration.deployer);
        }
    }

    /// @notice Revoke the temporarily granted role (no-op if it was already held)
    function _restoreOracleManagerRole(SuperGovernor governor, bool hadRole) internal {
        if (!hadRole) {
            console2.log("Revoking temporary ORACLE_MANAGER_ROLE from broadcaster");
            governor.revokeRole(governor.ORACLE_MANAGER_ROLE(), configuration.deployer);
        }
    }

    /// @notice Upkeep cost that returns 0 instead of reverting (matches updatePPS's try/catch view)
    function _tryUpkeepCost(SuperGovernor governor, address ppsOracle) internal view returns (uint256) {
        try governor.getUpkeepCostPerSingleUpdate(ppsOracle) returns (uint256 cost) {
            return cost;
        } catch {
            return 0;
        }
    }

    /// @notice Registered feed for the gas pair under a provider, or address(0) if none
    function _slotOrZero(SuperOracle superOracle, bytes32 provider) internal view returns (address) {
        try superOracle.getOracleAddress(GAS_QUOTE, WEI_QUOTE, provider) returns (address feed) {
            return feed;
        } catch {
            return address(0);
        }
    }

    /// @notice Read periphery contracts from output files
    function _readPeripheryContractsFromOutput(uint64 chainId, uint256 env) internal view returns (string memory) {
        string memory envName = env == 0 ? "prod" : "staging";
        string memory outputPath = string(
            abi.encodePacked(
                vm.projectRoot(),
                "/script/output/",
                envName,
                "/",
                vm.toString(uint256(chainId)),
                "/",
                chainNames[chainId],
                "-latest.json"
            )
        );
        console2.log("Reading deployment file:", outputPath);
        try vm.readFile(outputPath) returns (string memory fileContent) {
            return fileContent;
        } catch {
            return "";
        }
    }

    /// @notice Safely parse an address from JSON
    function _safeParseJsonAddress(string memory json, string memory key) internal pure returns (address) {
        try vm.parseJsonAddress(json, key) returns (address addr) {
            return addr;
        } catch {
            return address(0);
        }
    }
}
