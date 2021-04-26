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


// tokenAddress: 0x90a81fE6E78c12e090C8FFa48a24e8CFb61B6bD9
// storeAddress: 0xd7Af206e780D21aA9B1AD46DE96b5Dbe0c4a0C99
// govAddress: 0x3E869b3d1bbd3dEE0c9e01549E5A5fab632618a7
// grottoAddress: 0x2781a9845919694B976A6425d10E735066ef9e0F