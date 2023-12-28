// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import 'hardhat/console.sol';

contract Swap {
    IERC20 public bnbToken;
    IERC20 public usdtToken;

    uint256 public bnbAmount;
    uint256 public usdtAmount;

    uint256 public k;

    function initialize(address _bnbAddress, address _usdtAddress, uint256 _bnbAmount, uint256 _usdtAmount) public {
        bnbToken = IERC20(_bnbAddress);
        usdtToken = IERC20(_usdtAddress);

        bnbToken.transferFrom(msg.sender, address(this), _bnbAmount);
        usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);

        bnbAmount = _bnbAmount;
        usdtAmount = _usdtAmount;

        console.log(bnbAmount);

        k = bnbAmount * usdtAmount;
    }

    function buy(uint256 _bnbAmount) public {
        require(_bnbAmount > 0);
        require(_bnbAmount <= bnbAmount, 'not enough bnb');

        uint256 newBnbAmount = bnbAmount - _bnbAmount;
        uint256 _usdtAmount = (k / newBnbAmount) - usdtAmount;

        usdtToken.transferFrom(msg.sender, address(this), _usdtAmount);
        bnbToken.transferFrom(address(this), msg.sender, _bnbAmount);

        usdtAmount = usdtAmount + _usdtAmount;
        bnbAmount = newBnbAmount;
    }
}
