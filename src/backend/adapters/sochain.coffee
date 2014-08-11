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

  # Mock out the call to sochain in dev
  if process.env.NODE_ENV is 'development'
    request = (opt, cb) ->
      result = {"status":"success","data":{"network":"BTCTEST","address":"mgwqzy6pF5BSc72vxHBFSnnhNEBcV4TJzV","txs":[{"txid":"3218e0dff04a299a56cac0a14a012ded03d73c4e73f2d224a5ec24b0d99b7b57","output_no":0,"script_asm":"OP_DUP OP_HASH160 0fad45372cc2267b9df9680465c1a54dcbebc4db OP_EQUALVERIFY OP_CHECKSIG","script_hex":"76a9140fad45372cc2267b9df9680465c1a54dcbebc4db88ac","value":"0.10000000","confirmations":1315,"time":1407393993},{"txid":"7e2b9220253d54a7b38ea62a5bc197ae684f68a5ccff726e69f74cb809eeaf90","output_no":0,"script_asm":"OP_DUP OP_HASH160 0fad45372cc2267b9df9680465c1a54dcbebc4db OP_EQUALVERIFY OP_CHECKSIG","script_hex":"76a9140fad45372cc2267b9df9680465c1a54dcbebc4db88ac","value":"3.00000000","confirmations":1315,"time":1407393993}]}}
      cb(null, {statusCode: 200}, result)

  request options, (err, response, body) ->

    if not err? and (response.statusCode isnt 200 or (body.status? and body.status isnt "success"))
      err = body.err or new Error body

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
