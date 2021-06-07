// SPDX-License-Identifier: MIT

pragma solidity ^0.5.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './ComptrollerInterface.sol';
import './CTokenInterface.sol';

contract CompAdaptor {
    // pointers
    ComptrollerInterface public comptroller;

    event Log(string mssg, uint val);

    constructor (address _comptroller) public {
        comptroller = ComptrollerInterface(_comptroller);
    }

    // deposit tokens
    function deposit(address cTokenAddr, uint amount) public {
        CTokenInterface cToken = CTokenInterface(cTokenAddr);
        address underlying = cToken.underlying();
        IERC20 uToken = IERC20(underlying);
        uToken.approve(cTokenAddr, amount);

        uint result = cToken.mint(amount);
        emit Log("cToken mint", result);
        require(result == 0, "cToken#mint() failed. See Compound ErrorReporter.sol for details.");
    }

    // redeem ctokens for tokens
    function redeem(address cTokenAddr, uint cAmount) internal {
        CTokenInterface cToken = CTokenInterface(cTokenAddr);

        uint result = cToken.redeem(cAmount);
        require(result == 0, "cToken#redeem() failed. See Compound ErrorReporter.sol for details.");
    }

    //  borrow tokens
    function borrow(address cTokenAddr, uint uAmount) public {
        CTokenInterface cToken = CTokenInterface(cTokenAddr);

        address[] memory cTokens = new address[](1);
        cTokens[0] = cTokenAddr;

        uint[] memory result = comptroller.enterMarkets(cTokens);
        require(result[0] == 0, "Comptroller#enterMarkets() failed. See Compound ErrorReporter.sol for details.");

        uint result2 = cToken.borrow(uAmount);
        emit Log("cToken#borrow() error code: ", result2);

        // require(result2 > 1, "UNAUTHORIZED");
        // require(result2 > 2, "BAD_INPUT");
        // require(result2 > 3, "COMPTROLLER_REJECTION");
        // require(result2 > 4, "COMPTROLLER_CALCULATION_ERROR");
        // require(result2 > 5, "INTEREST_RATE_MODEL_ERROR");
        // require(result2 > 6, "INVALID_ACCOUNT_PAIR");
        // require(result2 > 7, "INVALID_CLOSE_AMOUNT_REQUESTED");
        // require(result2 > 8, "INVALID_COLLATERAL_FACTOR");
        // require(result2 > 9, "MATH_ERROR");
        // require(result2 > 10, "MARKET_NOT_FRESH");
        require(result2 == 0, "Token#borrow() failed.");
        
        // require(result2 == 0, "cToken#borrow() failed. See Compound ErrorReporter.sol for details.");
    }

    // repay the borrowed tokens
    function repay(address cTokenAddr, uint repayAmount) internal {
        CTokenInterface cToken = CTokenInterface(cTokenAddr);
        IERC20 uToken = IERC20(cToken.underlying());
        uToken.approve(cTokenAddr, repayAmount);

        uint result = cToken.repayBorrow(repayAmount);
        require(result == 0, "cToken#repayBorrow() failed. See Compound ErrorReporter.sol for details.");
    }

    function claimComp() internal {
        comptroller.claimComp(address(this));
    }

    function getCompAddress() internal view returns (address) {
        return comptroller.getCompAddress();
    }

    function getCTokenBalance(address cToken) public view returns (uint) {
        return CTokenInterface(cToken).balanceOf(address(this));
    }

    function getBorrowBalance(address cToken) public returns (uint) {
        return CTokenInterface(cToken).borrowBalanceCurrent(address(this));
    }

}