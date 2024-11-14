const { verify } = require("../helper-functions");
const { networkConfig, developmentChains } = require("../helper-hardhat-config");
const { ethers } = require("hardhat");
const { ADDRESS_ZERO } = require("../helper-hardhat-config");

const deployShopTreeToken = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log,get } = deployments;
  const { deployer } = await getNamedAccounts();
  const pricefeed = ADDRESS_ZERO; // placeholder, will replace with uniswap interface later
  log("----------------------------------------------------");
  log("Deploying Trading Tree Token Market Contract and waiting for confirmations...");
  const treeToken = await get("TreeToken");
  /*
  address vrfCoordinatorV2,
  uint64 subscriptionId,
  bytes32 gasLane, // keyHash
  address priceFeed,
  uint32 callbackGasLimit,
  uint256 mintPrice_,
  address treeTokenAddress,
  address stakingPoolAddress,
  uint256 fertilizerPrice_
  */
 
  const ShopTreeToken = await deploy("TreeNFT", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });
  log(`Purchase Tree Token at ${ShopTreeToken.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(ShopTreeToken.address, []);
  }

};


module.exports = deployShopTreeToken;
deployShopTreeToken.tags = ["all", "shop"];
