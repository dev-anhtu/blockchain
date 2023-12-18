// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract Key {
    uint private _totalSupply = 0;
    mapping(address => uint) private _balances;

    function deposit(address to, uint amount) public returns (bool) {
        require(amount > 0, 'Amount greater than 0');
        _balances[to] = _balances[to] + amount;
        _totalSupply = _totalSupply + amount;
        return true;
    }

    function balanceOf(address to) public view returns (uint) {
        return _balances[to];
    }

    function withdraw(address to, uint amount) public returns (uint) {
        require(amount > 0 && amount <= _balances[to], 'The withdrawal amount must be greater than 0 and less than the assets you currently have');
        _balances[to] = _balances[to] - amount;
        _totalSupply = _totalSupply - amount;
        return amount;
    }

    function getTotalSupply() public view returns (uint) {
        return _totalSupply;
    }
}
