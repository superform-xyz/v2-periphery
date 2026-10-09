// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

/// @notice Shared schema-1 vector from Bundler's pkg/erc8021/testdata/builder_codes.json.
/// @dev Registry 0xcccc…cccc on Base (8453), code "baseapp". Test-only: Bundler owns encoding.
library BuilderCodeFixtures {
    function suffix() internal pure returns (bytes memory) {
        return hex"cccccccccccccccccccccccccccccccccccccccc21050262617365617070070180218021802180218021802180218021";
    }
}
