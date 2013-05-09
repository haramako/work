CC=gcc
SRCS=main.c lisp.c cfunc.c
OBJS=$(SRCS:.c=.o)
CFLAGS=-Wall -O2 -g -std=c99 # -DNDEBUG
LDFLAGS=-lm

mlisp: $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@

clean:
	rm -f mlisp *.o

depends:
	$(CC) -MM $(SRCS) > .depends

include .depends
