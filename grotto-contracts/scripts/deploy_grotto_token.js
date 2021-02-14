// scripts/deploy_grotto_token.js
async function main() {
    const GrottoToken = await ethers.getContractFactory("GrottoToken");
    console.log("Deploying GrottoToken...");
    const grottoToken = await GrottoToken.deploy();
    await grottoToken.deployed();
    console.log("GrottoToken deployed to:", grottoToken.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });