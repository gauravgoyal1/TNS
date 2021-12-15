// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import "./Base64.sol";

contract TNS is Ownable, ERC721 {
    mapping(uint256 => string) private tokenToHandle;
    mapping(string => uint256) private handleToToken;

    mapping(uint256 => address) private records;
    mapping(address => uint256) private reverseRecords;

    uint256 public pricePerMint;
    uint256 public issued;

    event NewHandle(
        string indexed handle, 
        uint256 indexed id, 
        address indexed owner
    );
    event UpdateHandle(
        string indexed handle, 
        address indexed owner, 
        uint256 id
    );
    event UpdateAddress(
        address indexed owner, 
        string indexed handle, 
        uint256 id
    );

    function resolve(
        string memory handle
    ) public view returns (
        address
    ) {
        require(
            handleExists(handle), 
            "TNS: handle doesn't exist"
        );
        return records[handleToToken[handle]];
    }

    function reverseResolve(
        address addr
    ) public view returns (
        string memory
    ) {
        require(
            addressExists(addr), 
            "TNS: address doesn't exist"
        );
        return tokenToHandle[reverseRecords[addr]];
    }

    function getTokenHandle(
        uint256 tokenId
    ) public view returns (
        string memory
    ) {
        require(
            _exists(tokenId), 
            "TNS: nonexistent token"
        );
        return tokenToHandle[tokenId];
    }

    function updateRecord(
        uint256 tokenId, 
        address addr
    ) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId), 
            "TNS: not owner nor approved"
        );
        records[tokenId] = addr;

        emit UpdateHandle(
            tokenToHandle[tokenId], 
            addr, 
            tokenId
        );
    }

    function updateReverseRecord(
        address addr, 
        uint256 tokenId
    ) external {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId), 
            "TNS: not owner nor approved"
        );
        reverseRecords[addr] = tokenId;

        emit UpdateAddress(
            addr, 
            tokenToHandle[tokenId], 
            tokenId
        );
    }

    function mintPublic(
        address addr
    ) external payable {
        require(
            msg.value >= pricePerMint, 
            "TNS: Not enough value sent!"
        );
        issued += 1;
        _safeMint(addr, issued);
    }

    function verify(
        address addr,
        string memory handle,
        uint256 tokenId
    ) external onlyOwner {
        require(
            handleExists(handle) == false,
            "TNS: handle exists!"
        );
        _verify(addr, handle, tokenId);
    }
    
    function mintVerified(
        address addr,
        string memory handle
    ) external onlyOwner {
        require(
            handleExists(handle) == false,
            "TNS: handle exists!"
        );
        _mintVerified(addr, handle);
    }
    
    function mintVerifiedBulk(
        address[] memory addrs,
        string[] memory handles
    ) external onlyOwner {
        require(
            addrs.length == handles.length,
            "TNS: length mismatch!"
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            require(
                handleExists(handles[i]) == false,
                "TNS: handle exists!"
            );
        }
        for (uint256 i = 0; i < addrs.length; i++) {
            _mintVerified(addrs[i], handles[i]);
        }
    }

    function withdrawAmount(
        uint256 amount,
        address addr
    ) external onlyOwner {
        payable(addr).transfer(amount);

    }

    function tokenURI(
        uint256 tokenId
    ) public view override returns (
        string memory
    ) {
        require(
            _exists(tokenId), 
            "TNS: nonexistent token"
        );
        string memory output;
        string memory handle = tokenToHandle[tokenId];

        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
                '<style>.base { fill: white; font-family: sans-serif; font-size: 40px; }</style>',
                '<rect width="100%" height="100%" fill="#1DA1F2" /><text x="10" y="40" class="base">',
                handle,
                '</text><text x="250" y="300" class="base" style="font-size: 25px;">TNS</text></svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        handle,
                        '", "description": "',
                        handle,
                        ', a TNS Handle.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
        return output;
    }

    // INTERNAL FUNCTIONS

    function _mintVerified(
        address addr,
        string memory handle
    ) internal {
        issued += 1;
        _safeMint(addr, issued);
        _verify(addr, handle, issued);
    }

    function _verify(
        address addr,
        string memory handle,
        uint256 tokenId
    ) internal {
        tokenToHandle[tokenId] = handle;
        handleToToken[handle] = tokenId;
        records[tokenId] = addr;
        emit NewHandle(handle, tokenId, addr);
    }

    function handleExists(
        string memory handle
    ) internal view returns (
        bool
    ) {
        return handleToToken[handle] > 0;
    }

    function addressExists(
        address addr
    ) internal view returns (
        bool
    ) {
        return reverseRecords[addr] > 0;
    }
    
    constructor() ERC721("Twitter Naming Service", "TNS") Ownable() { }

}