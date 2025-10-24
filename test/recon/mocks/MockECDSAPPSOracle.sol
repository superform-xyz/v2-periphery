// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ISuperVaultAggregator} from "src/interfaces/SuperVault/ISuperVaultAggregator.sol";
import {IECDSAPPSOracle} from "src/interfaces/oracles/IECDSAPPSOracle.sol";

contract MockECDSAPPSOracle {
    //<>=============================================================<>
    //||                                                             ||
    //||                    NON-VIEW FUNCTIONS                       ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of updatePPS
    function updatePPS(IECDSAPPSOracle.UpdatePPSArgs memory args) public {
        ISuperVaultAggregator.ForwardPPSArgs
            memory forwardArgs = ISuperVaultAggregator.ForwardPPSArgs({
                strategies: args.strategies,
                ppss: args.ppss,
                ppsStdevs: args.ppsStdevs,
                validatorSets: args.validatorSets,
                totalValidators: args.totalValidators,
                timestamps: args.timestamps,
                updateAuthority: msg.sender
            });

        ISuperVaultAggregator(_SUPER_GOVERNORReturn_0).forwardPPS(forwardArgs);
    }

    //<>=============================================================<>
    //||                                                             ||
    //||                    SETTER FUNCTIONS                         ||
    //||                                                             ||
    //<>=============================================================<>
    // Function to set return values for SUPER_GOVERNOR
    function setSUPER_GOVERNORReturn(address _value0) public {
        _SUPER_GOVERNORReturn_0 = _value0;
    }

    // Function to set return values for UPDATE_PPS_TYPEHASH
    function setUPDATE_PPS_TYPEHASHReturn(bytes32 _value0) public {
        _UPDATE_PPS_TYPEHASHReturn_0 = _value0;
    }

    // Function to set return values for domainSeparator
    function setDomainSeparatorReturn(bytes32 _value0) public {
        _domainSeparatorReturn_0 = _value0;
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
    // Struct definition removed - using IECDSAPPSOracle.UpdatePPSArgs from interface

    //<>=============================================================<>
    //||                                                             ||
    //||        ⚠️  EVENTS DEFINITIONS - DO NOT MODIFY  ⚠️          ||
    //||                                                             ||
    //<>=============================================================<>
    event EIP712DomainChanged();
    event PPSValidated(
        address strategy,
        uint256 pps,
        uint256 ppsStdev,
        uint256 validatorSet,
        uint256 totalValidators,
        uint256 timestamp,
        address sender
    );

    //<>=============================================================<>
    //||                                                             ||
    //||         ⚠️  INTERNAL STORAGE - DO NOT MODIFY  ⚠️           ||
    //||                                                             ||
    //<>=============================================================<>
    address private _SUPER_GOVERNORReturn_0;
    bytes32 private _UPDATE_PPS_TYPEHASHReturn_0;
    bytes32 private _domainSeparatorReturn_0;
    bytes1 private _eip712DomainReturn_0;
    string private _eip712DomainReturn_1;
    string private _eip712DomainReturn_2;
    uint256 private _eip712DomainReturn_3;
    address private _eip712DomainReturn_4;
    bytes32 private _eip712DomainReturn_5;
    uint256[] private _eip712DomainReturn_6;
    uint256 private _nonceReturn_0;

    //<>=============================================================<>
    //||                                                             ||
    //||          ⚠️  VIEW FUNCTIONS - DO NOT MODIFY  ⚠️            ||
    //||                                                             ||
    //<>=============================================================<>
    // Mock implementation of SUPER_GOVERNOR
    function SUPER_GOVERNOR() public view returns (address) {
        return _SUPER_GOVERNORReturn_0;
    }

    // Mock implementation of UPDATE_PPS_TYPEHASH
    function UPDATE_PPS_TYPEHASH() public view returns (bytes32) {
        return _UPDATE_PPS_TYPEHASHReturn_0;
    }

    // Mock implementation of domainSeparator
    function domainSeparator() public view returns (bytes32) {
        return _domainSeparatorReturn_0;
    }

    // Mock implementation of eip712Domain
    function eip712Domain()
        public
        view
        returns (
            bytes1,
            string memory,
            string memory,
            uint256,
            address,
            bytes32,
            uint256[] memory
        )
    {
        return (
            _eip712DomainReturn_0,
            _eip712DomainReturn_1,
            _eip712DomainReturn_2,
            _eip712DomainReturn_3,
            _eip712DomainReturn_4,
            _eip712DomainReturn_5,
            _eip712DomainReturn_6
        );
    }

    // Mock implementation of nonce
    function nonce() public view returns (uint256) {
        return _nonceReturn_0;
    }
}
