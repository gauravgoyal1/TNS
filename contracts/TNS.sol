// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";

contract TNS is Ownable, ERC721 {
    mapping(uint256 => bytes32) private verifiedHandles;
    mapping(bytes32 => uint256) private verifiedTokens;

    mapping(uint256 => address) private records;
    mapping(address => uint256) private reverseRecords;

    uint256 public pricePerMint;
    uint256 public issued;

    event NewHandle(bytes32 indexed handle, uint256 indexed id, address indexed owner);
    event UpdateHandle(bytes32 indexed handle, address indexed owner, uint256 id);
    event UpdateAddress(address indexed owner, bytes32 indexed handle, uint256 id);

    function resolve(
        bytes32 handle
    ) public view returns (
        address
    ) {
        require(
            handleExists(handle), 
            "TNS: handle doesn't exist"
        );
        return records[verifiedTokens[handle]];
    }

    function reverseResolve(
        address addr
    ) public view returns (
        bytes32
    ) {
        require(
            addressExists(addr), 
            "TNS: address doesn't exist"
        );
        return verifiedHandles[reverseRecords[addr]];
    }

    function getTokenHandle(
        uint256 tokenId
    ) public view returns (
        bytes32
    ) {
        require(
            _exists(tokenId), 
            "TNS: nonexistent token"
        );
        return verifiedHandles[tokenId];
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
        emit UpdateHandle(verifiedHandles[tokenId], addr, tokenId);
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
        emit UpdateAddress(addr, verifiedHandles[tokenId], tokenId);
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
        bytes32 handle,
        uint256 tokenId
    ) external onlyOwner {
        _verify(addr, handle, tokenId);
    }
    
    function mintVerified(
        address addr,
        bytes32 handle
    ) external onlyOwner {
        _mintVerified(addr, handle);
    }
    
    function mintVerifiedBulk(
        address[] memory addrs,
        bytes32[] memory handles
    ) external onlyOwner {
        require(
            addrs.length == handles.length,
            "TNS: length mismatch!"
        );
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

    function tokenURI(uint256 tokenId) external override returns (string memory) {
        string memory output;
        string memory stringTokenId = toString(tokenId);

        output = string(
            abi.encodePacked(
                stringTokenId,
            )
        );

        output = string(
            abi.encodePacked(
                "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'> <rect width='350' height='350' fill='url(#paint0_linear)'/> <rect width='318' height='318' transform='translate(16 16)' fill='#16150f'/> <text fill='white' xml:space='preserve' style='white-space: pre;' font-family='Georgia' font-size='12' font-weight='bold' letter-spacing='0em'><tspan x='32' y='62.1865'>STARTER DECK</tspan></text> <text fill='#F19100' xml:space='preserve' style='white-space: pre;' font-family='Georgia' font-size='16' font-weight='bold' letter-spacing='0.16em'><tspan x='32' y='43.582'>45 ADVENTURE CARDS</tspan></text> <text fill='white' xml:space='preserve' style='white-space: pre;' font-family='Georgia' font-size='12' letter-spacing='0em'>",
                output,
                "<defs> <linearGradient id='paint0_linear' x1='175' y1='350' x2='175' y2='0' gradientUnits='userSpaceOnUse'> <stop stop-color='#744500'/> <stop offset='1' stop-color='#D68103'/> </linearGradient> </defs></svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "TNS #',
                        stringTokenId,
                        '", "description": "Twitter Name Service.", "image": "data:image/svg+xml;base64,',
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
        bytes32 handle
    ) internal {
        issued += 1;
        _safeMint(addr, issued);
        _verify(addr, handle, issued);
    }

    function _verify(
        address addr,
        bytes32 handle,
        uint256 tokenId
    ) internal {
        verifiedHandles[tokenId] = handle;
        verifiedTokens[handle] = tokenId;
        records[tokenId] = addr;
        emit NewHandle(handle, tokenId, addr);
    }

    function handleExists(
        bytes32 handle
    ) internal view returns (bool) {
        return verifiedTokens[handle] > 0;
    }

    function addressExists(
        address addr
    ) internal view returns (bool) {
        return reverseRecords[addr] > 0;
    }
    
    constructor() ERC721("Twitter Naming Service", "TNS") Ownable() { }

}