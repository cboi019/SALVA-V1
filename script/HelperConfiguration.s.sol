// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract HelperConfig is Script {
    Tokens private config;

    struct Tokens {
        address USDC;
        address USDT;
        address DAI;
    }

    constructor() {
        if (block.chainid == 1115511) _setConfig(_sepoliaConfig());
        else if (block.chainid == 1) _setConfig(_mainnetConfig());
        else _setConfig(_anvilConfig());
    }

    function getConfig() external view returns (Tokens memory) {
        return config;
    }

    function _setConfig(Tokens memory _token) internal {
        config = _token;
    }

    function _mainnetConfig() internal pure returns (Tokens memory) {
        return Tokens({
            USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48,
            USDT: 0xdAC17F958D2ee523a2206206994597C13D831ec7,
            DAI: 0x6B175474E89094C44Da98b954EedeAC495271d0F
        });
    }

    function _sepoliaConfig() internal pure returns (Tokens memory) {
        return Tokens({
            USDC: 0x94a9D9AC8A22534e3facA9f4E7f2e2cf85d5e1C8,
            USDT: 0x1F9fE06518175d71d3e502B76a6058098E69695C,
            DAI: 0x77C9d0d7F2C2a93414571a37D6E6A17BC53d4321
        });
    }

    function _anvilConfig() internal returns (Tokens memory) {
        vm.startBroadcast();
        ERC20Mock usdc = new ERC20Mock("USDC", "USC");
        ERC20Mock usdt = new ERC20Mock("USDT", "UST");
        ERC20Mock dai = new ERC20Mock("DAI", "DSC");
        vm.stopBroadcast();

        return Tokens({USDC: address(usdc), USDT: address(usdt), DAI: address(dai)});
    }
}
