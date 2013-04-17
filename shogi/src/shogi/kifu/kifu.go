package kifu

import (
	"fmt"
	"errors"
	"math"
	"path"
	"strings"
	iconv "github.com/djimenez/iconv-go"
	. "shogi"
)

// "右","左"の指定
type Side int

const (
	SideNone = iota
	SideLeft
	SideRight
)

var SideFromString = map[string]Side {
	""   : SideNone,
	"左" : SideLeft,
	"右" : SideRight,
}

var SideString = []string{"","左","右"}

// "上","寄" などの指定
type Moving int

const (
	MovingNone Moving = iota
	MovingAgaru
	MovingHiku
	MovingYoru
	MovingSugu
	MovingIku
)

var MovingFromString = map[string]Moving {
	""   : MovingNone,
	"上" : MovingAgaru,
	"引" : MovingHiku,
	"寄" : MovingYoru,
	"直" : MovingSugu,
	"行" : MovingIku,
}
var MovingString = []string{"","上","引","寄","直","行"}

// 人が読み書きする形の棋譜の一手
type HumanKifu struct {
	Src string
	Player Player
	To Pos
	Koma KomaKind
	Side Side
	Moving Moving
	Naru bool
	Utsu bool
}

func (k HumanKifu) String() string {
	return k.Src
}

//
type Loader struct {
	Ext []string
	Load func( string ) (Kifu, error)
}

var loaders = []Loader{}

func AddLoader( ld Loader ) {
	loaders = append( loaders, ld )
}

func LoadAuto( file string, src string ) (Kifu, error) {
	ext := strings.ToLower( path.Ext(file) )
	for _, ld := range loaders {
		for _, ld_ext := range ld.Ext {
			if ext == ld_ext {
				return ld.Load( src )
			}
		}
	}
	return nil, errors.New( "unknown ext: " + file )
}

// 棋譜の情報
type Kifu interface {
	Format() string
	Board() *Board
	Commands() []Command
	HumanCommands() []HumanKifu
	Info() map[string]string
}

type KifuBase struct {
	AFormat string
	AInfo map[string]string
	ACommands []Command
	AHumanCommands []HumanKifu
}

func (k *KifuBase) Format() string {
	return k.AFormat
}

func (k *KifuBase) Commands() []Command {
	return k.ACommands
}

func (k *KifuBase) HumanCommands() []HumanKifu {
	return k.AHumanCommands
}

func (k *KifuBase) Info() map[string]string {
	return k.AInfo
}

func (k *KifuBase) Board() *Board {
	return InitBoard()
}

func ConvertCommands(k Kifu) []Command {
	r := []Command{}
	b := k.Board()
	for i, hc := range k.HumanCommands() {
		com, err := hc.Convert(b)
		if err != nil { fmt.Printf("error in convert %d: %s\n%s", i+1, err, b); break }
		b.Progress( com )
		r = append( r, com )
	}
	return r
}


type intCommandPair struct{ n int; com Command }

func ProgressHumanKifu( b *Board, kifu []HumanKifu ) error {
	for _, k := range kifu {
		com, err := k.Convert(b)
		if err != nil { return err }
		b.Progress( com )
	}
	return nil
}

func (k *HumanKifu) Convert(b *Board) (Command, error) {
	//fmt.Println( k )
	if k.Naru { k.Koma = KomaNari[k.Koma] }
	
	coms := b.ListMovableAllWith( k.Player, true )

	var matchs []intCommandPair
	for _, com := range coms {
		if com.To == k.To && com.Koma == k.Koma {
			matchs = append( matchs, intCommandPair{0,com} )
		}
	}
	
	var match Command
	if len(matchs) > 1 {
		for i, _ := range matchs {
			ic := &matchs[i]
			com := ic.com
			//if k.Side != SideNone || k.Command != KIFU_NONE { fmt.Println( com ) }
			
			// "打"指定の場合のフィルタリング
			if k.Utsu {
				if ic.com.From != Komadai { ic.n = -1000; continue }
			}else{
				if ic.com.From == Komadai { ic.n = -1000; continue }
				
				// "成"指定の場合のフィルタリング
				if k.Naru {
					if ic.com.Koma == b.Cell(ic.com.From).Kind() { ic.n = -1000; continue }
				}else{
					if ic.com.Koma != b.Cell(ic.com.From).Kind() { ic.n = -1000; continue }
				}
				
				// "右","左"の場合のフィルタリング
				switch k.Side {
				case SideLeft : ic.n += -com.From.X() * com.Player.Dir() * 10
				case SideRight: ic.n +=  com.From.X() * com.Player.Dir() * 10
				}

				// "上","引","寄","直"のフィルタリング
				switch k.Moving {
				case MovingAgaru : ic.n += -com.From.Y() * com.Player.Dir()
				case MovingHiku  : ic.n +=  com.From.Y() * com.Player.Dir()
				case MovingYoru  : ic.n += -int( math.Abs( float64(com.From.Y() - com.To.Y()) ) )
				case MovingSugu  :
					ic.n += -int( math.Abs( float64(com.From.X() - com.To.X()) ) ) * 100 +
						-com.From.Y() * com.Player.Dir()
				case MovingIku   : ic.n += -com.From.Y() * com.Player.Dir()
				}
			}
		}
		max := -100
		for _, ic := range matchs {
			if ic.n > max {
				max = ic.n
				match = ic.com
			}
		}
		/*
		if k.Side != SideNone || k.Command != KIFU_NONE {
		fmt.Print( k, match, "[" )
		for _, x := range matchs { fmt.Printf( "%s ", x.com ) }
		fmt.Println("]")
		}
		*/
	}else{
		if len(matchs) == 0 { return match, NewError( fmt.Sprintf("Ilegal kifu %s", k.String() ) ) }
		if len(matchs) != 1 { return match, errors.New("invalid "+k.String()) }
		match = matchs[0].com
	}

	// fmt.Println( k, match, b )
	
	return match, nil
}

// エラー
type Error struct {
	msg string
}

func NewError( msg string ) *Error {
	r := new(Error)
	r.msg = msg
	return r
}
	
func (err *Error) Error() string {
	return err.msg
}

func ConvertEncodingAuto( src []byte ) ( []byte, error ){
	out := make([]byte, 64*1024)
	for _, encoding := range []string{"CP932","utf-8"} {
		_, bytes, err := iconv.Convert( src, out, encoding, "utf-8")
		if err == nil { return out[0:bytes], nil }
	}
	return nil, errors.New("cannot convert string")
}


