// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BaseFixture.sol";

contract TestFactory is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    function testFactoryOwnership() public {
        // Make sure the factory is owned by the DAO multisig
        assertEq(address(factory.owner()), factory.MAXIS_OPS());

        // Check implementation address
        assertEq(address(factory.getImplementation()), address(vester));
    }

    function testSetNewImplHappy() public {
        // Deploy a new vesting contract
        Vester newVester = new Vester();
        vm.prank(MAXIS_OPS);
        factory.setImplementation(address(newVester));
        assertEq(address(factory.getImplementation()), address(newVester));
    }

    /// @notice Should revert if not called by DAO multisig
    function testSetNewImplUnhappy() public {
        Vester newVester = new Vester();
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.setImplementation(address(newVester));
    }

    function testDeployVesters() public {
        vm.prank(MAXIS_OPS);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));

        // Check that the vesting contract was deployed
        assertEq(factory.vestingContracts(alice, 0), address(aliceVester));
        assertEq(aliceVester.beneficiary(), alice);

        // Deploy vester for Bob
        vm.prank(MAXIS_OPS);
        Vester bobVester = Vester(factory.deployVestingContract(bob));
        // Check that the vesting contract was deployed
        assertEq(factory.vestingContracts(bob, 0), address(bobVester));

        // Deploy one more for Bob and make sure it is accessible in the array
        vm.prank(MAXIS_OPS);
        Vester bobVester2 = Vester(factory.deployVestingContract(bob));
        assertEq(factory.vestingContracts(bob, 1), address(bobVester2));

        // Get all Bob's vesting contracts
        address[] memory bobVesters = factory.getVestingContracts(bob);
        assertEq(bobVesters.length, 2);
        assertEq(bobVesters[0], address(bobVester));
    }
}
