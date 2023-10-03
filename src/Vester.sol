// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

library VesterErrors {
    error NotDaoMsig();
    error NotBeneficiary();
}

contract Vester is Initializable {
    //////////////////////////////////////////////////////////////////
    //                         Constants                            //
    //////////////////////////////////////////////////////////////////
    address public constant STAKED_AURABAL = address(0x95c1D2014909c04202fa73820B894b45F054F25e);
    //////////////////////////////////////////////////////////////////
    //                         Storage                              //
    //////////////////////////////////////////////////////////////////
    address public beneficiary;
    address public daoMsig;

    //////////////////////////////////////////////////////////////////
    //                         Events                               //
    //////////////////////////////////////////////////////////////////
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Contract initializer
    /// @param _beneficiary Address of the beneficiary that will be able to claim tokens
    /// @param _daoMsig Address of the DAO multisig
    function initialise(address _beneficiary, address _daoMsig) public initializer {
        beneficiary = _beneficiary;
        daoMsig = _daoMsig;
    }

    //////////////////////////////////////////////////////////////////
    //                   Permissioned Setters                       //
    //////////////////////////////////////////////////////////////////
    function setBeneficiary(address _beneficiary) public {
        if (msg.sender != daoMsig) {
            revert VesterErrors.NotDaoMsig();
        }
        address oldBeneficiary = beneficiary;
        beneficiary = _beneficiary;
        emit BeneficiaryChanged(oldBeneficiary, _beneficiary);
    }
}
