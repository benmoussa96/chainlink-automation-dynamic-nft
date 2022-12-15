// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Chainlink Imports
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

// This import includes functions from both ./KeeperBase.sol and ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

// Dev imports
import "hardhat/console.sol";
import "./DateTime.sol";

contract WeatherNFT is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, KeeperCompatibleInterface, ChainlinkClient {
    using Chainlink for Chainlink.Request;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint public /*immutable*/ interval;
    uint public lastTimestamp;

    address private link;
    uint256 private fee;
    address private oracle;
    bytes32 private jobId;
    string private tunis_geoJson;

    uint256 public currentTemperature;

    // IPFS URIs for the dynamic nft graphics/metadata.
    string[] emojiUrisIpfs = [
        "https://ipfs.io/ipfs/QmbMNrzU2qRnhRvDHmaChzfA6pq36QswYhzNFoqEWoEaMi?filename=slightly-smiling-face.json",
        "https://ipfs.io/ipfs/QmS3JPCBGtmhK3bsrroUt9c7oatQ4K1FKYwAf4VthdCNzd?filename=grinning-squinting-face.json",
        "https://ipfs.io/ipfs/QmQfXVuX3WCuQSW3n2tWk9gTXXQXrP9kvPY6PM7WZD9qKg?filename=pensive-face.json"
    ];

    event TokensUpdated (uint index);
    event AvgTemp(uint256 _result);

    constructor(uint updateInterval/*, address _link, address _oracle*/) ERC721("WeatherNFT", "WTHRNFT") {
        // This sets the keeper update interval:
        interval = updateInterval;
        lastTimestamp = block.timestamp;

        // This sets the paramaters for the Ethereum Goerli Testnet:
        // LINK Token Address
        link = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        // 0.1 LINK
        fee = 0.1 * 10 ** 18;
        // Google Weather Oracle Address
        oracle = 0x292D4Cc76c00D9682230fC712F6B1419eF88aC9b;
        // Average Temperature jobId
        jobId = 0x3137383932643664373132343463633038356463313634353861633633636437;
        // GeoJson for Tunis converted to a string
        tunis_geoJson = "{\"type\":\"FeatureCollection\",\"features\":[{\"type\":\"Feature\",\"properties\":{},\"geometry\":{\"coordinates\":[10.182577566706385,36.80262629471457],\"type\":\"Point\"}}]}";

        // This configures the Chainlink Client:
        setChainlinkToken(link);
        setChainlinkOracle(oracle);
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
            requestAvgTemp();
        } else {
            console.log("UPKEEP INTERVAL IS STILL NOT UP!");
            return;
        }
    }

    function requestAvgTemp() private {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillAvgTemp.selector
        );
        req.add("geoJson", tunis_geoJson);
        req.add("dateFrom", getDateString(lastTimestamp));
        req.add("dateTo", getDateString(block.timestamp));
        req.add("method", "AVG");
        req.add("column", "temp");
        req.add("units", "metric");
        sendChainlinkRequest(req, fee);
    }
    
    function fulfillAvgTemp(
        bytes32 _requestId,
        uint256 _result
    ) external recordChainlinkFulfillment(_requestId) {
        updateAllTokenUris(_result);
        emit AvgTemp(_result);
    }

    function updateAllTokenUris(uint256 _latestTemperature) internal {
        lastTimestamp = block.timestamp;

        uint emojiIndex;

        if (_latestTemperature < 10 && currentTemperature >= 10) {
            // Set the index to the "pensive-face" emoji.
            emojiIndex = 2;
        } else if (_latestTemperature > 20 && currentTemperature <= 20) {
            // Set the index to the "grinning-squinting-face".
            emojiIndex = 1;
        } else if (currentTemperature > 20 || currentTemperature < 10) {
            // Set the index to the "slightly-smiling-face".
            emojiIndex = 0;
        } else {
            console.log("NOTHING TO UPDATE!");
            currentTemperature = _latestTemperature;
            return;
        }

        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            _setTokenURI(i, emojiUrisIpfs[emojiIndex]);
        }

        currentTemperature = _latestTemperature;
        emit TokensUpdated(emojiIndex);
    } 

    // Utility functions
    function getDateString(uint timestamp) private pure returns (string memory){
        (uint256 _year, uint256 _month, uint256 _day) = DateTime.timestampToDate(timestamp);
        return buildDateString(_year, _month, _day);
    }

    function buildDateString(uint256 _year, uint256 _month, uint256 _day) public pure returns (string memory){
        string memory yearString = Strings.toString(_year);
        string memory monthString = Strings.toString(_month);
        string memory dayString = Strings.toString(_day);

        string memory result = string(abi.encodePacked(yearString, " - ", monthString, " - ", dayString));

        return result;
    } 

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
