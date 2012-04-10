TARGET=ranksv
CFLAGS=-O2 -std=c99
SRC=ranked_store.c
OBJ=$(SRC:.c=.o)

default: $(TARGET)

$(TARGET): $(OBJ)
	$(CC) -o $@ $<

ranked_store.o: ranked_store.c ranked_store.h