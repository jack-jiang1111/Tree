const { verify } = require("../helper-functions");
const { networkConfig, developmentChains, MIN_DELAY } = require("../helper-hardhat-config");

const deployTimeLock = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  log("----------------------------------------------------");
  log("Deploying TimeLock and waiting for confirmations...");
  const timeLock = await deploy("TimeLock", {
    from: deployer,
    // minDelay is how long you have to wait before executing
    // proposers is the list of addresses that can propose
    // executors is the list of addresses that can execute
    //`admin`: optional account to be granted admin role; disable with zero address
    args: [MIN_DELAY, [], [], deployer],
    log: true,
    waitConfirmations: 1,
  });
  log(`TimeLock at ${timeLock.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(timeLock.address, []);
  }
};

module.exports = deployTimeLock;
deployTimeLock.tags = ["all", "timelock"];
