// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";


contract PrimaryMarket is IPrimaryMarket{
    
    address private primaryMarket;
    uint256 private ticketPrice;
    uint256 private totalMintedNFTs;
    IERC20 public purchaseTokenContract;

    ITicketNFT public ticketNFTContract;
    uint256 maxNumber;
    string eventN;

    constructor(address purchaseTokenContractAddress){
        purchaseTokenContract = IERC20(purchaseTokenContractAddress);
        
        primaryMarket = msg.sender;
        
        totalMintedNFTs = 0;
       
    }

  
    function createNewEvent( string memory eventName, uint256 price, uint256 maxNumberOfTickets) external returns (ITicketNFT ticketCollection)
    {
        maxNumber=maxNumberOfTickets;
        eventN = eventName;
        ticketNFTContract = new TicketNFT(maxNumber, eventN);
        ticketPrice = price;
        emit EventCreated(msg.sender, address(ticketNFTContract), eventName, price, maxNumberOfTickets);
        return ticketNFTContract;
    }

   
    function purchase( address ticketCollection, string memory holderName) external returns (uint256 id){
         // check if msg.sender has enough purchaseToken
        require(purchaseTokenContract.balanceOf(msg.sender) >= ticketPrice, "You do not have enough purchaseToken to purchase a ticket");
        // check if msg.sender has approved primaryMarket to spend purchaseToken
        require(purchaseTokenContract.allowance(msg.sender, address(this)) >= ticketPrice, "You have not approved primaryMarket to spend your purchaseToken");
        // check total number of issued tickets to be less than 1000
        require(totalMintedNFTs < maxNumber, "All tickets have been sold");
        // transfers funds to Primary Market owner from msg.sender 
        purchaseTokenContract.transferFrom(msg.sender, primaryMarket, ticketPrice);
        totalMintedNFTs++;
        // mints ticketNFT to msg.sender
        id = ticketNFTContract.mint(msg.sender, holderName);
        emit Purchase(msg.sender, address(ticketCollection),id,holderName);
        return id;
    }

   
    function getPrice(address ticketCollection) external view returns (uint256 price){

        require(address(ticketNFTContract) == ticketCollection,"Invalid ticketCollection address");
        return ticketPrice;
    }
}
