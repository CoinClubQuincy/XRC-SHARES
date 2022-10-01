pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface XRCSHARD_Interface {
    function viewAccount(uint _token) external view returns(uint);
    function redeem()external returns(bool); 
    function viewAccountTotal() external view returns(uint);            
}

/// @title SHARD Dividend Yeilding Token
/// @author Quincy Jones (https://github.com/CoinClubQuincy)
/// @dev a NFT that represents pices of a DApp
///  SHARD holders are able to redeem dividends from the acociated SHARD token account within the cntract
contract XRCSHARD is ERC1155, XRCSHARD_Interface {
    string public name;
    string public symbol;
    uint public totalSupply;

    //generations are counted in XRC101 contracts to represent
    // what the dilution of the token may be
    uint public generation = 0;
    
    // Each SHARD has an account within the contract
    // each account stores all the alocated funds to the appropriate token
    mapping (uint => Tokens) public accounts;
    // About Tokens struct
    // Account Details of SHARD token
    // Each account can be redeemd by its coresponding token
    struct Tokens{
        uint amount;
        bool exist;
    }
    
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

    /// @notice checks to see if holder holds any SHARDS
    /// @return status of wheather the holder possess the token
    function checkTokens()internal view returns(bool){
        uint token;
        for(token=0;token <= totalSupply-1;token++){
            if(balanceOf(msg.sender,token) == 1){
                return true;
            }
        }
        return false;
    }

    function callFromFallback(uint _singleShard)internal{
        uint CurrentCount=0;
        for(CurrentCount;CurrentCount<=totalSupply-1;CurrentCount++){
            accounts[CurrentCount].amount +=  _singleShard;
        }
    }
    //Account of your funds in contract
    function viewAccount(uint _token) public view returns(uint){
        require(_token<=totalSupply-1,"incorrect token number");
        return accounts[_token].amount;
    }
    function viewAccountTotal() public view returns(uint){
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += viewAccount(tokens);
            }
        }       
        return total;
    }
    //redeem Dividends from treasury
    function redeem()public TokenHolder returns(bool){
        address payable redeemAddress = payable(msg.sender);
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += accounts[tokens].amount;
                accounts[tokens].amount = 0;
            }
        }    
        redeemAddress.call{value: total}("");    
        return true;     
    }
    //Payments made to the contract
    receive() external payable {
        uint single_Shard = msg.value/totalSupply;
        callFromFallback(single_Shard); 
    }
}
