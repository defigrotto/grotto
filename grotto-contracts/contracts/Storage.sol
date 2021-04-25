/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;

pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/StorageInterface.sol";
import "./lib/Data.sol";

contract Storage is StorageInterface {
    using SafeMath for uint256;

    mapping(string => uint256) votes;
    mapping(address => mapping(string => bool)) voted;
    mapping(string => address payable[]) voters;
    mapping(string => uint256) yesVotes;
    mapping(string => uint256) noVotes;
    mapping(string => bool) inProgress;

    mapping(string => address payable) proposedGovernor;
    mapping(string => uint256) proposedValue;
    mapping(address => bool) isGovernor;
    
    Data.ProposedShare proposedShares;

    address payable[] governors;

    // Stake price for the main pool. $100
    //uint256 private mainPoolPrice = 100 * ONE_ETHER;
    uint256 private mainPoolPrice = 100 * Data.ONE_ETHER;

    // Number of accounts before winner is calculated. = 100
    uint256 private mainPoolSize = 100;

    // percentage of winning that goes to house/governors/stakers. 10%
    uint256 private houseCut = 10;

    uint256 private governorsShare = 30;
    uint256 private houseShare = 10;
    uint256 private stakersShare = 60;

    // how many % of new tokens go to house. 10%
    uint256 private houseCutNewToken = 10;

    // Minimum price for user defined poolss
    uint256 private minimumPoolPrice = 10 * Data.ONE_ETHER;

    // Minimum size for user defined pools
    uint256 private minimumPoolSize = 10;

    // Maximum size for user defined pools
    uint256 private maximumPoolSize = 100;

    /*
        When user defines a pool, they pay the POOL PRICE in exchange for GROTTO tokens
        These payments should be sent to house
    */ 
    uint256 private pendingGrottoMintingPayments = 0;

    // How much GROTTO is needed to be a governor
    uint256 private minimumGrottoPerGovernor = 100000 * Data.ONE_ETHER;

    Data.Pool[] private poolDetails;

    mapping(bytes32 => Data.Pool) pool;

    // Map of pool_id to their id in the poolIds array
    mapping(bytes32 => uint256) private poolIdMap;

    // poolers in a particular pool identified by bytes32
    mapping(bytes32 => address payable[]) private poolers;

    address payable private house;

    address private grotto = 0xfFBcEa756d44390c73124eD8De0408C2CF2f0706;
    address private gov = 0xD3861b19BC49a1A647e4B90aA502de5073Baceb6;

    // Holds all the staked GROTTO tokens.
    address private stakingMaster = 0x1337133713371337133713371337133713371337;
    uint256 currentStakePoolIndex = 1;
    // Maps address to staking pool to amount staked;    
    mapping(uint256 => mapping(address => uint256)) private staked;
    // Maps address to total amount staked
    mapping(address => uint256) private userStakes;
    // Maps stake index to amount of ETH per GROTTO
    mapping(uint256 => uint256) private rewardPerGrotto;
    // All the stakers
    address payable[] private stakers;
    // Mapping staker to index in stakers
    mapping(address => uint256) private stakerIndex;
    
    mapping(address => uint256) private rewardsCollected;

    uint256[] completedPools;

    uint256 minValueForSharesProcessing = 10 * Data.ONE_ETHER;

    function getMinValueForSharesProcessing() public view override returns (uint256) {
        return minValueForSharesProcessing;
    }

    function setMinValueForSharesProcessing(uint256 value) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        minValueForSharesProcessing = value;
    }

    function addCompletedPool(uint256 stakePoolIndex) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        completedPools.push(stakePoolIndex);
    }

    function getCompletedPools() public override view returns(uint256[] memory) {
        return completedPools;
    }

    function geRewardPerGrotto(uint256 stakePoolIndex) public override view returns(uint256) {
        return rewardPerGrotto[stakePoolIndex];
    }

    function setRewardPerGrotto(uint256 stakePoolIndex, uint256 reward) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        rewardPerGrotto[stakePoolIndex] = reward;
    }

    function getCurrentStakePoolIndex() public override view returns(uint256) {
        return currentStakePoolIndex;
    }

    function setCurrentStakePoolIndex(uint256 p) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        currentStakePoolIndex = p;
    }

    function getUserStakes(address staker) public override view returns (uint256) {
        return userStakes[staker];
    }

    function setUserStakes(address staker, uint256 stake) public override { 
        require(msg.sender == grotto, "Grotto: You can't do that");
        userStakes[staker] = stake;
    }

    function addressIsGovernor(address payable checkAddress) public override view returns (bool) {
        return isGovernor[checkAddress];
    }

    function setIsGovernor(address payable checkAddress, bool isG) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        isGovernor[checkAddress] = isG;
    }

    function getRewardsCollected(address staker) public override view returns (uint256) {   
        return rewardsCollected[staker];
    }

    function setRewardsCollected(address staker, uint256 reward) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        rewardsCollected[staker] = reward;
    }

    function setProposedShare(uint256 houseShare, uint256 govsShare, uint256 stakersShare) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        proposedShares = Data.ProposedShare ({
            house: houseShare,
            govs: govsShare,
            stakers: stakersShare
        });
    }

    function getHouseCutShares() public override view returns (uint256, uint256, uint256) {
        return (houseShare, governorsShare, stakersShare);
    }

    function getProposedShare() public override view returns (uint256, uint256, uint256) {        
        return (proposedShares.house, proposedShares.govs, proposedShares.stakers);
    }

    function getGovernorsShare() public override view returns (uint256) {
        return governorsShare;
    }

    function getStakersShare() public override view returns (uint256) {
        return stakersShare;
    }
 
    function getHouseShare() public override view returns (uint256) {
        return houseShare;
    }

    function setHouseShare(uint256 share) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        houseShare = share;
    }

    function setStakersShare(uint256 share) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        stakersShare = share;
    }

    function setGovernorsShare(uint256 share) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        governorsShare = share;
    }

    function setStakingMaster(address newStakingMaster) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        stakingMaster = newStakingMaster;
    }

    function getStakingMaster() public override view returns (address) {
        return stakingMaster;
    } 

    function setStake(address staker, uint256 stakePool, uint256 value) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        staked[stakePool][staker] = value;
    }

    function getStake(address staker, uint256 stakePool) public override view returns (uint256) {
        uint256 stakedInPool = staked[stakePool][staker];

        if(staker == stakingMaster) {
            return stakedInPool;
        }

        uint256 allUserStakes = getUserStakes(staker);
        if (allUserStakes >= stakedInPool) {
            // if allUserStakes < stakedInPool...it means user has withdrawn their stake
            return stakedInPool;
        }

        return 0;
    }

    function getStakers() public override view returns (address payable[] memory) {
        return stakers;
    }

    function withdrawStake(address payable staker) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        userStakes[staker] = 0;
        uint256 index = stakerIndex[staker];

        if(index == 0) {
            return;
        }
        
        uint256 userStakeInCurrentPool = staked[currentStakePoolIndex][staker];

        staked[currentStakePoolIndex][staker] = 0;
        staked[currentStakePoolIndex][stakingMaster] = staked[currentStakePoolIndex][stakingMaster].sub(userStakeInCurrentPool);        

        // remove from stakers.
        if(uint256(index) == (stakers.length.sub(1))) {
            stakers.pop(); 
            stakerIndex[staker] = 0;           
        } else {
            // first update the index. The index of he last element is now the index of the element to delete
            stakerIndex[stakers[stakers.length.sub(1)]] = index;            
            stakers[uint256(index)] = stakers[stakers.length.sub(1)];
            stakers.pop();
            stakerIndex[staker] = 0;
        }        
    }

    function addStake(address payable staker, uint256 stake) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        if(stakers.length == 0) {
            staked[currentStakePoolIndex][address(0)] = 1;
            stakers.push(address(0));
            stakerIndex[address(0)] = 0;
        }

        uint256 currentStake = getStake(staker, currentStakePoolIndex);
        uint256 newStake = currentStake.add(stake);        

        uint256 index = stakerIndex[staker];
        if(index <= 0) {
            // first time staker...
            index = stakers.length;
            staked[currentStakePoolIndex][staker] = newStake;
            stakers.push(staker);
            stakerIndex[staker] = index;
        } else {
            // already a staker
            staked[currentStakePoolIndex][staker] = newStake;
        }

        userStakes[staker] = userStakes[staker].add(stake);

        // increment how much is staked in this pool
        staked[currentStakePoolIndex][stakingMaster] = staked[currentStakePoolIndex][stakingMaster].add(stake);
    }

    function setGrotto(address newGrotto) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        grotto = newGrotto;
    }

    function setGov(address payable newGov) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        gov = newGov;
    }    

    function getPool(bytes32 poolId) public view override returns (Data.Pool memory) {
        return pool[poolId];        
    }

    function addPool(Data.Pool memory p) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
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
        return pendingGrottoMintingPayments;
    }    

    function setPendingGrottoMintingPayments(uint256 mpi) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        pendingGrottoMintingPayments = mpi;
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
        return mainPoolPrice;
    }

    function setMainPoolPrice(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        mainPoolPrice = mmp;
    }

    function getMainPoolSize() public view override returns (uint256) {
        return mainPoolSize;
    }

    function setMainPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        mainPoolSize = mmp;
    }    

    function getHouseCut() public view override returns (uint256) {
        return houseCut;
    }
 
    function setHouseCut(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        houseCut = mmp;
    }    

    function getHouseCutNewTokens() public view override returns (uint256) {
        return houseCutNewToken;
    }

    function setHouseCutNewTokens(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        houseCutNewToken = mmp;
    }        

    function getMinimumPoolPrice() public view override returns (uint256) {
        return minimumPoolPrice;
    }

    function setMinimumPoolPrice(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        minimumPoolPrice = mmp;
    }        

    function getMinimumPoolSize() public view override returns (uint256) {
        return minimumPoolSize;
    }

    function setMinimumPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        minimumPoolSize = mmp;
    }            

    function getMaximumPoolSize() public view override returns (uint256) {
        return maximumPoolSize;
    }

    function getGovernors() public override view returns (address payable[] memory) {
        return governors;
    }


    function getMinGrottoGovernor() public view override returns (uint256) {
        return minimumGrottoPerGovernor;
    }

    function setMinGrottoGovernor(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        minimumGrottoPerGovernor = mmp;
    }            

    function setMaximumPoolSize(uint256 mmp) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        maximumPoolSize = mmp;
    }            

    function addGovernor(address payable governor) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        governors.push(governor);
        isGovernor[governor] = true;
    }

    function isInProgress(string memory voteId) public override view returns (bool) {
        return inProgress[voteId];
    }

    function setProgress(string memory voteId, bool value) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        inProgress[voteId] = value;
    }

    function getVoters(string memory voteId) public override view returns (address payable[] memory) {        
        return voters[voteId];
    }

    function setVoters(string memory voteId, address payable[] memory v) public override {
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

    function addVoter(string memory voteId, address payable governor) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        voters[voteId].push(governor);
    }    

    function addProposedGovernor(string memory voteId, address payable newGovernor) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        proposedGovernor[voteId] = newGovernor;
    }

    function addProposedValue(string memory voteId, uint256 newValue) public override {
        require(msg.sender == gov, "Gov: You can't do that");
        proposedValue[voteId] = newValue;
    }    
 
    function getProposedGovernor(string memory voteId) public override view returns (address payable) {
        return proposedGovernor[voteId];
    }

    function setGovernors(address payable[] memory govs) public override { 
        require(msg.sender == gov, "Gov: You can't do that");
        governors = govs;
    }
}