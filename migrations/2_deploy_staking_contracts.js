const Staking = artifacts.require("Staking");
const XidenERC20 = artifacts.require("XidenERC20");

module.exports = async deployer => {
  await deployer.deploy(Staking);
  await deployer.deploy(XidenERC20, Staking.address);
};
