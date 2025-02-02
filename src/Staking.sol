// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Staking is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 duration;
    }

    // Constants
    uint256 public constant YEAR = 365 days;
    uint256 public minStakingDuration = 7 days;
    uint256 public maxStakingDuration = 365 days;
    uint256[] public stakingPeriod = [30, 90, 180, 360];
    uint256[] public APR = [10,32,70,150]; 

    error Staking__WrongStakePeriod();

    // State variables
    mapping(address => Stake) public stakes;
    uint256 public totalStaked;

    // Events
    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Withdrawn(address indexed user, uint256 amount, uint256 reward);
    event RewardClaimed(address indexed user, uint256 reward);

    // constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    // we don't use contructor in implementation contract,
    // because it only change the implementation contract storage slot, not the proxy contract
    constructor() {
        // make sure that no initializer is call during constructor
        _disableInitializers();
    }

    // this function treat as constructor for the proxy
    // initializer modifier will make sure that this function only call once
    function initialize() external initializer {
        __Ownable_init(msg.sender); // sets owner to: owner = msg.sender
        __UUPSUpgradeable_init();
    }

    // Modifiers
    modifier validateStakingDuration(uint256 duration) {
        bool isValid = false;
        for (uint256 i = 0; i < stakingPeriod.length; i++) {
            if (duration == stakingPeriod[i]) {
                isValid = true;
            }
        }
        if (!isValid) {
            revert Staking__WrongStakePeriod();
        }
        _;
    }

    // Calculate rewards for a given stake
    function calculateReward(
        Stake memory _stake
    ) public view returns (uint256) {
        if (_stake.amount == 0) return 0;
        uint256 staketime = block.timestamp - _stake.startTime;

        if (staketime >= 60 * 60 * 24 * stakingPeriod[3]) {
            return _stake.amount * APR[3] / 1000;
        }
        else if (staketime >= 60 * 60 * 24 * stakingPeriod[2]) {
            return _stake.amount * APR[2] / 1000;
        }
        else if (staketime >= 60 * 60 * 24 * stakingPeriod[1]) {
            return _stake.amount * APR[1] / 1000;
        }
        else {
            return _stake.amount * APR[0] / 1000;
        }
    }

    // View function to check pending rewards
    function getPendingReward(address _staker) external view returns (uint256) {
        return calculateReward(stakes[_staker]);
    }

    // Stake AVAX
    function stake(
        uint256 _duration
    ) external payable validateStakingDuration(_duration) {
        require(msg.value > 0, "Cannot stake 0 AVAX");
        require(stakes[msg.sender].amount == 0, "Already staking");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            duration: _duration
        });

        totalStaked = totalStaked + msg.value;

        emit Staked(msg.sender, msg.value, _duration);
    }

    // Withdraw staked AVAX and rewards
    function withdraw() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");
        require(block.timestamp >= userStake.startTime + 60 * 60 * 24 * stakingPeriod[0], "Minium stake time required");

        uint256 reward = calculateReward(userStake);
        uint256 amount = userStake.amount;

        // Reset stake
        totalStaked = totalStaked - amount;
        delete stakes[msg.sender];

        // Transfer staked amount and reward
        (bool success, ) = payable(msg.sender).call{value: amount + reward}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount, reward);
    }

    // // Claim only rewards
    // function claimRewards() external {
    //     Stake storage userStake = stakes[msg.sender];
    //     require(userStake.amount > 0, "No active stake");
    //     require(block.timestamp >= userStake.startTime + 60 * 60 * 24 * 30, "Minium stake time required");
    //     uint256 reward = calculateReward(userStake);
    //     require(reward > 0, "No rewards to claim");

    //     (bool success, ) = payable(msg.sender).call{value: reward}("");
    //     require(success, "Transfer failed");

    //     emit RewardClaimed(msg.sender, reward);
    // }

    // Admin functions
    function updateStakingSettings(
        uint256[] memory _stakingPeriod,
        uint256[] memory _apr
    ) external onlyOwner {
        stakingPeriod = _stakingPeriod;
        APR = _apr;
    }

    // Function to receive AVAX
    receive() external payable {}

    // Function to check contract AVAX balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // The following functions are overrides required by Solidity.
    function _authorizeUpgrade(
        address _newImplementation
    ) internal override onlyOwner {}
}
