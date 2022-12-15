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
    string private tunisAccuweatherEndpoint;

    // IPFS URIs for the dynamic nft graphics/metadata.
    string[] emojiUrisIpfs = [
        "https://ipfs.io/ipfs/QmbMNrzU2qRnhRvDHmaChzfA6pq36QswYhzNFoqEWoEaMi?filename=slightly-smiling-face.json",
        "https://ipfs.io/ipfs/QmS3JPCBGtmhK3bsrroUt9c7oatQ4K1FKYwAf4VthdCNzd?filename=grinning-squinting-face.json",
        "https://ipfs.io/ipfs/QmQfXVuX3WCuQSW3n2tWk9gTXXQXrP9kvPY6PM7WZD9qKg?filename=pensive-face.json"
    ];

    event TokensUpdated (uint index);
    event newTemperatureFulfilled(bytes32 indexed requestId, uint256 temperature);

    constructor(uint updateInterval, string memory _tunisAccuweatherEndpoint) ERC721("WeatherNFT", "WTHRNFT") {
        // This sets the keeper update interval:
        interval = updateInterval;
        lastTimestamp = block.timestamp;

        // This sets the paramaters for the Ethereum Goerli Testnet:
        // LINK Token Address
        link = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
        // 0.1 LINK fee
        fee = 0.1 * 10 ** 18;
        // Testnet Oracle Address
        oracle = 0xCC79157eb46F5624204f47AB42b3906cAA40eaB7;
        // GET>uint256 jobId
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        // Endpoint for fetching weather data for Tunis
        // http://dataservice.accuweather.com/currentconditions/v1/321398?apikey=5nmKA42A2WnKdchKvgK4aN5zOqBxWGGn
        tunisAccuweatherEndpoint = _tunisAccuweatherEndpoint;

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
            requestTemperatureData();
        } else {
            console.log("UPKEEP INTERVAL IS STILL NOT UP!");
            return;
        }
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 10 (to remove decimal places from data).
     */
    function requestTemperatureData() public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillTemperatureData.selector
        );

        // Set the URL to perform the GET request on
        req.add("get", tunisAccuweatherEndpoint);

        // Set the path to find the desired data in the API response, where the response format is:
        // [ { "Temperature": { "Metric": { "Value": 26.1 } } } ]
        req.add("path", "0,Temperature,Metric,Value"); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 10 to remove decimals
        req.addInt("times", 10);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillTemperatureData(
        bytes32 _requestId,
        uint256 _temperature
    ) public recordChainlinkFulfillment(_requestId) {
        // Update all the token URIs according to the temperature
        updateAllTokenUris(_temperature);

        emit newTemperatureFulfilled(_requestId, _temperature);
    }

    /**
     * Update all the token URIs according to the latestt temperature
     */
    function updateAllTokenUris(uint256 _temperature) internal {
        lastTimestamp = block.timestamp;

        uint emojiIndex;

        if (_temperature < 100) {
            // Set the index to the "pensive-face" emoji.
            emojiIndex = 2;
        } else if (_temperature > 200) {
            // Set the index to the "grinning-squinting-face" emoji.
            emojiIndex = 1;
        } else {
            // Set the index to the "slightly-smiling-face" emoji.
            emojiIndex = 0;
        }

        // Loop over all tokens and update their URIs
        // with the emoji at the new index
        for (uint i = 0; i < _tokenIdCounter.current(); i++) {
            _setTokenURI(i, emojiUrisIpfs[emojiIndex]);
        }

        emit TokensUpdated(emojiIndex);
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
