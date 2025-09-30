// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract AegisWallet {
    address public owner;
    uint256 public dailyCap;
    uint256 public spentToday;
    uint256 public lastReset;
    bool public paused;
    mapping(address => bool) public whitelist;

    event PaymentMade(address to, uint256 amount);

    constructor() {
        owner = msg.sender;
        dailyCap = 5 ether; // treat 1 ether as "$1" unit for demo
        paused = false;
        lastReset = block.timestamp;
    }

    modifier onlyOwner() { require(msg.sender == owner, "Not owner"); _; }

    modifier resetIfNewDay() {
        if (block.timestamp > lastReset + 1 days) {
            spentToday = 0;
            lastReset = block.timestamp;
        }
        _;
    }

    function setDailyCap(uint256 _cap) external onlyOwner { dailyCap = _cap; }
    function addPayee(address _payee) external onlyOwner { whitelist[_payee] = true; }
    function removePayee(address _payee) external onlyOwner { whitelist[_payee] = false; }
    function pause(bool _status) external onlyOwner { paused = _status; }

    // Preflight helper for UI (optional but handy)
    function checkSpendAllowed(address to, uint256 amount)
        external view
        returns (bool ok, string memory reason)
    {
        if (paused) return (false, "paused");
        if (!whitelist[to]) return (false, "not_whitelisted");
        if (spentToday + amount > dailyCap) return (false, "over_cap");
        return (true, "");
    }

    function spend(address to, uint256 amount)
        external onlyOwner resetIfNewDay
    {
        require(!paused, "paused");
        require(whitelist[to], "not_whitelisted");
        require(spentToday + amount <= dailyCap, "over_cap");
        spentToday += amount;
        emit PaymentMade(to, amount); // demo: event only (no token transfer)
    }

    function getRemainingBudget() external view returns (uint256) {
        return dailyCap - spentToday;
    }
}
