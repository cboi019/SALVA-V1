//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {SalvaV1} from "../src/SALVA.sol";

contract DeploySalvaV1 is Script {
    function run() external returns (SalvaV1) {
        return deploySalvaV1();
    }

    function deploySalvaV1() public returns (SalvaV1) {
        vm.startBroadcast();
        SalvaV1 salva = new SalvaV1();
        vm.stopBroadcast();
        return salva;
    }
}
