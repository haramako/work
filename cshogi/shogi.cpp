#include "shogi.h"
#include <string.h>
#include <assert.h>
#include <boost/uuid/sha1.hpp>
#include <stdio.h>

//================================
// Player
//================================

static const char* PLAYER_STRING[] = { "+", "-" };

const char* PlayerToString( Player player )
{
	assert( player < PLAYER_MAX );
	return PLAYER_STRING[player];
}

int PlayerDir( Player player ){ return player * 2 - 1; }
int PlayerSwitch( Player player ){ return 1-player; }

//================================
// KomaKind
//================================

static const char* KOMA_KIND_STRING[] = {
	"NN", "FU", "KY", "KE", "GI", "KI", "KA", "HI", "OU",
	"TO", "NY", "NK", "NG", "UM", "RY"
};

static const KomaKind KOMA_KIND_PROMOTE[] = {
	NN, TO, NY, NK, NG, KI, UM, RY, OU, TO, NY, NK, NG, UM, RY, KOMA_KIND_MAX
};

static const KomaKind KOMA_KIND_UNPROMOTE[] = {
	NN, FU, KY, KE, GI, KI, KA, HI, OU, FU, KY, KE, GI, KA, HI, KOMA_KIND_MAX
};

// 移動先のリスト
static int NN_MOVE_LIST[][2] = {{0,0}};
static int FU_MOVE_LIST[][2] = {{0,1},{0,0}};
static int KE_MOVE_LIST[][2] = {{1,2},{-1,2},{0,0}};
static int GI_MOVE_LIST[][2] = {{1,1},{0,1},{-1,1},{1,-1},{-1,-1},{0,0}};
static int KI_MOVE_LIST[][2] = {{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1},{0,0}};
static int OU_MOVE_LIST[][2] = {{1,1},{0,1},{-1,1},{1,0},{-1,0},{1,-1},{0,-1},{-1,-1},{0,0}};
static int UM_MOVE_LIST[][2] = {{0,1},{1,0},{-1,0},{0,-1},{0,0}};
static int RY_MOVE_LIST[][2] = {{1,1},{-1,1},{1,-1},{-1,-1},{0,0}};
typedef int (*pint2)[2];
static pint2 KOMA_MOVE_LIST[] = {
	NN_MOVE_LIST,
	FU_MOVE_LIST,
	NN_MOVE_LIST,
	KE_MOVE_LIST,
	GI_MOVE_LIST,
	KI_MOVE_LIST,
	NN_MOVE_LIST,
	NN_MOVE_LIST,
	OU_MOVE_LIST,
	KI_MOVE_LIST,
	KI_MOVE_LIST,
	KI_MOVE_LIST,
	KI_MOVE_LIST,
	UM_MOVE_LIST,
	RY_MOVE_LIST,
};

const char* KomaKindToString( KomaKind kind )
{
	assert( kind < KOMA_KIND_MAX );
	return KOMA_KIND_STRING[kind];
}

KomaKind KomaKindFromString( const string &str )
{
	for( KomaKind i=FU; i<KOMA_KIND_MAX; i++ ){
		if( str == KOMA_KIND_STRING[i] ){
			return i;
		}
	}
	return NN;
}

KomaKind KomaKindPromote( KomaKind kind )
{
	return KOMA_KIND_PROMOTE[kind];
}

KomaKind KomaKindUnpromote( KomaKind kind )
{
	return KOMA_KIND_UNPROMOTE[kind];
}

//================================
// Koma
//================================

string Koma::ToString() const {
	if( val == 0 ){
		return " * ";
	}else{
		return string(PlayerToString(GetPlayer())) + KomaKindToString(GetKind());
	}
}

//================================
// POS
//================================

string Pos::ToString() const {
	char buf[16];
	sprintf( buf, "%d%d", X(), Y() );
	return string(buf);
}

//================================
// Command
//================================

Command::Command( const string &src )
{
	if( src.length() < 7 ){
		throw ShogiException("invalid command");
	}

	if( src[0] == '+' ){ player = SENTE; }else{ player = GOTE; }
	from = Pos( src[1] - '0', src[2] - '0' );
	to   = Pos( src[3] - '0', src[4] - '0' );
	koma = KomaKindFromString( src.substr(5,2) );
}

string Command::ToString() const {
	return string(PlayerToString(player))+string(from)+string(to)
		+KomaKindToString(koma);
}

//================================
// Board
//================================

