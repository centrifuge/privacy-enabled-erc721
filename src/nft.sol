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

import { ERC721Metadata } from "./openzeppelin-solidity/token/ERC721/ERC721Metadata.sol";
import "./openzeppelin-solidity/cryptography/ECDSA.sol";
import "./merkle.sol";

contract AnchorLike {
    function getAnchorById(uint) public view returns (uint, bytes32, uint32);
}

contract KeyManagerLike {
    function keyHasPurpose(bytes32, uint) public view returns (bool);
    function getKey(bytes32) public view returns (bytes32, uint[] memory, uint32);
}

contract IdentityFactoryLike {
    function createdIdentity(address) public view returns (bool);
}

contract NFT is ERC721Metadata, MerkleVerifier {

    using ECDSA for bytes32;

    // --- Data ---
    KeyManagerLike public       key_manager;
    AnchorLike public           anchors;
    IdentityFactoryLike public  identity_factory;

    // Base for constructing dynamic metadata token URIS
    // the token uri also contains the registry address. uri + contract address + tokenId
    string public uri;

    // --- Compact Properties ---
    // compact prop for "next_version"
    bytes constant internal NEXT_VERSION = hex"0100000000000004";
    // compact prop for "nfts"
    bytes constant internal NFTS = hex"0100000000000014";
    // Value of the Signature purpose for an identity. sha256('CENTRIFUGE@SIGNING')
    // solium-disable-next-line
    uint constant internal SIGNING_PURPOSE = 0x774a43710604e3ce8db630136980a6ba5a65b5e6686ee51009ed5f3fded6ea7e;

    constructor (string memory name, string memory symbol, address anchors_, address identity_, address identity_factory_) ERC721Metadata(name, symbol) public {
        anchors = AnchorLike(anchors_);
        key_manager = KeyManagerLike(identity_);
        identity_factory = IdentityFactoryLike(identity_factory_);
    }

    event Minted(address usr, uint tkn);

    // --- Utils ---
    function concat(bytes32 b1, bytes32 b2) pure internal returns (bytes memory) {
        bytes memory result = new bytes(64);
        assembly {
            mstore(add(result, 32), b1)
            mstore(add(result, 64), b2)
        }
        return result;
    }

     /**
      * @dev Parses bytes and extracts a uint value
      * @param data bytes From where to extract the index
      * @return result the converted address
      */
    function bytesToUint(bytes memory data) internal pure returns (uint) {
        require(data.length <= 256, "slicing out of range");
        return abi.decode(data, (uint));
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

    function equalBytes(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length == b.length) {
            for (uint i = 0; i < a.length; i++) {
                if (a[i] != b[i]) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    // --- NFT ---
    function _checkAnchor(uint anchor, bytes32 data_root, bytes32 sig_root) internal view returns (bool) {
        bytes32 doc_root;
        (, doc_root, ) = anchors.getAnchorById(anchor);
        if (data_root < sig_root) {
           return doc_root == sha256(concat(data_root, sig_root));
        } else {
           return doc_root == sha256(concat(sig_root, data_root));
        }
    }

    function tokenURI( uint token_id) external view returns (string memory) {
        return string(abi.encodePacked(uri, "0x", uintToHexStr(uint(address(this))), "/0x", uintToHexStr(token_id)));
    }

  /**
   * @dev Checks if the document is the latest version anchored
   * @param data_root bytes32 hash of all data fields of the document which are signed
   * @param next_anchor_id uint the next id to be anchored
   */
  function _latestDoc( bytes32 data_root, uint next_anchor_id)  internal view returns (bool) {
        (, bytes32 next_merkle_root_, ) = anchors.getAnchorById(next_anchor_id);
        return next_merkle_root_ == 0x0;
  }

  /**
   * @dev Checks that provided document is signed by the given identity and validates and checks if the public key used is a valid SIGNING_KEY. Does not check if the signature root is part of the document root.
   * @param anchor uint anchor ID
   * @param data_root bytes32 hash of all data fields of the document which are signed
   * @param signature bytes The signature used to sign the data root
   */
    function _signed(uint anchor, bytes32 data_root, bytes memory signature) internal view {
      // Get anchored block from anchor ID
    (, , uint32 anchored_block) = anchors.getAnchorById(anchor);
      // Extract the public key and identity address from the signature
      address identity_ = data_root.toEthSignedMessageHash().recover(signature);
      bytes32 pbKey_ = bytes32(uint(identity_) << 96);
      // check that the identity being used has been created by the Centrifuge Identity Factory contract
      require(identity_factory.createdIdentity(identity_), "Identity is not registered.");
      // check that public key has signature purpose on provided identity
      require(key_manager.keyHasPurpose(pbKey_, SIGNING_PURPOSE), "Signature key is not valid.");
      // If key is revoked, anchor must be older the the key revocation
      (, , uint32 revokedAt_) = key_manager.getKey(pbKey_);
      if (revokedAt_ > 0) {
        require(anchored_block < revokedAt_,"Document signed with a revoked key.");
      }
    }

  /**
   * @dev Checks that the passed in token proof matches the data for minting
   * @param tkn uint The ID for the token to be minted
   */
    function _checkTokenData(uint tkn, bytes memory property, bytes memory value) internal view returns (bool) {
        if (bytesToUint(value) != tkn) {
            return false;
        }
        return equalBytes(property, abi.encodePacked(hex"0100000000000014", address(this), hex"000000000000000000000000"));
    }

  /**
   * @dev Mints a token to a specified address
   * @param usr address deposit address of token
   * @param tkn uint tokenID
   */
    function _mint(address usr, uint tkn) internal {
        super._mint(usr, tkn);
        emit Minted(usr, tkn);
    }
}

