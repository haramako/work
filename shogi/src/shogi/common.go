package shogi

import (
	// "strconv"
	"strings"
	"errors"
	"fmt"
)

const BoardSize = 9

// プレイヤー番号.
type Player int8
const (
	Sente Player = iota
	Gote
	MaxPlayer
)

var PlayerString = []string{"+","-"}
var PlayerFromString = map[string]Player{"+":Sente, "-":Gote}
var PlayerReadableString = []string{"先手","後手"}
var PlayerDir = []int{ -1, 1 }

/** 前方のY方向( 先手:-1, 後手:1 ) */
func (p Player) Dir() int {
	return  PlayerDir[p]
}

/** 先手/後手の切り替え */
func (p Player) Switch() Player {
	return Gote-p
}

// 駒.
// 定数名等は、CSAに準拠
type KomaKind uint8

const (
	NN KomaKind = iota
	FU; KY; KE; GI; KI; KA; HI; OU; TO; NY; NK; NG; UM; RY
	MaxKomaKind
)

var KomaNari = []KomaKind{
	NN, TO, NY, NK, NG, NN, UM, RY, NN,
	NN, NN, NN, NN, NN, NN,
}
var KomaFunari = []KomaKind{
	NN, NN, NN, NN, NN, NN, NN, NN, NN,
	FU, KY, KE, GI, KA, HI,
}

var KomaReadableString = []string{"  ","歩","香","桂","銀","金","角","飛","王","と","成香","成桂","成銀","馬","龍"}
var KomaString = []string{"  ","FU","KY","KE","GI","KI","KA","HI","OU","TO","NY","NK","NG","UM","RY"}

var KomaFromReadableString = map[string]KomaKind{
	"":NN,
	"FU":FU,
	"KY":KY,
	"KE":KE,
	"GI":GI,
	"KI":KI,
	"KA":KA,
	"HI":HI,
	"OU":OU,
	"TO":TO,
	"NY":NY,
	"NK":NK,
	"NG":NG,
	"UM":UM,
	"RY":RY,
	"歩":FU,
	"香":KY,
	"桂":KE,
	"銀":GI,
	"金":KI,
	"角":KA,
	"飛":HI,
	"王":OU,
	"玉":OU, // 重複
	"と":TO,
	"成香":NY,
	"成桂":NK,
	"成銀":NG,
	"馬":UM,
	"龍":RY,
	"竜":RY, // 重複
}


func (k KomaKind) String() string {
	return KomaString[k]
}

func (k KomaKind) ReadableString() string {
	return KomaReadableString[k]
}

func (k KomaKind) KifuString() string {
	return KomaString[k]
}

func KomaFromString(str string) KomaKind {
	return KomaFromReadableString[str]
}

// 盤上の駒
type Koma uint8

func MakeKoma( kind KomaKind, player Player ) Koma {
	return Koma( int8(kind) | (int8(player) << 4) )
}

func (k Koma) Kind() KomaKind {
	return KomaKind( int(k) & 15 )
}
	
func (k Koma) Player() Player {
	return Player( k >> 4 )
}

// 文字列に変換する。Blankの場合は、"*"に変換する
func (k Koma) String() string {
	if k == Blank { return "*" }
	return PlayerString[k.Player()] + KomaReadableString[k.Kind()]
}

// ブランク駒
const Blank = Koma(0)

// 各駒の動ける先(飛車、角、香の複数移動分は含まない)
var KomaMoveList = [][][]int{
	{}, // NN
	{{0,1}}, // FU
	{}, // KY
	{{1,2},{-1,2}}, // KE
	{{1,1},{0,1},{-1,1},{1,-1},{-1,-1}}, // GI
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1}}, // KI
	{}, // KA
	{}, // HI
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{1,-1},{0,-1},{-1,-1}}, // OU
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1}}, // TO
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1}}, // NY
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1}}, // NK
	{{1,1},{0,1},{-1,1},{1,0},{-1,0},{0,-1}}, // NG
	{{1,0},{0,1},{0,-1},{-1,0}}, // UM
	{{1,1},{1,-1},{-1,1},{-1,-1}}, // RY
}

// 位置。
// X,Y ともに 1〜9の範囲をとる	
// 駒台は、例外的に{0,0}の値で 定数 Komadai で表す
// 駒箱は、例外的に{0,1}の値で 定数 Komabako で表す
type Pos uint8

// 駒台を表すPos
const Komadai = Pos(0)
const Komabako = Pos(1<<4)

var PosYReadableString = []string{"〇","一","二","三","四","五","六","七","八","九"}
var PosXReadableString = []string{"０","１","２","３","４","５","６","７","８","９"}
var POS_STRING_TO_NUM = map[string]int{
	"１":1, "２":2, "３":3, "４":4, "５":5, "６":6, "７":7, "８":8, "９":9,
	"一":1, "二":2, "三":3, "四":4, "五":5, "六":6, "七":7, "八":8, "九":9,
}

func MakePos( x, y int ) Pos {
	return Pos(y << 4 + x)
}

func (p Pos) X() int {
	return int(p & 15)
}

func (p Pos) Y() int {
	return int(p >> 4)
}

func (p Pos) Int() int {
	return int((p.Y()-1) * BoardSize + p.X()-1)
}

func (p Pos) KifuString() string {
	var r [2]uint8
	r[0] = uint8('0'+p.X())
	r[1] = uint8('0'+p.Y())
	return string(r[:])
	//return strconv.Itoa(p.X())+strconv.Itoa(p.Y())
}

func (p Pos) String() string {
	var r [2]uint8
	r[0] = uint8('0'+p.X())
	r[1] = uint8('0'+p.Y())
	return string(r[:])
	//return strconv.Itoa(p.X())+strconv.Itoa(p.Y())
}

// "１一".."９九"の文字列を返す
func (p Pos) ReadableString() string {
	return PosXReadableString[p.X()] + PosYReadableString[p.Y()]
}

// 盤上に含まれれていれば、trueを返す
func (p Pos) InSide() bool {
	return (p.Y()>=1 && p.Y()<=BoardSize) && (p.X()>=1 && p.X()<=BoardSize)
}

// 一手を表す
type Command struct {
	Player Player // プレイヤー
	From Pos // 移動元の位置
	To Pos // 移動先の位置
	Koma KomaKind // 駒
}

func MakeCommand( p Player, from Pos, to Pos, koma KomaKind ) Command {
	return Command{ p, from, to, koma }
}

func (s Command) String() string {
	return PlayerString[s.Player] + s.From.KifuString() + s.To.KifuString() + s.Koma.KifuString()
}

func ParseCommand(str string) (Command, error) {
	if len(str) < 7 { return Command{}, errors.New("invalid command str:"+str) }
	var player Player
	if str[0] == '+' { player = Sente }else{ player = Gote }
	from := MakePos( int(str[1]) - '0', int(str[2]) - '0' )
	to   := MakePos( int(str[3]) - '0', int(str[4]) - '0' )
	koma := KomaFromString( str[5:7] )
	return MakeCommand( player, from, to, koma ), nil
}

func ParseCommands(str string) ([]Command, error) {
	r := []Command{}
	fmt.Println(str)
	for _, line := range strings.Split(str,"\n") {
		if len(line) == 0 { continue }
		com, err := ParseCommand(line)
		fmt.Println( com )
		if err != nil { return nil, err }
		r = append( r, com )
	}
	return r, nil
}
