// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Bylaws.sol";

contract MockBylaws is Bylaws {
    constructor(string memory initialBylawsUrl) Bylaws(initialBylawsUrl) {}
}

contract BylawsTest is Test {
    MockBylaws public bylaws;
    string constant INITIAL_URL = "ar://initial-bylaws-hash";
    string constant NEW_URL = "ar://new-bylaws-hash";

    event BylawsSet(string bylawsUrl);

    function setUp() public {
        bylaws = new MockBylaws(INITIAL_URL);
    }

    function testInitialBylawsUrl() public {
        assertEq(bylaws.getBylawsUrl(), INITIAL_URL);
    }

    function testSetBylaws() public {
        vm.expectEmit(false, false, false, true);
        emit BylawsSet(NEW_URL);
        bylaws.setBylaws(NEW_URL);
        assertEq(bylaws.getBylawsUrl(), NEW_URL);
    }

    function testSetBylawsEmptyString() public {
        vm.expectRevert("Bylaws URL cannot be empty");
        bylaws.setBylaws("");
    }

    function testSetBylawsSameUrl() public {
        bylaws.setBylaws(INITIAL_URL);
        assertEq(bylaws.getBylawsUrl(), INITIAL_URL);
    }

    function testSetBylawsLongUrl() public {
        string memory longUrl = "ar://";
        for (uint i = 0; i < 100; i++) {
            longUrl = string(abi.encodePacked(longUrl, "abcdefghij"));
        }
        bylaws.setBylaws(longUrl);
        assertEq(bylaws.getBylawsUrl(), longUrl);
    }
}
