// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract VRFMock is VRFCoordinatorV2Mock {
    constructor(uint96 _baseFee, uint96 _gasPriceLink)
        VRFCoordinatorV2Mock(_baseFee, _gasPriceLink)
    {}
}
