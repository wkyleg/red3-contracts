// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract PermissionManagment {
    enum PermissionType {
        NONE,
        TREASURY,
        CONTENT
    }

    mapping(address => uint256) private _permissions;

    event PermissionGranted(address indexed user, PermissionType permission);
    event PermissionRevoked(address indexed user, PermissionType permission);

    function _grantPermission(address user, PermissionType permission) internal virtual {
        require(permission != PermissionType.NONE, "Invalid permission");
        _permissions[user] |= (1 << uint256(permission));
        emit PermissionGranted(user, permission);
    }

    function _revokePermission(address user, PermissionType permission) internal virtual {
        _permissions[user] &= ~(1 << uint256(permission));
        emit PermissionRevoked(user, permission);
    }

    function _revokeAllPermissions(address user) internal virtual {
        _permissions[user] = 0;
        emit PermissionRevoked(user, PermissionType.NONE);
    }

    modifier onlyWithPermission(PermissionType permission) {
        require(hasPermission(msg.sender, permission), "Permission not granted");
        _;
    }

    function hasPermission(address user, PermissionType permission) public view returns (bool) {
        return (_permissions[user] & (1 << uint256(permission))) != 0;
    }

    function getUserPermissions(address user) public view returns (PermissionType[] memory) {
        PermissionType[] memory userPermissions = new PermissionType[](32); // Max possible permissions
        uint256 count = 0;
        for (uint256 i = 0; i < 32; i++) {
            if ((_permissions[user] & (1 << i)) != 0) {
                userPermissions[count] = PermissionType(i);
                count++;
            }
        }
        
        // Create a new array with the correct size
        PermissionType[] memory result = new PermissionType[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = userPermissions[i];
        }
        return result;
    }

    function permissionToString(PermissionType permission) public pure returns (string memory) {
        if (permission == PermissionType.TREASURY) return "TREASURY";
        if (permission == PermissionType.CONTENT) return "CONTENT";
        return "NONE";
    }

    function stringToPermission(string memory _permission) public pure returns (PermissionType) {
        bytes32 permissionHash = keccak256(abi.encodePacked(_permission));
        if (permissionHash == keccak256(abi.encodePacked("TREASURY"))) return PermissionType.TREASURY;
        if (permissionHash == keccak256(abi.encodePacked("CONTENT"))) return PermissionType.CONTENT;
        return PermissionType.NONE;
    }
}