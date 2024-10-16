// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./Interface/IERC20.sol";
import "./Utils/ReentrancyGuard.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

struct RewardRateSnapshot {
    uint256 timestamp;   // The timestamp when the reward rate was updated
    uint256 rewardRate;  // The reward rate for this snapshot
}


contract StakingTree is ReentrancyGuard, AutomationCompatibleInterface{
    IERC20 public TreeToken;

    mapping(address => uint256) public stakedBalance; // how many tokens staking in the contract
    mapping(address => uint256) public rewards; // how many reward token left unclaimed
    mapping(address => uint256) public stakingStartTime; // start time for staking

    // contract variable
    uint256 public totalStakingPervious = 0; // previous total staking amount
    uint256 public totalStaking = 0; // Total staking amount
    uint256 public rewardsDuration = 7 days;
    uint256 public fullYear = 365 days;
    uint256 public availableFunds = 0; // Available Fund to distribute staking rewards
    bool public stakeOpen = true;

    // Rewards calculating constant
    uint256 public lastRewardUpdateTime = 0;
    uint256 public currentRewardRate = 0;
    RewardRateSnapshot[] public rewardRateHistory;

    
    constructor(IERC20 _stakingToken) {
        TreeToken = _stakingToken;
        lastRewardUpdateTime = block.timestamp;
    }

    /* view function*/
    function earned(address account) public view returns (uint256) {
        uint256 totalReward = 0;
        uint256 userStakeWeek = stakingStartTime[account];
        uint256 userBalance = stakedBalance[account];

        if(stakingStartTime[account] >= rewardRateHistory.length){
            revert StakingLessThanOneWeek();
        }


        // only get staking reward for a full week
        for (uint256 i = userStakeWeek; i < rewardRateHistory.length; i++) {
            RewardRateSnapshot memory snapshot = rewardRateHistory[i];
            totalReward += (userBalance * snapshot.rewardRate * rewardsDuration) / 1e18;
        }

        return totalReward;
    }

    function getRewardForDuration() external view returns (uint256) {
        return currentRewardRate*rewardsDuration;
    }

    function getTotalStaking() external view returns(uint256){
        return totalStaking;
    }

    // Function to view staked balance
    function balanceOf(address account) external view returns (uint256) {
        return stakedBalance[account];
    }


    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external nonReentrant{
        if(amount<=0){
            revert StakeZeroToken();
        }
        require(stakeOpen, "Stake not open");
        totalStaking += amount;
        stakedBalance[msg.sender] += amount;
        stakingStartTime[msg.sender] = rewardRateHistory.length;
        TreeToken.transferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant{
        if(amount<=0){
            revert StakeZeroToken();
        }
        require(stakeOpen, "Stake not open");
        rewards[msg.sender] += earned(msg.sender);
        totalStaking -= amount;
        stakedBalance[msg.sender] -= amount;
        TreeToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant{
        require(stakeOpen, "Stake not open");
        uint256 reward = rewards[msg.sender];
        if(reward<=0){
            revert NoRewardAvailable(reward);
        }
        else{
            rewards[msg.sender] = 0;
            TreeToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() public  nonReentrant{
        require(stakeOpen, "Stake not open");
        withdraw(stakedBalance[msg.sender]);
        getReward();
    } 


    /* ========== chainlink keeper ========== */

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     */
    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool timePassed = ((block.timestamp - lastRewardUpdateTime) > rewardsDuration); // seconds
        upkeepNeeded = (timePassed && stakeOpen && availableFunds>0 && totalStaking>0);
        return (upkeepNeeded, "0x0");
    }
    
    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off reward update
     */
    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert StakingRewardNotUpdate(availableFunds,totalStaking);
        }
        stakeOpen = false;

        // calculate new reward rate if staking amount changed
        if (totalStaking!=totalStakingPervious && totalStaking !=0) {
            uint256 newRewardPaid = (totalStaking-totalStakingPervious)*currentRewardRate*rewardsDuration;
            availableFunds -= newRewardPaid;
            currentRewardRate = availableFunds/fullYear/totalStaking;
        }

        // update variable
        totalStakingPervious = totalStaking;
        lastRewardUpdateTime = block.timestamp;

        RewardRateSnapshot memory newSnapshot = RewardRateSnapshot({
            timestamp: block.timestamp,  // Set the current block timestamp
            rewardRate: currentRewardRate    // Set the new reward rate
        });

        // Push the new snapshot into the rewardRateHistory array
        rewardRateHistory.push(newSnapshot);

        stakeOpen = true;
        emit StakePeriodFinish(currentRewardRate);
    }
    // external function to desposit tree token
    function depositFunds(uint256 _amount) external nonReentrant{
        // Transfer tokens to this contract
        if (_amount == 0) {
            revert DepositFundFailed(_amount);
        }

        bool transfer_status= TreeToken.transferFrom(msg.sender, address(this), _amount);
        if(!transfer_status){
            revert DepositFundFailed(_amount);
        }
        
        // Update available funds in the contract
        availableFunds += _amount;

        // Emit an event to log the deposit (optional)
        emit FundsDeposited(msg.sender, _amount);
    }



    // Event declarations
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 amount);
    event StakePeriodFinish(uint256 rewardRate);
    event FundsDeposited(address indexed from, uint256 amount);

    // Error declarations
    error StakingRewardNotUpdate(uint256 availableFunds,uint256 totalStaking);
    error StakingLessThanOneWeek();
    error DepositFundFailed(uint256 amount);
    error StakeZeroToken();
    error NoRewardAvailable(uint256 reward);

}
