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

pragma solidity >=0.4.24;


// This is an optimized Merkle proof checker. It caches all valid leaves in an array called
// matches. If a proof is validated, all the intermediate hashes will be added to the array.
// When validating a subsequent proof, that proof will stop being validated as soon as a hash
// has been computed that has been a computed hash in a previously validated proof.
//
// When submitting a list of proof, the client can thus choose to chop of all the already proven
// nodes when submitting multiple proofs.
//
// matches: matches must be initialized with length = sum of all proof hashes to ensure all
//          computed hashes can be stored.
//
// len:     is a pointer that points to the first non-empty element in the matches array.
//          Solidity unfortunately has no internal count.
//
// In the first call to verify(), you should pass in the matches containing exactly one hash,
// the Merkle root and len should be 1. For any subsequent call, the return values from the
// previous call to verify should be used.
//
contract MerkleVerifier {
    uint constant hashLength = 512;
    function find(bytes32[] memory values, bytes32 value) internal pure returns (bool) {
        for (uint i=0; i < values.length; i++) {
            if (values[i] == value) {
                return true;
            }
        }
        return false;
    }

    function verify(bytes32[] memory proof, bytes32[] memory matches, uint len, bytes32 leaf) internal pure returns (bytes32[] memory, uint) {
        bytes32 res = leaf;
        if (find(matches, res)) {
            return (matches, len);
        }
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 elem = proof[i];
            matches[len] = elem;
            len++;
            if (res < elem) {
                res = sha256(abi.encodePacked(res, elem));
            } else {
                res = sha256(abi.encodePacked(elem, res));
            }
            if (find(matches, res)){
                return (matches, len);
            }
            matches[len] = res;
            len++;
        }
        // special case, int==proof validation failed
        return (matches, 0);
    }

    function verify(bytes32[][] memory proofs, bytes32[] memory matches, uint len, bytes32[] memory leafs) internal pure returns (bool) {
        require(len>0);
        for (uint256 i = 0; i < proofs.length; i++) {
            (matches, len) = verify(proofs[i], matches, len, leafs[i]);
            if (len == 0) {
                return false;
            }
        }
        return true;
    }

    function verify(bytes32[][] memory proofs, bytes32 root, bytes32[] memory leafs) internal pure returns (bool) {
        uint len = 0;
        for (uint256 i = 0; i< proofs.length; i++) {
            len += proofs[i].length;
        }
        bytes32[] memory matches = new bytes32[](len*2);
        matches[0] = root;
        len = 1;

        return verify(proofs, matches, len, leafs);
    }

}
