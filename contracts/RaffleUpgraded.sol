// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {RaffleAccessControl} from "./RaffleAccessControl.sol";
import {ConsumerBase} from "./ConsumerBase.sol";

// USDT for Uniswap (ETH MAINNET) 0xdAC17F958D2ee523a2206206994597C13D831ec7
// npx hardhat node --fork https://mainnet.infura.io/v3/9da4b61767434810949acae93347ae39

contract BohdanRaffleUpgraded is RaffleAccessControl, OwnableUpgradeable {
    uint256 public raffleMoneyPoolUSD;
    uint256 public ownerFee;
    uint256 public contractFee;

    IUniswapV2Router02 private _router;
    address private _weth = _router.WETH();

    uint256 private _currentRoundID;
    bool private _isRollActive;

    ConsumerBase private _consumer;

    struct UserInfo {
        address user;
        uint256 from;
        uint256 to;
    }

    struct AllowedToken {
        IERC20 token;
        AggregatorV3Interface priceFeed;
    }

    UserInfo[] private _participants;

    mapping(address => AllowedToken) public acceptedTokens;

    address public usdt;

    event Deposit(address indexed user, IERC20 token, uint256 indexed amount);
    event RollStarted(uint256 indexed currentRoundID, uint256 timestamp);
    event RollEnded(
        uint256 indexed currentRoundID,
        uint256 timestamp,
        address winner,
        uint256 winnerValueETH
    );

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */

    function initialize(
        ConsumerBase consumer,
        address raffleConroller,
        address dexRouter,
        uint256 ownerFee_,
        uint256 contractFee_
    ) public initializer {
        __Ownable_init();
        _router = IUniswapV2Router02(dexRouter);
        _grantRole(RAFFLE_ADMIN, raffleConroller);
        _consumer = consumer;
        usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        ownerFee = ownerFee_;
        contractFee = contractFee_;
    }

    constructor() {
        _disableInitializers();
    }

    function setOwnerFee(uint256 feeAmount) public onlyOwner {
        ownerFee = feeAmount;
    }

    function setContractFee(uint256 feeAmount) public onlyOwner {
        contractFee = feeAmount;
    }

    function setConsumer(ConsumerBase consumer) public onlyOwner {
        _consumer = consumer;
    }

    function setUniswapRouteAddress(address uniswapRouter) public onlyOwner {
        _router = IUniswapV2Router02(uniswapRouter);
    }

    modifier onlyAcceptedToken(address _token) {
        require(
            acceptedTokens[_token].token != IERC20(address(0)),
            "Token not accepted"
        );
        _;
    }

    function addAcceptedToken(address _token, address _aggregatorToUSDAddress)
        external
        onlyOwner
    {
        acceptedTokens[_token].token = IERC20(_token);
        acceptedTokens[_token].priceFeed = AggregatorV3Interface(
            _aggregatorToUSDAddress
        );
    }

    function removeAcceptedToken(address _token) external onlyOwner {
        acceptedTokens[_token].token = IERC20(address(0));
        acceptedTokens[_token].priceFeed = AggregatorV3Interface(address(0));
    }

    function getLatestPrice(AggregatorV3Interface _priceFeed)
        public
        view
        returns (uint256)
    {
        (, int256 price, , , ) = _priceFeed.latestRoundData();
        //price is in int, so we convert it to uint before returning
        uint256 finalPrice = uint256(price);
        return finalPrice;
    }

    function depositToRafflePool(address _token, uint256 _amount)
        external
        onlyAcceptedToken(_token)
    {
        require(!_isRollActive, "Roll in progress");
        require(_amount > 0, "Cannot deposit 0");
        require(!_consumer.locked(), "VRF Locked");
        _consumer.changeLock(true);

        IERC20 tokenContract = IERC20(_token);
        tokenContract.transferFrom(msg.sender, address(this), _amount);

        address[] memory path = new address[](2);
        path[0] = address(tokenContract);
        path[1] = _weth;

        uint256 wethAmount = _router.swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp + 100
        )[1]; // swap user's to WETh

        AggregatorV3Interface ethToUSDPriceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        uint256 latestPrice = getLatestPrice(ethToUSDPriceFeed); // ETH / USD calculation

        uint256 totalValueInUSD = (wethAmount * latestPrice) / 1e8; // divide by chainlink decimals
        raffleMoneyPoolUSD += totalValueInUSD;

        if (raffleMoneyPoolUSD > 0) {
            UserInfo memory newUser = UserInfo({
                user: msg.sender,
                from: _participants[_participants.length - 1].to,
                to: _participants[_participants.length - 1].to + totalValueInUSD
            });
            _participants.push(newUser);
        } else {
            UserInfo memory newUser = UserInfo({
                user: msg.sender,
                from: 0,
                to: totalValueInUSD
            });
            _participants.push(newUser);
        }

        emit Deposit(msg.sender, tokenContract, totalValueInUSD);
        _consumer.changeLock(false);
    }

    function getParticipants()
        external
        onlyRole(RAFFLE_ADMIN)
        returns (UserInfo[] memory)
    {
        _consumer.changeLock(true);

        return _participants;
    }

    function getRandomNumber()
        external
        view
        onlyRole(RAFFLE_ADMIN)
        returns (uint256)
    {
        uint256 randomNumber = _consumer.randomNumber();
        return randomNumber;
    }

    function startRaffle() public onlyRole(RAFFLE_ADMIN) {
        require(!_isRollActive, "Roll started");
        _isRollActive = true;
        _currentRoundID = _currentRoundID + 1;

        emit RollStarted(_currentRoundID, block.timestamp);
    }

    function endRaffle(uint256 randomNumber) public onlyRole(RAFFLE_ADMIN) {
        require(_isRollActive, "Raffle not started");
        require(_participants.length > 0, "No users in raffle");
        require(!_consumer.locked(), "VRF locked");
        _consumer.changeLock(true);

        UserInfo memory winner;

        if (
            _participants[randomNumber + 1].from >= randomNumber &&
            _participants[randomNumber + 1].to <= randomNumber
        ) {
            winner = _participants[randomNumber + 1];
        } else {
            revert("Owner tried to fool us");
        }

        raffleMoneyPoolUSD = 0;

        IERC20 wethContract = IERC20(_weth);
        uint256 ownerFeeAmount = (wethContract.balanceOf(address(this)) *
            ownerFee) / 100;
        uint256 contractFeeAmount = (wethContract.balanceOf(address(this)) *
            contractFee) / 100;
        wethContract.transfer(
            winner.user,
            wethContract.balanceOf(address(this)) -
                contractFeeAmount -
                ownerFeeAmount
        );

        address owner = owner();
        wethContract.transfer(owner, ownerFeeAmount);

        emit RollEnded(
            _currentRoundID,
            block.timestamp,
            winner.user,
            wethContract.balanceOf(address(this)) -
                contractFeeAmount -
                ownerFeeAmount
        );

        _consumer.changeLock(false);
    }
}
