pragma solidity ^0.5.1;

contract Lottery{
    
    /* Since multiple players will be able to enter the lottery, we will create a dynamic array of addresses where
    each address represents a players that takes part in the lottery, it is important that the addresses are payable
    if the version of solidity we are using is 0.5 or higher.
    */
    address payable[] public players;
    address public manager; //The person that decides when the winner is decided
    
    constructor () public{
        manager = msg.sender;
    }
    
    /* In this fallback payable function the address of the player that sends ether to the contract is stored in our array
    What the require statement does is if the condition is not met, no more code in the function is executed 
    */
    function () payable external{
        require(msg.value >= 0.01 ether);
        players.push(msg.sender);
    }
    
    //The balance is something that only the admin can see, hence the require statement below
    function get_balance() public view returns (uint){
        require(msg.sender == manager);
        return address(this).balance;
    }
    
    /* Solidity does not have a built in random function so this is an attempt to get a random number, it is not a
    random number since a malicious miner can know the block difficulty and block timestamp in advances and could somehow
    exploit the function, but for the purposes of this program it's enough. It uses the keccak256 hash function to create a
    hash using those 4 values and then we return the casted uint256 of that hash 
    */
    function random() public view returns (uint256){
        uint256 randomnumber = uint256(keccak256(abi.encodePacked(now, players.length, block.difficulty, block.timestamp)));
        return randomnumber;
    }
    
    function selectWinner () public returns(address){
        require(msg.sender == manager);
        
        uint r = random();
        
        //Important to declare this variable as payable
        address payable winner;
        
        uint index = r % players.length;
        winner = players[index];
        
        winner.transfer(address(this).balance);
        
        //After assigning a winner, we reinitialize the lottery by clearing the array of addresses
        players = new address payable[](0);
        
        return winner;
    }
}