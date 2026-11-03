# Uniswap — Ethereum mainnet
#
# Who owns the V3 Factory. The owner can enable new fee tiers and turn on the
# protocol fee switch; it is expected to be the Uniswap governance timelock.
#
# `owner` has a setter (setOwner), but it lives in `expect` on purpose: this
# repo watches, it never proposes calls.

version = "1"

chain {
  name     = "ethereum"
  chain_id = 1
  rpc      = env("RPC_URL")
}

resource "contract" "v3Factory" {
  # Uniswap V3 Factory
  # https://docs.uniswap.org/contracts/v3/reference/deployments/ethereum-deployments
  # https://etherscan.io/address/0x1F98431c8aD98523631AE4a59f267346ea31F984
  address = "0x1F98431c8aD98523631AE4a59f267346ea31F984"
  abi     = "abis/uniswap-v3-factory.abi.json"

  expect {
    owner = "0x1a9C8182C09F50C8318d769245beA52c32BE35BC" # Uniswap governance timelock
  }
}
