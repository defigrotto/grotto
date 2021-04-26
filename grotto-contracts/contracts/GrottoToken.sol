/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;

import "./interface/GrottoTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GrottoToken is GrottoTokenInterface, ERC20("Grotto", "GROTTO") {
    address private grotto = 0x2781a9845919694B976A6425d10E735066ef9e0F;
    
    constructor() {
    }    

    function mintToken(address owner, uint256 amount) public override {
        require(grotto == msg.sender, 'Grotto: You can not do that');
        require(owner != address(0), "ERC20: mint to the zero address");
        _mint(owner, amount);
    }

    function setGrotto(address newGrotto) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        grotto = newGrotto;
    }

    function stake(address staker, address stakeMaster, uint256 amount) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        _transfer(staker, stakeMaster, amount);
    }

    function unstake(address stakeMaster, address staker, uint256 amount) public override {
        require(msg.sender == grotto, "Grotto: You can't do that");
        _transfer(stakeMaster, staker, amount);
    }    
}