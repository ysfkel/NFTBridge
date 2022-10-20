// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title BridgeNFT
/// @notice Mints transfered NFT at the destination chain. 
/// @dev This NFT will be minted and transfered to the users walet after ensuring it has been locked in the source chain BridgeCustodial contract
/// only the owner can mint nfts
/// bridge mint functions can mint arbitrary nft ids rather than e.g an acsending order , since nfts being minted already exist on a source chain
contract BridgeNFT is ERC721Enumerable, Ownable{
   
   using Strings for uint256;
   string public baseURI;
   string public baseExtension = ".json";
   uint256 public maxSupply = 1000; // maxsupply should be same as source nft
   bool public paused = false;

   constructor() ERC721("Net2Dev NFT Collection", "N2D") {
        
   } 

   function _baseURI() internal view virtual override returns(string memory) {
      return "ipfs://QmYB5uWZqfunBq7yWnamTqoXWBAHiQoirNLmuxMzDThHhi/";
   }

   function bridgeMint(address to, uint256 tokenId) external virtual onlyOwner() {
     _mint(to, tokenId);
   }

   /// @notice returns specified address nft ids
   function walletOfOwner(address _owner) external view returns(uint256[] memory) {
      uint256 ownerTokenCount = balanceOf(_owner);
      uint256[] memory tokenIds = new uint256[](ownerTokenCount);
      for(uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
      }

      return tokenIds;
   }

   function tokenURI(uint256 tokenId) 
   public 
   view 
   virtual 
   override
   returns (string memory) {
    require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
      );

      string memory currentBaseURI = _baseURI();
      return bytes(currentBaseURI).length > 0
      ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
      : "";
   }

   function setBaseURI(string memory _newBaseURI) external onlyOwner() {
       baseURI = _newBaseURI;
   }

    function setBaseExtension(string memory _newBaseExtension) external onlyOwner() {
            baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner() {
        paused = _state;
    }


}