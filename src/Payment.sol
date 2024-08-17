// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Payment {
    event PaymentReceived(address from, uint256 amount, string description);
    event PaymentSent(address to, address from, uint256 amount, string memo);

    function receivePayment(string calldata memo) public payable virtual {
        emit PaymentReceived(msg.sender, msg.value, memo);
    }

    function sendPayment(
        address recipient,
        uint256 amount,
        string memory memo
    ) public virtual {
        require(
            amount <= address(this).balance,
            "Insufficient balance for payment"
        );
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit PaymentSent(recipient, msg.sender, amount, memo);
    }
}
