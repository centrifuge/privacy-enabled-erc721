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

pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import "../nft.sol";
import "../../lib/ds-test/src/test.sol";

contract AssetManagerMock {
    mapping (bytes32 => uint8) public assets;
    bool assetValid;

    function file(bool assetVaild_) public {
        assetValid = assetVaild_;
    }

    function isAssetValid(bytes32 asset) external view returns (bool) {
        return assetValid;
    }
}

contract KeyManagerMock {
    bytes32 key;
    bytes32 value;
    uint purpose;
    uint[] mem;
    bool validPurpose;
    uint32 revoked;

    function file(bool validity_) public {
        validPurpose = validity_;
    }

    function keyHasPurpose(bytes32 pbKey, uint purpose_) public view returns (bool) {
        return validPurpose;
    }
}

contract IDFactoryMock {
    address identity;
    bool validIdentity;

    function file(bool validity_) public {
        validIdentity = validity_;
    }

    function createdIdentity(address identity_) public returns (bool) {
        return validIdentity;
    }
}

contract TestNFT is NFT {
    constructor (address asset_manager_, address key_manager_, address identity_factory_) NFT("Test NFT", "TNFT", asset_manager_, key_manager_, identity_factory_) public {
    }

    /**
    @dev Mints NFT after verifying the asset, signture of the collaborator and token uniqueness
    */
    function mint(address usr, uint tkn, bytes32 data_root, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) public {
        require(_verify_asset(usr, properties, values, salts), "asset hash invalid");
        _signed(data_root, values[0]); // expect the first value to be collaborator signature
        _checkTokenData(tkn, properties[1], values[1]); // expects the second property and value to be token unique proof
        _mint(usr, tkn);
    }
}

contract NFTTest is DSTest {
    TestNFT nft;
    AssetManagerMock assetManager;
    KeyManagerMock keyManager;
    IDFactoryMock identityFactory;
    uint tokenId;
    bytes32 dataRoot;
    address to;
    bytes[] props;
    bytes[] values;
    bytes32[] salts;
    bytes32[] saltsInvalid;

    function setUp() public {
        assetManager = new AssetManagerMock();
        identityFactory = new IDFactoryMock();
        keyManager = new KeyManagerMock();
        nft = new TestNFT(address(assetManager), address(identityFactory), address(keyManager));
        tokenId = 1;
        to = address(1234);
        dataRoot = 0xca87e9ba4fcfc9eb27594e18d14dc3fb094913e67c9aa3f19e0e3205dbb7dbfa;
        props = new bytes[](3);
        props[0] = hex"392614ecdd98ce9b86b6c82242ae1b85aaf53ebe6f52490ed44539c88215b17a";
        props[1] = hex"0100000000000014e821d1b50945ff736992d0af793684dd53ac7fa7000000000000000000000000";
        props[2] = hex"000100000000000d";

        values = new bytes[](3);
        values[0] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c01";
        values[1] = hex"fc03d8fc2094952d153396f1904513850b4f76fcfeaef9c44dcb6d7de1921674";
        values[2] = hex"443e4fa3d89952c9f24433d1112713a075d9205195dc9a16a12301caa1afb5d2";

        salts = new bytes32[](3);
        salts[0] = 0x34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408;
        salts[1] = 0xe257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b39;
        salts[2] = 0xed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cc;

        saltsInvalid = new bytes32[](3);
        saltsInvalid[0] = 0x34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408;
        saltsInvalid[1] = 0xe257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b99;
        saltsInvalid[2] = 0xed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cd;
    }

    function testFailInvalidToAddress() public logs_gas {
        nft.mint(address(0), tokenId, dataRoot, props, values, salts);
    }

    function testFailMismatchAssetHash() public logs_gas {
        nft.mint(to, tokenId, dataRoot, props, values, saltsInvalid);
    }

    function testFailIdentityNotRegistered() public logs_gas {
        assetManager.file(true);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailPublicKeyNotValid() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailTokenIDValueMismatch() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        keyManager.file(true);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailTokenPropertyMismatch() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        keyManager.file(true);
        values[1] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testSuccessMintNFT() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        keyManager.file(true);
        values[1] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        props[1] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        nft.mint(to, tokenId, dataRoot, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);
    }

    function testFailDoubleMintNFT() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        keyManager.file(true);
        values[1] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        props[1] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        nft.mint(to, tokenId, dataRoot, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }
}
