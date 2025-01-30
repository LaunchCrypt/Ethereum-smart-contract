// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LinearStaking is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    struct Stake {
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        uint256 lastClaimTime;
    }

    // Constants
    uint256 public constant YEAR = 365 days;
    uint256 public constant APR = 1000; // 10% APR, can be adjusted
    uint256 public minStakingDuration = 7 days;
    uint256 public maxStakingDuration = 365 days;

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
        require(duration >= minStakingDuration && duration <= maxStakingDuration, "Invalid staking duration");
        _;
    }

    // Calculate rewards for a given stake
    function calculateReward(Stake memory _stake) public view returns (uint256) {
        if (_stake.amount == 0) return 0;

        uint256 endTime = block.timestamp > _stake.endTime ? _stake.endTime : block.timestamp;

        uint256 lastClaim = _stake.lastClaimTime > _stake.startTime ? _stake.lastClaimTime : _stake.startTime;

        if (lastClaim >= endTime) return 0;

        uint256 stakingDuration = endTime - lastClaim;
        uint256 yearlyReward = _stake.amount * APR / 10000; // APR is in basis points
        uint256 reward = yearlyReward * stakingDuration / YEAR;

        return reward;
    }

    // View function to check pending rewards
    function getPendingReward(address _staker) external view returns (uint256) {
        return calculateReward(stakes[_staker]);
    }

    // Stake AVAX
    function stake(uint256 _duration) external payable validateStakingDuration(_duration) {
        require(msg.value > 0, "Cannot stake 0 AVAX");
        require(stakes[msg.sender].amount == 0, "Already staking");

        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            lastClaimTime: block.timestamp
        });

        totalStaked = totalStaked + msg.value;

        emit Staked(msg.sender, msg.value, _duration);
    }

    // Withdraw staked AVAX and rewards
    function withdraw() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");
        require(block.timestamp >= userStake.endTime, "Stake still locked");

        uint256 reward = calculateReward(userStake);
        uint256 amount = userStake.amount;

        // Reset stake
        totalStaked = totalStaked - amount;
        delete stakes[msg.sender];

        // Transfer staked amount and reward
        (bool success,) = payable(msg.sender).call{value: amount + reward}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount, reward);
    }

    // Claim only rewards
    function claimRewards() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");

        uint256 reward = calculateReward(userStake);
        require(reward > 0, "No rewards to claim");

        userStake.lastClaimTime = block.timestamp;

        (bool success,) = payable(msg.sender).call{value: reward}("");
        require(success, "Transfer failed");

        emit RewardClaimed(msg.sender, reward);
    }

    // Emergency withdraw function
    function emergencyWithdraw() external {
        Stake storage userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No active stake");

        uint256 amount = userStake.amount;
        totalStaked = totalStaked - amount;
        delete stakes[msg.sender];

        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");

        emit Withdrawn(msg.sender, amount, 0);
    }

    // Admin functions
    function updateStakingDurations(uint256 _minDuration, uint256 _maxDuration) external onlyOwner {
        require(_minDuration <= _maxDuration, "Invalid durations");
        minStakingDuration = _minDuration;
        maxStakingDuration = _maxDuration;
    }

    // Function to receive AVAX
    receive() external payable {}

    // Function to check contract AVAX balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // The following functions are overrides required by Solidity.
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}
}
