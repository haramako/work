.PHONY: all
all:
	coffee -c .

.PHONY: test
test: all
	vows --no-color node_modules/*_test.coffee

watch:
	coffee -w -c . | grep --color line

doc:
	coffee tools/make-doc > list.html

