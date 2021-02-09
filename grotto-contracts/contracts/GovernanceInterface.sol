// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3 <0.8.0;

interface GovernanceInterface {
    function getTransferGas() external view returns (uint256);
    function getMainPoolPrice() external view returns (uint256);
    function getMainPoolSize() external view returns (uint256);
    function getHouseCut() external view returns (uint256);
    function getHouseCutNewTokens() external view returns (uint256);
    function getMinimumPoolPrice() external view returns (uint256);
    function getMinimumPoolSize() external view returns (uint256);
    function getMaximumPoolSize() external view returns (uint256);
}