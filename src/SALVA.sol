//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SalvaBase} from "./SALVA_BASE_LIB.sol";

/**
 * @title SalvaV1
 * @notice A non-custodial smart contract for creating and managing decentralized, token-based savings commitments.
 * @dev The contract supports two types of commitments: time-based (locked until a date) and goal-based (locked until an amount is reached).
 * The owner is responsible for whitelisting approved ERC20 tokens.
 */
contract SalvaV1 {
    using SafeERC20 for IERC20;

    /// @notice Thrown when a non-owner attempts an owner-only operation.
    error SalvaV1__NOT_AUTHORIZED();
    /// @notice Thrown when a function requires a non-zero amount but receives zero.
    error SalvaV1__INPUT_AN_AMOUNT();
    /// @notice Thrown when a user attempts to use a token that has not been whitelisted by the owner.
    error SalvaV1__NOT_ALLOWED_TOKEN();
    /// @notice Thrown when a user attempts to withdraw from a plan before its maturity time or goal is reached.
    error SalvaV1__COMMITMENT_NOT_MATURE();
    /// @notice Thrown when an invalid or zero address is provided.
    error SalvaV1__INVALID_ADDRESS(address);
    /// @notice Thrown when the token deposited does not match the token set for the plan.
    error SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
    /// @notice Thrown when a user attempts to withdraw more than the current balance of the plan.
    error SalvaV1__INSUFFICIENT_BALANCE(uint256);

    /** @dev The immutable address of the contract deployer (owner). */
    address private immutable i_owner;

    /** @dev Counter used to assign unique IDs to new savings plans. Starts at 1. */
    uint256 private s_planIdCounter = 1;

    /** @dev Mapping to track which ERC20 token addresses are whitelisted for use in savings plans. */
    mapping(address token => bool) private s_isTokenWhitelisted;

    /** @dev Mapping from user address to their TimeBasedCommitment plans (ID => Commitment Struct). */
    mapping(address user => mapping(uint256 => SalvaBase.TimeBasedCommitment)) private s_timeBasedPlans;

    /** @dev Mapping from user address to their GoalBasedSavings plans (ID => Savings Struct). */
    mapping(address user => mapping(uint256 => SalvaBase.GoalBasedSavings)) private s_goalBasedPlans;

    /// @notice Emitted when the owner adds a new token to the whitelist.
    /// @param _tokenAddress The address of the token that was added.
    /// @param _name The descriptive name of the token.
    /// @param _isAllowed True, confirming the token is now allowed.
    event tokenAdded(address indexed _tokenAddress, string _name, bool _isAllowed);

    /// @notice Emitted when the owner removes a token from the whitelist.
    /// @param _tokenAddress The address of the token that was removed.
    /// @param _name The descriptive name of the token.
    /// @param _isAllowed False, confirming the token is no longer allowed.
    event tokenRemoved(address indexed _tokenAddress, string _name, bool _isAllowed);

    /// @notice Emitted when a new savings plan (Time-Based or Goal-Based) is successfully created.
    /// @param _user The address of the user who created the plan.
    /// @param _description The description provided by the user for the plan.
    /// @param _planID The unique identifier of the newly created plan.
    event planCreated(address indexed _user, string _description, uint256 _planID);

    /// @notice Emitted when a savings plan receives a deposit.
    /// @param _user The address of the user who funded the plan.
    /// @param _description The description of the funded plan.
    /// @param _amount The amount of tokens deposited.
    /// @param _id The ID of the plan that was funded.
    event planFunded(address indexed _user, string _description, uint256 _amount, uint256 _id);

    /// @notice Emitted when a Goal-Based Savings plan reaches its target amount.
    /// @param _user The address of the user who completed the goal.
    /// @param _amount The target amount that was achieved.
    event GoalAchieved(address indexed _user, uint256 _amount);

    /**
     * @notice Initializes the contract and sets the deployer as the immutable owner.
     */
    constructor() {
        i_owner = msg.sender;
    }

    /**
     * @dev Restricts function execution to the immutable owner.
     */
    modifier onlyOwner() {
        _onlyOwner(msg.sender);
        _;
    }

    /**
     * @dev Checks that the input amount is greater than zero.
     * @param _amount The amount to check.
     */
    modifier noneZero(uint256 _amount) {
        _noneZero(_amount);
        _;
    }

    /**
     * @dev Checks if the specified token is currently whitelisted.
     * @param _token The address of the token to check.
     */
    modifier isAllowedToken(address _token) {
        _isAllowedToken(_token);
        _;
    }

    /**
     * @notice Creates a new Time-Based Savings plan. Funds in this plan can only be withdrawn after the maturity time.
     * @param _token The ERC20 token address to be used for this plan (must be whitelisted).
     * @param _description A user-defined description for the savings goal.
     * @param _savingsDuration The duration (in seconds) the funds must be locked for, starting from creation time.
     */
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

        uint256 planID = s_planIdCounter;
        s_planIdCounter++;

        s_timeBasedPlans[msg.sender][planID] = newTimeBasedPlan;

        emit planCreated(msg.sender, _description, planID);
    }

    /**
     * @notice Creates a new Goal-Based Savings plan. Funds in this plan can only be withdrawn once the target amount is reached.
     * @param _token The ERC20 token address to be used for this plan (must be whitelisted).
     * @param _description A user-defined description for the savings goal.
     * @param _targetAmount The total amount of tokens required to complete the goal.
     */
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

        uint256 planID = s_planIdCounter;
        s_planIdCounter++;

        s_goalBasedPlans[msg.sender][planID] = newGoalBasedPlan;

        emit planCreated(msg.sender, _description, planID);
    }

    /**
     * @notice Deposits a specified amount of tokens into an existing Time-Based Savings plan.
     * @dev The user must approve this contract to spend the tokens prior to calling this function.
     * @param _token The address of the token being deposited.
     * @param _id The ID of the time-based plan to fund.
     * @param _amount The amount of tokens to deposit. Must be greater than zero.
     */
    function fundTimeBasedPlan(address _token, uint256 _id, uint256 _amount)
        external
        isAllowedToken(_token)
        noneZero(_amount)
    {
        SalvaBase.TimeBasedCommitment storage timePlan = s_timeBasedPlans[msg.sender][_id];

        if (_token != timePlan.token) revert SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
        timePlan.currentAmount += _amount;

        emit planFunded(msg.sender, timePlan.description, _amount, _id);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Deposits a specified amount of tokens into an existing Goal-Based Savings plan. Checks for goal completion.
     * @dev The user must approve this contract to spend the tokens prior to calling this function.
     * @param _token The address of the token being deposited.
     * @param _id The ID of the goal-based plan to fund.
     * @param _amount The amount of tokens to deposit. Must be greater than zero.
     */
    function fundGoalBasedPlan(address _token, uint256 _id, uint256 _amount)
        external
        isAllowedToken(_token)
        noneZero(_amount)
    {
        SalvaBase.GoalBasedSavings storage goalPlan = s_goalBasedPlans[msg.sender][_id];

        if (_token != goalPlan.token) revert SalvaV1__TOKEN_MISMATCH_FOR_PLAN();
        goalPlan.currentAmount += _amount;

        if (goalPlan.currentAmount >= goalPlan.targetAmount) {
            goalPlan.isComplete = true;
            emit GoalAchieved(msg.sender, goalPlan.targetAmount);
        }

        emit planFunded(msg.sender, goalPlan.description, _amount, _id);
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @notice Withdraws a specified amount of tokens from a Time-Based Savings plan.
     * @dev This function can only be called if the current block.timestamp is greater than or equal to the plan's maturity time.
     * If the plan balance reaches zero, the plan is deleted.
     * @param _id The ID of the time-based plan to withdraw from.
     * @param _amount The amount of tokens to withdraw. Must be greater than zero.
     */
    function withdrawFromTBS(uint256 _id, uint256 _amount) external noneZero(_amount) {
        SalvaBase.TimeBasedCommitment storage timePlan = s_timeBasedPlans[msg.sender][_id];

        address token = timePlan.token;
        if (block.timestamp >= timePlan.maturityTime) timePlan.isComplete = true;
        
        if (timePlan.isComplete == false) revert SalvaV1__COMMITMENT_NOT_MATURE();
        if (_amount > timePlan.currentAmount) revert SalvaV1__INSUFFICIENT_BALANCE(timePlan.currentAmount);

        timePlan.currentAmount -= _amount;

        IERC20(token).safeTransfer(msg.sender, _amount);

        if (timePlan.currentAmount == 0) {
            delete s_timeBasedPlans[msg.sender][_id];
        }
    }

    /**
     * @notice Withdraws a specified amount of tokens from a Goal-Based Savings plan.
     * @dev This function can only be called if the plan's current amount is greater than or equal to the target amount (`isComplete` is true).
     * If the plan balance reaches zero, the plan is deleted.
     * @param _id The ID of the goal-based plan to withdraw from.
     * @param _amount The amount of tokens to withdraw. Must be greater than zero.
     */
    function withdrawFromGBS(uint256 _id, uint256 _amount) external noneZero(_amount) {
        SalvaBase.GoalBasedSavings storage goalPlan = s_goalBasedPlans[msg.sender][_id];
        
        if (goalPlan.isComplete == false) revert SalvaV1__COMMITMENT_NOT_MATURE();
        if (_amount > goalPlan.currentAmount) revert SalvaV1__INSUFFICIENT_BALANCE(goalPlan.currentAmount);

        address token = goalPlan.token;
        goalPlan.currentAmount -= _amount;

        IERC20(token).safeTransfer(msg.sender, _amount);

        if (goalPlan.currentAmount == 0) {
            delete s_goalBasedPlans[msg.sender][_id];
        }
    }

    /**
     * @notice Allows the contract owner to add or remove a token from the whitelist.
     * @dev Only callable by the contract owner.
     * @param _tokenAddress The address of the ERC20 token to modify.
     * @param _name A descriptive name for the token (used in events).
     * @param _isAllowed If true, the token is added/allowed; if false, it is removed/disallowed.
     */
    function addOrRemoveToken(address _tokenAddress, string memory _name, bool _isAllowed) external onlyOwner {
        if (_isAllowed) {
            s_isTokenWhitelisted[_tokenAddress] = true;
            emit tokenAdded(_tokenAddress, _name, _isAllowed);
        } else {
            s_isTokenWhitelisted[_tokenAddress] = false;
            emit tokenRemoved(_tokenAddress, _name, _isAllowed);
        }
    }

    /**
     * @notice Returns the details of a Time-Based Savings plan for a specific user and ID.
     * @param _user The address of the plan creator.
     * @param _id The ID of the Time-Based plan to view.
     * @return TimeBasedCommitment The structure containing all plan details.
     */
    function viewTimeBasedPlan(address _user, uint256 _id)
        external
        view
        returns (SalvaBase.TimeBasedCommitment memory)
    {
        return s_timeBasedPlans[_user][_id];
    }

    /**
     * @notice Returns the details of a Goal-Based Savings plan for a specific user and ID.
     * @param _user The address of the plan creator.
     * @param _id The ID of the Goal-Based plan to view.
     * @return GoalBasedSavings The structure containing all plan details.
     */
    function viewGoalBasedPlan(address _user, uint256 _id) external view returns (SalvaBase.GoalBasedSavings memory) {
        return s_goalBasedPlans[_user][_id];
    }

    /**
     * @notice Returns the immutable address of the contract owner.
     * @return The owner's address.
     */
    function getOwner() public view returns (address) {
        return i_owner;
    }

    /**
     * @notice Checks if a given ERC20 token address is currently whitelisted.
     * @param _tokenAddress The address of the token to check.
     * @return True if the token is whitelisted, false otherwise.
     */
    function checkAllowedToken(address _tokenAddress) external view returns (bool) {
        return s_isTokenWhitelisted[_tokenAddress];
    }

    /**
     * @dev Internal function to check if the sender is the contract owner.
     * @param _sender The address of the caller.
     */
    function _onlyOwner(address _sender) internal view {
        if (_sender != getOwner()) revert SalvaV1__NOT_AUTHORIZED();
    }

    /**
     * @dev Internal function to ensure an amount is greater than zero.
     * @param _amount The amount to validate.
     */
    function _noneZero(uint256 _amount) internal pure {
        if (_amount == 0) revert SalvaV1__INPUT_AN_AMOUNT();
    }

    /**
     * @dev Internal function to ensure a token is whitelisted.
     * @param _token The address of the token to validate.
     */
    function _isAllowedToken(address _token) internal view {
        if (!s_isTokenWhitelisted[_token]) revert SalvaV1__NOT_ALLOWED_TOKEN();
    }
}
