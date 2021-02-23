// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;

import "../lib/Data.sol";

interface StorageInterface {
    function setPoolIdMap(bytes32, uint256) external;

    function addPooler(bytes32, address payable) external;

    function addPool(Data.Pool memory) external;

    function setHouse(address payable) external;

    function setPoolCurrentSize(bytes32, uint256) external;

    function setPoolTotalStaked(bytes32, uint256) external;

    function setPoolWinner(bytes32, address) external;

    function setPoolConcluded(bytes32, bool) external;

    function setPendingGrottoMintingPayments(uint256) external;

    function setMinGrottoGovernor(uint256) external;

    function getPool(bytes32 poolId) external view returns (Data.Pool memory);

    function getPendingGrottoMintingPayments() external view returns (uint256);

    function getPoolDetail(uint256) external view returns (Data.Pool memory);

    function getPoolIdIndex(bytes32) external view returns (uint256);

    function getPoolTotalStaked(bytes32) external view returns (uint256);

    function getPoolers(bytes32)
        external
        view
        returns (address payable[] memory);

    function getHouse() external view returns (address payable newHouse);

    function getAllPools() external view returns (Data.Pool[] memory);

    function getMinGrottoGovernor() external view returns (uint256);

    function getGovernors() external view returns (address payable[] memory);

    function getMainPoolPrice() external view returns (uint256);

    function getMainPoolSize() external view returns (uint256);

    function getHouseCut() external view returns (uint256);

    function getHouseCutNewTokens() external view returns (uint256);

    function getMinimumPoolPrice() external view returns (uint256);

    function getMinimumPoolSize() external view returns (uint256);

    function getMaximumPoolSize() external view returns (uint256);

    function addGovernor(address payable) external;

    function addProposedGovernor(string memory, address payable) external;

    function addProposedValue(string memory, uint256) external;

    function addVoter(string memory, address payable) external;

    function setProgress(string memory, bool) external;

    function setVoted(
        string memory,
        address,
        bool
    ) external;

    function setVoters(string memory, address payable[] memory) external;

    function setYesVotes(string memory, uint256) external;

    function setNoVotes(string memory, uint256) external;

    function setVotes(string memory, uint256) external;

    function setMainPoolPrice(uint256) external;

    function setMainPoolSize(uint256) external;

    function setHouseCut(uint256) external;

    function setHouseCutNewTokens(uint256) external;

    function setMinimumPoolPrice(uint256) external;

    function setMinimumPoolSize(uint256) external;

    function setMaximumPoolSize(uint256) external;

    function isInProgress(string memory) external view returns (bool);

    function getVoters(string memory) external view returns (address payable[] memory);

    function getYesVotes(string memory) external view returns (uint256);

    function getNoVotes(string memory) external view returns (uint256);

    function getVotes(string memory) external view returns (uint256);

    function getProposedValue(string memory) external view returns (uint256);

    function getProposedGovernor(string memory) external view returns (address payable);

    function getVoted(string memory, address) external view returns (bool);

    function setGrotto(address) external;

    function setGov(address payable) external;

    function setGovernors(address payable[] memory) external;

    function setStakingMaster(address) external;

    function getStakingMaster() external view returns (address);

    function addStake(address payable, uint256) external;

    function getStake(address, uint256) external view returns (uint256);

    function setStake(address, uint256, uint256)  external;

    function getStakers() external view returns (address payable[] memory);

    function withdrawStake(address payable) external;

    function getGovernorsShare() external view returns (uint256);

    function getStakersShare() external view returns (uint256);

    function getHouseShare() external view returns (uint256);

    function setHouseShare(uint256) external;

    function setStakersShare(uint256) external;

    function setGovernorsShare(uint256) external;

    function setProposedShare(uint256, uint256, uint256) external;

    function getProposedShare() external view returns (uint256, uint256, uint256);

    function getHouseCutShares() external view returns (uint256, uint256, uint256);  

    function getRewardsCollected(address staker) external view returns(uint256);
    
    function setRewardsCollected(address, uint256) external;

    function addressIsGovernor(address payable) external view returns (bool);
    
    function setIsGovernor(address payable, bool) external;

    function getUserStakes(address) external view returns (uint256);

    function setUserStakes(address, uint256) external;

    function getCurrentStakePoolIndex() external view returns(uint256);

    function setCurrentStakePoolIndex(uint256) external;

    function geRewardPerGrotto(uint256) external view returns(uint256);

    function setRewardPerGrotto(uint256, uint256) external;

    function addCompletedPool(uint256) external;

    function getCompletedPools() external view returns(uint256[] memory);

    function getMinValueForSharesProcessing() external view returns (uint256);

    function setMinValueForSharesProcessing(uint256 value) external;
}