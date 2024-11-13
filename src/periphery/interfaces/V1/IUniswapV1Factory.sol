pragma solidity ^0.8.28;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}
