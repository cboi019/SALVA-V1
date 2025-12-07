//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Test, console2} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {SalvaV1} from "../src/SALVA.sol";
import {DeploySalvaV1} from "../script/DeploySalvaV1.s.sol";
import {HelperConfig} from "../script/HelperConfiguration.s.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract testSavingsWallet is Test {
    SalvaV1 private salva;
    HelperConfig config;
    uint8 constant timeBasedType = 0;
    uint8 constant goalBasedType = 1;
    address user1 = makeAddr("user1");
    uint128 constant FORK_BLOCK = 20000000;
    uint128 constant USDC_TO_FUND = 10000 * 1e6;
    uint128 constant DAI_TO_FUND = 1000 * 1e18;
    address DAI;
    address USDC;

    function setUp() external {
        config = new HelperConfig();
        DAI = config.getConfig().DAI;
        USDC = config.getConfig().USDC;

        if (block.chainid == 1) {
            vm.createSelectFork(vm.rpcUrl("ETH_MAINNET_RPC_URL"), FORK_BLOCK);
            vm.deal(user1, 5000 ether);

            deal(USDC, user1, USDC_TO_FUND);
            deal(DAI, user1, DAI_TO_FUND);
        } else if (block.chainid == 11155111) {
            vm.deal(user1, 5000 ether);

            deal(USDC, user1, USDC_TO_FUND);
            deal(DAI, user1, DAI_TO_FUND);
        }

        DeploySalvaV1 deploySalva = new DeploySalvaV1();
        salva = deploySalva.run();

        if (block.chainid == 31337) {
            ERC20Mock(USDC).mint(user1, 1000 ether); // 1000000000000000
            ERC20Mock(DAI).mint(user1, 1000 ether);
        }
    }

    // modifier onlyAnvilOrMainnetChain() {
    //     if (block.chainid == 11155111) return;
    //     _;
    // }

    modifier approveTokenAdded() {
        vm.prank(msg.sender);
        salva.addOrRemoveToken(USDC, "USDC", true);
        _;
    }

    modifier UserPlanCreated(uint8 _type) {
        if (_type == timeBasedType) {
            string memory description = "My Rent";
            vm.prank(user1);
            salva.createTimeBasedPlan(USDC, description, 30 days);
        } else {
            string memory description = "New IPhone";
            uint256 amount = 500 * 1e6;
            vm.prank(user1);
            salva.createGoalBasedPlan(USDC, description, amount);
        }
        _;
    }

    modifier UserPlanFunded(uint8 _type) {
        uint256 amount = 1000 * 1e6;
        if (_type == timeBasedType) {
            vm.startPrank(user1);
            IERC20(USDC).approve(address(salva), amount);
            salva.fundTimeBasedPlan(USDC, 1, amount / 3);
            vm.stopPrank();
        } else {
            vm.startPrank(user1);
            IERC20(USDC).approve(address(salva), amount);
            salva.fundGoalBasedPlan(USDC, 1, amount / 3);
            vm.stopPrank();
        }
        _;
    }

    function test_OWNER_IS_SET_AND_CORRECT() public view {
        address owner = salva.getOwner();
        assertEq(owner, msg.sender);
    }

    // function test_ONLY_OWNER_CAN_REMOVE_OR_ADD_APPROVED_TOKENS(address _users) public {
    //     vm.prank(msg.sender);
    //     salva.addOrRemoveToken(DAI, "DAI", true);

    //     vm.assume(_users != msg.sender);
    //     vm.startPrank(_users);
    //     vm.expectRevert(SalvaV1.SalvaV1__NOT_AUTHORIZED.selector);
    //     salva.addOrRemoveToken(USDC, "USDC", true);

    //     vm.expectRevert(SalvaV1.SalvaV1__NOT_AUTHORIZED.selector);
    //     salva.addOrRemoveToken(DAI, "DAI", false);
    //     vm.stopPrank();
    // }

    function test_APPROVED_TOKEN_IS_ADDED_AND_DISAPPROVED_TOKEN_IS_REMOVED() public {
        vm.prank(msg.sender);
        salva.addOrRemoveToken(DAI, "DAI", true);

        bool isAllowed = salva.checkAllowedToken(DAI);
        console2.log(isAllowed);

        assert(isAllowed);

        vm.prank(msg.sender);
        salva.addOrRemoveToken(DAI, "DAI", false);

        bool isNotAllowed = salva.checkAllowedToken(DAI);

        assert(!isNotAllowed);
        console2.log(isNotAllowed);
    }

    function test_CREATING_TIME_BASED_PLAN() public approveTokenAdded {
        string memory description = "My Rent";
        vm.prank(user1);
        salva.createTimeBasedPlan(USDC, description, 30 days);

        vm.expectRevert(SalvaV1.SalvaV1__NOT_ALLOWED_TOKEN.selector);
        vm.prank(user1);
        salva.createTimeBasedPlan(DAI, description, 30 days);

        address user = salva.viewTimeBasedPlan(user1, 1).user;
        console2.log(user);
    }

    function test_CREATING_GOAL_BASED_PLAN() public approveTokenAdded {
        string memory description = "New IPhone";
        uint256 amount = 200_000 * 1e18;
        vm.prank(user1);
        salva.createGoalBasedPlan(USDC, description, amount);

        vm.expectRevert(SalvaV1.SalvaV1__NOT_ALLOWED_TOKEN.selector);
        vm.prank(user1);
        salva.createGoalBasedPlan(DAI, description, amount);
    }

    function test_FUND_TIME_BASED_PLAN() public approveTokenAdded UserPlanCreated(timeBasedType) {
        uint256 amount = 10 * 1e6;
        vm.prank(msg.sender);
        salva.addOrRemoveToken(DAI, "DAI", true);

        vm.startPrank(user1);
        IERC20(USDC).approve(address(salva), amount);
        salva.fundTimeBasedPlan(USDC, 1, amount);
        vm.stopPrank();

        uint256 salvaBalance = IERC20(USDC).balanceOf(address(salva));
        assertEq(salvaBalance, amount);

        uint256 userBalance = salva.viewTimeBasedPlan(user1, 1).currentAmount;
        assertEq(userBalance, amount);

        vm.startPrank(user1);
        IERC20(DAI).approve(address(salva), amount);
        vm.expectRevert(SalvaV1.SalvaV1__TOKEN_MISMATCH_FOR_PLAN.selector);
        salva.fundGoalBasedPlan(DAI, 1, amount);
        vm.stopPrank();
    }

    function test_FUND_GOAL_BASED_PLAN() public approveTokenAdded UserPlanCreated(goalBasedType) {
        uint256 amount = 10 * 1e6;
        vm.prank(msg.sender);
        salva.addOrRemoveToken(DAI, "DAI", true);

        vm.startPrank(user1);
        IERC20(USDC).approve(address(salva), amount);
        console2.log(IERC20(USDC).balanceOf(user1));
        salva.fundGoalBasedPlan(USDC, 1, amount);
        vm.stopPrank();

        uint256 salvaBalance = IERC20(USDC).balanceOf(address(salva));
        assertEq(salvaBalance, amount);

        uint256 userBalance = salva.viewGoalBasedPlan(user1, 1).currentAmount;
        assertEq(userBalance, amount);

        vm.startPrank(user1);
        IERC20(DAI).approve(address(salva), amount);
        vm.expectRevert(SalvaV1.SalvaV1__TOKEN_MISMATCH_FOR_PLAN.selector);
        salva.fundGoalBasedPlan(DAI, 1, amount);
        vm.stopPrank();
    }

    function test_CANNOT_WITHDRAW_FROM_TBS_UNTIL_MATURITY()
        public
        approveTokenAdded
        UserPlanCreated(timeBasedType)
        UserPlanFunded(timeBasedType)
    {
        uint256 amount = 10 * 1e6;

        vm.prank(user1);
        vm.expectRevert(SalvaV1.SalvaV1__COMMITMENT_NOT_MATURE.selector);
        salva.withdrawFromTBS(1, amount);

        uint256 userBalance = salva.viewTimeBasedPlan(user1, 1).currentAmount;
        uint256 maturityTime = salva.viewTimeBasedPlan(user1, 1).maturityTime;
        console2.log(userBalance);

        vm.warp(maturityTime);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(SalvaV1.SalvaV1__INSUFFICIENT_BALANCE.selector, userBalance));
        salva.withdrawFromTBS(1, userBalance * 2);
    }

    function test_CANNOT_WITHDRAW_FROM_GBS_UNTIL_MATURITY()
        public
        approveTokenAdded
        UserPlanCreated(goalBasedType)
        UserPlanFunded(goalBasedType)
    {
        uint256 amount = 10 * 1e6;

        vm.prank(user1);
        vm.expectRevert(SalvaV1.SalvaV1__COMMITMENT_NOT_MATURE.selector);
        salva.withdrawFromGBS(1, amount);

        uint256 goalAmount = 1000 * 1e6;
        vm.startPrank(user1);
        IERC20(USDC).approve(address(salva), goalAmount);
        salva.fundGoalBasedPlan(USDC, 1, goalAmount);
        vm.stopPrank();

        uint256 userBalance = salva.viewGoalBasedPlan(user1, 1).currentAmount;
        console2.log(userBalance);

        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(SalvaV1.SalvaV1__INSUFFICIENT_BALANCE.selector, userBalance));
        salva.withdrawFromGBS(1, goalAmount * 2);
    }
}

