// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/ISecondaryMarket.sol";
import "../interfaces/IPrimaryMarket.sol";
import "../interfaces/ITicketNFT.sol";
import "../interfaces/IERC20.sol";
import "./TicketNFT.sol";
import "./PurchaseToken.sol";
import "./PrimaryMarket.sol";

contract SecondaryMarket is ISecondaryMarket {
    
    mapping(uint256 => address) private bidderList;
    mapping(uint256 => uint256) private priceList;
    mapping(uint256 => bool) private listedList;
    mapping(uint256 => string) private nameList;
    mapping(uint256 => address) private ownerList;
    
    PrimaryMarket public primaryMarketContract;
    TicketNFT public ticketNFTContract;
    PurchaseToken public purchaseToken;


   constructor(PurchaseToken _purchaseToken) {
        purchaseToken = _purchaseToken;
    }

    // List the ticket for saling
    function listTicket(address ticketCollection, uint256 ticketID, uint256 price) external{
        ticketNFTContract =TicketNFT(ticketCollection);
        // check the holder and expiry time of the ticket
        require(ticketNFTContract.holderOf(ticketID) == msg.sender, "You do not own this ticket");
        require(ticketNFTContract.isExpiredOrUsed(ticketID) == false, "Ticket is expired or used");
        
        // Transfer ticketNFT to this contract
        ticketNFTContract.transferFrom(msg.sender, address(this), ticketID);
        
        // List ticketNFT
        bidderList[ticketID] = address(0);
        priceList[ticketID] = price;
        listedList[ticketID] = true;
        ownerList[ticketID] = msg.sender;
        
        emit Listing(msg.sender,address(ticketCollection), ticketID, price);
    }

    // submit the bid for the ticket
    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string calldata name) external override {
        // Ensure that the sender is the lister of the ticket
        require(listedList[ticketID], "Ticket is not listed");

        require(bidAmount > priceList[ticketID], "Bid amount must be higher than current price");
        require(!ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        
        // Transfer the bid amount to this contract
        purchaseToken.transferFrom(msg.sender, address(this), bidAmount);
        
        // If there is a previous highest bidder, return funds to them
        if (bidderList[ticketID] != address(0)) {
            purchaseToken.transfer(bidderList[ticketID], priceList[ticketID]);
        }

        // Update bid information
        priceList[ticketID] = bidAmount;
        bidderList[ticketID] = msg.sender;
        nameList[ticketID] =name;
        
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);

    }

    // get the highest bid price
    function getHighestBid(address ticketCollection, uint256 ticketID) external view override returns (uint256) {
        TicketNFT _ticketNFTContract =TicketNFT(ticketCollection);
        // Ensure that the sender is the lister of the ticket
        require(listedList[ticketID], "Ticket is not listed");
        require(!_ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        return priceList[ticketID];
    }

    // get the bidder name who has the highest bid price
    function getHighestBidder(address ticketCollection, uint256 ticketID) external view override returns (address) {
        TicketNFT _ticketNFTContract =TicketNFT(ticketCollection);
        // Ensure that the sender is the lister of the ticket
        require(listedList[ticketID], "Ticket is not listed");
        require(!_ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        return bidderList[ticketID];
    }

    // accept the bid 
    function acceptBid(address ticketCollection, uint256 ticketID) external override {
        TicketNFT _ticketNFTContract =TicketNFT(ticketCollection);
        address bidder;
        uint256 bidAmount;
        require(!_ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        // Ensure that the ticket is listed
        require(listedList[ticketID], "Ticket is not listed");

        // Ensure that there is a bid to accept
        require(priceList[ticketID] > 0, "No bid to accept");

        // Transfer the ticket to the highest bidder
        bidder = bidderList[ticketID];
        bidAmount =priceList[ticketID];
        purchaseToken.balanceOf(bidder);
        purchaseToken.balanceOf(address(this));
        uint fee = (priceList[ticketID] *  0.05e18) / 1e18;
        purchaseToken.transfer(msg.sender, priceList[ticketID]-fee);
        purchaseToken.transfer(_ticketNFTContract.creator(), fee);
        _ticketNFTContract.updateHolderName(ticketID, nameList[ticketID]);
        _ticketNFTContract.transferFrom(address(this),bidder,ticketID);
        ownerList[ticketID] = bidder;

        // Reset listing information
        bidderList[ticketID] = address(0);
        priceList[ticketID] = 0;
        listedList[ticketID] = false;
        nameList[ticketID] ="";
        
        emit BidAccepted(bidder, ticketCollection, ticketID, bidAmount, ticketNFTContract.holderNameOf(ticketID));
    }

    // The account that listed the ticket may delist the ticket.
    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        
        // Ensure that the sender is the lister of the ticket
        require(msg.sender == ownerList[ticketID], "You are not the lister of this ticket");

        ticketNFTContract.transferFrom(address(this), msg.sender, ticketID);

        // Return funds to the highest bidder, if any
        if (bidderList[ticketID] != address(0)) {
            purchaseToken.transfer(bidderList[ticketID], priceList[ticketID]);
        }

        // Reset the ticket listing information
        priceList[ticketID] = 0;
        bidderList[ticketID] = address(0);
        listedList[ticketID] = false;
        nameList[ticketID] ="";

        emit Delisting(ticketCollection, ticketID);
    }

}
