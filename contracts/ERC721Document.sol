pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721Token.sol";
import "openzeppelin-solidity/contracts/MerkleProof.sol";
import "contracts/AnchorRegistry.sol";


contract ERC721Document is ERC721Token {
  bytes4 internal constant InterfaceId_AnchorRegistry = 0x04d466b2;
  /*
   * 0x04d466b2 ===
   *   bytes4(keccak256('getAnchorById(bytes32)')) 
   */  

  // anchor registry
  address internal anchorRegistry_;

  // The ownable anchor
  struct OwnedAnchor {
    bytes32 documentId;
    bytes32 rootHash;
  }

  // Mapping from token details to token ID
  mapping (uint256 => OwnedAnchor) internal tokenDetails_;

  /** 
   * @dev Constructor function
   * @param _name string The name of this token 
   * @param _symbol string The shorthand token identifier
   * @param _anchorRegistry address The address of the anchor registry
   * that is backing this token's mint method.
   */
  constructor(string _name, string _symbol, address _anchorRegistry) 
  ERC721Token(_name, _symbol) 
  public 
  {
    require(
      AnchorRegistry(_anchorRegistry).supportsInterface(InterfaceId_AnchorRegistry), 
      "not a valid anchor registry"
    ); 
    anchorRegistry_ = _anchorRegistry;
  }

  /**
   * @dev Gets the anchor registry's address that is backing this token
   * @return address The address of the anchor registry
   */
  function anchorRegistry() 
  external view 
  returns (address) 
  {
    return anchorRegistry_;
  }  

  /**
   * @dev Checks if a given document is registered in the the
   * anchor registry of this contract with the given root hash.
   * @param _documentId bytes32 The ID of the document as identified
   * by the set up anchorRegistry.
   * @param _merkleRoot bytes32 The root hash of the merkle proof/doc
   */
  function _isRegisteredInRegistryWithRoot(
    bytes32 _documentId,
    bytes32 _merkleRoot
  )
  internal view 
  returns (bool)
  {
    AnchorRegistry ar = AnchorRegistry(anchorRegistry_);
    (bytes32 identifier, bytes32 merkleRoot) = ar.getAnchorById(_documentId);
    if(
      identifier != 0x0 && 
      _documentId == identifier &&
      
      merkleRoot != 0x0 &&
      _merkleRoot == merkleRoot
    ){
      return true;
    } 
    return false;
  }

  /**
   * @dev Hashes a leaf's data according to precise-proof leaf 
   * concatenation rules. Using keccak256 hashing.
   * @param _leafName string The leaf's name that is being proved
   * @param _leafValue string The leaf's value that is being proved
   * @param _leafSalt bytes32 The leaf's that is being proved
   * @return byte32 keccak256 hash of the concatenated plain-text values
   */
  function _hashLeafData(
    string _leafName,
    string _leafValue,
    bytes32 _leafSalt 
  ) 
  internal pure
  returns (bytes32)
  {
    return keccak256(abi.encodePacked(_leafName, _leafValue, _leafSalt)); 
  }

  /**
   * @dev Mints a token after validating the given merkle proof
   * and comparing it to the anchor registry's stored hash/doc ID.
   * @param _to address The recipient of the minted token
   * @param _tokenId uint256 The ID for the minted token
   * @param _documentId bytes32 The ID of the document as identified
   * by the set up anchorRegistry.
   * @param _merkleRoot bytes32 The root hash of the merkle proof/doc
   * @param _proof bytes32[] The proof to prove the _leaf authenticity
   * @param _leafName string The leaf's name that is being proved. 
   * Will be concatenated for proof verification as outlined in 
   * precise-proofs library.
   * @param _leafValue string The leaf's value that is being proved
   * Will be concatenated for proof verification as outlined in 
   * precise-proofs library.
   * @param _leafSalt bytes32 The leaf's that is being proved
   * Will be concatenated for proof verification as outlined in 
   * precise-proofs library.
   */
  function mintMerklePlainText(
    address _to, 
    uint256 _tokenId, 
    bytes32 _documentId, 
    bytes32 _merkleRoot, 
    bytes32[] _proof, 
    string _leafName,
    string _leafValue,
    bytes32 _leafSalt 
  ) 
  external 
  {
    // explicitly not checking on plain text values being empty
    // as it might actually be a use-case to have empty values being provided

    // Add business-logic-specific validations based on the clear-text values here

    bytes32 leaf = _hashLeafData(_leafName, _leafValue, _leafSalt); 
    this.mintMerkle(_to, _tokenId, _documentId, _merkleRoot, _proof, leaf);
  }


  /**
   * @dev Mints a token after validating the given merkle proof
   * and comparing it to the anchor registry's stored hash/doc ID.
   * @param _to address The recipient of the minted token
   * @param _tokenId uint256 The ID for the minted token
   * @param _documentId bytes32 The ID of the document as identified
   * by the set up anchorRegistry.
   * @param _merkleRoot bytes32 The root hash of the merkle proof/doc
   * @param _proof bytes32[] The proof to prove the _leaf authenticity
   * @param _leaf bytes32 The leaf that is being proved
   */
  function mintMerkle(
    address _to, 
    uint256 _tokenId, 
    bytes32 _documentId, 
    bytes32 _merkleRoot, 
    bytes32[] _proof, 
    bytes32 _leaf 
  ) 
  external 
  {
    require(
      _documentId != 0x0, 
      "document ID needs to be valid"
    );
    require(
      _merkleRoot != 0x0, 
      "merkle root needs to be valid"
    );
    require(
      _isRegisteredInRegistryWithRoot(_documentId, _merkleRoot),
      "document needs to be registered in registry"
    );
    require(
      MerkleProof.verifyProof(_proof, _merkleRoot, _leaf), 
      "merkle tree needs to validate"
    );
    
    //Add business-logic-specific validations here

    super._mint(_to, _tokenId);
    tokenDetails_[_tokenId] = OwnedAnchor(_documentId, _merkleRoot);
    _registerTokenURI(_tokenId);
  }

  function _registerTokenURI(uint256 _tokenId) 
  internal 
  {
    // pseudo code
    // string uri = "XYZ:ABC/".toSlice().concat(tokenDetails_[_tokenId].documentId.toSlice());
    tokenURIs[_tokenId] = "somewhere:decentralized";
  }
}