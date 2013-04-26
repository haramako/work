CC=g++
SRCS=main.cpp shogi.cpp csa.cpp think.cpp
OBJS=$(SRCS:.cpp=.o)
CCFLAGS=-O3 -g
LDFLAGS=

shogi: $(OBJS)
	$(CC) $(CCFLAGS) $(OBJS) -o $@

clean:
	rm -f shogi *.o

.cpp.o:
	$(CC) $(LDFLAGS) -c $< -o $@

depends:
	$(CC) -MM $(SRCS) > .depends

include .depends
