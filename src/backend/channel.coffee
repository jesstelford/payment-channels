Q = require 'q'
CoinUtils = require "#{__dirname}/coin-utils"
rpcClient = require "#{__dirname}/jrpcClient"

module.exports = class

  channelId: undefined
  timeLock: undefined
  pubkey: undefined
  privkey: undefined
  serverPubkey: undefined
  maxPayment: undefined
  agreementTxT1: undefined

  constructor: (@pubkey, @privkey, @maxPayment) ->

  createAndCommit: (callback) ->

    # `"channel.open"`
    # `"channel.setRefund"`
    # `"channel.commit"`
    # `"channel.pay"`
    # rpcClient.call(method, params, opts, callback)

    Q.nfcall(rpcClient.call, "channel.open", [], {}).then(
      (result) ->

        @channelId = result.pubkey
        @serverPubkey = result.pubkey
        @timeLock = result.timelock.prefer

        @agreementTxT1 = @createAgreementTxT1 @serverPubkey,

        refundTxInfo = @createRefundTxT2()

        params =
          "channel.id": @channelId # The id returned from "channel.open"
          pubkey: @pubkey # pubkey of client
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

  createAgreementTxT1: (serverPubkey) ->
    multiSigTxBuilder = CoinUtils.build2of2MultiSigTx @pubkey, serverPubkey, @maxPayment
    multiSigTx = multiSigTxBuilder.sign([@privkey]).build()
    return multiSigTx.serialize().toString('hex')


  createRefundTxT2: ->
    CoinUtils.buildRollingRefundTxFromMultiSigOutput
    # TODO
    return {
      tx: ""
      t1InIdx: 0
    }

  verifyServerSignedT2: (signature) ->
    # TODO
    return true

  signRefundTx: ->

