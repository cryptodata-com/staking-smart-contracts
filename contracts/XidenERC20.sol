// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title XIDEN ERC20 Token - sXID (symbol)
/// @author CryptoDATA TEAM (5381)
/// @notice ERC20 token that holds coinbase and adds node validators,
/// @notice it interacts with the Staking Contract on zero address
/// @dev It must hold the coinbase value in exchange for tokens
//
//  ██╗  ██╗██╗██████╗ ███████╗███╗   ██╗    ███████╗██████╗  ██████╗██████╗  ██████╗
//  ╚██╗██╔╝██║██╔══██╗██╔════╝████╗  ██║    ██╔════╝██╔══██╗██╔════╝╚════██╗██╔═████╗
//   ╚███╔╝ ██║██║  ██║█████╗  ██╔██╗ ██║    █████╗  ██████╔╝██║      █████╔╝██║██╔██║
//   ██╔██╗ ██║██║  ██║██╔══╝  ██║╚██╗██║    ██╔══╝  ██╔══██╗██║     ██╔═══╝ ████╔╝██║
//  ██╔╝ ██╗██║██████╔╝███████╗██║ ╚████║    ███████╗██║  ██║╚██████╗███████╗╚██████╔╝
//  ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚══════╝╚═╝  ╚═╝ ╚═════╝╚══════╝ ╚═════╝

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ValidatorStaking.sol";

contract XidenERC20 is
    ERC20,
    ERC20Burnable,
    Pausable,
    Ownable,
    ValidatorStaking
{
    uint128 private constant VALIDATOR_STAKE_AMOUNT_SXID = 2e6 * 10**18;
    uint128 private constant VALIDATOR_STAKE_AMOUNT_XDEN = 2e6 * 10**18;
    uint128 private constant SXID_INITIAL_SUPPLY = 2e8;
    address private immutable stakingContract;

    event NewMachineId(address account);

    constructor(address deployedStakingContract)
        ERC20("XIDEN Staking", "sXID")
    {
        require(
            deployedStakingContract != address(0x0),
            "Parent address can't be the zero address"
        );
        _mint(msg.sender, SXID_INITIAL_SUPPLY * 10**decimals());
        stakingContract = deployedStakingContract;
    }

    /// @notice Add a new machine id to the whitelist of validator nodes
    /// @dev Only owner can add a license
    /// @param machineId UUID v4
    /// @return boolean
    function addMachineId(string calldata machineId)
        external
        onlyOwner
        whenNotPaused
        returns (bool)
    {
        _addNewMachineId(machineId);
        emit NewMachineId(msg.sender);
        return true;
    }

    /// @notice Add a new node as validator
    /// @dev To compute the _signature you need to use getMessageHash and then
    /// @dev use web3.eth.sign(_messageHash, web3.eth.defaultAccount, console.log)
    /// @param validatorNodeAddress address of the validator node
    /// @param machineId pre-aproved UUID license
    /// @param signature bytes signed hash of a computed message hash
    /// @return bool true or false
    function stake(
        address validatorNodeAddress,
        string memory machineId,
        bytes memory signature
    ) external payable returns (bool) {
        require(
            validatorNodeAddress != address(0x0),
            "Invalid validator node address"
        );
        require(
            balanceOf(msg.sender) >= VALIDATOR_STAKE_AMOUNT_SXID,
            "Insuficient funds to stake"
        );
        require(signature.length == 65, "Invalid signature length");

        _burn(msg.sender, VALIDATOR_STAKE_AMOUNT_SXID);
        _setNewStake(
            validatorNodeAddress,
            VALIDATOR_STAKE_AMOUNT_SXID,
            machineId,
            signature
        );

        (bool stakeCallComplete, ) = address(stakingContract).call{
            value: VALIDATOR_STAKE_AMOUNT_XDEN
        }(abi.encodeWithSignature("stake(address)", validatorNodeAddress));
        require(stakeCallComplete, "Unable to stake on parent contract");
        return stakeCallComplete;
    }

    /// @notice Remove validator node
    /// @param validatorNodeAddress Account of the validator node
    /// @param machineId Whitelist UUID machine ID license
    /// @return bool true or false
    function unstake(address validatorNodeAddress, string calldata machineId)
        external
        returns (bool)
    {
        require(
            validatorNodeAddress != address(0x0),
            "Invalid validator node address"
        );
        _removeStake(validatorNodeAddress, machineId);
        _mint(msg.sender, VALIDATOR_STAKE_AMOUNT_SXID);

        (bool unstakeCallComplete, ) = address(stakingContract).call(
            abi.encodeWithSignature("unstake(address)", validatorNodeAddress)
        );
        require(
            unstakeCallComplete,
            "Something went sideways trying to unstake"
        );
        return unstakeCallComplete;
    }

    /// @notice In case of emergency pause the contract
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpause the contract and resume business
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Can use it to mint new tokens
    /// @param account the account where to mint new tokens
    /// @param amount amount of tokens in wei
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /// @notice not possible with this smart contract
    function renounceOwnership() public view override onlyOwner {
        revert("can't renounceOwnership here");
    }

    /// @dev make sure no transfers are allowed if contract == paused
    function _beforeTokenTransfer(
        address from,
        address validatorNodeAddress,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, validatorNodeAddress, amount);
    }

    receive() external payable {}
}
