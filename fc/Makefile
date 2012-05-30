
.PHONY: all
all: parser.rb

.PHONY: test
test: all
	for i in `ls test/test_*.fc` ; do \
	  echo ./fc $$i && node emu.js a.nes ; \
	done

parser.rb: parser.y
	racc parser.y -o parser.rb

.PHONY: clean
clean:
	rm -f *.asm *.nes parser.output parser.rb
