package shogi

import (
	"strconv"
)

// 盤の状況
type Board struct {
	cell [BoardSize*BoardSize]Koma
	moti [MaxPlayer][MaxKomaKind]uint8
	Teban Player
}

func NewBoard() *Board {
	return new(Board)
}

func (b *Board) Cell( pos Pos ) Koma {
	return b.cell[pos.Int()]
}

func (b *Board) SetCell( pos Pos, koma Koma ){
	b.cell[pos.Int()] = koma
}

func (b *Board) String() string {
	r := "  ９   ８   ７   ６   ５   ４   ３   ２   １  \n"
	for y:=1; y<=BoardSize; y++ {
		r += "+----+----+----+----+----+----+----+----+----+\n"
		r1 := ""
		r2 := ""
		for x:=BoardSize; x>=1; x-- {
			koma := b.Cell( MakePos(x,y) )
			if koma != Blank {
				kstr := koma.Kind().ReadableString()
				if len(kstr)<6 { kstr = " "+kstr+" " }
				if koma.Player() == Sente {
					r1 += "| /\\ "
					r2 += "|"+kstr
				}else{
					r1 += "|"+kstr
					r2 += "| \\/ "
				}
			}else{
				r1 += "|    "
				r2 += "|    "
			}
		}
		r1 += "|"+PosYReadableString[y]+"\n"
		r2 += "|\n"
		r += r1 + r2
	}
		r += "+----+----+----+----+----+----+----+----+----+\n"
	for pl, moti := range b.moti {
		r += PlayerReadableString[pl] + ": "
		for kind, num := range moti {
			if num > 0 {
				r += KomaKind(kind).String() + "x" + strconv.Itoa(int(num)) + ","
			}
		}
		r += "\n"
	}
	return r
}

func (b *Board) moveStraight(list *[]Pos, pos Pos, player Player, dy int, dx int ) {
	for {
		pos = MakePos( pos.X() + dx, pos.Y() + dy )
		if !pos.InSide() { break }
		koma := b.Cell( pos )
		if koma != Blank && koma.Player() == player { break }
		*list = append( *list, pos )
		if koma != Blank && koma.Player() != player { break }
	}
}

func (b *Board) ListMovable(pos Pos) []Pos {
	r := make([]Pos, 0, 20)
	koma := b.Cell( pos )
	if koma.Kind() == NN { return r }

	// 通常の移動
	dir := koma.Player().Dir()
	for _, to := range KomaMoveList[koma.Kind()] {
		to_pos := MakePos( pos.X() + to[0], pos.Y() + dir * to[1] )
		if !to_pos.InSide() { continue }
		to_koma := b.Cell( to_pos )
		if to_koma != Blank && to_koma.Player() == koma.Player() { continue }
		r = append( r, to_pos )
	}

	// 複数マス直進する移動
	switch koma.Kind() {
	case KY:
		b.moveStraight( &r, pos, koma.Player(), koma.Player().Dir(),  0 )
	case HI, RY:
		b.moveStraight( &r, pos, koma.Player(),  1,  0 )
		b.moveStraight( &r, pos, koma.Player(), -1,  0 )
		b.moveStraight( &r, pos, koma.Player(),  0,  1 )
		b.moveStraight( &r, pos, koma.Player(),  0, -1 )
	case KA, UM:
		b.moveStraight( &r, pos, koma.Player(),  1,  1 )
		b.moveStraight( &r, pos, koma.Player(), -1,  1 )
		b.moveStraight( &r, pos, koma.Player(),  1, -1 )
		b.moveStraight( &r, pos, koma.Player(), -1, -1 )
	}
	
	return r
}

// 先手なら１行めから、後手なら９行目から数えた行数を返す。１はじまり
func fromTop( pl Player, y int ) int {
	if pl == Sente { return y }
	return 10 - y
}

// 不正(動けない駒)かどうかを確認する
func movable( koma Koma, pos Pos ) bool {
	switch koma.Kind() {
	case FU,KY:
		return fromTop(koma.Player(), pos.Y()) >= 2
	case KE:
		return fromTop(koma.Player(), pos.Y()) >= 3
	}
	return true
}

// プレイヤーの選択肢のコマンドをすべて取得する。
// 二歩、動けない場所への移動、のチェックはここで行う。
func (b *Board) ListMovableAll( pl Player) []Command {
	r := make( []Command, 0, 256 )
	
	// 通常の移動
	for y:=1; y<=BoardSize; y++ {
		for x:=1; x<=BoardSize; x++ {
			pos := MakePos(x,y)
			koma := b.Cell( pos )
			if koma != Blank && koma.Player() == pl {
				for _,to_pos := range b.ListMovable( pos ) {
					com := MakeCommand(pl, pos, to_pos, koma.Kind() )
					// 動けない場所でないならでないなら追加
					if movable( koma, to_pos ) {
						r = append( r, com )
					}
					// 成れる場合は、その選択肢も追加
					if KomaNari[ koma.Kind() ] != NN {
						if fromTop(pl,to_pos.Y()) <= 3 {
							com := MakeCommand(pl, pos, to_pos, KomaNari[koma.Kind()] )
							r = append( r, com )
						}
					}
				}
			}
		}
	}
	
	// 打ち駒
	for x:=1; x<=BoardSize; x++ {
		
		// 二歩チェックリスト作成
		nifu := false
		for y:=1; y<=BoardSize; y++ {
			koma := b.Cell(MakePos(x,y))
			if koma.Kind() == FU && koma.Player() == pl {
				nifu = true
				break;
			}
		}

		for y:=1; y<=BoardSize; y++ {
			// 打てる場所を探す
			to_pos := MakePos(x,y)
			if b.Cell(to_pos).Kind() != NN { continue }
			for kk:= FU; kk<OU; kk++ {
				if b.moti[pl][kk] <= 0 { continue }
				if kk == FU && nifu { continue } // 二歩チェック
				// 動けない場所でないならでないなら追加
				if movable( MakeKoma(kk,pl), to_pos ) {
					r = append( r,MakeCommand(pl,Komadai,to_pos,kk) )
				}
			}
		}
	}
	return r
}

func (b *Board) Progress( com Command ) {
	switch com.From {
	case Komabako:
		// 駒箱から取る
	case Komadai:
		// 打ち駒
		b.moti[com.Player][com.Koma] -= 1
	default:
		// それ以外
		koma := b.Cell( com.To )
		if koma != Blank {
			if KomaFunari[koma.Kind()] != NN {
				b.moti[com.Player][KomaFunari[koma.Kind()]] += 1
			}else{
				b.moti[com.Player][koma.Kind()] += 1
			}
		}
		b.SetCell( com.From, Blank )
	}

	switch com.To {
	case Komabako:
		// 駒箱に入れる
	case Komadai:
		// 駒台に置く
		b.moti[com.Player][com.Koma] += 1
	default:
		// 通常
		b.SetCell( com.To, MakeKoma( com.Koma, com.Player) )
	}
	b.Teban = com.Player.Switch()
}

func (b *Board) ProgressCommands( coms []Command ) {
	for _, com := range coms {
		b.Progress( com )
	}
}

func (b *Board) ProgressString( str string ) error {
	coms, err := ParseCommands( str )
	if err != nil { return err }
	b.ProgressCommands( coms )
	return nil
}
