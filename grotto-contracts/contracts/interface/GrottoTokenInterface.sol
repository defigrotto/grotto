/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface GrottoTokenInterface is IERC20 {
    function mintToken(address owner, uint256 amount) external;
    function setGrotto(address) external;
}