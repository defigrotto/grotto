async function main() {
    let Governance = await ethers.getContractFactory('Governance');
    let gov = await Governance.deploy();

    await gov.deployed();
    console.log(`Governance: ${gov.address}`);

    let acc = await ethers.provider.listAccounts();
    let sig = await ethers.getSigners();

    accounts = [acc[4], acc[5], acc[6], acc[8], acc[7]];
    signers = [sig[4], sig[5], sig[6], sig[8], sig[7]];
    proposedGovernor = acc[0];
    proposedGovernorSig = sig[0];
    removedGovernor = "0xB6D80F6d661927afEf42f39e52d630E250696bc4";
    removedGovernorIndex = 2;

    console.log(await gov.getGovernors());

    gov.on("*", (event) => {
        console.log(event.event);
        console.log(event.args);
        console.log("---------------------------------");
        console.log("");
    });

    // 1. Add new governor and vote
    console.log(accounts[0]);
    let gi = await gov.connect(signers[0]);
    await gi.proposeNewGovernor(proposedGovernor);

    for (i = 0; i < signers.length; i++) {
        try {
            gi = await gov.connect(signers[i]);
            await gi.vote('add_new_governor', true);
        } catch (err) {
            console.log(err);
        }
    }

    signers.push(proposedGovernorSig);
    accounts.push(proposedGovernor);

    // 2. Remove a governor
    gi = await gov.connect(proposedGovernorSig);
    await gi.proposeRemoveGovernor(removedGovernor);

    for (i = 0; i < signers.length; i++) {
        try {
            gi = await gov.connect(signers[i]);
            await gi.vote('remove_new_governor', true);
        } catch (err) {
            console.log(err);
        }
    }
    
    signers.splice(removedGovernorIndex, 1);
    accounts.splice(removedGovernorIndex, 1);

    console.log(await gov.getGovernors());    
}

main()
    .then(() => {
        //process.exit(0)
    })
    .catch(error => {
        console.error(error);
        process.exit(1);
    });