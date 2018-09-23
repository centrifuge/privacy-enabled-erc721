pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/introspection/ERC165.sol";


/**
 * @title An anchor registry that is used in conjunction with a privacy-enabled NFT registry
 */
contract AnchorRegistry is ERC165 {
  bytes4 internal constant InterfaceId_AnchorRegistry = 0x04d466b2;
  /*
   * 0x04d466b2 ===
   *   bytes4(keccak256('getAnchorById(bytes32)')) 
   */  

  /**
   * @dev Gets the anchor details for a document.
   * @param _identifier bytes32 The document anchor identifier
   * @return identifier bytes32 The document anchor identifier as found
   * @return merkleRoot bytes32 The document's root hash value
   */
  function getAnchorById (bytes32 _identifier) 
  external view 
  returns (
    bytes32 identifier, 
    bytes32 merkleRoot
    );
}