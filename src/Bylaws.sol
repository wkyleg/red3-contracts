// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Bylaws {
    string private _bylawsUrl;
    
    event BylawsSet(string bylawsUrl);
    
    constructor(string memory initialBylawsUrl) {
        _setBylaws(initialBylawsUrl);
    }
    
    function getBylawsUrl() public view returns (string memory) {
        return _bylawsUrl;
    }
    
    function setBylaws(string memory _arweaveUrl) public virtual {
        _setBylaws(_arweaveUrl);
    }
    
    function _setBylaws(string memory _arweaveUrl) internal virtual {
        require(bytes(_arweaveUrl).length > 0, "Bylaws URL cannot be empty");
        require(bytes(_arweaveUrl).length <= 2048, "Bylaws URL too long"); // Example max length
        _bylawsUrl = _arweaveUrl;
        emit BylawsSet(_arweaveUrl);
    }

    function isBylawsUrl(string memory _url) public view returns (bool) {
        return keccak256(abi.encodePacked(_bylawsUrl)) == keccak256(abi.encodePacked(_url));
    }
}