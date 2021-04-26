/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/GovernanceInterface.sol";
import "./interface/GrottoTokenInterface.sol";
import "./interface/StorageInterface.sol";
import "./lib/Data.sol";

contract Grotto {
    event POOL_CREATED(bytes32, address);
    event POOL_JOINED(bytes32, address);
    event WINNER_FOUND(bytes32, address);

    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    // addresses for chainlink price fetcher
    address public constant MAINNET_ETH_USD_PF = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address public constant KOVAN_ETH_USD_PF = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address public constant BSC_ETH_USD_PF = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

    StorageInterface store;

    address private tokenAddress = 0x90a81fE6E78c12e090C8FFa48a24e8CFb61B6bD9;
    address private storeAddress = 0xd7Af206e780D21aA9B1AD46DE96b5Dbe0c4a0C99;

    GrottoTokenInterface grottoToken;

    constructor() {
        store = StorageInterface(storeAddress);        

        grottoToken = GrottoTokenInterface(tokenAddress);

        store.setHouse(msg.sender);

        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);    

        _mintTokensForGovernors();   

        // TODO: Comment Everything below this line in prod
        grottoToken.mintToken(0x94Ce615ca10EFb74cED680298CD7bdB0479940bc, store.getMinGrottoGovernor()); 
        grottoToken.mintToken(0xf0eB683bb243eCE4Fe94494E4014628AfCb6Efe5, store.getMinGrottoGovernor()); 
        grottoToken.mintToken(0xCF68FA93220dE12f278873Be1F458b3D289B5794, store.getMinGrottoGovernor()); 
        grottoToken.mintToken(0xfd7c2019A9b04C73CA07eE42c8cEc8850671540D, store.getMinGrottoGovernor());         
    }

    function updateGrotto(address payable newAddress) public {
        require(msg.sender == store.getHouse(), "Only a house can do that");
        store.setGrotto(newAddress);
        grottoToken.setGrotto(newAddress);
        uint256 balance = address(this).balance;
        newAddress.transfer(balance);
    }


    function getRewardPerGrotto(uint256 stakePoolIndex) public view returns (uint256) {
        return store.geRewardPerGrotto(stakePoolIndex);
    }

    function stake(uint256 amount) public {
        address payable staker = msg.sender;
        require(grottoToken.balanceOf(staker) >= amount, 'You do not have enough GROTTO');
        require(!store.addressIsGovernor(staker), 'Governors can not stake');
        grottoToken.stake(staker, store.getStakingMaster(), amount);
        store.addStake(staker, amount);        
    }

    function withdrawStakeRewards(uint256 stakePoolIndex) public {
        address payable staker = msg.sender;
        uint256 stakeInPool = store.getStake(staker, stakePoolIndex);
        uint256 rewardPerGrotto = store.geRewardPerGrotto(stakePoolIndex);
        // we multiplied by 1 ether when calculating RPG, now we divide by 1 ether
        uint256 totalRewards = (stakeInPool.mul(rewardPerGrotto)) / 1 ether;
        withdrawStake();
        store.setStake(staker, stakePoolIndex, 0);
        staker.transfer(totalRewards);
    }

    function withdrawStake() public {
        address payable staker = msg.sender;
        require(store.getUserStakes(staker) > 0, 'You do not have a stake');
        require(!store.addressIsGovernor(staker), 'Governors can not stake');

        uint256 _stake = store.getUserStakes(staker);
        store.withdrawStake(staker);
        grottoToken.unstake(store.getStakingMaster(), staker, _stake);
    }

    function getStakeInPool(address staker, uint256 stakePoolIndex) public view returns (uint256) {
        return store.getStake(staker, stakePoolIndex);
    }

    function getStakers() public view returns (address payable[] memory) {
        return store.getStakers();
    }

    function getStake(address staker) public view returns (uint256) {
        return store.getUserStakes(staker);
    }

    function getGrottoTokenBalance(address account) public view returns (uint256) {
        return grottoToken.balanceOf(account);
    }

    function getStakingMasterBalance() public view returns (uint256) {
        return grottoToken.balanceOf(store.getStakingMaster());
    }

    function getCompletedStakePools() public view returns (uint256[] memory) {
        return store.getCompletedPools();
    }

    function processShares() public {
        if(store.getPendingGrottoMintingPayments() >= 10 ether) {
            uint256 payment = store.getPendingGrottoMintingPayments();
            uint256 toHouse = payment.mul(store.getHouseShare()).div(100);
            uint256 toGovs = payment.mul(store.getGovernorsShare()).div(100);
            uint256 toStakers = payment.mul(store.getStakersShare()).div(100);

            uint256 totalStakedForCurrentPool = store.getStake(store.getStakingMaster(), store.getCurrentStakePoolIndex());
            // multiply by 1 ether so that result will not be 0 for result like (0.12/60000)
            uint256 ethPerGrotto = toStakers.mul(1 ether).div(totalStakedForCurrentPool);
            store.setRewardPerGrotto(store.getCurrentStakePoolIndex(), ethPerGrotto);                     
            store.setPendingGrottoMintingPayments(0);  
            store.addCompletedPool(store.getCurrentStakePoolIndex());
            store.setCurrentStakePoolIndex(store.getCurrentStakePoolIndex().add(1));

            // store.setStake(address(0), store.getCurrentStakePool(), 1);
             store.getHouse().transfer(toHouse);
            _payGovernors(toGovs);
        }        
    }

    function enterPool(bytes32 poolId) public payable {
        uint256 value = msg.value;
        address payable pooler = msg.sender;
        Data.Pool memory pool = store.getPool(poolId);

        require(store.getPoolers(poolId).length < pool.poolSize, "This Pool is full");        

        require(pooler != pool.poolCreator, "You can't participate in this pool.");        

        // calculate dollar value
        uint256 latestUsdPrice = getLatestPrice();
        uint256 usdtValue = latestUsdPrice.mul(value);

        require(usdtValue >= pool.poolPrice, "Value Sent is less than pool price.");

        uint256 ts = store.getPoolTotalStaked(poolId);
        store.setPoolTotalStaked(poolId, ts.add(value));
        store.addPooler(poolId, pooler);

        address payable[] memory poolers = store.getPoolers(poolId);
        store.setPoolCurrentSize(poolId, poolers.length);

        pool = store.getPool(poolId);
        if (poolers.length == pool.poolSize) {
            // pay winner
            _payWinner(poolId);
        }
        
        emit POOL_JOINED(poolId, pooler);
    }

    function _payGovernors(uint256 share) private {
        address payable[] memory governors = store.getGovernors();
        uint256 each = share.div(governors.length);
        for(uint256 i = 0; i < governors.length; i++) {
            governors[i].transfer(each);
        }
    }

    function startNewPool(uint256 poolSize, bytes32 poolId) public payable {
        uint256 value = msg.value;
        uint256 usdtValue = getLatestPrice().mul(value);        
        bool isMainPool = false;

        uint256 poolPrice = store.getMinimumPoolPrice();

        address payable pooler = msg.sender;
        if(pooler == store.getHouse()) {
            usdtValue = store.getMainPoolPrice();
            poolPrice = store.getMainPoolPrice();
            poolSize = store.getMainPoolSize();
            isMainPool = true;
        } else {
            require(poolSize >= store.getMinimumPoolSize(), "Pool size too low");
            require(poolSize <= store.getMaximumPoolSize(), "Pool size too high");
        }

        require(usdtValue >= poolPrice, "Value Sent is less than pool price.");

        address winner = address(0);
        uint256 currentPoolSize = 0;
        bool isInMainPool = isMainPool;
        bool isPoolConcluded = false;

        Data.Pool memory p =
            Data.Pool({
                poolId: poolId,
                winner: winner,
                currentPoolSize: currentPoolSize,
                isInMainPool: isInMainPool,
                poolSize: poolSize,
                poolPrice: usdtValue,
                poolCreator: pooler,
                isPoolConcluded: isPoolConcluded,
                poolPriceInEther: value,
                totalStaked: 0        
            });

        store.addPool(p);

        emit POOL_CREATED(poolId, pooler);
    }

    function getAllPools() public view returns (Data.Pool[] memory) {
        return store.getAllPools();
    }

    function getLatestPrice() public pure returns (uint256) {
        // TODO: Uncomment in production
        // (
        //     uint80 roundID,
        //     int price,
        //     uint startedAt,
        //     uint timeStamp,
        //     uint80 answeredInRound
        // ) = priceFeed.latestRoundData();
        // return uint256(price).div(10**8);
        return 500;
    }        
    

    function _payWinner(bytes32 poolId) internal {
        Data.Pool memory pool = store.getPool(poolId);
        address payable[] memory poolers = store.getPoolers(poolId);
        uint256 totalStaked = store.getPoolTotalStaked(poolId);
        
        uint mid = poolers.length / 2;
        uint end = poolers.length - 1;
        bytes32 randBase = keccak256(abi.encodePacked(poolers[0]));            
        randBase = keccak256(abi.encodePacked(randBase, poolers[mid]));
        randBase = keccak256(abi.encodePacked(randBase, poolers[end]));

        uint256 winnerIndex = uint256(keccak256(abi.encodePacked(totalStaked, randBase))) % (pool.poolSize);
        address payable winner = poolers[winnerIndex];

        uint256 toHouse = totalStaked.mul(store.getHouseCut()).div(100);

        // pay winner first
        winner.transfer(totalStaked.sub(toHouse));
        // then send house's cut to contract creator
        store.getHouse().transfer(toHouse);
        // set winner for pool_id
        store.setPoolWinner(poolId, winner);
        store.setPoolConcluded(poolId, true);
        
        store.setPoolWinner(poolId, winner);
        store.setPoolConcluded(poolId, true);

        pool = store.getPool(poolId);
        uint256 creatorReward = pool.poolPrice.mul(pool.poolSize);
        uint256 houseCutNewTokens = creatorReward.mul(store.getHouseCutNewTokens()).div(100);
        grottoToken.mintToken(pool.poolCreator, creatorReward.sub(houseCutNewTokens));
        grottoToken.mintToken(store.getHouse(), houseCutNewTokens);

        store.setPendingGrottoMintingPayments(store.getPendingGrottoMintingPayments().add(pool.poolPriceInEther));

        emit WINNER_FOUND(poolId, winner);        
    }

    function getPendingGrottoMintingPayments() public view returns (uint256) {
        return store.getPendingGrottoMintingPayments();
    }

    function _mintTokensForGovernors() private {
        address payable[] memory govs = store.getGovernors();
        for (uint256 i = 0; i < govs.length; i++) {
            if(grottoToken.balanceOf(govs[i]) == 0) {
                grottoToken.mintToken(govs[i], store.getMinGrottoGovernor());
            }
        }        
    }
}
