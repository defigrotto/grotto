// scripts/deploy.js
async function main() {
    // We get the contract to deploy
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