//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title BridgeCustodial
/// @notice Custodial vault for transfering nft between source chain and destination chain
/// @dev deployed on all chains where the nft is to be transfered
contract BridgeCustodial is IERC721Receiver, ReentrancyGuard, Ownable {

    uint256 public costCustom = 1 ether;
    uint256 public costNative = 0.000075 ether;

    struct TokenIdentity {
        uint256 tokenId;
        address owner; // owner
    }

    mapping(uint256 => TokenIdentity) public holdCustody;

    event NftLocked (
        uint256 indexed tokenId,
        address owner 
    );

    event OwnerUpdated(
        uint256 indexed tokenId,
        address owner 
    );
 
    IERC721Enumerable nft; 
    IERC20 paytoken;

    constructor(IERC721Enumerable _nft, IERC20 _paytoken) {
        nft = _nft;
        paytoken = _paytoken;
    }

    
    /// @notice locks nft in source chain using custom token for payment processing
    function lockNFTC(uint256 tokenId) public nonReentrant {
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(holdCustody[tokenId].tokenId == 0, "NFT already locked");
        paytoken.transferFrom(msg.sender, address(this), costCustom); // pay processing fee 

        holdCustody[tokenId] = TokenIdentity({
            tokenId: tokenId,
            owner: msg.sender
        });

        nft.transferFrom(msg.sender, address(this), tokenId);

        emit NftLocked(tokenId, msg.sender);
    }

    /// @notice locks nft in source chain using native currency for payment processing
    function lockNFTN(uint256 tokenId) public payable nonReentrant {
        require(msg.value == costNative, "not enough processing fee to complete transaction");
        require(nft.ownerOf(tokenId) == msg.sender, "Not NFT owner");
        require(holdCustody[tokenId].tokenId == 0, "NFT already locked");
 
        holdCustody[tokenId] = TokenIdentity({
            tokenId: tokenId,
            owner: msg.sender
        });

        nft.transferFrom(msg.sender, address(this), tokenId);

        emit NftLocked(tokenId, msg.sender);
    } 

    function updateOwner(uint256 tokenId, address newOwner) public nonReentrant onlyOwner() {
        holdCustody[tokenId] = TokenIdentity(tokenId, newOwner);
        emit OwnerUpdated(tokenId, newOwner);
    }

    /// @notice releases the nft in destination chain - called at the destination
    function releaseNFT(uint256 tokenId, address wallet) public nonReentrant onlyOwner() {
          nft.transferFrom(address(this), wallet, tokenId);
          delete holdCustody[tokenId];
    }

    /// @notice called if someone transfer NFT without calling lockNFTN or lockNFTC
    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns(bytes4) {
        require(from == address(0x0), "Cannot Receive NFTs Directly");
        return IERC721Receiver.onERC721Received.selector;
    }
    
    /// @notice withdraws processing fees
    function withdrawCustom() public payable onlyOwner() {
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }

    /// @notice withdraws processing fees
    function withdrawNative() public payable onlyOwner() {
        require(payable(msg.sender).send(address(this).balance));
    }

}
