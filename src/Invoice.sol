// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Invoice {
    event InvoiceReceived(address from, uint256 amount, string description);
    event InvoiceSent(address to, address from, uint256 amount, string memo);

    function receiveInvoice(string calldata memo) public payable virtual {
        emit InvoiceReceived(msg.sender, msg.value, memo);
    }

    function sendInvoice(
        address recipient,
        uint256 amount,
        string memory memo
    ) public virtual {
        require(
            amount <= address(this).balance,
            "Insufficient balance for invoice"
        );
        (bool sent, ) = recipient.call{value: amount}("");
        require(sent, "Failed to send Ether");
        emit InvoiceSent(recipient, msg.sender, amount, memo);
    }
}
