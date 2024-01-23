// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract RaffleAccessControl is AccessControlUpgradeable {
    bytes32 public constant RAFFLE_ADMIN = keccak256("RAFFLE_ADMIN");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }
}
