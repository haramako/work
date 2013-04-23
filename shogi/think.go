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
	//"runtime"
	"sync"
	//"os/exec"
	"strings"
	"shogi"
	"shogi/kifu"
	_ "shogi/kifu/csa"
	_ "shogi/kifu/ki2"
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
	
	b := new(Node)
	b.Board = *kif.Board()
	b.ProgressCommands( kif.Commands() )

	fmt.Println( b )

	//watcher := NewWatcher()
	history, point := Solv( b, level, b.Teban.Dir()*-1, *parallel )
	fmt.Println( history )
	fmt.Printf( "COM: %s POINT: %d\n", history[0], point)

	b.Progress( history[0] )
	
	// fmt.Println( b )
	
	return nil
}

func pipe() error {
	// runtime.GOMAXPROCS( *parallel )
	in := bufio.NewReader( os.Stdin )
	for {
		line, _, err := in.ReadLine()
		if err == io.EOF { return nil }
		if err != nil { return err }
		if len(line) == 0 { return nil }

		var hex string
		var level, sign int
		var rest_level, limit int 
		n, err := fmt.Sscan( string(line), &hex, &level, &rest_level, &limit, &sign )
		if n != 5 { return nil }
		if err != nil { return err }

		node := new(Node)
		node.point = math.MinInt32
		node.DeserializeHex( hex )


		//watcher := NewWatcher()
		//result, point := ab_method.SolvNode( param, node )
		result, point := Solv( node, rest_level, sign, *parallel )

		result_str := []string{}
		for _,x:= range result { result_str = append( result_str, fmt.Sprintf("%s",x) ) }
		fmt.Printf( "%s %d\n", strings.Join(result_str,","), point )
	}
	return nil
}

//-----------------------------------------------------------

/*
type MyWatcher struct {
	count int
	comsSum int
	max float64
	min float64
}

func NewWatcher() *MyWatcher {
	return &MyWatcher{0,0,-9999,9999}
}

func (w *MyWatcher) OnCheck(node Node) {
	b := node
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
*/

//-----------------------------------------------------------

type Node struct {
	shogi.Board
	point int
}

var POINT = []int {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0, 10,  20,  20,  40,  50,  80, 100,99999,  60,  50,  50,  50, 100, 120,
}

func NewNode() (*Node) {
	n := new(Node)
	n.point = math.MinInt32
	return n
}

func (n *Node) Clone() *Node {
	r := NewNode()
	*r = *n
	r.point = math.MinInt32
	return r
}

func (n *Node) Point() int {
	if n.point != math.MinInt32 { return n.point }
	p := 0
	for y:=1; y<=9; y++ {
		for x:=1; x<=9; x++ {
			koma := n.Cell( shogi.MakePos(x,y) )
			if koma == shogi.Blank { continue }
			p += POINT[koma.Kind()] * -koma.Player().Dir()
		}
	}
	for pl:=shogi.Sente; pl<=shogi.Gote; pl++ {
		for koma, num := range n.Moti()[pl] {
			p += POINT[koma] * -pl.Dir() * int(num)
		}
	}
	n.point = p // + rand.Float64() - 0.5
	return p
}

func (n *Node) Stop() bool {
	if math.Abs(float64(n.Point())) > 100000 { return true }
	return false
}

func (n *Node) Choose( choice shogi.Command ) (*Node, int) {
	r := n.Clone()
	r.Progress( choice )
	level := 8
	// if r.board.Cell( choice.To ) != Blank { level = 0.5 }
	return r, level
}


/*
func (n *Node) SolvParallel(inch chan SolvInChan, outch chan SolvOutChan ) {
	for {
		in := <- inch
		if in.Finish { break }
		result, point := SolvNode( in.Param, in.Node )
		outch <- SolvOutChan{append([]shogi.Command{in.Choice},result...),point,nil}
	}
}
*/

/*
func (n *Node) SolvParallel(inch chan ab_method.SolvInChan, outch chan ab_method.SolvOutChan ) {
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

			n := in.Node.(*Node)
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
*/

//-----------------------------------------------------------

type Param struct {
	Parallel int
	Cache map[uint64]*CacheItem
}

type SolvInChan struct {
	Finish bool
	Param Param
	Node *Node
	Choice shogi.Command
}

