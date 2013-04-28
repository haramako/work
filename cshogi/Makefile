CC=g++
SRCS=main.cpp shogi.cpp csa.cpp think.cpp
OBJS=$(SRCS:.cpp=.o)
CCFLAGS=-O2 -g -DNDEBUG
LDFLAGS=

shogi: $(OBJS)
	$(CC) $(LDFLAGS) $(OBJS) -o $@

clean:
	rm -f shogi *.o

.cpp.o:
	$(CC) $(CCFLAGS) -c $< -o $@

depends:
	$(CC) -MM $(SRCS) > .depends

include .depends
