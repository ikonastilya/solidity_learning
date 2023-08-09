// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "hardhat/console.sol";

contract Vesting is Ownable {
    using ECDSA for bytes32;

    uint256 public cliff;
    uint256 public timeDeployed;

    bytes32 public merkleRoot;

    mapping(address => bool) private _claimedUsers;
    mapping(bytes => bool) private _claimedSignatures;

    IERC20 public immutable token;

    constructor(IERC20 vestedToken) {
        token = vestedToken;
        cliff = (60 * 60 * 24 * 365) * 2; // 2 years
        timeDeployed = block.timestamp;
    }

    function changeMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function isAbleToClaim(uint256 amount, bytes32[] calldata merkleProof)
        public
        view
        returns (bool)
    {
        require(timeDeployed + cliff > block.timestamp, "Cliff not ended");
        return
            _claimedUsers[msg.sender] == false &&
            MerkleProof.verify(
                merkleProof,
                merkleRoot,
                keccak256(abi.encodePacked(msg.sender, amount))
            );
    }

    function claim(uint256 amount, bytes32[] calldata merkleProof) public {
        require(isAbleToClaim(amount, merkleProof), "Not able to claim");
        _claimedUsers[msg.sender] = true;
        token.transfer(msg.sender, amount);
    }

    function isAbleToClaimSignature(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public view returns (bool) {
        require(timeDeployed + cliff > block.timestamp, "Cliff not ended");

        bytes32 message = keccak256(
            abi.encodePacked(msg.sender, amount, nonce, address(this))
        );

        return
            _claimedSignatures[signature] == false &&
            message.toEthSignedMessageHash().recover(signature) == owner();
    }

    function claimWithSignature(
        uint256 amount,
        uint256 nonce,
        bytes calldata signature
    ) public {
        require(
            isAbleToClaimSignature(amount, nonce, signature),
            "Not able to claim"
        );
        _claimedSignatures[signature] = true;
        token.transfer(msg.sender, amount);
    }
}
