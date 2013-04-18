package shogi

import (
	"testing"
	"strings"
	"sort"
)

func TestBoard(t *testing.T) {
	// b := NewBoard()
}

func TestCell(t *testing.T) {
	b := NewBoard()
	
	if b.Cell(MakePos(1,1)) != Blank { t.Error("init as blank") }

	b.SetCell(MakePos(1,1), MakeKoma(FU,Sente))
	if b.Cell(MakePos(1,1)) != MakeKoma(FU,Sente) { t.Error("set (1,1)") }

	b.SetCell(MakePos(9,9), MakeKoma(OU,Gote))
	if b.Cell(MakePos(9,9)) != MakeKoma(OU,Gote) { t.Error("set (9,9)") }
}

func TestProgress(t *testing.T) {
	b := NewBoard()
	
	b.Progress( MakeCommand(Sente, Komabako, MakePos(5,5), OU) )
	if b.Cell(MakePos(5,5)) != MakeKoma(OU,Sente) { t.Error("from komabako") }

	b.ProgressString( "-0195OU" )
	if b.Cell(MakePos(9,5)) != MakeKoma(OU,Gote) { t.Error("from komabako") }
}

func initBoard( coms string ) *Board {
	b := NewBoard()
	b.ProgressString( coms )
	return b
}

func comsString( coms []Command ) string {
	coms_str := make([]string, len(coms))
	for i, com := range coms { coms_str[i] = com.String() }
	sort.Strings(coms_str)
	return strings.Join(coms_str,",")
}

func possString( poss []Pos ) string {
	poss_str := make([]string, len(poss))
	for i, pos := range poss { poss_str[i] = pos.String() }
	sort.Strings(poss_str)
	return strings.Join(poss_str,",")
}

func TestMovableList(t *testing.T) {

	// 盤の端の処理、味方駒の妨害の処理
	b := initBoard( "+0159OU\n+0158FU\n+0138HI" )
	if possString(b.ListMovable( MakePos(5,9) )) != "48,49,68,69" { t.Error( "OU move to" ) }
	if possString(b.ListMovable( MakePos(5,8) )) != "57" { t.Error( "FU move to" ) }
	if possString(b.ListMovable( MakePos(3,8) )) != "18,28,31,32,33,34,35,36,37,39,48" { t.Error("HI move to") }

	// 敵の駒の妨害, 成り
	b = initBoard( "+0115KY\n-0112FU" )
	if comsString(b.ListMovableAll(Sente)) != "+1512KY,+1512NY,+1513KY,+1513NY,+1514KY" { t.Error("KY move and nari") }

	// 動けない場所への移動はできない
	b = initBoard( "+0112FU\n+0123KY\n+0144KE" )
	if comsString(b.ListMovableAll(Sente)) != "+1211TO,+2321NY,+2322KY,+2322NY,+4432NK,+4452NK" {
		t.Error( "move to invalid" )
	}

	// 打ちゴマ、二歩
	b = initBoard( "+0100FU\n+0191FU\n-0112FU" )
	if len(b.ListMovableAll(Sente)) != 63 {
		t.Error( "check utigoma, nifu" )
	}

	// 戻り成り
	b = initBoard( "+0113GI" )
	if comsString(b.ListMovableAll(Sente)) != "+1312GI,+1312NG,+1322GI,+1322NG,+1324GI,+1324NG" {
		t.Error( "move back nari" )
	}

	// 王をとれる場合は、必ず取る
	b = initBoard( "-0111OU\n+0112KI" )
	if comsString(b.ListMovableAll(Sente)) != "+1211KI" {
		t.Error( "must get OU" )
	}
	

}
