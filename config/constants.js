import { build } from '@onflow/sdk'
import dotenv from 'dotenv'
dotenv.config()

export const nodeUrl = process.env.FLOW_ACCESS_NODE

export const privateKey = process.env.FLOW_ACCOUNT_PRIVATE_KEY

export const publicKey = process.env.FLOW_ACCOUNT_PUBLIC_KEY

export const accountKeyId = process.env.FLOW_ACCOUNT_KEY_ID

export const accountAddr = process.env.FLOW_ACCOUNT_ADDRESS

export const FLOWTokenAddr = process.env.FLOW_TOKEN_ADDRESS

export const FUSDTokenAddr = process.env.FUSD_TOKEN_ADDRESS

export const KIBBLETokenAddr = process.env.KIBBLE_TOKEN_ADDRESS

export const flowFungibleAddr = process.env.FLOW_FUNGIBLE_ADDRESS

export const flowNonFungibleAddr = process.env.FLOW_NONFUNGIBLE_ADDRESS

export const alchemyKey = process.env.ALCHEMY_KEY

const buildPath = (fileName, type) => {
  let filePath = ''
  switch (type) {
    case 'script':
      filePath = `../cadence/scripts/${fileName}`
      break
    default:
      filePath = `../cadence/transactions/${fileName}`
  }
  return filePath
}

export const paths = {
  scripts: {
    getFLOW: buildPath('get_flow_balance.cdc', 'script'),
    getKIBBLE: buildPath('get_kibble_balance.cdc', 'script'),
    getFUSD: buildPath('get_fusd_balance.cdc', 'script'),
    getTimestamp: buildPath('get_block_timestamp.cdc', 'script'),
  },
  transactions: {
    initTokens: buildPath('init_tokens.cdc'),
    mintFLOW: buildPath('mint_flow_token.cdc'),
    mintFUSD: buildPath('mint_fusd.cdc'),
    mintKIBBLE: buildPath('mint_kibble.cdc'),
    transferFLOW: buildPath('transfer_flow.cdc'),
    transferFUSD: buildPath('transfer_fusd.cdc'),
    transferKibble: buildPath('transfer_kibble.cdc'),
  },
}
