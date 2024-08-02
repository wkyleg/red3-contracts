// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/DACFactory.sol";

contract DACFactoryTest is Test {
    DACFactory factory;

    function setUp() public {
        factory = new DACFactory();
    }

    function testDeployDAC() public {
        // Set up initial parameters for the DAC
        string memory name = "Test DAC";
        string memory symbol = "TDAC";
        uint256 initialSupply = 1000000;
        string memory initialBylawsUrl = "https://example.com/bylaws";
        uint256 electionThreshold = 10;
        uint256 votingPeriod = 7 days;
        uint256 minParticipationRate = 50;
        address titheBeneficiary = address(0x5678);
        uint256 tithePercentage = 10;
        address initialCEO = address(0x1234);

        // Deploy the DAC
        address newDAC = factory.deployDAC(
            name,
            symbol,
            initialSupply,
            initialBylawsUrl,
            electionThreshold,
            votingPeriod,
            minParticipationRate,
            titheBeneficiary,
            tithePercentage,
            initialCEO
        );

        // Verify the DAC address
        assertTrue(newDAC != address(0), "DAC deployment failed");

        // Verify that the DAC was added to the deployedDACs list
        address[] memory deployedDACs = factory.getDeployedDACs();
        assertEq(deployedDACs.length, 1);
        assertEq(deployedDACs[0], newDAC);
    }
}
