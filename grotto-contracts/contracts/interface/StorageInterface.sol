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

    function getPool(bytes32 poolId) external view returns (Data.Pool memory);
    function getPendingGrottoMintingPayments() external view returns (uint256);    
    function getPoolDetail(uint256) external view returns (Data.Pool memory);
    function getPoolIdIndex(bytes32) external view returns (uint256);
    function getPoolTotalStaked(bytes32) external view returns (uint256);
    function getPoolers(bytes32) external view returns (address payable[] memory);
        
    function getHouse() external view returns (address payable newHouse);    
    function getAllPools() external view returns (Data.Pool[] memory);

    function getGovernors() external view returns (address[] memory);
    function getMainPoolPrice() external view returns (uint256);
    function getMainPoolSize() external view returns (uint256);
    function getHouseCut() external view returns (uint256);
    function getHouseCutNewTokens() external view returns (uint256);
    function getMinimumPoolPrice() external view returns (uint256);
    function getMinimumPoolSize() external view returns (uint256);
    function getMaximumPoolSize() external view returns (uint256); 

    function addGovernor(address) external;
    function addProposedGovernor(string memory, address) external;
    function addProposedValue(string memory, uint256) external;   
    function addVoter(string memory, address) external;

    function setProgress(string memory, bool) external;
    function setVoted(string memory, address, bool) external;
    function setVoters(string memory, address[] memory) external;
    function setYesVotes(string memory, uint256) external;        
    function setNoVotes(string memory, uint256) external;
    function setVotes(string memory, uint256) external;
    function setMainPoolPrice(uint256 mmp) external;
    function setMainPoolSize(uint256 mmp) external;
    function setHouseCut(uint256 mmp) external;
    function setHouseCutNewTokens(uint256 mmp) external;
    function setMinimumPoolPrice(uint256 mmp) external;
    function setMinimumPoolSize(uint256 mmp) external;
    function setMaximumPoolSize(uint256 mmp) external;

    function isInProgress(string memory) external view returns (bool);        
    function getVoters(string memory) external view returns (address[] memory);
    function getYesVotes(string memory) external view returns (uint256);
    function getNoVotes(string memory) external view returns (uint256);
    function getVotes(string memory) external view returns (uint256);
    function getProposedValue(string memory) external view returns (uint256);
    function getProposedGovernor(string memory) external view returns (address);    
    function getVoted(string memory, address) external view returns (bool);

    function setGrotto(address) external;
    function setGov(address) external;
    function setGovernors(address[] memory govs) external;
}