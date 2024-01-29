// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
import '@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol';

contract FundMe{

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed; // 0x694AA1769357215DE4FAC081bf1f309aDC325306

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable{
        // 50$
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) > minimumUSD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }   

    function getVersion() public view returns (uint256){
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        return (ethPrice * ethAmount) / 1000000000000000000;
    }

    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        // return (minimumUSD * precision) / price;
        // We fixed a rounding error found in the video by adding one!
        return ((minimumUSD * precision) / price) + 1;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function withdraw() payable onlyOwner public{
        address payable sender = payable(msg.sender);
        sender.transfer(address(this).balance);
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}