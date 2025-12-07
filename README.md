Salva V1: Decentralized Savings Protocol

Salva V1 is a Solidity smart contract implementation of a non-custodial decentralized savings protocol. It allows users to create goal-oriented commitments to save specific whitelisted ERC20 tokens over time.

The protocol supports two main types of savings plans: Time-Based Commitments and Goal-Based Savings, offering users flexibility in how they lock and mature their funds.

🚀 Features

Non-Custodial: Funds are held by the contract under logic that dictates withdrawal only upon meeting a pre-defined condition (time or amount).

Whitelisted Tokens: Only tokens approved by the contract owner can be used for creating savings plans.

Time-Based Commitments (TBC): Funds are locked until a specified maturity time is reached.

Goal-Based Savings (GBS): Funds are locked until the cumulative deposited amount meets or exceeds a defined target amount.

Owner Control: The contract owner can manage the list of whitelisted tokens.

🛠️ CONTRACT STRUCTURE

```javascript
The Salva V1 protocol is built using two core components: the main executable contract (SalvaV1.sol) and a library (SALVA_BASE_LIB.sol) that defines the primary data models.

1. SalvaV1.sol (The Main Contract)

This contract manages all user interactions, state transitions, and ownership controls.

Key State Variables:

i_owner: The immutable address of the contract deployer/owner.

s_planIdCounter: A monotonically increasing counter to assign unique IDs to new plans.

s_isTokenWhitelisted: A mapping to track which ERC20 token addresses are approved for creating plans.

s_timeBasedPlans: A nested mapping to store all Time-Based Commitment structs, keyed by user address and plan ID.

s_goalBasedPlans: A nested mapping to store all Goal-Based Savings structs, keyed by user address and plan ID.
```



```javascript
2. SALVA_BASE_LIB.sol (The Data Library)

This library defines the two core structs that encapsulate the specific parameters of each type of savings plan.

TimeBasedCommitment Struct (TBC)

Represents a plan where funds are locked until a specific timestamp is reached.

user: The address of the user who initiated the plan.

token: The ERC20 token address being locked.

description: The user-defined purpose or goal.

currentAmount: The total principal amount deposited so far.

startTime: The timestamp when the plan was created.

maturityTime: The timestamp after which withdrawal is allowed.

isComplete: A flag indicating if the plan is available for withdrawal (i.e., maturity time has passed).
// =========================================================================================================
GoalBasedSavings Struct (GBS)

Represents a plan where funds are locked until a financial target amount is met.

user: The address of the user who initiated the plan.

token: The ERC20 token address being used.

description: The user-defined purpose or goal.

currentAmount: The total cumulative amount deposited into the plan.

targetAmount: The financial goal amount the user aims to reach.

isComplete: A flag indicating if the target amount has been reached and withdrawal is allowed.
```

🔑 Key Functions

```javascript
Owner Functions (Whitelisting)

addOrRemoveToken: Allows the contract owner to add or remove an ERC20 token from the whitelist.

getOwner: Returns the address of the contract owner.

User Functions (Plan Management)

createTimeBasedPlan: Initiates a new plan locked until a specified duration passes.

createGoalBasedPlan: Initiates a new plan locked until a specified token amount is reached.

fundTimeBasedPlan: Deposits tokens into an existing Time-Based plan. (Requires prior approve() call on the ERC20 token.)

fundGoalBasedPlan: Deposits tokens into an existing Goal-Based plan. (Requires prior approve() call on the ERC20 token.)

withdrawFromTBS: Withdraws funds from a Time-Based plan if its maturity time has passed.

withdrawFromGBS: Withdraws funds from a Goal-Based plan if its target goal has been met.
// =============================================================================================================================

View Functions

viewTimeBasedPlan: Retrieves the details of a specific Time-Based plan.

viewGoalBasedPlan: Retrieves the details of a specific Goal-Based plan.

checkAllowedToken: Checks if a token address is currently whitelisted.

// =============================================================================================================================

🛑 Error Codes

The contract utilizes custom error codes for efficient gas usage and clear debugging:

SalvaV1__NOT_AUTHORIZED: Caller is not the contract owner.

SalvaV1__INPUT_AN_AMOUNT: The deposited or withdrawn amount is zero.

SalvaV1__NOT_ALLOWED_TOKEN: The token used is not whitelisted.

SalvaV1__COMMITMENT_NOT_MATURE: Attempted withdrawal before time maturity or goal completion.

SalvaV1__TOKEN_MISMATCH_FOR_PLAN: Attempted to fund a plan with the wrong token.

SalvaV1__INSUFFICIENT_BALANCE: Attempted to withdraw more than the plan's current balance.
```
