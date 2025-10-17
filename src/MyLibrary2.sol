//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library myLibrary {
    
    function getPrice(AggregatorV3Interface dataFeed) internal view returns (uint256) {
      (,int256 answer,,,) = dataFeed.latestRoundData();
      require(answer >=0, "Value is Negative");
      return uint256(answer / 1e8);
    }

    function getConversionRate(uint256 amount, AggregatorV3Interface _dataFeed) internal view returns(uint256) {
      uint256 ethPrice = getPrice(_dataFeed);
      uint256 ethPriceInUsd = (amount * ethPrice) / 1e18;
      return ethPriceInUsd;
    }

    function getVersion(AggregatorV3Interface version) internal view returns(uint256) {
      return version.version();
    }
}