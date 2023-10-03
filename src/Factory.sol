// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/openzeppelin-contracts/contracts/proxy/Clones.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Vester} from "./Vester.sol";

contract Factory is Ownable {
    using Clones for address;
    //////////////////////////////////////////////////////////////////
    //                         Constants                            //
    //////////////////////////////////////////////////////////////////

    address public constant DAO_MSIG = address(1337);

    //////////////////////////////////////////////////////////////////
    //                         Storage                              //
    //////////////////////////////////////////////////////////////////
    address public implementation;

    //////////////////////////////////////////////////////////////////
    //                         Events                               //
    //////////////////////////////////////////////////////////////////
    event LogImplementationChanged(address indexed oldImplementation, address indexed newImplementation);
    event LogVestingContractDeployed(address indexed vestingContract, address indexed owner);

    /// @notice Factory constructor
    /// @param _implementation Address of the implementation
    constructor(address _implementation) Ownable() {
        address oldImplementation = implementation;
        implementation = _implementation;
        emit LogImplementationChanged(oldImplementation, _implementation);
        // Transfer ownership of this contract to DAO multisig
        transferOwnership(DAO_MSIG);
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

    /// @notice Deploy a new vesting contract
    function deployVestingContract(address _owner) public onlyOwner returns (address vestingContract) {
        vestingContract = implementation.clone();
        Vester(vestingContract).initialise(_owner, DAO_MSIG);
        emit LogVestingContractDeployed(vestingContract, _owner);
    }
}
