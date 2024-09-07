// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DAC.sol";
import "../src/PermissionManagment.sol";

contract DACTest is Test {
    DAC public dac;
    address public owner;
    address public ceo;
    address public user1;
    address public user2;
    address public titheBeneficiary;

    function setUp() public {
        owner = address(this);
        ceo = address(0x1);
        user1 = address(0x2);
        user2 = address(0x3);
        titheBeneficiary = address(0x4);

        vm.prank(owner);
        dac = new DAC(
            "Test DAC",
            "TDAC",
            1000000 * 10 ** 18,
            "ar://initial-bylaws",
            10, // electionThreshold
            1 days, // votingPeriod
            51, // minParticipationRate
            titheBeneficiary,
            5, // tithePercentage
            ceo
        );

        // Transfer tokens from CEO to the test contract (owner)
        vm.prank(ceo);
        dac.transfer(owner, 900000 * 10 ** 18);

        // Check the balance of the owner (test contract)
        uint256 ownerBalance = dac.balanceOf(owner);
        console.log("Owner balance:", ownerBalance);
    }

    function testInitialState() public {
        assertEq(dac.name(), "Test DAC");
        assertEq(dac.symbol(), "TDAC");
        assertEq(dac.totalSupply(), 1000000 * 10 ** 18);
        assertEq(dac.getBylawsUrl(), "ar://initial-bylaws");
        assertEq(dac.currentCEO(), ceo);
        assertTrue(
            dac.hasPermission(ceo, PermissionManagment.PermissionType.TREASURY)
        );
        assertTrue(
            dac.hasPermission(ceo, PermissionManagment.PermissionType.CONTENT)
        );
    }

    function testGrantAndRevokePermission() public {
        vm.prank(ceo);
        dac.grantPermission(user1, "TREASURY");
        assertTrue(
            dac.hasPermission(
                user1,
                PermissionManagment.PermissionType.TREASURY
            )
        );

        vm.prank(ceo);
        dac.revokePermission(user1, "TREASURY");
        assertFalse(
            dac.hasPermission(
                user1,
                PermissionManagment.PermissionType.TREASURY
            )
        );
    }

    function testOnlyCEOCanGrantPermissions() public {
        vm.prank(user1);
        vm.expectRevert("Caller is not the CEO");
        dac.grantPermission(user2, "CONTENT");
    }

    function testElectionProcess() public {
        // Transfer tokens to users for voting
        vm.startPrank(owner);
        dac.transfer(user1, 400000 * 10 ** 18);
        dac.transfer(user2, 400000 * 10 ** 18);
        vm.stopPrank();

        // Call for election
        vm.prank(user2);
        dac.callForElection();
        assertTrue(dac.electionInProgress());

        // Nominate candidates
        vm.prank(user1);
        dac.nominate(user1);
        vm.prank(user2);
        dac.nominate(user2);

        // Vote
        vm.prank(user1);
        dac.vote(user1);
        vm.prank(user2);
        dac.vote(user2);

        // Fast forward time
        vm.warp(block.timestamp + 2 days);

        // Conclude election
        dac.concludeElection();
        
        address newCEO = dac.currentCEO();
        console.log("New CEO:", newCEO);
        console.log("User1:", user1);
        console.log("User2:", user2);
        
        assertTrue(newCEO == user1 || newCEO == user2, "New CEO should be either user1 or user2");
    }

    function testDividendDistribution() public {
        vm.deal(address(dac), 20 ether);
        
        vm.startPrank(owner);
        dac.transfer(user1, 400000 * 10 ** 18);
        dac.transfer(user2, 400000 * 10 ** 18);  // Changed from 600000 to 400000
        vm.stopPrank();

        // Grant TREASURY permission to CEO
        vm.prank(ceo);
        dac.grantPermission(ceo, "TREASURY");

        // Disburse dividends
        vm.prank(ceo);
        dac.disburse(1 ether);

        // Check accumulated dividends
        assertApproxEqAbs(dac.accumulatedDividends(user1), 0.4 ether, 1000);
        assertApproxEqAbs(dac.accumulatedDividends(user2), 0.4 ether, 1000);

        console.log(
            "Contract balance before withdrawal:",
            dac.getContractBalance()
        );
        console.log(
            "User1 accumulated dividends:",
            dac.accumulatedDividends(user1)
        );

        // Withdraw dividends
        uint256 initialUserBalance = user1.balance;
        vm.prank(user1);
        dac.withdrawDividends();

        console.log(
            "Contract balance after withdrawal:",
            dac.getContractBalance()
        );

        assertApproxEqAbs(user1.balance - initialUserBalance, 0.4 ether, 1000);
        assertApproxEqAbs(dac.getContractBalance(), 19.6 ether, 1000);
    }

    function testTitheOnReceiveInvoice() public {
        uint256 initialContractBalance = address(dac).balance;
        uint256 initialTitheBeneficiaryBalance = titheBeneficiary.balance;

        console.log("Initial contract balance:", initialContractBalance);
        console.log(
            "Initial tithe beneficiary balance:",
            initialTitheBeneficiaryBalance
        );

        vm.deal(user1, 1 ether); // Give user1 some ETH to send
        vm.prank(user1);
        dac.receivePayment{value: 1 ether}("Test Invoice");

        uint256 expectedTithe = (1 ether * 5) / 100; // 5% tithe
        console.log("Expected tithe:", expectedTithe);
        console.log(
            "Final tithe beneficiary balance:",
            titheBeneficiary.balance
        );
        console.log("Final contract balance:", address(dac).balance);

        assertEq(
            titheBeneficiary.balance - initialTitheBeneficiaryBalance,
            expectedTithe
        );
        assertEq(
            address(dac).balance,
            initialContractBalance + 1 ether - expectedTithe
        );
    }

    function testExecuteTransaction() public {
        address payable recipient = payable(address(0x5));
        uint256 amount = 0.5 ether;

        // Fund the DAC contract
        vm.deal(address(dac), 1 ether);

        // Grant TREASURY permission to CEO
        vm.prank(ceo);
        dac.grantPermission(ceo, "TREASURY");

        vm.prank(ceo);
        bool success = dac.execute(
            recipient,
            amount,
            "",
            false,
            100000,
            "Test transaction"
        );
        assertTrue(success);
        assertEq(recipient.balance, amount);
    }

    function testSetBylaws() public {
        string memory newBylawsUrl = "ar://new-bylaws";
        vm.prank(ceo);
        dac.setBylaws(newBylawsUrl);
        assertEq(dac.getBylawsUrl(), newBylawsUrl);
    }

    function testFailNonCEOSetBylaws() public {
        string memory newBylawsUrl = "ar://new-bylaws";
        vm.prank(user1);
        dac.setBylaws(newBylawsUrl);
    }
    function testElectionWithInsufficientTokens() public {
        // Transfer 4.9% of tokens
        vm.prank(owner);
        dac.transfer(user1, 49000 * 10 ** 18);

        uint256 userBalance = dac.balanceOf(user1);
        uint256 totalSupply = dac.totalSupply();
        uint256 threshold = dac.electionThreshold();
        uint256 requiredBalance = (totalSupply * threshold) / 100;

        console.log("User balance:", userBalance);
        console.log("Required balance:", requiredBalance);
        console.log("Total supply:", totalSupply);
        console.log("Election threshold:", threshold);

        vm.expectRevert("Insufficient tokens to call election");
        vm.prank(user1);
        dac.callForElection();
    }

    function testVoteForNonCandidate() public {
        // Set up election
        vm.prank(owner);
        dac.transfer(user1, 200000 * 10 ** 18);
        vm.prank(user1);
        dac.callForElection();

        // Try to vote for a non-candidate (user2)
        vm.prank(user1);
        vm.expectRevert("Invalid candidate");
        dac.vote(user2);
    }

    function testWithdrawNoDividends() public {
        vm.prank(user1);
        vm.expectRevert("No dividends to withdraw");
        dac.withdrawDividends();
    }
}
