// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "../interfaces/ITicketNFT.sol";

contract TicketNFT is ITicketNFT {
    uint256 private ticketID;
    
    uint256 public maxNumberTickets;
    string public nameEvent;


    // The basic information about one ticket 
    mapping(uint256 => address) private holderOfTicket;
    mapping(uint256 => uint256) private expiryTimestamp;
    mapping(uint256 => bool) private ticketUsed;
    mapping(uint256 => address) private callingOperator;
    mapping(uint256 => string) private nameOfHolder;
    mapping(address => uint256) private balanceOfHolder;
    mapping(address => address) private ticketNFTContract;

    address private creat;
    address private _primaryMarket;
  
    constructor(uint maxNum, string memory name,address sender,address primaryMarket) {
        creat = sender;
        ticketID = 0;
        maxNumberTickets = maxNum;
        nameEvent =name;
        _primaryMarket =primaryMarket;
    }

    // return the creator of the ticket collection
    function creator() external view override returns (address) {

        return creat;
    }

    // return the maximum number of tickets in the event
    function maxNumberOfTickets() external view override returns (uint256) {
        return maxNumberTickets;
    }

    // return the name of the event
    function eventName() external view override returns (string memory) {
        return nameEvent;
     }

    // mint the ticket
    function mint(address holder, string memory holderName) external override returns (uint256 id)
    {
        // only the primary market can mint the ticket
        require(msg.sender == _primaryMarket, "Only primary market can mint");
        
        ticketID++;
        holderOfTicket[ticketID] = holder;
        nameOfHolder[ticketID] = holderName;
        expiryTimestamp[ticketID] = block.timestamp + 10 days;
        ticketUsed[ticketID] = false;
        /* The address is set to zero after the transfer to ensure that 
        any authorization to the NFT is cleared after the transfer is complete.
        */ 
        callingOperator[ticketID] = address(0);
        balanceOfHolder[holder]++;
        
        emit Transfer(address(0), holder, ticketID);
        return ticketID;
    }

    // Returns the number of tickets a `holder` has.
    function balanceOf(address holder) external view override returns (uint256 balance) {
        return balanceOfHolder[holder];
    }

    // Returns the address of the holder of the `ticketID` ticket.
    function holderOf(uint256 _ticketID) external view override returns (address holder) {
        // ensure the ticket is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        require(ticketID <= maxNumberTickets, "Ticket does not exist");
        return holderOfTicket[_ticketID];
    }

    // transfer the ticket address
    function transferFrom(address from, address to, uint256 _ticketID) external override
    {   // ensure the the address is valid
        require(from != address(0), "Invalid 'from' address");
        require(to != address(0), "Invalid 'to' address");
        // ensure only the approve operator or holder of the ticket can use this function
        require(holderOfTicket[_ticketID] == msg.sender || callingOperator[_ticketID] == msg.sender, "You are not the holder of this ticket or you are not authorised to transfer it");

        holderOfTicket[_ticketID] = to;
        balanceOfHolder[from]--;
        balanceOfHolder[to]++;
        callingOperator[_ticketID] = address(0);
        emit Transfer(from, to, _ticketID);
        
        emit Approval(to, address(0), _ticketID);
    }
    // approve the ticket to trnasfer to to address
    function approve(address to, uint256 _ticketID) external override {
        // ensure the the ticketID is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        // ensure the operator is the holder
        require(holderOfTicket[_ticketID] == msg.sender, "You are not the holder of this ticket");
        callingOperator[_ticketID] = to;
        emit Approval(msg.sender, to, _ticketID);
    }

    // get approvement for the ticketID
    function getApproved(uint256 _ticketID) external view override returns (address operator) {
        // ensure the ticketID is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        return callingOperator[_ticketID];
    }

    // get the holder name of the ticket
    function holderNameOf(uint256 _ticketID) external view override returns (string memory holderName) {
        // ensure the ticketID is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        return nameOfHolder[_ticketID];
    }

    // update the holder name
    function updateHolderName(uint256 _ticketID, string calldata newName) external override{
        // ensure the ticketID is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        require(holderOfTicket[_ticketID] == msg.sender, "You are not the holder of this ticket");
        nameOfHolder[_ticketID] = newName;
    }

    // set the ticket as used 
    function setUsed(uint256 _ticketID) external override{
        // ensure the ticketID is valid and check the expiry time, using situation and the caller
        require(msg.sender == creat, "Only primary market can set ticket as used");
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        require(ticketUsed[_ticketID] == false,"Ticket already used");
        require(block.timestamp <= expiryTimestamp[_ticketID],"Ticket expired");
        ticketUsed[_ticketID] = true;
    }

    // judge whether the ticket is used or expired or not
    function isExpiredOrUsed(uint256 _ticketID) external view returns (bool){
        // ensure the ticketID is valid
        require(holderOfTicket[_ticketID] != address(0), "Invalid ticketID");
        return(block.timestamp > expiryTimestamp[_ticketID] || ticketUsed[_ticketID] == true);

    }


}
