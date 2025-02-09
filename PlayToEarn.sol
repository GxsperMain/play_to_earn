// SPDX-License-Identifier: FTM
pragma solidity 0.8.26;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/refs/heads/master/contracts/access/Ownable.sol";
import "https://raw.githubusercontent.com/GxsperMain/play_to_earn/refs/heads/main/PlayToEarnNFT.sol";

contract PlayToEarnCoin is
    ERC20("Play To Earn Coin", "PTE"),
    Ownable(address(0xCC2c9AE7e9E6Cc6Cdf35C2e50d99c4891a1E0A97))
{
    uint256 public tokensPerDay = 100 * 10**18; // Starting Tokens Per Day "100"

    uint256 public constant REWARD_COOLDOWN = 24 hours; // Cooldown per address
    address public constant PTE_NFT_CONTRACT =
        address(0x0a37AA28a0DaF565D2aAa41aeCf5051dB28f9634); // PTE NFT Contract

    uint256 public lastReductionTimestamp; // Reduction Cooldown
    uint256 public constant REDUCTION_COOLDOWN = 24 hours;
    uint256 public constant REDUCTION_RATE = 99995;

    address[] public addressOnCooldown; // Stores the cooldown address
    mapping(address => uint256) public addressTimestampCooldown; // Stores the timestamp cooldown address

    event TokensBurned(address indexed account, uint256 amount); // Burn event
    event RewardClaimed(address indexed account, uint256 amount); // Reward Claimed

    uint256 public lastCleanupTimestamp; // Timestamp of the last cleanup call

    function rewardTokens() public {
        // Getting the Play to Earn NFT Contract
        PlayToEarnNFT pteContract = PlayToEarnNFT(PTE_NFT_CONTRACT);

        // Get nft amount
        uint256 balance = pteContract.balanceOf(msg.sender);

        // No balance
        require(balance > 0, "You must own at least one NFT to claim rewards");

        // Check if 24 hours have passed since last reward
        require(
            block.timestamp >=
                addressTimestampCooldown[msg.sender] + REWARD_COOLDOWN,
            "Cannot reward the same wallet within 24 hours"
        );

        // Apply reduction if 24 hours have passed
        if (block.timestamp >= lastReductionTimestamp + REDUCTION_COOLDOWN) {
            tokensPerDay = (tokensPerDay * REDUCTION_RATE) / 100000; // Reduce by 0.005%
            lastReductionTimestamp = block.timestamp; // Update last reduction time
        }

        // Give tokens for the rewarded wallet
        for (uint256 i = 0; i < balance; i++) {
            _mint(msg.sender, tokensPerDay);
        }

        // Update the last reward timestamp for the given wallet
        addressTimestampCooldown[msg.sender] = block.timestamp;
        addressOnCooldown.push(msg.sender);

        emit RewardClaimed(msg.sender, tokensPerDay);
    }

    function cleanupRewardAddresses() public onlyOwner {
        // Ensure this function is only called once per day
        require(
            block.timestamp >= lastCleanupTimestamp + REWARD_COOLDOWN,
            "Cleanup can only be called once every 24 hours"
        );

        uint256 i = 0;

        // Loop through all addresses on cooldown
        while (i < addressOnCooldown.length) {
            // Get the current address from the cooldown list
            address wallet = addressOnCooldown[i];
            // Get the last reward timestamp of the current address
            uint256 cooldownTime = addressTimestampCooldown[wallet];

            // Check if the cooldown period has passed for the current address
            if (block.timestamp >= cooldownTime + REWARD_COOLDOWN) {
                // Remove it from mapping address
                delete addressTimestampCooldown[wallet];

                // Remove it from array address
                addressOnCooldown[i] = addressOnCooldown[
                    addressOnCooldown.length - 1
                ];
                addressOnCooldown.pop();

                // Reduce the index so it can be read again in this index
                i--;
            }

            i++;
        }

        // Update the last cleanup timestamp
        lastCleanupTimestamp = block.timestamp;
    }

    function burnCoin(uint256 amount) public {
        _burn(msg.sender, amount);
        emit TokensBurned(msg.sender, amount);
    }
}