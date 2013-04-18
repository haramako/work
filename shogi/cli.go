package main

import (
	"fmt"
	"time"
	"math/rand"
	"math"
	"os"
	"flag"
	"log"
	"runtime/pprof"
	. "shogi"
	"shogi/net/csa"
	"ab_method"
)



func mainloop() error {
	name := fmt.Sprintf( "hoge%d", rand.Intn(1000) )
	cli, err := csa.NewClient(name,name,"192.168.11.4:4081")
	if err != nil { return err }
	cli.SetCallback( new(MyClient) )
	return cli.Run()
}

var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")

func main(){
	
    flag.Parse()
    if *cpuprofile != "" {
        f, err := os.Create(*cpuprofile)
        if err != nil {
            log.Fatal(err)
        }
        pprof.StartCPUProfile(f)
        defer pprof.StopCPUProfile()
    }

	rand.Seed(time.Now().UTC().UnixNano())

	/*
	b := new(AbBoard)
	b.board = NewBoard()
	// b.board.ProgressString("+0199OU\n-0198KI\n-0197KI\n-0111OU")
	//b.board.ProgressString("+0199OU\n-0197KI\n-0187KI\n-0111OU")
	b.board.Init()
	b.board.Teban = Gote
	watcher := &MyWatcher{0,0,-9999,9999}
	history, point := ab_method.Solv( b, 4, b.board.Teban == Sente, watcher )
	fmt.Println( history, point )
	fmt.Printf( "COM: %s POINT: %4.1f (%3.0f..%3.0f) COUNT: %4d / %3.1f\n",
		history[0], point, watcher.max, watcher.min, watcher.count, 
		float64(watcher.comsSum)/float64(watcher.count) )

	return
	*/

	for {
		err := mainloop()
		if err != nil {
			fmt.Printf( "error: %s\n", err )
		}
		//break
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
	node := &(AbBoard{nil,math.MinInt32})
	node.board = b.Clone()
	watcher := &MyWatcher{0,0,-9999,9999}
	history, point := ab_method.Solv( node, 3, b.Teban == Sente, watcher )
	com := history[0]
	fmt.Printf( "COM: %s POINT: %4.1f (%3.0f..%3.0f) COUNT: %4d/%4d, TEBAN:%d\n",
		com, point, watcher.max, watcher.min, watcher.count, 
		watcher.comsSum/watcher.count, b.Teban )
	fmt.Println( history )
	
	if point < -10000 {
		return "%TORYO", nil
	}
	return com, nil
}

//-----------------------------------------------------------

type AbBoard struct {
	board *Board
	point float64
}

func (b *AbBoard) Clone() *AbBoard {
	return &AbBoard{b.board,math.MinInt32}
}

var POINT = []float64 {
	//NN; FU; KY; KE; GI; KI; KA; HI;  OU; TO; NY; NK; NG; UM; RY
        0, 1,  2,  2,  4,  5,  8, 10,9999,  6,  5,  5,  5, 12, 14,
}

func (n *AbBoard) Point() float64 {
	if n.point != math.MinInt32 { return n.point }
	b := n.board
	p := 0.0
	for y:=1; y<=9; y++ {
		for x:=1; x<=9; x++ {
			koma := b.Cell( MakePos(x,y) )
			if koma == Blank { continue }
			p += POINT[koma.Kind()] * float64(-koma.Player().Dir())
		}
	}
	for pl:=Sente; pl<=Gote; pl++ {
		for koma, num := range b.Moti()[pl] {
			p += POINT[koma] * float64(-pl.Dir() * int(num))
		}
	}
	n.point = p + rand.Float64() - 0.5
	return p
}

func (b *AbBoard) Stop() bool {
	if math.Abs(float64(b.Point())) > 10000 { return true }
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

func (n *AbBoard) Choose( choice string ) (ab_method.Node, float64) {
	r := new(AbBoard)
	r.board = n.board.Clone()
	r.point = math.MinInt32
	com, _ := ParseCommand( choice )
	level := 1.0
	if r.board.Cell( com.To ) != Blank { level = 0.25 }
	r.board.Progress( com )
	return r, level
	return n, 1.0
}

func (n *AbBoard) String() string {
	return "Board"
}
