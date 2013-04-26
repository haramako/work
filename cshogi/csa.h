#pragma once
#include "shogi.h"

class Kifu {
 public:
 Kifu():board(NULL){}
 Kifu(Board *_board, vector<Command>& _commands):board(_board),commands(_commands){}
	~Kifu(){ delete board; }
	Board* GetBoard() const { return board; }
	const vector<Command>& Commands() const { return commands; }
	
 private:
	Board *board;
	vector<Command> commands;
};

namespace csa {
	Kifu* parse( istream &in );
	Kifu* parse( const string &src );
}
