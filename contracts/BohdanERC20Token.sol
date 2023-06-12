// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract BohdanERC20Token is IERC20, Ownable {
    uint256 private _tokenPrice = 1;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // todo: totalsupply for owner (?)

    constructor() {
        _mint(50000, msg.sender);
    }

    function _mint(uint256 amount, address to) internal {
        require(amount > 0, "Cannot mint zero");
        require(to != address(0), "Cannot mint to no address");

        _balances[to] += amount;
        _totalSupply += amount;

        emit Transfer(address(this), to, amount);
    }

    function _burn(uint256 amount, address owner) internal onlyOwner {
        require(amount > 0, "Cannot burn zero");
        require(_balances[owner] >= amount, "Not enough to burn");

        _balances[owner] -= amount;
        _totalSupply -= amount;

        emit Transfer(address(0), owner, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) public view returns (uint256) {
        require(user != address(0), "User address invalid");

        return _balances[user];
    }

    function _verifyTransfer(address to, uint256 amount)
        private
        pure
        returns (bool)
    {
        require(to != address(0), "Receiver address cannot be zero");
        require(amount > 0, "Amount cannot be zero");

        return true;
    }

    function _performTransfer(
        address from,
        address to,
        uint256 amount
    ) private returns (bool) {
        _balances[from] -= amount;
        _balances[to] += amount;

        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _verifyTransfer(to, amount);
        require(_balances[msg.sender] >= amount, "Insufficient amount");

        _performTransfer(msg.sender, to, amount);

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address owner,
        address to,
        uint256 amount
    ) external returns (bool) {
        _verifyTransfer(to, amount);
        require(owner != address(0), "Owner address cannot be zero");
        require(
            allowance(owner, msg.sender) >= amount,
            "Insufficient allowance"
        );

        _allowances[owner][msg.sender] -= amount;
        _performTransfer(owner, to, amount);

        emit Transfer(owner, to, amount);

        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        require(owner != address(0), "Owner address cannot be zero");
        require(spender != address(0), "Spender address cannot be zero");

        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        require(spender != address(0), "Spender address cannot be zero");
        require(amount > 0, "Amount cannot be zero");
        require(_balances[msg.sender] >= amount, "Insufficient amount");

        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function symbol() external pure returns (string memory) {
        return "BHD";
    }

    function name() external pure returns (string memory) {
        return "Bohdan Euro";
    }

    function tokenPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function buy() public payable {
        require(msg.value >= _tokenPrice, "Cannot deposit zero tokens");
        uint256 tokenAmount = msg.value / (_tokenPrice);
        _balances[msg.sender] += tokenAmount;

        _totalSupply += tokenAmount;
    }

    function sell(uint256 amount) public {
        require(_balances[msg.sender] > 0, "Cannot withdraw zero tokens");
        require(_balances[msg.sender] > amount, "Withdrawing way too much");

        uint256 withdrawAmount = amount * (_tokenPrice);
        _balances[msg.sender] -= withdrawAmount;

        (bool transfered, ) = msg.sender.call{value: withdrawAmount}("");
        require(transfered, "Transaction not successful");
    }
}
