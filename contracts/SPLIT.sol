pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./SHARE.sol";

interface XRCSPLIT_Interface {
    function viewAccount(uint _token) external view returns(uint,uint,uint);
    function Redeem()external returns(bool);  
    function redeemShard()external returns(string memory);
    function viewAccountTotal() external view returns(uint,uint,uint);
}
contract XRCSPLIT is ERC1155, XRCSPLIT_Interface {
    string public name;
    string public symbol;
    uint public totalSupply;
    uint public shareToken;
    uint public generation;

    uint[] tokenList;
    uint[] tokenCount;
    XRCSHARE public SHARE;
    bool public activated;
    //mappings map Account amounts and micro ledger
    mapping (uint => Tokens) public accounts;
    //Account Details
    struct Tokens{
        uint amount;
        bool exist;
    }
    //launch Contract
    constructor(address payable _shareContract)ERC1155("{name:SPLIT, token:{id}}") { 
        SHARE = XRCSHARE(payable(_shareContract));

        name= SHARE.name();
        symbol= SHARE.symbol();
        totalSupply = SHARE.totalSupply();
        generation = SHARE.generation()+1;
        
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
    function activateContract(uint _share) public returns(bool){
        require(SHARE.balanceOf(msg.sender,_share) == 1, "you must hold share token");
        require(SHARE.isApprovedForAll(msg.sender,address(this))==true,"isApprovedForAll on SHARE contract is false must equal true");
        require(activated == false, " contract already activated");

        shareToken = _share;
        SHARE.safeTransferFrom(msg.sender, address(this), _share,1,"");
        
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            accounts[tokens] = Tokens(0,true);
            _mint(msg.sender,tokens, 1, "");
        }
        activated = true;
        return true;
    }
    //Account of your funds in contract
    function viewAccount(uint _token) public view returns(uint,uint,uint){
        require(_token<=totalSupply-1,"incorrect token number");
        uint total = accounts[_token].amount + (SHARE.viewAccount(shareToken)/totalSupply);
        return (accounts[_token].amount,SHARE.viewAccount(shareToken)/totalSupply,total);
    }
    // view total of all token yeild in account 
    function viewAccountTotal() public view returns(uint,uint,uint){
        uint total =0;
        uint totalFromSource=0;
        for(uint count =0;count<=totalSupply-1;count++){
            if(balanceOf(msg.sender,count)== 1){
                total += accounts[count].amount;
                totalFromSource += (SHARE.viewAccount(shareToken)/totalSupply);
            }
        }
        return (total,totalFromSource,total+totalFromSource);
    }

    //Redeem Dividends from treasury
    function Redeem()public TokenHolder returns(bool){
        //Call Original share contract
        SHARE.redeem();
        address payable RedeemAddress = payable(msg.sender);
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += accounts[tokens].amount;
                accounts[tokens].amount = 0;
            }
        }    
        RedeemAddress.call{value: total}("");     
        return true;     
    }
    function redeemShard()public TokenHolder returns(string memory){
        require(SHARE.balanceOf(address(this),shareToken) == 1, "contract not activated");
        require(checkAllTokens() == true,"you must hold all splits");

        _burnBatch(msg.sender, tokenList,tokenCount);
        SHARE.safeTransferFrom(address(this),msg.sender,shareToken, 1, "");
        activated = false;
        return "redeeming SHARE from SPLIT Treasury";

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