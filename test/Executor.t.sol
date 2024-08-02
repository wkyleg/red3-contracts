// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Executor.sol";

contract MockExecutor is Executor {
    // Empty implementation to make the contract concrete
}

contract TestContract {
    uint256 public value;
    event ValueSet(uint256 newValue);

    function setValue(uint256 _value) external payable {
        value = _value;
        emit ValueSet(_value);
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

contract ExecutorTest is Test {
    MockExecutor public executor;
    TestContract public testContract;

    function setUp() public {
        executor = new MockExecutor();
        testContract = new TestContract();
    }

    function testExecuteCall() public {
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute(
            address(testContract),
            0,
            data,
            false,
            100000,
            "Set value"
        );
        assertTrue(success);
        assertEq(testContract.value(), 42);
    }

    function testExecuteDelegateCall() public {
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute(
            address(testContract),
            0,
            data,
            true,
            100000,
            "Delegate call"
        );
        assertTrue(success);
        // Note: In a real delegatecall, the state would be changed in the executor contract, not in testContract
    }

    function testExecuteWithValue() public {
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute{value: 1 ether}(
            address(testContract),
            1 ether,
            data,
            false,
            100000,
            "Set value with ETH"
        );
        assertTrue(success);
        assertEq(testContract.value(), 42);
        assertEq(address(testContract).balance, 1 ether);
    }

    function testExecuteWithInsufficientGas() public {
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute(
            address(testContract),
            0,
            data,
            false,
            1000,
            "Insufficient gas"
        );
        assertFalse(success);
        assertEq(testContract.value(), 0);
    }

    function testExecuteToNonExistentContract() public {
        address nonExistentContract = address(0x123);
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute(
            nonExistentContract,
            0,
            data,
            false,
            100000,
            "Call to non-existent contract"
        );
        assertTrue(success);
    }

    function testExecuteWithLowGas() public {
        bytes memory data = abi.encodeWithSelector(
            TestContract.setValue.selector,
            42
        );
        bool success = executor.execute(
            address(testContract),
            0,
            data,
            false,
            21000,
            "Low gas"
        );
        assertFalse(success); // Expect the call to fail due to out of gas
        assertEq(testContract.value(), 0); // The value should not have been set
    }

    receive() external payable {}
}
