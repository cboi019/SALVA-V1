//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library SalvaBase {
    // uint128 private constant s_PRECISION = 1e18;
    // uint128 private constant s_ANSWER_PRECISION = 1e10;

    // function getPrice(AggregatorV3Interface dataFeed) internal view returns (uint256) {
    //     (, int256 answer,,,) = dataFeed.latestRoundData();
    //     require(answer >= 0, "Value is Negative");
    //     return uint256(answer) * s_ANSWER_PRECISION;
    // }

    // function getConversionRate(uint256 amount, AggregatorV3Interface _dataFeed) internal view returns (uint256) {
    //     uint256 ethPrice = getPrice(_dataFeed);
    //     uint256 ethPriceInUsd = (amount * ethPrice) / s_PRECISION;
    //     return ethPriceInUsd;
    // }

    // function getVersion(AggregatorV3Interface version) internal view returns (uint256) {
    //     return version.version();
    // }

    struct TimeBasedCommitment {
        address user; // The address of the user who initiated the savings commitment.
        address token; // The ERC-20 token address being locked.
        string description; // The Purpose
        uint256 currentAmount; // The principal amount of the token deposited.
        uint256 startTime; // The timestamp when the funds were deposited.
        uint256 maturityTime; // The timestamp when the funds become available (startTime + lockDuration).
        bool isComplete; // Flag indicating target has been reached.
    }

    struct GoalBasedSavings {
        address user; // The address of the user who initiated the savings goal.
        address token; // The ERC-20 token address being used.
        string description; // The Purpose
        uint256 currentAmount; // The total cumulative amount deposited so far.
        uint256 targetAmount; // The final financial goal the user is aiming for.
        bool isComplete; // Flag indicating target has been reached.
    }
}
