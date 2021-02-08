// scripts/deploy.js
async function main() {
    const [deployer] = await ethers.getSigners();
    console.log(
        "Deploying contracts with the account:",
        deployer        
    );    
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const Grotto = await ethers.getContractFactory("Grotto");
    console.log("Deploying Grotto...");
    const grotto = await Grotto.deploy();
    await grotto.deployed();
    console.log("Grotto deployed to:", grotto.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });