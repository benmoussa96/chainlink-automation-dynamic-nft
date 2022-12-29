const { accountPrivateKey, alchemyApiKey } = require("./secrets.json");
const { GANACHE_ENDPOINT, GOERLI_NETWORK_ENDPOINT } = require("./constants.js");

require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  networks: {
    localhost: {
      url: GANACHE_ENDPOINT,
    },
    goerli: {
      url: GOERLI_NETWORK_ENDPOINT + alchemyApiKey,
      accounts: [accountPrivateKey],
    },
  },
};
