default: cfd

cfd: cfd.cc
	g++ -O3 -std=c++11 -Wall -ffast-math cfd.cc -o cfd

test1.json: cfd
	time ./cfd > test1.json

test1.gif: test1.json plot.rb
	time ruby plot.rb

