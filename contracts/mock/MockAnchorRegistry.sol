pragma solidity ^0.4.24;

import "../AnchorRegistry.sol";
/* solium-disable-next-line */
import "openzeppelin-solidity/contracts/introspection/SupportsInterfaceWithLookup.sol";

 
/**
 * @title MockAnchorRegistry
 * This mock is for easy testing purposes of an anchor registry
 * that goes hand in hand with a mintable ERC721 contract
 */
contract MockAnchorRegistry is AnchorRegistry, SupportsInterfaceWithLookup {
  // A simplistic representation of a document anchor
  struct Anchor {
    bytes32 documentRoot; 
  }

  mapping(bytes32 => Anchor) public anchors;

  constructor()
    public
  {
    // register the supported interfaces to conform as AnchorRegistry
    _registerInterface(InterfaceId_AnchorRegistry);
  }

  /**
   * @dev Sets the anchor details for a document.
   * @param _anchorId bytes32 The document anchor identifier
   * @param _documentRoot bytes32 The root hash of document
   */
  function setAnchorById(bytes32 _anchorId, bytes32 _documentRoot) 
  external payable 
  {
    // not allowing empty vals
    require(_anchorId != 0x0);
    require(_documentRoot != 0x0);
    
    anchors[_anchorId] = Anchor(_documentRoot);
  }

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
    )
  {
    return (
      _identifier,
      anchors[_identifier].documentRoot
    );
  }    

  function calculateSelector() public pure returns (bytes4) {
    AnchorRegistry ar;
    return ar.getAnchorById.selector;
  }  
}
