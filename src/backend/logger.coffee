fs = require 'fs'
path = require('path')
winston = require 'winston'

if process.env.NODE_ENV isnt 'development'

  if process.env.LOG_DIR? and fs.existsSync process.env.LOG_DIR
    logDir = process.env.LOG_DIR
  else
    # Default log dir as local directory
    # `main` is executed within `lib`
    appDir = "#{path.dirname(require.main.filename)}/.."
    logDir = "#{appDir}/log"

    if not fs.existsSync logDir
      fs.mkdirSync logDir

  console = false
  errorFile = "#{logDir}/application-error.log"
  logFile = "#{logDir}/application.log"
else
  console = true
  errorFile = false
  logFile = false


transports = []
transports.push(new (winston.transports.Console)()) if !!console
transports.push(new (winston.transports.File) { filename: logFile }) if !!logFile

logger = new (winston.Logger) {transports}

# Since winston can only handle a single instance of a particular trasport for
# each logger, but we want 2 seperate files for logging to (one just for 'error'
# level, and the other for everything), we have to create a second logger.
if !!errorFile
  errorFileLogger = new (winston.Logger)
    transports: [new (winston.transports.File) { filename: errorFile, level: 'error' }]

  # Listen to log events and push them through into our secondary logger too
  logger.on 'logging', (transport, level, msg, meta) ->
    errorFileLogger.log level, msg, meta

# Only export the one logger
module.exports = logger
