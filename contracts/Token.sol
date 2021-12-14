// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract TNSGov is ERC20 {

    constructor(string memory name, string memory symbol, uint256 totalSupply) ERC20(name, symbol){
        _mint(msg.sender, totalSupply);
    }

}
