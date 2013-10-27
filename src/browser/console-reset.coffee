# Provided by html5boilerplate.com
noop = ->
methods = [
  'assert', 'clear', 'count', 'debug', 'dir', 'dirxml', 'error',
  'exception', 'group', 'groupCollapsed', 'groupEnd', 'info', 'log',
  'markTimeline', 'profile', 'profileEnd', 'table', 'time', 'timeEnd',
  'timeStamp', 'trace', 'warn'
]
length = methods.length
console = (window.console = window.console || {})

while length--
  method = methods[length]

  # Only stub undefined methods.
  if not console[method]
    console[method] = noop
