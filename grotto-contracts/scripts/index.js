// scripts/index.js
async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log(accounts);

}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });