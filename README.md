# 🎟️ Loyalty Ticketing System – Smart Contracts

This project implements a modular, gasless smart contract architecture for a loyalty-based ticketing platform using the FLEXBLOK spec.

---

## 🧾 Architecture Summary

Three contracts:

1. **RaghavTicketManager** – Manages event creation, ticket sales, reward minting
2. **RaghavLoyaltyToken** – ERC-20–style token for buyer rewards
3. **RaghavTicketNFT** – ERC-721–style NFT representing tickets

All logic is on-chain; payments are simulated (no ETH used).

---

## 🛂 Roles & Access Control

| Contract      | Admin Permissions        | Minter Role   |
| ------------- | ------------------------ | ------------- |
| TicketManager | Full control over events | —             |
| LoyaltyToken  | Can assign `minter`      | TicketManager |
| TicketNFT     | Can assign `NFTminter`   | TicketManager |

---

## 🧱 Key Functions

### 🎫 RaghavTicketManager

- `createEvent(...)` – creates an event (admin-only)
- `purchaseTicket(...)` – validates input, mints NFTs & rewards
- `updatePrice(...)`, `updateReward(...)` – configurable by admin

### 💰 RaghavLoyaltyToken

- `mint(...)` – by admin or manager
- `transfer`, `approve`, `transferFrom` – standard ERC-20 functions

### 🖼️ RaghavTicketNFT

- `mint(...)` – creates NFTs with event metadata
- `transfer`, `transferFrom`, `approve` – minimal ERC-721 logic

---

## 📡 Events

| Contract      | Event                  | When Emitted                  |
| ------------- | ---------------------- | ----------------------------- |
| TicketManager | `EventCreated`         | On new event setup            |
|               | `TicketPurchased`      | After ticket + reward minting |
| LoyaltyToken  | `Transfer`, `Approval` | Standard ERC-20               |
| TicketNFT     | `Transfer`, `Approval` | Standard ERC-721              |

---

## 🛡️ Validations & Limits

- `startDate > block.timestamp`
- `startDate < endDate`
- Max 10 tickets per purchase
- Cannot mint to zero address
- Role-restricted minting only

---

## 🧪 Testing

- Compatible with Hardhat & solidity-coverage
- Full suite covers ticket sales, reward flows, and transfer logic

---

## 🧩 Ready for Integration

- Gasless environments like FLEXBLOK
- API-driven testing platforms
- Event tracking and loyalty reward models

---

## ✅ Test Coverage Report

```bash
$ npx hardhat coverage

Version
=======
> solidity-coverage: v0.8.16

Instrumenting for coverage...
=============================

> RaghavLoyaltyToken.sol
> RaghavTicketManager.sol
> RaghavTicketNFT.sol

Compilation:
============

Compiled 3 Solidity files successfully (evm target: paris).

Network Info
============
> HardhatEVM: v2.24.0
> network:    hardhat

Test Results:
=============
  Loyalty Ticketing System
    ✔ should create an event
    ✔ should allow a user to purchase tickets and receive rewards (41ms)
    ✔ should allow admin to update ticket price and reward
    ✔ should prevent unauthorized minting
    ✔ should allow loyalty token transfers and approvals
    ✔ should reject loyalty token transfers exceeding balance or allowance
    ✔ should allow NFT approval and transferFrom by approved user
    ✔ should not allow unauthorized NFT transfers
    ✔ should store correct NFT metadata
    ✔ should set correct name, symbol, and admin in NFT contract
    ✔ should clear approval after transferFrom
    ✔ should revert if transferFrom is called by non-approved user

  12 passing (771ms)

Coverage Summary:
=================
--------------------------|----------|----------|----------|----------|----------------|
File                      |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
--------------------------|----------|----------|----------|----------|----------------|
 contracts\               |    87.72 |    57.35 |    90.91 |    92.08 |                |
  RaghavLoyaltyToken.sol  |      100 |       75 |      100 |      100 |                |
  RaghavTicketManager.sol |    96.55 |       50 |      100 |      100 |                |
  RaghavTicketNFT.sol     |       60 |    54.55 |       75 |    74.19 |... 154,155,156 |
--------------------------|----------|----------|----------|----------|----------------|
All files                 |    87.72 |    57.35 |    90.91 |    92.08 |                |
--------------------------|----------|----------|----------|----------|----------------|

> Istanbul reports written to ./coverage/ and ./coverage.json
```
