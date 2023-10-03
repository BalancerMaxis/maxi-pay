// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./Utils.sol";
import "../src/Factory.sol";

contract BaseFixture is Test {
    using stdStorage for StdStorage;

    address public constant DAO_MSIG = address(0xaF23DC5983230E9eEAf93280e312e57539D098D0);

    Utils internal utils;
    address payable[] internal users;
    address public alice;
    address public bob;

    Factory public factory;
    Vester public vester;

    function setStorage(address _user, bytes4 _selector, address _contract, uint256 value) public {
        uint256 slot = stdstore.target(_contract).sig(_selector).with_key(_user).find();
        vm.store(_contract, bytes32(slot), bytes32(value));
    }

    function setUp() public virtual {
        // https://arbiscan.io/block/137047782
        vm.createSelectFork("arbitrum", 137_047_782);
        utils = new Utils();
        users = utils.createUsers(5);
        alice = users[0];
        vm.label(alice, "Alice");
        bob = users[1];
        vm.label(bob, "Bob");
        vester = new Vester();
        factory = new Factory(address(vester));
    }
}
