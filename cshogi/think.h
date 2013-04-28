#pragma once
#include "shogi.h"
#include <boost/unordered_map.hpp>

struct CacheItem {
	int rest_level;
	int point;
	Command choice;
};

class State {
 public:
 State():nodeCount(0),leafCount(0),cacheHit(0){}
	boost::unordered_map<uint64_t,CacheItem> cache;
	int nodeCount;
	int leafCount;
	int cacheHit;
};

class Node : public Board {
public:
	Node(){};
	Node( const Board *src );
	Node( const Node *src ){ Copy(src); }
	void Copy( const Node *src );
	Player CurPlayer() const { return curPlayer; }
	bool Stop() const;
	int Choose( Command com, Node &out_child ) const;
	int Point() const;
	
	void CalcKiki() const;
	int CalcKikiPoint() const;
	// Player curPlayer;
	mutable int point;
	mutable int8_t kiki[PLAYER_MAX][BOARD_SIZE][BOARD_SIZE];
};

pair<Command,int> SolvNode( State *state, const Node &node, int sign, int level, int rest_level, int limit );

pair<Command,int> Solv( const Node &node, int level, int sign, int parallel);
