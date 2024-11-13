// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/core/UniswapV2Factory.sol";
import "../src/core/UniswapV2Pair.sol";
import { UniswapV2Router02 } from "../src/periphery/UniswapV2Router02.sol";
import { ERC20 as TestERC20 } from "../src/periphery/test/ERC20.sol";
import { WETH9 } from "../src/periphery/test/WETH9.sol";
import { UniswapV2Library } from "../src/periphery/libraries/UniswapV2Library.sol";

contract UniswapV2Test is Test {
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    TestERC20 public tokenA;
    TestERC20 public tokenB;
    WETH9 public weth;

    address public owner;
    address public user;

    event InitCodeHash(bytes32 hash);

    receive() external payable { }

    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        vm.startPrank(owner);

        // deploy v2
        factory = new UniswapV2Factory(owner);
        weth = new WETH9();
        router = new UniswapV2Router02(address(factory), address(weth));

        // deploy test token
        tokenA = new TestERC20(1_000_000 ether); // 1M tokens
        tokenB = new TestERC20(1_000_000 ether); // 1M tokens

        // transfer some tokens to user
        tokenA.transfer(user, 10_000 ether);
        tokenB.transfer(user, 10_000 ether);
        vm.stopPrank();

        // confirm user balance
        assertEq(tokenA.balanceOf(user), 10_000 ether);
        assertEq(tokenB.balanceOf(user), 10_000 ether);
    }

    function testInitCodeHash() public {
        bytes32 hash = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
        emit InitCodeHash(hash);
    }

    function testCreatePair() public {
        address pair = factory.createPair(address(tokenA), address(tokenB));
        assertTrue(pair != address(0));
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pair);
    }

    function testAddLiquidity() public {
        vm.startPrank(user);

        // create pair and get pair address
        address pair = factory.createPair(address(tokenA), address(tokenB));

        // print pair address
        address actualPair = factory.getPair(address(tokenA), address(tokenB));
        console.log("Pair created at:", actualPair);

        // check pair is initialized
        (address token0, address token1) =
            address(tokenA) < address(tokenB) ? (address(tokenA), address(tokenB)) : (address(tokenB), address(tokenA));

        assertEq(UniswapV2Pair(pair).token0(), token0, "Token0 not set correctly");
        assertEq(UniswapV2Pair(pair).token1(), token1, "Token1 not set correctly");

        // approve tokens for router
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        console.log("Tokens approved for router");

        console.log("Router address:", address(router));
        console.log("Factory address:", address(factory));
        console.log("TokenA address:", address(tokenA));
        console.log("TokenB address:", address(tokenB));
        console.log("User address:", user);

        // check initial reserves
        (uint112 reserve0, uint112 reserve1,) = UniswapV2Pair(pair).getReserves();
        console.log("Initial reserves - reserve0:", reserve0, "reserve1:", reserve1);

        // check pairFor calculated address
        address calculatedPair = UniswapV2Library.pairFor(address(factory), address(tokenA), address(tokenB));
        console.log("Calculated pair address:", calculatedPair);
        console.log("Actual pair address:", pair);

        // check init code hash
        bytes32 hash = keccak256(abi.encodePacked(type(UniswapV2Pair).creationCode));
        bytes32 libraryHash = hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f";
        console.logBytes32(hash);
        console.log("Current init code hash (hex):", vm.toString(hash));
        console.log("Library init code hash (hex):", vm.toString(libraryHash));

        uint256 amountA = 1000 ether;
        uint256 amountB = 1000 ether;

        // add liquidity
        (uint256 actualAmountA, uint256 actualAmountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA, // desired amount A
            amountB, // desired amount B
            0, // min amount A
            0, // min amount B
            user, // to
            block.timestamp + 1 // deadline
        );

        console.log("Liquidity added successfully");
        console.log("Actual amount A:", actualAmountA);
        console.log("Actual amount B:", actualAmountB);
        console.log("Liquidity tokens:", liquidity);

        // check results
        assertTrue(actualAmountA > 0, "Amount A should be greater than 0");
        assertTrue(actualAmountB > 0, "Amount B should be greater than 0");
        assertTrue(liquidity > 0, "Liquidity should be greater than 0");

        // check tokens are transferred to pair
        assertEq(tokenA.balanceOf(pair), actualAmountA, "Pair should have correct amount of token A");
        assertEq(tokenB.balanceOf(pair), actualAmountB, "Pair should have correct amount of token B");

        // check user LP tokens balance
        assertEq(UniswapV2Pair(pair).balanceOf(user), liquidity, "User should have correct LP tokens");

        vm.stopPrank();
    }

    function testSwap() public {
        vm.startPrank(user);

        // create pair
        factory.createPair(address(tokenA), address(tokenB));

        // approve tokens for router
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);

        // add liquidity
        router.addLiquidity(address(tokenA), address(tokenB), 1000 ether, 1000 ether, 0, 0, user, block.timestamp + 1);

        // record balance before swap
        uint256 tokenBBalanceBefore = tokenB.balanceOf(user);

        // prepare swap parameters
        uint256 amountIn = 10 ether;
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // estimate output amount
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256 amountOutMin = amounts[1] * 99 / 100; // allow 1% slippage

        // execute swap
        router.swapExactTokensForTokens(amountIn, amountOutMin, path, user, block.timestamp + 1);

        // check results
        uint256 tokenBBalanceAfter = tokenB.balanceOf(user);
        assertTrue(tokenBBalanceAfter > tokenBBalanceBefore, "Should receive token B");
        assertEq(tokenBBalanceAfter - tokenBBalanceBefore, amounts[1], "Should receive expected amount");

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user);

        // create pair
        factory.createPair(address(tokenA), address(tokenB));

        // approve tokens for router
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);

        // add liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), 1000 ether, 1000 ether, 0, 0, user, block.timestamp + 1
        );

        // get pair address and approve
        address pair = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair(pair).approve(address(router), liquidity);

        // record balance before removing liquidity
        uint256 tokenABalanceBefore = tokenA.balanceOf(user);
        uint256 tokenBBalanceBefore = tokenB.balanceOf(user);

        // remove liquidity
        (uint256 removeAmountA, uint256 removeAmountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), liquidity, 0, 0, user, block.timestamp + 1);

        // check results
        // remember to subtract the minimum liquidity
        assertEq(
            removeAmountA,
            amountA - IUniswapV2Pair(pair).MINIMUM_LIQUIDITY(),
            "Should receive correct amount of token A"
        );
        assertEq(
            removeAmountB,
            amountB - IUniswapV2Pair(pair).MINIMUM_LIQUIDITY(),
            "Should receive correct amount of token B"
        );
        assertEq(tokenA.balanceOf(user) - tokenABalanceBefore, removeAmountA, "Balance change should match");
        assertEq(tokenB.balanceOf(user) - tokenBBalanceBefore, removeAmountB, "Balance change should match");
        assertEq(IUniswapV2Pair(pair).balanceOf(user), 0, "Should have no LP tokens left");

        vm.stopPrank();
    }
}
