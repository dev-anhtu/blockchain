// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import 'hardhat/console.sol';

contract Escrow {
    IERC20 token;
    address public depositor;
    address public recipient;
    uint public balance;
    uint public withdrawTime;

    modifier notMatch(address address1, address address2) {
        require(address1 != address2, 'addresses must not match');
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender == depositor, 'sender must be the depositor');
        _;
    }

    modifier onlyRecipient() {
        require(msg.sender == recipient, 'sender must be the recipient');
        _;
    }

    function deposit(IERC20 _token, address _recipient, uint _balance, uint _withdrawTime) external notMatch(msg.sender, _recipient) {
        require(_balance > 0, 'balance must be greater than 0');

        token = _token;
        depositor = msg.sender;
        recipient = _recipient;
        balance = _balance;
        withdrawTime = block.timestamp + _withdrawTime;

        token.transferFrom(depositor, address(this), balance);
    }

    function withdraw() external onlyRecipient {
        require(block.timestamp <= withdrawTime, 'withdraw time is expired');
        token.transfer(msg.sender, balance);
    }

    function refund() public onlyDepositor {
        require(block.timestamp > withdrawTime, 'refund time must be in the past');
        token.transfer(msg.sender, balance);
    }
}
