// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Invoice.sol";

contract MockInvoice is Invoice {
    // Empty implementation to make the contract concrete
}

contract InvoiceTest is Test {
    MockInvoice public invoice;
    address public user1;
    address payable public contractRecipient;

    event InvoiceReceived(address from, uint256 amount, string description);
    event InvoiceSent(address to, address from, uint256 amount, string memo);

    function setUp() public {
        invoice = new MockInvoice();
        user1 = address(0x1);
        contractRecipient = payable(address(new RecipientContract()));
        vm.deal(address(invoice), 10 ether);
    }

    function testReceiveInvoice() public {
        vm.expectEmit(true, true, false, true);
        emit InvoiceReceived(address(this), 1 ether, "Test Invoice");
        invoice.receiveInvoice{value: 1 ether}("Test Invoice");
    }

    function testSendInvoiceToAddress() public {
        uint256 initialBalance = user1.balance;
        vm.expectEmit(true, true, false, true);
        emit InvoiceSent(user1, address(this), 1 ether, "Payment to User1");
        invoice.sendInvoice(user1, 1 ether, "Payment to User1");
        assertEq(user1.balance, initialBalance + 1 ether);
    }

    function testSendInvoiceToContract() public {
        uint256 initialBalance = contractRecipient.balance;
        vm.expectEmit(true, true, false, true);
        emit InvoiceSent(
            contractRecipient,
            address(this),
            1 ether,
            "Payment to Contract"
        );
        invoice.sendInvoice(contractRecipient, 1 ether, "Payment to Contract");
        assertEq(contractRecipient.balance, initialBalance + 1 ether);
    }

    function testSendInvoiceInsufficientBalance() public {
        vm.expectRevert("Insufficient balance for invoice");
        invoice.sendInvoice(user1, 11 ether, "Too much");
    }

    function testSendInvoiceFailedSend() public {
        ContractThatRejectsEther rejectingContract = new ContractThatRejectsEther();
        vm.expectRevert("Failed to send Ether");
        invoice.sendInvoice(address(rejectingContract), 1 ether, "Should fail");
    }
}

contract RecipientContract {
    receive() external payable {}
}

contract ContractThatRejectsEther {
    receive() external payable {
        revert("I reject Ether");
    }
}
