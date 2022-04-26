# XIDEN Staking Smart contracts

The blockchain network is build on top of [Polygon Edge](https://polygon.technology/solutions/polygon-edge/ "Polygon Edge") and it is deployed with the IBFT Proof of Stake (PoS) consensus. 

In IBFT networks, approved accounts, known as validators, validate transactions and blocks. Validators take turns to create the next block. Before inserting the block onto the chain, a super-majority (greater than 66%) of validators must first sign the block.

A validator never assumes the “leader”, or “block proposer”, to be correct or honest. Instead it verifies the proposed block just like other consensus engines operating in an untrusted environment (Proof-of-Work, etc.).

## Smart Contracts in this reqository

`Staking.sol` - This smart contract is pre-deployed from block 0 when the chain was initialized, and is available on the address `0x0000000000000000000000000000000000001001`.
`XidenERC20.sol` - XidenERC20 with sXID as symbol, is an ERC20 token interface to interact with the Smart Contract. Node validators will be required to get on the pre-aproved whitelist and stake 2 Milion sXID. The contract will call the `stake(nodeValidator)` funtion on the Staking Smart contract and send 2 Million XDEN that are locked until the `unstake(nodeValidator)` method is called. 

## PoS Features

The core logic behind the Proof of Stake implementation is situated within the [Staking Smart Contract.](https://github.com/cryptodata-com/staking-smart-contracts/blob/main/contracts/Staking.sol "Xiden Staking Smart Contract.")
By staking funds on the Staking Smart Contract, whitelisted addresses can enter the validator set and thus be able to participate in the block production process.


## Installation

```bash
$ npm install
```

## Deploy and build

```bash
# deploy contracts
$ npm run deploy

# build artifacts
$ npm run compile
```

## Test

Because the minimum value to stake is 2 million XDEN and sXID, before runing tests please make sure to change the values of the smart contracts:

```bash
# contracts/Staking.sol 
uint128 private constant VALIDATOR_THRESHOLD = 32 gwei;

# contracts/XidenERC20.sol
uint128 private constant VALIDATOR_STAKE_AMOUNT_SXID = 1000 ether;
uint128 private constant VALIDATOR_STAKE_AMOUNT_ETHER = 32 gwei;
```

and the run the command

```bash
# unit tests
$ npm run test
```


