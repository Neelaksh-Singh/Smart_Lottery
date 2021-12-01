// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Lottery is VRFConsumerBase , Ownable {
    address payable[] public players;
    uint256 public usdEntryFee;
    AggregatorV3Interface internal ethUsdPriceFeed;
    bytes32 public keyHash;
    uint256 public fee;
    uint256 public randomness;
    address payable public recentWinner;
    event RequestedRandomness(bytes32 requestId);

    // state of lottery

    enum LotteryState{
        OPEN, 
        CLOSED,
        F_WINNER
    }
    LotteryState public lottery_state;

    constructor(address _priceFeedAddress, address _vrfCoordinator, address _link, uint256 _fee, bytes32 _keyhash) public VRFConsumerBase(_vrfCoordinator,_link) {
        usdEntryFee = 50*(10**18);
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // lottery is closed at the beginning
        lottery_state = LotteryState.CLOSED; // or simply 1
        fee = _fee;
        keyHash = _keyhash;
    }

    function enter() public payable {
        // $50 minimum
        require(lottery_state == LotteryState.OPEN);
        require(msg.value>= getEntranceFee(),"Not enough ETH!");
        players.push(payable(msg.sender));
    }

    function getEntranceFee() public view returns(uint256) {
        (,int price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price)* 10**10 ; //18 decimal

        //$50, $2000 /ETH
        //50/2000
        // 50 * 100000 / 2000
        uint256 costToEnter = (usdEntryFee * 10**18)/adjustedPrice;
        return costToEnter;
    }
    
    function startLottery() public onlyOwner {
        require(lottery_state == LotteryState.CLOSED, "Can't start lottery yet!!" );
        lottery_state = LotteryState.OPEN;
    }

    function endLottery() public onlyOwner{
        lottery_state = LotteryState.F_WINNER;
        bytes32  requestId = requestRandomness(keyHash,fee);
        emit RequestedRandomness(requestId);
    }

    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        require(lottery_state == LotteryState.F_WINNER,"You aren't there yet!!" );
        require(_randomness > 0, "random-not-found!!");
        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        recentWinner.transfer(address(this).balance);

        //Reset
        players = new address payable[](0);
        LotteryState.CLOSED;
        randomness = _randomness;
    } 
}