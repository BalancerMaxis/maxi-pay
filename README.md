## Balancer Maxis Vesting Factory for Arbitrum

## What is this?
This repo contains Factory that deploys vesting contracts for Balancer Maxis.

Deployed vesting contract accepts staked auraBAL tokens that accrues auraBAL rewards and generates AURA rewards.

Once vesting period is over, user can claim their staked auraBAL tokens(plus accrued auraBAL rewards) and AURA rewards.

**NOTE**: Vesting contracts accept NOT naked auraBAL tokens, but staked pounder auraBAL tokens at this [address](https://arbiscan.io/address/0x4EA9317D90b61fc28C418C247ad0CA8939Bbb0e9)

---

## How to use
1. Deploy factory contract. Once deployed, ownership of the contract is transferred to multisig
2. All deployed vesting contracts are stored in `factory.vestingContracts` mapping. You can get all deployed vesting contracts using: `factory.getVestingContracts(address _beneficiary)`
3. At this stage, owner of the factory can deploy vesting contracts for any address using: `factory.deployVestingContract(address _beneficiary)`
4. Once vesting contract is deployed, vesting contract can be topped up with auraBAL tokens using: `vestingContract.deposit(uint256 _amount)`
or `vestingContract.deposit(uint256 _amount, uint256 _vestingPeriod)` if you wanna specify custom vesting period(not 365 days).
5. Each deposit is a separate nonce stored in `vester.vestingPositions` mapping. Each new deposit will increase internal nonce counter - `vestingContract.vestingNonce`.
6. Once vesting period is over, user can claim their staked auraBAL tokens(plus accrued auraBAL rewards) and AURA rewards using: `vestingContract.claim(uint256 _nonce)`.

**NOTE**: Single user's vesting contract can have as many vesting positions as needed. Each vesting position can be claimed separately once specific vesting period is over.

### Ragequit:
If anything goes wrong, owner of the factory can ragequit and withdraw all auraBAL tokens from vesting contracts using: `vestingContract.ragequit(address _to)`. 
Pending AURA rewards will be claimed and transferred to `address _to` as well.

### Upgrading vesting contract implementation
Simply deploy new implementation and pass it to `factory.setImplementation(address _newImplementation)` from the owner of the factory.

**NOTE**: Implementation upgrade is not retroactive. All previously deployed vesting contracts will use old implementation.

### TL;DR:
Check this script for usage example: [Usage Example](https://github.com/BalancerMaxis/maxi-pay/blob/main/script/UsageExample.sol)


## Interfaces:

### Factory
```solidity
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
```

### Vesting contract
```solidity
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
```

## Building and running tests:
1. Create `.env` file and place `ALCHEMY_API_KEY={YOUR KEY HERE}` env var there for Arbitrum
2. Run `forge build` to build contracts
3. Run `forge test` to run test suite
4. Run `forge coverage` to run test suite with coverage

**NOTE**: Tests are running on forked Arbitrum mainnet on block 137_047_782