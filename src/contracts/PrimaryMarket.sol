// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITicketNFT.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";


contract PrimaryMarket is IPrimaryMarket{
    
    // set the basic information for the primary market
    address private primaryMarket;
    uint256 private ticketPrice;
    uint256 private totalMintedNFTs;
    mapping(ITicketNFT => address) private creatorOfEvent;
    PurchaseToken public purchaseToken;
    ITicketNFT public ticketNFTContract;
    uint256 maxNumber;
    string eventN;
    address public currentTicketNFT;

    constructor(PurchaseToken purchaseTokenContractAddress){
        purchaseToken = purchaseTokenContractAddress;
        primaryMarket = msg.sender;
        totalMintedNFTs = 0;
       
    }

    // create a new event for ticketcollection 
    function createNewEvent( string memory eventName, uint256 price, uint256 maxNumberOfTickets) external returns (ITicketNFT ticketCollection)
    {
        maxNumber=maxNumberOfTickets;

        eventN = eventName;
        // initialize the ticketNFTContract
        ticketNFTContract = new TicketNFT(maxNumber, eventN,msg.sender,address(this));

        creatorOfEvent[ticketNFTContract] = msg.sender;
        ticketPrice = price;

        totalMintedNFTs = 0;
        emit EventCreated(msg.sender,address(ticketNFTContract), eventName, price, maxNumberOfTickets);
        return ticketNFTContract;
    }

    // purchase the ticket in the specified ticketcollection
    function purchase( address ticketCollection, string memory holderName) external returns (uint256 id){
        // ensure the balance is enough 
        require(purchaseToken.balanceOf(msg.sender) >= ticketPrice, "You do not have enough purchaseToken");
        
        require(purchaseToken.allowance(msg.sender, address(this)) >= ticketPrice, "You do not provide enough purchaseToken for primaryMarket");
       
        require(totalMintedNFTs < maxNumber, "All tickets have been sold");
       
        purchaseToken.transferFrom(msg.sender,creatorOfEvent[ticketNFTContract], ticketPrice);
        totalMintedNFTs++;
       
        id = ticketNFTContract.mint(msg.sender, holderName);
        emit Purchase(msg.sender, address(ticketCollection),id,holderName);
        return id;
    }

    // get the price of the ticket collection
    function getPrice(address ticketCollection) external view returns (uint256 price){

        require(address(ticketNFTContract) == ticketCollection,"Invalid ticketCollection address");
        return ticketPrice;
    }
    
}
