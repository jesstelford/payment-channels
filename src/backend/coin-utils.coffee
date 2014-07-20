_ = require 'underscore'
KeyModule = require 'bitcore/Key'
Builder = require 'bitcore/TransactionBuilder'
Key = require 'bitcore/Key'
networks = require "#{__dirname}/networks.js"

# TODO: Research: What's riskier; 1) Using satoshi's and worry about overflowing
# the integer type, or 2) Using BTC's and worry about Javascript's innacuracies?

T1INPUT_ID_FOR_T2_T3 = 0

opts =
  network: networks.testnet

module.exports =
  decodePubkey: (hexStr) ->
    buf = new Buffer hexStr, 'hex'
    return undefined if not buf
    key = new KeyModule.Key()
    key.public = buf
    return key

  verifyTxSig: (tx, sig) ->
    hash = tx.serialize().toString('hex')
    return Key.verifySignatureSync hash, sig

  build2of2MultiSigTx: (pubkeyHex1, pubkeyHex2, amountSat) ->

    pubkeysForTransaction = 2

    # Using an OP_CHECKMULTISIG transaction for 2 of 2 multisig
    pubkeys = [pubkeyHex1, pubkeyHex2]

    # TODO: where can I get these from? a bitcoind instance? API? (Let's go with
    # API)
    # TODO: Ensure that the 'amountSat' field is in satoshi's
    utxos = [{
      address: input.addr
      txid: "39c71ebda371f75f4b854a720eaf9898b237facf3c2b101b58cd4383a44a6adc"
      vout: 1
      scriptPubKey: "76a914e867aad8bd361f57c50adc37a0c018692b5b0c9a88ac"
      amountSat: 42960000
      confirmations: 1
    }]

    outs = [{
      nreq: pubkeysForTransaction
      pubkeys: pubkeys
      amountSat: amountSat
    }]

    # partially build the transaction here, and let it be signed elsewhere
    builder = new Builder(opts)
      .setUnspent(utxos)
      .setOutputs(outs)

    return builder

  ###
  # @param txToRefund a bitcore transaction to refund
  # @param refundPubKey Public key to send the refund to
  # @param amountNotRefundedK2 satoshi's to pay server
  # @param serverPubkeyK2 server's public key
  # @param timeToLock Unix timestamp before which the transaction will not be accepted into a block
  ###
  buildRollingRefundTxFromMultiSigOutput: (txToRefund, refundPubKey, amountNotRefundedK2, serverPubkeyK2, timeToLock) ->

    amountNotRefundedK2 || amountNotRefundedK2 = 0
    totalRefund = txToRefund.valueOutSat

    if amountNotRefundedK2 > totalRefund
      throw new Error "Cannot pay out more than the total original agreement"

    # txToRefundHex = txToRefund.serialize().toString('hex')
    txToRefundHexScriptPubkey = txToRefund.outs[0].s.toString('hex')

    utxos = [{
      # address: input.addr, # Looking through bitcore implys we don't need this for a multisig input
      txid: txToRefund.getHash().toString('hex'),
      vout: 0, # There should only be a single output for the transactoin, so it's always vout number 0
      scriptPubKey: txToRefundHexScriptPubkey,
      amountSat: totalRefund
      confirmations: 1
    }]

    outs = [{
      address: refundPubKey,
      amountSat: totalRefund - amountNotRefundedK2
    }]

    # When there is an amount to actually pay to the server, deduct it from the
    # amount being refunded
    if amountNotRefundedK2 > 0
      # add K2 as an output for total of amountNotRefundedK2 at output ID 1
      outs.push {
        address: serverPubkeyK2,
        amountSat: amountNotRefundedK2
      }

    builderOpts = _({}).extend opts

    if timeToLock > 0
      builderOpts.lockTime = timeToLock
      # Since the previous transaction we're attempting to spend hasn't
      # necessarily been transmitted into the network, we need to flag that we
      # could be spending an unconfirmed output
      builderOpts.spendUnconfirmed = true

    builder = new Builder(builderOpts)
      .setUnspent(utxos)
      .setOutputs(outs)

    return {
      tx: builder
      t1InIdx: T1INPUT_ID_FOR_T2_T3 # Due to the way we constructed the transaction above, the in id will always be at index 0
    }
