const { exec } = require('child_process');
var ethJsUtil = require('ethereumjs-util');
const Web3 = require('web3');
const web3 = new Web3("https://sokol.poa.network");

web3.eth.getTransactionCount("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc").then((index) => {
    var shouldDeployToken = true;
    var tokenAddress;
    var storeAddress;
    var govAddress;
    var grottoAddress;

    index--;
    
    if (shouldDeployToken) {
        tokenAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));
        console.log(`tokenAddress: ${ethJsUtil.toChecksumAddress(tokenAddress)}`);

        storeAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));

        govAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));

        grottoAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));
    } else {
        storeAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));

        govAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));

        grottoAddress = ethJsUtil.bufferToHex(ethJsUtil.generateAddress("0x94Ce615ca10EFb74cED680298CD7bdB0479940bc", ++index));
    }

    console.log(`storeAddress: ${ethJsUtil.toChecksumAddress(storeAddress)}`);
    console.log(`govAddress: ${ethJsUtil.toChecksumAddress(govAddress)}`);
    console.log(`grottoAddress: ${ethJsUtil.toChecksumAddress(grottoAddress)}`);

    // Grotto.sol
    exec(`sed -i .bak 's/address private storeAddress.*;/address private storeAddress = ${ethJsUtil.toChecksumAddress(storeAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Grotto.sol`, (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.log(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
    });

    if (shouldDeployToken) {
        exec(`sed -i .bak 's/address private tokenAddress.*;/address private tokenAddress = ${ethJsUtil.toChecksumAddress(tokenAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Grotto.sol`, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
                return;
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
                return;
            }
            console.log(`stdout: ${stdout}`);
        });
    }

    // Governance.sol
    exec(`sed -i .bak 's/address private storeAddress.*;/address private storeAddress = ${ethJsUtil.toChecksumAddress(storeAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Governance.sol`, (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.log(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
    });

    if (shouldDeployToken) {
        exec(`sed -i .bak 's/address private tokenAddress.*;/address private tokenAddress = ${ethJsUtil.toChecksumAddress(tokenAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Governance.sol`, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
                return;
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
                return;
            }
            console.log(`stdout: ${stdout}`);
        });
    }

    // storage.sol
    exec(`sed -i .bak 's/address gov.*;/address gov = ${ethJsUtil.toChecksumAddress(govAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Storage.sol`, (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.log(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
    });

    exec(`sed -i .bak 's/address grotto.*;/address grotto = ${ethJsUtil.toChecksumAddress(grottoAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/Storage.sol`, (error, stdout, stderr) => {
        if (error) {
            console.log(`error: ${error.message}`);
            return;
        }
        if (stderr) {
            console.log(`stderr: ${stderr}`);
            return;
        }
        console.log(`stdout: ${stdout}`);
    });

    if (shouldDeployToken) {
        // GrottoToken.sol
        exec(`sed -i .bak 's/address grotto.*;/address grotto = ${ethJsUtil.toChecksumAddress(grottoAddress)};/g' /Users/aardvocate/src/grotto/grotto-contracts/contracts/GrottoToken.sol`, (error, stdout, stderr) => {
            if (error) {
                console.log(`error: ${error.message}`);
                return;
            }
            if (stderr) {
                console.log(`stderr: ${stderr}`);
                return;
            }
            console.log(`stdout: ${stdout}`);
        });
    }
});

