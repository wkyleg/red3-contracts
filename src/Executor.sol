// Based on https://github.com/safe-global/safe-smart-account/blob/main/contracts/base/Executor.sol
pragma solidity ^0.8.0;

/**
 * @title Executor - A contract that can execute transactions
 * @author Richard Meissner - @rmeissner
 * @dev This contract is based on the Gnosis Safe Executor contract, with some modifications.
 */
abstract contract Executor {
    /**
     * @dev Emitted when a transaction is executed.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param isDelegateCall Flag indicating if the call was a delegate call.
     * @param txGas Gas used for the transaction.
     * @param memo Memo for the transaction.
     */
    event TransactionExecuted(
        address indexed to,
        uint256 value,
        bytes data,
        bool isDelegateCall,
        uint256 txGas,
        string memo
    );

    /*
     * @notice Executes either a delegatecall or a call with provided parameters.
     * @dev This method doesn't perform any sanity check of the transaction, such as:
     *      - if the contract at `to` address has code or not
     *      It is the responsibility of the caller to perform such checks.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @return success boolean flag indicating if the call succeeded.
     */

    function execute(
        address to,
        uint256 value,
        bytes memory data,
        bool isDelegateCall,
        uint256 txGas,
        string memory memo
    ) public payable virtual returns (bool success) {
       
        if (isDelegateCall) {
            /* solhint-disable no-inline-assembly */
            /// @solidity memory-safe-assembly
            assembly {
                success := delegatecall(
                    txGas,
                    to,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            /* solhint-enable no-inline-assembly */
        } else {
            /* solhint-disable no-inline-assembly */
            /// @solidity memory-safe-assembly
            assembly {
                success := call(
                    txGas,
                    to,
                    value,
                    add(data, 0x20),
                    mload(data),
                    0,
                    0
                )
            }
            /* solhint-enable no-inline-assembly */
        }

        emit TransactionExecuted(to, value, data, isDelegateCall, txGas, memo);

        return success;
    }
}
