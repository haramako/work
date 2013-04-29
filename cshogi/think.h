#pragma once
#include "shogi.h"
#include <boost/unordered_map.hpp>

struct CacheItem {
	CacheItem(){}
CacheItem( int _rest_level, int _point, Command _choice ):rest_level(_rest_level),point(_point),choice(_choice){}
	int rest_level;
	int point;
	Command choice;
};

class State {
 public:
 State():nodeCount(0),leafCount(0),cacheHit(0){memset(levelCount,0,sizeof(levelCount));}
	boost::unordered_map<uint64_t,CacheItem> cache;
	int nodeCount;
	int leafCount;
	int cacheHit;
	int levelCount[32];
};

class Node : public Board {
public:
 Node( bool initialized = false ):Board(initialized){ if( initialized ){ point = INT_MIN; kikiUpdated = false; } };
	Node( const Board *src );
	Node( const Node *src ){ Copy(src); }
	void Copy( const Node *src );
	Player CurPlayer() const { return curPlayer; }
	bool Stop() const;
	int Choose( Command com, Node &out_child, int level ) const;
	int Point() const;
	int GetKiki( Player pl, Pos pos ) const { return kiki[pl][pos.X()-1][pos.Y()-1]; }
	
	void CalcKiki() const;
	int CalcKikiPoint() const;
	// Player curPlayer;
	mutable int point;
	mutable int8_t kiki[PLAYER_MAX][BOARD_SIZE][BOARD_SIZE];
	mutable bool kikiUpdated;
};

pair<Command,int> SolvNode( State *state, const Node &node, int sign, int level, int rest_level, int limit );

pair<Command,int> Solv( const Node &node, int level, int sign, int parallel);
