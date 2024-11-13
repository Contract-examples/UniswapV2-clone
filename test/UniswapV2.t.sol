// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";
import {UniswapV2Router02} from "../src/periphery/UniswapV2Router02.sol";
import {ERC20 as TestERC20} from "../src/periphery/test/ERC20.sol";
import {WETH9} from "../src/periphery/test/WETH9.sol";

contract UniswapV2Test is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    WETH9 public weth;

    address public owner;
    address public user;

    function setUp() public {
        // 设置测试账户
        owner = address(this);
        user = address(0xABCD);
        vm.startPrank(owner);

        // 部署合约
        factory = new UniswapV2Factory(owner);
        weth = new WETH9();
        router = new UniswapV2Router02(address(factory), address(weth));

        // 部署测试代币
        tokenA = new TestERC20(1_000_000 ether); // 1M tokens
        tokenB = new TestERC20(1_000_000 ether); // 1M tokens

        // 给测试用户转一些代币
        tokenA.transfer(user, 10_000 ether);
        tokenB.transfer(user, 10_000 ether);
        vm.stopPrank();
    }

    function testCreatePair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        // 授权
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);

        // 添加流动性
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1000 ether, // desired amount A
            1000 ether, // desired amount B
            0, // min amount A
            0, // min amount B
            user, // to
            block.timestamp + 1 // deadline
        );

        assertTrue(amountA > 0);
        assertTrue(amountB > 0);
        assertTrue(liquidity > 0);

        // 检查代币是否被转移
        address pair = factory.getPair(address(tokenA), address(tokenB));
        assertEq(tokenA.balanceOf(pair), amountA);
        assertEq(tokenB.balanceOf(pair), amountB);

        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(user);

        // 先添加流动性
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);

        router.addLiquidity(address(tokenA), address(tokenB), 1000 ether, 1000 ether, 0, 0, user, block.timestamp + 1);

        // 记录交换前的余额
        uint256 tokenBBalanceBefore = tokenB.balanceOf(user);

        // 用 tokenA 换 tokenB
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        router.swapExactTokensForTokens(
            10 ether, // 输入数量
            1, // 最小输出数量
            path, // 交易路径
            user, // 接收地址
            block.timestamp + 1 // 截止时间
        );

        // 验证交换结果
        uint256 tokenBBalanceAfter = tokenB.balanceOf(user);
        assertTrue(tokenBBalanceAfter > tokenBBalanceBefore);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        // 先添加流动性
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), 1000 ether, 1000 ether, 0, 0, user, block.timestamp + 1
        );

        // 获取 pair 地址并授权
        address pair = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair(pair).approve(address(router), type(uint256).max);

        // 移除流动性
        (uint256 removeAmountA, uint256 removeAmountB) = router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity, // 移除全部流动性
            0, // 最小 A 数量
            0, // 最小 B 数量
            user, // 接收地址
            block.timestamp + 1 // 截止时间
        );

        // 验证结果
        assertTrue(removeAmountA > 0);
        assertTrue(removeAmountB > 0);
        assertEq(removeAmountA, amountA);
        assertEq(removeAmountB, amountB);

        vm.stopPrank();
    }
}
