// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./Interface/IERC20.sol";
import "./Utils/ReentrancyGuard.sol";
import "./Utils/PriceConverter.sol";

contract Shop is ReentrancyGuard {
    using PriceConverter for uint256;

    IERC20 public TreeToken;
    AggregatorV3Interface internal priceFeed;
    uint256 public tokenPriceUsd = 1e16; // $0.01, represented in wei (1e16 = 0.01 USD)

    address public owner;
    uint256 public availableTokens;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event TokensDeposited(address indexed depositor, uint256 tokenAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(IERC20 _treeToken, AggregatorV3Interface _priceFeed) {
        TreeToken = _treeToken;
        priceFeed = _priceFeed;
        owner = msg.sender;
    }

    // user input amount in wei
    function getQuote(uint256 amount) public view returns(uint256){
        return (amount.getConversionRate(priceFeed) * 1e18) / tokenPriceUsd; // Calculate token amount in wei
    }

    // the token price is fixed (0.01$ per token)
    function buyTokens() external payable nonReentrant {
        require(msg.value > 0, "No ETH sent");

        uint256 ethAmount = msg.value;
        uint256 usdAmount = ethAmount.getConversionRate(priceFeed); // Convert ETH to USD
        
        uint256 tokenAmount = (usdAmount * 1e18) / tokenPriceUsd; // Calculate token amount in wei

        require(availableTokens >= tokenAmount, "Not enough tokens available for sale");

        // Transfer tokens to buyer
        availableTokens -= tokenAmount;
        TreeToken.transfer(msg.sender, tokenAmount);

        emit TokensPurchased(msg.sender, ethAmount, tokenAmount);
    }

    // Function for the owner to deposit tokens into the contract
    function depositTokens(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Cannot deposit 0 tokens");

        availableTokens += _amount;
        TreeToken.transferFrom(msg.sender, address(this), _amount);

        emit TokensDeposited(msg.sender, _amount);
    }

    // Owner can withdraw ETH from contract
    function withdrawEth(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount <= address(this).balance, "Not enough ETH balance");
        payable(owner).transfer(_amount);
    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }
}