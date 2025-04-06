// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {LotteryVRF} from "../src/lottery.sol";
import "@chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";

contract CounterScript is Script {
    LotteryVRF public lottery;
    uint64 public subscriptionId = 1234;
    bytes32 public gasLane = keccak256("test");
    uint32 public callbackGasLimit = 500000;
    uint256 public entranceFee = 0.001 ether;
    uint256 public interval = 5;


    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        lottery = new LotteryVRF(
            0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            subscriptionId,
            gasLane,
            callbackGasLimit,
            entranceFee,
            interval

        );

        vm.stopBroadcast();
    }
}
