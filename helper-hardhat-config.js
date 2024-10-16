const { ethers } = require("hardhat")

const networkConfig = {
    default: {
        name: "hardhat",
        keepersUpdateInterval: "30",
    },
    31337: {
        name: "localhost",
        subscriptionId: "588",
        gasLane: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c", // 30 gwei
        keepersUpdateInterval: "30", // mock every 30 seconds
        callbackGasLimit: "500000", // 500,000 gas
    },
    11155111: {
        name: "sepolia",
        subscriptionId: "51572676631606313810434601680697152095356924584252780340603629995332314120314",
        gasLane: "0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c", // 30 gwei
        keepersUpdateInterval: "604800",
        callbackGasLimit: "500000", // 500,000 gas
        vrfCoordinatorV2: "0x9ddfaca8183c41ad55329bdeed9f6a8d53168b1b",
        ethUsdPriceFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
    },
    1: {
        name: "mainnet",
        keepersUpdateInterval: "30",
    },
}

const developmentChains = ["hardhat", "localhost"]
const VERIFICATION_BLOCK_CONFIRMATIONS = 6
const INITIAL_SUPPLY = "1000000000"
module.exports = {
    networkConfig,
    developmentChains,
    VERIFICATION_BLOCK_CONFIRMATIONS,
}
