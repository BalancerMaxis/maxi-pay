// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IVester {
    /// @notice Vesting position struct
    struct VestingPosition {
        uint256 amount;
        uint256 vestingEnds;
        bool claimed;
    }

    /// @notice Set beneficiary address
    function setBeneficiary(address _beneficiary) external;

    /// @notice Get next nonce
    function getVestingNonce() external view returns (uint256);

    /// @notice Get vesting position by nonce
    function getVestingPosition(uint256 _nonce) external view returns (VestingPosition memory);

    /// @notice Deposit with custom vesting period
    function deposit(uint256 _amount, uint256 _vestingPeriod) external;

    /// @notice Deposit with default vesting period
    function deposit(uint256 _amount) external;

    /// @notice Withdraw tokens
    function ragequit(address _to) external;

    /// @notice Claim vesting position
    function claim(uint256 _nonce) external;
}
