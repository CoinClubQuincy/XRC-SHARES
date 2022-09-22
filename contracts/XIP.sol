pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface XRC100_Interface {
    function View_Account(uint _token) external view returns(uint);
    function Redeem()external returns(bool);             
}
contract XRC100 is ERC1155, XRC100_Interface {
    string public name;
    string public symbol;
    uint public totalSupply;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
        bool exist;
    }
    //launch Contract
    constructor(string memory _name,string memory _symbol,uint _totalSupply) ERC1155("{name:SHARD, token:{id}}") {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        
        require(totalSupply<=1000);
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            accounts[tokens] = Tokens(0,true);
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
        for(CurrentCount;CurrentCount<=totalSupply-1;CurrentCount++){
            accounts[CurrentCount].amount +=  _singleShard;
        }
    }
    //Account of your funds in contract
    function View_Account(uint _token) public view returns(uint){
        require(_token<=totalSupply-1,"incorrect token number");
        return accounts[_token].amount;
    }
    //Redeem Dividends from treasury
    function Redeem()public TokenHolder returns(bool){
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
    //Payments made to the contract
    receive() external payable {
        uint single_Shard = msg.value/totalSupply;
        callFromFallback(single_Shard); 
    }
}

interface XRC101_Interface {
    function View_Account(uint _token) external view returns(uint);
    function Redeem()external returns(bool);  
    function RedeemShard()external returns(bool);
}
contract XRC101 is ERC1155, XRC100_Interface {
    uint public totalSupply;
    uint public shardToken;
    XRC100 public SHARD;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
    }
    //launch Contract
    constructor(address payable _shardContract,uint _shard) ERC1155("{name:SPLIT, token:{id}}") { 
        require(balanceOf(msg.sender,_shard) == 1,"must hold shard to start contract");

        shardToken = _shard;
        SHARD = XRC100(_shardContract);
        totalSupply = SHARD.totalSupply();
        
        safeTransferFrom(msg.sender, address(this), _shard, 1, "");
  
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
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
    //Account of your funds in contract
    function View_Account(uint _token) public view returns(uint){
        require(_token<=totalSupply-1,"incorrect token number");
        uint total = accounts[_token].amount + (SHARD.View_Account(shardToken)/totalSupply);
        return total;
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
    function RedeemShard()public TokenHolder returns(bool,bool){
        if(checkAllTokens() == true){
            safeTransferFrom(address(this),msg.sender,shardToken, 1, "");
            return (true,true);
        }
        SHARD.Redeem();
        return (true,false);
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

