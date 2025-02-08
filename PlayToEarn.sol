// SPDX-License-Identifier: FTM
pragma solidity 0.8.26;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./PlayToEarnNFT.sol";

contract PlayToEarn is
ERC20("Play To Earn", "PTE"),
Ownable(address(0x2c9f3404c42d555c5b766b1f59d6FF24D27f2ecE))
{
    uint256 public constant TOKENS_PER_DAY = 100 * 10**18; // Tokens Per Day "100"
    uint256 public constant REWARD_COOLDOWN = 24 hours; // Cooldown per address
    address public constant PTE_NFT_CONTRACT =
    address(0x3E0ED3704AF4007A41029b07f3284C0D7F6D5328); // PTE NFT Contract

    address[] public addressOnCooldown; // Stores the cooldown address
    mapping(address => uint256) public addressTimestampCooldown; // Stores the timestamp cooldown address

    uint256 public lastCleanupTimestamp; // Timestamp of the last cleanup call

    function rewardTokens(address rewardedWallet) public onlyOwner {
        // Check if 24 hours have passed since last reward
        require(
            block.timestamp >=
            addressTimestampCooldown[rewardedWallet] + REWARD_COOLDOWN,
            "Cannot reward the same wallet within 24 hours"
        );

        // Getting the Play to Earn NFT Contract
        PlayToEarnNFT pteContract = PlayToEarnNFT(PTE_NFT_CONTRACT);

        // Get nft amount
        uint256 balance = pteContract.balanceOf(rewardedWallet);

        // Give tokens for the rewarded wallet
        for (uint256 i = 0; i < balance; i++) {
            _mint(rewardedWallet, TOKENS_PER_DAY);
        }

        // Update the last reward timestamp for the given wallet
        addressTimestampCooldown[rewardedWallet] = block.timestamp;
        addressOnCooldown.push(rewardedWallet);
    }

    function cleanupRewardAddresses() public onlyOwner {
        // Ensure this function is only called once per day
        require(
            block.timestamp >= lastCleanupTimestamp + REWARD_COOLDOWN,
            "Cleanup can only be called once every 24 hours"
        );

        uint256 i = 0;

        // Loop through all addresses on cooldown
        while (true) {
            if (i >= addressOnCooldown.length) break;

            // Get the current address from the cooldown list
            address wallet = addressOnCooldown[i];
            // Get the last reward timestamp of the current address
            uint256 cooldownTime = addressTimestampCooldown[wallet];

            // Check if the cooldown period has passed for the current address
            if (block.timestamp >= cooldownTime + REWARD_COOLDOWN) {
                // Remove it
                delete addressTimestampCooldown[wallet];

                addressOnCooldown[i] = addressOnCooldown[
                    addressOnCooldown.length - 1
                ];
                addressOnCooldown.pop();
            }

            i++;
        }

        // Update the last cleanup timestamp
        lastCleanupTimestamp = block.timestamp;
    }
}
