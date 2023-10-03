// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./BaseFixture.sol";

contract TestFactory is BaseFixture {
    function setUp() public override {
        super.setUp();
    }

    function testFactoryOwnership() public {
        // Make sure the factory is owned by the DAO multisig
        assertEq(address(factory.owner()), factory.DAO_MSIG());

        // Check implementation address
        assertEq(address(factory.getImplementation()), address(vester));
    }

    function testSetNewImplHappy() public {
        // Deploy a new vesting contract
        Vester newVester = new Vester();
        vm.prank(DAO_MSIG);
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
        vm.prank(DAO_MSIG);
        Vester aliceVester = Vester(factory.deployVestingContract(alice));

        // Check that the vesting contract was deployed
        assertEq(factory.vestingContracts(alice, 0), address(aliceVester));
        assertEq(aliceVester.beneficiary(), alice);
    }
}
