// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Tithe.sol";

contract TestTithe is Tithe {
    constructor(
        address _beneficiary,
        uint256 _percentage
    ) Tithe(_beneficiary, _percentage) {}
}

contract TitheTest is Test {
    TestTithe tithe;
    address beneficiary = address(1);
    uint256 initialPercentage = 10;

    function setUp() public {
        tithe = new TestTithe(beneficiary, initialPercentage);
    }

    function testInitialState() public {
        assertEq(tithe.beneficiary(), beneficiary);
        assertEq(tithe.tithePercentage(), initialPercentage);
    }

    function testSetTithe() public {
        address newBeneficiary = address(2);
        uint256 newPercentage = 15;

        tithe.setTithe(newBeneficiary, newPercentage);

        assertEq(tithe.beneficiary(), newBeneficiary);
        assertEq(tithe.tithePercentage(), newPercentage);
    }

    function testPayTithe() public {
        uint256 sendAmount = 1000 ether;
        uint256 expectedTithe = (sendAmount * initialPercentage) / 100;

        uint256 initialBeneficiaryBalance = beneficiary.balance;

        tithe.payTithe{value: sendAmount}();

        assertEq(
            beneficiary.balance,
            initialBeneficiaryBalance + expectedTithe
        );
    }

    function testPayTitheZeroAmount() public {
        vm.expectRevert("Must send some ETH to pay tithe");
        tithe.payTithe{value: 0}();
    }

    function testSetTitheInvalidBeneficiary() public {
        vm.expectRevert("Invalid beneficiary address");
        tithe.setTithe(address(0), 10);
    }

    function testSetTitheInvalidPercentage() public {
        vm.expectRevert("Percentage must be between 0 and 100");
        tithe.setTithe(address(1), 101);
    }

    receive() external payable {}
}
