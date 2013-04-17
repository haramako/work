package ki2

import (
	"fmt"
	"strings"
	"regexp"
	. "shogi"
	. "shogi/kifu"
)

type Ki2Kifu struct {
	KifuBase
}

func Load( src string ) (Kifu, error) {
	return Parse( src )
}

func Parse( str string ) (*Ki2Kifu, error) {
	r := new(Ki2Kifu)
	r.AInfo = map[string]string{}
	src := strings.Split( str, "\n" )
	re, err := regexp.Compile(
		"(△|▲)([１２３４５６７８９一二三四五六七八九同]+)[ 　]*" +
		"(歩|香|桂|銀|金|角|飛|王|玉|と|成香|成桂|成銀|馬|竜|龍)(右|左)?(上|引|寄|直|行)?(成|打)?")
	if err != nil { fmt.Println( err ); return r, err }
	var pos Pos
	for _, line := range src {
		if len(line) <= 0 || line[0] == '*' { continue } // コメント
		line = strings.TrimSpace(line)
		// 付加情報
		if strings.Index(line,"：") >= 0 {
			pair := strings.SplitN(line,"：",2)
			r.AInfo[pair[0]] = pair[1]
			continue
		} 
		for _, s := range re.FindAllStringSubmatch( line, -1 ) {
			var pl Player
			if s[1] == "▲" { pl = Sente }else{ pl = Gote }
			if s[2] != "同" {
				x := POS_STRING_TO_NUM[s[2][0:3]]
				y := POS_STRING_TO_NUM[s[2][3:6]]
				pos = MakePos( int(x), int(y) )
			}
			koma := KomaFromReadableString[s[3]]
			side := SideFromString[s[4]]
			moving := MovingFromString[s[5]]
			naru := (s[6] == "成")
			utsu := (s[6] == "打")
			k := HumanKifu{ s[0], pl, pos, koma, side, moving, naru, utsu }
			// fmt.Println( s[0], kifu )
			r.AHumanCommands = append( r.AHumanCommands, k )
		}
	}
	//b, _ := Parse( "PI" )
	// ProgressHumanKifu( b, r )
	return r, nil
}

func (k *Ki2Kifu) Board() *Board {
	b := InitBoard()
	ochi, exists := k.AInfo["手合割"]
	if exists {
		switch ochi {
		case"角落ち":
			b.SetCell(MakePos(2,2), Blank)
		case"飛車落ち":
			b.SetCell(MakePos(8,2), Blank)
		case"香落ち":
			b.SetCell(MakePos(1,1), Blank)
		case"右香落ち":
			b.SetCell(MakePos(9,1), Blank)
		case"飛香落ち":
			b.SetCell(MakePos(8,2), Blank)
			b.SetCell(MakePos(1,1), Blank)
		case"二枚落ち":
			b.SetCell(MakePos(2,2), Blank)
			b.SetCell(MakePos(8,2), Blank)
		case"三枚落ち":
			b.SetCell(MakePos(1,1), Blank)
			b.SetCell(MakePos(2,2), Blank)
			b.SetCell(MakePos(8,2), Blank)
		case"四枚落ち":
			b.SetCell(MakePos(1,1), Blank)
			b.SetCell(MakePos(9,1), Blank)
			b.SetCell(MakePos(2,2), Blank)
			b.SetCell(MakePos(8,2), Blank)
		case"六枚落ち":
			b.SetCell(MakePos(1,1), Blank)
			b.SetCell(MakePos(2,1), Blank)
			b.SetCell(MakePos(8,1), Blank)
			b.SetCell(MakePos(9,1), Blank)
			b.SetCell(MakePos(2,2), Blank)
			b.SetCell(MakePos(8,2), Blank)
		default:
			fmt.Println( "unkown ochi: " + ochi )
		}
	}
	return b
}

func (k *Ki2Kifu) Commands() []Command {
	if k.ACommands == nil && k.AHumanCommands != nil {
		k.ACommands = ConvertCommands( k )
	}
	return k.ACommands
}

