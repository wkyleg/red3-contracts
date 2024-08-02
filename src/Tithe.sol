// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Tithe {
    address public beneficiary;
    uint256 public tithePercentage;

    event TithePaid(address to, uint256 amount);
    event TitheUpdated(address indexed newBeneficiary, uint256 newPercentage);

    constructor(address _beneficiary, uint256 _percentage) {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        beneficiary = _beneficiary;
        tithePercentage = _percentage;
    }

    function setTithe(
        address _beneficiary,
        uint256 _percentage
    ) public virtual {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_percentage <= 100, "Percentage must be between 0 and 100");
        beneficiary = _beneficiary;
        tithePercentage = _percentage;
        emit TitheUpdated(_beneficiary, _percentage);
    }

    function payTithe() public payable {
        require(msg.value > 0, "Must send some ETH to pay tithe");
        uint256 titheAmount = (msg.value * tithePercentage) / 100;

        require(
            address(this).balance >= titheAmount,
            "Insufficient balance for tithe"
        );

        (bool success, ) = payable(beneficiary).call{value: titheAmount}("");
        require(success, "Failed to transfer tithe");

        emit TithePaid(beneficiary, titheAmount);
    }
}
