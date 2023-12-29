// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Swap {
    event Funded(address indexed sender, uint bnbAmount, uint usdtAmount);

    IERC20 public bnbToken;
    IERC20 public usdtToken;

    uint public bnbAmount;
    uint public usdtAmount;
    uint public k;

    constructor(IERC20 _bnbToken, IERC20 _usdtToken) {
        bnbToken = _bnbToken;
        usdtToken = _usdtToken;
    }

    modifier hasBeenFunded() {
        require(bnbAmount > 0 && usdtAmount > 0, 'Contract has not been funded yet');
        _;
    }

    function fund(uint _bnbAmount, uint _usdtAmount) public {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(_usdtAmount > 0, 'Invalid USDT amount');

        require(bnbToken.transferFrom(msg.sender, address(this), _bnbAmount), 'BNB transfer failed');
        require(usdtToken.transferFrom(msg.sender, address(this), _usdtAmount), 'USDT transfer failed');

        bnbAmount += _bnbAmount;
        usdtAmount += _usdtAmount;

        k = bnbAmount * usdtAmount;

        emit Funded(msg.sender, _bnbAmount, _usdtAmount);
    }

    function buy(uint256 _bnbAmount) public hasBeenFunded {
        require(_bnbAmount > 0, 'Invalid BNB amount');
        require(_bnbAmount < bnbAmount, 'Not enough BNB');

        uint256 newBnbAmount = bnbAmount - _bnbAmount;
        uint256 _usdtAmount = k / newBnbAmount - usdtAmount;

        require(usdtToken.balanceOf(msg.sender) >= _usdtAmount, 'Your USDT balance is not enough');
        require(usdtToken.transfer(address(this), _usdtAmount), 'USDT transfer failed');

        bnbToken.transfer(msg.sender, _bnbAmount);

        usdtAmount += _usdtAmount;
        bnbAmount = newBnbAmount;
    }
}
