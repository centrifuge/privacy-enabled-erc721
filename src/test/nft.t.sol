// Copyright (C) 2019 Centrifuge

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
pragma experimental ABIEncoderV2;

import "../nft.sol";
import "../../lib/ds-test/src/test.sol";

contract NFTTest is DSTest {
    NFT nft;
    uint256 tokenId;
    address to;
    bytes32 assetHashValid;
    bytes32 assetHashInvalid;
    bytes[] props;
    bytes[] values;
    bytes32[] salts;

    function setUp() public {
        nft = new NFT("NFT", "NFT");
        tokenId = uint256(keccak256(hex"000200000000000c"));
        to = bytesToAddress(hex"f2bd5de8b57ebfc45dcee97524a7a08fccc80aef");
        assetHashValid = 0xee49e1ca6aa1204cfb571094ce14ab254e5185005cbee3f26af9afd3140ac12d;
        assetHashInvalid = 0xc437005805629feeb716f4ff329f62a4cf393f4cbfc7cd14fc0a64d8321a3e99;
        props = new bytes[](3);
        props[0] = hex"392614ecdd98ce9b86b6c82242ae1b85aaf53ebe6f52490ed44539c88215b17a";
        props[1] = hex"8db964a550ede5fea3f059ca6a74cf436890bb1d31a39c63ea0ccfbc8d8235fd";
        props[2] = hex"c437005805629feeb716f4ff329f62a4cf393f4cbfc7cd14fc0a64d8321a3e99";

        values = new bytes[](3);
        values[0] = hex"d6ad85800460ea404f3289484f9300ed787dc951203cb3f0ef5fa0fa4db283cc";
        values[1] = hex"446bfed759680364b759d32d6d217e287df7aad0bf4c82816f124d7e03ab248f";
        values[2] = hex"443e4fa3d89952c9f24433d1112713a075d9205195dc9a16a12301caa1afb5d2";

        salts = new bytes32[](3);
        salts[0] = 0x34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408;
        salts[1] = 0xe257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b39;
        salts[2] = 0xed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cc;
    }

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys,20))
        }
    }

    function testFailInvalidToAddress() public logs_gas {
        nft.mint(address(0), tokenId, assetHashValid, props, values, salts);
        assertEq(address(0), nft.ownerOf(tokenId));
    }

    function testFailMismatchAssetHash() public logs_gas {
        nft.mint(to, tokenId, assetHashInvalid, props, values, salts);
        assertEq(nft.balanceOf(to), 0);
    }

    function testNFTSuccess() public logs_gas {
        nft.mint(to, tokenId, assetHashValid, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);
    }

    function testFailNFTOverride() public logs_gas {
        nft.mint(to, tokenId, assetHashValid, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);

        // mint again
        nft.mint(to, tokenId, assetHashValid, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
    }
}
