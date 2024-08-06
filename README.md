# red3

Decentralized Autonomous Corporation (DAC) Contracts

## Overview

This project implements a framework for creating and managing Decentralized Autonomous Corporations (DACs) on the Ethereum blockchain. DACs are designed to operate as on-chain entities with governance, dividend distribution, and tithe mechanisms.

You can view live at [red3.me](https://red3.me) or consider funding at [Gitcoin](https://builder.gitcoin.co/#/chains/8453/registry/0x/projects/0x6a7033a145a1ae5ec1ccffe2ed01e81b7a08da4e218b682e82e899d8ae2a4315)

## Key Features

- DAC Creation: Deploy new DACs with customizable parameters.
- Governance: Implement CEO elections with configurable voting mechanisms.
- Dividend Distribution: Automatically distribute dividends to token holders.
- Tithe System: Implement a tithe mechanism for revenue sharing.
- Bylaws Management: Store and update bylaws for each DAC.

## Smart Contracts

### DAC.sol

The main contract for each Decentralized Autonomous Corporation.

Key functions:

- `callForElection()`: Initiate a new CEO election.
- `vote(address candidate)`: Cast a vote in the ongoing election.
- `concludeElection()`: Finalize the election and update the CEO.
- `disburse(uint256 amount)`: Distribute dividends to token holders.
- `withdrawDividends()`: Allow token holders to withdraw their dividends.
- `receiveInvoice(string calldata description)`: Receive payments and apply tithe.

### DACFactory.sol

A factory contract for deploying new DAC instances.

Key functions:

- `deployDAC(...)`: Deploy a new DAC with specified parameters.
- `getDeployedDACs()`: Retrieve a list of all deployed DACs.

### Other Supporting Contracts

- `Bylaws.sol`: Manage bylaws for DACs.
- `Invoice.sol`: Manage invoice creation and processing.
- `PermissionManagement.sol`: Handle permission and access control.
- `Executor.sol`: Execute arbitrary transactions on behalf of the DAC.
- `Tithe.sol`: Implement tithe mechanisms.

Warning: these contracts have not yet been audited but feedback is welcome

This project is licensed under the MIT License.
