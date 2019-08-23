pragma solidity ^0.5.1;

contract Auction{
    
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    uint public bidIncrement;
    string public ipfsHash; /*It is expensive to store data in the Ethereum Blockchain, so we will use the
    offchain interplanetary file system (ipfs) to store info about the product, and we will just keep the hash 
    representing that info */
    
    enum State{Started, Running, Ended, Canceled}
    State public AuctionState; 
    
    uint public highestBindingBid;
    address payable public highestBidder;
    
    mapping(address => uint) public bids;
    
    constructor(uint _startBlock, uint _endBlock, string memory _ipfsHash, uint _bidIncrement) public{
        owner = msg.sender;
        AuctionState = State.Running;
        
        startBlock = block.number; //block.number is the block number where the Auction is deployed
        endBlock = startBlock + 40320; //Eth block time is ~15 seconds -> 60*60*24*7/15 = 40320 ~ #of Eth blocks in a week
        ipfsHash = _ipfsHash;
        bidIncrement = _bidIncrement;
    }
    /* These are what we call a function modifier, in Solidity, we use these to avoid writing require
    statements around the entire code, we call these function modifiers in other function's headers, usually
    after the visibility 
    */
    
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }
    
    modifier notOwner(){
        require(owner != msg.sender);
        _;
    }
    
    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }
    
    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }
    
    function cancelAuction() onlyOwner public{
        AuctionState = State.Canceled;
    } 
    
    function placeBid() payable notOwner afterStart beforeEnd public returns(bool){
        require(AuctionState == State.Running);
        require(msg.value > 0.001 ether);
        
        uint currentBid = bids[msg.sender] + msg.value;
        
        require(currentBid > highestBindingBid);
        
        bids[msg.sender] = currentBid;
        
        if(currentBid <= bids[highestBidder]){
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else{
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = msg.sender;
        }
        return true;
    }
    
    //"pure" means that it does not modify the blockchain, so we dont pay gas for using it
    function min(uint a, uint b) private pure returns(uint){
        if(a<=b){
            return a;
        }
        else{
            return b;
        }
    }
    
    function finalizeAuction() public{
        require(AuctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender]>0);
        
        address payable recipient;
        uint value;
        
        if(AuctionState == State.Canceled){
            recipient = msg.sender;
            value = bids[msg.sender];
        }else{
            if(msg.sender == owner){
                recipient = owner;
                value = highestBindingBid;
            }else{
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                }else{
                    recipient = msg.sender;
                    value = bids[msg.sender];
                }
            }
        }
        
        recipient.transfer(value);
    }
    
}