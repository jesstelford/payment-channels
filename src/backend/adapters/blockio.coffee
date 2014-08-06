Q = require 'q'
request = require 'request'

buildUrl = (address) ->
  # TODO: Build a valid GET url
  return "#{address}"

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

    if not err? and (response.statusCode isnt 200 or (body.error? and body.success isnt 1))
      err = body.err

    next err, body

pushTransaction = (transaction, next) ->
  # Never succeed
  q.nextTick ->
    next new Error "Not implemented"

module.exports = {unspentOutputs, pushTransaction}
