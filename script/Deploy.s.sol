// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { Factory } from "../src/Factory.sol";
import { Vester } from "../src/Vester.sol";
import { ERC20 } from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ProductionWireUpDeployment is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        // 1. Deploy vester implementation
        Vester vesterImpl = new Vester();

        // 2. Deploy the factory. Once it's deployed, ownership is transferred to DAO multisig
        Factory factory = new Factory(address(vesterImpl));
        vm.stopBroadcast();
    }
}
