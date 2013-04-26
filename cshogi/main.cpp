#include <stdio.h>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iterator>
#include "shogi.h"
#include "csa.h"
#include "think.h"

void help_mode()
{
	cout << "./shogi board kifu.csa level\n";
	exit(0);
}

void test_mode(int argc, char **argv )
{
	/*
	cout << BLANK.ToString() << endl;
	printf( "%ld\n", sizeof(Koma) );
	cout << string(Koma(OU,SENTE)) << endl;
	cout << string(KOMABAKO) << endl;
	cout << Pos(1,1).ToString() << " " << Pos(1,1).Inside() << endl;
	cout << string(Command("+0113OU")) << endl;

	Board *b = new Board();
	b->Init();
	b->Progress( "+7776FU" );
	cout << b->ToString() << endl;
	*/

	/*
	Pos pos[100];
	int len = b->ListMovable( Pos(2,8), pos );
	for( int i=0; i<len; i++ ){
		cout << string(pos[i]) << ",";
	}
	cout << endl;

	Command com[200];
	int clen = b->ListMovableAll( SENTE, com );

	
	for( int i=0; i<clen; i++ ){
		cout << string(com[i]) << "\n";
	}
	cout << endl;
	*/

	ifstream ifs(argv[0]);

	cout << "cheking " << argv[0] << endl;
	
	//copy( istreambuf_iterator<char>(ifs), istreambuf_iterator<char>(), ostream_iterator<char>(cout) );
	
	Kifu *kifu = csa::parse( ifs );
	Board *board = kifu->GetBoard();
	// cout << board->Hash() << endl;
	
	int i = 0;
	// cout << board->ToString() << endl;
	for( vector<Command>::const_iterator it=kifu->Commands().begin(); it!=kifu->Commands().end(); ++it,++i ){
		// cout << i << ":" << string(*it) << "\n";
		
		Command com[600];
		int clen = board->ListMovableAll( board->curPlayer, com );
		bool found = false;
		for( int j=0; j<clen; j++ ){
			// cout << string(com[j]) << endl;
			if( com[j] == *it ){
				found = true;
				break;
			}
		}
		if( !found ){
			cout << board->ToString() << endl;
			cout << "ERROR:" << i << " " << string(*it) << endl;
			exit(1);
		}
		
		board->Progress( *it );
	}

}

void board_mode(int argc, char **argv )
{
	if( argc < 2 ) help_mode();
	string path = argv[0];
	int level = atoi(argv[1]);

	ifstream ifs(path.c_str());
	if( !ifs ){ throw ShogiException( "file "+path+" not found"); }
	Kifu *kifu = csa::parse( ifs );
	
	Node *node = new Node( kifu->GetBoard() );
	for( vector<Command>::const_iterator it=kifu->Commands().begin(); it!=kifu->Commands().end(); ++it ){
		node->Progress( *it );
	}
	cout << node->ToString() << endl;

	pair<Command,int> result = Solv( node, level, 1, 0 );
	cout << "point: " << result.second << " " << string(result.first) << endl;
}

int main(int argc, char **argv )
{
	if( argc <= 1 ) help_mode();

	string mode(argv[1]);
	if( mode == "board" ){
		board_mode( argc-2, argv+2 );
	}else if( mode == "test" ){
		test_mode( argc-2, argv+2 );
	}else{
		help_mode();
	}
}
