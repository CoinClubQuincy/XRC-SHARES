<p align="center">
  <img src=".github/assets/banner.svg" alt="XRC-SHARES: Turn a DApp's revenue into dividends for its token holders" width="100%">
</p>

<p align="center">
  
<a href="https://github.com/CoinClubQuincy/XRC-SHARES/actions/workflows/build.yml"><img alt="build" src="https://github.com/CoinClubQuincy/XRC-SHARES/actions/workflows/build.yml/badge.svg"></a>  <img alt="network: XDC" src="https://img.shields.io/badge/network-XDC-2563eb">  <img alt="language: Solidity" src="https://img.shields.io/badge/language-Solidity-0e7490">  <img alt="status: proposal" src="https://img.shields.io/badge/status-proposal-b45309">  <img alt="license: MIT" src="https://img.shields.io/badge/license-MIT-475569">
</p>

<p align="center">
  <a href="#how-it-works">How it works</a> · <a href="#try-it">Try it</a> · <a href="#what-is-tested">What is tested</a> · <a href="#known-issues">Known issues</a>
</p>

A SHARE is an NFT that represents a piece of a DApp. Money paid to the contract is divided evenly across every share, and each holder withdraws what their shares have earned. A SPLIT divides one SHARE into smaller dividend tokens, and SPLITS can themselves be split.

