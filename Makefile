default: run-dev

BROWSER_SRCDIR = src/browser
BROWSER_MODULEDIR = $(BROWSER_SRCDIR)/module
BROWSER_DISTDIR = public
BROWSER_JSDIR = $(BROWSER_DISTDIR)/js
BROWSER_TMPL_SRCDIR = $(BROWSER_SRCDIR)/templates
BROWSER_TMPL_DISTDIR = tmp/templates

BROWSER_MODULES = $(shell find "$(BROWSER_MODULEDIR)" -maxdepth 2 -name "index.coffee" -type f)
BROWSER_LIB = $(BROWSER_MODULES:$(BROWSER_MODULEDIR)/%/index.coffee=$(BROWSER_JSDIR)/%.js)
SOURCE_MAPS = ""

BACKEND_JS_SRCDIR = src/backend
BACKEND_JS_LIBDIR = lib
BACKEND_TMPL_SRCDIR = $(BACKEND_JS_SRCDIR)/templates
BACKEND_TMPL_LIBDIR = $(BACKEND_JS_LIBDIR)/templates

TEMPLATE_EXTENSION = hbs
BINDIR = node_modules/.bin

TESTDIR = test

BACKEND_SRC = $(shell find "$(BACKEND_JS_SRCDIR)" -name "*.coffee" -type f)
BACKEND_LIB = $(BACKEND_SRC:$(BACKEND_JS_SRCDIR)/%.coffee=$(BACKEND_JS_LIBDIR)/%.js)

BACKEND_JSON = $(shell find "$(BACKEND_JS_SRCDIR)" -name "*.json" -type f)
BACKEND_JSON_LIB = $(BACKEND_JSON:$(BACKEND_JS_SRCDIR)/%.json=$(BACKEND_JS_LIBDIR)/%.json)

BACKEND_TMPL_SRC = $(shell find "$(BACKEND_TMPL_SRCDIR)" -name "*.$(TEMPLATE_EXTENSION)" -type f)
BACKEND_TMPL_LIB = $(BACKEND_TMPL_SRC:$(BACKEND_TMPL_SRCDIR)/%.$(TEMPLATE_EXTENSION)=$(BACKEND_TMPL_LIBDIR)/%.js)

BROWSER_TMPL_SRC = $(shell find "$(BROWSER_TMPL_SRCDIR)" -name "*.$(TEMPLATE_EXTENSION)" -type f)
BROWSER_TMPL_DIST = $(BROWSER_TMPL_SRC:$(BROWSER_TMPL_SRCDIR)/%.$(TEMPLATE_EXTENSION)=$(BROWSER_TMPL_DISTDIR)/%.$(TEMPLATE_EXTENSION).js)

# The below sed is essentially:
# sed 's,browser/src/templates/\(.*\).hbs,--alias /templates/\1.hbs:/../../tmp/templates/\1.hbs.js,g'
make_alias = $(shell echo $(file) | sed 's,$(BROWSER_TMPL_SRCDIR)/\(.*\)\.$(TEMPLATE_EXTENSION),--alias templates/\1.$(TEMPLATE_EXTENSION):../../../../$(BROWSER_TMPL_DISTDIR)/\1.$(TEMPLATE_EXTENSION).js,g')
BROWSER_TMPL_ALIASES := $(foreach file,$(BROWSER_TMPL_SRC),$(make_alias))

TEST = $(shell find "$(TESTDIR)" -name "*.coffee" -type f | sort)
CJSIFYEXTRAPARAMS =

COFFEE=$(BINDIR)/coffee --js
MOCHA=$(BINDIR)/mocha --compilers coffee:coffee-script-redux/register -r coffee-script-redux/register -r test-setup.coffee -u tdd -R dot
CJSIFY=$(BINDIR)/cjsify
HANDLEBARS=$(BINDIR)/handlebars
HANDLEBARS_PARAMS= --extension="$(TEMPLATE_EXTENSION)"

all: backend browser test

browser-templates: $(BROWSER_TMPL_DIST)
	$(eval CJSIFYEXTRAPARAMS += $(BROWSER_TMPL_ALIASES))

backend: $(BACKEND_TMPL_LIB) $(BACKEND_LIB) $(BACKEND_JSON_LIB)

backend-dev: backend

browser: browser-dep browser-all

browser-dev: browser-dev-dep browser-all

