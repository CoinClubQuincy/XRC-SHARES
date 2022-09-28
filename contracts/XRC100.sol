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
    uint public generation = 0;
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
    function View_Total() public view returns(uint){
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += View_Account(tokens);
            }
        }       
        return total;
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
