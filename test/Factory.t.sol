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
}
