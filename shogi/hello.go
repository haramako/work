package main

import (
	"fmt"
	"os"
	"io/ioutil"
	"shogi"
	"shogi/kifu"
	"unsafe"
)

func main(){
	if false {
	if len(os.Args) <= 1 {
		println( "./shogi <csa file>" )
		os.Exit(0)
	}

	var s shogi.Command
	fmt.Println( unsafe.Sizeof(s) )
	
	src, err := ioutil.ReadFile( os.Args[1] )
	if err != nil {
		fmt.Printf( "can't read %s\n", os.Args[1] )
		os.Exit(1)
	}

	src, err = kifu.ConvertEncodingAuto( src )
	if err != nil {
		fmt.Println( err )
		os.Exit(1)
	}

	fmt.Println( string(src)[0:80] )
	kifu.ParseKi2( string(src) )
	return;
	}
	
	// board, tes := kifu.Parse( string(src) )
	board, tes := kifu.Parse( "PI" )
	
	fmt.Println( board )
	
	for _, te := range tes {
		board.Progress( te )
		fmt.Println( te )
	}
	
	fmt.Println( board.ListMovableAll(shogi.Sente) )
	fmt.Println( board )

}
