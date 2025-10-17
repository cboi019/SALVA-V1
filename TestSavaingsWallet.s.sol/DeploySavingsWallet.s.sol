//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {SavingsWallet} from "../src/MultiWalletUpdate.sol";

contract deploySavingsWallet is Script{

  function run() external returns(SavingsWallet){
    vm.startBroadcast();
    SavingsWallet newSavings = new SavingsWallet(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    vm.stopBroadcast();
    return newSavings;
  }

}
