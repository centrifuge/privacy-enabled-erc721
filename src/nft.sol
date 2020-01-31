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
pragma experimental ABIEncoderV2;

import { ERC721Metadata } from "./openzeppelin-solidity/token/ERC721/ERC721Metadata.sol";
import "./asset_verifier.sol";

contract NFT is ERC721Metadata, AssetVerifier {

    constructor(string memory name, string memory symbol, address _assetManager) ERC721Metadata(name, symbol) public {
        assetManager = IAssetManager(_assetManager);
    }

    event Minted(address to, uint tokenId);

  /**
   * @dev Mints a token to a specified address
   * @param to address deposit address of token
   * @param tokenId uint256 tokenID
   */
    function mint(address to, uint256 tokenId, bytes[] memory properties, bytes[] memory values, bytes32[] memory salts) public {
        require(_verify_asset(to, properties, values, salts), "asset hash invalid");
        super._mint(to, tokenId);
        emit Minted(to, tokenId);
    }

}

