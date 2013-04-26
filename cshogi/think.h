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
	boost::unordered_map<uint64_t,CacheItem> cache;
	int count;
};

class Node : public Board {
public:
	Node( const Board *src );
	Node( const Node *src );
	Player CurPlayer() const { return curPlayer; }
	bool Stop() const;
	int Choose( Command com, Node **out_child ) const;
	int Point() const;
	
	// Player curPlayer;
	mutable int point;
};

pair<Command,int> SolvNode( State *state, Node *node, int sign, int level, int rest_level, int limit );

pair<Command,int> Solv( Node *node, int level, int sign, int parallel);
