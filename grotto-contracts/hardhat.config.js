const { accounts } = require('./env');

require('@nomiclabs/hardhat-ethers');
const myAccounts = require('./env');
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.7.3",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./build"
  },
  networks: {
    bsc_testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      accounts: myAccounts.privateKeys
    },
    sokol: {
      url: "https://sokol.poa.network",
      accounts: myAccounts.privateKeys,
      // gas: 582876,
      // gasPrice: 10000000000
    }    
  },
};
