/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./GovernanceInterface.sol";

contract Governance is GovernanceInterface, ERC20('Governance Contract', 'DOTGOV') {
    using SafeMath for uint256;

    address[]  INITIAL_GOVERNORS;
    
    // amount of gas needed for transfer
    uint256 private TRANSFER_GAS = 2300;

    // stake price for the main pool. $100
    uint256 private MAIN_POOL_PRICE = 100000000000000000000;

    // number of accounts before winner is calculated.
    uint256 private MAIN_POOL_SIZE = 3;

    // percentage of winning that goes to house. 10%
    uint256 private HOUSE_CUT = 10;

    // how many % of new tokens go to house. 10%
    uint256 private HOUSE_CUT_NEW_TOKEN = 10;

    // Minimum price for user defined pools
    uint256 private MINIMUM_POOL_PRICE = 10;

    // Minimum size for user defined pools
    uint256 private MINIMUM_POOL_SIZE = 10;    

    // Maximum size for user defined pools
    uint256 private MAXIMUM_POOL_SIZE = 100;

    constructor() {
        INITIAL_GOVERNORS.push(0xC04915f6b3ff85b50A863eB1FcBF368171539413);
        INITIAL_GOVERNORS.push(0xb58c226a300fF6dc1eF762d62c536c7aED5CeA74);
        INITIAL_GOVERNORS.push(0xB6D80F6d661927afEf42f39e52d630E250696bc4);
    }

    function getTransferGas() public override view returns (uint256) {
        return TRANSFER_GAS;
    }

    function getMainPoolPrice() public override view returns (uint256) {
        return MAIN_POOL_PRICE;
    }

    function getMainPoolSize() public override view returns (uint256) {
        return MAIN_POOL_SIZE;
    }

    function getHouseCut() public override view returns (uint256) {
        return HOUSE_CUT;
    }

    function getHouseCutNewTokens() public override view returns (uint256) {
        return HOUSE_CUT_NEW_TOKEN;
    }

    function getMinimumPoolPrice() public override view returns (uint256) {
        return MINIMUM_POOL_PRICE;
    }

    function getMinimumPoolSize() public override view returns (uint256) {
        return MINIMUM_POOL_SIZE;
    }    

    function getMaximumPoolSize() public override view returns (uint256) {
        return MAXIMUM_POOL_SIZE;
    }        
}