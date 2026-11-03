# chainform-watch

[![watch](https://github.com/aleksandarknezevic/chainform-watch/actions/workflows/watch.yml/badge.svg)](https://github.com/aleksandarknezevic/chainform-watch/actions/workflows/watch.yml)
[![Drift issues](https://img.shields.io/github/issues/aleksandarknezevic/chainform-watch/drift?label=open%20drift&color=B60205)](https://github.com/aleksandarknezevic/chainform-watch/issues?q=is%3Aissue+label%3Adrift)

Every hour, this repo checks owners, admins, fees, pause flags and oracle
settings of major DeFi contracts on Ethereum mainnet. Any on-chain change
becomes a public GitHub issue with a reviewable diff.

It runs on [ChainForm](https://github.com/aleksandarknezevic/chainform), an
open-source CLI that compares declared contract configuration with live chain
state. It performs **read-only `eth_call`s only**. No keys, no transactions.

## What is watched

| Protocol | Contract | Watched values | Config |
| --- | --- | --- | --- |
| Aave | [V3 PoolAddressesProvider](https://etherscan.io/address/0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e) | owner, ACL admin, Pool / Configurator / oracle pointers | [watch/aave-v3-addresses-provider.hcl](watch/aave-v3-addresses-provider.hcl) |
| Aave | [V3 Pool](https://etherscan.io/address/0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2) | listed reserves, flash loan premium | [watch/aave-v3-pool.hcl](watch/aave-v3-pool.hcl) |
| Compound | [cUSDCv3](https://etherscan.io/address/0xc3d688B66703497DAA19211EEdff47f25384cdc3) | governor, pause guardian & flags, interest rate curve | [watch/compound-v3-usdc.hcl](watch/compound-v3-usdc.hcl) |
| Compound | [cWETHv3](https://etherscan.io/address/0xA17581A9E3356d9A858b789D68B4d866e593aE94) | governor, pause guardian & flags, interest rate curve | [watch/compound-v3-weth.hcl](watch/compound-v3-weth.hcl) |
| Lido | [stETH](https://etherscan.io/address/0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84) | protocol fee, emergency stop, token metadata | [watch/lido.hcl](watch/lido.hcl) |
| Uniswap | [V3 Factory](https://etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984) | owner | [watch/uniswap.hcl](watch/uniswap.hcl) |
| Chainlink | [ETH / USD feed](https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) | owner, aggregator, metadata | [watch/chainlink-eth-usd.hcl](watch/chainlink-eth-usd.hcl) |
| Chainlink | [BTC / USD feed](https://etherscan.io/address/0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c) | owner, aggregator, metadata | [watch/chainlink-btc-usd.hcl](watch/chainlink-btc-usd.hcl) |
| Circle | [USDC](https://etherscan.io/address/0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48) | owner, master minter, pauser, blacklister, rescuer, paused | [watch/usdc.hcl](watch/usdc.hcl) |
| Tether | [USDT](https://etherscan.io/address/0xdAC17F958D2ee523a2206206994597C13D831ec7) | owner, paused, deprecation, transfer fee | [watch/usdt.hcl](watch/usdt.hcl) |
| BitGo / BiT Global | [WBTC](https://etherscan.io/address/0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599) | owner, paused | [watch/wbtc.hcl](watch/wbtc.hcl) |

Rows whose config file is missing are waiting for their bootstrap PR.

## How it works

```
watch/*.hcl  ──hourly──▶  chainform plan  ──drift──▶  issue "Drift: watch/<file>"
     ▲                                          └───▶  PR drift/<name> with the
     │                                                 on-chain values
     └──── a human verifies the change, links the source, merges ◀──┘
           (merge closes the issue)
```

1. Each file in [`watch/`](watch/) declares the values a contract is expected
   to have, in `expect` blocks.
2. [`.github/workflows/watch.yml`](.github/workflows/watch.yml) runs
   `chainform plan` for every file every hour, plus on every push and PR.
3. On drift, the workflow opens an issue labeled `drift` that contains the plan.
   It comments again only if the drift changes.
4. It also opens a PR that rewrites the expected values to the on-chain ones
   ([`scripts/rebaseline.py`](scripts/rebaseline.py)) and marks each changed
   line with a `TODO`.
5. A maintainer checks that the change is legitimate (a governance vote, a
   planned migration), replaces the `TODO`s with a description and a link to the
   source, and merges. The next run closes the issue. If the chain reverts on
   its own, the issue and the PR are closed automatically.

The result is a public, timestamped, reviewed history of parameter changes:
the [`drift` issues](https://github.com/aleksandarknezevic/chainform-watch/issues?q=label%3Adrift)
and the git log of `watch/`.

## Add a contract

PRs are welcome. Prefer values whose change matters to users: owners, admins,
fees, pause or stop flags, oracle and implementation pointers. Skip values
that change on their own (prices, supplies, timestamps).

Values are never typed by hand. They are snapshotted from the chain, so a new
config starts with no drift.

1. Add an ABI to [`abis/`](abis/) that lists **only the view functions you
   want watched**. Without setters, every value becomes a read-only `expect`
   assertion.
2. Add an entry to [`targets.json`](targets.json): `file`, `title`, `tags`
   (the hashtags used in post drafts), `address`, `abi`, `note`, optional
   `source`.
3. Merge it. The [`bootstrap`](.github/workflows/bootstrap.yml) workflow runs
   `chainform import` for every target without a config and opens a PR with the
   generated files. A target that fails to import is listed in the PR, and the
   others still go in.
4. Check the PR, add a row to the table above, and merge.

To snapshot locally instead, run
`RPC_URL=... python3 scripts/bootstrap.py`.

Install ChainForm with
`go install github.com/aleksandarknezevic/chainform/cmd/chainform@latest` or
a [release binary](https://github.com/aleksandarknezevic/chainform/releases).

## Run it yourself

Fork the repo and enable Actions, then configure:

| Setting | Why |
| --- | --- |
| Secret `RPC_URL` | Ethereum mainnet JSON-RPC endpoint (required). |
| Secret `WATCH_TOKEN` | Fine-grained PAT (contents, issues, pull requests: write). Recommended: PRs opened with the default token do not trigger the PR check. |
| Settings → Actions → General → *Allow GitHub Actions to create and approve pull requests* | Needed only without `WATCH_TOKEN`. |
| Branch protection on `main`: require PRs and the `watch result` check | Configs can then only land if they match the chain, so a stale value never becomes a baseline. |
| Settings → General → *Automatically delete head branches* | Cleans up `drift/*` branches after merge. |

To watch your own protocol, replace `watch/` with your contracts. Locally:

```bash
chainform plan -f watch/lido.hcl    # exit 0 = matches, 1 = drift, 2 = run failed
```

## Disclaimer

A drift issue means a value changed. It does not mean something is wrong:
most changes are legitimate governance actions. This is not a security
monitoring service and comes with no guarantees. See [LICENSE](LICENSE).
