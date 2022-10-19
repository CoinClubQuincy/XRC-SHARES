# **Tokenizing DApps & Contracts: SHARES & SPLITS**

  

Most people are familiar with NFTs as decentralized objects that show ownership of an item or keep a unit of account. An NFT can represent literally anything, even a decentralized application (DApp).

  

I recently made a proposal to the XDC Community ([XIP Proposal](https://github.com/XDC-Community/XIPs.github.io)) to standardize a new type of token — the SHARE. A SHARE is an NFT that represents ownership over a DApp and will take the incoming funds and distribute them among the token holders. Developers can also use these NFTs within their application to give the SHARES governance capabilities, such as access control and voting rights, by defining the tokens in the code itself.

  

There are 2 types of SHARES — SHARES and SPLITS. A SHARE acts as a share of a DApp that receives the dividends based on its performance while a SPLIT is a share of a SHARE, receiving the yield of the original SHARE while splitting the dividends again amongst a set of derivative token holders.

  

SHARES are not a crypto currency but a native crypto asset to a crypto application. The performance and relative value of the SHARE is predicated on the growth and use of the DApp and the accumulated fees that are dispersed among the token holders.

  

**_SHARES Attributes:_**

-   A DApp can have a max of 1,000 SHARES.
    
-   Each SHARE has its own account in the contract, and the holder of the SHARE can redeem any yield from that token’s account.
    

  

_**SPLIT Attributes:**_

-   SPLITS have the same amount of splits per SHARE as the SHARE has total SHARES.
    
-   A SPLIT is a uniform contract and doesn't have any additional functions but redeem value from the deriving SHARE.
    
-   A SPLIT of the same generation maintains equal value even if it comes from a different SHARE in the same SHARES contract.
    

  

**Example of a DApp with SHARES:**

![](https://lh5.googleusercontent.com/VGAhLfodKDyz8KcP-dNBAU9gWEjBnsewnF3C2ZlpdO2TuJ6rzV6iAy95PXsZEvDi_G3rFs8bM2byNLrnJaGO9fDNxVbs2_FWHZLn1_OUf3HuAFLu1an4qOd-EVgnWL0eYMGrDBR67mNN0ApIlfRWXSgIa7U9tp3p8FGvq7Z_co6T2uCUk8EN48HUoQ)

  

GitHub: [https://github.com/CoinClubQuincy/XRC-SHARES](https://github.com/CoinClubQuincy/XRC-SHARDS)

  All function within contract can use this line of code at the bottom of their function to forward funds to the receiving function to allocate funds.
```solidity
redirectValue(msg.value); //this will forward all funds to share token treasury
```
This contract bellow is an example of a lemonade stand contract that receives 10XDC for a glass of lemonade and divides those funds amongst a set token holders while keeping track of how many glasses have been sold.

```solidity
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
``` 

**SHARES & SPLITS** allow developers to sell portions of their DApps by allowing a simple means of owning and distributing equity of profitable applications that reside on the XDC Network. This means an investor can invest in the DApp, to help the developer build more features or to help grow its user and community base while being attributed dividends. The value of the tokens are based on the performance of the DApp. Any DApp, no matter how big or small, can have SHARES to allocate profits.

  

SPLITS are uniform contracts to split SHARE tokens into smaller dividend tokens that redeem and split the dividends allocated to that associated token provided to the SPLIT contract. A SPLIT is functionally identical to a SHARE, but a SPLIT can only represent partial ownership of a SHARE, whereas a SHARE represents ownership of the DApp. If a DApp uses the SHARE tokens as governance tokens or in some form of automation, SPLITS cannot participate. SPLITS only redeem dividends from the SHARE that's been split.

  

We refer to these layers of SPLITS as generations, as shown in the graphic above. The original SHARE stands as generation 0, the next is generation 1, and so forth. All SPLITS in a given generation hold equal value.

  

These generations allow for SHARES to be divided up indefinitely. SPLITS can only have as many splits as the SHARE contract has SHARES. That means that if there are 1,000 SHARES, each of those SHARES can have only 1,000 SPLITS in the first generation. In the second generation, each of these 1,000 first generation SPLITS can have 1,000 second generation SPLITS.

  

Meaning that in generation one, all the SHARES can have a total of 1 million SPLITS derived from them, and in the second generation can have 1 Billion SPLITS derived from its first generation SPLITS . Simply put, dividend-earning stakeholding of a DApp can increase liquidity in each generation, as these SPLITS also increase affordability to investors who want to own the yield of a DApp,as a derivative token of the original SHARE.

### How DApps Can Use SHARES

DApps can use SHARES in a few different ways:

  

-   DApps can be built with SHARES to allow for dividend allocation of the revenue in these DApps
    
-   Developers can also build more smart contracts after the fact, which can offer more functionality and consolidate the profits from the new DApps into the original SHARE contract
    
-   Third-party developers can also do this to add functionality and increase the yield for the SHARES
    
-   Developers can also create abstract single function contracts (ex: polling DApp, analysis DApp, TAx DApp) called DApplets — isolated DApps that aren't typically user facing and may allow functionality to other smart contracts that can hold SHARES and justify profitability from otherwise abstract functions
    
-   SHARES are a direct means of having developers sell portions of their products no matter how big or small to help fund their future products
    
-   Investors can own DApps similar to how they own companies
    

  

Currently, crypto currencies are the primary market on blockchain. However, as DApps develop novel means of ownership, new markets will arise that are centered around the popularity and growth of DApps. As primary DApps interconnect with secondary applications that rely on them, both the secondary and primary DApps may become profitable. The SHARE holders of both are able to gain fees on the usage of their contract.

  

SHARES and SPLITs allow developers, investors, and DApp users to easily sell and invest in DApps of all sizes in a more autonomous way than was possible before. This model exemplifies the promise of blockchain.

  

The XRC-SHARE & XRC-SPLITS contracts have been submitted to be approved as an official standard on the XDC Network. To comment on the process or the contracts, check out the [XDC-Community](https://github.com/XDC-Community/XIPs.github.io) Github to participate in the XDC XIP process.
