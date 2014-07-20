Q = require 'q'
CoinUtils = require "#{__dirname}/coin-utils"
rpcClient = require "#{__dirname}/jrpcClient"

Q.longStackSupport = true

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
  refundTxT2: undefined
  paymentTotalTx3: 0

  constructor: (@pubkeyK1, @privkeyK1, @maxPayment) ->

  createAndCommit: (callback) ->

    console.info "Opening the channel"
    Q.nfcall(rpcClient.call, "channel.open", [{}], {}).then(
      (result) =>

        @channelId = result.pubkey
        @serverPubkeyK2 = result.pubkey
        @timeLock = result["timelock.prefer"]

        console.info "Creating T1"
        @agreementTxT1 = @_createAgreementTxT1 @serverPubkeyK2
        console.info "Created T1"

        @agreementTxT1ScriptPubkey = @agreementTxT1.outs[0].s.toString('hex')

        refundTxInfo = @_createRefundTxT2 @timeLock
        console.info "Created T2"
        @refundTxT2 = refundTxInfo.tx.build()

        params =
          "channel.id": @channelId # The id returned from "channel.open"
          pubkey: @pubkeyK1 # pubkey of client
          tx: @refundTxT2.serialize().toString('hex') # the refund transaction, hex encoded (unsigned)
          txInIdx: refundTxInfo.t1InIdx # the input id of the T1 transaction (that the server doesn't yet know about)

        # next step in the process
        return Q.nfcall(rpcClient.call, "channel.setRefund", [params], {})

    ).then(
      (result) =>

        if not @_verifyServerSignedT2 result.signature
          throw new Error "Couldn't verify server agreed to and signed T2 transaction"

        agreementT1Hex = @agreementTxT1.serialize().toString('hex')

        # Create a payment that is just a fully unlocked refund
        paymentTxT3Builder = @_createPayTxT3(@paymentTotalTx3, undefined).tx
        paymentTxT3 = paymentTxT3Builder.sign(@privkeyK1).build()

        params =
          "channel.id": @channelId
          "tx.commit": agreementT1Hex
          "tx.firstPayment": paymentTxT3.serialize().toString('hex')

        return Q.nfcall(rpcClient.call, "channel.commit", [params], {})

    ).done(
      (result) => callback null, result
      callback
    )

  ###
  # @param cost Satoshi's that server is charging per microtransaction
  ###
  makeNewPayment: (cost, callback) ->
    # Now, we have established the protocol, and just need to start
    # requesting services by altering the amount in paymentTxT3, re-sign,
    # and send it to the server

    @paymentTotalTx3 += cost

    # Create a payment that is just a fully unlocked refund
    paymentTxT3Builder = @_createPayTxT3(@paymentTotalTx3, undefined).tx
    paymentTxT3 = paymentTxT3Builder.sign(@privkeyK1).build()

    params =
      "channel.id": @channelId
      "tx.payment": paymentTxT3.serialize().toString('hex')

    rpcClient.call "channel.pay", [params], {}, callback

  _createAgreementTxT1: (serverPubkeyK2) ->
    multiSigTxBuilder = CoinUtils.build2of2MultiSigTx @pubkeyK1, serverPubkeyK2, @maxPayment
    # TODO: What about all the input transactions? What are they signed with?
    multiSigTx = multiSigTxBuilder.sign([@privkeyK1]).build()
    return multiSigTx


  _createRefundTxT2: (timeToLock) ->
    return CoinUtils.buildRollingRefundTxFromMultiSigOutput @agreementTxT1, @pubkeyK1, 0, undefined, timeToLock

  _verifyServerSignedT2: (signature) ->
    return CoinUtils.verifyTxSig @refundTxT2, signature

  _createPayTxT3: (amount, serverPubKey) ->
    return CoinUtils.buildRollingRefundTxFromMultiSigOutput @agreementTxT1, @pubkeyK1, amount, serverPubKey, 0

