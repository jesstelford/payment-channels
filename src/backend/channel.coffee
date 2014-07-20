Q = require 'q'
CoinUtils = require "#{__dirname}/coin-utils"
rpcClient = require "#{__dirname}/jrpcClient"

T1INPUT_ID_FOR_T2_T3 = 0

module.exports = class

  channelId: undefined
  timeLock: undefined
  pubkeyK1: undefined
  privkeyK1: undefined
  serverPubkeyK2: undefined
  maxPayment: undefined
  agreementTxT1: undefined
  agreementTxT1ScriptPubkey: undefined

  constructor: (@pubkeyK1, @privkeyK1, @maxPayment) ->

  createAndCommit: (callback) ->

    # `"channel.open"`
    # `"channel.setRefund"`
    # `"channel.commit"`
    # `"channel.pay"`
    # rpcClient.call(method, params, opts, callback)

    Q.nfcall(rpcClient.call, "channel.open", [], {}).then(
      (result) ->

        @channelId = result.pubkey
        @serverPubkeyK2 = result.pubkey
        @timeLock = result.timelock.prefer

        @agreementTxT1 = @createAgreementTxT1 @serverPubkeyK2

        @agreementTxT1ScriptPubkey = agreementTx.outs[0].s.toString('hex')

        refundTxInfo = @createRefundTxT2 @timeLock

        params =
          "channel.id": @channelId # The id returned from "channel.open"
          pubkey: @pubkeyK1 # pubkey of client
          tx: refundTxInfo.tx # the refund transaction, hex encoded (unsigned)
          txInIdx: refundTxInfo.t1InIdx # the input id of the T1 transaction (that the server doesn't yet know about)

        # next step in the process
        return Q.nfcall(rpcClient.call, "channel.setRefund", [params], {})

    ).then(
      (result) ->

        if not @verifyServerSignedT2 result.signature
          throw new Error "Couldn't verify server agreed to and signed T2 transaction"

    ).done(
      (result) -> callback result
      callback
    )

  createAgreementTxT1: (serverPubkeyK2) ->
    multiSigTxBuilder = CoinUtils.build2of2MultiSigTx @pubkeyK1, serverPubkeyK2, @maxPayment
    # TODO: What about all the input transactions? What are they signed with?
    multiSigTx = multiSigTxBuilder.sign([@privkeyK1]).build()
    return multiSigTx


  createRefundTxT2: (timeToLock) ->
    return CoinUtils.buildRollingRefundTxFromMultiSigOutput @agreementTxT1, @pubkeyK1, 0, undefined, timeToLock

  verifyServerSignedT2: (signature) ->
    # TODO
    return true

  signRefundTx: ->

  createPayTxT3: (amount, serverPubKey) ->
    return CoinUtils.buildRollingRefundTxFromMultiSigOutput @agreementTxT1, @pubkeyK1, amount, serverPubKey, 0

