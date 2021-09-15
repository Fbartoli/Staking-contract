pragma solidity >=0.6.0 <=0.8.7;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol"; //https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol

contract Staker {

  mapping (address => uint) public balances;
  uint public constant threshold = 1 ether;
  uint public deadline;
  ExampleExternalContract public exampleExternalContract;

  event Stake (address indexed, uint amount);

  /**
  * @notice Contract Constructor
  * @param exampleExternalContractAddress Address of the external contract that will hold stacked funds
  */
  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    deadline = block.timestamp + 30 minutes;
  }

  /**
  * @notice modifier to check the if the external contract public variable is true
  */
  modifier stakeNotCompleted () {
    require(!exampleExternalContract.completed(), "Contract already completed");
    _;
  }

    /**
  * @notice Modifier that require the deadline to be reached or not
  * @param requireReached Check if the deadline has reached or not
  */
  modifier deadlineReached( bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }

  /**
  * @notice Stake method that update the user's balance
  */
  function stake() public payable deadlineReached(false) stakeNotCompleted {
    require (msg.value >= 0, "An amount is needed");
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public deadlineReached(true) stakeNotCompleted {
    require(address(this).balance >= threshold, "Threshold not reached");
    (bool sent, ) = address(exampleExternalContract).call{value:address(this).balance}(abi.encodeWithSignature("complete()"));
    require(sent, "Transfer to external contract failed");
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  /**
  * @notice Allow users to withdraw their balance from the contract only if deadline is reached but the stake is not completed
  */
  function withdraw() public deadlineReached(true) stakeNotCompleted {
    uint userFund = balances[msg.sender];
    require(userFund > 0, "You didn't deposit fund");

    balances[msg.sender] = 0;

    (bool sent, ) = msg.sender.call{value: userFund}("");
    require(sent, "Failed to send the balance back to the user");
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  /**
  * @notice public method to check the remaining time
  */
  function timeLeft() public view returns(uint timeleft) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

}
