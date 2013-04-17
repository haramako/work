package main

import (
	"fmt"
	"os"
	"path/filepath"
	"shogi/kifu"
	"shogi/kifu/ki2"
	"shogi/kifu/csa"
)

func main() {
	if len(os.Args) <= 1 {
		println( "./shogi [dir] ..." )
		os.Exit(0)
	}

	kifu.AddLoader( kifu.Loader{ []string{".ki2"}, ki2.Parse } )
	kifu.AddLoader( kifu.Loader{ []string{".csa"}, csa.Parse } )

	for _, path := range os.Args[1:] {
		err := filepath.Walk( path, func( path string, info os.FileInfo, err error ) error {
			fmt.Println( "checking " + path )

			if info.IsDir() { return nil }

			k, err := kifu.LoadAuto( path )
			if err != nil { return err }
			
			b := k.Board()
			b.ProgressCommands( k.Commands() )

			return nil
		})
		if err != nil {
			fmt.Printf( "error: %s\n", err )
		}
	}
}
