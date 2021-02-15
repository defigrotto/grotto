/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/StorageInterface.sol";
import "./lib/Data.sol";

contract Storage is StorageInterface {
    using SafeMath for uint256;

    mapping(string => uint256) votes;
    mapping(address => mapping(string => bool)) voted;
    mapping(string => address[]) voters;
    mapping(string => uint256) yesVotes;
    mapping(string => uint256) noVotes;
    mapping(string => bool) inProgress;

    mapping(string => address) proposedGovernor;
    mapping(string => uint256) proposedValue;

    address[] governors;

    // Stake price for the main pool. $100
    //uint256 private MAIN_POOL_PRICE = 100 * ONE_ETHER;
    uint256 private MAIN_POOL_PRICE = 100 * Data.ONE_ETHER;

    // Number of accounts before winner is calculated.
    uint256 private MAIN_POOL_SIZE = 100;

    // percentage of winning that goes to house. 10%
    uint256 private HOUSE_CUT = 10;

    // how many % of new tokens go to house. 10%
    uint256 private HOUSE_CUT_NEW_TOKEN = 10;

    // Minimum price for user defined pools
    uint256 private MINIMUM_POOL_PRICE = 10 * Data.ONE_ETHER;

    // Minimum size for user defined pools
    uint256 private MINIMUM_POOL_SIZE = 10;

    // Maximum size for user defined pools
    uint256 private MAXIMUM_POOL_SIZE = 100;

    /*
        When user defines a pool, they pay the POOL PRICE in exchange for GROTTO tokens
        These payments should be sent to house
    */ 
    uint256 private PENDING_GROTTO_MINTING_PAYMENTS = 0;

    // How much GROTTO is needed to be a governor
    uint256 private MINIMUM_GROTTO_GOVERNOR = 10000 * Data.ONE_ETHER;

    Data.Pool[] private poolDetails;

    mapping(bytes32 => Data.Pool) pool;

    // Map of pool_id to their id in the poolIds array
    mapping(bytes32 => uint256) private poolIdMap;

    // poolers in a particular pool identified by bytes32
    mapping(bytes32 => address payable[]) private poolers;

    address payable private house;

    address grotto = 0x9f2Ee575df41B27c966F05c3e9579E495d234368;
    address gov = 0xEb3b048D517b5130804EF68B74A959c47abaCfb5;

    function setGrotto(address newGrotto) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        grotto = newGrotto;
    }

    function setGov(address newGov) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        gov = newGov;
    }    

    function getPool(bytes32 poolId) public view override returns (Data.Pool memory) {
        return pool[poolId];        
    }

    function addPool(Data.Pool memory p) public override {
        pool[p.poolId] = p;
        poolIdMap[p.poolId] = poolDetails.length;
        poolDetails.push(p);        
    }

    function getPoolers(bytes32 poolId) public view override returns (address payable[] memory) {
        return poolers[poolId];
    }

    function getHouse() public view override returns (address payable newHouse) {
        return house;
    }

    function getPoolIdIndex(bytes32 poolId) public view override returns (uint256) {
        return poolIdMap[poolId];
    }

    function getPoolTotalStaked(bytes32 poolId) public view override returns (uint256) {
        return pool[poolId].totalStaked;
    }

    function getPoolDetail(uint256 index) public view override returns (Data.Pool memory) {
        return poolDetails[index];
    }

    function getPendingGrottoMintingPayments() public view override returns (uint256) {
        return PENDING_GROTTO_MINTING_PAYMENTS;
    }    

    function setPendingGrottoMintingPayments(uint256 mpi) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        PENDING_GROTTO_MINTING_PAYMENTS = mpi;
    }    

    function setVoted(string memory voteId, address governor, bool vt) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        voted[governor][voteId] = vt;
    }

    function setPoolCurrentSize(bytes32 poolId, uint256 size) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        pool[poolId].currentPoolSize = size;
        uint256 index = poolIdMap[poolId];
        poolDetails[index] = pool[poolId];
    }

    function setPoolTotalStaked(bytes32 poolId, uint256 ts) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        pool[poolId].totalStaked = ts;
        uint256 index = poolIdMap[poolId];
        poolDetails[index] = pool[poolId];        
    }

    function setPoolWinner(bytes32 poolId, address winner) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        pool[poolId].winner = winner; 
        uint256 index = poolIdMap[poolId];
        poolDetails[index] = pool[poolId];        
    }

    function setPoolConcluded(bytes32 poolId, bool concluded) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        pool[poolId].isPoolConcluded = concluded;
        uint256 index = poolIdMap[poolId];
        poolDetails[index] = pool[poolId];        
    }

    function setHouse(address payable newHouse) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        house = newHouse;
    }

    function addPooler(bytes32 poolId, address payable pooler) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        poolers[poolId].push(pooler);    
    }

    function setPoolIdMap(bytes32 poolId, uint256 id) override public {
        require(msg.sender == grotto, "Grotto: You can't do that");
        poolIdMap[poolId] = id;
    } 

    function getAllPools() override public view returns (Data.Pool[] memory) {
        return poolDetails;
    }

    function getMainPoolPrice() public view override returns (uint256) {
        return MAIN_POOL_PRICE;
    }

    function setMainPoolPrice(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MAIN_POOL_PRICE = mmp;
    }

    function getMainPoolSize() public view override returns (uint256) {
        return MAIN_POOL_SIZE;
    }

    function setMainPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MAIN_POOL_SIZE = mmp;
    }    

    function getHouseCut() public view override returns (uint256) {
        return HOUSE_CUT;
    }
 
    function setHouseCut(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        HOUSE_CUT = mmp;
    }    

    function getHouseCutNewTokens() public view override returns (uint256) {
        return HOUSE_CUT_NEW_TOKEN;
    }

    function setHouseCutNewTokens(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        HOUSE_CUT_NEW_TOKEN = mmp;
    }        

    function getMinimumPoolPrice() public view override returns (uint256) {
        return MINIMUM_POOL_PRICE;
    }

    function setMinimumPoolPrice(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MINIMUM_POOL_PRICE = mmp;
    }        

    function getMinimumPoolSize() public view override returns (uint256) {
        return MINIMUM_POOL_SIZE;
    }

    function setMinimumPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MINIMUM_POOL_SIZE = mmp;
    }            

    function getMaximumPoolSize() public view override returns (uint256) {
        return MAXIMUM_POOL_SIZE;
    }

    function getGovernors() public override view returns (address[] memory) {
        return governors;
    }


    function getMinGrottoGovernor() public view override returns (uint256) {
        return MINIMUM_GROTTO_GOVERNOR;
    }

    function setMinGrottoGovernor(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MINIMUM_GROTTO_GOVERNOR = mmp;
    }            

    function setMaximumPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        MAXIMUM_POOL_SIZE = mmp;
    }            

    function addGovernor(address governor) public override {
        governors.push(governor);
    }

    function isInProgress(string memory voteId) public override view returns (bool) {
        return inProgress[voteId];
    }

    function setProgress(string memory voteId, bool value) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        inProgress[voteId] = value;
    }

    function getVoters(string memory voteId) public override view returns (address[] memory) {        
        return voters[voteId];
    }

    function setVoters(string memory voteId, address[] memory v) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        voters[voteId] = v;
    }

    function setYesVotes(string memory voteId, uint256 yv) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        yesVotes[voteId] = yv;
    }

    function setNoVotes(string memory voteId, uint256 nv) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        noVotes[voteId] = nv;
    }

    function setVotes(string memory voteId, uint256 v) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        votes[voteId] = v;
    }  

    function getYesVotes(string memory voteId) public override view returns (uint256) {
        return yesVotes[voteId];
    }

    function getNoVotes(string memory voteId) public override view returns (uint256) {
        return noVotes[voteId];        
    }    

    function getVotes(string memory voteId) public override view returns (uint256) {
        return votes[voteId];        
    }

    function getProposedValue(string memory voteId) public override view returns (uint256) {
        return proposedValue[voteId];        
    }

    function getVoted(string memory voteId, address governor) public override view returns (bool) {
        return voted[governor][voteId];
    }

    function addVoter(string memory voteId, address governor) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        voters[voteId].push(governor);
    }    

    function addProposedGovernor(string memory voteId, address newGovernor) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        proposedGovernor[voteId] = newGovernor;
    }

    function addProposedValue(string memory voteId, uint256 newValue) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        proposedValue[voteId] = newValue;
    }    
 
    function getProposedGovernor(string memory voteId) public override view returns (address) {
        return proposedGovernor[voteId];
    }

    function setGovernors(address[] memory govs) public override { 
        require(msg.sender == gov, "Gov: You can't do that");
        governors = govs;
    }
}