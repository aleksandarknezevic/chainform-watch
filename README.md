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
| Lido | [stETH](https://etherscan.io/address/0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84) | protocol fee, emergency stop, token metadata | [watch/lido.hcl](watch/lido.hcl) |
| Chainlink | [ETH / USD feed](https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) | description, decimals, version | [watch/chainlink.hcl](watch/chainlink.hcl) |
| Uniswap | [V3 Factory](https://etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984) | owner (governance timelock) | [watch/uniswap.hcl](watch/uniswap.hcl) |

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

1. Put a trimmed ABI (view functions you watch) in [`abis/`](abis/).
2. Snapshot the live values:

   ```bash
   export RPC_URL=https://your-mainnet-rpc.example
   scripts/import.sh aaveV3Pool 0x... abis/aave-v3-pool.abi.json
   ```

3. Edit the generated `watch/<name>.hcl`. Move everything into `expect`,
   delete volatile values, and add an explorer link for every address.
4. Add a row to the table above and open a PR. CI runs the same plan against
   mainnet.

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
