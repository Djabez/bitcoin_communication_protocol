// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../src/contracts/PurchaseToken.sol";
import "../src/interfaces/ITicketNFT.sol";
import "../src/contracts/PrimaryMarket.sol";
import "../src/contracts/SecondaryMarket.sol";

contract EndToEnd is Test {
    PrimaryMarket public primaryMarket;
    PurchaseToken public purchaseToken;
    SecondaryMarket public secondaryMarket;

    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");

    function setUp() public {
        purchaseToken = new PurchaseToken();
        primaryMarket = new PrimaryMarket(purchaseToken);
        secondaryMarket = new SecondaryMarket(purchaseToken);

        payable(alice).transfer(1e18);
        payable(bob).transfer(2e18);
    }

    function testEndToEnd() external {
        uint256 ticketPrice = 20e18;

        vm.prank(charlie);
        ITicketNFT ticketNFT = primaryMarket.createNewEvent(
            "Charlie's concert",
            ticketPrice,
            100
        );
       
        assertEq(ticketNFT.creator(), charlie);
        assertEq(ticketNFT.maxNumberOfTickets(), 100);
        assertEq(primaryMarket.getPrice(address(ticketNFT)), ticketPrice);
        
        vm.startPrank(alice);
        purchaseToken.mint{value: 1e18}();
        assertEq(purchaseToken.balanceOf(alice), 100e18);

        purchaseToken.approve(address(primaryMarket), 100e18);
        uint256 id = primaryMarket.purchase(address(ticketNFT), "Alice");
        assertEq(ticketNFT.balanceOf(alice), 1);
        assertEq(ticketNFT.holderOf(id), alice);
        assertEq(ticketNFT.isExpiredOrUsed(id),false);
        
        vm.stopPrank();
        vm.startPrank(charlie);
        ticketNFT.setUsed(id);
        assertEq(ticketNFT.isExpiredOrUsed(id),true);
    
    }
}

