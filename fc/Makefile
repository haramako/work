
.PHONY: all
all: parser.rb

.PHONY: test
test: all
	cd test ; ./test-all

parser.rb: parser.y
	racc parser.y -o parser.rb

.PHONY: clean
clean:
	rm -f *.asm *.nes parser.output parser.rb
