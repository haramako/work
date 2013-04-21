package main

import (
	"fmt"
	"time"
	"math/rand"
	"math"
	"os"
	"flag"
	"log"
	"io"
	"bufio"
	"strconv"
	"runtime/pprof"
	"os/exec"
	"strings"
	. "shogi"
	"shogi/kifu"
	_ "shogi/kifu/csa"
	_ "shogi/kifu/ki2"
	"ab_method"
)

func showHelp(){
	println(
		"Shogi Thinking Program:\n"+
		"example:\n"+
		"  ./think board [options ...] kifufile level  # think a board\n"+
		"  ./think pipe [options ...]                  # think client mode\n"+
		"options:" )
	flag.PrintDefaults()
	os.Exit(0)
}

var (
	parallel = flag.Int("p", 1, "parallel")
	cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")
	help = flag.Bool("h", false, "show help message")
)

func main(){

    flag.Parse()
	
	if len(os.Args) <= 1 { showHelp() }
	mode := flag.Arg(0)
	
    if *cpuprofile != "" {
        f, err := os.Create(*cpuprofile)
        if err != nil {
            log.Fatal(err)
        }
        pprof.StartCPUProfile(f)
        defer pprof.StopCPUProfile()
    }

	_ = parallel
	if *help { showHelp() }

	var err error
	switch mode {
	case "board","b":
		err = boardMode( flag.Arg(1), flag.Arg(2) )
	case "pipe","p":
		err = pipe()
		if err != nil {
			fmt.Fprintf( os.Stderr, "error: %s\n", err )
		}
	default:
		showHelp()
	}
	if err != nil {
		fmt.Printf( "error: %s\n", err )
		os.Exit(1)
	}
}

func boardMode( filename string, level_str string ) error {
	level, err := strconv.Atoi( level_str )
	if err != nil { return err }
	
	rand.Seed(time.Now().UTC().UnixNano())

	kif, err := kifu.LoadAuto( filename )
	if err != nil { return err }
	
	b := new(AbBoard)
	b.board = kif.Board()
	b.board.ProgressCommands( kif.Commands() )

	fmt.Println( b.board )

	watcher := NewWatcher()
	history, point := ab_method.Solv( b, float64(level), b.board.Teban == Sente, *parallel, watcher )
	fmt.Println( history )
	fmt.Printf( "COM: %s POINT: %4.1f %s\n", history[0], point, watcher )

	b.board.Progress( history[0].(Command) )
	
	fmt.Println( b.board )
	
	return nil
}

func pipe() error {
	in := bufio.NewReader( os.Stdin )
	for {
		line, _, err := in.ReadLine()
		if err == io.EOF { return nil }
		if err != nil { return err }
		if len(line) == 0 { return nil }

		var hex string
		var level, sign int
		var rest_level, limit float64
		n, err := fmt.Sscan( string(line), &hex, &level, &rest_level, &limit, &sign )
		if n != 5 { return nil }
		if err != nil { return err }

		node := new(AbBoard)
		node.point = math.MinInt32
		node.board = NewBoard()
		node.board.DeserializeHex( hex )


		watcher := NewWatcher()
		param := ab_method.Param{limit,level,rest_level,float64(sign),watcher,*parallel}
		result, point := ab_method.SolvNode( param, node )

		result_str := []string{}
		for _,x:= range result { result_str = append( result_str, fmt.Sprintf("%s",x) ) }
		fmt.Printf( "%s %f\n", strings.Join(result_str,","), point )
	}
	return nil
}

//-----------------------------------------------------------

type MyWatcher struct {
	count int
	comsSum int
	max float64
	min float64
}

func NewWatcher() *MyWatcher {
	return &MyWatcher{0,0,-9999,9999}
}

func (w *MyWatcher) OnCheck(node ab_method.Node) {
	b := node.(*AbBoard)
	w.count += 1
	w.comsSum += len(b.board.ListMovableAll(b.board.Teban))
	p := float64(b.Point())
	w.max = math.Max( w.max, p )
	w.min = math.Min( w.min, p )
}

func (w *MyWatcher) String() string {
	return fmt.Sprintf( "RANGE: %6.1f..%6.1f COUNT: %4d / %3.1f\n",
		w.max, w.min, w.count, 
		float64(w.comsSum)/float64(w.count) )
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
	n.point = p // + rand.Float64() - 0.5
	return p
}

func (b *AbBoard) Stop() bool {
	if math.Abs(float64(b.Point())) > 10000 { return true }
	return false
}

func (b *AbBoard) Choices() []interface{} {
	coms := b.board.ListMovableAll(b.board.Teban)
	r := make([]interface{},len(coms))
	for i, com := range coms {
		r[i] = com
	}
	return r
}

func (n *AbBoard) Choose( choice interface{} ) (ab_method.Node, float64) {
	r := new(AbBoard)
	r.board = n.board.Clone()
	r.point = math.MinInt32
	com := choice.(Command)
	level := 1.0
	if r.board.Cell( com.To ) != Blank { level = 0.5 }
	r.board.Progress( com )
	return r, level
}

func (n *AbBoard) String() string {
	return "Board"
}

func (n *AbBoard) SolvParallel(inch chan ab_method.SolvInChan, outch chan ab_method.SolvOutChan ) {
	err := func( inch chan ab_method.SolvInChan, outch chan ab_method.SolvOutChan ) error {
		// fmt.Println( "thinkiing" )
		pipe := exec.Command( "./think", "pipe" )
		pipeerr, err := pipe.StderrPipe()
		if err != nil { return err }
		go io.Copy( os.Stderr, pipeerr )
		if err != nil { return err }
		pipein, err := pipe.StdinPipe()
		if err != nil { return err }
		pipeout_raw, err := pipe.StdoutPipe()
		if err != nil { return err }
		pipeout := bufio.NewReader( pipeout_raw )
		err = pipe.Start()
		if err != nil { return err }

		for {
			in := <- inch
			if in.Finish { break }
			// fmt.Printf( "thinkiing %s\n", in.Choice )
			// fmt.Println( "solv", p.choice )

			n := in.Node.(*AbBoard)
			str := fmt.Sprintf( "%s %d %f %f %d\n",
				n.board.SerializeHex(),
				in.Param.Level, in.Param.RestLevel, in.Param.Limit, int(in.Param.Sign) )
			// fmt.Println( "SEND:", str )
			_, err := pipein.Write( []byte(str) )
			if err != nil { return err }
			
			line, _, err := pipeout.ReadLine()
			if err != nil { return err }
			// fmt.Println( "THINK:", string(line) )

			s := strings.Split(string(line)," ")
			result_str := strings.Split(s[0],",")
			result := []interface{}{}
			for _,x:= range result_str {
				com, err := ParseCommand(x)
				if err != nil { return err }
				result = append( result, com )
			}

			point, err := strconv.ParseFloat( s[1], 64 )
			if err != nil { return err }
			
			outch <- ab_method.SolvOutChan{append([]interface{}{in.Choice},result...),point,nil}
		}
		return nil
	}( inch, outch )
	if err != nil { fmt.Printf( "error: %s\n", err ) }
}

