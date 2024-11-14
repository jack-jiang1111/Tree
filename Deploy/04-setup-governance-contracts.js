const { ADDRESS_ZERO } = require("../helper-hardhat-config");
const { ethers } = require("hardhat");

const setupContracts = async function (hre) {
  const { getNamedAccounts, deployments } = hre;
  const { log, get } = deployments; // Use `get` from `deployments`
  const { deployer } = await getNamedAccounts();
  
  const signer = await ethers.getSigner(deployer)
  const timeLock = await get("TimeLock");
  const governor = await get("GovernorContract");

  const timeLockContract = await ethers.getContractAt("TimeLock", timeLock.address, signer);
  const governorContract = await ethers.getContractAt("GovernorContract", governor.address, signer);

  log("----------------------------------------------------");
  log("Setting up contracts for roles...");

  const proposerRole = await timeLockContract.PROPOSER_ROLE();
  const executorRole = await timeLockContract.EXECUTOR_ROLE();
  const adminRole = await timeLockContract.TIMELOCK_ADMIN_ROLE();

  const proposerTx = await timeLockContract.grantRole(proposerRole, governorContract.address);
  await proposerTx.wait(1);

  const executorTx = await timeLockContract.grantRole(executorRole, ADDRESS_ZERO);
  await executorTx.wait(1);

  const revokeTx = await timeLockContract.revokeRole(adminRole, deployer);
  await revokeTx.wait(1);

  log("Roles setup complete! Now, all actions by the timelock must go through the governance process.");
};

module.exports = setupContracts;
setupContracts.tags = ["all", "setup"];
