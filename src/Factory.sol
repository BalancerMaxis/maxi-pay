// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import { Vester } from "./Vester.sol";
import "./interfaces/IFactory.sol";

contract Factory is Ownable, IFactory {
    using Clones for address;
    //////////////////////////////////////////////////////////////////
    //                         Constants                            //
    //////////////////////////////////////////////////////////////////

    address public constant MAXIS_OPS = address(0x5891b90CE909d4c3540d640d2BdAAF3fD5157EAD);
    //////////////////////////////////////////////////////////////////
    //                         Storage                              //
    //////////////////////////////////////////////////////////////////
    address public implementation;
    // User -> vesting contracts deployed
    mapping(address => address[]) public vestingContracts;
    //////////////////////////////////////////////////////////////////
    //                         Events                               //
    //////////////////////////////////////////////////////////////////

    event LogImplementationChanged(address indexed oldImplementation, address indexed newImplementation);
    event LogVestingContractDeployed(address indexed vestingContract, address indexed owner);

    /// @notice Factory constructor
    /// @param _implementation Address of the implementation
    constructor(address _implementation) Ownable() {
        implementation = _implementation;
        _transferOwnership(MAXIS_OPS);
    }

    /// @notice Set implementation address
    /// @param _implementation Address of the implementation
    function setImplementation(address _implementation) public onlyOwner {
        implementation = _implementation;
        emit LogImplementationChanged(implementation, _implementation);
    }

    /// @notice Get implementation address
    function getImplementation() public view returns (address) {
        return implementation;
    }

    function getVestingContracts(address _user) public view returns (address[] memory) {
        return vestingContracts[_user];
    }

    /// @notice Deploy a new vesting contract
    function deployVestingContract(address _beneficiary) public onlyOwner returns (address vestingContract) {
        vestingContract = implementation.clone();
        Vester(vestingContract).initialise(_beneficiary);
        // Put vesting contract in mapping
        vestingContracts[_beneficiary].push(vestingContract);
        emit LogVestingContractDeployed(vestingContract, _beneficiary);
    }
}
