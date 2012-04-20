.PHONY: all
all:
	coffee -c *.coffee

.PHONY: test
test: all
	vows --no-color *_test.coffee

watch:
	coffee -w -c *.coffee
