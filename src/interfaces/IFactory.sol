// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IFactory {
    /// @notice Get implementation address
    function getImplementation() external view returns (address);
    /// @notice Deploy a new vesting contract
    function deployVestingContract(address _beneficiary) external returns (address vestingContract);
    /// @notice Get vesting contracts deployed for a user
    function getVestingContracts(address _user) external view returns (address[] memory);
    /// @notice Set implementation address
    function setImplementation(address _implementation) external;
}
