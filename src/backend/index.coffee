h5bp = require 'h5bp'
path = require 'path'
logger = require "#{__dirname}/logger"
Channel = require "#{__dirname}/channel"

Handlebars = require 'handlebars'
require './templates/index'
require './templates/error'

# Note that the directory tree is relative to the 'BACKEND_LIBDIR' Makefile
# variable (`lib` by default) directory
app = h5bp.createServer
  root: path.join(__dirname, "..", "public")
  www: false     # Redirect www.example.tld -> example.tld
  compress: true # gzip responses from the server

#if process.env.NODE_ENV is 'development'
  # Put development environment only routes + code here

app.get '/', (req, res) ->

  pubkey = req.query.pubkey
  privkey = req.query.privkey

  channel = new Channel(pubkey, privkey, 100000000)
  channel.createAndCommit().then(
    (result) ->
      # return res.send(500, err.message) if err?
      res.write 200, "Payment channel created\n"

      if process.env.NODE_ENV is 'development'
        # Loop every second making a new micropayment
        # This simulates a series of requests to access a chunk of API data, for
        # example
        interval = setInterval(
          ->
            channel.makeNewPayment(10000000).then(
              (result) ->
                res.write "New micropayment negotatiated\n----\nDOING X\n----\n"
              (err) ->
                clearInterval interval
                res.write err.message + "\n"
                return res.end()
            )

          1000
        )

    (err) ->
      console.error err.stack
      res.send(500, err.message)
  )


onError = (res, code, message, url, extra) ->

  error =
    error:
      code: code
      url: url

  error.error.extra = extra if extra?

  logger.error message, error

  res.send code, Handlebars.templates['error']
    code: code
    message: message


# The 404 Route
app.use (req, res, next) ->

  onError res, 404, "Page Not Found", req.url


# The error Route (ALWAYS Keep this as the last route)
app.use (err, req, res, next) ->

  onError res, 500, "There was an error", req.url,
    message: err.message
    stack: err.stack


app.listen 3000
logger.info "STARTUP: Listening on http://localhost:3000"
