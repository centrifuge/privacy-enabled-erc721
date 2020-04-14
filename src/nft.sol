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
    function verify(bytes32) public view;
}

contract KeyManagerLike {
    function keyHasPurpose(bytes32, uint) public view returns (bool);
    function getKey(bytes32) public view returns (bytes32, uint[] memory, uint32);
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

    // Base for constructing dynamic metadata token URIS
    // the token uri also contains the registry address. uri + contract address + tokenId
    string public uri;

    constructor(string memory name, string memory symbol, address assetManager_, address identityFactory_) ERC721Metadata(name, symbol) public {
        assetManager = AssetManagerLike(assetManager_);
        identityFactory = IdentityFactoryLike(identityFactory_);
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
    function _verifyAsset(address to, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) internal view  {
        // construct assetHash from the props, values, salts
        // append to address
        bytes memory data = abi.encodePacked(to);

        // append hashes
        for (uint i=0; i< properties.length; i++) {
            data = abi.encodePacked(data, keccak256(abi.encodePacked(properties[i], values[i], salts[i])));
        }

        assetManager.verify(keccak256(data));
    }

    /**
     * @dev Checks that provided document is signed by the given identity. Validates and checks if the public key used is a not revoked and has the purpose SIGNING_KEY.
     * Does not check if the signature root is part of the document root.
     * @param identity address identity which is a collaborator of the document
     * @param dataRoot bytes32 hash of all data fields of the document which are signed
     * @param signature bytes contains signature + transition flag
     */
    function _signed_document(address identity, bytes32 dataRoot, bytes memory signature) internal view {
        // check that the identity being used has been created by the Centrifuge Identity Factory contract
        require(identityFactory.createdIdentity(identity), "nft/identity-not-registered");
        // extract flag from signature
        (bytes memory sig, byte flag) = _recoverSignatureAndFlag(signature);
        // Recalculate hash and extract the public key from the signature
        address key = _toEthSignedMessage(dataRoot, flag).recover(sig);
        bytes32 pubKey = bytes32(uint(key) << 96);
        // check that public key has signature purpose on provided identity
        KeyManagerLike keyManager = KeyManagerLike(identity);
        require(keyManager.keyHasPurpose(pubKey, SIGNING_PURPOSE), "nft/sig-key-not-valid");
        (, , uint32 revokedAt) = keyManager.getKey(pubKey);
        require(revokedAt == 0, "nft/key-revoked");
    }

    function _recoverSignatureAndFlag(bytes memory signature) internal pure returns (bytes memory, byte) {
        // ensure signature value is 66
        require(signature.length == 66, "nft/invalid-signature-length");
        byte flag = signature[65];
        bytes memory sig = new bytes(65);
        uint i = 0;
        for (i = 0; i < 65; i++) {
            sig[i] = signature[i];
        }
        return (sig, flag);
    }

    function _toEthSignedMessage(bytes32 dataRoot, byte flag) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n33", dataRoot, flag));
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

    function tokenURI( uint token_id) external view returns (string memory) {
        return string(abi.encodePacked(uri, "0x", uintToHexStr(uint(address(this))), "/0x", uintToHexStr(token_id)));
    }
}
