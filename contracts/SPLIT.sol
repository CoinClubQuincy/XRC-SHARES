pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./SHARE.sol";

interface XRCSPLIT_Interface {
    function viewAccount(uint _token) external view returns(uint,uint,uint);
    function redeem()external returns(bool);  
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
    // Each split earns the same amount, so one running total covers every token.
    uint public perShareAccrued = 0;
    // The part of past payments too small to divide across all splits yet
    uint public remainder = 0;
    // How much of the running total each split has already been paid
    mapping (uint => uint) private claimed;

    //launch Contract
    constructor(address payable _shareContract,string memory URI)ERC1155(URI) { 
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
    //credits a payment to every split, carrying what doesnt divide evenly into the next one
    function creditPayment(uint _amount)internal{
        uint total = _amount + remainder;
        perShareAccrued += total/totalSupply;
        remainder = total%totalSupply;
    }
    //What the source still owes this contract. A source may be a SHARE, whose viewAccount
    //returns one value, or another SPLIT, which returns three with the total last.
    function sourcePending()internal view returns(uint){
        if(activated == false){
            return 0;
        }
        (bool success, bytes memory data) = address(SHARE).staticcall(abi.encodeWithSignature("viewAccount(uint256)",shareToken));
        require(success, "source account could not be read");
        if(data.length == 96){
            (, , uint total) = abi.decode(data,(uint,uint,uint));
            return total;
        }
        return abi.decode(data,(uint));
    }
    //What one split would receive if the source were paid out now
    function sourcePerSplit()internal view returns(uint){
        return (sourcePending()+remainder)/totalSupply;
    }
    function activateContract(uint _share) public returns(bool){
        require(SHARE.balanceOf(msg.sender,_share) == 1, "you must hold share token");
        require(SHARE.isApprovedForAll(msg.sender,address(this))==true,"isApprovedForAll on SHARE contract is false must equal true");
        require(activated == false, " contract already activated");
        
        shareToken = _share;
        activated = true;
        SHARE.safeTransferFrom(msg.sender, address(this), _share,1,"");
        //redeemShard already paid everything out, so a new round of splits starts level
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            _mint(msg.sender,tokens, 1, "");
        }
        return true;
    }
    //Account of your funds in contract
    function viewAccount(uint _token) public view returns(uint,uint,uint){
        require(_token<=totalSupply-1,"incorrect token number");
        uint own = activated ? perShareAccrued - claimed[_token] : 0;
        uint fromSource = sourcePerSplit();
        return (own,fromSource,own+fromSource);
    }
    /// @notice the unclaimed funds held here for a split, and whether that split exists
    function accounts(uint _token) public view returns(uint amount,bool exist){
        if(activated == false || _token >= totalSupply){
            return (0,false);
        }
        return (perShareAccrued - claimed[_token],true);
    }
    // view total of all token yeild in account 
    function viewAccountTotal() public view returns(uint,uint,uint){
        uint total =0;
        uint totalFromSource=0;
        uint fromSource = sourcePerSplit();
        for(uint count =0;count<=totalSupply-1;count++){
            if(balanceOf(msg.sender,count)== 1){
                total += perShareAccrued - claimed[count];
                totalFromSource += fromSource;
            }
        }
        return (total,totalFromSource,total+totalFromSource);
    }

    //Redeem Dividends from treasury
    function redeem()public TokenHolder returns(bool){
        //Call Original share contract, which pays into receive below
        SHARE.redeem();
        uint total=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            if(balanceOf(msg.sender,tokens) == 1){
                total += perShareAccrued - claimed[tokens];
                claimed[tokens] = perShareAccrued;
            }
        }
        pay(total);
        return true;
    }
    //Burns all the splits and returns the SHARE. The holder owns every split, so they also
    //receive everything the splits earned, including what was too small to divide.
    function redeemShard()public TokenHolder returns(string memory){
        require(activated == true, "contract not activated");
        require(checkAllTokens() == true,"you must hold all splits");
        SHARE.redeem();

        uint total=remainder;
        remainder=0;
        for(uint tokens=0;tokens<=totalSupply-1;tokens++){
            total += perShareAccrued - claimed[tokens];
            claimed[tokens] = perShareAccrued;
        }
        _burnBatch(msg.sender, tokenList,tokenCount);
        activated = false;
        SHARE.safeTransferFrom(address(this),msg.sender,shareToken, 1, "");
        pay(total);
        return "redeeming SHARE from SPLIT Treasury";
    }
    function pay(uint _amount)internal{
        if(_amount > 0){
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "payment failed");
        }
    }
    function checkAllTokens()internal view returns(bool){
        for(uint count=0;count<=totalSupply-1;count++){
            if(balanceOf(msg.sender, count) != 1){
                return false;
            }
        }
        return true;
    }
    //Accepts only the SHARE being taken in by activateContract, so nothing else can get stuck here
    function onERC1155Received(address, address, uint256 _id, uint256, bytes memory) public virtual returns (bytes4) {
        require(activated == true && msg.sender == address(SHARE) && _id == shareToken, "use activateContract");
        return this.onERC1155Received.selector;
    }
    //Payments made to the contract
    receive() external payable {
        require(activated == true, "contract not activated");
        creditPayment(msg.value);
    }
}