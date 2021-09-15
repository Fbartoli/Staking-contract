pragma solidity >=0.6.0 <=0.8.7;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}
