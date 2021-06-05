// SPDX-License-Identifier: MIT

pragma solidity ^0.5.7;

interface ComptrollerInterface {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function claimComp(address holder) external;
    // function getAccountLiquidity(address owner) external view returns(uint, uint, uint);
    function getCompAddress() external view returns (address);
}