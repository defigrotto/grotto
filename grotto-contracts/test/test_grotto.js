// test/Box.test.js
// Load dependencies
const { expect, assert } = require('chai');

const TIMEOUT = 120000;
const address0 = "0x0000000000000000000000000000000000000000";

// Start test block
describe('Grotto', function () {
  before(async function () {
    this.timeout(TIMEOUT);
    this.accounts = await ethers.provider.listAccounts();
    this.signers = await ethers.getSigners();
    this.Grotto = await ethers.getContractFactory('Grotto');
    this.grotto = await this.Grotto.deploy();

    await this.grotto.deployed();
    console.log(`Grotto: ${this.grotto.address}`);

      // this.signers[0].sendTransaction({
      //   to: this.grotto.address,
      //   value: ethers.utils.parseEther("44.8");
      // });
  });

  beforeEach(async function () {

  });

  it('should enter main pool', async function () {
    let sum = 0;
    for (let i = 0; i < this.signers.length; i++) {      
      const gi = await this.grotto.connect(this.signers[i]);
      const toSend = 0.2 + Math.random();
      const overrides = {
        value: ethers.utils.parseEther(toSend + "")
      };
      console.log(`Entering Pool ${i}: ${this.accounts[i]} with ${ethers.utils.parseEther(toSend + "")}`);

      sum += toSend;
      await gi.enterMainPool(overrides);
      console.log(`Total Stacked: ${sum}`);
    }    
  }).timeout(TIMEOUT);

  it('should select winners', async function () {
    const pool1 = "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6";
    const pool2 = "0x405787fa12a823e0f2b7631cc41b3ba8828b3321ca811111fa75cd3aa3bb5ace";

    const address1 = await this.grotto.getWinner(pool1);
    const address2 = await this.grotto.getWinner(pool2);
    console.log(address1);
    console.log(address2);    
    assert.notEqual(address1, address0);
    assert.notEqual(address2, address0);
    console.log(await ethers.provider.getBalance(address1));
    console.log(await ethers.provider.getBalance(address2));
  }).timeout(TIMEOUT);

  it('should start a new pool', async function () {
    const poolName = "Segun's Pool";
    const creator = this.accounts[5];
    const gi = await this.grotto.connect(this.signers[5]);
    const toSend = 0.2;
    const overrides = {
      value: ethers.utils.parseEther(toSend + "")
    };
    
    console.log(`Creating Pool ${poolName}: ${creator} with ${ethers.utils.parseEther(toSend + "")}`);
    await gi.startNewPool(poolName, 3, overrides);
  }).timeout(TIMEOUT);

  it('should start a second pool', async function () {
    const poolName = "Segun's Pool - 2";
    const creator = this.accounts[6];
    const gi = await this.grotto.connect(this.signers[6]);
    const toSend = 0.25;
    const overrides = {
      value: ethers.utils.parseEther(toSend + "")
    };
    
    console.log(`Creating Pool ${poolName}: ${creator} with ${ethers.utils.parseEther(toSend + "")}`);
    await gi.startNewPool(poolName, 4, overrides);
  }).timeout(TIMEOUT);  

  it('should start a third pool', async function () {
    const poolName = "The Martians";
    const creator = this.accounts[7];
    const gi = await this.grotto.connect(this.signers[7]);
    const toSend = 0.125;
    const overrides = {
      value: ethers.utils.parseEther(toSend + "")
    };
    
    console.log(`Creating Pool ${poolName}: ${creator} with ${ethers.utils.parseEther(toSend + "")}`);
    await gi.startNewPool(poolName, 5, overrides);
  }).timeout(TIMEOUT);  

  it('should get pool details', async function () {
    const pool1Name = "Segun's Pool";
    const pool2Name = "Segun's Pool - 2";
    const pool3Name = "The Martians";

    const pool1Creator = this.accounts[5];
    const pool2Creator = this.accounts[6];
    const pool3Creator = this.accounts[7];

    const poolDetails1 = await this.grotto.getPoolDetails(pool1Name, pool1Creator);
    validatePoolDetails(poolDetails1, pool1Creator, 0.2, 3);

    const poolDetails2 = await this.grotto.getPoolDetails(pool2Name, pool2Creator);
    validatePoolDetails(poolDetails2, pool2Creator, 0.25, 4);    

    const poolDetails3 = await this.grotto.getPoolDetails(pool3Name, pool3Creator);
    validatePoolDetails(poolDetails3, pool3Creator, 0.125, 5);    
  }).timeout(TIMEOUT);

  it('should get all pools', async function () {
    const allPools = await this.grotto.getAllPools();    
    assert.equal(allPools.length, 6);
    let pd = await this.grotto.getPoolDetailsById(allPools[0]);
    assert.isTrue(pd[5]);
    pd = await this.grotto.getPoolDetailsById(allPools[1]);
    assert.isTrue(pd[5]);
    pd = await this.grotto.getPoolDetailsById(allPools[2]);
    assert.isTrue(pd[5]);    
  }).timeout(TIMEOUT);
});

function validatePoolDetails(poolDetails, account, price, size) {
  console.log(poolDetails);
  assert.equal(poolDetails[3].toNumber(), size);
  assert.equal(poolDetails[1], poolDetails[4]);
  assert.equal(poolDetails[1], account);  
  assert.isNotTrue(poolDetails[5])
  // Note: This test will fail in production unless price of ether is $500
  // assert.equal(ethers.util.formatEther(poolDetails[2]), (price * 500));  
}