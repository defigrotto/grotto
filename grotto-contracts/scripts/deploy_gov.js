// scripts/deploy_gov.js
async function main() {
    const Governance = await ethers.getContractFactory("Governance");
    console.log("Deploying Governance...");
    const gov = await Governance.deploy();
    await gov.deployed();
    console.log("Governance deployed to:", gov.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });