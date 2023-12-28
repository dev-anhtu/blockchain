// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Token is ERC20, Ownable(msg.sender) {
    uint8 private _decimals;

    constructor(string memory _name, string memory _symbol, uint8 _tokenDecimals) ERC20(_name, _symbol) {
        _decimals = _tokenDecimals;
        _mint(msg.sender, 100_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}
