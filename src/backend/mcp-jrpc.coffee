Q = require "q"
rpcClient = require "#{__dirname}/jrpcClient"

module.exports = (httpOpts) ->

  return {
    request: (method, params) ->
      return Q.nfcall(rpcClient.request, method, [params], httpOpts)
  }
