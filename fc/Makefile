
.PHONY: all
all: parser.rb

parser.rb: parser.y
	racc -g parser.y -o parser.rb

.PHONY: clean
clean:
	rm -f *.asm *.nes
