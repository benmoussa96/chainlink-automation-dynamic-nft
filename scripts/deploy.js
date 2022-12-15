const { ethers } = require("hardhat");

const { accuweatherApiKey } = require('../secrets.json');
const { KEEPER_UPDATE_INTERVAL, TUNIS_LOCATION_KEY, ACCUWEATHER_CURRENT_CONDITIONS_ENDPOINT } = require('../constants.js');

async function main() {
    // Getting info about the network
    const network = await ethers.provider.getNetwork();
    console.log("Deploying contract to network:", network.name);
    console.log("Network Chain Id:", network.chainId);

    // Getting info about the deployer
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const WeatherNFT = await ethers.getContractFactory("WeatherNFT");

    const weatherNFT = await WeatherNFT.deploy(
        KEEPER_UPDATE_INTERVAL,
        ACCUWEATHER_CURRENT_CONDITIONS_ENDPOINT + TUNIS_LOCATION_KEY + '?apikey=' + accuweatherApiKey,
        { gasLimit: 4000000 }
    );

    await weatherNFT.deployed();

    console.log("WeatherNFT deployed to:", weatherNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });