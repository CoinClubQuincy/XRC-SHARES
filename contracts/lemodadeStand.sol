contract lemonadeStand is XRCSHARE{
    uint public lemonadeCount =0;
    constructor(string  memory _name,string  memory _symbol,uint _totalSupply) XRCSHARE(_name,_symbol,_totalSupply){}
    
    function GlassOfLemonade()  public  payable  returns(bool){
        require(msg.value >=  10000000000000000000,"need more funds");
        lemonadeCount++;
        //this call can be used in all functions that recive fees
        redirectValue(msg.value);
        return  true;
    }
}
