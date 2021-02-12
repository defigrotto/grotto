async function main() {
    let Governance = await ethers.getContractFactory('Governance');
    let gov = await Governance.deploy();

    await gov.deployed();
    console.log(`Governance: ${gov.address}`);

    let acc = await ethers.provider.listAccounts();
    let sig = await ethers.getSigners();

    accounts = [acc[4], acc[5], acc[6], acc[8], acc[7]];
    signers = [sig[4], sig[5], sig[6], sig[8], sig[7]];

    // change main pool price
    gov.on("*", (event) => {
        console.log(event.event);
        console.log(event.args);
        console.log("---------------------------------");
        console.log("");
    });

    let gi = await gov.connect(signers[0]);
    await gi.proposeNewValue(125, 'alter_main_pool_price');
    for (i = 0; i < signers.length; i++) {
        console.log(`Vote: ${i + 1}`);
        try {
            gi = await gov.connect(signers[i]);
            await gi.vote('alter_main_pool_price', true);
        } catch (err) {
            console.log(err);
        }
    }

    console.log((await gov.getMainPoolPrice()).toString());

    gi = await gov.connect(signers[3]);
    await gi.proposeNewValue(15, 'alter_house_cut_tokens');
    for (i = 0; i < signers.length; i++) {
        console.log(`Vote: ${i + 1}`);
        try {
            gi = await gov.connect(signers[i]);
            await gi.vote('alter_house_cut_tokens', true);
        } catch (err) {
            console.log(err);
        }
    }

    console.log((await gov.getHouseCutNewTokens()).toString());

}

main()
    .then(() => {
        //process.exit(0)
    })
    .catch(error => {
        console.error(error);
        process.exit(1);
    });