browser-all: browser-templates $(BROWSER_LIB)
# Cleanup temporarily compiled handlebars files
	@rm -f $(BROWSER_TMPL_DISTDIR)/*.$(TEMPLATE_EXTENSION).js

run-dev: browser-dev backend-dev node-dev

run: browser backend node-stage

node-dev:
	NODE_ENV=development node "$(BACKEND_JS_LIBDIR)/$(shell node -pe 'require("./package.json").main')"

node-stage:
	NODE_ENV=staging node "$(BACKEND_JS_LIBDIR)/$(shell node -pe 'require("./package.json").main')"

$(BACKEND_JS_LIBDIR)/%.js: $(BACKEND_JS_SRCDIR)/%.coffee
	@mkdir -p "$(@D)"
	$(COFFEE) --input "$<" >"$@"

$(BROWSER_JSDIR)/%.js $(BROWSER_JSDIR)/%.js.map: $(BROWSER_MODULEDIR)/%/index.coffee
	@mkdir -p "$(@D)"
	$(eval MODULE_NAME := $(notdir $(patsubst %/,%,$(<D))))
ifeq ($(SOURCE_MAPS),"true")
	$(eval CJSIFY_SOURCE_MAPS := --source-map "$(MODULE_NAME).js.map")
	$(CJSIFY) --root "$(dir $<)" --export "$(MODULE_NAME)" $(CJSIFY_SOURCE_MAPS) $(CJSIFYEXTRAPARAMS) "index.coffee" >"$@"
	@mv "$(MODULE_NAME).js.map" "$(BROWSER_JSDIR)/"
else
	$(CJSIFY) --root "$(dir $<)" --export "$(MODULE_NAME)" $(CJSIFYEXTRAPARAMS) "index.coffee" >"$@"
endif

$(BACKEND_TMPL_LIBDIR)/%.js: $(BACKEND_TMPL_SRCDIR)/%.$(TEMPLATE_EXTENSION)
	@mkdir -p "$(@D)"
	$(HANDLEBARS) "$<" --commonjs="handlebars" $(HANDLEBARS_PARAMS) --root="$(BACKEND_TMPL_SRCDIR)" --output "$@"

$(BACKEND_JS_LIBDIR)/%.json: $(BACKEND_JS_SRCDIR)/%.json
	@mkdir -p "$(@D)"
	@cp "$<" "$@"

$(BROWSER_TMPL_DISTDIR)/%.$(TEMPLATE_EXTENSION).js: $(BROWSER_TMPL_SRCDIR)/%.$(TEMPLATE_EXTENSION)
	@mkdir -p "$(@D)"
	$(HANDLEBARS) "$<" --commonjs="../../vendor/handlebars" $(HANDLEBARS_PARAMS) --root="$(BROWSER_TMPL_SRCDIR)" --output "$@"

browser-dev-dep:
	$(eval SOURCE_MAPS := true)
	$(eval CJSIFYEXTRAPARAMS := --inline-sources)

browser-dep:
	$(eval SOURCE_MAPS :=)
	$(eval CJSIFYEXTRAPARAMS := --minify)


.PHONY: phony-dep release test loc clean dep-dev run-dev run node browser
phony-dep:

VERSION = $(shell node -pe 'require("./package.json").version')
release-patch: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "patch")')
release-minor: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "minor")')
release-major: NEXT_VERSION = $(shell node -pe 'require("semver").inc("$(VERSION)", "major")')
release-patch: release
release-minor: release
release-major: release

release: all
	@printf "Current version is $(VERSION). This will publish version $(NEXT_VERSION). Press [enter] to continue." >&2
	@read nothing
	node -e "\
		var j = require('./package.json');\
		j.version = '$(NEXT_VERSION)';\
		var s = JSON.stringify(j, null, 2) + '\n';\
		require('fs').writeFileSync('./package.json', s);"
	git commit package.json -m 'Version $(NEXT_VERSION)'
	git tag -a "v$(NEXT_VERSION)" -m "Version $(NEXT_VERSION)"
	git push --tags origin HEAD:master

test:
	$(MOCHA) $(TEST)
$(TESTDIR)/%.coffee: phony-dep
	$(MOCHA) "$@"

loc:
	@wc -l "$(BROWSER_SRCDIR)"/* "$(BACKEND_JS_SRCDIR)"/*

clean:
	@rm -rf $(BACKEND_JS_LIBDIR) $(BROWSER_JSDIR)/*.js $(BROWSER_JSDIR)/*.map $(BROWSER_TMPL_DISTDIR)
