// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAC.sol";

contract DACFactory {
    address[] public deployedDACs;

    event DACDeployed(address indexed dacAddress);

    function deployDAC(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        string memory initialBylawsUrl,
        uint256 _electionThreshold,
        uint256 _votingPeriod,
        uint256 _minParticipationRate,
        address _titheBeneficiary,
        uint256 _tithePercentage,
        address _initialCEO
    ) public returns (address) {
        DAC newDAC = new DAC(
            name,
            symbol,
            initialSupply,
            initialBylawsUrl,
            _electionThreshold,
            _votingPeriod,
            _minParticipationRate,
            _titheBeneficiary,
            _tithePercentage,
            _initialCEO
        );
        deployedDACs.push(address(newDAC));
        emit DACDeployed(address(newDAC));
        return address(newDAC);
    }

    function getDeployedDACs() public view returns (address[] memory) {
        return deployedDACs;
    }
}
