// scripts/deploy_store.js
async function main() {
    const Storage = await ethers.getContractFactory("Storage");
    console.log("Deploying Storage...");
    const store = await Storage.deploy();
    await store.deployed();
    console.log("Storage deployed to:", store.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });