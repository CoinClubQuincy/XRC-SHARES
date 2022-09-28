pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./XRC100.sol";

interface XRC101_Interface {
    function View_Account(uint _token) external view returns(uint,uint,uint);
    function Redeem()external returns(bool);  
    function RedeemShard()external returns(string memory);
}
contract XRC101 is ERC1155, XRC101_Interface {
    string public name;
    string public symbol;
    uint public totalSupply;
    uint public shardToken;
    uint public generation;

    uint[] tokenList;
    uint[] tokenCount;
    XRC100 public SHARD;
    bool public activated;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
    }
    //launch Contract
    constructor(address payable _shardContract)ERC1155("{name:SPLIT, token:{id}}") { 
        SHARD = XRC100(payable(_shardContract));
        name= SHARD.name();
        symbol= SHARD.symbol();
        totalSupply = SHARD.totalSupply();
        generation = SHARD.generation()+1;
        
        for(uint count=0;count<=totalSupply-1;count++){
            tokenList.push(count);
            tokenCount.push(1);
        }
    }
    //Only Token Holders can use contract
    modifier TokenHolder{
        require(checkTokens()== true, "only token holders can access");
        _;
    }
    function checkTokens()internal view returns(bool){
        uint token;
        for(token=0;token <= totalSupply-1;token++){
            if(balanceOf(msg.sender,token) == 1){
                return true;
            }
        }
        return false;
    }
    //Accept payment from CoinBank and issue dividends to accounts
    function callFromFallback(uint _singleShard)internal{
        uint CurrentCount=0;
        //Fix Gas ploblem
        for(CurrentCount;CurrentCount<=totalSupply-1;CurrentCount++){
            accounts[CurrentCount].amount +=  _singleShard;
        }
    }
    function activateContract(uint _shard) public returns(bool){
        require(SHARD.balanceOf(msg.sender,_shard) == 1, "you must hold shard token");
        require(SHARD.isApprovedForAll(msg.sender,address(this))==true,"isApprovedForAll on SHARD contract is false must equal true");
        require(activated == false, " contract already activated");

        shardToken = _shard;
        SHARD.safeTransferFrom(msg.sender, address(this), _shard,1,"");
        
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            _mint(msg.sender,tokens, 1, "");
        }
        activated = true;
        return true;
    }
    //Account of your funds in contract
    function View_Account(uint _token) public view returns(uint,uint,uint){
        require(_token<=totalSupply-1,"incorrect token number");
        uint total = accounts[_token].amount + (SHARD.View_Account(shardToken)/totalSupply);
        return (accounts[_token].amount,SHARD.View_Account(shardToken)/totalSupply,total);
    }
    //Redeem Dividends from treasury
    function Redeem()public TokenHolder returns(bool){
        //Call Original shard contract
        address payable RedeemAddress = payable(msg.sender);
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += accounts[tokens].amount;
                accounts[tokens].amount = 0;
            }
        }    
        RedeemAddress.transfer(total);    
        return true;     
    }
    function redeemPush() public returns(bool){
        SHARD.Redeem();
        return true;
    }
    function RedeemShard()public TokenHolder returns(string memory){
        require(SHARD.balanceOf(address(this),shardToken) == 1, "contract not activated");
        require(checkAllTokens() == true,"you must hold all splits");

        _burnBatch(msg.sender, tokenList,tokenCount);
        SHARD.safeTransferFrom(address(this),msg.sender,shardToken, 1, "");
        activated = false;
        return "redeeming SHARD from SPLIT Treasury";

    }
    function checkAllTokens()internal view returns(bool){
        for(uint count=0;count<=totalSupply-1;count++){
            if(balanceOf(msg.sender, count) == 1){  
                count++;
            } else{
                return false;
            }
        }
        return true;
    }
    //ERC1155Received fuctions
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
    //Payments made to the contract
    receive() external payable {
        uint single_Shard = msg.value/totalSupply;
        callFromFallback(single_Shard); 
    }
}