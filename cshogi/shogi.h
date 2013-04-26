#pragma once
#include <string>
#include <vector>
#include <stdint.h>
#include <assert.h>
#include <iostream>

using namespace std;

/** 盤のサイズ */
const int BOARD_SIZE = 9;

class ShogiException {
 public:
 ShogiException( const string & _msg ): msg(_msg) {}
	virtual ~ShogiException() {}
	string msg;
};

/**
 * プレイヤー.
 */
typedef unsigned char Player;

enum { SENTE, GOTE, PLAYER_MAX };

const char* PlayerToString( Player player );

int PlayerDir( Player player );
int PlayerSwitch( Player player );

/**
 * コマの種類.
 */
typedef unsigned char KomaKind;

enum { NN, FU, KY, KE, GI, KI, KA, HI, OU, TO, NY, NK, NG, UM, RY, KOMA_KIND_MAX };

const char* KomaKindToString( KomaKind kind );
KomaKind KomaKindFromString( const string &str );
KomaKind KomaKindPromote( KomaKind kind );
KomaKind KomaKindUnpromote( KomaKind kind );

/**
 * 盤上の駒.
 */
class Koma {
 public:
 Koma():val(0){}
 Koma( KomaKind kind, Player player ):val( kind | player << 4){}
	KomaKind GetKind() const { return val & 15; }
	Player GetPlayer() const { return val >> 4; }
	unsigned char Val() const { return val; }
	string ToString() const;
	operator string() const { return ToString(); }
	bool operator==( const Koma &b ) const { return Val() == b.Val(); }
	bool operator!=( const Koma &b ) const { return Val() != b.Val(); }
 private:
	unsigned char val;
	
};

const Koma BLANK;

/**
 * 位置を表す. 
 * X,Y ともに 1〜9の範囲をとる	
 * 駒台は、例外的に{0,0}の値で 定数 KOMADAI で表す
 * 駒箱は、例外的に{0,1}の値で 定数 KOMABAKO で表す
 */
class Pos {
 public:
 Pos(){}
 Pos( const Pos &pos ): val(pos.val) {}
 Pos( int x, int y): val( y << 4 | x) {}
	int X() const { return val & 15; }
	int Y() const { return val >> 4; }
	bool Inside() const { return X() >= 1 && X() <= 9 && Y() >= 1 && Y() <= 9; }
	string ToString() const;
	operator string() const { return ToString(); }
	bool operator==( const Pos &dest ) const { return val == dest.val; }
	bool operator!=( const Pos &dest ) const { return val != dest.val; }
 private:
	unsigned char val;
};

const Pos KOMADAI(0,0);
const Pos KOMABAKO(0,1);


/**
 * 一手を表す.
 */
class Command {
 public:
 Command(){}
 Command( Player _p, Pos _from, Pos _to, KomaKind _koma ):
	player(_p), from(_from), to(_to), koma(_koma){}
	Command( const string &src );
	string ToString() const;
	operator string() const { return ToString(); }
	bool operator==( const Command &dest ) const { return player==dest.player && from==dest.from && to==dest.to && koma==dest.koma; }
	
	Player player; // プレイヤー
	Pos from; // 移動元の位置
	Pos to; // 移動先の位置
	KomaKind koma; // 駒
 private:
};

const Command NO_COMMAND(NN,Pos(0,0),Pos(0,0),0);


/**
 * 盤の状況.
 */
class Board {
 public:
	Board(){ Clear(); }
	Board( const Board *src );

	void Init();
	Koma GetCell(Pos pos) const { return cell[pos.X()-1][pos.Y()-1]; }
	void SetCell(Pos pos, Koma koma ){ cell[pos.X()-1][pos.Y()-1] = koma; Reset(); }
	void AddHand(Player pl, KomaKind koma){ hand[pl][koma] += 1; Reset(); }
	void RemoveHand(Player pl, KomaKind koma){ hand[pl][koma] -= 1; Reset(); }
	int64_t Hash() const;
	string ToString() const;
	int ListMovable( Pos pos, Pos *out_pos ) const;
	int ListMovableAll( Player pl, Command *out_com, bool allow_invalid = false ) const;

	void Progress( Command com );
	void Progress( const string &com ){ Progress( Command(com) ); }
	
	Koma cell [BOARD_SIZE][BOARD_SIZE];
	uint8_t hand[PLAYER_MAX][KOMA_KIND_MAX];
	mutable int64_t hash;
	Player curPlayer;
	// vector<Command> movableList;
 private:
	void Clear();
	void Reset(){ hash = 0; }
	Pos* MoveStraight(Pos* out_pos, Pos pos, Player player, int dx, int dy ) const;
};

void ShogiInit();
