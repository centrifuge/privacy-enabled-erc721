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
import "../merkle.sol";


contract MerkleTest is DSTest, MerkleVerifier {
    address to = bytesToAddress(hex"f2bd5de8b57ebfc45dcee97524a7a08fccc80aef");
    bytes32 assetHashValid = bytesToBytes32(hex"ee49e1ca6aa1204cfb571094ce14ab254e5185005cbee3f26af9afd3140ac12d");
    bytes32 assetHashInvalid = bytesToBytes32(hex"c437005805629feeb716f4ff329f62a4cf393f4cbfc7cd14fc0a64d8321a3e99");

    function hash(bytes32 a, bytes32 b) public pure returns (bytes32) {
        if (a < b) {
            return sha256(abi.encodePacked(a, b));
        } else {
            return sha256(abi.encodePacked(b, a));
        }
    }

    function testVerifier() public {
        bytes32 leaf1 = sha256("1");
        bytes32 leaf2 = sha256("2");
        bytes32 leaf3 = sha256("3");
        bytes32 leaf4 = sha256("4");
        bytes32 parent1 = hash(leaf1, leaf2);
        bytes32 parent2 = hash(leaf3, leaf4);
        bytes32 root = hash(parent1, parent2);
        bytes32[] memory matches = new bytes32[](10);
        matches[0] = root;
        uint len = 1;
        bytes32[][] memory proofs = new bytes32[][](3);
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = leaf2;
        proof[1] = parent2;
        proofs[0] = proof;
        (matches, len) = verify(proof, matches, len, leaf1);
        assertEq(len, 4);

        proof = new bytes32[](1);
        proof[0] = leaf4;
        proofs[1] = proof;
        (matches, len) = verify(proof, matches, len, leaf3);
        assertEq(len, 5);

        proof = new bytes32[](1);
        proof[0] = leaf1;
        proofs[2] = proof;
        (matches, len) = verify(proof, matches, len, leaf2);
        assertEq(len, 5);

        matches = new bytes32[](10);
        matches[0] = root;
        len = 1;
        bytes32[] memory leafs = new bytes32[](3);
        leafs[0] = leaf1;
        leafs[1] = leaf3;
        leafs[2] = leaf2;
        require(verify(proofs, matches, len, leafs));
        require(verify(proofs, root, leafs));
    }

    function testFind() public {
        bytes32[] memory matches = new bytes32[](512);
        matches[0] = "0";
        assertTrue(find(matches, "0"));
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function bytesToBytes32(bytes memory b) private pure returns (bytes32) {
        bytes32 out;
        uint offset = 0;

        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return out;
    }

    function testFailInvalidToAddress() public logs_gas {
        bytes[] memory properties = new bytes[](0);
        bytes[] memory values = new bytes[](0);
        bytes32[] memory salts = new bytes32[](0);
        bytes32 assetHash = keccak256(hex"000100000000300a");
        verify(address(0), assetHash, properties, values, salts);
    }

    function getPropsValuesSalts() private pure returns (bytes[] memory props, bytes[] memory values, bytes32[] memory salts) {
        props = new bytes[](3);
        props[0] = bytes(hex"392614ecdd98ce9b86b6c82242ae1b85aaf53ebe6f52490ed44539c88215b17a");
        props[1] = bytes(hex"8db964a550ede5fea3f059ca6a74cf436890bb1d31a39c63ea0ccfbc8d8235fd");
        props[2] = bytes(hex"c437005805629feeb716f4ff329f62a4cf393f4cbfc7cd14fc0a64d8321a3e99");

        values = new bytes[](3);
        values[0] = bytes(hex"d6ad85800460ea404f3289484f9300ed787dc951203cb3f0ef5fa0fa4db283cc");
        values[1] = bytes(hex"446bfed759680364b759d32d6d217e287df7aad0bf4c82816f124d7e03ab248f");
        values[2] = bytes(hex"443e4fa3d89952c9f24433d1112713a075d9205195dc9a16a12301caa1afb5d2");

        salts = new bytes32[](3);
        salts[0] = bytesToBytes32(hex"34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408");
        salts[1] = bytesToBytes32(hex"e257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b39");
        salts[2] = bytesToBytes32(hex"ed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cc");

        return (props, values, salts);
    }

    function testVerifyAssetMismatch() public logs_gas {
        (bytes[] memory props, bytes[] memory values, bytes32[] memory salts) = getPropsValuesSalts();
        bool res = verify(to, assetHashInvalid, props, values, salts);
        assertTrue(!res);
    }

    function testVerifyBundledSuccess() public logs_gas {
        (bytes[] memory props, bytes[] memory values, bytes32[] memory salts) = getPropsValuesSalts();
        bool res = verify(to, assetHashValid, props, values, salts);
        assertTrue(res);
    }
}
