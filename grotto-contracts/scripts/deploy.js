// scripts/deploy.js
//https://abi.hashex.org/
async function main() {
    let deployToken = true;
    let deployStore = true;
    let deployGov = true;
    let deployGrotto = true;
    let tokenAddress = "0x5Afe41d0Ad5F2a6E486D5A115462a3a7cBf50254";
    let storeAddress = "0xd3E74829CC67905BEdcD8A8c817E673BEbc199F8";
    let govAddress = "0xfE0cb62fbbdbaf56c21e179712e57A9b6e24F4A0";
    let grottoAddress = "0xf937D32ce61105297d13F86Bde8F4f441db11108";
    //"npm run deploy:grotto_token && npm run deploy:store &&  npm run deploy:gov &&  npm run deploy"    

    const [deployer] = await ethers.getSigners();
    console.log("Account balance:", (await deployer.getBalance()).toString());
    console.log("Account:", deployer.address);

    // deploy Token    
    if (deployToken === true) {
        const GrottoToken = await ethers.getContractFactory("GrottoToken");
        console.log("Deploying GrottoToken...");
        const grottoToken = await GrottoToken.deploy();
        await grottoToken.deployed();
        console.log("GrottoToken deployed to:", grottoToken.address);
        tokenAddress = grottoToken.address;
    } 

    if (deployStore === true) {
        const Storage = await ethers.getContractFactory("Storage");
        console.log("Deploying Storage...");
        const store = await Storage.deploy();
        await store.deployed();
        console.log("Storage deployed to:", store.address);
        storeAddress = store.address;
    } 

    if(tokenAddress === undefined) {
        throw Error('Token was not deployed and token address was not set`')
    }

    if(storeAddress === undefined) {
        throw Error('Store was not deployed and store address was not set`')
    }

    if (deployGov === true) {
        const Governance = await ethers.getContractFactory("Governance");
        console.log("Deploying Governance...");
        const gov = await Governance.deploy(tokenAddress, storeAddress);
        await gov.deployed();
        console.log("Governance deployed to:", gov.address);
        govAddress = gov.address;
    }

    if (deployGrotto === true) {
        const Grotto = await ethers.getContractFactory("Grotto");
        console.log("Deploying Grotto...");
        const grotto = await Grotto.deploy(tokenAddress, storeAddress);
        await grotto.deployed();
        console.log("Grotto deployed to:", grotto.address);
        grottoAddress = grotto.address;
    }
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });