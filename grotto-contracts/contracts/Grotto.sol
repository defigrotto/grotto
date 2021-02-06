/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.6.0 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract Grotto is ERC20 ('Grotto', 'GROTTO') {
    using SafeMath for uint256;
    
    event DEBUG(uint256 msg);
    event DEBUG(string msg);
    
    AggregatorV3Interface internal priceFeed;
    address constant internal MAINNET_ETH_USD_PF = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address constant internal KOVAN_ETH_USD_PF = 0x9326BFA02ADD2366b30bacB125260Af641031331;
    address constant internal BSC_ETH_USD_PF = 0x9ef1B8c0E4F7dc8bF5719Ea496883DC6401d5b2e;
    
    // Amount that must be sent to the pool
    mapping (bytes32 => uint256) internal _pool_prices;
    
    // Maz Size of Pool
    mapping (bytes32 => uint256) internal _pool_sizes;
    
    uint256 internal _main_pool_index = 1;
    
    // Pool ID, increments after every time the pool is filled
    bytes32 internal _main_pool_id = keccak256(abi.encodePacked(_main_pool_index));
    
    // Array of pool IDs
    bytes32[] internal _pool_ids;
    
    // poolers in a particular pool identified by bytes32
    mapping (bytes32 => address[]) internal _poolers;
    
    // poolers stakes in a particular pool identified by bytes32
    mapping (bytes32 => mapping (address => uint256)) internal _poolers_stakes;
    
    
    function getPoolers(bytes32 _pool) public view returns (address[] memory) {
        return _poolers[_pool];
    }
    
    
    // function changeMainPoolSize(uint256 new_size_) public {
    //     // this function should be implemented only when governance is figured out
    //     revert('Not Yet implemented');
    // }
    
    // function changeMainPoolPrice(uint256 new_size_) public {
    //     // this function should be implemented only when governance is figured out
    //     revert('Not Yet implemented');
    // }    

    
    constructor() public {
        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);
        _pool_ids.push(_main_pool_id);
        _pool_prices[_main_pool_id] = 1;
        _pool_sizes[_main_pool_id] = 1;
    }
    
    function enterPool() public payable {
        uint256 _value = msg.value;
        address _pooler = msg.sender;
        // calculate dollar value
        uint256 _usd_value = getLatestPrice().mul(_value);
        emit DEBUG(_usd_value);
        if(_usd_value < _pool_prices[_main_pool_id]) {
            revert('ETH Sent is less than pool price.');
        } else {
            _poolers_stakes[_main_pool_id][_pooler] = _poolers_stakes[_main_pool_id][_pooler].add(_usd_value);
            _poolers[_main_pool_id].push(_pooler);
        }
        
        if(_poolers[_main_pool_id].length == _pool_sizes[_main_pool_id]) {
            emit DEBUG('Calculating Winner');
            emit DEBUG(_main_pool_index);
            // calculate the winner and restart pool
            //address[] memory _poolers = _poolers[_main_pool_id];
            //uint256 _last_pool_id = _main_pool_index;
            
            // restart pooling
            _main_pool_index = _main_pool_index.add(1);
            _main_pool_id = keccak256(abi.encodePacked(_main_pool_index));
            _pool_ids.push(_main_pool_id);
            _pool_prices[_main_pool_id] = 1;
            _pool_sizes[_main_pool_id] = 1;            
        }
        
        msg.sender.transfer(_value);
    }
    
    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return uint256(price).div(10**8);
    }    
}
