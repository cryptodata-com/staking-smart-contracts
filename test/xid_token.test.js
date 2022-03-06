const XidenERC20 = artifacts.require("XidenERC20");
const StakingContract = artifacts.require("Staking");

var chai = require("chai");
const BN = web3.utils.BN;
const chaiBN = require('chai-bn')(BN);
chai.use(chaiBN);

var chaiAsPromised = require("chai-as-promised");
chai.use(chaiAsPromised);

const expect = chai.expect;

contract("XidenERC20 Token", async accounts => {

  const _name = 'XIDEN Staking';
  const _symbol = 'sXID';
  const _decimals = new BN("18");
  const _totalSupply = new BN("200000000000000000000000000");
  const _owner = accounts[4];
  const _newMint = new BN("5381");

  beforeEach(async () => {
    this.stakingContract = await StakingContract.deployed();
    this.token = await XidenERC20.deployed(this.stakingContract.address);
  })

  describe("Token attributes", async () => {
    it('has the correct name', async () => {
      expect(await this.token.name()).to.be.equal(_name)
    });

    it('has the correct symbol', async () => {
      expect(await this.token.symbol()).to.be.equal(_symbol)
    });

    it('has the correct decimals', async () => {
      expect(await this.token.decimals()).to.be.a.bignumber.equal(_decimals)
    });
  })

  describe('Owner attributes', async () => {
    it('has correct owner', async () => {
      expect(await this.token.owner()).to.be.equal(_owner)
    })

    it('has the total supply minted', async () => {
      expect(await this.token.balanceOf(_owner)).to.be.a.bignumber.equal(_totalSupply)
    })
  })

  describe('Mint/Burn/Pause', async () => {
    it('can mint new tokens', async () => {
      await this.token.mint(accounts[1], _newMint)
      expect(await this.token.balanceOf(accounts[1])).to.be.a.bignumber.equal(_newMint);
    })

    it('can burn tokens', async () => {
      await this.token.burn(_newMint)
      expect(await this.token.balanceOf(_owner)).to.be.a.bignumber.equal(_totalSupply.sub(_newMint));
    })

    it('can not transfer when paused', async () => {
      await this.token.pause()
      await expect(this.token.transfer(accounts[4], accounts[1], 1000)).to.eventually.be.rejected;
    })
  })
})