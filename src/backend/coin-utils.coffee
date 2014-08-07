_ = require 'underscore'
bignum = require "../node_modules/bitcore/node_modules/bignum"
Builder = require 'bitcore/lib/TransactionBuilder'
Key = require 'bitcore/lib/Key'
networks = require "#{__dirname}/networks.js"
BlockApi = require "#{__dirname}/adapters/blockio"


# TODO: Research: What's riskier; 1) Using satoshi's and worry about overflowing
# the integer type, or 2) Using BTC's and worry about Javascript's innacuracies?

T1INPUT_ID_FOR_T2_T3 = 0

opts =
  network: networks.testnet

module.exports =
  decodePubkey: (hexStr) ->
    buf = new Buffer hexStr, 'hex'
    return undefined if not buf
    key = new Key.Key()
    key.public = buf
    return key

  verifyTxSig: (tx, sig) ->
    hash = tx.serialize().toString('hex')
    return Key.verifySignatureSync hash, sig

  build2of2MultiSigTx: (pubkeyHex1, pubkeyHex2, amountSat, callback) ->

    pubkeysForTransaction = 2

    # Using an OP_CHECKMULTISIG transaction for 2 of 2 multisig
    pubkeys = [pubkeyHex1, pubkeyHex2]

    outs = [{
      nreq: pubkeysForTransaction
      pubkeys: pubkeys
      amount: "0.1" # TODO: set the actual amount
    }]

    BlockApi.unspentOutputs pubkeyHex1, (err, utxos) ->

      # partially build the transaction here, and let it be signed elsewhere
      builder = new Builder(opts)
      builder.setUnspent(utxos)
      console.log "unspent"
      builder.setOutputs(outs)
      console.log "outs"

      callback null, builder

  ###
  # @param txToRefund a bitcore transaction to refund
  # @param refundPubKey Public key to send the refund to
  # @param amountNotRefundedK2 satoshi's to pay server (an instance of bignum)
  # @param serverPubkeyK2 server's public key
  # @param timeToLock Unix timestamp before which the transaction will not be accepted into a block
  ###
  buildRollingRefundTxFromMultiSigOutput: (txToRefund, totalRefund, refundPubKey, amountNotRefundedK2, serverPubkeyK2, timeToLock) ->

    if not amountNotRefundedK2 or amountNotRefundedK2.eq(0) then amountNotRefundedK2 = bignum(0)

    if amountNotRefundedK2.gt(totalRefund)
      throw new Error "Cannot pay out more than the total original agreement"

    # txToRefundHex = txToRefund.serialize().toString('hex')
    txToRefundHexScriptPubkey = txToRefund.outs[0].s.toString('hex')

    utxos = [{
      # address: "abc123", # Looking through bitcore implys we don't need this for a multisig input
      txid: txToRefund.getHash().toString('hex'),
      vout: 0, # There should only be a single output for the transactoin, so it's always vout number 0
      scriptPubKey: txToRefundHexScriptPubkey,
      amountSat: totalRefund
      confirmations: 1
    }]

    outs = [{
      address: refundPubKey,
      amountSat: totalRefund.sub(amountNotRefundedK2)
    }]

    # When there is an amount to actually pay to the server, deduct it from the
    # amount being refunded
    if amountNotRefundedK2.gt(0)
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
