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
	"runtime"
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
		err = pipeMode()
	case "point":
		err = pointMode( flag.Arg(1) )
	default:
		showHelp()
	}
	if err != nil {
		fmt.Printf( "error: %s\n", err )
		os.Exit(1)
	}
}

func pointMode( filename string ) error {
	flag_set := flag.NewFlagSet("", flag.ExitOnError )
	_ = flag_set

	kif, err := kifu.LoadAuto( filename )
	if err != nil { return err }
	
	n := NewNode()
	n.Board = *kif.Board()
	for i, com := range kif.Commands() {
		n.Progress( com )

		kiki := calcKiki( n )
		fmt.Printf( "%2d手目 koma:%5d kiki:%5d\n", i+1, calcKomaPoint(n), CalcKikiPoint(n,kiki))
		fmt.Println( n )
	}

	return nil
}

func calcKomaPoint( b *Node ) int {
	p := 0
	for y:=1; y<=shogi.BoardSize; y++ {
		for x:=1; x<=shogi.BoardSize; x++ {
			koma := b.Cell( shogi.MakePos(x,y) )
			if koma == shogi.Blank { continue }
			p += POINT[koma.Kind()] * -koma.Player().Dir()
		}
	}
	for pl:=shogi.Sente; pl<=shogi.Gote; pl++ {
		for koma, num := range b.Moti()[pl] {
			p += POINT[koma] * -pl.Dir() * int(num)
		}
	}

	return p
}

func calcKiki( b *Node ) [][]int {
	kiki := [][]int{ make([]int,81), make([]int,81) }
	var moveToBuf [32]shogi.Pos
	for y:=1; y<=shogi.BoardSize; y++ {
		for x:=1; x<=shogi.BoardSize; x++ {
			pos := shogi.MakePos(x,y)
			koma := b.Cell( pos )
			if koma == shogi.Blank { continue }
			for _, to := range ListKikiInto( b, pos, moveToBuf[0:0] ) {
				kiki[koma.Player()][to.Int()] += 1
			}
		}
	}

	/*
	for pl:=0; pl<2; pl++ {
		for y:=1; y<=shogi.BoardSize; y++ {
			for x:=shogi.BoardSize; x>=1; x-- {
				fmt.Print( kiki[pl][shogi.MakePos(x,y).Int()], "," )
			}
			fmt.Println( "" )
		}
		fmt.Println( "" )
	}
	*/
	return kiki
}

func kikiStraight(b *Node, list *[]shogi.Pos, pos shogi.Pos, player shogi.Player, dy int, dx int ) {
	for {
		pos = shogi.MakePos( pos.X() + dx, pos.Y() + dy )
		if !pos.InSide() { break }
		koma := b.Cell( pos )
		*list = append( *list, pos )
		if koma != shogi.Blank { break }
	}
}

func ListKikiInto(b *Node, pos shogi.Pos, r []shogi.Pos ) []shogi.Pos {
	koma := b.Cell( pos )
	if koma.Kind() == shogi.NN { return r }

	// 通常の移動
	dir := koma.Player().Dir()
	for _, to := range shogi.KomaMoveList[koma.Kind()] {
		to_pos := shogi.MakePos( pos.X() + to[0], pos.Y() + dir * to[1] )
		if !to_pos.InSide() { continue }
		to_koma := b.Cell( to_pos )
		if to_koma != shogi.Blank && to_koma.Player() == koma.Player() { continue }
		r = append( r, to_pos )
	}

	// 複数マス直進する移動
	switch koma.Kind() {
	case shogi.KY:
		kikiStraight( b, &r, pos, koma.Player(), koma.Player().Dir(),  0 )
	case shogi.HI, shogi.RY:
		kikiStraight( b, &r, pos, koma.Player(),  1,  0 )
		kikiStraight( b, &r, pos, koma.Player(), -1,  0 )
		kikiStraight( b, &r, pos, koma.Player(),  0,  1 )
		kikiStraight( b, &r, pos, koma.Player(),  0, -1 )
	case shogi.KA, shogi.UM:
		kikiStraight( b, &r, pos, koma.Player(),  1,  1 )
		kikiStraight( b, &r, pos, koma.Player(), -1,  1 )
		kikiStraight( b, &r, pos, koma.Player(),  1, -1 )
		kikiStraight( b, &r, pos, koma.Player(), -1, -1 )
	}
	
	return r
}

func CalcKikiPoint( b *Node, kiki [][]int ) int {
	p := 0
	for y:=1; y<=shogi.BoardSize; y++ {
		for x:=1; x<=shogi.BoardSize; x++ {
			pos := shogi.MakePos(x,y)
			koma := b.Cell( pos )
			if koma == shogi.Blank { continue }
			idx := pos.Int()
			pl := koma.Player()
			if kiki[pl][idx] < kiki[pl.Switch()][idx] {
				p += KikiKomaPoint[koma.Kind()] * pl.Dir() * 10
			}else if koma.Kind() != shogi.OU && kiki[pl][idx] > 0 {
				p += KikiKomaPoint[koma.Kind()] * -pl.Dir()
			}
		}
	}
	return p/100
}


func boardMode( filename string, level_str string ) error {
	level, err := strconv.Atoi( level_str )
	if err != nil { return err }
	
	rand.Seed(time.Now().UTC().UnixNano())

	kif, err := kifu.LoadAuto( filename )
	if err != nil { return err }
	
	b := NewNode()
	b.Board = *kif.Board()
	b.ProgressCommands( kif.Commands() )

	fmt.Println( b )

	//watcher := NewWatcher()
	history, point, param := Solv( b, level, -b.Teban.Dir(), *parallel )
	fmt.Println( history )
	fmt.Printf( "COM: %s POINT: %d COUNT:%d\n", history[0], point, param.Count)

	b.Progress( history[0] )
	
	// fmt.Println( b )
	
	return nil
}

