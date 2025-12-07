//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SalvaBase} from "./SALVA_BASE_LIB.sol";

contract SalvaV1 {
    using SafeERC20 for IERC20;

    error SalvaV1__NOT_AUTHORIZED();
    error SalvaV1__INPUT_AN_AMOUNT();
    error SalvaV1__NOT_ALLOWED_TOKEN();
    error SalvaV1__COMMITMENT_NOT_MATURE();
    error SalvaV1__INVALID_ADDRESS(address);
    error SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
    error SalvaV1__INSUFFICIENT_BALANCE(uint256);

    address private immutable i_OWNER;
    uint256 private s_ID_COUNTER = 1;
    mapping(address token => bool) private s_IS_ALLOWED_TOKEN;
    mapping(address user => mapping(uint256 => SalvaBase.TimeBasedCommitment)) private s_TIME_BASED_SAVINGS;
    mapping(address user => mapping(uint256 => SalvaBase.GoalBasedSavings)) private s_GOAL_BASED_SAVINGS;

    event tokenAdded(address indexed _tokenAddress, string _name, bool _isAllowed);
    event tokenRemoved(address indexed _tokenAddress, string _name, bool _isAllowed);
    event planCreated(address indexed _user, string _description, uint256 _planID);
    event planFunded(address indexed _user, string _description, uint256 _amount, uint256 _id);
    event GoalAchieved(address indexed _user, uint256 _amount);

    constructor() {
        i_OWNER = msg.sender;
    }

    modifier onlyOwner() {
        _onlyOwner(msg.sender);
        _;
    }

    modifier noneZero(uint256 _amount) {
        _noneZero(_amount);
        _;
    }

    modifier isAllowedToken(address _token) {
        _isAllowedToken(_token);
        _;
    }

    function createTimeBasedPlan(address _token, string memory _description, uint256 _savingsDuration)
        external
        isAllowedToken(_token)
    {
        SalvaBase.TimeBasedCommitment memory newTimeBasedPlan = SalvaBase.TimeBasedCommitment({
            user: msg.sender,
            token: _token,
            description: _description,
            currentAmount: 0,
            startTime: block.timestamp,
            maturityTime: block.timestamp + _savingsDuration,
            isComplete: false
        });

        uint256 planID = s_ID_COUNTER;
        s_ID_COUNTER++;

        s_TIME_BASED_SAVINGS[msg.sender][planID] = newTimeBasedPlan;

        emit planCreated(msg.sender, _description, planID);
    }

    function createGoalBasedPlan(address _token, string memory _description, uint256 _targetAmount)
        external
        isAllowedToken(_token)
    {
        SalvaBase.GoalBasedSavings memory newGoalBasedPlan = SalvaBase.GoalBasedSavings({
            user: msg.sender,
            token: _token,
            description: _description,
            currentAmount: 0,
            targetAmount: _targetAmount,
            isComplete: false
        });

        uint256 planID = s_ID_COUNTER;
        s_ID_COUNTER++;

        s_GOAL_BASED_SAVINGS[msg.sender][planID] = newGoalBasedPlan;

        emit planCreated(msg.sender, _description, planID);
    }

    function fundTimeBasedPlan(address _token, uint256 _id, uint256 _amount)
        external
        isAllowedToken(_token)
        noneZero(_amount)
    {
        SalvaBase.TimeBasedCommitment storage timePlan = s_TIME_BASED_SAVINGS[msg.sender][_id];

        if (_token != timePlan.token) revert SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
        timePlan.currentAmount += _amount;

        emit planFunded(msg.sender, timePlan.description, _amount, _id);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function fundGoalBasedPlan(address _token, uint256 _id, uint256 _amount)
        external
        isAllowedToken(_token)
        noneZero(_amount)
    {
        SalvaBase.GoalBasedSavings storage goalPlan = s_GOAL_BASED_SAVINGS[msg.sender][_id];

        if (_token != goalPlan.token) revert SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
        goalPlan.currentAmount += _amount;

        if (goalPlan.currentAmount >= goalPlan.targetAmount) {
            goalPlan.isComplete = true;
            emit GoalAchieved(msg.sender, goalPlan.targetAmount);
        }

        emit planFunded(msg.sender, goalPlan.description, _amount, _id);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    function withdrawFromTBS(uint256 _id, uint256 _amount) external noneZero(_amount) {
        SalvaBase.TimeBasedCommitment storage timePlan = s_TIME_BASED_SAVINGS[msg.sender][_id];

        address token = timePlan.token;
        if (block.timestamp >= timePlan.maturityTime) timePlan.isComplete = true;
        if (timePlan.isComplete == false) revert SalvaV1__COMMITMENT_NOT_MATURE();
        if (_amount > timePlan.currentAmount) revert SalvaV1__INSUFFICIENT_BALANCE(timePlan.currentAmount);

        timePlan.currentAmount -= _amount;

        IERC20(token).safeTransfer(msg.sender, _amount);

        if (timePlan.currentAmount == 0) {
            delete s_TIME_BASED_SAVINGS[msg.sender][_id];
        }
    }

    function withdrawFromGBS(uint256 _id, uint256 _amount) external noneZero(_amount) {
        SalvaBase.GoalBasedSavings storage goalPlan = s_GOAL_BASED_SAVINGS[msg.sender][_id];
        if (goalPlan.isComplete == false) revert SalvaV1__COMMITMENT_NOT_MATURE();
        if (_amount > goalPlan.currentAmount) revert SalvaV1__INSUFFICIENT_BALANCE(goalPlan.currentAmount);

        address token = goalPlan.token;
        goalPlan.currentAmount -= _amount;

        IERC20(token).safeTransfer(msg.sender, _amount);

        if (goalPlan.currentAmount == 0) {
            delete s_GOAL_BASED_SAVINGS[msg.sender][_id];
        }
    }

    function addOrRemoveToken(address _tokenAddress, string memory _name, bool _isAllowed) external onlyOwner {
        if (_isAllowed) {
            s_IS_ALLOWED_TOKEN[_tokenAddress] = true;
            emit tokenAdded(_tokenAddress, _name, _isAllowed);
        } else {
            s_IS_ALLOWED_TOKEN[_tokenAddress] = false;
            emit tokenRemoved(_tokenAddress, _name, _isAllowed);
        }
    }

    function viewTimeBasedPlan(address _user, uint256 _id)
        external
        view
        returns (SalvaBase.TimeBasedCommitment memory)
    {
        return s_TIME_BASED_SAVINGS[_user][_id];
    }

    function viewGoalBasedPlan(address _user, uint256 _id) external view returns (SalvaBase.GoalBasedSavings memory) {
        return s_GOAL_BASED_SAVINGS[_user][_id];
    }

    function getOwner() public view returns (address) {
        return i_OWNER;
    }

    function checkAllowedToken(address _tokenAddress) external view returns (bool) {
        if (s_IS_ALLOWED_TOKEN[_tokenAddress]) return true;
        else return false;
    }

    function _onlyOwner(address _sender) internal view {
        if (_sender != getOwner()) revert SalvaV1__NOT_AUTHORIZED();
    }

    function _noneZero(uint256 _amount) internal pure {
        if (_amount <= 0) revert SalvaV1__INPUT_AN_AMOUNT();
    }

    function _isAllowedToken(address _token) internal view {
        if (!s_IS_ALLOWED_TOKEN[_token]) revert SalvaV1__NOT_ALLOWED_TOKEN();
    }
}

