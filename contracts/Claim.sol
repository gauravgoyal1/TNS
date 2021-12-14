// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

contract TNS {
    function ownerOf(uint256 tokenId) public view virtual returns (address) {}
}

contract ClaimTNSGov is Context, Ownable {
    event ClaimedTNSGov(address indexed token, address indexed addr, uint256 amount);

    uint256 public claimedTotal;

    TNS private immutable tns;
    address private immutable token;
    mapping(uint256 => uint256) private claimed;

    uint256 private decimals = 1000000000000000000;

    constructor(
        address _token,
        address _tns
    ) {
        token = _token;
        tns = TNS(_tns);
    }
    
    function claimable(uint256 tokenId) public view returns (uint256) {
        require(tns.ownerOf(tokenId) == _msgSender(), "You aren't owner");
        if (claimed[tokenId] > 0) {
            return 0;
        } else if (tokenId <= 1000) {
            return 1240 * decimals;
        } else if (tokenId <= 10000) {
            return 420 * decimals;
        } else if (tokenId <= 100000) {
            return 222 * decimals;
        } else {
            return 0;
        }
    }

    function claim(uint256 tokenId) external {
        uint256 amount = claimable(tokenId);
        require(amount > 0, "Nothing to claim");
        require(claimed[tokenId] > 0, "already claimed");
        claimed[tokenId] = amount;
        claimedTotal += amount;
        SafeERC20.safeTransfer(IERC20(token), _msgSender(), amount);
        emit ClaimedTNSGov(token, _msgSender(), amount);
    }
}