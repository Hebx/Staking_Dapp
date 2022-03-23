// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

// External Contract that save old stacked funds
  ExampleExternalContract public exampleExternalContract;

  // Balances of the user's stacked funds
      mapping(address => uint256) public balances;

  // Staking Threshold
     uint256 public constant threshold = 1 ether;

// Staking Deadline
uint256 public deadline = block.timestamp + 72 hours;

// Contract's Event
  event Stake(address indexed sender, uint256 amount);
  event Withdraw(address indexed sender, uint256 amount);

// Modifiers
/*
* @notice Modifiers that require the deadline to be reached
* @param requireReached check if the deadline had reched or not
*/
modifier deadlineReached() {
  uint256 timeRemaining = timeLeft();
    require(timeRemaining == 0, "Deadline is not reached yet");
    _;
}

modifier deadlineRemaining() {
  uint256 timeRemaining = timeLeft();
  require(timeRemaining > 0, "Deadline already reched");
  _;
  }

/*
* @notice Modifier that require the external contract to not be completed
*/
modifier stakeNotCompleted() {
  bool completed = exampleExternalContract.completed();
  require(!completed, "staking process is already completed");
  _;
}

// exampleExternalContractAddress Address of the external contract that will hold stacked fund
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

function execute() public stakeNotCompleted deadlineReached {
  uint256 contractBalance = address(this).balance;

  // check if the contract has enough ETH to reach the threshold
  require(contractBalance >= threshold, "Threshold not reached");
  // Execute the external contract transfer all the balance to the contract
  // (bool sent, bytes memory data) = exampleExternalContract.complete{value: contractBalance}()

  // (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
  // require(sent, "exampleExternalContract.complete failed");

  exampleExternalContract.complete{value: address(this).balance}();
}

// Stake method that update the user's balance
  function stake()  public payable deadlineRemaining stakeNotCompleted {
    // updates the user's balance
    balances[msg.sender] += msg.value;

// notify the blockchain that we have correctly Staked some fund for the user
    emit Stake(msg.sender, msg.value);
  }

/*
* @notice Allow the users to withdraw their balance from the contract only if the deadline is reached but the stake is not complete
 */
  function withdraw(address payable withdrawer) public deadlineReached stakeNotCompleted {
    uint256 amount = balances[withdrawer];

    // check if the user have balance to withdraw
    require(amount > 0, "You don't have balance to withdraw");
    // reset the balance of the user
    balances[msg.sender] = 0;
    // transfer balance back to user
    (bool sent,) = withdrawer.call{value: amount}("");
    require(sent, "Failed to send user balance back to user");
    emit Withdraw(withdrawer, amount);
  }

/*
* @notice the number of seconds remaining until the deadline is reached
 */
 function timeLeft() public view returns (uint256 timeleft) {
   if (block.timestamp >= deadline) {
     return 0;
   } else {
     return deadline - block.timestamp;
   }
 }

}
