// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {BohdanERC20Token} from "./BohdanERC20Token.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VotingContract is BohdanERC20Token, Ownable, ReentrancyGuard {
    uint256 public timeToVote = 1 weeks;
    uint256 public executionTime = 1 weeks;
    uint256 public amountToBurn;

    bool public actionExecuted;

    uint256 public totalVotesCounted;

    // tests w/ typechain for time dependant things

    struct ProposedVote {
        uint256 vote;
        uint256 power;
        address next;
        address prev;
    }

    mapping(address => ProposedVote) private _proposedPrices;
    mapping(uint256 => address) private _isParticularPriceProposed;
    mapping(address => address) private _voters;
    address private _head;

    uint256 public priceOption;
    uint256 public feePercentage;
    uint256 public votingEndTime;

    mapping(uint256 => uint256) private _votesByPrice;

    constructor(uint256 _feePercentage) {
        feePercentage = _feePercentage;
        votingEndTime = block.timestamp + timeToVote;
        actionExecuted = false;
    }

    function isAbleToVote(address user) public view returns (bool) {
        uint256 balance = _voters[user].balance;
        uint256 minimumBalance = (totalSupply * 5) / 10000; // 0.05% of totalSupply

        return balance > minimumBalance;
    }

    function vote(
        uint256 _option,
        address prev,
        address next
    ) public {
        address voterAddress = msg.sender;
        uint256 voterBalance = balanceOf(voterAddress);

        require(block.timestamp <= votingEndTime, "Voting period has ended");
        require(_option != priceOption, "Already voted for this option");
        require(isAbleToVote(voterAddress), "Not enough balance to vote");

        require(voterBalance > 0, "You do not have any tokens");
        require(_voters[voterAddress] == address(0), "Already voted");

        address index = _isParticularPriceProposed[_option];

        if (_proposedPrices[index].vote == 0) {
            // if voter does not exist then we create one

            totalVotesCounted++; // make +1 for loop so we know the length of mapping

            _proposedPrices[voterAddress] = ProposedVote(
                _option,
                voterBalance,
                prev,
                next
            );

            sortNode(prev, next, voterAddress);
        } else {
            // if it exists, we add the power to the price he wanted
            _proposedPrices[index].power += voterBalance; 
            sortNode(prev, next, index);
        }
    }

    function givePricesList()
        public
        view
        returns (mapping(address => ProposedVote))
    {
        return _proposedPrices;
    }

    function sortNode(
        address prev,
        address next,
        address currentIndex
    ) public {
        if (
            _proposedPrices[prev].power < _proposedPrices[currentIndex].power &&
            _proposedPrices[next].power > _proposedPrices[currentIndex].power &&
            _proposedPrices[prev].next == next
        ) {
            _proposedPrices[currentIndex].prev = prev;
            _proposedPrices[currentIndex].next = next;

            _proposedPrices[prev].next = currentIndex;
            _proposedPrices[next].prev = currentIndex;

            if (_proposedPrices[next].power != 0) {
                if (
                    _proposedPrices[currentIndex].power >
                    _proposedPrices[_head].power
                ) {
                    _head = currentIndex;
                }
            }
        } else {
            revert("Wrong position");
        }
    }

    function endVote() public onlyOwner {
        require(block.timestamp > votingEndTime, "Voting not ended");
        priceOption = _proposedPrices[_head].vote;
    }

    function burnFee() public onlyOwner {
        require(block.timestamp >= executionTime, "Only once a week");
        require(!actionExecuted, "Already executed");

        _voters[address(0)].balance += amountToBurn;
        totalSupply -= amountToBurn;

        actionExecuted = true;
    }

    function buyTokens(address prev, address next, addressCurrentIndex) public payable nonReentrant {
        uint256 fee = (msg.value * feePercentage) / 100;
        uint256 purchaseAmount = (msg.value - fee) * priceOption;

        require(purchaseAmount > 0, "Insufficient payment");

        address voterAddress = msg.sender;
        Voter storage voter = _voters[voterAddress];

        totalSupply += purchaseAmount;
        amountToBurn += fee;
        _balances[voterAddress] += purchaseAmount;

        if(_proposedPrices[votedAddress].vote !== 0) {
            sortNode(prev, next, currentIndex)
        }
    }

    function sellTokens(uint256 _amount, address prev, address next, address currentIndex) public nonReentrant {
        require(_voters[msg.sender].balance >= _amount, "Insufficient balance");

        uint256 fee = (_amount * feePercentage) / 100;
        uint256 saleAmount = (_amount - fee) * priceOption;

        _balances[msg.sender] -= _amount;

        totalSupply -= _amount;
        amountToBurn += fee;

        if(_proposedPrices[votedAddress].vote !== 0) {
            sortNode(prev, next, currentIndex)
        }

        payable(msg.sender).transfer(saleAmount);
    }
}
