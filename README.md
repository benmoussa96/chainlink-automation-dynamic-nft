# Dar Blockchain Test
Dynamic NFT (ERC721) smart contract created using Solidity, Chainlink and the Ethereum Blockchain.

## Description

The NFT changes it's metadata according to the weather.
* If the temperature is under 10C, we get a "pensive" emoji 😔
* If the temperature is over 20C, we get a "grinning squinting" emoji 😆
* Else we get a "slightly smiling" emoji 🙂

The contract is deployed at: [0x04f5F947296E181Ea92a7cC5796a14a04A47e67f](https://goerli.etherscan.io/address/0x04f5F947296E181Ea92a7cC5796a14a04A47e67f) on the Goerli Testnet. This one is already funded with LINK Tokens.
* First of all, you can mint an NFT using the `safeMint(address to)` function. You can check that it's URI is set by default to the "slightly smiling" emoji by calling the `tokenURI(uint256 tokenId)` function.
* Then, when you call the `performUpkeep(bytes calldata)` function (with [] as parameter), the contract requests the weather data and uptates the URI of all the tokens. Use `tokenURI(uint256 tokenId)` again to verify that the URI has changed.
* Our NFT Contract also implements the Keepers interface so that it is Keepers compatible. This means that it contains custom logic to allow Chainlink Automation to determine when to execute our smart contract functions.

### Built with

* JavaScript
* Solidity
* Npm
* Node.js (14.0.0)
* Hardhat
* Ethers
* Chainlink
* OpenZeppelin
* Chai

## Getting Started

### Dependencies

* [Metamask](https://metamask.io) extension installed in chrome.
* [Alchemy](https://alchemy.com) account and API key.
* [AccuWeather](https://developer.accuweather.com/) account and API key.

### Installing

1. Clone the repo

   ```sh
   git clone https://github.com/benmoussa96/dar-blockchain-test.git
   ```
2. Change into repo root directory

    ```
    cd dar-blockchain-test
    ```
3. Install dependencies

    ```
    npm install
    ```

### Compiling and deploying new contract (optional)

4. Create a `secrets.json` file at the root of theee project:
> :warning: **The account that you supply must have test ETH and test LINK on the Goerli Testnet!**

    ```json
    {
        "mnemonic": "...",
        "accountPrivateKey": "...",
        "alchemyApiKey": "...",
        "accuweatherApiKey": "..."
    }
    ```
5. Compiling the contract:

    ```
    npm run compile
    ```
6. Testing the contract:

    ```
    npm run test
    ```
7. Launching a hardhat node:

    ```
    npm run node
    ```
8. Deploying the contract to the Goerli Testnet:

    ```
    npm run deploy-goerli
    ```
9. **Fund the contract with LINK Tokens and have fun!!**
