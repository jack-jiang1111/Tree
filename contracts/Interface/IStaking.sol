// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IStaking {
    function earned(address account) external view returns (uint256); 
    function getRewardForDuration() external view returns (uint256);
    function getTotalStaking() external view returns(uint256);
    function balanceOf(address account) external view returns (uint256);
    function stake(uint256 amount) external; 
    function withdraw(uint256 amount) external;
    function getReward() external;
    function exit() external;
    function depositFunds(uint256 _amount) external;

}
