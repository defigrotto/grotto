var ethJsUtil = require('ethereumjs-util');
const Web3 = require('web3');
const web3 = new Web3("https://sokol.poa.network");

web3.eth.getTransactionCount("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc").then((index) => {
    var updateAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", (index + 1)));
    console.log(`updateAddress: ${ethJsUtil.toChecksumAddress(updateAddress)}`);
});

