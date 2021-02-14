/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/GovernanceInterface.sol";
import "./interface/GrottoTokenInterface.sol";
import "./interface/StorageInterface.sol";
import "./lib/Data.sol";
import "./Governance.sol";

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

    address private tokenAddress = 0xE6dC5F56F658a1868f10c374c4e1Fb39D2CD0F99;
    address private storeAddress = 0xecb02254257B6F4b637463cAA1c4BB2D54AFE1aF;    

    GrottoTokenInterface grottoToken;

    constructor() {
        store = StorageInterface(storeAddress);

        grottoToken = GrottoTokenInterface(tokenAddress);

        store.setHouse(msg.sender);

        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);        
    }

    function updateGrotto(address payable newAddress) public {
        require(msg.sender == store.getHouse(), "Only a house can do that");
        store.setGrotto(newAddress);
        grottoToken.setGrotto(newAddress);
        uint256 balance = address(this).balance;
        newAddress.transfer(balance);
    }

    function enterPool(bytes32 poolId) public payable {
        uint256 value = msg.value;
        address payable pooler = msg.sender;
        Data.Pool memory pool = store.getPool(poolId);

        require(store.getPoolers(poolId).length < pool.poolSize, "This Pool is full");        

        if(pool.currentPoolSize > 0) {
            require(pooler != pool.poolCreator, "You can't participate in this pool.");
        }

        // calculate dollar value
        uint256 latestUsdPrice = getLatestPrice();
        uint256 usdtValue = latestUsdPrice.mul(value);

        require(usdtValue >= pool.poolPrice, "Value Sent is less than pool price.");

        uint256 ts = store.getPoolTotalStaked(poolId);
        store.setPoolTotalStaked(poolId, ts.add(value));
        store.addPooler(poolId, pooler);

        address payable[] memory poolers = store.getPoolers(poolId);
        store.setPoolCurrentSize(poolId, poolers.length);

        // check if we have any pending grotto payments...
        if(store.getPendingGrottoMintingPayments() > 0) {
            uint256 payment = store.getPendingGrottoMintingPayments();
            if(payment > 1 ether) {
                store.getHouse().transfer(1 ether);
                store.setPendingGrottoMintingPayments(payment.sub(1 ether));
            }
        }

        pool = store.getPool(poolId);
        if (poolers.length == pool.poolSize) {
            // pay winner
            _payWinner(poolId);
        }
        
        emit POOL_JOINED(poolId, pooler);
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
        bytes32 randBase = keccak256(abi.encodePacked(poolers[0]));

        for (uint8 i = 1; i < pool.poolSize; i++) {            
            randBase = keccak256(abi.encodePacked(randBase, poolers[i]));
        }

        uint256 toHouse = totalStaked.mul(store.getHouseCut()).div(100);

        address payable winner = poolers[uint256(keccak256(abi.encodePacked(totalStaked, randBase))) % (pool.poolSize)];

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
}
