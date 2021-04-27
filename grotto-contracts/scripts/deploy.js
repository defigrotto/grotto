// scripts/deploy.js
async function main() {
    let deployToken = false;
    let deployStore = false;
    let deployGov = false;
    let deployGrotto = true;
    let mintTokens = true;
    let tokenAddress = "0xE8df890C7f3c464178f699a75e1b3EBf5788F137";
    let storeAddress = "0x105D525A6e9eA005868d77FA55730b759Fe76051";
    let govAddress = "0x16167CCB391Dbed3b68D1F4262fBB01164494ecD";
    let grottoAddress = "0x90801416Fa4482F2bb35EcE122f2f7484D81b338";
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
        const grotto = await Grotto.deploy(tokenAddress, storeAddress, mintTokens);
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