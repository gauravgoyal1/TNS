// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/utils/math/Math.sol";

contract VestingWallet is Context, Ownable {
    event ERC20Released(address indexed token, address indexed beneficiary, uint256 amount);

    address public token;
    uint public totalShares;
    uint64 public duration;

    uint256 public releasedTotal;
    mapping(address => uint256) private releasedTokens;
    mapping(address => uint256) private shares;

    mapping(address => uint64) private startTimes;

    constructor(
        address _token,
        uint32 _totalShares,
        uint64 durationSeconds
    ) {
        token = _token;
        totalShares = _totalShares;
        duration = durationSeconds;
    }

    receive() external payable {}

    function allocateShares(address addr, uint32 _shares) external onlyOwner {
        shares[addr] = _shares;
    }

    function beneficiaryStart(address addr, uint64 _startTime) external onlyOwner {
        startTimes[addr] = _startTime;
    }

    function beneficiaryShares(address addr) public view returns (uint256) {
        return shares[addr];
    }

    function startTime(address addr) public view returns (uint256) {
        return startTimes[addr];
    }

    function endTime(address addr) public view returns (uint256) {
        return startTime(addr) + duration;
    }

    function released(address addr) public view returns (uint256) {
        return releasedTokens[addr];
    }

    function release() public {
        uint256 releasable = vested(_msgSender(), uint64(block.timestamp)) - released(_msgSender());
        releasedTokens[_msgSender()] += releasable;
        releasedTotal += releasable;
        emit ERC20Released(token, _msgSender(), releasable);
        SafeERC20.safeTransfer(IERC20(token), _msgSender(), releasable);
    }

    function vested(address addr, uint64 timestamp) public view returns (uint256) {
        return (_vestingSchedule(addr, IERC20(token).balanceOf(address(this)) + released(addr), timestamp) * beneficiaryShares(addr)) / totalShares;
    }

    function _vestingSchedule(address addr, uint256 totalAllocation, uint64 timestamp) internal view returns (uint256) {
        if (timestamp < startTime(addr)) {
            return 0;
        } else if (timestamp > startTime(addr) + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - startTime(addr))) / duration;
        }
    }
}