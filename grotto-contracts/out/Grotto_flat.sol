// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3 <0.8.0;

interface GovernanceInterface {
    function getTransferGas() external view returns (uint256);
    function getMainPoolPrice() external view returns (uint256);
    function getMainPoolSize() external view returns (uint256);
    function getHouseCut() external view returns (uint256);
    function getNewTokensMinted() external view returns (uint256);
    function getHouseCutNewTokens() external view returns (uint256);
}


interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}









/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}





/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}






/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
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
    uint256 oneEther = 1000000000000000000;
    
    // Array of pool IDs
    bytes32[] internal poolIds;
    bytes32[] internal completedPoolIds;
    mapping(bytes32 => bool) isMainPool;

    // Map of pool_id to their id in the poolIds array
    mapping (bytes32 => uint256) internal poolIdMap;

    // Map of pool ids to their creators
    mapping (bytes32 => address payable) internal poolCreators;
    
    // poolers in a particular pool identified by bytes32
    mapping (bytes32 => address payable[]) internal poolers;
    
    // poolers stakes in a particular pool identified by bytes32
    mapping (bytes32 => mapping (address => uint256)) internal poolersStakes;
    
    address payable house;

    mapping(bytes32 => address payable) internal winners;    
    
    address private governor = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    
    constructor() {
        gov = GovernanceInterface(governor);
        priceFeed = AggregatorV3Interface(KOVAN_ETH_USD_PF);
        poolIds.push(mainPoolId);
        poolPrices[mainPoolId] = gov.getMainPoolPrice();
        poolSizes[mainPoolId] = gov.getMainPoolSize();
        poolIdMap[mainPoolId] = mainPoolIndex;
        isMainPool[mainPoolId] = true;
        house = msg.sender;
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

    // function enterPool(string calldata poolName, address creator) public payable {
    //     uint256 value = msg.value;        
    //     address payable pooler = msg.sender;
    //     bytes32 poolId = keccak256(abi.encodePacked(poolName, creator));     

    //     _enter_pool(poolId, value, pooler);   
    // }

    function _enter_pool(bytes32 poolId, uint256 _value, address payable _pooler) internal {
        require(poolers[poolId].length < poolSizes[poolId], 'This Pool is full');
        // calculate dollar value  
        uint256 _latest_usd_price = getLatestPrice();
        uint256 _usdt_value = _latest_usd_price.mul(_value);    

        uint256 _pool_price_in_ether = poolPrices[poolId].mul(oneEther).div(_latest_usd_price);
        uint256 _pool_price_dollar_value = _pool_price_in_ether.mul(_latest_usd_price);
        if(_usdt_value < _pool_price_dollar_value) {
            revert('ETH Sent is less than pool price.');
        } else {
            poolersStakes[poolId][_pooler] = poolersStakes[poolId][_pooler].add(_value);
            poolers[poolId].push(_pooler);
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
        address payable _pooler = msg.sender; 
        bytes32 poolId = keccak256(abi.encodePacked(pool_name_, _pooler));        

        require(poolIdMap[poolId] == 0, 'Pool name already exists');
        
        uint256 _latest_usd_price = getLatestPrice();
        uint256 _usdt_value = _latest_usd_price.mul(_value); 

        uint256 _last_index = poolIds.length;
        poolIds.push(poolId);
        poolPrices[poolId] = _usdt_value;
        poolSizes[poolId] = pool_size_ == 0 ? gov.getMainPoolSize() : pool_size_;
        poolIdMap[mainPoolId] = _last_index;
        poolCreators[poolId] = _pooler;
        isMainPool[poolId] = false;
    }

    // function getPoolDetails(string calldata pool_name_, address creator) public view returns (bytes32, address, uint256, uint256, address, bool) {
    //     bytes32 poolId = keccak256(abi.encodePacked(pool_name_, creator));        
    //     return (poolId, creator, poolPrices[poolId], poolSizes[poolId], poolCreators[poolId], isMainPool[poolId]);
    // }

    function getPoolDetails(bytes32 poolId) public view returns (bytes32, address, uint256, uint256, address, bool, uint256) {
        return (poolId, poolCreators[poolId], poolPrices[poolId], poolSizes[poolId], poolCreators[poolId], isMainPool[poolId], poolers[poolId].length);
    }

    function getAllPools() public view returns (bytes32[] memory) {
        return poolIds;
    }

    function enterMainPool() public payable {
        uint256 _value = msg.value;        
        address payable _pooler = msg.sender;
        // calculate dollar value        
        uint256 _latest_usd_price = getLatestPrice();
        uint256 _usdt_value = _latest_usd_price.mul(_value);    

        uint256 _pool_price_in_ether = poolPrices[mainPoolId].mul(oneEther).div(_latest_usd_price);
        uint256 _pool_price_dollar_value = _pool_price_in_ether.mul(_latest_usd_price);
        if(_usdt_value < _pool_price_dollar_value) {
            revert('ETH Sent is less than pool price.');
        } else {
            poolersStakes[mainPoolId][_pooler] = poolersStakes[mainPoolId][_pooler].add(_value);
            poolers[mainPoolId].push(_pooler);
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

            _pay_winner(_lastpoolId, _last_pool_size);
        }    
    }
    
    function getPoolers(bytes32 _pool) public view returns (address payable[] memory) {
        return poolers[_pool];
    }

    function getWinner(bytes32 poolId) public view returns (address payable) {
        return winners[poolId];
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



