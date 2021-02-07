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
      await gi.enterPool(overrides);
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
});