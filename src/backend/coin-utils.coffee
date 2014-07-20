KeyModule = require 'bitcore/Key'
networks = require "#{__dirname}/networks.js"

opts =
  network: networks.testnet

module.exports =
  decodePubkey: (hexStr) ->
    buf = new Buffer hexStr, 'hex'
    return undefined if not buf
    key = new KeyModule.Key()
    key.public = buf
    return key

  build2of2MultiSigTx: (pubkeyHex1, pubkeyHex2, amount) ->

    pubkeysForTransaction = 2

    # Using an OP_CHECKMULTISIG transaction for 2 of 2 multisig
    pubkeys = [pubkeyHex1, pubkeyHex2]

    # TODO: where can I get these from? a bitcoind instance? API? (Let's go with
    # API)
    utxos = [{
      address: input.addr
      txid: "39c71ebda371f75f4b854a720eaf9898b237facf3c2b101b58cd4383a44a6adc"
      vout: 1
      ts: 1396288753
      scriptPubKey: "76a914e867aad8bd361f57c50adc37a0c018692b5b0c9a88ac"
      amount: 0.4296
      confirmations: 2
    }]

    outs = [{
      nreq: pubkeysForTransaction
      pubkeys: pubkeys
      amount: amount
    }]

    # partially build the transaction here, and let it be signed elsewhere
    builder = new Builder(opts)
      .setUnspent(utxos)
      .setOutputs(outs)

    return builder

  buildRollingRefundTxFromMultiSigOutput: (txToRefund, refundPubKey, amountNotRefundedK2, K2, timeToLock) ->

    # TODO: Add refundPubKey as an output

    totalRefund = # TODO: extract from txToRefund's outputs

    if totalRefund - amountNotRefundedK2 < 0
      throw new Error "Cannot pay out more than the total original agreement"

    # When there is an amount to actually pay to the server, deduct it from the
    # amount being refunded
    if amountNotRefundedK2 > 0
      # TODO: add K2 as an output for total of amountNotRefundedK2

      totalRefund -= amountNotRefundedK2

    if timeToLock > 0
      # TODO: Lock transaction somehow

    # TODO: return the built, unsigned tx