type SolvOutChan struct {
	Result []shogi.Command
	Point int
	Err error
}

type CacheItem struct {
	RestLevel int
	Point int
	Choices []shogi.Command
}

// solvNodeの並列化バージョン
/*
func solvNodeParallel( param Param, node *Node, choices []shogi.Command ) ( []shogi.Command, float64 ) {
	var r_choices []shogi.Command
	child_param := param
	child_param.Level += 1
	child_param.Sign = -param.Sign
	child_param.Limit = math.MaxInt32
	child_param.Parallel = 1
	r_point := -math.MaxFloat64

	inch := make(chan SolvInChan)
	outch := make(chan SolvOutChan)

	if param.Parallel > len(choices) { param.Parallel = len(choices) }

	for i:=0; i<param.Parallel; i++ {
		go node.SolvParallel(inch, outch)
	}

	num_sent := 0
	num_buf := 0
	for i:=0; i<len(choices); i++ {
		for ; num_sent < len(choices) && num_buf < param.Parallel; {
			child, use_level := node.Choose( choices[num_sent] )
			child_param.RestLevel = param.RestLevel - use_level
			inch <- SolvInChan{false,child_param, child, choices[num_sent] }
			num_sent++
			num_buf++
		}
		res := <- outch
		num_buf--
		result := res.Result
		point := res.Point
		point = -point
		if r_point < point {
			r_choices = result
			r_point = point
			child_param.Limit = -point
			// アルファ/ベータカット
			if point >= param.Limit { 
				// fmt.Printf("%salpha/beta cut %v point:%d limit:%d\n",
				// strings.Repeat("  ", child_param.Level), child, point, param.Limit);
				break
			}
		}
	}

	for i:=0; i<param.Parallel; i++ {
		inch <- SolvInChan{true,child_param, nil, shogi.Command{}}
	}
	
	return r_choices, r_point
}
*/

var mutex sync.Mutex

func SolvNode( param *Param, node *Node, sign int, level int, rest_level int, limit int ) ( []shogi.Command, int ) {
	var r_choices []shogi.Command
	var r_point int

	node.Hash()
	//mutex.Lock()
	//if param.Watcher != nil { param.Watcher.OnCheck( node ) }
	item, exists := param.Cache[node.Hash()]
	//mutex.Unlock()
	if exists && item.RestLevel >= rest_level {
		// キャッシュが利用できる
		r_choices = item.Choices
		r_point = item.Point
	}else{
		// キャッシュが利用できない
		choices := node.ListMovableAll(node.Teban)
		
		if rest_level > 0 && !node.Stop() && len(choices) > 0 {
			// 前回のベスト選択肢を先頭にする
			best_exists := false
			if exists && len(item.Choices)>0 {
				best_exists = true
				best_choice := item.Choices[0]
				for i, com := range choices {
					if best_choice == com {
						choices[0], choices[i] = best_choice, choices[0]
						break
					}
				}
			}
			//if param.Parallel > 1 {
			//	r_choices, r_point = solvNodeParallel( param, node, choices )
			//}else{
			r_point = -math.MaxInt32
			for _, choice := range choices {
				child, use_level := node.Choose( choice )
				if best_exists { use_level -= 4; best_exists = false }
				result, point := SolvNode( param, child, -sign, level+1, rest_level-use_level, -r_point )
				point = -point
				if r_point < point {
					r_choices = append( []shogi.Command{choice}, result... )
					r_point = point
					// アルファ/ベータカット
					if point >= limit { break }
				}
			}
			//}
		}else{
			r_choices = []shogi.Command{}
			r_point = node.Point() * sign
		}
	}
	
	if len(param.Cache) < 10000000 {
		//mutex.Lock()
		param.Cache[node.Hash()] = &CacheItem{rest_level, r_point, r_choices}
		//mutex.Unlock()
	}

	return r_choices, r_point
}

func Solv( node *Node, level int, sign int, parallel int) ([]shogi.Command, int) {
	var a []shogi.Command
	var b int
	param := Param{parallel,nil}
	param.Cache = make( map[uint64]*CacheItem, 10000000 )
	for lv:=1; lv<=level; lv++ {
		a, b = SolvNode( &param, node, sign, 0, lv*8, 99999999 )
		println( "cachesize:", len(param.Cache) )
	}
	return a,b
}
