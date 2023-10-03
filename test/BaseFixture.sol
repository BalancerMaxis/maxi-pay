// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "./Utils.sol";
import "../src/Factory.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract BaseFixture is Test {
    using stdStorage for StdStorage;

    address public constant DAO_MSIG = address(0xaF23DC5983230E9eEAf93280e312e57539D098D0);
    ERC20 public constant STAKED_AURABAL = ERC20(address(0x4EA9317D90b61fc28C418C247ad0CA8939Bbb0e9));
    ERC20 public constant AURA = ERC20(address(0x1509706a6c66CA549ff0cB464de88231DDBe213B));

    Utils internal utils;
    address payable[] internal users;
    address public alice;
    address public bob;
    address public randomEOA;

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
        randomEOA = users[2];
        vm.label(randomEOA, "randomEOA");

        vester = new Vester();
        factory = new Factory(address(vester));
    }
}
