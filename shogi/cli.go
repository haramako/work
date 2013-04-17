package main

import (
	"fmt"
	"time"
	"math/rand"
	"math"
	. "shogi"
	"shogi/net/csa"
	"ab_method"
)



func mainloop() error {
	name := fmt.Sprintf( "hoge%d", rand.Intn(1000) )
	cli, err := csa.NewClient(name,name,"localhost:4081")
	if err != nil { return err }
	cli.SetCallback( new(MyClient) )
	return cli.Run()
}

func main(){
	rand.Seed(time.Now().UTC().UnixNano())

	for {
		err := mainloop()
		if err != nil {
			fmt.Printf( "error: %s\n", err )
		}
		break
	}

}

type MyWatcher struct {
	count int
	comsSum int
	max float64
	min float64
}

func (w *MyWatcher) OnCheck(node ab_method.Node) {
	b := node.(*AbBoard)
	w.count += 1
	w.comsSum += len(b.board.ListMovableAll(b.board.Teban))
	p := float64(b.Point())
	w.max = math.Max( w.max, p )
	w.min = math.Min( w.min, p )
}

type MyClient struct{}

func (c *MyClient) Play( b *Board ) (string, error) {
	node := new(AbBoard)
	node.board = b.Clone()
	watcher := new(MyWatcher)
	watcher.max = -9999
	watcher.min = 9999
	history, point := ab_method.Solv( node, 2, b.Teban == Sente, watcher )
	com := history[0]
	fmt.Printf( "COM: %s POINT: %3d (%3.0f..%3.0f) COUNT: %4d/%4d, TEBAN:%d\n",
		com, point, watcher.max, watcher.min, watcher.count, 
		watcher.comsSum/watcher.count, b.Teban )
	return com, nil
}

//-----------------------------------------------------------

type AbBoard struct {
	board *Board
}

func (b *AbBoard) Clone() *AbBoard {
	return &AbBoard{b.board}
}

var POINT = []int {
	//NN; FU; KY; KE; GI; KI; KA; HI;  OU; TO; NY; NK; NG; UM; RY
        0, 1,  2,  2,  4,  5,  8, 10,9999,  6,  5,  5,  5, 14, 16,
}

func (n *AbBoard) Point() int {
	b := n.board
	p := 0
	for y:=1; y<=9; y++ {
		for x:=1; x<=9; x++ {
			koma := b.Cell( MakePos(x,y) )
			if koma == Blank { continue }
			p += POINT[koma.Kind()] * -koma.Player().Dir()
		}
	}
	return p
}

func (b *AbBoard) Stop() bool {
	return false
}

func (b *AbBoard) Choices() []string {
	coms := b.board.ListMovableAll(b.board.Teban)
	r := make([]string,len(coms))
	for i, com := range coms {
		r[i] = com.String()
	}
	return r
}

func (n *AbBoard) Choose( choice string ) ab_method.Node {
	r := new(AbBoard)
	r.board = n.board.Clone()
	com, _ := ParseCommand( choice )
	r.board.Progress( com )
	return r
}

func (n *AbBoard) String() string {
	return "Board"
}
