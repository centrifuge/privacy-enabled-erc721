// Copyright (C) 2019 lucasvo

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

import "ds-test/test.sol";
import "../nft.sol";

contract User {
    function doMint(address registry, address usr) public {
    }
}

contract AnchorMock {
    bytes32 documentRoot;
    uint32  blockNumber;

    function file(bytes32 documentRoot_, uint32 blockNumber_) public {
        documentRoot = documentRoot_;
        blockNumber = blockNumber;
    }

    function getAnchorById(uint id) public returns (uint, bytes32, uint32) {
        return (id, documentRoot, blockNumber);
    }
}

contract TestNFT is NFT {
    constructor (string memory name, string memory symbol, address anchors_) NFT(name, symbol, anchors_) public {
    }
    function checkAnchor(uint anchor, bytes32 droot, bytes32 sigs) public returns (bool) {
        return _checkAnchor(anchor, droot, sigs); 
    }
} 

contract NFTTest is DSTest  {
    TestNFT     nft;
    address     self;
    User        user1;
    User        user2;
    AnchorMock  anchors;

    function setUp() public {
        self = address(this);
        user1 = new User();
        user2 = new User();
        anchors = new AnchorMock();
        nft = new TestNFT("test", "TEST", address(anchors));
    }

    function testAnchor() public logs_gas {
        bytes32 sigs = 0x5d9215ea8ea2c12bcc724d9690de0801a1b9658014c29c2a26d3b89eaa65cd07;
        bytes32 data_root = 0x7fdb7b2d4ddb3ca67c1a79725fc9b3e4e2b8d4c15bedc8cac1873fa58a75b837;
        bytes32 root = 0x0ea4cc3dcbc2b85a3032d00edb8314119b9b199ca05d8a7c35e0427a8ae64991;

        // Setting AnchorMock to return a given root
        anchors.file(root, 0); 
       
        assertTrue(nft.checkAnchor(0, data_root, sigs));
    }

}
