// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IERC20 {
    function GetTotalSupply() external view returns (uint256);
    function BalanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function GetAllowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
}