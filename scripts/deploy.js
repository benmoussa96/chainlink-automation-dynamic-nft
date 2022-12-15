const { ethers } = require("hardhat");

async function main() {
    // Getting info about the network
    const network = await ethers.provider.getNetwork();
    console.log("Deploying contract to network:", network.name);
    console.log("Network Chain Id:", network.chainId);

    // Getting info about the deployer
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // Keeper's update interval:
    const updateInterval = 10;

    const WeatherNFT = await ethers.getContractFactory("WeatherNFT");
    const weatherNFT = await WeatherNFT.deploy(updateInterval, { gasLimit: 4000000 });

    await weatherNFT.deployed();

    console.log("WeatherNFT deployed to:", weatherNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });