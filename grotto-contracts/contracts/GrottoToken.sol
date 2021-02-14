/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.8.0;

import "./interface/GrottoTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GrottoToken is GrottoTokenInterface, ERC20("Grotto", "GROTTO") {
    address grotto = 0x602977Cc32F9199cF1d29a1f2E8cA7bD3b6b5805;
    constructor() {}    

    function mintToken(address owner, uint256 amount) public override {
        require(grotto == msg.sender, 'Grotto: You can not do that');
        require(owner != address(0), "ERC20: mint to the zero address");
        _mint(owner, amount);
    }

    function setGrotto(address newGrotto) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        grotto = newGrotto;
    }    
}