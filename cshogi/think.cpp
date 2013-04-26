#include "think.h"
#include <limits.h>

Node::Node( const Board *src ): Board(src)
{
	curPlayer = SENTE;
	point = INT_MIN;
}

Node::Node( const Node *src ): Board(src)
{
	curPlayer = src->curPlayer;
	point = INT_MIN;
}

bool Node::Stop() const
{
	return false;
}

int Node::Choose( Command com, Node **out_child ) const
{
	Node *child = new Node(this);
	child->Progress( com );
	
	*out_child = child;
	return 8;
}

const int POINT[] = {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0,100, 200, 200, 400, 500, 800,1000,99999, 600, 500, 500, 500,1000,1200,
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
			p += POINT[koma] * -PlayerDir(pl) * hand[pl][koma];
		}
	}

	point = p;

	return p;
}


const int COMMAND_LEN = 600;

pair<Command,int> SolvNode( State &state, Node *node, int sign, int level, int rest_level, int limit )
{
	state.count++;

	// リーフの場合
	if( rest_level <= 0 || node->Stop() ){
		return pair<Command,int>( NO_COMMAND, node->Point() * sign );
	}

	// キャッシュが利用できるなら帰る
	boost::unordered_map<uint64_t,CacheItem>::const_iterator it = state.cache.find(node->Hash());
	if( it != state.cache.end() ){
		const CacheItem &item = it->second;
		if( item.rest_level >= rest_level ) return pair<Command,int>( item.choice, item.point*sign );
	}

	Command choices[COMMAND_LEN];
	int choices_len = node->ListMovableAll(node->CurPlayer(), choices);

	// 選択肢がないなら帰る
	if( choices_len <= 0 ) return pair<Command,int>( NO_COMMAND, node->Point() * sign );

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
	int r_point = -INT_MAX;

	// 非並列バージョン
	int cut = 0;
	for( int i=0; i<choices_len; ++i ){
		cut = i;
		Command choice = choices[i];
		Node *child;
		// cout << "choose: " << level << " " << string(choice) << endl;
		int use_level = node->Choose( choice, &child );
		if( best_exists ){ use_level -= 4; best_exists = false; }
		pair<Command,int> result = SolvNode( state, child, -sign, level+1, rest_level-use_level, -r_point );
		int point = -result.second;
		delete child;
		if( r_point < point ){
			r_choice = choice;
			r_point = point;
			// アルファ/ベータカット
			if( point >= limit ) break;
		}
	}

	CacheItem item;
	item.rest_level = rest_level;
	item.point = r_point * sign;
	item.choice = r_choice;
	// cout << level << " " << string(r_choice) <<" "<< cut << "/" << choices_len << " " << limit << " " << r_point << " " << sign << endl;
	state.cache[node->Hash()] = item;
	
	return pair<Command,int>(r_choice,r_point);
}


pair<Command,int> Solv( Node *node, int level, int sign, int parallel)
{
	assert( sign == 1 || sign == -1 );
	State state;
	state.count = 0;
	state.cache.rehash(1000000);

	pair<Command,int> result;
	for( int lv=1; lv<=level; lv++ ){
		result = SolvNode( state, node, sign, 0, lv*8, INT_MAX );
	}
	// point = SolvNode( state, node, sign, 0, level*8, INT_MAX );
	
	cout << "count: " << state.count << " cache-size: " << state.cache.size() << endl;
	
	return result;
}
