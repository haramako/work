#include "csa.h"
#include <boost/algorithm/string.hpp>
#include <iostream>

namespace csa {
	
Kifu* parse( istream &in )
{
	Kifu *kifu = new Kifu();
	Board *board = new Board();
	vector<Command> coms;

	string line;
	while( in && getline( in, line ) ){
		if( line.length() == 0 ) continue;
		switch( line[0] ){
		case '\'': // コメント
		case 'N': // 対戦者名
		case '$': // 付加情報
		case 'T': // 時間情報
		case '%': // 特殊コマンド
		case 'V': // バージョン
			break;
		case 'P':
			switch( line[1] ){
			case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
				{
					int y = line[1] - '0';
					for( int i = 0; i <= BOARD_SIZE; i++ ){
						if( line.length() <= 2+i*3 ) break;
						if( line[2+i*3] == '-' || line[2+i*3] == '+' ){
							Player player = (line[2+i*3] == '+' )?SENTE:GOTE;
							KomaKind koma = KomaKindFromString( line.substr(2+i*3+1,2).c_str() );
							board->SetCell( Pos(9-i,y), Koma( koma, player ) );
						}
					}
				}
				break;
			case 'I':
				board->Init();
				break;
			case '+':
			case '-':
				{
					Player player = (line[1] == '+')?SENTE:GOTE;
					for( int i=0; i<(line.length()-2)/4; ++i ){
						Pos pos(line[i*4+2] - '0', line[i*4+3] - '0');
						KomaKind koma = KomaKindFromString( line.substr(i*4+4,2).c_str() );
						if( pos == KOMADAI ){
							board->hand[player][koma] += 1;
						}else{
							board->SetCell( pos, Koma( koma, player ) );
						}
					}
				}
				break;
			default:
				cout << line << endl;
				break;
			}
			break;
		case '+':
		case '-':
			if( line.length() == 1 ){
				board->curPlayer = (line[0] == '+')?SENTE:GOTE;
			}else{
				coms.push_back( Command( line ) );
			}
			break;
		default:
			cout << line << endl;
		}
	}

	return new Kifu( board, coms );
}
	
}
