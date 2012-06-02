
.PHONY: all
all: lib/fc/parser.rb

.PHONY: test
test: all
	cd test ; ./test-all

lib/fc/parser.rb: parser.y
	racc parser.y -o lib/fc/parser.rb

.PHONY: clean
clean:
	rm -f a.asm a.nes parser.output parser.rb
