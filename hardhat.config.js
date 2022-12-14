const { mnemonic, accountPrivateKey, goerliNetworkEndpoint, alchemyApiKey } = require('./secrets.json');

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
            url: "http://127.0.0.1:7545",
            allowUnlimitedContractSize: true
        },
        goerli: {
            url: goerliNetworkEndpoint,
            accounts: [accountPrivateKey],
            allowUnlimitedContractSize: true
        }
    }
};