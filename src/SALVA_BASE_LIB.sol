//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title SalvaBase
 * @notice A library defining the core data structures for savings commitments used throughout the SalvaV1 contract.
 * @dev Contains structs for time-enforced and goal-enforced savings plans.
 */
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

    /**
     * @notice Represents a savings commitment that is locked until a specific time is reached.
     * @dev The funds are inaccessible until `maturityTime` is reached.
     */
    struct TimeBasedCommitment {
        /// @param user The address of the user who initiated the savings commitment.
        address user;
        /// @param token The ERC-20 token address being locked.
        address token;
        /// @param description The user-defined purpose of the savings plan.
        string description;
        /// @param currentAmount The principal amount of the token deposited.
        uint256 currentAmount;
        /// @param startTime The timestamp when the plan was initiated (or the first deposit was made).
        uint256 startTime;
        /// @param maturityTime The timestamp when the funds become available (startTime + lockDuration).
        uint256 maturityTime;
        /// @param isComplete Flag indicating if the maturity time has been reached and the plan is available for withdrawal.
        bool isComplete;
    }

    /**
     * @notice Represents a savings commitment that is locked until a financial goal (target amount) is reached.
     * @dev The funds are inaccessible until `currentAmount` >= `targetAmount`.
     */
    struct GoalBasedSavings {
        /// @param user The address of the user who initiated the savings goal.
        address user;
        /// @param token The ERC-20 token address being used.
        address token;
        /// @param description The user-defined purpose of the savings goal.
        string description;
        /// @param currentAmount The total cumulative amount deposited into the plan so far.
        uint256 currentAmount;
        /// @param targetAmount The final financial goal amount the user is aiming to reach.
        uint256 targetAmount;
        /// @param isComplete Flag indicating if the target amount has been reached and the plan is available for withdrawal.
        bool isComplete;
    }
}
