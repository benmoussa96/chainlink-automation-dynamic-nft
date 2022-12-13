const { ethers } = require("hardhat");

async function main() {
    const WeatherNFT = await ethers.getContractFactory("WeatherNFT");
    const weatherNFT = await WeatherNFT.deploy();

    await weatherNFT.deployed();

    console.log("WeatherNFT deployed to:", weatherNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });