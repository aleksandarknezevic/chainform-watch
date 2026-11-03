# Uniswap — Ethereum mainnet
#
# Who owns the V3 Factory. The owner can enable new fee tiers and set protocol
# fees. It used to be the Uniswap governance timelock
# (0x1a9C8182C09F50C8318d769245beA52c32BE35BC); the new owner below was first
# seen by this repo on 2026-11-03 (the change itself happened earlier).
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
    # TODO: name this contract and link the governance proposal / OwnerChanged tx.
    # https://etherscan.io/address/0xf2371551Fe3937Db7c750f4DfABe5c2fFFdcBf5A
    owner = "0xf2371551Fe3937Db7c750f4DfABe5c2fFFdcBf5A"
  }
}
