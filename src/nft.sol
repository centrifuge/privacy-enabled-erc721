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

pragma solidity >=0.5.15 <0.6.0;
pragma experimental ABIEncoderV2;

import { ERC721Metadata } from "./openzeppelin-solidity/token/ERC721/ERC721Metadata.sol";
import "./openzeppelin-solidity/cryptography/ECDSA.sol";

contract AssetManagerLike {
    function isAssetValid(bytes32 asset) external view returns (bool);
}

contract KeyManagerLike {
    function keyHasPurpose(bytes32, uint) public view returns (bool);
}

contract IdentityFactoryLike {
    function createdIdentity(address) public view returns (bool);
}

contract NFT is ERC721Metadata {

    using ECDSA for bytes32;

    // compact prop for "nfts"
    bytes constant internal NFTS = hex"0100000000000014";
    // Value of the Signature purpose for an identity. sha256('CENTRIFUGE@SIGNING')
    // solium-disable-next-line
    uint constant internal SIGNING_PURPOSE = 0x774a43710604e3ce8db630136980a6ba5a65b5e6686ee51009ed5f3fded6ea7e;

    AssetManagerLike assetManager;
    IdentityFactoryLike identityFactory;
    KeyManagerLike keyManager;

    constructor(string memory name, string memory symbol, address assetManager_, address identityFactory_, address keyManager_) ERC721Metadata(name, symbol) public {
        assetManager = AssetManagerLike(assetManager_);
        identityFactory = IdentityFactoryLike(identityFactory_);
        keyManager = KeyManagerLike(keyManager_);
    }

    event Minted(address to, uint tokenId);

    /**
     * @dev Mints a token to a specified address
     * @param to address deposit address of token
     * @param tokenId uint256 tokenID
     */
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);
        emit Minted(to, tokenId);
    }

    /**
     * Computes the asset hash from the given params and verifies if its present in the AssetManager
     * @param to address deposit address of the token
     * @param properties bytes[] properties of the each proof
     * @param values bytes[] value associated with each property
     * @param salts bytes[] salt associated with each property
     */
    function _verifyAsset(address to, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) internal view returns (bool) {
        require(to != address(0), "not a valid address");

        // construct assetHash from the props, values, salts
        // append to address
        bytes memory data = abi.encodePacked(to);

        // append hashes
        for (uint i=0; i< properties.length; i++) {
            data = abi.encodePacked(data, keccak256(abi.encodePacked(properties[i], values[i], salts[i])));
        }

        return assetManager.isAssetValid(keccak256(data));
    }

    /**
     * @dev Checks that provided document is signed by the given identity. Validates and checks if the public key used is a valid SIGNING_KEY.
     * Does not check if the signature root is part of the document root.
     * @param data_root bytes32 hash of all data fields of the document which are signed
     * @param signature bytes The signature used to sign the data root
     */
    function _signed(bytes32 data_root, bytes memory signature) internal view {
        // Extract the public key and identity address from the signature
        address identity_ = data_root.toEthSignedMessageHash().recover(signature);
        bytes32 pbKey_ = bytes32(uint(identity_) << 96);
        // check that the identity being used has been created by the Centrifuge Identity Factory contract
        require(identityFactory.createdIdentity(identity_), "Identity is not registered.");
        // check that public key has signature purpose on provided identity
        require(keyManager.keyHasPurpose(pbKey_, SIGNING_PURPOSE), "Signature key is not valid.");
    }

    /**
     * @dev Checks that the passed in token proof matches the data for minting
     * @param tkn uint The ID for the token to be minted
     */
    function _checkTokenData(uint tkn, bytes memory property, bytes memory value) internal view {
        require(_bytesToUint(value) == tkn, "tokenID mismatch");
        require(_equalBytes(property, abi.encodePacked(NFTS, address(this), hex"000000000000000000000000")), "token property mismatch");
    }

    /**
     * @dev Parses bytes and extracts a uint value
     * @param data bytes From where to extract the index
     * @return result the converted address
     */
    function _bytesToUint(bytes memory data) internal pure returns (uint) {
        require(data.length <= 256, "slicing out of range");
        return abi.decode(data, (uint));
    }

    function _equalBytes(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }

        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Parses a uint and returns the hex string
     * @param payload uint
     * @return string the corresponding hex string
     */
    function uintToHexStr(uint payload) internal pure returns (string memory) {
        if (payload == 0)
            return "0";
        // calculate string length
        uint i = payload;
        uint length;

        while (i != 0) {
            length++;
            i = i >> 4;
        }
        // parse byte by byte and construct the string
        i = payload;
        uint mask = 15;
        bytes memory result = new bytes(length);
        uint k = length - 1;

        while (i != 0) {
            uint curr = (i & mask);
            result[k--] = curr > 9 ? byte(55 + uint8(curr)) : byte(48 + uint8(curr));
            i = i >> 4;
        }

        return string(result);
    }
}

