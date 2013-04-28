#include "think.h"
#include <limits.h>

Node::Node( const Board *src ): Board(src)
{
	curPlayer = SENTE;
	point = INT_MIN;
	Reset();
}

void Node::Copy( const Node *src )
{
	Board::Copy( src );
	curPlayer = src->curPlayer;
	point = INT_MIN;
	Reset();
}

bool Node::Stop() const
{
	return abs(Point())>10000;
}

int Node::Choose( Command com, Node &out_child ) const
{
	out_child.Copy(this);
	out_child.Progress( com );
	out_child.hash = 0;
	return 8;
}

const int POINT[] = {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0,100, 200, 200, 400, 500, 800,1000,99999, 600, 500, 500, 500,1000,1200,
};

const int KIKI_POINT[] = {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0,100, 200, 200, 400, 500, 800,1000, 2000, 600, 500, 500, 500,1000,1200,
};

int Node::Point() const
{
	if( point != INT_MIN ) return point;
	
	int p = 0;
	for( int y=1; y<=BOARD_SIZE; y++ ){
		for( int x=1; x<=BOARD_SIZE; x++ ){
			Koma koma = GetCell( Pos(x,y) );
			if( koma == BLANK ) continue;
			p += POINT[koma.GetKind()] * -PlayerDir(koma.GetPlayer());
		}
	}
	for( Player pl=SENTE; pl<=GOTE; pl++ ){
		for( KomaKind koma=FU; koma<OU; koma++ ){
			if( hand[pl][koma] == 0 ) continue;
			p += POINT[koma] * -PlayerDir(pl) * hand[pl][koma] * 1.2;
		}
	}

	p += CalcKikiPoint();
	point = p;// + rand()%10 - 5;

	return point;
}

void Node::CalcKiki() const
{
	Pos move_to_buf[32];
	memset( kiki, 0, sizeof(kiki) );
	for( int y=1; y<=BOARD_SIZE; y++ ){
		for( int x=1; x<=BOARD_SIZE; x++ ){
			Pos pos(x,y);
			Koma koma( GetCell(pos) );
			if( koma == BLANK ) continue;
			int kiki_len = ListMovable( pos, move_to_buf );
			for( int i=0; i<kiki_len; ++i ){
				kiki[koma.GetPlayer()][pos.X()-1][pos.Y()-1] += 1;
			}
		}
	}
}

int Node::CalcKikiPoint() const
{
	CalcKiki();
	int p = 0;
	for( int y=1; y<=BOARD_SIZE; y++ ){
		for( int x=1; x<=BOARD_SIZE; x++ ){
			Pos pos(x,y);
			Koma koma( GetCell( pos ) );
			if( koma == BLANK ) continue;
			Player pl = koma.GetPlayer();
			if( kiki[pl][pos.X()-1][pos.Y()-1] < kiki[PlayerSwitch(pl)][pos.X()-1][pos.Y()-1] ){
				p += KIKI_POINT[koma.GetKind()] * PlayerDir(pl) * 10;
			}else if( kiki[PlayerSwitch(pl)][pos.X()-1][pos.Y()-1] > 0 ){
				p += KIKI_POINT[koma.GetKind()] * PlayerDir(pl);
			}
		}
	}
	return p/100;
}

const int COMMAND_LEN = 600;

pair<Command,int> SolvNode( State &state, const Node &node, int sign, int level, int rest_level, int alpha, int beta )
{

	// リーフの場合
	if( ( rest_level <= 0 && level % 2 == 1 ) || node.Stop() ){
		state.leafCount++;
		return pair<Command,int>( NO_COMMAND, node.Point() * sign );
	}
	
	state.nodeCount++;

	// キャッシュが利用できるなら帰る
	boost::unordered_map<uint64_t,CacheItem>::const_iterator it = state.cache.find(node.Hash());
	if( it != state.cache.end() ){
		const CacheItem &item = it->second;
		if( item.rest_level >= rest_level ){
			state.cacheHit++;
			return pair<Command,int>( item.choice, item.point*sign );
		}
	}

	Command choices[COMMAND_LEN];
	int choices_len = node.ListMovableAll(node.CurPlayer(), choices);

	// 選択肢がないなら帰る
	if( choices_len <= 0 ) return pair<Command,int>( NO_COMMAND, node.Point() * sign );

	// 前回のベスト選択肢を先頭にする
	bool best_exists = false;
	Command best_choice;
	if( it != state.cache.end() ){
		const CacheItem &item = it->second;
		best_choice = item.choice;
		if( best_choice.koma != NN ){
			best_exists = true;
			for( int i=0; i<choices_len; ++i ){
				if( best_choice == choices[i] ){
					choices[i] = choices[0];
					choices[0] = best_choice;
					break;
				}
			}
		}
	}
	
	Command r_choice = NO_COMMAND;

	for( int i=0; i<choices_len; ++i ){
		Command choice = choices[i];
		Node child;
		// cout << "choose: " << level << " " << string(choice) << endl;
		int use_level = node.Choose( choice, child );
		if( best_exists ){
			// キャッシュ上の最善手は、0.5手上乗せする
			use_level -= 4;
			best_exists = false;
		}

		for( int rest=0; rest+8<rest_level-use_level; rest+=8 ){
			SolvNode( state, child, -sign, level+1, rest, -beta, -alpha );
		}
		pair<Command,int> result = SolvNode( state, child, -sign, level+1, rest_level-use_level, -beta, -alpha );
		
		int point = -result.second;
		// if( level == 0 ) cout << string(choice) << " " << point << " " << string(result.first) << endl;
		if( alpha < point ){
			r_choice = choice;
			alpha = point;
			// アルファ/ベータカット
			if( alpha >= beta ) break;
		}
	}

	CacheItem item;
	item.rest_level = rest_level;
	item.point = alpha * sign;
	item.choice = r_choice;
	// cout << level << " " << string(r_choice) <<" "<< choices_len << " " << limit << " " << alpha << " " << sign << endl;

	state.cache[node.Hash()] = item;
	
	return pair<Command,int>(r_choice,alpha);
}


pair<Command,int> Solv( const Node &node, int level, int sign, int parallel)
{
	assert( sign == 1 || sign == -1 );
	
	State state;
	pair<Command,int> result = SolvNode( state, node, sign, 0, level*8, -INT_MAX, INT_MAX );

	printf( "count:%dN + %dL = %d cache-size:%ld %2.1f%%\n",
			state.nodeCount,
			state.leafCount,
			state.nodeCount+state.leafCount,
			state.cache.size(),
			(100.0*state.cacheHit/state.nodeCount) );
	
	return result;
}
