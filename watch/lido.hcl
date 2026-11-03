# Lido stETH (Ethereum)
#
# stETH protocol fee and emergency stop flag. Both are governance-controlled:
# a change here means a DAO vote (or an emergency action) went through.
#
# tags: #Lido #stETH #Ethereum #DeFi

version = "1"

chain {
  name     = "ethereum"
  chain_id = 1
  rpc      = env("RPC_URL")
}

resource "contract" "lidoSteth" {
  # Lido stETH token (proxy)
  # https://docs.lido.fi/deployed-contracts/
  # https://etherscan.io/address/0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
  address = "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"
  abi     = "abis/lido-steth.abi.json"

  expect {
    name      = "Liquid staked Ether 2.0"
    symbol    = "stETH"
    decimals  = 18
    getFee    = 999   # protocol fee in basis points (fee share of staking rewards)
    isStopped = false # emergency stop
  }
}
