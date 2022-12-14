// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
// This import includes functions from both ./KeeperBase.sol and ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports
import "hardhat/console.sol";

contract WeatherNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public /*immutable*/ interval;
    uint public lastTimestamp;

    int256 public currentTemperature;

    // IPFS URIs for the dynamic nft graphics/metadata.
    string[] emojiUrisIpfs = [
        "https://ipfs.io/ipfs/QmbMNrzU2qRnhRvDHmaChzfA6pq36QswYhzNFoqEWoEaMi?filename=slightly-smiling-face.json",
        "https://ipfs.io/ipfs/QmS3JPCBGtmhK3bsrroUt9c7oatQ4K1FKYwAf4VthdCNzd?filename=grinning-squinting-face.json",
        "https://ipfs.io/ipfs/QmQfXVuX3WCuQSW3n2tWk9gTXXQXrP9kvPY6PM7WZD9qKg?filename=pensive-face.json"
    ];

    // event TokensUpdated (string message);

    constructor(uint updateInterval, address _link, address _oracle) ERC721("WeatherNFT", "WTHRNFT") {
        // This sets the keeper update interval.
        interval = updateInterval;
        lastTimestamp = block.timestamp;

        // This sets the link Token and Oracle for the weather feed
        // For the Ethereum Goerli Testnet we have:
        // LINK Token Address: 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
        // Operator Address: 0xB9756312523826A566e222a34793E414A81c88E1
        setChainlinkToken(_link);
        setChainlinkOracle(_oracle);

        // currentTemperature = getLatestTemperature();
        currentTemperature = 0;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);

        // By default, when you mint, you get a Slightly Smiling NFT.
        string memory defaultUri = emojiUrisIpfs[0];

        _setTokenURI(tokenId, defaultUri);
    }

    function checkUpkeep(bytes calldata /*checkData*/) external view override returns(bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = (block.timestamp - lastTimestamp) > interval; 
    }

    function performUpkeep (bytes calldata /*performData*/) external override {
        // Revalidating the upkeep in the performUpkeep function is highly recommended
        if ((block.timestamp - lastTimestamp) > interval) {
            lastTimestamp = block.timestamp;
            // int latestTemperature = getLatestTemperature();
            int latestTemperature = 0;

            uint emojiIndex;

            if (latestTemperature < 10 && currentTemperature >= 10) {
                // updateAllTokenUris("pensive-face");
                emojiIndex = 0;

            } else if (latestTemperature > 20 && currentTemperature <= 20) {
                // updateAllTokenUris("grinning-squinting-face");
                emojiIndex = 1;

            } else if (currentTemperature > 20 || currentTemperature < 10) {
                // updateAllTokenUris("slightly-smiling-face");
                emojiIndex = 0;

            } else {
                console.log("NOTHING TO UPDATE!");
                currentTemperature = latestTemperature;
                return;
            }

            for (uint i = 0; i < _tokenIdCounter.current(); i++) {
                _setTokenURI(i, emojiUrisIpfs[emojiIndex]);
            }

            currentTemperature = latestTemperature;
        } else {
            console.log("UPKEEP INTERVAL IS STILL NOT UP!");
            return;
        }
    }

    // function updateAllTokenUris(string memory emoji) internal {
    //     if (compareStrings("slightly-smiling-face", emoji)) {
    //         for (uint i = 0; i < _tokenIdCounter.current(); i++) {
    //             _setTokenURI(i, emojiUrisIpfs[0]);
    //         }
    //     } else if (compareStrings("grinning-squinting-face", emoji)) {
    //         for (uint i = 0; i < _tokenIdCounter.current(); i++) {
    //             _setTokenURI(i, emojiUrisIpfs[1]);
    //         }
    //     } else if (compareStrings("pensive-face", emoji)) {
    //         for (uint i = 0; i < _tokenIdCounter.current(); i++) {
    //             _setTokenURI(i, emojiUrisIpfs[2]);
    //         }
    //     }

    //     emit TokensUpdated(emoji);
    // }
    
    // function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    //     return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    // }

    // function getLatestTemperature() public view returns (int256) {
    //     // Implment fetching temperature here!
        
    //     return 0;
    // }
    

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
