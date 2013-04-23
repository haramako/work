package ab_method

import (
	//"fmt"
	//"strings"
	"math"
	"sync"
	"shogi"
)

type Watcher interface {
	OnCheck( Node )
}

type Param struct {
	Limit float64
	Level int
	RestLevel float64
	Sign float64
	Watcher Watcher
	Parallel int
}

type Node interface {
	String() string
	Choices() []shogi.Command
	Choose( shogi.Command ) (Node, float64)
	Point() float64
	Stop() bool
	SolvParallel( inch chan SolvInChan, outch chan SolvOutChan )
	Hash() uint64
}

type Walker interface {
	Inspect( Node )
}

type SolvInChan struct {
	Finish bool
	Param Param
	Node Node
	Choice shogi.Command
}

type SolvOutChan struct {
	Result []shogi.Command
	Point float64
	Err error
}

type CacheItem struct {
	RestLevel float64
	Point float64
	Choices []shogi.Command
}

var cache = make( map[uint64]*CacheItem, 1000*1000 )


// solvNodeの並列化バージョン
func solvNodeParallel( param Param, node Node, choices []shogi.Command ) ( []shogi.Command, float64 ) {
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

var mutex sync.Mutex

func SolvNode( param Param, node Node ) ( []shogi.Command, float64 ) {
	// fmt.Printf( "%ssolving: %s alpha:%d\n", strings.Repeat("  ", param.Level), node, param.Limit )

	var r_choices []shogi.Command
	var r_point float64

	node.Hash()
	mutex.Lock()
	if param.Watcher != nil { param.Watcher.OnCheck( node ) }
	item, exists := cache[node.Hash()]
	mutex.Unlock()
	if exists && item.RestLevel >= param.RestLevel {
		// キャッシュが利用できる
		r_choices = item.Choices
		r_point = item.Point
	}else{
		// キャッシュが利用できない
		choices := node.Choices()
		
		if exists && len(item.Choices)>0 {
			choices = append( []shogi.Command{item.Choices[0]}, choices... )
		}
		
		if param.RestLevel >= 0 && !node.Stop() && len(choices) > 0 {
			if param.Parallel > 1 {
				r_choices, r_point = solvNodeParallel( param, node, choices )
			}else{
				child_param := param
				child_param.Level += 1
				child_param.Sign = -param.Sign
				child_param.Limit = math.MaxInt32
				r_point = -math.MaxFloat64
				for i, choice := range choices {
					child, use_level := node.Choose( choice )
					child_param.RestLevel = param.RestLevel - use_level
					if i == 0 { child_param.RestLevel += 0.5 }
					result, point := SolvNode( child_param, child )
					point = -point
					if r_point < point {
						r_choices = append( []shogi.Command{choice}, result... )
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
			}
		}else{
			r_choices = []shogi.Command{}
			r_point = node.Point() * param.Sign
		}
		if len(cache) < 1000000 {
			mutex.Lock()
			cache[node.Hash()] = &CacheItem{param.RestLevel, r_point, r_choices}
			mutex.Unlock()
		}
	}
	// fmt.Printf( "%ssolved: %s %d\n", strings.Repeat("  ", param.Level), r_choices, r_point )
	return r_choices, r_point
}

var age = 0

func Solv( node Node, level float64, positive bool, parallel int, watcher Watcher) ([]shogi.Command, float64) {
	sign := 1.0
	if !positive { sign = -1 }
	param := Param{9999999,0,level,sign,watcher,parallel}
	a, b := SolvNode( param, node )
	println( "cachesize:", len(cache) )
	return a,b
}

func SolvRepeat( node Node, level float64, positive bool, parallel int, watcher Watcher) ([]shogi.Command, float64) {
	var a []shogi.Command
	var b float64
	//cache = make( map[uint64]*CacheItem, 1000000 )
	for i:=1.0; i<=level; i+=1.0 {
		if i == level {
			a, b = Solv( node, i, positive, parallel, nil )
		}else{
			a, b = Solv( node, i, positive, parallel, nil )
		}
	}
	/*
	num_delete := 0
	for hash,item := range cache {
		if item.Age < age {
			num_delete++
			delete( cache,hash )
		}
	}
	println( "deleted:", num_delete )
	age++
	*/
	return a,b
}
