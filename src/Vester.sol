// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

library VesterErrors {
    error NotDaoMsig();
    error NotBeneficiary();
}

contract Vester is Initializable {
    using SafeERC20 for ERC20;
    //////////////////////////////////////////////////////////////////
    //                         Constants                            //
    //////////////////////////////////////////////////////////////////

    ERC20 public constant STAKED_AURABAL = ERC20(address(0x95c1D2014909c04202fa73820B894b45F054F25e));
    address public constant DAO_MSIG = address(0xaF23DC5983230E9eEAf93280e312e57539D098D0);
    //////////////////////////////////////////////////////////////////
    //                         Storage                              //
    //////////////////////////////////////////////////////////////////
    address public beneficiary;

    //////////////////////////////////////////////////////////////////
    //                         Events                               //
    //////////////////////////////////////////////////////////////////
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);

    /// @notice Contract initializer
    /// @param _beneficiary Address of the beneficiary that will be able to claim tokens
    function initialise(address _beneficiary) public initializer {
        beneficiary = _beneficiary;
    }

    //////////////////////////////////////////////////////////////////
    //                       Modifiers                              //
    //////////////////////////////////////////////////////////////////

    modifier onlyBeneficiary() {
        if (msg.sender != beneficiary) {
            revert VesterErrors.NotBeneficiary();
        }
        _;
    }

    modifier onlyDaoMsig() {
        if (msg.sender != DAO_MSIG) {
            revert VesterErrors.NotDaoMsig();
        }
        _;
    }

    //////////////////////////////////////////////////////////////////
    //                   Permissioned Setters                       //
    //////////////////////////////////////////////////////////////////
    function setBeneficiary(address _beneficiary) public onlyDaoMsig {
        address oldBeneficiary = beneficiary;
        beneficiary = _beneficiary;
        emit BeneficiaryChanged(oldBeneficiary, _beneficiary);
    }
}
