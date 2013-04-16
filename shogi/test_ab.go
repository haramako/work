package main

import (
	"fmt"
	"encoding/json"
	"reflect"
	"errors"
	"strconv"
	. "ab_method"
)

var nameIdx = 0

type TestNode struct {
	point int
	children map[string]*TestNode
	name string
}

func (n *TestNode) Point() int {
	return n.point
}

func (n *TestNode) Stop() bool {
	return n.point != 0
}

func (n *TestNode) Choices() []string {
	r := make([]string, len(n.children))
	i := 0
	for k, _ := range n.children {
		r[i] = k
		i++
	}
	return r
}

func (n *TestNode) Choose(choice string) Node {
	return n.children[choice]
}

func (n *TestNode) String() string {
	if len(n.children) != 0 {
		return fmt.Sprintf("{%s %v}", n.name, n.children)
	}else{
		return fmt.Sprintf("{%s %d}", n.name, n.point )
	}
	return ""
}

func jsonToTestNode( j []byte ) (*TestNode, error) {
	var array []interface{}
	err := json.Unmarshal( j, &array )
	if err != nil { return nil, err }
	return unmarshalTestNode( array )
}

func unmarshalTestNode( val interface{} ) (*TestNode, error) {
	nameIdx++
	r := new(TestNode)
	r.children = make(map[string]*TestNode)
	r.name = fmt.Sprintf("N%d", nameIdx)
	
	// fmt.Println( val, reflect.TypeOf(val) )
	switch reflect.TypeOf(val).Kind() {
	case reflect.Float64:
		r.point = int( reflect.ValueOf(val).Float() )
	case reflect.Slice:
		array := val.([]interface{})
		for i, v := range array {
			new_node, err := unmarshalTestNode( v )
			if err != nil { return nil, err }
			r.children[strconv.Itoa(i)] = new_node
		}
	default:
		fmt.Println( "error", val, reflect.TypeOf(val), reflect.TypeOf(val).Kind() )
		return nil, errors.New("invalid json")
	}
	return r, nil
}

func main() {
	// node, err := jsonToTestNode( []byte(`[1,4,[3,5]]`) )
	node, err := jsonToTestNode( []byte(`[ [[1,3],[4,2]], [[2,1],[3,5]] ]`) )
	if err != nil { fmt.Println( err ) }
	fmt.Println( node )
	solv, point := Solv( node )
	fmt.Println( "result:", solv, point )
}