func pipeMode() error {
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
		result, point, _ := Solv( node, rest_level, sign, *parallel )

		result_str := []string{}
		for _,x:= range result { result_str = append( result_str, fmt.Sprintf("%s",x) ) }
		fmt.Printf( "%s %d\n", strings.Join(result_str,","), point )

	}
	return nil
}

//-----------------------------------------------------------

type Node struct {
	shogi.Board
	point int
}

var KikiKomaPoint = []int {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0,100, 200, 200, 400, 500, 800,1000,1000, 600, 500, 500, 500,1000,1200,
}

var POINT = []int {
	//NN;  FU;  KY;  KE;  GI;  KI;  KA;  HI;   OU;  TO;  NY;  NK;  NG;  UM;  RY
        0,100, 200, 200, 400, 500, 800,1000,99999, 600, 500, 500, 500,1000,1200,
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
	p := calcKomaPoint( n )
	kiki := calcKiki( n )
	p += CalcKikiPoint( n, kiki )
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
	use_level := 8
	// if r.Cell( choice.To ) != shogi.Blank { use_level = 4 }
	return r, use_level
}

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
	Count int
	InChannel chan SolvInChan
	BasePoint int
}

type SolvInChan struct {
	OutChannel chan SolvOutChan
	Finish bool
	Param *Param
	Node *Node
	Choice shogi.Command
	Sign int
	Level int
	RestLevel int
	Limit int
}

type SolvOutChan struct {
	Choice shogi.Command
	Result []shogi.Command
	Point int
	Err error
}

type CacheItem struct {
	RestLevel int
	Point int
	Choices []shogi.Command
}

var mutex sync.Mutex

func SolvNode( param *Param, node *Node, sign int, level int, rest_level int, limit int ) ( []shogi.Command, int ) {

	// リーフの場合
	if rest_level <= 0 || node.Stop() {
		param.Count++
		return nil, node.Point() * sign
	}
	
	node.Hash()
	mutex.Lock()
	param.Count++
	item, exists := param.Cache[node.Hash()]
	mutex.Unlock()

	// キャッシュが利用できるなら帰る
	if exists && item.RestLevel >= rest_level { return item.Choices, item.Point*sign }
	
	choices := node.ListMovableAll(node.Teban)

	// 選択肢がないなら帰る
	if len(choices) <= 0 { return nil, node.Point() * sign }
	
	// 前回のベスト選択肢を先頭にする
	best_exists := false
	if exists {
		best_exists = true
		best_choice := item.Choices[0]
		for i, com := range choices {
			if best_choice == com {
				choices[i] = choices[0]
				choices[0] = best_choice
				break
			}
		}
	}

	// 悪すぎる場合は、どうせだめだろうということで読まない
	diff := node.Point() - param.BasePoint
	if diff < 0 { diff = -diff }
	if diff > rest_level * 30 + 1000 {
		return nil, node.Point() * sign
	}
	
	var r_choices []shogi.Command
	r_point := -math.MaxInt32
	if level == 0 && rest_level >= 4*8 && param.Parallel > 1 {
		// 並列バージョン
		outch := make(chan SolvOutChan)
		num_sent := 0
		num_buf := 0
		for i:=0; i<len(choices); i++ {
			for ; num_sent < len(choices) && num_buf < param.Parallel; {
				child, use_level := node.Choose( choices[num_sent] )
				if best_exists { use_level -= 4; best_exists = false }
				param.InChannel <- SolvInChan{outch, false,param, child, choices[num_sent], -sign, level+1, rest_level - use_level, -r_point }
				num_sent++
				num_buf++
			}
			res := <- outch
			num_buf--
			point := -res.Point
			if r_point < point {
				r_choices = append( []shogi.Command{res.Choice}, res.Result... )
				r_point = point
				// アルファ/ベータカット
				if point >= limit { break }
			}
		}

	}else{
		// 非並列バージョン
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
	}

	if exists || len(param.Cache) < 1000000 {
		mutex.Lock()
		param.Cache[node.Hash()] = &CacheItem{rest_level, r_point*sign, r_choices}
		mutex.Unlock()
	}

	return r_choices, r_point
}

func Solv( node *Node, level int, sign int, parallel int) ([]shogi.Command, int, *Param) {
	if sign != 1 && sign != -1 { os.Exit(1) }

	param := &Param{parallel,nil,0,make(chan SolvInChan, 32),node.Point()}
	runtime.GOMAXPROCS( param.Parallel )
	
	for i:=0; i<param.Parallel; i++ {
		go func(inch chan SolvInChan){
			for {
				in := <- inch
				if in.Finish { break }
				result, point := SolvNode( in.Param, in.Node, in.Sign, in.Level, in.RestLevel, in.Limit )
				in.OutChannel <- SolvOutChan{in.Choice,result,point,nil}
			}
		}(param.InChannel)
	}
	
	
	var history []shogi.Command
	var point int
	param.Cache = make( map[uint64]*CacheItem, 1000000 )
	for lv:=1; lv<=level; lv++ {
		history, point = SolvNode( param, node, sign, 0, lv*8, 99999999 )
		println( "cachesize:", len(param.Cache) )
	}

	
	for i:=0; i<param.Parallel; i++ {
		param.InChannel <- SolvInChan{nil,true,param, nil, shogi.Command{}, 0, 0, 0, 0}
	}

	return history,point,param
}
