

## A New Type of Token: SHARDS & SPLITS

  

Most are familiar with NFTs as decentralized Objects that show ownership of an item or keep a unit of account of an Item. NFTs can be a representative of anything, even a DApp. Today I made a proposal to the XDC-Community [XIP Proposal](https://github.com/XDC-Community/XIPs.github.io) to standardize a new type of token — the SHARD. A SHARD is an NFT that represents ownership over a DApp and will take the incoming funds and distribute them among the token holders. Developers can also use these NFTs within their application to give the SHARDS governance capabilities, like access control and voting rights, by defining the tokens in the code itself.

  

There are 2 types of SHARDS — SHARDS and SPLITS. A SHARD acts as a share of a DApp that receives the dividends based on its performance while a SPLIT is a Share of a SHARD and receives the yield of the original SHARD while splitting the dividends again amongst a set of derivative token holders.

  

SHARDs are not a crypto currency but a native crypto asset to a native crypto application. The Performance and relative value of the SHARD is predicated on the growth and use of the DApp and the accumulated fees that act as a yield for the Token holders.

  

SHARDS Attributes:

-   A DApp can have a max of 1000 SHARDS.
    
-   Each SHARD has its own account in the contract, and the holder of the token can redeem any yield from that token’s account.
    

  

SPLIT Attributes:

-   SPLITS have the same amount of splits per SHARD as the SHARD has shards.
    
-   A SPLIT is a uniform contract and doesn't have any additional functions. A SPLIT of the same generation maintains equal value even if it comes from a different SHARD in the same SHARDS contract.
    

  

Example of a DApp with SHARDS:

![](https://lh3.googleusercontent.com/jSqdOe-TX-_rW14iQGtvVtMnFcqSH2gLu6tpGR4nkkoJ6P1ERWKneu8PtbK6Hhf3Y_XUTajZO49KJGA4NsOCjleVtgOJz5Dm1gqoTqCCbkdN_q1ppW0_0qxwa0FUsP1wzQ6c_VcRwPHVcosH0e2wrCTvWZ8K5sodMtkhn-vtpNmLZRt2HD59B41dWg)

 All function within contract can use this line of code at the bottom of their function to forward funds to the **receive()** function to allocate funds.
````solidity
address(this).call{value: msg.value}; //this will forward all funds to the receive() function
````
This contract bellow is an example of a lemonade stand contract that receives 100XDC for a glass of lemonade and divides those funds amongst 10 token holders

````solidity
contract lemonadeStand is XRC100{
	constructor(string  memory _name,string  memory _symbol,uint _totalSupply) XRC100(_name,_symbol,_totalSupply){}

	function GlassOfLemonade()  public  payable  returns(bool){
	    require(msg.value ==  100000000000000000000,"need more funds");

	    //this call can be used in all functions that recive fees
	    address(this).call{value:  msg.value};  
	    return  true;
	}
}
````

SHARDS (XRC100) & SPLITS (XRC101) allow Developers to sell portions of their DApps by allowing a simple means of retrieving profitable applications that reside on the XDC Network while investors can invest in the DApp, helping to grow its user base while being attributed dividends. The value of the Tokens are based on the performance of the DApp. Any DApp, no matter how big or small, can have SHARDS to allocate profits and sell stake in the DApp.

  

SPLITS are a uniform contract to split SHARD tokens into smaller dividend tokens that redeem and split the dividends allocated to that associated Token provided to the SPLIT contract. A SPLIT is functionally identical to a SHARD except a SPLIT can only represent split ownership of a SHARD, whereas a SHARD represents equitable ownership in the DApp. If a DApp uses the SHARD tokens as governance tokens or in some form of automation, SPLITS cannot participate. SPLITS only redeem dividends from the SHARD that's been split.

  

SPLITS can be broken up into generations (as referenced in the example above). The original SHARD stands as Generation 0 while the first SPLIT is generation 1. Each generation's SPLIT is equal in value to all SPLITS in that same generation.

  

SPLIT generations allow for SHARDS to be divided up indefinitely. If a DApp has 1000 SHARDs, each SHARD’s SPLIT must have the same number of SPLITS as the total SHARDS. So each SHARD will be split 1000 times. The first generation of SPLITS will have a maximum of 1M SPLITS and 1000 SPLITS per SHARD.A second generation SPLIT will have a max of 1B SPLITS and1000 SPLITS per generation 1 SPLIT, and a Trillion SPLITS for generation 3.

### How DApps Can Use SHARDS

DApps can use SHARDS in a few different ways:

  

-   DApps can be built with SHARDS to allow for dividend allocation in these DApps.
    
-   Developers can also build more smart contracts after the fact, which can offer more functionality and consolidate the profits from the new DApps into the original SHARD contract.
    
-   Third party developers can also do this to add functionality and increase the Yield for the SHARDS by creating new functions.
    
-   Developers can also create abstract single function contracts [ex: polling DApp, analysis DApp, TAx DApp] called DApplets — isolated DApps that aren't typically user facing and may allow functionality to other smart contracts that can hold SHARDS and justify profitability from otherwise abstract functions.
    
-   SHARDS are a direct means of having developers sell portions of their products no matter how big or small to help fund their future products
    
-   inventors can own DApps similar to how they own companies
    

  

Currently, crypto currencies are the primary market on blockchain. However, as more DApps have various means of ownership over the DApp, new markets will arise that are centered around the popularity and growth of DApps on the network. As DApps incestuously interconnect with each secondary DApp that relies on Dependency functions from the primary DApp, the secondary DApps become popular and profitable as do the primary DApps. The SHARD holders of both are able to gain fees on the usage of their contract.

  

SHARDs are built to be DApps, the standard for XDC applications to allow DApps to distribute incoming funds amongst a set of token holders who hold them as ownership of the DApp and its dividends. This allows Developers, investors, and DApp users to easily sell and invest in DApps of all sizes getting user growth, similar to how companies operate in traditional economies. The only difference is that the DApp is autonomous, the dividends are autonomous, and anyone can own a piece of any DApp.

  

The XRC-SHARD & XRC-SPLITS contracts have been submitted to be approved as an official standard on the XDC Network. To comment on the process or the contracts, check out the [XDC-Community](https://github.com/XDC-Community/XIPs.github.io) Github to participate in the XDC XIP process.


## Security Considerations
**WARNING: Lost SHARDS will result in the portion of funds allocated to the token to also be lost**


  
