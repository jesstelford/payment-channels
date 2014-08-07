_ = require 'underscore'
Q = require 'q'
request = require 'request'

network = if process.env.NODE_ENV is 'production'
  'BTC'
else
  'BTCTEST'

buildUrl = (address) ->
  return "http://chain.so/api/v2/get_tx_unspent/#{network}/#{address}"

###
Expected output format:
[{
  address: pubkeyHex1
  txid: "39c71ebda371f75f4b854a720eaf9898b237facf3c2b101b58cd4383a44a6adc"
  vout: 1
  scriptPubKey: "76a914e867aad8bd361f57c50adc37a0c018692b5b0c9a88ac"
  amount: 0.4296 (BTC)
  amountSat: 0.4296 (Satoshis)
  confirmations: 1
}]
###
unspentOutputs = (address, next) ->

  options =
    url: buildUrl address
    method: 'GET'
    json: true

  request options, (err, response, body) ->

    if not err? and (response.statusCode isnt 200 or (body.status? and body.status isnt "success"))
      err = body.err

    result = _(body.data.txs).map (txn) ->
      return {
        address: body.data.address
        txid: txn.txid
        vout: txn.output_no
        scriptPubKey: txn.script_hex
        amount: txn.value
        confirmations: txn.confirmations
      }

    next err, result

pushTransaction = (transaction, next) ->
  # Never succeed
  q.nextTick ->
    next new Error "Not implemented"

module.exports = {unspentOutputs, pushTransaction}
