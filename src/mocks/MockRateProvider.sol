// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.21;

contract MockRateProvider {

    address public owner;
    uint256 public rate = 1e27;

    modifier onlyOwner() {
        require(msg.sender == owner, "MockRateProvider/not-owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function getConversionRate() external view returns (uint256) {
        return rate;
    }
}
