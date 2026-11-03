# Chainlink — Ethereum mainnet
#
# Price feed proxy metadata. A change in description/decimals/version would
# break every consumer that hard-codes them.
#
# TODO: add `owner` and `aggregator` (who controls the proxy, and which
# aggregator it currently points to) once their live values are snapshotted
# with scripts/import.sh — an aggregator switch is exactly the kind of change
# this repo exists to surface.

version = "1"

chain {
  name     = "ethereum"
  chain_id = 1
  rpc      = env("RPC_URL")
}

resource "contract" "ethUsd" {
  # ETH / USD price feed
  # https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum
  # https://etherscan.io/address/0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
  address = "0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419"
  abi     = "abis/chainlink-aggregator-proxy.abi.json"

  expect {
    decimals    = 8
    description = "ETH / USD"
    version     = 6
  }
}
