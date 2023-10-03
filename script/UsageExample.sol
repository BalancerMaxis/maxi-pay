// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Script.sol";
import { Factory } from "../src/Factory.sol";
import { Vester } from "../src/Vester.sol";
import { ERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @notice Pseudo code usage showcase for Vesting Contract. Please, don't use this for actual deployment
contract UsageExample is Script {
    ERC20 public constant STAKED_AURABAL = ERC20(address(0x4EA9317D90b61fc28C418C247ad0CA8939Bbb0e9));
    address public constant DAO_MSIG = address(0xaF23DC5983230E9eEAf93280e312e57539D098D0);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // 1. Deploy vester implementation
        Vester vesterImpl = new Vester();

        // 2. Deploy the factory. Once it's deployed, ownership is transferred to DAO multisig
        Factory factory = new Factory(address(vesterImpl));
        vm.stopBroadcast();

        // 3. Deploy vesting contract for any user now:
        // Prank DAO msig
        vm.startPrank(DAO_MSIG);
        address alice = vm.envAddress("ALICE");
        address vestingContract = factory.deployVestingContract(alice);
        vm.stopPrank();

        // 4. Anyone with staked auraBAL can deposit it to the vesting contract
        address whale = vm.envAddress("WHALE");
        vm.startPrank(DAO_MSIG);
        // Approve st auraBAL to be spent by vesting contract
        STAKED_AURABAL.approve(vestingContract, STAKED_AURABAL.balanceOf(whale));
        // Deposit st auraBAL to the vesting contract
        Vester(vestingContract).deposit(STAKED_AURABAL.balanceOf(whale));
        vm.stopPrank();

        // 5. After vesting period is over, beneficiary can claim the tokens
        vm.startPrank(alice);
        Vester(vestingContract).claim(0);
        vm.stopPrank();

        // 6. DAO msig can ragequit the vesting contract at any time if something goes wrong, and claim all auraBAL
        // tokens and AURA rewards
        vm.startPrank(DAO_MSIG);
        address to = vm.envAddress("TO");
        Vester(vestingContract).ragequit(to);
        vm.stopPrank();
    }
}
