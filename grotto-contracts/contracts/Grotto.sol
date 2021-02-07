/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Grotto is ERC20 ('Grotto', 'GROTTO') {
    using SafeMath for uint256;
    //event DEBUG(string, bytes32);
    //event DEBUG(string, address);
    event DEBUG(string, uint256);

    AggregatorV3Interface internal priceFeed;
    address constant internal MAINNET_ETH_USD_PF = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant internal KOVAN_ETH_USD_PF = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address constant internal BSC_ETH_USD_PF = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    uint256 constant internal TRANSFER_GAS = 2300;
    
    // Amount that must be sent to the pool
    mapping (bytes32 => uint256) internal _pool_prices;
    
    // Max Size of Pool
    mapping (bytes32 => uint256) internal _pool_sizes;

    // Pool ETH Price in USD to determine a static number of ETH that must be sent
    
    uint256 internal _main_pool_index = 1;
    
    // Pool ID, increments after every time the pool is filled
    bytes32 internal _main_pool_id = keccak256(abi.encodePacked(_main_pool_index));
    uint256 _one_ether = 1000000000000000000;
    // $100
    uint256 _main_pool_price = 100;
    uint256 _main_pool_size = 10;
    
    // Array of pool IDs
    bytes32[] internal _pool_ids;

    // Map of pool_id to their id in the _pool_ids array
    mapping (bytes32 => uint256) internal _pool_id_map;

    // Map of pool ids to their creators
    mapping (bytes32 => address) internal _pool_creators;
    
    // poolers in a particular pool identified by bytes32
    mapping (bytes32 => address payable[]) internal _poolers;
    
    // poolers stakes in a particular pool identified by bytes32
    mapping (bytes32 => mapping (address => uint256)) internal _poolers_stakes;
    
    address payable house;
    // percentage of winning that goes to house
    uint256 _house_cut = 10;

    mapping(bytes32 => address payable) internal _winners;
    
    
    constructor() {
        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);
        _pool_ids.push(_main_pool_id);
        _pool_prices[_main_pool_id] = _main_pool_price;
        _pool_sizes[_main_pool_id] = _main_pool_size;
        _pool_id_map[_main_pool_id] = _main_pool_index;
        house = msg.sender;
    }
    
    function enterPool(string calldata pool_name_, address _creator) public payable {
        uint256 _value = msg.value;        
        address payable _pooler = msg.sender;
        bytes32 _pool_id = keccak256(abi.encodePacked(pool_name_, _creator));        
        // calculate dollar value        
        uint256 _latest_usd_price = getLatestPrice();
        uint256 _usdt_value = _latest_usd_price.mul(_value);    

        uint256 _pool_price_in_ether = _pool_prices[_pool_id].mul(_one_ether).div(_latest_usd_price);
        uint256 _pool_price_dollar_value = _pool_price_in_ether.mul(_latest_usd_price);
        if(_usdt_value < _pool_price_dollar_value) {
            revert('ETH Sent is less than pool price.');
        } else {
            _poolers_stakes[_pool_id][_pooler] = _poolers_stakes[_pool_id][_pooler].add(_value);
            _poolers[_pool_id].push(_pooler);
        }
        
        if(_poolers[_pool_id].length == _pool_sizes[_pool_id]) {                                
            // pay winner
            _pay_winner(_pool_id, _pool_sizes[_pool_id]);
        }            
    }

    function enterPool() public payable {
        uint256 _value = msg.value;        
        address payable _pooler = msg.sender;
        // calculate dollar value        
        uint256 _latest_usd_price = getLatestPrice();
        uint256 _usdt_value = _latest_usd_price.mul(_value);    

        uint256 _pool_price_in_ether = _pool_prices[_main_pool_id].mul(_one_ether).div(_latest_usd_price);
        uint256 _pool_price_dollar_value = _pool_price_in_ether.mul(_latest_usd_price);
        if(_usdt_value < _pool_price_dollar_value) {
            revert('ETH Sent is less than pool price.');
        } else {
            _poolers_stakes[_main_pool_id][_pooler] = _poolers_stakes[_main_pool_id][_pooler].add(_value);
            _poolers[_main_pool_id].push(_pooler);
        }
        
        if(_poolers[_main_pool_id].length == _pool_sizes[_main_pool_id]) {                    
            bytes32 _last_pool_id = _main_pool_id;
            uint256 _last_pool_size = _pool_sizes[_main_pool_id];
            
            // restart pooling
            _main_pool_index = _main_pool_index.add(1);
            _main_pool_id = keccak256(abi.encodePacked(_main_pool_index));
            _pool_ids.push(_main_pool_id);
            _pool_prices[_main_pool_id] = _main_pool_price;
            _pool_sizes[_main_pool_id] = _main_pool_size;
            _pool_id_map[_main_pool_id] = _main_pool_index;

            _pay_winner(_last_pool_id, _last_pool_size);
        }    
    }
    
    function getPoolers(bytes32 _pool) public view returns (address payable[] memory) {
        return _poolers[_pool];
    }

    function getWinner(bytes32 pool_id_) public view returns (address payable) {
        return _winners[pool_id_];
    }
    
    
    // function changeMainPoolSize(uint256 new_size_) public {
    //     // this function should be implemented only when governance is figured out
    //     revert('Not Yet implemented');
    // }
    
    // function changeMainPoolPrice(uint256 new_size_) public {
    //     // this function should be implemented only when governance is figured out
    //     revert('Not Yet implemented');
    // }    

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

    function _pay_winner(bytes32 pool_id_, uint256 pool_size_) internal {        
        bytes32 randBase = keccak256(abi.encodePacked(_poolers_stakes[pool_id_][_poolers[pool_id_][0]], _poolers[pool_id_][0]));
        uint256 _total_staked = _poolers_stakes[pool_id_][_poolers[pool_id_][0]];        
        
        for(uint8 i = 1; i < pool_size_; i++) {
            randBase = keccak256(abi.encodePacked(_poolers_stakes[pool_id_][_poolers[pool_id_][i]], randBase, _poolers[pool_id_][i]));
            _total_staked = _total_staked.add(_poolers_stakes[pool_id_][_poolers[pool_id_][i]]);
        }

        uint256 _to_house = _total_staked.mul(_house_cut).div(100);        

        // Winner should pay all gas costs
        uint256 _amount_to_win = _total_staked.sub(_to_house).sub(TRANSFER_GAS.mul(2));
        
        uint256 _winnner_id = uint256(keccak256(abi.encodePacked(_total_staked, randBase))) % (pool_size_);
        
        address payable _winner = _poolers[pool_id_][_winnner_id];

        // pay winner first
        _winner.transfer(_amount_to_win);
        // then send house's cut to contract creator
        house.transfer(_to_house);        
        // set winner for pool_id
        _winners[pool_id_] = _winner;
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
