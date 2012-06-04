
.PHONY: all
all: lib/fc/parser.rb

.PHONY: test
test: all
	rspec test
	cd test ; ./test-all

lib/fc/parser.rb: parser.y
	racc parser.y -o lib/fc/parser.rb

.PHONY: clean
clean:
	rm -f a.asm a.nes a.html lib/fc/parser.output lib/fc/parser.rb
