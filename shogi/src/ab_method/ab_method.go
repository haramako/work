package ab_method

import (
	//"fmt"
	//"strings"
	"math"
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
	Choices() []interface{}
	Choose( interface{} ) (Node, float64)
	Point() float64
	Stop() bool
	SolvParallel( inch chan SolvInChan, outch chan SolvOutChan )
}

type Walker interface {
	Inspect( Node )
}

type SolvInChan struct {
	Finish bool
	Param Param
	Node Node
	Choice interface{}
}

type SolvOutChan struct {
	Result []interface{}
	Point float64
	Err error
}


// solvNodeの並列化バージョン
func solvNodeParallel( param Param, node Node, choices []interface{} ) ( []interface{}, float64 ) {
	var r_choices []interface{}
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
		inch <- SolvInChan{true,child_param, nil,nil}
	}
	
	return r_choices, r_point
}

func SolvNode( param Param, node Node ) ( []interface{}, float64 ) {
	// fmt.Printf( "%ssolving: %s alpha:%d\n", strings.Repeat("  ", param.Level), node, param.Limit )
	if param.Watcher != nil { param.Watcher.OnCheck( node ) }
	
	choices := node.Choices()
	var r_choices []interface{}
	var r_point float64
	if param.RestLevel >= 0 && !node.Stop() && len(choices) > 0 {
		if param.Parallel > 1 {
			r_choices, r_point = solvNodeParallel( param, node, choices )
		}else{
			child_param := param
			child_param.Level += 1
			child_param.Sign = -param.Sign
			child_param.Limit = math.MaxInt32
			r_point = -math.MaxFloat64
			for _, choice := range choices {
				child, use_level := node.Choose( choice )
				child_param.RestLevel = param.RestLevel - use_level
				result, point := SolvNode( child_param, child )
				point = -point
				if r_point < point {
					r_choices = append( []interface{}{choice}, result... )
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
		r_choices = []interface{}{}
		r_point = node.Point() * param.Sign
	}
	// fmt.Printf( "%ssolved: %s %d\n", strings.Repeat("  ", param.Level), r_choices, r_point )
	return r_choices, r_point
}

func Solv( node Node, level float64, positive bool, parallel int, watcher Watcher) ([]interface{}, float64) {
	sign := 1.0
	if !positive { sign = -1 }
	param := Param{9999999,0,level,sign,watcher,parallel}
	return SolvNode( param, node )
}
