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
    
    mapping(uint256 => address) private ticketListOriginator;
    mapping(uint256 => uint256) private ticketListPrice;
    mapping(uint256 => bool) private ticketListListed;

    IPrimaryMarket public primaryMarketContract;
    IERC20 public purchaseTokenContract;
    ITicketNFT public ticketNFTContract;

   constructor(address _purchaseTokenAddress, address _primaryMarketAddress, address _ticketNFTAddress) {
        purchaseTokenContract = IERC20(_purchaseTokenAddress);
        ticketNFTContract = ITicketNFT(_ticketNFTAddress);
        primaryMarketContract = IPrimaryMarket(_primaryMarketAddress);
    }

  

    function listTicket(address ticketCollection, uint256 ticketID, uint256 price) external{
        require(ticketNFTContract.holderOf(ticketID) == msg.sender, "You do not own this ticket");
        require(ticketNFTContract.isExpiredOrUsed(ticketID) == false, "Ticket is expired or used");
        // Transfer ticketNFT to this contract
        ticketNFTContract.transferFrom(msg.sender, address(this), ticketID);
        // List ticketNFT
        ticketListOriginator[ticketID] = msg.sender;
        ticketListPrice[ticketID] = price;
        ticketListListed[ticketID] = true;
        // emit event
        emit Listing(msg.sender,address(ticketCollection), ticketID, price);
    }

    // function submitBid( address ticketCollection, uint256 ticketID, uint256 bidAmount,string calldata name) external{
    //     require(ticketListListed[ticketID]==true, "Ticket is not listed");
    //     require(ticketNFTContract.isExpiredOrUsed(ticketID) == false, "Ticket is expired or used");
    //     require(bidAmount > ticketListPrice[ticketID],"Bid must be higher than the current highest bid");
    //     // Transfer the bid amount to this contract
    //     purchaseTokenContract.transferFrom(msg.sender, address(this), bidAmount);

    //     // Update bid information
    //     ticketListPrice[ticketID] = bidAmount;

    //     // if (msg.sender != address(0)) {

    //     //     ITicketNFT(ticketCollection).transferFrom(
    //     //         address(this),
    //     //         msg.sender,
    //     //         ticketID
    //     //     );
    //     // }

    //     // // Escrow the bid amount
    //     // ITicketNFT(ticketCollection).transferFrom(msg.sender, address(this), ticketID);

    //     // ticketListPrice[ticketID] = bidAmount;
    //     // ticketListOriginator[ticketID] = msg.sender;
    //     // ticketNFTContract.updateHolderName(ticketID,name);
        
    //     // emit BidSubmitted(
    //     //     msg.sender,
    //     //     ticketCollection,
    //     //     ticketID,
    //     //     bidAmount,
    //     //     name
    //     // );

    // }


    function submitBid(address ticketCollection, uint256 ticketID, uint256 bidAmount, string calldata name) external override {
        // Ensure that the ticket is listed
        require(ticketListListed[ticketID], "Ticket is not listed");

        // Ensure that the bid amount is higher than the current highest bid
        require(bidAmount > ticketListPrice[ticketID], "Bid amount must be higher than current price");

        // Ensure that the ticket is non-expired and unused
        require(!ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        // Transfer the bid amount to this contract
        purchaseTokenContract.transferFrom(msg.sender, address(this), bidAmount);
      
        // If there is a previous highest bidder, return funds to them
        if (ticketListOriginator[ticketID] != address(0)) {
            purchaseTokenContract.transfer(ticketListOriginator[ticketID], ticketListPrice[ticketID]);
        }

        // Update bid information
        ticketListPrice[ticketID] = bidAmount;
        ticketListOriginator[ticketID] = msg.sender;
        ticketNFTContract.updateHolderName(ticketID, name);

        // Emit the BidSubmitted event
        emit BidSubmitted(msg.sender, ticketCollection, ticketID, bidAmount, name);

    }

    function getHighestBid(address ticketCollection, uint256 ticketID) external view override returns (uint256) {
        require(ticketListListed[ticketID], "Ticket is not listed");
        require(!ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");

        return ticketListPrice[ticketID];
    }

    function getHighestBidder(address ticketCollection, uint256 ticketID) external view override returns (address) {
        require(ticketListListed[ticketID], "Ticket is not listed");
        require(!ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        return ticketListOriginator[ticketID];
    }

    function acceptBid(address ticketCollection, uint256 ticketID) external override {
 
        require(!ticketNFTContract.isExpiredOrUsed(ticketID), "Ticket is expired or used");
        // Ensure that the ticket is listed
        require(ticketListListed[ticketID], "Ticket is not listed");

        // Ensure that there is a bid to accept
        require(ticketListPrice[ticketID] > 0, "No bid to accept");

        // Transfer the bid amount to the ticket lister
        purchaseTokenContract.transfer(ticketListOriginator[ticketID], ticketListPrice[ticketID]);

        // Transfer the ticket to the highest bidder
        ticketNFTContract.transferFrom(address(this), msg.sender, ticketID);

        // Reset listing information
        ticketListOriginator[ticketID] = address(0);
        ticketListPrice[ticketID] = 0;
        ticketListListed[ticketID] = false;

        emit BidAccepted(msg.sender, ticketCollection, ticketID, ticketListPrice[ticketID], ticketNFTContract.holderNameOf(ticketID));
    }

   // This method delists a previously listed ticket with `ticketID`
    function delistTicket(address ticketCollection, uint256 ticketID) external override {
        // Ensure that the sender is the lister of the ticket
        require(msg.sender == ticketListOriginator[ticketID], "You are not the lister of this ticket");

        // Transfer the ticket back to the lister
        ticketNFTContract.transferFrom(address(this), msg.sender, ticketID);

        // Return funds to the highest bidder, if any
        if (ticketListOriginator[ticketID] != address(0)) {
            purchaseTokenContract.transfer(ticketListOriginator[ticketID], ticketListPrice[ticketID]);
        }

        // Reset the ticket listing information
        ticketListPrice[ticketID] = 0;
        ticketListOriginator[ticketID] = address(0);
        ticketListListed[ticketID] = false;

        // Emit the Delisting event
        emit Delisting(ticketCollection, ticketID);
    }



 
    // function getHighestBid( address ticketCollection, uint256 ticketId) external view returns (uint256){
        
    //     return ticketListPrice[ticketId];

    // }


    // function getHighestBidder(
    //     address ticketCollection,
    //     uint256 ticketId
    // ) external view returns (address);

    
    // function acceptBid(address ticketCollection, uint256 ticketID) external;


    // function delistTicket(address ticketCollection, uint256 ticketID) external;







   

   

    // function getHighestBid(address ticketCollection, uint256 ticketID)
    //     external
    //     view
    //     override
    //     onlyListedTicket(ticketCollection, ticketID)
    //     returns (uint256)
    // {
    //     return ticketListings[ticketCollection][ticketID].highestBid;
    // }

    // function getHighestBidder(address ticketCollection, uint256 ticketID)
    //     external
    //     view
    //     override
    //     onlyListedTicket(ticketCollection, ticketID)
    //     returns (address)
    // {
    //     return ticketListings[ticketCollection][ticketID].highestBidder;
    // }

    // function acceptBid(address ticketCollection, uint256 ticketID)
    //     external
    //     override
    //     onlyListedTicket(ticketCollection, ticketID)
    // {
    //     TicketListing storage listing = ticketListings[ticketCollection][ticketID];

    //     uint256 fee = (listing.highestBid * bidFeePercentage) / 100;
    //     uint256 amountAfterFee = listing.highestBid - fee;

    //     ITicketNFT(ticketCollection).transferFrom(
    //         address(this),
    //         listing.highestBidder,
    //         ticketID
    //     );

    //     ITicketNFT(ticketCollection).transferFrom(
    //         address(this),
    //         primaryMarket,
    //         ticketID
    //     );

    //     listing.isListed = false;

    //     emit BidAccepted(
    //         listing.highestBidder,
    //         ticketCollection,
    //         ticketID,
    //         listing.highestBid,
    //         listing.holderName
    //     );
    // }

   



}
