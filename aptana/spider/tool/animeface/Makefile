all: animeface

animeface: animeface.cpp
	g++ -o animeface animeface.cpp `pkg-config opencv --cflags --libs`

clean:
	rm -f *.o animeface
