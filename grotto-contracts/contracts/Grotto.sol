/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceInterface.sol";
import "./Governance.sol";

struct Pool {
    address winner;
    uint256 currentPoolSize;
    bool isInMainPool;
    uint256 poolSize;
    uint256 poolPrice;    
    address poolCreator;
    bool isPoolConcluded;
    uint256 poolPriceInEther;
}

contract Grotto is ERC20 ('Grotto', 'GROTTO') {
    using SafeMath for uint256;

    AggregatorV3Interface internal priceFeed;
    // addresses for chainlink price fetcher    
    address constant public MAINNET_ETH_USD_PF = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant public KOVAN_ETH_USD_PF = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address constant public BSC_ETH_USD_PF = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;

    GovernanceInterface gov;

    // Amount that must be sent to the pool
    mapping (bytes32 => uint256) internal poolPrices;
    
    // Max Size of Pool
    mapping (bytes32 => uint256) internal poolSizes;
    
    uint256 internal mainPoolIndex = 1;
    
    // Pool ID, increments after every time the pool is filled
    bytes32 internal mainPoolId = keccak256(abi.encodePacked(mainPoolIndex));
    // uint256 oneEther = 1000000000000000000;
    
    // Array of pool IDs
    bytes32[] internal poolIds;
    
    mapping(bytes32 => bool) isMainPool;
    mapping(bytes32 => bool) isConcluded;

    // Map of pool_id to their id in the poolIds array
    mapping (bytes32 => uint256) internal poolIdMap;

    // Map of pool ids to their creators
    mapping (bytes32 => address payable) internal poolCreators;

    // Map of pool creator to their pools
    mapping (address => bytes32[]) internal creatorPools;
    
    // poolers in a particular pool identified by bytes32
    mapping (bytes32 => address payable[]) internal poolers;
    
    // poolers stakes in a particular pool identified by bytes32
    mapping (bytes32 => mapping (address => uint256)) internal poolersStakes;
    
    address payable house;

    mapping(bytes32 => address payable) internal winners;    
    
    address private governor = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    constructor() {
        //gov = GovernanceInterface(0x728DF34e0D66f26266d62498174e97a2B390a9De);
        gov = new Governance();
        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);
        poolIds.push(mainPoolId);
        poolPrices[mainPoolId] = gov.getMainPoolPrice();
        poolSizes[mainPoolId] = gov.getMainPoolSize();
        poolIdMap[mainPoolId] = mainPoolIndex;
        isMainPool[mainPoolId] = true;
        house = msg.sender;
        poolCreators[mainPoolId] = house;
        creatorPools[house].push(mainPoolId);
    }
    
    function updateGovernor(address newGovernor) public {
        require(msg.sender == house, 'Only a house can do that');
        governor = newGovernor;
        gov = GovernanceInterface(governor);
    }

    function enterPool(bytes32 poolId) public payable {
        uint256 value = msg.value;        
        address payable pooler = msg.sender;
        _enter_pool(poolId, value, pooler);   
    }

    function _enter_pool(bytes32 poolId, uint256 value, address payable pooler) internal {
        require(poolers[poolId].length < poolSizes[poolId], 'This Pool is full');
        // calculate dollar value  
        uint256 latestUsdPrice = getLatestPrice();
        uint256 usdtValue = latestUsdPrice.mul(value);    

        uint256 poolPriceInEther = poolPrices[poolId].div(latestUsdPrice);
        uint256 poolPriceInDollarValue = poolPriceInEther.mul(latestUsdPrice);
        if(usdtValue < poolPriceInDollarValue) {
            revert('ETH Sent is less than pool price.');
        } else {
            poolersStakes[poolId][pooler] = poolersStakes[poolId][pooler].add(value);
            poolers[poolId].push(pooler);
        }
        
        if(poolers[poolId].length == poolSizes[poolId]) {                                
            // pay winner
            _pay_winner(poolId, poolSizes[poolId]);            
            // pay pool creator
            address creator = poolCreators[poolId];
            uint256 houseCutNewTokens = gov.getNewTokensMinted().mul(gov.getHouseCutNewTokens()).div(100);
            uint256 newTokens = gov.getNewTokensMinted().sub(houseCutNewTokens);
            _mint(creator, newTokens);
            _mint(house, houseCutNewTokens);
        }                    
    }

    function startNewPool(string calldata pool_name_, uint256 pool_size_) public payable {        
        uint256 _value = msg.value;  
        address payable pooler = msg.sender; 
        bytes32 poolId = keccak256(abi.encodePacked(pool_name_, pooler));        

        require(poolIdMap[poolId] == 0, 'Pool name already exists');
        
        uint256 latestUsdPrice = getLatestPrice();
        uint256 usdtValue = latestUsdPrice.mul(_value); 

        uint256 _last_index = poolIds.length;
        poolIds.push(poolId);
        poolPrices[poolId] = usdtValue;
        poolSizes[poolId] = pool_size_ == 0 ? gov.getMainPoolSize() : pool_size_;
        poolIdMap[mainPoolId] = _last_index;
        poolCreators[poolId] = pooler;
        isMainPool[poolId] = false;
        creatorPools[pooler].push(poolId);
    }

    /**
    returns
        poolId
        poolCreator
        poolPrice
        poolSize
        isMainPool
        currentNumberOfPoolers
        winner (if any),
        isConcluded
     */
    function getPoolDetails(bytes32 poolId) public view returns (Pool memory) {        
        address winner = winners[poolId];
        uint256 currentPoolSize = poolers[poolId].length;
        bool isInMainPool = isMainPool[poolId];
        uint256 poolSize = poolSizes[poolId];
        uint256 poolPrice = poolPrices[poolId];
        address poolCreator = poolCreators[poolId];
        bool isPoolConcluded = isConcluded[poolId];
        uint256 latestUsdPrice = getLatestPrice();
        uint256 poolPriceInEther = poolPrices[mainPoolId].div(latestUsdPrice);

        Pool memory pool = Pool({
            winner: winner,
            currentPoolSize: currentPoolSize,
            isInMainPool: isInMainPool,
            poolSize: poolSize,
            poolPrice: poolPrice,            
            poolCreator: poolCreator,
            isPoolConcluded: isPoolConcluded,
            poolPriceInEther: poolPriceInEther
        });

        return pool;
    }

    function getAllPools() public view returns (bytes32[] memory) {
        return poolIds;
    }

    function getPoolsByOwner(address creator) public view returns (bytes32[] memory) {
        return creatorPools[creator];
    }

    function enterMainPool() public payable {
        uint256 _value = msg.value;        
        address payable pooler = msg.sender;
        // calculate dollar value        
        uint256 latestUsdPrice = getLatestPrice();
        uint256 usdtValue = latestUsdPrice.mul(_value);    

        uint256 poolPriceInEther = poolPrices[mainPoolId].div(latestUsdPrice);
        uint256 poolPriceInDollarValue = poolPriceInEther.mul(latestUsdPrice);
        if(usdtValue < poolPriceInDollarValue) {
            revert('ETH Sent is less than pool price.');
        } else {
            poolersStakes[mainPoolId][pooler] = poolersStakes[mainPoolId][pooler].add(_value);
            poolers[mainPoolId].push(pooler);
        }
        
        if(poolers[mainPoolId].length == poolSizes[mainPoolId]) {                    
            bytes32 _lastpoolId = mainPoolId;
            uint256 _last_pool_size = poolSizes[mainPoolId];
            
            // restart pooling
            mainPoolIndex = mainPoolIndex.add(1);
            mainPoolId = keccak256(abi.encodePacked(mainPoolIndex));
            poolIds.push(mainPoolId);
            poolPrices[mainPoolId] = gov.getMainPoolPrice();
            poolSizes[mainPoolId] = gov.getMainPoolSize();
            poolIdMap[mainPoolId] = mainPoolIndex;
            isMainPool[mainPoolId] = true;
            poolCreators[mainPoolId] = house;
            creatorPools[house].push(mainPoolId);

            _pay_winner(_lastpoolId, _last_pool_size);
        }    
    }
    
    function getPoolers(bytes32 _pool) public view returns (address payable[] memory) {
        return poolers[_pool];
    }

    function getWinner(bytes32 poolId) public view returns (address payable) {
        return winners[poolId];
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

    function _pay_winner(bytes32 poolId, uint256 pool_size_) internal {        
        bytes32 randBase = keccak256(abi.encodePacked(poolersStakes[poolId][poolers[poolId][0]], poolers[poolId][0]));
        uint256 totalStaked = poolersStakes[poolId][poolers[poolId][0]];        
        
        for(uint8 i = 1; i < pool_size_; i++) {
            randBase = keccak256(abi.encodePacked(poolersStakes[poolId][poolers[poolId][i]], randBase, poolers[poolId][i]));
            totalStaked = totalStaked.add(poolersStakes[poolId][poolers[poolId][i]]);
        }

        uint256 toHouse = totalStaked.mul(gov.getHouseCut()).div(100);        

        // Winner should pay all gas costs
        uint256 _amount_to_win = totalStaked.sub(toHouse).sub(gov.getTransferGas().mul(2));
        
        uint256 _winnner_id = uint256(keccak256(abi.encodePacked(totalStaked, randBase))) % (pool_size_);
        
        address payable _winner = poolers[poolId][_winnner_id];

        // pay winner first
        _winner.transfer(_amount_to_win);
        // then send house's cut to contract creator
        house.transfer(toHouse);        
        // set winner for pool_id
        winners[poolId] = _winner;
        isConcluded[poolId] = true;
    }

function uint2str(
  uint256 _i
)
  internal
  pure
  returns (string memory str)
{
  if (_i == 0)
  {
    return "0";
  }
  uint256 j = _i;
  uint256 length;
  while (j != 0)
  {
    length++;
    j /= 10;
  }
  bytes memory bstr = new bytes(length);
  uint256 k = length;
  j = _i;
  while (j != 0)
  {
    bstr[--k] = bytes1(uint8(48 + j % 10));
    j /= 10;
  }
  str = string(bstr);
}
}
