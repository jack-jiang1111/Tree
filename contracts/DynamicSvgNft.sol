// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
// The new-version of "@openzeppelin/contracts": "^5.0.1", already has Base64.sol
// You can import it like as shown just below...
import "@openzeppelin/contracts/utils/Base64.sol";   // 👈 comment in this import
import "hardhat/console.sol";

error ERC721Metadata__URI_QueryFor_NonExistentToken();

contract TreeSvgNft is ERC721, Ownable {
    // Define the Status of the tree
    enum Status { Seed, Flower, Tree }
    
    // Define Rare Levels
    enum RareLevel { Normal, Rare, SuperRare, SuperSuperRare }

    struct Tree {
        Status status;       // Status: Seed, Flower, Tree
        RareLevel rareLevel; // Rarity level
        uint8 growLevel;     // Grow Level: 1 to 15
        uint256 lastWatered; // Timestamp when last watered
        uint256 mintTime;    // Timestamp when NFT was minted
        string img_url;
    }
    uint256 private s_tokenCounter;
    // Need image url for (n,r,sr,ssr)*(seed,flower,tree)
    string private N_ImageURI;
    string private s_highImageURI;

    address public treeToken; // erc20 Address
    address public stakingPool; // these are two address that built in constrcutor, will trasfer the erc20 token in this contract once it reaches a certain level
    address public EcotourPool; 
    uint256 public mintPrice; // how many erc20 it takes to mint one nft
    uint256 public fertilizerPrice; // how many tree token it takes to ferilize
    uint256 public waterPeriod = 7 days;

    mapping(uint256 => Tree) public treeAttributes;

    event CreatedNFT(uint256 indexed tokenId, int256 highValue);

    constructor(
        address priceFeedAddress,
        string memory lowSvg,
        string memory highSvg
    ) ERC721("Tree NFT", "DSN") {
        s_tokenCounter = 0;
        i_priceFeed = AggregatorV3Interface(priceFeedAddress);
        // setLowSVG(lowSvg);
        // setHighSVG(highSvg);
        s_lowImageURI = svgToImageURI(lowSvg);
        s_highImageURI = svgToImageURI(highSvg);
    }


    function mintNft(int256 highValue) public {
        // User must spend Tree token to fertilize
        require(treeToken.transferFrom(msg.sender, address(this), mintPrice * 10**18), "TreeNFT: Transfer failed");
        uint256 tokenId = nextTokenId;
        _safeMint(msg.sender, tokenId);

        // Initialize the tree's attributes
        treeAttributes[tokenId] = Tree({
            status: Status.Seed,
            rareLevel: getRareLevel(RareLevel.Normal,Status.Seed);
            growLevel: 1, // Start from level 1
            lastWatered: block.timestamp,
            mintTime: block.timestamp
            img_url://
        });

        nextTokenId++;
        emit CreatedNFT(newTokenId, highValue);
    }

    // Function to water the tree daily
    function waterTree(uint256 tokenId) public {
        require(_exists(tokenId), "TreeNFT: Token does not exist");
        Tree storage tree = treeAttributes[tokenId];

        // Check if the tree was watered in the past 24 hours
        require(block.timestamp >= tree.lastWatered + 1 days, "TreeNFT: Tree already watered today");
        require(tree.status!= Status.Tree, "No need water anymore")

        // Water the tree
        tree.lastWatered = block.timestamp;

        // Grow the tree if it can grow further
        if (tree.growLevel < getMaxGrowLevel(tree.status)) {
            tree.growLevel++;
        } else {
            // If growLevel hits max, evolve to the next status
            evolveTree(tokenId);
        }
    }

    // Function to evolve the tree when growLevel is maxed out
    function evolveTree(uint256 tokenId) internal {
        Tree storage tree = treeAttributes[tokenId];
        require(tree.status!=Status.Tree,"can't evolve fully growed tree");

        // Evolve from Seed -> Flower -> Tree
        if (tree.status == Status.Seed) {
            tree.status = Status.Flower;
            tree.growLevel = 1;  // Reset growLevel for Flower
        } else if (tree.status == Status.Flower) {
            tree.status = Status.Tree;
            tree.growLevel = 1;  // Reset growLevel for Tree
        }

        // Improve rarity after evolving
        improveRarity(tree);
    }

    // Function to randomly improve the rarity
    function improveRarity(Tree storage tree) internal {
        // Randomly improve rarity using pseudo-random logic (for demonstration purposes), will use chainlink vrf further
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100;
        RareLevel newLevel = getRareLevel(tree.rareLevel,tree.status);
        tree.rareLevel = newLevel;
        // TODO: change url based on rarity
    }

    // use chainlink vrf to get rarelevel
    function getRareLevel(RareLevel level,Status current status) internal returns(RareLevel){

    }
    // Function to fertilize the tree by spending ERC20 tokens
    function fertilizeTree(uint256 tokenId) public {
        require(_exists(tokenId), "TreeNFT: Token does not exist");
        Tree storage tree = treeAttributes[tokenId];
        require(tree.status!=Status.Tree,"can't fertilize tree");
        

        // User must spend Tree token to fertilize
        require(treeToken.transferFrom(msg.sender, address(this), fertilizerPrice * 10**18), "TreeNFT: Transfer failed");

        tree.growLevel++;
        // Increase growLevel by 1
        if (tree.growLevel == getMaxGrowLevel(tree.status)) {
            // If growLevel hits max, evolve to the next status
            evolveTree(tokenId);
        }
    }

    // You could also just upload the raw SVG and let solildity convert it!
    function svgToImageURI(string memory svg) public pure returns (string memory) {
        // example:
        // '<svg width="500" height="500" viewBox="0 0 285 350" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill="black" d="M150,0,L75,200,L225,200,Z"></path></svg>'
        // would return ""
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL, svgBase64Encoded));
    }

    function _baseURI() internal pure override returns (string memory) {
        return "data:application/json;base64,";
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) {
            revert ERC721Metadata__URI_QueryFor_NonExistentToken();
        }
        string memory imageURI = treeAttributes[tokenId].img_url;
        return
            string(
                abi.encodePacked(
                    _baseURI(),
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name(), // You can add whatever name here
                                '", "description":"An NFT that changes based on the Chainlink Feed", ',
                                '"attributes": [{"trait_type": "coolness", "value": 100}], "image":"',
                                imageURI,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function getTokenCounter() public view returns (uint256) {
        return s_tokenCounter;
    }

    // Helper function to get the max grow level based on the current status
    function getMaxGrowLevel(Status status) public pure returns (uint8) {
        if (status == Status.Seed) {
            return 15;  // Max grow level for Seed is 15 (to become a Flower)
        } else if (status == Status.Flower) {
            return 7;   // Max grow level for Flower is 7 (to become a Tree)
        } else {
            return 0;   // Tree is fully grown, no more levels
        }
    }

    // Function to view the tree's attributes
    function getTreeAttributes(uint256 tokenId) public view returns (
        Status, 
        bool, 
        RareLevel, 
        uint8, 
        uint256, 
        uint256
    ) {
        require(_exists(tokenId), "TreeNFT: Token does not exist");
        Tree memory tree = treeAttributes[tokenId];
        return (
            tree.status,
            tree.watered,
            tree.rareLevel,
            tree.growLevel,
            tree.lastWatered,
            tree.mintTime
        );
    }
    // TODO:
    /*
        1. chainlink vrf to randomize
        2. image url initialize
        3. mint
        // TODO: change url based on rarity
    */
}