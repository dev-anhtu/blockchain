// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

contract Swap is Ownable {
    event Funded(address indexed sender, uint bnbAmount, uint usdtAmount);

    IERC20 public bnbToken;
    IERC20 public usdtToken;

    uint public bnbAmount;
    uint public usdtAmount;
    uint public k;

    mapping(address => uint) bnbDeposit;

    constructor(IERC20 _bnbToken, IERC20 _usdtToken) Ownable(msg.sender) {
        bnbToken = _bnbToken;
        usdtToken = _usdtToken;
    }

    modifier hasBeenFunded() {
        require(bnbAmount > 0 && usdtAmount > 0, 'Contract has not been funded yet');
        _;
    }

    modifier hasNotBeenFunded() {
        require(bnbAmount == 0 || usdtAmount == 0, 'Contract has been funded yet');
        _;
    }

    function fund(uint _bnbAmount, uint _usdtAmount) external hasNotBeenFunded onlyOwner {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(_usdtAmount > 0, 'Invalid USDT amount');

        require(bnbToken.transferFrom(msg.sender, address(this), _bnbAmount), 'BNB transfer failed');
        require(usdtToken.transferFrom(msg.sender, address(this), _usdtAmount), 'USDT transfer failed');

        bnbAmount += _bnbAmount;
        usdtAmount += _usdtAmount;

        k = bnbAmount * usdtAmount;

        emit Funded(msg.sender, _bnbAmount, _usdtAmount);
    }

    function buy(uint _bnbAmount) external hasBeenFunded {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(_bnbAmount < bnbAmount, 'Not enough BNB');

        uint newBnbAmount = bnbAmount - _bnbAmount;
        uint newUsdtAmount = k / newBnbAmount;

        uint _usdtAmount = newUsdtAmount - usdtAmount;

        require(usdtToken.balanceOf(msg.sender) >= _usdtAmount, 'Your USDT balance is not enough');

        usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);
        bnbToken.transfer(msg.sender, _bnbAmount);

        bnbAmount = newBnbAmount;
        usdtAmount = newUsdtAmount;
    }

    function sell(uint _bnbAmount) external hasBeenFunded {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(bnbToken.balanceOf(msg.sender) >= _bnbAmount, 'Your BNB balance is not enough');

        uint newBnbAmount = bnbAmount + _bnbAmount;
        uint newUsdtAmount = k / newBnbAmount;

        uint _usdtAmount = usdtAmount - newUsdtAmount;

        bnbToken.transferFrom(msg.sender, address(this), _bnbAmount);
        usdtToken.transfer(msg.sender, _usdtAmount);

        bnbAmount = newBnbAmount;
        usdtAmount = newUsdtAmount;
    }

    function deposit(uint _bnbAmount) external hasBeenFunded {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(bnbToken.balanceOf(msg.sender) >= _bnbAmount, 'Your BNB balance is not enough');

        uint newBnbAmount = bnbAmount + _bnbAmount;
        uint newUsdtAmount = (newBnbAmount * usdtAmount) / bnbAmount;

        uint _usdtAmount = newUsdtAmount - usdtAmount;

        require(usdtToken.balanceOf(msg.sender) > _usdtAmount, 'Your USDT balance is not enough');

        bnbToken.transferFrom(msg.sender, address(this), _bnbAmount);
        usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);

        bnbAmount = newBnbAmount;
        usdtAmount = newUsdtAmount;

        k = bnbAmount * usdtAmount;

        bnbDeposit[msg.sender] += _bnbAmount;
    }

    function withdraw(uint _bnbAmount) external hasBeenFunded {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(bnbDeposit[msg.sender] >= _bnbAmount, 'Insufficient BNB');

        uint newBnbAmount = bnbAmount - _bnbAmount;
        uint newUsdtAmount = (newBnbAmount * usdtAmount) / bnbAmount;

        uint _usdtAmount = usdtAmount - newUsdtAmount;

        bnbToken.transfer(msg.sender, _bnbAmount);
        usdtToken.transfer(msg.sender, _usdtAmount);

        bnbAmount = newBnbAmount;
        usdtAmount = newUsdtAmount;

        k = bnbAmount * usdtAmount;

        bnbDeposit[msg.sender] -= _bnbAmount;
    }
}
