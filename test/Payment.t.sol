// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Payment.sol";

contract MockPayment is Payment {
    // Empty implementation to make the contract concrete
}

contract PaymentTest is Test {
    MockPayment public payment;
    address public user1;
    address payable public contractRecipient;

    event PaymentReceived(address from, uint256 amount, string description);
    event PaymentSent(address to, address from, uint256 amount, string memo);

    function setUp() public {
        payment = new MockPayment();
        user1 = address(0x1);
        contractRecipient = payable(address(new RecipientContract()));
        vm.deal(address(payment), 10 ether);
    }

    function testReceivePayment() public {
        vm.expectEmit(true, true, false, true);
        emit PaymentReceived(address(this), 1 ether, "Test Payment");
        payment.receivePayment{value: 1 ether}("Test Payment");
    }

    function testSendPaymentToAddress() public {
        uint256 initialBalance = user1.balance;
        vm.expectEmit(true, true, false, true);
        emit PaymentSent(user1, address(this), 1 ether, "Payment to User1");
        payment.sendPayment(user1, 1 ether, "Payment to User1");
        assertEq(user1.balance, initialBalance + 1 ether);
    }

    function testSendPaymentToContract() public {
        uint256 initialBalance = contractRecipient.balance;
        vm.expectEmit(true, true, false, true);
        emit PaymentSent(
            contractRecipient,
            address(this),
            1 ether,
            "Payment to Contract"
        );
        payment.sendPayment(contractRecipient, 1 ether, "Payment to Contract");
        assertEq(contractRecipient.balance, initialBalance + 1 ether);
    }

    function testSendPaymentInsufficientBalance() public {
        vm.expectRevert("Insufficient balance for payment");
        payment.sendPayment(user1, 11 ether, "Too much");
    }

    function testSendPaymentFailedSend() public {
        ContractThatRejectsEther rejectingContract = new ContractThatRejectsEther();
        vm.expectRevert("Failed to send Ether");
        payment.sendPayment(address(rejectingContract), 1 ether, "Should fail");
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
