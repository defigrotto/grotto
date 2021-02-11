// scripts/index.js
async function main() {
    let Grotto = await ethers.getContractFactory('Grotto');
    let grotto = await Grotto.deploy();

    await grotto.deployed();
    console.log(`Grotto: ${grotto.address}`);

    let acc = await ethers.provider.listAccounts();
    let sig = await ethers.getSigners();

    accounts = [acc[0], acc[1], acc[2], acc[3], acc[4], acc[8]];
    signers = [sig[0], sig[1], sig[2], sig[3], sig[4], sig[8]];

    // 1. enter main pool
    let pool1 = "0xb10e2d527612073b26eecdfd717e6a320cf44b4afac2b0732d9fcbe2b7fa0cf6";
    for (let i = 0; i < 6; i++) {
        let gi = await grotto.connect(signers[i]);
        let toSend = 0.002 + Math.random();
        let overrides = {
            value: ethers.utils.parseEther(toSend + "")
        };

        console.log(`${accounts[i]} is entering pool with ${toSend}`);
        let resp = await gi.enterMainPool(overrides);
        console.log(resp.hash);        
    }

    for (let i = 0; i < 6; i++) {
        let gi = await grotto.connect(signers[i]);
        let toSend = 0.002 + Math.random();
        let overrides = {
            value: ethers.utils.parseEther(toSend + "")
        };

        console.log(`${accounts[i]} is entering pool with ${toSend}`);
        let resp = await gi.enterMainPool(overrides);
        console.log(resp.hash);        
    }    

    // get winner
    let address1 = await grotto.getWinner(pool1);
    console.log("winner: " + address1);
    console.log(await ethers.provider.getBalance(address1));

    // Start a user defined pool
    let poolName = "Segun's Pool";
    let creator = accounts[3];
    let gi = await grotto.connect(signers[3]);
    let toSend = 0.1;
    let overrides = {
        value: ethers.utils.parseEther(toSend + "")
    };

    console.log(`Creating Pool ${poolName}: ${creator} with ${ethers.utils.parseEther(toSend + "")}`);
    let resp = await gi.startNewPool(poolName, 3, overrides);
    console.log(resp.hash);
    let poolStatus = await gi.getPoolDetailsByPoolName(poolName, creator);
    console.log(poolStatus.poolId);
    let userPool = poolStatus.poolId;


    for (let i = 0; i < 3; i++) {
        const gi = await grotto.connect(signers[i]);
        const toSend = 0.1 + Math.random();
        const overrides = {
            value: ethers.utils.parseEther(toSend + "")
        };
        
        console.log(`${accounts[i]} is entering pool ${userPool} with ${toSend}`);
        let resp = await gi.enterPool(userPool, overrides);
        console.log(resp.hash);        
    }

    // get winner
    address1 = await grotto.getWinner(userPool);
    console.log("winner: " + address1);
    console.log(await ethers.provider.getBalance(address1));

    // // Start another user defined pool
    poolName = "Dayo's Pool";
    creator = accounts[4];
    gi = await grotto.connect(signers[4]);
    toSend = 0.1;
    overrides = {
        value: ethers.utils.parseEther(toSend + "")
    };

    console.log(`Creating Pool ${poolName}: ${creator} with ${ethers.utils.parseEther(toSend + "")}`);
    resp = await gi.startNewPool(poolName, 5, overrides);
    console.log(resp.hash);
    poolStatus = await gi.getPoolDetailsByPoolName(poolName, creator);
    console.log(poolStatus.poolId);
    userPool = poolStatus.poolId;

    // get all pools
    let pools = await grotto.getAllPools();
    console.log(pools);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });