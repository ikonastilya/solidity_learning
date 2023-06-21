// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract VotingContract {
    uint256 public timeToVote = 1 weeks;
    uint256 public executionTime = 1 weeks;
    uint256 public amountToBurn;

    bool public actionExecuted;

    struct Voter {
        uint256 balance;
        uint256 vote;
        bool voted;
        address nextVoter;
    }

    mapping(address => Voter) private _voters;
    address private _head;
    uint256 public totalSupply;

    uint256 public priceOption;
    uint256 public feePercentage;
    uint256 public burnAmount;
    uint256 public votingEndTime;

    constructor(uint256 _feePercentage, uint256 _burnAmount) {
        feePercentage = _feePercentage;
        burnAmount = _burnAmount;
        votingEndTime = block.timestamp + timeToVote;
        actionExecuted = false;
    }

    function isAbleToVote(address user) public view returns (bool) {
        uint256 balance = _voters[user].balance;
        uint256 minimumBalance = (totalSupply * 5) / 10000; // 0.05% of totalSupply

        return balance > minimumBalance;
    }

    function vote(uint256 _option) public {
        require(block.timestamp <= votingEndTime, "Voting period has ended");
        require(_option != priceOption, "Already voted for this option");
        require(isAbleToVote(msg.sender), "Not enough balance to vote");

        address voterAddress = msg.sender;
        Voter storage voter = _voters[voterAddress];
        require(voter.balance > 0, "You do not have any tokens");
        require(!voter.voted, "Already voted");

        voter.vote = _option;
        voter.voted = true;

        if (voter.balance > _voters[_head].balance || _head == address(0)) {
            voter.nextVoter = _head;
            _head = voterAddress;
        } else {
            _head = _insertVoter(_head, voterAddress);
        }
    }

    function _insertVoter(address _currentVoter, address _voterToInsert)
        private
        returns (address)
    {
        if (
            _currentVoter == address(0) ||
            _voters[_voterToInsert].balance > _voters[_currentVoter].balance
        ) {
            _voters[_voterToInsert].nextVoter = _currentVoter;
            return _voterToInsert;
        }

        _voters[_currentVoter].nextVoter = _insertVoter(
            _voters[_currentVoter].nextVoter,
            _voterToInsert
        );
        return _currentVoter;
    }

    function burnFee() public {
        require(block.timestamp >= executionTime, "Only once a week");
        require(!actionExecuted, "Already executed");

        _voters[address(0)].balance += amountToBurn;
        totalSupply -= amountToBurn;

        actionExecuted = true;
    }

    function buyTokens() public payable {
        uint256 fee = (msg.value * feePercentage) / 100;
        uint256 purchaseAmount = msg.value - fee;

        require(purchaseAmount > 0, "Insufficient payment");

        if (msg.value > purchaseAmount) {
            payable(msg.sender).transfer(msg.value - purchaseAmount);
        }

        address voterAddress = msg.sender;
        Voter storage voter = _voters[voterAddress];
        voter.balance += purchaseAmount;
        totalSupply += purchaseAmount;

        if (
            voter.balance == purchaseAmount ||
            _head == address(0) ||
            _voters[_head].balance < voter.balance
        ) {
            voter.nextVoter = _head;
            _head = voterAddress;
        } else {
            _insertVoter(_head, voterAddress);
        }
    }

    function sellTokens(uint256 _amount) public {
        require(_voters[msg.sender].balance >= _amount, "Insufficient balance");

        uint256 fee = (_amount * feePercentage) / 100;
        uint256 saleAmount = _amount - fee;

        _voters[msg.sender].balance -= _amount;
        totalSupply -= _amount;

        if (fee > 0) {
            // Burn fee tokens
            amountToBurn += fee;
        }

        payable(msg.sender).transfer(saleAmount * priceOption);
    }
}
