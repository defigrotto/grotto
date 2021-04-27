/// SPDX-License-Identifier: MIT-0
pragma solidity >=0.7.3 <0.9.0;

import "./interface/GrottoTokenInterface.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GrottoToken is GrottoTokenInterface, ERC20("Grotto", "GROTTO") {
    address private grotto = address(0);
    address private parent = address(0);
    
    constructor() {
    }

    function setGrotto(address _grotto, address _parent) public override {
        if (grotto == address(0) && parent == address(0)) {
            parent = _parent;
            grotto = _grotto;
        } else if (parent == _parent) {
            grotto = _grotto;
        } else {
            revert('OACDT');
        }
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