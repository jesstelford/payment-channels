h5bp = require 'h5bp'
path = require 'path'
logger = require "#{__dirname}/logger"

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

  res.send 200, Handlebars.templates['index']({})


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
