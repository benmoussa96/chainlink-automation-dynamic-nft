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

    // Setting the contract's parameters
    // Keeper's update interval:
    const updateInterval = 10;
    // LINK Token Address on Goerli network:
    const _link = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    // ORACLE Address on Goerli network
    const _oracle = '0xB9756312523826A566e222a34793E414A81c88E1';

    const WeatherNFT = await ethers.getContractFactory("WeatherNFT");
    const weatherNFT = await WeatherNFT.deploy(updateInterval, _link, _oracle, { gasLimit: 3000000 });

    await weatherNFT.deployed();

    console.log("WeatherNFT deployed to:", weatherNFT.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exitCode = 1;
    });