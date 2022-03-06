const StakingContract = artifacts.require("Staking");
const XidenERC20 = artifacts.require("XidenERC20");

var chai = require("chai");
const BN = web3.utils.BN;
const chaiBN = require('chai-bn')(BN);
chai.use(chaiBN);

var chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);

const expect = chai.expect;

contract("XidenERC20 Staking", async accounts => {

  const machineId = '177cfd9e-997f-11ec-b909-0242ac120002';
  const machineId1 = '46d2685f-e13a-4b1b-81be-1c779a26b515';
  const machineId2 = '9f932975-7cd5-45e2-9522-2590d6dc5390';
  const machineId3 = '7c40c29f-8b94-4eb6-8377-93274b47fa48';
  const machineId4 = 'a7fab5ff-956e-46cf-b317-0aeac4b12187';

  /*
  # ---
  # Staking.sol 
  # uint128 private constant VALIDATOR_THRESHOLD = 32 gwei;
  # ---
  # XidenERC20.sol
  # uint128 private constant VALIDATOR_STAKE_AMOUNT_SXID = 1000 ether;
  # uint128 private constant VALIDATOR_STAKE_AMOUNT_ETHER = 32 gwei;
  # ---
  */

  const transferAmount = web3.utils.toWei('50', 'gwei') // for test you need to change the values from the smart contract
  const xidTokenAmount = web3.utils.toWei('1000', 'ether') // for test you need to change the values from the smart contract
  const [node0, validatorNode, node1, node3, owner, node4] = accounts

  beforeEach(async () => {
    this.stakingContract = await StakingContract.deployed()
    this.token = await XidenERC20.deployed(this.stakingContract.address)
    const messageHash = await this.token.getMessageHash(validatorNode, machineId)
    signature = await web3.eth.sign(messageHash, owner);

    // little hack thanks to 
    // https://ethereum.stackexchange.com/questions/76810/sign-message-with-web3-and-verify-with-openzeppelin-solidity-ecdsa-sol
    this.signedHash = signature.substr(0, 130) + (signature.substr(130) == "00" ? "1b" : "1c");
  })

  describe('Staking', async () => {
    it('should fail, with insuficient token funds', async () => {
      await expect(this.token.stake(validatorNode, machineId, this.signedHash, { from: validatorNode })).to.eventually.be.rejected
    })

    it('should fail, with machineId not whitelisted', async () => {
      await expect(this.token.stake(validatorNode, machineId, this.signedHash)).to.eventually.be.rejected
    })

    it('should fail, for validatorNode in validators list', async () => {
      await expect(this.stakingContract.isValidator(validatorNode)).to.eventually.be.false
    })

    it('should be able to add new machine ID', async () => {
      await expect(this.token.addMachineId(machineId)).to.eventually.be.fulfilled
    })

    it('should be able to stake', async () => {
      await expect(this.token.sendTransaction({ to: this.token.address, from: node4, value: transferAmount })).to.eventually.be.fulfilled
      await expect(this.token.stake(validatorNode, machineId, this.signedHash, { from: owner })).to.eventually.be.fulfilled
    })

    it('validatorNode should be on the validators list', async () => {
      await expect(this.stakingContract.isValidator(validatorNode)).to.eventually.be.true
    })
  })

  describe('Unstake', async () => {
    it('should fail because MINIMUM_REQUIRED_NUM_VALIDATORS', async () => {
      await expect(this.token.unstake(validatorNode, machineId, { from: owner })).to.eventually.be.rejected
    })

    it('should pass after 4 more new stakes', async () => {
      // send coinbase to the XID token contract to be able to stake
      await expect(this.token.sendTransaction({ to: this.token.address, from: node4, value: transferAmount * 4 })).to.eventually.be.fulfilled

      // send tokens to the account that will call stake
      await expect(this.token.transfer(node0, xidTokenAmount)).to.eventually.be.fulfilled
      await expect(this.token.transfer(node1, xidTokenAmount)).to.eventually.be.fulfilled
      await expect(this.token.transfer(node3, xidTokenAmount)).to.eventually.be.fulfilled
      await expect(this.token.transfer(node4, xidTokenAmount)).to.eventually.be.fulfilled

      // add new machineId to the whitelist
      await expect(this.token.addMachineId(machineId1)).to.eventually.be.fulfilled
      await expect(this.token.addMachineId(machineId2)).to.eventually.be.fulfilled
      await expect(this.token.addMachineId(machineId3)).to.eventually.be.fulfilled
      await expect(this.token.addMachineId(machineId4)).to.eventually.be.fulfilled

      // stake and set new node validators
      await expect(this.token.stake(node3, machineId1, this.signedHash, { from: node1 })).to.eventually.be.fulfilled
      await expect(this.token.stake(node4, machineId2, this.signedHash, { from: node3 })).to.eventually.be.fulfilled
      await expect(this.token.stake(node1, machineId3, this.signedHash, { from: node0 })).to.eventually.be.fulfilled
      await expect(this.token.stake(node0, machineId4, this.signedHash, { from: node4 })).to.eventually.be.fulfilled

      // final step is to unstake the first validator
      await expect(this.token.unstake(validatorNode, machineId, { from: owner, gas: 6000000 })).to.eventually.be.fulfilled
    })

    it('validatorNode should no longer be on the validators list', async () => {
      await expect(this.stakingContract.isValidator(validatorNode)).to.eventually.be.false
    })
  })


});