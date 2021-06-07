// SPDX-License-Identifier: MIT

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;

import '@studydefi/money-legos/dydx/contracts/DydxFlashloanBase.sol';
import '@studydefi/money-legos/dydx/contracts/ICallee.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './CompAdaptor.sol';

contract CompoundFlash is DydxFlashloanBase, ICallee, CompAdaptor {
    enum Direction { Borrow, Repay }
    struct CallData {
        address solo;
        address token;
        address cToken;
        uint amountProvided;
        uint loanAmount;
        uint repayAmount;
        Direction direction;
    }

    address public owner;

    constructor (address _comptroller) CompAdaptor(_comptroller) public {
        owner = msg.sender;
    }

    function startFlashLoan(address _solo, address _token, address _cToken, uint256 _amountProvided, uint256 _loanAmount) external {
        require(msg.sender == owner, "Only Owner allowed");
        _initiateFlashLoan(_solo, _token, _cToken, _amountProvided, (_loanAmount - 2), Direction.Borrow);
    }

    function closeOutFlashLoan(address _solo, address _token, address _cToken) external {
        require(msg.sender == owner, "Only Owner allowed");

        // COMP
        claimComp();
        address compAddr = getCompAddress();
        IERC20 compToken = IERC20(compAddr);
        uint compBalance = compToken.balanceOf(address(this));
        compToken.transfer(msg.sender, compBalance);

        // ensure sufficient underlying balance
        IERC20 token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), 2);

        // conduct flashloan for repayment
        uint borrowBal = getBorrowBalance(_cToken);
        _initiateFlashLoan(_solo, _token, _cToken, 0, borrowBal, Direction.Repay);

        // Underlying
        uint tknAmount = token.balanceOf(address(this));
        token.transfer(msg.sender, tknAmount);
    }

    function _initiateFlashLoan(address _solo, address _token, address _cToken, uint256 _amountProvided, uint256 _loanAmount, Direction _direction) internal {
        ISoloMargin solo = ISoloMargin(_solo);

        // Get marketId from token address
        uint256 marketId = _getMarketIdFromTokenAddress(_solo, _token);

        // Calculate repay amount (_loanAmount + (2 wei))
        // Approve transfer from
        uint256 repayAmount = _getRepaymentAmountInternal(_loanAmount);
        IERC20(_token).approve(_solo, repayAmount);

        // 1. Withdraw $, 2. Call callFunction(...), 3. Deposit back $
        Actions.ActionArgs[] memory operations = new Actions.ActionArgs[](3);
        operations[0] = _getWithdrawAction(marketId, _loanAmount);
        CallData memory cdata = CallData( _solo, _token, _cToken, _amountProvided, _loanAmount, repayAmount, _direction );
        operations[1] = _getCallAction( abi.encode(cdata) );    // Encode MyCustomData for callFunction
        operations[2] = _getDepositAction(marketId, repayAmount);

        Account.Info[] memory accountInfos = new Account.Info[](1);
        accountInfos[0] = _getAccountInfo();

        solo.operate(accountInfos, operations);
    }

    // This is the function that will be called postLoan
    function callFunction( address sender, Account.Info memory account, bytes memory data ) public {
        CallData memory cd = abi.decode(data, (CallData));
        uint256 balOfLoanedToken = IERC20(cd.token).balanceOf(address(this));

        require(balOfLoanedToken >= cd.repayAmount, "Not enough funds to repay dydx loan!");

        // deposit funds to relevant cToken contract - (amountProvided + loanAmount)
        // trigger enterMarkets on comptroller - (loanAmount + 2 wei = repayAmount)
        // transfer ERC20 amount back to loan provider
        if(cd.direction == Direction.Borrow){
            deposit(cd.cToken, (cd.loanAmount + cd.amountProvided));
            borrow(cd.cToken, cd.loanAmount);
        } else if(cd.direction == Direction.Repay) {
            repay(cd.cToken, cd.loanAmount);
            uint cTknBal = getCTokenBalance(cd.cToken);
            redeem(cd.cToken, cTknBal);
        }
        
        // revert("Hello, you haven't encoded your logic");
    }
}