Board::Board( const Board *src )
{
	memcpy( cell, src->cell, sizeof(cell) );
	memcpy( hand, src->hand, sizeof(hand) );
	hash = 0;
}

void Board::Init()
{
	Clear();
	for( Player pl=0; pl<PLAYER_MAX; pl++ ){
		int dir = PlayerDir(pl);
		SetCell( Pos(1,5-dir*4), Koma(KY,pl) );
		SetCell( Pos(2,5-dir*4), Koma(KE,pl) );
		SetCell( Pos(3,5-dir*4), Koma(GI,pl) );
		SetCell( Pos(4,5-dir*4), Koma(KI,pl) );
		SetCell( Pos(5,5-dir*4), Koma(OU,pl) );
		SetCell( Pos(6,5-dir*4), Koma(KI,pl) );
		SetCell( Pos(7,5-dir*4), Koma(GI,pl) );
		SetCell( Pos(8,5-dir*4), Koma(KE,pl) );
		SetCell( Pos(9,5-dir*4), Koma(KY,pl) );
		SetCell( Pos(5-dir*3,5-dir*3), Koma(KA,pl) );
		SetCell( Pos(5+dir*3,5-dir*3), Koma(HI,pl) );
		for( int x=1; x<=9; x++ ){
			SetCell( Pos(x,5-dir*2), Koma(FU,pl) );
		}
	}
}

int64_t Board::Hash() const
{
	if( hash != 0 ) return hash;
	boost::uuids::detail::sha1 sha1;
	sha1.process_bytes( (unsigned char*)this, sizeof(Board) );
	unsigned int digest[5];
	sha1.get_digest( digest );
	hash = *((int64_t*)digest);
	return hash;
}

string Board::ToString() const
{
	string r("_9__8__7__6__5__4__3__2__1__\n");
	for( int y=1; y<=BOARD_SIZE; y++ ){
		// r += "+--+--+--+--+--+--+--+--+--+\n";
		string r1;
		string r2;
		for( int x=BOARD_SIZE; x>=1; x-- ){
			Koma koma = GetCell( Pos(x,y) );
			if( koma != BLANK ){
				string kstr( KomaKindToString(koma.GetKind()) );
				if( koma.GetPlayer() == SENTE ){
					r1 += "|/\\";
					r2 += "|"+kstr;
				}else{
					r1 += "|"+kstr;
					r2 += "|\\/";
				}
			}else{
				r1 += "|  ";
				r2 += "|__";
			}
		}
		r1 += "|\n";///*+y*/+"\n";
		r2 += "|\n";
		r += r1 + r2;
	}
	for( Player pl=0; pl<PLAYER_MAX; pl++ ){
		r += string(PlayerToString(pl)) + ": ";
		for( KomaKind kind=0; kind<KOMA_KIND_MAX; kind++ ){
			int num = hand[pl][kind];
			if( num > 0 ){
				char buf[4];
				sprintf( buf, "%d", num );
				r += string(KomaKindToString(kind)) + "x" + buf + ",";
			}
		}
		r += "\n";
	}
	return r;
}

Pos* Board::MoveStraight(Pos* out_pos, Pos pos, Player player, int dx, int dy ) const {
	for(;;){
		pos = Pos( pos.X() + dx, pos.Y() + dy );
		if( !pos.Inside() ) break;
		Koma koma = GetCell( pos );
		if( koma != BLANK && koma.GetPlayer() == player ) break;
		*out_pos++ = pos;
		if( koma != BLANK && koma.GetPlayer() != player ) break;
	}
	return out_pos;
}

int Board::ListMovable( Pos pos, Pos *out_pos ) const
{
	Pos *cur_pos = out_pos;
	Koma koma = GetCell( pos );
	if( koma.GetKind() == NN ) return 0;

	// 通常の移動
	int dir = PlayerDir( koma.GetPlayer() );
	for( pint2 to = KOMA_MOVE_LIST[koma.GetKind()]; (*to)[0] != 0 || (*to)[1] != 0; to++ ){
		Pos to_pos = Pos( pos.X() + (*to)[0], pos.Y() + dir * (*to)[1] );
		if( !to_pos.Inside() ) continue;
		Koma to_koma = GetCell( to_pos );
		if( to_koma != BLANK && to_koma.GetPlayer() == koma.GetPlayer() ) continue;
		*(cur_pos++) = to_pos;
	}

	// 複数マス直進する移動
	switch( koma.GetKind() ){
	case KY:
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(), 0, PlayerDir( koma.GetPlayer() ) );
		break;
	case HI:
	case RY:
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(),  1,  0 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(), -1,  0 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(),  0,  1 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(),  0, -1 );
		break;
	case KA:
	case UM:
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(),  1,  1 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(), -1,  1 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(),  1, -1 );
		cur_pos = MoveStraight( cur_pos, pos, koma.GetPlayer(), -1, -1 );
		break;
	}
	return cur_pos - out_pos;
}

