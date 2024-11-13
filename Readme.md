# UniswapV2-clone

## Core
``UniswapV2Factory ->(creates) ->UniswapV2Pair ->(inherits) ->UniswapV2ERC20 ``

## Periphery
``UniswapV2Router02 --> (IUniswapV2Factory, IWETH)``
    
## Features
- Foundry template
- upgrade solidity compiler to version 0.8.28


## Test
```
forge test -vv
```

## Logs
```
Ran 9 tests for test/UniswapV2.t.sol:UniswapV2Test
[PASS] testAddLiquidity() (gas: 2427072)
Logs:
  Pair created at: 0xbac839AA79a71FD59D39a1E88CDE503Bb0DDfdF1
  Tokens approved for router
  Router address: 0xF62849F9A0B5Bf2913b396098F7c7019b51A820a
  Factory address: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f
  TokenA address: 0x5991A2dF15A8F6A256D3Ec51E99254Cd3fb576A9
  TokenB address: 0xc7183455a4C133Ae270771860664b6B7ec320bB1
  User address: 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
  Initial reserves - reserve0: 0 reserve1: 0
  Calculated pair address: 0xbac839AA79a71FD59D39a1E88CDE503Bb0DDfdF1
  Actual pair address: 0xbac839AA79a71FD59D39a1E88CDE503Bb0DDfdF1
  0xfad7b624020a0d6c9b7146c4b92bd08ab740db01de17bac2111932fc9b6193c2
  Current init code hash (hex): 0xfad7b624020a0d6c9b7146c4b92bd08ab740db01de17bac2111932fc9b6193c2
  Library init code hash (hex): 0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f
  Liquidity added successfully
  Actual amount A: 1000000000000000000000
  Actual amount B: 1000000000000000000000
  Liquidity tokens: 999999999999999999000

[PASS] testAddLiquidityETH() (gas: 2385152)
Logs:
  RNT-WETH Pair created at: 0x58cC05ab181E6f74bFD74497Cb6e6e01EBa1acc1
  Liquidity added successfully
  RNT amount: 1000000000000000000000
  ETH amount: 1000000000000000000
  Liquidity tokens: 31622776601683792319

[PASS] testCreatePair() (gas: 2145117)
[PASS] testInitCodeHash() (gas: 8313)
[PASS] testRemoveLiquidity() (gas: 2418634)
[PASS] testRemoveLiquidityETH() (gas: 2422536)
[PASS] testSwap() (gas: 2431558)
[PASS] testSwapExactETHForTokens() (gas: 2434951)
[PASS] testSwapExactTokensForETH() (gas: 2432616)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 2.86ms (9.40ms CPU time)

Ran 1 test suite in 11.54ms (2.86ms CPU time): 9 tests passed, 0 failed, 0 skipped (9 total tests)
```


## References
- https://github.com/Uniswap/v2-core
- https://github.com/Uniswap/v2-periphery
- https://github.com/Uniswap/solidity-lib
