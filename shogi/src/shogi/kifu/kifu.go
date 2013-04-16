package kifu

import (
	"fmt"
	"strings"
	"regexp"
	"errors"
	iconv "github.com/djimenez/iconv-go"
	. "shogi"
)

func atoi( c uint8 ) int {
	return int(c) - '0'
}

const _INIT_STR = 
"P1-KY-KE-GI-KI-OU-KI-GI-KE-KY\n" +
"P2 * -HI *  *  *  *  * -KA * \n" +
"P3-FU-FU-FU-FU-FU-FU-FU-FU-FU\n" +
"P4 *  *  *  *  *  *  *  *  * \n" +
"P5 *  *  *  *  *  *  *  *  * \n" +
"P6 *  *  *  *  *  *  *  *  * \n" +
"P7+FU+FU+FU+FU+FU+FU+FU+FU+FU\n" +
"P8 * +KA *  *  *  *  * +HI * \n" +
"P9+KY+KE+GI+KI+OU+KI+GI+KE+KY\n"

func Parse( str string ) ( *Board, []Command ) {
	var coms []Command
	b := new(Board)
	
	src := strings.Split( str, "\n" )
	version := 0
	for _,line := range src {
		if len(line) == 0 { continue }
		switch line[0] {
		case '\'':
			// コメント
		case 'V':
			version = atoi(line[1])
		case 'N':
			// 対戦者名
		case '$':
			// 付加情報
		case 'T':
			// 時間情報
		case '%':
			// 特殊コマンド
		case 'P':
			switch line[1] {
			case '1','2','3','4','5','6','7','8','9':
				y := int(line[1]) - '0'
				for i := 0; i <= 9; i++ {
					if len(line) <= 2+i*3 { break }
					if line[2+i*3] == '-' || line[2+i*3] == '+' {
						var player Player
						if line[2+i*3] == '+' { player = Sente }else{ player = Gote }
						koma := KomaFromString( line[2+i*3+1:2+i*3+3] )
						b.SetCell( MakePos(9-i,y), MakeKoma( koma, player ) )
					}
				}
				_ = y
			case 'I':
				new_b, _ := Parse( _INIT_STR )
				*b = *new_b
			case '+','-':
			default:
				println( line )
			}
		case '+','-':
			if len(line) == 1 {
				// 手番設定
				if( line == "+" ){
					b.Teban = Sente
				}else{
					b.Teban = Gote
				}
			}else{
				var player Player
				if line[0] == '+' { player = Sente }else{ player = Gote }
				from := MakePos( int(line[1]) - '0', int(line[2]) - '0' )
				to   := MakePos( int(line[3]) - '0', int(line[4]) - '0' )
				koma := KomaFromString( line[5:7] )
				coms = append( coms, MakeCommand( player, from, to, koma ) )
			}
		default:
			println( line )
		}
	}
	_ = version
	return b, coms
}

var KOMA_READABLE_MAP = map[string]KomaKind{
	"歩":FU,
	"香":KY,
	"桂":KE,
	"銀":GI,
	"金":KI,
	"角":KA,
	"飛":HI,
	"王":OU,
	"玉":OU,
	"と":TO,
	"成香":NY,
	"成桂":NK,
	"成銀":NG,
	"馬":UM,
	"龍":RY,
	"竜":RY,
}

type HumanKifuCommand int

const (
	KIFU_NONE HumanKifuCommand = iota
	KIFU_NARU
	KIFU_UTSU
	KIFU_MIGI
	KIFU_HIDARI
	KIFU_UE
	KIFU_SHITA
)

var KIFU_COMMAND_MAP = map[string]HumanKifuCommand {
	""   : KIFU_NONE,
	"成" : KIFU_NARU,
	"打" : KIFU_UTSU,
	"右" : KIFU_MIGI,
	"左" : KIFU_HIDARI,
	"上" : KIFU_UE,
	"下" : KIFU_SHITA,
}
var KIFU_COMMAND_STRING = []string{"","成","打","右","左","上","下"}

type HumanKifu struct {
	Player Player
	To Pos
	Koma KomaKind
	Command HumanKifuCommand
}

func (k HumanKifu) String() string {
	return []string{"▲","△"}[k.Player] + k.To.ReadableString() +
		k.Koma.String() + KIFU_COMMAND_STRING[k.Command]
}

func ParseKi2( str string ) []HumanKifu {
	r := []HumanKifu{}
	src := strings.Split( str, "\n" )
	re, err := regexp.Compile(
		"(△|▲)([１２３４５６７８９一二三四五六七八九同]+)[ 　]*" +
		"(歩|香|桂|銀|金|角|飛|王|玉|と|成香|成桂|馬|竜|龍)(成|打|右|左|上|下)?")
	if err != nil { fmt.Println( err ); return nil }
	var pos Pos
	for _, line := range src {
		if len(line) <= 0 || line[0] == '*' { continue } // コメント
		for _, s := range re.FindAllStringSubmatch( line, -1 ) {
			var pl Player
			if s[1] == "▲" { pl = Sente }else{ pl = Gote }
			if s[2] != "同" {
				x := POS_STRING_TO_NUM[s[2][0:3]]
				y := POS_STRING_TO_NUM[s[2][3:6]]
				pos = MakePos( int(x), int(y) )
			}
			koma := KOMA_READABLE_MAP[s[3]]
			com := KIFU_COMMAND_MAP[s[4]]
			kifu := HumanKifu{ pl, pos, koma, com }
			r = append( r, kifu )
		}
	}
	b, _ := Parse( "PI" )
	ProgressHumanKifu( b, r )
	return r
}

func ConvertEncodingAuto( src []byte ) ( []byte, error ){
	out := make([]byte, 8192)
	for _, encoding := range []string{"CP932","utf-8"} {
		_, _, err := iconv.Convert( src, out, encoding, "utf-8")
		if err == nil { return out, nil }
	}
	return nil, errors.New("cannot convert string")
}

func ProgressHumanKifu( b *Board, kifu []HumanKifu ) {
	for _, k := range kifu {
		// fmt.Println( k )
		if k.Command == KIFU_NARU { k.Koma = KomaNari[k.Koma] }
		
		coms := b.ListMovableAll( k.Player )
		// fmt.Println( tes )
		var matchs []Command
		for _, com := range coms {
			if com.To == k.To && com.Koma == k.Koma {
				matchs = append( matchs, com )
			}
		}
		var match Command
		switch k.Command {
		case KIFU_MIGI, KIFU_HIDARI, KIFU_UE, KIFU_SHITA:
			if( len(matchs) <= 1 ){ return }
			// TODO: ちゃんと選ぶ
			match = matchs[0]
		case KIFU_UTSU:
			if( len(matchs) <= 1 ){ return }
			// 打ち駒を選ぶ
			for _, com := range matchs {
				if com.From == Komadai{
					match = com
					break
				}
			}
		default:
			if len(matchs) == 1 {
				match = matchs[0]
			}else if len(matchs) != 1 {
				// 打ち駒が混じっている場合、排除する
				for _, com := range matchs {
					if com.From != Komadai {
						match = com
						break
					}
				}
			}else{
				return
			}
		}

		//fmt.Println( match )
		b.Progress( match )
	}
	fmt.Println( b )
}