static int fromTop( Player pl, int y)
{
	return ( pl == SENTE )?y:10-y;
}

// 不正(動けない駒)かどうかを確認する
static bool movable( Koma koma, Pos pos )
{
	switch( koma.GetKind() ){
	case FU:
	case KY:
		return fromTop(koma.GetPlayer(), pos.Y()) >= 2;
	case KE:
		return fromTop(koma.GetPlayer(), pos.Y()) >= 3;
	default:
		return true;
	}
}


int Board::ListMovableAll( Player pl, Command *out_com, bool allow_invalid ) const
{
	Command *cur_com = out_com;
	
	// 通常の移動
	Pos temp_pos[32];
	for( int y=1; y<=BOARD_SIZE; y++ ){
		for( int x=1; x<=BOARD_SIZE; x++ ){
			Pos pos = Pos(x,y);
			Koma koma = GetCell( pos );
			if( koma == BLANK || koma.GetPlayer() != pl ) continue;
			int len = ListMovable( pos, temp_pos );
			for( int i =0; i<len; i++ ){
				Pos to_pos = temp_pos[i];
				// 王をとれる場合は、それのみを返す
				if( !allow_invalid ){
					Koma to_cell = GetCell(to_pos);
					if( to_cell.GetKind() == OU ){
						*out_com = Command( pl, pos, to_pos, koma.GetKind() );
						return 1;
					}
				}
				// 動けない場所でないなら追加
				if( movable( koma, to_pos ) ){
					*cur_com++ = Command(pl, pos, to_pos, koma.GetKind());
				}
				// 成れる場合は、その選択肢も追加
				KomaKind promoted = KomaKindPromote( koma.GetKind() );
				if( promoted != koma.GetKind() ){
					if( fromTop(pl,to_pos.Y()) <= 3 || fromTop(pl,pos.Y()) <= 3 ){
						*cur_com++ = Command(pl, pos, to_pos, promoted );
					}
				}
			}
		}
	}

	// 打ち駒
	for( KomaKind kk = FU; kk<OU; kk++ ){
		if( hand[pl][kk] <= 0 ) continue;
		for( int x=1; x<=BOARD_SIZE; x++ ){
			// 二歩チェックリスト作成
			bool nifu = false;
			if( !allow_invalid && kk == FU ){
				for( int y=1; y<=BOARD_SIZE; y++ ){
					Koma koma = GetCell(Pos(x,y));
					if( koma.GetKind() == FU && koma.GetPlayer() == pl ){
						nifu = true;
						break;
					}
				}
			}

			for( int y=1; y<=BOARD_SIZE; y++ ){
				// 打てる場所を探す
				Pos to_pos = Pos(x,y);
				if( GetCell(to_pos) != BLANK ) continue;
				if( kk == FU && nifu ) continue; // 二歩チェック
				// 動けない場所でないならでないなら追加
				if( movable( Koma(kk,pl), to_pos ) ){
					*cur_com++ = Command(pl,KOMADAI,to_pos,kk);
				}
			}
		}
	}

	return cur_com - out_com;
}

void Board::Progress( Command com )
{
	if( com.from == KOMABAKO ){
		// 駒箱から取る
	}else if( com.from == KOMADAI ){
		// 打ち駒
		hand[com.player][com.koma] -= 1;
	}else{
		// それ以外
		Koma koma = GetCell( com.to );
		if( koma != BLANK ){
			KomaKind unpromoted = KomaKindUnpromote(koma.GetKind());
			hand[com.player][unpromoted] += 1;
		}
		SetCell( com.from, BLANK );
	}

	if( com.to == KOMABAKO ){
		// 駒箱に入れる
	}else if( com.to == KOMADAI ){
		// 駒台に置く
		hand[com.player][com.koma] += 1;
	}else{
		// 通常
		SetCell( com.to, Koma( com.koma, com.player) );
	}
	curPlayer = PlayerSwitch(com.player);
}

void Board::Clear()
{
	hash = 0;
	curPlayer = SENTE;
	memset( &cell, 0, sizeof(cell) );
	memset( &hand, 0, sizeof(hand) );
}


void ShogiInit()
{
}
