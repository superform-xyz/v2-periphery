// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

/// @notice Settable AUM-oracle stand-in for cap-guard tests (isAUMFresh + getTotalAUM).
contract MockAumOracleLite {
    mapping(address => bool) public fresh;
    mapping(address => uint256) public total;

    function setFresh(address s, bool f) external {
        fresh[s] = f;
    }

    function setTotal(address s, uint256 t) external {
        total[s] = t;
    }

    function isAUMFresh(address s) external view returns (bool) {
        return fresh[s];
    }

    function getTotalAUM(address s) external view returns (uint256) {
        return total[s];
    }
}

/// @notice Settable registry exposure stand-in for cap-guard tests.
contract MockRegistryExposureLite {
    mapping(address => uint256) internal _eff;
    mapping(address => mapping(uint64 => uint256)) internal _effChain;

    function setEff(address s, uint256 v) external {
        _eff[s] = v;
    }

    function setEffChain(address s, uint64 c, uint256 v) external {
        _effChain[s][c] = v;
    }

    function getEffectiveCrossChainExposure(address s) external view returns (uint256) {
        return _eff[s];
    }

    function getEffectiveChainExposure(address s, uint64 c) external view returns (uint256) {
        return _effChain[s][c];
    }
}

/// @notice Settable aggregator stand-in (isMainManager + isPPSStale for the K2 backstop).
contract MockAggregatorLite {
    mapping(bytes32 => bool) internal _mm;
    mapping(address => bool) public isPPSStale;

    function setMainManager(address m, address s, bool ok) external {
        _mm[keccak256(abi.encode(m, s))] = ok;
    }

    function isMainManager(address m, address s) external view returns (bool) {
        return _mm[keccak256(abi.encode(m, s))];
    }

    function setPPSStale(address s, bool stale) external {
        isPPSStale[s] = stale;
    }
}

/// @notice K2 fixtures: a strategy exposing getVaultInfo and a vault exposing totalAssets — the
///         PPS x supply implied-assets source the AUM oracle reads.
contract MockVaultLite {
    uint256 public totalAssets;

    function setTotalAssets(uint256 v) external {
        totalAssets = v;
    }
}

contract MockStrategyWithVault {
    address public vaultAddr;

    function setVault(address v) external {
        vaultAddr = v;
    }

    function getVaultInfo() external view returns (address vault, address asset, uint8 vaultDecimals) {
        return (vaultAddr, address(0), 18);
    }
}
