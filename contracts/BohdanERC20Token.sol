// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BohdanERC20Token is IERC20, Ownable {
    uint256 private _tokenPrice = 1 ether;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() {
        _totalSupply = 50000;
    }

    function mint(uint256 amount, address to) public onlyOwner {
        require(amount >= 0, "Cannot mint zero");
        require(to != address(0), "Cannot mint to no address");

        _balances[to] += amount;
        _totalSupply += amount;

        emit Transfer(address(this), to, amount);
    }

    function burn(uint256 amount, address owner) public onlyOwner {
        require(amount > 0, "Cannot burn zero");
        require(owner != address(0), "Cannot burn from no address");
        require(_balances[owner] >= amount, "Not enough to burn");

        _balances[owner] -= amount;
        _totalSupply -= amount;

        emit Transfer(address(this), owner, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address user) public view returns (uint256) {
        require(user != address(0), "User address invalid");

        return _balances[user];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(to != address(0), "Receiver address cannot be zero");
        require(amount > 0, "Amount cannot be zero");
        require(_balances[msg.sender] >= amount, "Insufficient amount");

        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);

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

    function transferFrom(
        address owner,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(owner != address(0), "Owner address cannot be zero");
        require(to != address(0), "Receiver address cannot be zero");
        require(amount > 0, "Amount cannot be zero");
        require(allowance(owner, msg.sender) >= amount, "Insufficient amount");

        _allowances[owner][msg.sender] -= amount;
        _balances[owner] -= amount;
        _balances[to] += amount;

        emit Transfer(owner, to, amount);

        return true;
    }

    function decimals() external pure returns (uint256) {
        return 18;
    }

    function getTokenPrice() external view returns (uint256) {
        return _tokenPrice;
    }

    function deposit() public payable {
        require(msg.value > 0, "Cannot deposit zero tokens");
        uint256 tokenAmount = msg.value / (_tokenPrice);
        _balances[msg.sender] += tokenAmount;
    }

    function withdraw(address to) public payable {
        require(_balances[msg.sender] > 0, "Cannot withdraw without deposit");
        uint256 withdrawAmount = balanceOf(msg.sender) * (_tokenPrice);
        _balances[msg.sender] = 0;

        bool transfered = transfer(to, withdrawAmount);

        require(transfered, "Transaction not successful");
    }
}
