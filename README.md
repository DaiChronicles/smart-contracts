# DaiChronicles • Smart Contracts

On‑chain contracts that power **[DaiChronicles.io](https://daichronicles.io)** — a decentralized, AI‑assisted media protocol where satirical 1/1 **Chronicles** are minted as NFTs, community ideology is staked on‑chain, and operations are executed by programmatic agents.

> TL;DR: **Code > promises.** Roles, mint caps, swaps, royalties, and agent permissions are enforced on Ethereum by these contracts.

---

## ✨ Highlights

- **Solidity**: `^0.8.24`
- **Libraries**: OpenZeppelin `^5`, Uniswap V2 interfaces
- **Token**: `DAC` — ERC20 (capped, burnable, permit) with a **hard cap of 1,000,000,000**
- **NFTs**: `DAChronicle` — ERC721 with EIP‑712 delegated actions + ERC2981 royalties
- **Agents**: On‑chain role‑gated programmatic wallets: **DaiChronicler**, **DaiLiquidarian**, **DaiTreasurer**
- **Governance**: Role registry + **7‑day timelocks** on sensitive role changes (progressive decentralization)
- **No VC / No private sale**: 10% pre‑mint for bootstrap; the rest is minted **only** via the Treasury within strict caps

---

## 🧩 Contracts at a Glance

| Contract | Purpose |
|---|---|
| `DACAuthority.sol` | Central on‑chain registry of **roles & permissions** with timelocks. Admin (multisig, early) + agent roles (Chronicles, Liquidity, Treasurer). |
| `DACAccessManaged.sol` | Base that checks `DACAuthority` before allowing sensitive calls. Composed into all operational contracts. |
| `DACToken.sol` | ERC20 **Capped**, **Burnable**, **Permit**. **Only `DACTreasury` can mint**, never exceeding 1B. |
| `DACTreasury.sol` | Protocol treasury: minting (within caps), **Uniswap V2** liquidity, swaps (via pluggable swappers), vesting, buybacks, reward routing. |
| `DACStaking.sol` | Stake **DAC** to influence the **Bias Meter** (Left/Neutral/Right) and enter daily prize draws for Chronicle mint rights. **No DAC emissions.** |
| `DAChronicle.sol` | ERC721 for Chronicles. Supports **delegated EIP‑712 signatures** for minting/updates, perspective cooldowns, and metadata updates. |
| `DACRewardSplitter.sol` | Pull‑payment splitter used for routing fees (e.g., perspective changes) to burn/curation/alignment pools. |
| `ERC721DelegatedActions.sol` | EIP‑712 action hub + ERC2981 royalties for the Chronicle NFT line. |
| `ERC721Nonces.sol` | Per‑token nonce utility used by delegated actions. |
| `IDACToken.sol`, `IDAChronicle.sol`, `IDACTreasury.sol`, `IDACStaking.sol`, `IDACSwapper.sol`, `IERC721DelegatedActions.sol` | Interfaces for safety and modular integrations. |

> **Key invariants**
>
> - Only `DACTreasury` mints DAC, hard‑capped at **1,000,000,000**.
> - Reserved pools (founders, ops, CEX liquidity, airdrops — **5% each**) are **caps**, not pre‑mints.
> - **No staking emissions**: staking confers influence + prize draw rights, not DAC.
> - Role updates & new swappers are **timelocked (7 days)** via `DACAuthority`.
> - Chronicle mints/updates require **agent signatures** (EIP‑712).

---

## 🔐 Deployed Addresses (Ethereum Mainnet)

> Always verify addresses on an official channel before interacting.

| Contract | Address |
|---|---|
| **DACAuthority** | `0x975f1dAc2FC1f24A86284c9c95059F78382bBacB` |
| **DACToken** | `0xCb063cEb309867f430fa7AfF521fA11eb76A4e94` |
| **DACStaking** | `0x57872e4bd7d3D4158551Ea67f0B332Ef09fFb705` |
| **DAChronicle** | `0x93E9DF690Ce849784867d4Ad84D128ABB16542D9` |
| **DACTreasury** | `0x1EA55022826e48C465B02ec8C4Ca522b5e0aEe82` |
| **DACRewardSplitter** | `0x7d0b0927625ee8fd91090ABC2b52Ef720c38d345` |

---

## 🧠 System Overview

```
[ Agents ]  ──sign──▶  [ DACAuthority ] ──grants──▶ [ Access‑Managed Contracts ]
   │                               │                         ├─ DACTreasury (mint, LP, swaps)
   │                               │                         ├─ DAChronicle (EIP‑712 mints/updates)
   │                               │                         └─ DACStaking (bias + prize draws)
   └── programmatic wallets ──────────────────────────────────────────────────────────────────────▶

Users ──stake DAC──▶ DACStaking ──influence bias / enter draw──▶ Chronicle mint right (1/1 NFT)
Owners ──spend DAC──▶ Perspective update ──▶ burn/split via DACRewardSplitter
Revenue (ETH) ──▶ DACTreasury ──▶ LP (Uniswap V2), swaps, buybacks, vesting
```

---

## 🧭 Configuration Notes

- **Treasury minting**: Enforces global cap and per‑pool caps (founders, ops, CEX liquidity, airdrops). Caps are **upper bounds**, not obligations.
- **Swaps/Liquidity**: Uses Uniswap V2 interfaces; actual swap execution is abstracted behind `IDACSwapper` so strategies can be hot‑swapped (after timelock) without redeploying the treasury.
- **Royalties**: ERC2981 standard in `ERC721DelegatedActions`; enforced at marketplace level.
- **Perspective updates**: Spend DAC to change an NFT’s political bias (Left/Neutral/Right) with cooldowns.
- **Staking**: Time‑weighted multipliers + ideological declaration; rewards are **rights to mint** new Chronicles via daily drawings (not token emissions).

---

## 🔒 Security & Trust

> **Security audit status:** An independent third‑party audit is currently in progress (initiated November 2025). We’ll publish the report and remediation details once complete.


- Contracts are modular and follow OZ patterns; **still treat as production‑grade code that deserves review**.
- Critical actions are permissioned by `DACAuthority` and **timelocked (7 days)**.
- Agent wallets are isolated and can only call authorized functions.
- **Use at your own risk.** No warranty is expressed or implied. Read the source.

If you believe you’ve found a vulnerability, please open a security disclosure channel (see [`SECURITY.md`](SECURITY.md)).

---

## 📜 Tokenomics Summary

- **Fixed cap**: 1,000,000,000 DAC
- **Pre‑mint**: 10% at launch for ops/liquidity/bootstrap
- **Reserved (unminted caps)**: 5% founders (3y vest, 6m cliff), 5% ops (10y), 5% CEX liquidity (optional), 5% potential airdrops (optional)
- **No VC / No private sale**
- **Supply entry**: New DAC only enters via **Treasury‑controlled** events (e.g., liquidity provisioning), **not** staking emissions

---

## 🗺️ Documentation

- Protocol docs: https://daichronicles.io/docs
- Tokenomics → Utility of DAC, Revenue Flow, Treasury Governance
- Governance & Trust → Decentralization Philosophy, Why Anonymous, Agent‑led Future, Security Practices, Smart Contracts & Addresses

---

## 📄 License

MIT — see `LICENSE`.

---

## 🦉 Appendix: Agents

- **DaiChronicler**: Creates daily Chronicles (10/day), posts on X, and — over time — adapts tone to on‑chain ideology.
- **DaiLiquidarian**: Manages DAC/ETH liquidity and introduces new DAC via treasury‑approved liquidity actions.
- **DaiTreasurer**: Manages treasury assests and reward flows.

*May Owlyus watch over your gas fees.*

