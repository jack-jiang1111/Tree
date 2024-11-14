const { verify } = require("../helper-functions");
const {
  networkConfig,
  developmentChains,
  QUORUM_PERCENTAGE,
  VOTING_PERIOD,
  VOTING_DELAY,
} = require("../helper-hardhat-config");

const deployGovernorContract = async function (hre) {
  const { getNamedAccounts, deployments, network } = hre;
  const { deploy, log, get } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId
  const governanceToken = await get("TreeToken");
  const timeLock = await get("TimeLock");
  const args = [
    governanceToken.address,
    timeLock.address,
    QUORUM_PERCENTAGE,
    VOTING_PERIOD,
    VOTING_DELAY,
  ];
  log("----------------------------------------------------");
  log("Deploying GovernorContract and waiting for confirmations...");
  const governorContract = await deploy("GovernorContract", {
    from: deployer,
    args,
    log: false,
    waitConfirmations:1,
    gasLimit: networkConfig[chainId]["callbackGasLimit"],
  });
  log(`GovernorContract at ${governorContract.address}`);

  if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
    await verify(governorContract.address, args);
  }
};

module.exports = deployGovernorContract;
deployGovernorContract.tags = ["all", "governor"];
