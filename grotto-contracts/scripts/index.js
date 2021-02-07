// scripts/index.js
async function main() {
    const accounts = await ethers.provider.listAccounts();
    console.log(accounts);
    const signers = await ethers.getSigners();
    console.log(signers);
    const Grotto = await ethers.getContractFactory('Grotto');
    const grotto = await Grotto.deploy();

    await grotto.deployed();
    console.log(`Grotto: ${grotto.address}`);

    signers[0].sendTransaction({
        to: grotto.address,
        value: ethers.utils.parseEther("10")
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });