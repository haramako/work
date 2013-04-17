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
	Limit int
	Level int
	MaxLevel int
	Sign int
	Watcher Watcher
}

type Node interface {
	String() string
	Choices() []string
	Choose( string ) Node
	Point() int
	Stop() bool
}

type Walker interface {
	Inspect( Node )
}

func solvNode( param Param, node Node ) ( []string, int ) {
	//fmt.Printf( "%ssolving: %s alpha:%d\n", strings.Repeat("  ", param.Level), node, param.Limit )
	if param.Watcher != nil { param.Watcher.OnCheck( node ) }
	
	choices := node.Choices()
	var r_choices []string
	var r_point int
	if param.Level < param.MaxLevel && !node.Stop() && len(choices) > 0 {
		child_param := param
		child_param.Level += 1
		child_param.Sign = -param.Sign
		r_point = math.MinInt32
		for _, choice := range choices {
			child := node.Choose( choice )
			result, point := solvNode( child_param, child )
			point = -point
			if r_point < point {
				r_choices = append( []string{choice}, result... )
				r_point = point
				child_param.Limit = -point
				// アルファ/ベータカット
				if point >= param.Limit { 
					//fmt.Printf("%salpha/beta cut %v %d\n", strings.Repeat("  ", child_param.Level), child, point);
					break
				}
			}
		}
	}else{
		r_choices = []string{}
		r_point = node.Point() * param.Sign
	}
	//fmt.Printf( "%ssolved: %s %d\n", strings.Repeat("  ", param.Level), r_choices, r_point )
	return r_choices, r_point
}

func Solv( node Node, level int, positive bool, watcher Watcher) ([]string, int) {
	sign := 1
	if !positive { sign = -1 }
	param := Param{math.MaxInt32,0,level,sign,watcher}
	return solvNode( param, node )
}
