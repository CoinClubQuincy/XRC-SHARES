pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

interface XRCSHARE_Interface {
    function viewAccount(uint _token) external view returns(uint);
    function redeem()external returns(bool); 
    function viewAccountTotal() external view returns(uint);            
}

/// @title SHARE Dividend Yeilding Token
/// @author Quincy Jones (https://github.com/CoinClubQuincy)
/// @dev a NFT that represents pices of a DApp
///  SHARE holders are able to redeem dividends from the acociated SHARE token account within the cntract
contract XRCSHARE is ERC1155, XRCSHARE_Interface {
    string public name;
    string public symbol;
    uint public totalSupply;

    //generations are counted in XRC101 contracts to represent
    // what the dilution of the token may be
    uint public generation = 0;
    
    // Each SHARE earns the same amount, so one running total covers every token.
    // A payment costs the same however many SHARES exist.
    uint public perShareAccrued = 0;
    // The part of past payments too small to divide across all SHARES yet
    uint public remainder = 0;
    // How much of the running total each token has already been paid
    mapping (uint => uint) private claimed;

    constructor(string memory _name,string memory _symbol,uint _totalSupply,string memory URI) ERC1155(URI) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        
        require(totalSupply>0, "at least one share is required");
        require(totalSupply<=1000, "at most 1000 shares are allowed");
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            _mint(msg.sender,tokens, 1, "");
        }
    }
    //Only Token Holders can use contract
    modifier TokenHolder{
        require(checkTokens()== true, "only token holders can access");
        _;
    }

    /// @notice checks to see if holder holds any SHARES
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

    //credits a payment to every SHARE, carrying what doesnt divide evenly into the next one
    function creditPayment(uint _amount)internal{
        uint total = _amount + remainder;
        perShareAccrued += total/totalSupply;
        remainder = total%totalSupply;
    }
    //Account of your funds in contract
    function viewAccount(uint _token) public view returns(uint){
        require(_token<=totalSupply-1,"incorrect token number");
        return perShareAccrued - claimed[_token];
    }
    /// @notice the unclaimed funds of a SHARE, and whether that SHARE exists
    function accounts(uint _token) public view returns(uint amount,bool exist){
        if(_token >= totalSupply){
            return (0,false);
        }
        return (perShareAccrued - claimed[_token],true);
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
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += perShareAccrued - claimed[tokens];
                claimed[tokens] = perShareAccrued;
            }
        }
        if(total > 0){
            (bool success, ) = payable(msg.sender).call{value: total}("");
            require(success, "payment failed");
        }
        return true;
    }
    //developers can use this function in thier contracts
    // to redirect funds from a function to the share holders.
    // only pass value this contract actually received, or redeems will run out of funds
    function redirectValue(uint _msgValue) internal returns(bool){
        creditPayment(_msgValue);
        return true;
    }
    //Payments made to the contract
    receive() external payable {
        creditPayment(msg.value);
    }
}