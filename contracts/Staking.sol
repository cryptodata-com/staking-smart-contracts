// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/// @title The Staking Contract for XIDEN (XDEN) PoS Network
/// @author Polygon-Edge TEAM and CryptoDATA TEAM (5381)
/// @notice The Xiden network requires Node validators to stake 2 Million XDEN
//
//   ██╗  ██╗██╗██████╗ ███████╗███╗   ██╗    ███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗
//   ╚██╗██╔╝██║██╔══██╗██╔════╝████╗  ██║    ██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝
//    ╚███╔╝ ██║██║  ██║█████╗  ██╔██╗ ██║    ███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗
//    ██╔██╗ ██║██║  ██║██╔══╝  ██║╚██╗██║    ╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║
//   ██╔╝ ██╗██║██████╔╝███████╗██║ ╚████║    ███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝
//   ╚═╝  ╚═╝╚═╝╚═════╝ ╚══════╝╚═╝  ╚═══╝    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

contract Staking {
    uint128 private constant VALIDATOR_THRESHOLD = 2e6 * 10**18;
    uint32 private constant MINIMUM_REQUIRED_NUM_VALIDATORS = 4;

    // Properties
    address[] public validatorsList;
    mapping(address => bool) addressToIsValidator;
    mapping(address => uint256) addressToStakedAmount;
    mapping(address => uint256) addressToValidatorIndex;
    uint256 private totalStakedAmount;
    mapping(address => address) private delegatedStaker;

    // Events
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);

    // Please no steal
    modifier onlyStaker(address _validatorNode) {
        require(
            delegatedStaker[_validatorNode] == msg.sender,
            "Only staker can call function"
        );
        _;
    }

    constructor() {}

    function stakedAmount() external view returns (uint256) {
        return totalStakedAmount;
    }

    function validators() external view returns (address[] memory) {
        return validatorsList;
    }

    function isValidator(address addr) external view returns (bool) {
        return addressToIsValidator[addr];
    }

    function accountStake(address addr) external view returns (uint256) {
        return addressToStakedAmount[addr];
    }

    // Public functions
    receive() external payable {
        _stake(msg.sender);
    }

    function stake(address validatorNode) external payable returns (bool) {
        require(
            msg.value >= VALIDATOR_THRESHOLD,
            "You need more funds in order to stake!"
        );
        _stake(validatorNode);
        return true;
    }

    function unstake(address validatorNode) external onlyStaker(validatorNode) {
        _unstake(validatorNode);
    }

    // Private functions
    function _stake(address validatorNode) private {
        totalStakedAmount += msg.value;
        addressToStakedAmount[validatorNode] += msg.value;

        if (
            !addressToIsValidator[validatorNode] &&
            addressToStakedAmount[validatorNode] >= VALIDATOR_THRESHOLD
        ) {
            // append to validator set
            addressToIsValidator[validatorNode] = true;
            addressToValidatorIndex[validatorNode] = validatorsList.length;
            delegatedStaker[validatorNode] = msg.sender;
            validatorsList.push(validatorNode);
        }

        emit Staked(validatorNode, msg.value);
    }

    function _unstake(address validatorNode) private {
        require(
            validatorsList.length > MINIMUM_REQUIRED_NUM_VALIDATORS,
            "Number of validators can't be less than MINIMUM_REQUIRED_NUM_VALIDATORS"
        );

        uint256 amount = addressToStakedAmount[validatorNode];
        address delegator = delegatedStaker[validatorNode];
        if (addressToIsValidator[validatorNode]) {
            _deleteFromValidators(validatorNode);
        }

        totalStakedAmount -= amount;
        addressToStakedAmount[validatorNode] = 0;
        delete delegatedStaker[validatorNode];

        emit Unstaked(validatorNode, amount);
        payable(delegator).transfer(amount);
    }

    function _deleteFromValidators(address staker) private {
        require(
            addressToValidatorIndex[staker] < validatorsList.length,
            "index out of range"
        );

        // index of removed address
        uint256 index = addressToValidatorIndex[staker];
        uint256 lastIndex = validatorsList.length - 1;

        if (index != lastIndex) {
            // exchange between the element and last to pop for delete
            address lastAddr = validatorsList[lastIndex];
            validatorsList[index] = lastAddr;
            addressToValidatorIndex[lastAddr] = index;
        }

        addressToIsValidator[staker] = false;
        addressToValidatorIndex[staker] = 0;
        validatorsList.pop();
    }
}
