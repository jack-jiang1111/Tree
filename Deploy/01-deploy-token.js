/*
1. tree token contract
2. time-lock
3. deploy-governor-contract
4. setup-governance-contract
5. staking
6. market
7. treeNft
*/

const { verify } = require("../helper-functions");
const { networkConfig, developmentChains } = require("../helper-hardhat-config");
const { ethers } = require("hardhat");

const deployGovernanceToken = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------------------------------");
  log("Deploying Tree Token and waiting for confirmations...");
  const governanceToken = await deploy("TreeToken", {
    from: deployer,
    args: [],
    log: true,
    waitConfirmations: 1,
  });
  log(`Governance Tree Token at ${governanceToken.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(governanceToken.address, []);
  }

  log(`Delegating to ${deployer}`);
  await delegate(governanceToken.address, deployer);
  log("Delegated!");
};

const delegate = async (governanceTokenAddress, delegatedAccount) => {
  const governanceToken = await ethers.getContractAt("TreeToken", governanceTokenAddress);
  const transactionResponse = await governanceToken.delegate(delegatedAccount);
  await transactionResponse.wait(1);
  console.log(`Checkpoints: ${await governanceToken.numCheckpoints(delegatedAccount)}`);
};

module.exports = deployGovernanceToken;
deployGovernanceToken.tags = ["all", "governor"];
