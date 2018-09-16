pragma solidity ^0.4.24;

import "../ERC721Document.sol";

 
/**
 * @title MockERC721Document
 * This mock is for easy testing purposes of internal methods
 */
contract MockERC721Document is ERC721Document {
  
  constructor(string _name, string _symbol, address _anchorRegistry) 
  ERC721Document(_name, _symbol, _anchorRegistry) 
  public 
  {
  }

  function isRegisteredInRegistryWithRoot(
    bytes32 _documentId,
    bytes32 _merkleRoot
  )
  public view
  returns (bool)
  {
    return super._isRegisteredInRegistryWithRoot(
      _documentId, 
      _merkleRoot
    );
  }

  function hashLeafData(
    string _leafName,
    string _leafValue,
    bytes32 _leafSalt 
  ) 
  external pure
  returns (bytes32)
  {
    return super._hashLeafData(_leafName, _leafValue, _leafSalt); 
  }
}
