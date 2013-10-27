# This file will be exported to the global namespace as a commonJS module based
# on the `BROWSER_MAIN_MODULE' variable set in Makefile
require '../../console-reset'

Handlebars = require '../../vendor/handlebars'
require 'templates/test.hbs'
appContainer = document.getElementById 'app'
appContainer.innerHTML = Handlebars.templates['test']({whatIsIt: 'test'})
