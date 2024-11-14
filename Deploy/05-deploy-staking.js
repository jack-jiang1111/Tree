const { verify } = require("../helper-functions");
const { networkConfig, developmentChains } = require("../helper-hardhat-config");
const { ethers } = require("hardhat");

const deployStakingTreeToken = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log,get } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------------------------------");
  log("Deploying Staking Tree Token Contract and waiting for confirmations...");
  const treeToken = await get("TreeToken");
  const StakingTreeToken = await deploy("StakingTree", {
    from: deployer,
    args: [treeToken.address],
    log: true,
    waitConfirmations: 1,
  });
  log(`Staking Tree Token at ${StakingTreeToken.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(StakingTreeToken.address, []);
  }

};


module.exports = deployStakingTreeToken;
deployStakingTreeToken.tags = ["all", "staking"];