> [!WARNING]
> This is a proposal and has not been audited. Read [Known issues](#known-issues) before sending real funds to it.

## Why use it

| You want to | With SHARES |
| --- | --- |
| Sell part of a DApp | Sell share tokens, which are ordinary ERC-1155 tokens |
| Pay holders automatically | Send fees to the contract and each share account is credited |
| Let holders use access control or voting | Check `balanceOf` for a share in your own contract |
| Offer smaller stakes | Put a SHARE into a SPLIT contract and sell the splits |

## How it works

```mermaid
flowchart LR
    U[Customer] -->|pays the DApp| D[Your DApp<br/>extends XRCSHARE]
    D -->|redirectValue| A[One account per SHARE]
    A -->|redeem| H[SHARE holders]
    A -->|redeem| S[XRCSPLIT<br/>holds one SHARE]
    S -->|redeem| SH[SPLIT holders]
```

Inherit `XRCSHARE` and forward fees from any payable function:

```solidity
contract LemonadeStand is XRCSHARE {
    uint public lemonadeCount;

    constructor(string memory _name, string memory _symbol, uint _totalSupply, string memory _URI)
        XRCSHARE(_name, _symbol, _totalSupply, _URI) {}

    function GlassOfLemonade() public payable returns (bool) {
        require(msg.value >= 10 ether, "need more funds");
        lemonadeCount++;
        redirectValue(msg.value); // credits every share account
        return true;
    }
}
```

| Contract | Function | What it does |
| --- | --- | --- |
| `XRCSHARE` | `constructor` | Mints one token per share to the deployer, up to 1,000 shares |
| `XRCSHARE` | `viewAccount(token)` | Unclaimed funds for one share |
| `XRCSHARE` | `viewAccountTotal()` | Unclaimed funds across the caller's shares |
| `XRCSHARE` | `redeem()` | Pays the caller for every share they hold |
| `XRCSPLIT` | `activateContract(share)` | Takes in one SHARE and mints the splits to the caller |
| `XRCSPLIT` | `redeem()` | Pulls the SHARE's dividends, then pays the caller's splits |
| `XRCSPLIT` | `redeemShard()` | Burns all the splits and returns the SHARE |

> [!IMPORTANT]
> Before calling `activateContract`, call `setApprovalForAll(splitAddress, true)` on the SHARE contract.

Unclaimed dividends stay with the token. If a share is sold, the new holder can redeem what it has already earned.

The full write-up, including generations of SPLITS and how DApps can use them, is in [docs/WRITEUP.md](docs/WRITEUP.md). To comment on the proposal, use the [XDC XIP repository](https://github.com/XDC-Community/XIPs.github.io).

## Try it

```bash
git clone https://github.com/CoinClubQuincy/XRC-SHARES.git
cd XRC-SHARES
git clone --depth 1 -b v4.9.6 https://github.com/OpenZeppelin/openzeppelin-contracts lib/openzeppelin-contracts
git clone --depth 1 -b v1.9.7 https://github.com/foundry-rs/forge-std lib/forge-std
forge test
```

You need [Foundry](https://getfoundry.sh). Tests named `test_KnownIssue_*` pass because they pin a defect, so a passing run does not mean the defect is gone.

To try it on a network, use the Apothem testnet:

| Network | Chain ID | RPC |
| --- | --- | --- |
| Apothem testnet | 51 | `https://rpc.apothem.network` |
| XDC mainnet | 50 | `https://rpc.xinfin.network` |

```bash
forge create contracts/SHARE.sol:XRCSHARE --rpc-url https://rpc.apothem.network --interactive --broadcast --legacy \
  --constructor-args "My DApp" "MDA" 100 "https://example.com/{id}.json"
```

## What is tested

[`test/foundry/Share.t.sol`](test/foundry/Share.t.sol) has 10 tests and runs in CI on every push.

| Tested | Not tested |
| --- | --- |
| Minting, the 1,000 share cap and even splitting | A real network, testnet or mainnet |
| Redeeming only the shares you hold | An independent security audit |
| Dividends moving with a sold token | `redeemShard()` and more than one generation of SPLITS |
| A SPLIT paying its holders from the SHARE | |

## Known issues

| Issue | Effect | Test |
| --- | --- | --- |
| `redeem()` ignores a failed payout | A holder contract that can't receive funds loses its balance, because the account is zeroed first | `test_KnownIssue_RedeemZeroesBalanceWhenThePayoutFails` |
| Payments use a lot of gas | A sender limited to 2,300 gas, as with Solidity's `transfer`, fails. The first payment to 1,000 shares used about 20.6 million gas in testing | `test_KnownIssue_PaymentWith2300GasFails` |
| Integer division | Whatever doesn't divide evenly by the share count stays in the contract uncredited | Read from the code |

<details>
<summary><strong>More XDC projects</strong></summary>

| Group | Project | What it is |
| --- | --- | --- |
| Standards | [XRCDividendPlus](https://github.com/CoinClubQuincy/XRCDividendPlus) | Dividend-paying XRC-20 token |
| Treasury and finance | [Multi-Sig-Treasury](https://github.com/CoinClubQuincy/Multi-Sig-Treasury) | Treasury controlled by tokenized keys |
| Treasury and finance | [XRC-Airdrop](https://github.com/CoinClubQuincy/XRC-Airdrop) | Self-run token airdrop |
| Treasury and finance | [XRC-Credit](https://github.com/CoinClubQuincy/XRC-Credit) | Debt contract skeleton |
| Treasury and finance | [XDC-Defi-Instruments](https://github.com/CoinClubQuincy/XDC-Defi-Instruments) | Assets, agreements, forwards, futures and a marketplace |
| Identity and access | [LoginMFAContract](https://github.com/CoinClubQuincy/LoginMFAContract) | Login with a password and an NFT |
| Identity and access | [PrivateAccessToken](https://github.com/CoinClubQuincy/PrivateAccessToken) | Token-gated contract data demo |
| Identity and access | [Delegated_Authority](https://github.com/CoinClubQuincy/Delegated_Authority) | KYC notary proof of concept |
| Learning and libraries | [XDC-LemonadeStand](https://github.com/CoinClubQuincy/XDC-LemonadeStand) | Workshop DApp built on XRC-SHARES |
| Learning and libraries | [Non-Financial-SmartContracts](https://github.com/CoinClubQuincy/Non-Financial-SmartContracts) | Games, inventory, keys and on-chain repositories |
| Tools | [XDC_Python_SDK_V1](https://github.com/CoinClubQuincy/XDC_Python_SDK_V1) | Python client for the XDC JSON-RPC API |
| Tools | [PrivateXDCNode_SetupScript](https://github.com/CoinClubQuincy/PrivateXDCNode_SetupScript) | Private XDC network setup scripts |
| Tools | [WebApp_to_XDCPay](https://github.com/CoinClubQuincy/WebApp_to_XDCPay) | Web app to XDCPay tutorial |
| Multi-chain | [CoinClub_Framework](https://github.com/CoinClubQuincy/CoinClub_Framework) | Python library with an XDC adapter |
| Interfaces | [Contract_Interface_Model_Language](https://github.com/CoinClubQuincy/Contract_Interface_Model_Language) | Interface documents for smart contracts and APIs |

</details>

## License

MIT, as declared in the SPDX headers of the source files. This repository has no separate license file.
