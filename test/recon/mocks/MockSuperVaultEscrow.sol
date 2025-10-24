// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MockSuperVaultEscrow {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of escrowShares
    function escrowShares(address from, uint256 amount) public {}

    // Mock implementation of initialize
    function initialize(address vaultAddress, address strategyAddress) public {}

    // Mock implementation of returnShares
    function returnShares(address to, uint256 amount) public {}

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for initialized
    function setInitializedReturn(bool _value0) public {
        _initializedReturn_0 = _value0;
    }

    // Function to set return values for strategy
    function setStrategyReturn(address _value0) public {
        _strategyReturn_0 = _value0;
    }

    // Function to set return values for vault
    function setVaultReturn(address _value0) public {
        _vaultReturn_0 = _value0;
    }

    /*******************************************************************
     *   ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️ WARNING ⚠️  *
     *-----------------------------------------------------------------*
     *      Generally you only need to modify the sections above.      *
     *          The code below handles system operations.              *
     *******************************************************************/

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  STRUCT DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    bool private _initializedReturn_0;
    address private _strategyReturn_0;
    address private _vaultReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of initialized
    function initialized() public view returns (bool) {
        return _initializedReturn_0;
    }

    // Mock implementation of strategy
    function strategy() public view returns (address) {
        return _strategyReturn_0;
    }

    // Mock implementation of vault
    function vault() public view returns (address) {
        return _vaultReturn_0;
    }
}
