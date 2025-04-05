// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Lottery.sol"; // Adjust path as needed
import "forge-std/console.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

// Mock Chainlink VRF Coordinator for testing
contract MockVRFCoordinator is VRFCoordinatorV2Interface {
    uint256 private lastRequestId;
    LotteryVRF private lottery;

    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32,
        uint32
    ) external returns (uint256) {
        lastRequestId++;
        lottery = LotteryVRF(msg.sender);
        return lastRequestId;
    }

    function triggerRandomWords(uint256[] memory randomWords) external {
        if (address(lottery) != address(0)) {
            // Cast to VRFConsumerBaseV2 to call fulfillRandomWords
            VRFConsumerBaseV2(address(lottery)).rawFulfillRandomWords(lastRequestId, randomWords);
        }
    }

    // Implement required interface functions with minimal logic
    function getRequestConfig() external pure returns (uint16, uint32, bytes32[] memory) {
        bytes32[] memory keyhashes = new bytes32[](0);
        return (3, 1000000, keyhashes);
    }

    function createSubscription() external pure returns (uint64) {
        return 1;
    }

    function getSubscription(uint64) external pure returns (
        uint96, uint64, address, address[] memory
    ) {
        address[] memory consumers = new address[](0);
        return (0, 0, address(0), consumers);
    }

    function requestSubscriptionOwnerTransfer(uint64, address) external pure {}
    function acceptSubscriptionOwnerTransfer(uint64) external pure {}
    function addConsumer(uint64, address) external pure {}
    function removeConsumer(uint64, address) external pure {}
    function cancelSubscription(uint64, address) external pure {}
    function pendingRequestExists(uint64) external pure returns (bool) {
        return false;
    }
}

contract LotteryVRFTest is Test {
    LotteryVRF public lottery;
    MockVRFCoordinator public vrfCoordinator;
    
    // Test addresses
    address public alice = address(0x1);
    address public bob = address(0x2);
    address public charlie = address(0x3);
    
    // Test constants
    uint64 public subscriptionId = 1234;
    bytes32 public gasLane = keccak256("test");
    uint32 public callbackGasLimit = 500000;
    uint256 public entranceFee = 0.01 ether;
    uint256 public interval = 5;
    
    function setUp() public {
        // Deploy mock VRF Coordinator
        vrfCoordinator = new MockVRFCoordinator();
        
        // Deploy the lottery contract
        lottery = new LotteryVRF(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId,
            gasLane,
            callbackGasLimit,
            entranceFee,
            interval
        );
        
        // Fund test users
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
    }
    
    function testEnterLottery() public {
        // Enter as Alice
        vm.prank(alice);
        lottery.enterLottery{value: entranceFee}();
        
        // Check player count
        assertEq(lottery.getNumberOfPlayers(), 1);
    }
    
    function testMultiplePlayersEnterLottery() public {
        // Enter as Alice
        vm.prank(alice);
        lottery.enterLottery{value: entranceFee}();
        
        // Enter as Bob
        vm.prank(bob);
        lottery.enterLottery{value: entranceFee}();
        
        // Enter as Charlie
        vm.prank(charlie);
        lottery.enterLottery{value: entranceFee}();
        
        // Check player count
        assertEq(lottery.getNumberOfPlayers(), 3);
        
        // Check player at index 0 is Alice
        assertEq(lottery.getPlayer(0), alice);
        
        // Check player at index 1 is Bob
        assertEq(lottery.getPlayer(1), bob);
        
        // Check player at index 2 is Charlie
        assertEq(lottery.getPlayer(2), charlie);
    }
    
    function testCheckUpkeepReturnsFalseIfNoPlayers() public {
        // Warp time forward past interval
        vm.warp(block.timestamp + 6 minutes);
        
        // Check upkeep
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        
        // Should be false since there are no players
        assertEq(upkeepNeeded, false);
    }
    
    function testCheckUpkeepReturnsFalseIfNotEnoughTimeHasPassed() public {
        // Enter as Alice
        vm.prank(alice);
        lottery.enterLottery{value: entranceFee}();
        
        // Check upkeep without time passing
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        
        // Should be false since not enough time has passed
        assertEq(upkeepNeeded, false);
    }
    
    function testCheckUpkeepReturnsTrueWhenParametersAreGood() public {
        // Enter as Alice
        vm.prank(alice);
        lottery.enterLottery{value: entranceFee}();
        
        // Warp time forward past interval
        vm.warp(block.timestamp + 6 minutes);
        
        // Check upkeep
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        
        // Should be true since we have players, time has passed, and we have ETH
        assertEq(upkeepNeeded, true);
    }
    
    function testPerformUpkeepAndFulfillRandomWords() public {
        // Enter as multiple players
        vm.prank(alice);
        lottery.enterLottery{value: entranceFee}();
        
        vm.prank(bob);
        lottery.enterLottery{value: entranceFee}();
        
        vm.prank(charlie);
        lottery.enterLottery{value: entranceFee}();
        
        // Total balance should be 0.03 ETH
        assertEq(address(lottery).balance, 0.03 ether);
        
        // Record player balances before lottery
        uint256 aliceBalanceBefore = alice.balance;
        uint256 bobBalanceBefore = bob.balance;
        uint256 charlieBalanceBefore = charlie.balance;
        
        // Warp time forward past interval
        vm.warp(block.timestamp + 6 minutes);
        
        // Perform upkeep to request random words
        lottery.performUpkeep("");
        
        // Create a fixed random result that will select the first player (Alice)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 0; // This will select index 0 since 0 % 3 = 0
        
        // Trigger random word fulfillment
        vrfCoordinator.triggerRandomWords(randomWords);
        
        // Check that we have a winner (should be Alice)
        address winner = lottery.getRecentWinner();
        assertEq(winner, alice);
        
        // Check that lottery is reset
        assertEq(lottery.getNumberOfPlayers(), 0);
        assertEq(address(lottery).balance, 0); // All ETH should be paid out
        
        // Check that Alice received the prize
        assertEq(alice.balance, aliceBalanceBefore + 0.03 ether);
        
        // Check that Bob and Charlie balances are unchanged
        assertEq(bob.balance, bobBalanceBefore);
        assertEq(charlie.balance, charlieBalanceBefore);
    }
    
    function testPicksRandomWinner() public {
        // Enter as multiple players
        for (uint i = 0; i < 5; i++) {
            // Create new address
            address player = address(uint160(uint(keccak256(abi.encodePacked(i)))));
            vm.deal(player, 1 ether);
            
            // Enter lottery as this player
            vm.prank(player);
            lottery.enterLottery{value: entranceFee}();
        }
        
        // Warp time forward past interval
        vm.warp(block.timestamp + 6 minutes);
        
        // Perform upkeep to request random words
        lottery.performUpkeep("");
        
        // Create a fixed random result that will select the third player
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 2; // This will select index 2 since 2 % 5 = 2
        
        // Get expected winner
        address expectedWinner = lottery.getPlayer(2);
        uint256 winnerBalanceBefore = expectedWinner.balance;
        
        // Trigger random word fulfillment
        vrfCoordinator.triggerRandomWords(randomWords);
        
        // Check winner is as expected
        address actualWinner = lottery.getRecentWinner();
        assertEq(actualWinner, expectedWinner);
        
        // Check winner received prize
        assertEq(expectedWinner.balance, winnerBalanceBefore + 5 * entranceFee);
    }
}