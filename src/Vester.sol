// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAuraRewardPool.sol";
import "./interfaces/IVester.sol";

library VesterErrors {
    error NotDaoMsig();
    error NotBeneficiary();
    error NotMaxis();
    error AlreadyClaimed();
    error NotVestedYet();

    error ProtectedToken();
}

/// @title Vester contract
/// @notice Each Maxis User has a personal vesting contract deployed
contract Vester is Initializable, IVester {
    using SafeERC20 for ERC20;

    //////////////////////////////////////////////////////////////////
    //                         Constants                            //
    //////////////////////////////////////////////////////////////////
    ERC20 public constant STAKED_AURABAL = ERC20(address(0x4EA9317D90b61fc28C418C247ad0CA8939Bbb0e9));
    ERC20 public constant AURA = ERC20(address(0x1509706a6c66CA549ff0cB464de88231DDBe213B));

    IAuraRewardPool public constant AURA_REWARD_POOL =
        IAuraRewardPool(address(0x14b820F0F69614761E81ea4431509178dF47bBD3));
    address public constant DAO_MSIG = address(0xaF23DC5983230E9eEAf93280e312e57539D098D0);
    address public constant MAXIS_OPS = address(0x5891b90CE909d4c3540d640d2BdAAF3fD5157EAD);
    uint256 public constant DEFAULT_VESTING_PERIOD = 365 days;
    //////////////////////////////////////////////////////////////////
    //                         Storage                              //
    //////////////////////////////////////////////////////////////////
    address public beneficiary;
    uint256 internal vestingNonce;
    // Mapping for vesting positions
    // Nonce -> VestingPosition
    mapping(uint256 => VestingPosition) internal vestingPositions;

    //////////////////////////////////////////////////////////////////
    //                         Events                               //
    //////////////////////////////////////////////////////////////////
    event BeneficiaryChanged(address indexed oldBeneficiary, address indexed newBeneficiary);
    event VestingPositionCreated(uint256 indexed nonce, uint256 amount, uint256 vestingEnds);
    event Claimed(uint256 indexed nonce, uint256 amount);
    event ClaimedAuraRewards(uint256 amount);
    event Ragequit(address indexed to);
    event Sweep(address indexed token, uint256 amount, address indexed to);

    constructor() {
        // Disable initializers for the implementation contract
        _disableInitializers();
    }

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

    modifier onlyMaxisOps() {
        if (msg.sender != MAXIS_OPS) {
            revert VesterErrors.NotMaxis();
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

    //////////////////////////////////////////////////////////////////
    //                       External functions                     //
    //////////////////////////////////////////////////////////////////
    /// @notice Get current vesting nonce. This nonce represents future vesting position nonce
    /// @dev If needed to check current existing nonce, subtract 1 from this value
    function getVestingNonce() external view returns (uint256) {
        return vestingNonce;
    }

    /// @notice Get vesting position by nonce
    /// @param _nonce Nonce of the vesting position
    function getVestingPosition(uint256 _nonce) external view returns (VestingPosition memory) {
        return vestingPositions[_nonce];
    }

    /// @notice Claim vesting position
    /// @param _nonce Nonce of the vesting position
    function claim(uint256 _nonce) external onlyBeneficiary {
        VestingPosition storage vestingPosition = vestingPositions[_nonce];
        if (vestingPosition.claimed) {
            revert VesterErrors.AlreadyClaimed();
        }
        if (block.timestamp < vestingPosition.vestingEnds) {
            revert VesterErrors.NotVestedYet();
        }
        vestingPosition.claimed = true;
        // Claim AURA rewards
        // TODO: Q: should send all AURA rewards even if there are multiple vesting positions?
        AURA_REWARD_POOL.getReward();
        // Transfer staked AURA BAL to beneficiary
        STAKED_AURABAL.safeTransfer(beneficiary, vestingPosition.amount);
        // Transfer AURA to beneficiary
        AURA.safeTransfer(beneficiary, AURA.balanceOf(address(this)));

        emit Claimed(_nonce, vestingPosition.amount);
    }

    /// @notice Deposit logic but with default vesting period
    /// @param _amount Amount of tokens to deposit
    function deposit(uint256 _amount) external onlyMaxisOps {
        _deposit(_amount, DEFAULT_VESTING_PERIOD);
    }

    /// @notice Deposit logic
    /// @param _amount Amount of tokens to deposit
    /// @param _vestingPeriod Vesting period in seconds
    function deposit(uint256 _amount, uint256 _vestingPeriod) external onlyMaxisOps {
        _deposit(_amount, _vestingPeriod);
    }

    /// @notice DAO msig should be able to sweep any ERC20 tokens except staked aura bal
    /// @param _token Address of the token to sweep
    /// @param _amount Amount of tokens to sweep
    /// @param _to Address to send the tokens to
    function sweep(address _token, uint256 _amount, address _to) external onlyMaxisOps {
        if (_token == address(STAKED_AURABAL)) {
            revert VesterErrors.ProtectedToken();
        }
        ERC20(_token).safeTransfer(_to, _amount);
        emit Sweep(_token, _amount, _to);
    }

    /// @notice Ragequit all AURA BAL and AURA in case of emergency
    /// @dev This function is only callable by the DAO multisig
    /// @param _to Address to send all AURA BAL and AURA to
    function ragequit(address _to) external onlyDaoMsig {
        // Claim rewards and transfer AURA to beneficiary
        AURA_REWARD_POOL.getReward();
        // Transfer staked AURA BAL to beneficiary
        STAKED_AURABAL.safeTransfer(_to, STAKED_AURABAL.balanceOf(address(this)));
        // Transfer AURA to beneficiary
        AURA.safeTransfer(_to, AURA.balanceOf(address(this)));
        emit Ragequit(_to);
    }

    /// @notice Function to claim aura rewards from staked auraBAL
    function claimAuraRewards() external onlyBeneficiary {
        AURA_REWARD_POOL.getReward();
        AURA.safeTransfer(beneficiary, AURA.balanceOf(address(this)));
        emit ClaimedAuraRewards(AURA.balanceOf(address(this)));
    }

    //////////////////////////////////////////////////////////////////
    //                       Internal functions                     //
    //////////////////////////////////////////////////////////////////
    function _deposit(uint256 _amount, uint256 _vestingPeriod) internal {
        // Local variable to avoid multiple SLOADs
        uint256 _nonce = vestingNonce;
        // Increase nonce
        vestingNonce++;
        uint256 vestingEnds = block.timestamp + _vestingPeriod;
        vestingPositions[_nonce] = VestingPosition(_amount, vestingEnds, false);
        STAKED_AURABAL.safeTransferFrom(msg.sender, address(this), _amount);
        emit VestingPositionCreated(_nonce, _amount, vestingEnds);
    }
}
