const { accountPrivateKey, alchemyApiKey } = require('./secrets.json');
const { GOERLI_NETWORK_ENDPOINT } = require('./constants.js');

require("@nomiclabs/hardhat-waffle");

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: {
        version: "0.8.9",
        settings: {
            optimizer: {
                enabled: true
            }
        }
    },
    paths: {
        sources: "./contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts"
    },
    networks: {
        localhost: {
            url: "http://127.0.0.1:7545"
        },
        goerli: {
            url: GOERLI_NETWORK_ENDPOINT + alchemyApiKey,
            accounts: [accountPrivateKey]
        }
    }
};