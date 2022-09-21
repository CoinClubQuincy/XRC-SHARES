pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface XRC100_Interface {
    function View_Account(uint _token) external view returns(uint);
    function Redeem()external returns(bool);             
}
contract XRC100 is ERC1155, XRC100_Interface {
    uint public totalSupply;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
    }
    //launch Contract
    constructor(string memory URI,uint _totalSupply) ERC1155(URI) {
        totalSupply = _totalSupply;
        require(totalSupply<=1000);
        for(uint tokens=0;tokens<=totalSupply;tokens++){
            _mint(msg.sender,tokens, 1, "");
        }
    }
    //Only Token Holders can use contract
    modifier TokenHolder{
        require(checkTokens()== true, "only token holders can access");
        _;
    }
    function checkTokens()internal view returns(bool){
        uint token;
        for(token=0;token <= totalSupply;token++){
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
        for(CurrentCount;CurrentCount<totalSupply;CurrentCount++){
            InternalAccounting(CurrentCount,_singleShard);
        }
    }
    //Sorts funds into accounts
    function InternalAccounting(uint _shard,uint _singleShard)internal returns(uint){
        accounts[_shard].amount +=  _singleShard;
        return (_shard);      
    }
    //Account of your funds in contract
    function View_Account(uint _token) public view returns(uint){
        require(_token<=totalSupply,"incorrect token number");
        return accounts[_token].amount;
    }
    //Redeem Dividends from treasury
    function Redeem()public TokenHolder returns(bool){
        address payable RedeemAddress = payable(msg.sender);
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += accounts[tokens].amount;
                accounts[tokens].amount = 0;
            }
        }    
        RedeemAddress.transfer(total);    
        return true;     
    }
    //Payments made to the contract
    receive() external payable {
        uint single_Shard = msg.value/totalSupply;
        callFromFallback(single_Shard); 
    }
}

contract XRC101 is ERC1155, XRC100_Interface {
    uint public totalSupply;
    XRC100 SHARD;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
    }
    //launch Contract
    constructor(string memory URI,address payable _shardContract,uint _shard) ERC1155(URI) { 
        SHARD = XRC100(_shardContract);
        totalSupply = SHARD.totalSupply;
        require(balanceOf(msg.sender,_shard) == 1,"must hold shard to start contract");
        safeTransferFrom(msg.sender, address(this), _shard, 1, "");
  
        for(uint tokens=0;tokens<=totalSupply;tokens++){
            _mint(msg.sender,tokens, 1, "");
        }
    }
    //Only Token Holders can use contract
    modifier TokenHolder{
        require(checkTokens()== true, "only token holders can access");
        _;
    }
    function checkTokens()internal view returns(bool){
        uint token;
        for(token=0;token <= totalSupply;token++){
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
        for(CurrentCount;CurrentCount<totalSupply;CurrentCount++){
            InternalAccounting(CurrentCount,_singleShard);
        }
    }
    //Sorts funds into accounts
    function InternalAccounting(uint _shard,uint _singleShard)internal returns(uint){
        accounts[_shard].amount +=  _singleShard;
        return (_shard);      
    }
    //Account of your funds in contract
    function View_Account(uint _token) public view returns(uint){
        require(_token<=totalSupply,"incorrect token number");
        return accounts[_token].amount;
    }
    //Redeem Dividends from treasury
    function Redeem()public TokenHolder returns(bool){
        //Call Original shard contract
        address payable RedeemAddress = payable(msg.sender);
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += accounts[tokens].amount;
                accounts[tokens].amount = 0;
            }
        }    
        RedeemAddress.transfer(total);    
        return true;     
    }
    
    function RedeemShard()public TokenHolder returns(bool){}

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

