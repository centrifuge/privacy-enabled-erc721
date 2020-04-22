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
import "../asset_nft.sol";

contract AssetManagerMock {
    mapping (bytes32 => uint8) public assets;
    bool assetValid;

    function file(bool assetValid_) public {
        assetValid = assetValid_;
    }

    function getHash(bytes32 ) external view returns (bool) {
        return assetValid;
    }
}


contract IDFactoryMock {
    address identity;
    bool validIdentity;

    function file(bool validity_) public {
        validIdentity = validity_;
    }

    function createdIdentity(address) public view returns (bool) {
        return validIdentity;
    }
}

contract NFTTest is DSTest {
    AssetNFT nft;
    AssetManagerMock assetManager;
    IDFactoryMock identityFactory;
    uint tokenId;
    bytes32 dataRoot;
    address to;
    bytes[] props;
    bytes[] values;
    bytes32[] salts;
    bytes32[] saltsInvalid;

    bytes32 key;
    uint[] mem;
    uint32 revoked = 1;
    bool valid;

    function file(uint32 revoked_) public {
        revoked = revoked_;
    }

    function file(bool valid_) public {
        valid = valid_;
    }

    function getKey(bytes32) public view returns (bytes32, uint[] memory, uint32) {
        return (key, mem, revoked);
    }

    function keyHasPurpose(bytes32, uint) public view returns (bool){
        return valid;
    }

    function setUp() public {
        assetManager = new AssetManagerMock();
        identityFactory = new IDFactoryMock();
        nft = new AssetNFT(address(assetManager), address(identityFactory));
        tokenId = 1;
        to = address(1234);
        dataRoot = 0xca87e9ba4fcfc9eb27594e18d14dc3fb094913e67c9aa3f19e0e3205dbb7dbfa;
        props = new bytes[](6);
        props[0] = hex"010000000000001ce24e7917d4fcaf79095539ac23af9f6d5c80ea8b0d95c9cd860152bff8fdab1700000005";
        props[1] = hex"010000000000001ccd35852d8705a28d4f83ba46f02ebdf46daf03638b40da74b9371d715976e6dd00000005";
        props[2] = hex"010000000000001cbbaa573c53fa357a3b53624eb6deab5f4c758f299cffc2b0b6162400e3ec13ee00000005";
        props[3] = hex"010000000000001ce5588a8a267ed4c32962568afe216d4ba70ae60576a611e3ca557b84f1724e2900000005";
        props[4] = hex"0100000000000014e821d1b50945ff736992d0af793684dd53ac7fa7000000000000000000000000";
        props[5] = hex"010000000000001ce821d1b50945fd736992d0af793684dd53ac7ff7000000000000000000000000";


        values = new bytes[](6);
        values[0] = hex"c631f33ee268544609b47de2903da8a41162df3f";
        values[1] = hex"0000000000000000000000000000000000000000000000056bc75e2d63100000";
        values[2] = hex"a4c57ce7c1de38f90d11b56e05c24d11aecade34422c1504c9b7f04d9d7fed80";
        values[3] = hex"000000005e9d5c300b3147b8";
        values[4] = hex"fc03d8fc2094952d153396f1904513850b4f76fcfeaef9c44dcb6d7de1921674";
        values[5] = hex"443e4fa3d89952c9f24433d1112713a075d9205195dc9a16a12301caa1afb5d2";


        salts = new bytes32[](6);
        salts[0] = 0x34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408;
        salts[1] = 0xe257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b39;
        salts[2] = 0xed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cc;
        salts[3] = 0x34ea1aa3061dca2e1e23573c3b8866f80032d18fd85934d90339c8bafcab0408;
        salts[4] = 0xe257b56611cf3244b2b63bfe486ea3072f10223d473285f8fea868aae2323b39;
        salts[5] = 0xed58f4a0d0c76770c81d2b1cc035413edebb567f5c006160596dc73b9297a9cc;
    }

    function toBytes(address x) internal pure returns (bytes memory b) {
        b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
    }

    function testFailMismatchAssetHash() public logs_gas {
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailOriginatorPropMismatch() public logs_gas{
        assetManager.file(true);
        props[0] = hex"010000000000001cbbaa573c53fa357a3b53624eb6deab5f4c758f299cffc2b0b6162400e3ec13ee00000005";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailOriginatorValueMismatch() public logs_gas{
        assetManager.file(true);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailIdentityNotRegistered() public logs_gas {
        assetManager.file(true);
        values[0] = toBytes(address(this));
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }


    function testFailSignatureValueNotValid() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c01";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }


    function testFailKeyDoNotHaveValidPurpose() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailKeyRevoked() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailTokenPropertyMismatch() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailTokenIdMismatch() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailAssetValuePropertyMismatch() public logs_gas{
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        props[1] = hex"010000000000001cbbaa573c53fa357a3b53624eb6deab5f4c758f299cffc2b0b6162400e3ec13ee00000005";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailAssetIDPropertyMismatch() public logs_gas{
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        props[2] = hex"010000000000001ce24e7917d4fcaf79095539ac23af9f6d5c80ea8b0d95c9cd860152bff8fdab1700000005";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailAssetIDLengthMismatch() public logs_gas{
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        values[2] = hex"c631f33ee268544609b47de2903da8a41162df3f";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }

    function testFailMaturityDatePropertyMismatch() public logs_gas{
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        props[3] = hex"010000000000001ce24e7917d4fcaf79095539ac23af9f6d5c80ea8b0d95c9cd860152bff8fdab1700000005";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }


    function testSuccessMintNFT() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);
        (address originator, uint asset_value, bytes32 asset_id, uint64 maturity_date) = nft.data(tokenId);
        assertEq(originator, address(this));
        assertEq0(abi.encode(asset_value), values[1]);
        assertEq0(abi.encode(asset_id), values[2]);
        assertEq(uint(maturity_date), 6817706772324763576);
    }

    function testFailDoubleMintNFT() public logs_gas {
        assetManager.file(true);
        identityFactory.file(true);
        values[0] = toBytes(address(this));
        values[4] = hex"a2776063c2177a8e4be999fd337d939d03df0f341c50d2dac45dafad0008016e248cfb0076035c514dfc66af39e574bcc795a6af6b112a6ec90ff9291c766b7c7c01";
        file(true);
        file(0);
        props[5] = abi.encodePacked(hex"0100000000000014", address(nft), hex"000000000000000000000000");
        values[5] = hex"0000000000000000000000000000000000000000000000000000000000000001";
        nft.mint(to, tokenId, dataRoot, props, values, salts);
        assertEq(nft.balanceOf(to), 1);
        assertEq(nft.ownerOf(tokenId), to);
        nft.mint(to, tokenId, dataRoot, props, values, salts);
    }
}
