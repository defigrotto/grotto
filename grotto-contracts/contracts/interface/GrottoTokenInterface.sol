/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface GrottoTokenInterface is IERC20 {
    function mintToken(address, uint256) external;
    function setGrotto(address) external;
    function stake(address, address, uint256) external;
    function unstake(address, address, uint256) external;
    function setGrotto(address _grotto, address _parent) external;
}