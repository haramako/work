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
}

type Node interface {
	String() string
	Choices() []string
	Choose( string ) (Node, float64)
	Point() float64
	Stop() bool
}

type Walker interface {
	Inspect( Node )
}

func solvNode( param Param, node Node ) ( []string, float64 ) {
	// fmt.Printf( "%ssolving: %s alpha:%d\n", strings.Repeat("  ", param.Level), node, param.Limit )
	if param.Watcher != nil { param.Watcher.OnCheck( node ) }
	
	choices := node.Choices()
	var r_choices []string
	var r_point float64
	if param.RestLevel >= 0 && !node.Stop() && len(choices) > 0 {
		child_param := param
		child_param.Level += 1
		// child_param.RestLevel -= 1.0
		child_param.Sign = -param.Sign
		child_param.Limit = math.MaxInt32
		r_point = -math.MaxFloat64
		for _, choice := range choices {
			child, use_level := node.Choose( choice )
			child_param.RestLevel = param.RestLevel - use_level
			result, point := solvNode( child_param, child )
			point = -point
			if r_point < point {
				r_choices = append( []string{choice}, result... )
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
	}else{
		r_choices = []string{}
		r_point = node.Point() * param.Sign
	}
	// fmt.Printf( "%ssolved: %s %d\n", strings.Repeat("  ", param.Level), r_choices, r_point )
	return r_choices, r_point
}

func Solv( node Node, level float64, positive bool, watcher Watcher) ([]string, float64) {
	sign := 1.0
	if !positive { sign = -1 }
	param := Param{9999999,0,level,sign,watcher}
	return solvNode( param, node )
}
