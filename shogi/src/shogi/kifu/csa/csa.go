package csa

import (
	"fmt"
	"strings"
	. "shogi"
	"shogi/kifu"
)

var registered = kifu.AddLoader( kifu.Loader{ []string{".csa"}, Parse } )

func atoi( c uint8 ) int {
	return int(c) - '0'
}

func Parse( str string ) ( kifu.Kifu, error ) {
	coms := []Command{}
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
				b.Init()
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
				com, err := ParseCommand( line )
				if err != nil { fmt.Println( "error: "+line ) }
				coms = append( coms, com )
			}
		default:
			println( line )
		}
	}
	_ = version

	r := new(kifu.KifuBase)
	r.ACommands = coms
	r.ABoard = b
	return r, nil
}
