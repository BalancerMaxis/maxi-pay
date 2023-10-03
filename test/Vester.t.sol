// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BaseFixture.sol";
import { VesterErrors } from "../src/Vester.sol";

contract TestVester is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    //////////////////////////////////////////////////////////////////
    //                   Deposits and claims                        //
    //////////////////////////////////////////////////////////////////
    /// @dev Simple case when deposit creates vesting position
    function testDepositHappy(uint256 _depositAmount) public {
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply());
        // Deploy a new vesting contract
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        // Give st auraBAL to the DAO multisig
        setStorage(address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), _depositAmount);

        // Approve the vesting contract to spend st auraBAL
        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), _depositAmount);

        // Deposit st auraBAL into the vesting contract
        vm.prank(DAO_MSIG);
        aliceVester.deposit(_depositAmount);

        // Make sure the vesting contract has the st auraBAL
        assertEq(STAKED_AURABAL.balanceOf(address(aliceVester)), _depositAmount);
        // Make sure vesting position was created
        Vester.VestingPosition memory vestingPosition = aliceVester.getVestingPosition(0);
        assertEq(vestingPosition.amount, _depositAmount);
        assertFalse(vestingPosition.claimed);
    }

    /// @dev Simple claim
    function testClaimHappyStandardVestingPeriod(uint256 _depositAmount) public {
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply());
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        setStorage(address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), _depositAmount);

        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), _depositAmount);

        vm.prank(DAO_MSIG);
        aliceVester.deposit(_depositAmount);

        // Roll time to the end of the vesting period
        vm.warp(block.timestamp + vester.DEFAULT_VESTING_PERIOD());

        // Claim
        vm.prank(alice);
        aliceVester.claim(0);

        // Make sure the vesting position has been claimed
        Vester.VestingPosition memory vestingPosition = aliceVester.getVestingPosition(0);
        assertTrue(vestingPosition.claimed);

        // Check Alice balance now:
        assertEq(STAKED_AURABAL.balanceOf(address(alice)), _depositAmount);
        assertGt(AURA.balanceOf(address(alice)), 0);
    }

    function testClaimHappyCustomVestingPeriod(uint256 _depositAmount, uint256 _vestingPeriod) public {
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply());
        _vestingPeriod = bound(_vestingPeriod, 1 days, 1000 days);
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        setStorage(address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), _depositAmount);

        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), _depositAmount);

        vm.prank(DAO_MSIG);
        aliceVester.deposit(_depositAmount, _vestingPeriod);

        // Roll time to the end of the vesting period
        vm.warp(block.timestamp + _vestingPeriod);

        // Claim
        vm.prank(alice);
        aliceVester.claim(0);

        // Make sure the vesting position has been claimed
        Vester.VestingPosition memory vestingPosition = aliceVester.getVestingPosition(0);
        assertTrue(vestingPosition.claimed);

        // Check Alice balance now:
        assertEq(STAKED_AURABAL.balanceOf(address(alice)), _depositAmount);
        assertGt(AURA.balanceOf(address(alice)), 0);
    }

    function testMultipleClaims(uint256 _depositAmount, uint256 _positionsAmnt) public {
        _positionsAmnt = bound(_positionsAmnt, 1, 10);
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply() / _positionsAmnt);
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        setStorage(
            address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), STAKED_AURABAL.totalSupply()
        );

        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), type(uint256).max);
        for (uint256 i = 0; i < _positionsAmnt; i++) {
            vm.prank(DAO_MSIG);
            aliceVester.deposit(_depositAmount);
        }
        // Now roll time to the end of the vesting period and claim all positions
        vm.warp(block.timestamp + vester.DEFAULT_VESTING_PERIOD());
        for (uint256 i = 0; i < _positionsAmnt; i++) {
            vm.prank(alice);
            Vester(aliceVester).claim(i);
        }
        // Make sure Alice balance is now _depositAmount * _positionsAmnt
        assertEq(STAKED_AURABAL.balanceOf(address(alice)), _depositAmount * _positionsAmnt);
        assertGt(AURA.balanceOf(address(alice)), 0);
    }

    /// @dev Should revert when trying to claim too early
    function testClaimTooEarly(uint256 _depositAmount, uint256 _vestingPeriod) public {
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply());
        _vestingPeriod = bound(_vestingPeriod, 1 days, 1000 days);
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        setStorage(address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), _depositAmount);

        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), _depositAmount);

        vm.prank(DAO_MSIG);
        aliceVester.deposit(_depositAmount, _vestingPeriod);

        // Roll time almost to the end of the vesting period
        vm.warp(block.timestamp + (_vestingPeriod - 1));

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(VesterErrors.NotVestedYet.selector));
        aliceVester.claim(0);
    }

    //////////////////////////////////////////////////////////////////
    //                       Ragequit                               //
    //////////////////////////////////////////////////////////////////
    function testRageQuitHappy(uint256 _depositAmount) public {
        _depositAmount = bound(_depositAmount, 1e18, STAKED_AURABAL.totalSupply());
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));
        setStorage(address(DAO_MSIG), STAKED_AURABAL.balanceOf.selector, address(STAKED_AURABAL), _depositAmount);

        vm.prank(DAO_MSIG);
        STAKED_AURABAL.approve(address(aliceVester), _depositAmount);

        vm.prank(DAO_MSIG);
        aliceVester.deposit(_depositAmount);

        // Roll time to the end of the vesting period to accrue AURA rewards
        vm.warp(block.timestamp + vester.DEFAULT_VESTING_PERIOD());

        // Rage quite to random EOA
        vm.prank(DAO_MSIG);
        aliceVester.ragequit(randomEOA);
        assertEq(STAKED_AURABAL.balanceOf(randomEOA), _depositAmount);
        assertGt(AURA.balanceOf(randomEOA), 0);

        // Make sure vester has no more st auraBAL
        assertEq(STAKED_AURABAL.balanceOf(address(aliceVester)), 0);
        // Make sure vester has no more AURA
        assertEq(AURA.balanceOf(address(aliceVester)), 0);
    }
}
