// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3 <0.8.0;

interface GovernanceInterface {
    event NEW_GOVERNOR_ADDED(address);
    event GOVERNOR_REMOVED(address);
    event MAIN_POOL_PRICE_CHANGED(uint256);
    event MAIN_POOL_SIZE_CHANGED(uint256);
    event HOUSE_CUT_CHANGED(uint256);
    event HOUSE_CUT_NEW_TOKENS_CHANGED(uint256);
    event MINIMUM_POOL_PRICE_CHANGED(uint256);
    event MINIMUM_POOL_SIZE_CHANGED(uint256);
    event MAXIMUM_POOL_SIZE_CHANGED(uint256);
    event NO_CONSENSUS(string);
    event VOTE_CASTED(address, string);
    event NEW_PROPOSAL(string);
    function getGovernors() external view returns (address[] memory);
    function getTransferGas() external view returns (uint256);
    function getMainPoolPrice() external view returns (uint256);
    function getMainPoolSize() external view returns (uint256);
    function getHouseCut() external view returns (uint256);
    function getHouseCutNewTokens() external view returns (uint256);
    function getMinimumPoolPrice() external view returns (uint256);
    function getMinimumPoolSize() external view returns (uint256);
    function getMaximumPoolSize() external view returns (uint256);
}