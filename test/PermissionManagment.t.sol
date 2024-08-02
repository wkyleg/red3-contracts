// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/PermissionManagment.sol";

contract MockPermissionManagment is PermissionManagment {
    function grantPermission(address user, PermissionType permission) public {
        _grantPermission(user, permission);
    }

    function revokePermission(address user, PermissionType permission) public {
        _revokePermission(user, permission);
    }

    function revokeAllPermissions(address user) public {
        _revokeAllPermissions(user);
    }

    function checkPermission(PermissionType permission) public view onlyWithPermission(permission) {}
}

contract PermissionManagmentTest is Test {
    MockPermissionManagment public permissions;
    address public user1;
    address public user2;

    function setUp() public {
        permissions = new MockPermissionManagment();
        user1 = address(0x1);
        user2 = address(0x2);
    }

    function testGrantSinglePermission() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        assertTrue(permissions.hasPermission(user1, PermissionManagment.PermissionType.TREASURY));
        assertFalse(permissions.hasPermission(user1, PermissionManagment.PermissionType.CONTENT));
    }

    function testGrantMultiplePermissions() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        permissions.grantPermission(user1, PermissionManagment.PermissionType.CONTENT);
        assertTrue(permissions.hasPermission(user1, PermissionManagment.PermissionType.TREASURY));
        assertTrue(permissions.hasPermission(user1, PermissionManagment.PermissionType.CONTENT));
    }

    function testRevokeSpecificPermission() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        permissions.grantPermission(user1, PermissionManagment.PermissionType.CONTENT);
        permissions.revokePermission(user1, PermissionManagment.PermissionType.TREASURY);
        assertFalse(permissions.hasPermission(user1, PermissionManagment.PermissionType.TREASURY));
        assertTrue(permissions.hasPermission(user1, PermissionManagment.PermissionType.CONTENT));
    }

    function testRevokeAllPermissions() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        permissions.grantPermission(user1, PermissionManagment.PermissionType.CONTENT);
        permissions.revokeAllPermissions(user1);
        assertFalse(permissions.hasPermission(user1, PermissionManagment.PermissionType.TREASURY));
        assertFalse(permissions.hasPermission(user1, PermissionManagment.PermissionType.CONTENT));
    }

    function testGetUserPermissions() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        permissions.grantPermission(user1, PermissionManagment.PermissionType.CONTENT);
        PermissionManagment.PermissionType[] memory userPerms = permissions.getUserPermissions(user1);
        assertEq(userPerms.length, 2);
        assertTrue(
            (userPerms[0] == PermissionManagment.PermissionType.TREASURY && userPerms[1] == PermissionManagment.PermissionType.CONTENT) ||
            (userPerms[0] == PermissionManagment.PermissionType.CONTENT && userPerms[1] == PermissionManagment.PermissionType.TREASURY)
        );
    }

    function testPermissionToString() public {
        assertEq(permissions.permissionToString(PermissionManagment.PermissionType.TREASURY), "TREASURY");
        assertEq(permissions.permissionToString(PermissionManagment.PermissionType.CONTENT), "CONTENT");
        assertEq(permissions.permissionToString(PermissionManagment.PermissionType.NONE), "NONE");
    }

    function testStringToPermission() public {
        assertEq(uint(permissions.stringToPermission("TREASURY")), uint(PermissionManagment.PermissionType.TREASURY));
        assertEq(uint(permissions.stringToPermission("CONTENT")), uint(PermissionManagment.PermissionType.CONTENT));
        assertEq(uint(permissions.stringToPermission("INVALID")), uint(PermissionManagment.PermissionType.NONE));
    }

    function testOnlyWithPermissionModifier() public {
        permissions.grantPermission(user1, PermissionManagment.PermissionType.TREASURY);
        vm.prank(user1);
        permissions.checkPermission(PermissionManagment.PermissionType.TREASURY);

        vm.expectRevert("Permission not granted");
        vm.prank(user2);
        permissions.checkPermission(PermissionManagment.PermissionType.TREASURY);
    }
}