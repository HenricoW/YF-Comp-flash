// SPDX-License-Identifier: MIT

pragma solidity ^0.5.7;

interface CTokenInterface {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    // function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    // function balanceOfUnderlying(address owner) external returns (uint);
    function underlying() external view returns(address);
}