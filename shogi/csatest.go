package main

import (
	"fmt"
	"os"
	"io/ioutil"
	"path"
	"strings"
	_ "shogi"
	"shogi/kifu"
	"shogi/kifu/ki2"
	"shogi/kifu/csa"
)

func checkFile( file string, src string ) error {
	var k kifu.Kifu
	var err error = nil
	
	switch strings.ToLower(path.Ext( file )) {
	case ".csa":
		k, err = csa.Parse( src )
	case ".ki2":
		k, err = ki2.Parse( src )
	default:
		fmt.Printf( "unkonown format %s\n", file )
		return nil
	}
	if err != nil { return err }
	
	b := k.Board()
	b.ProgressCommands( k.Commands() )
	
	return nil
}

func checkDir( dir string ) error {
	files, err := ioutil.ReadDir( dir )
	fmt.Println( dir )
	if err != nil { return err }
	for _, file := range files {
		err := check( path.Join( dir, file.Name() ) )
		if err != nil { return err }
	}
	return nil
}

func check( file string ) error {
	fmt.Println( "checking " + file )

	// ディレクトリかどうか確かめる
	stat, err := os.Stat( file )
	if err != nil { return err }
	if stat.Mode().IsDir() {
		return checkDir( file )
	}
	
	src, err := ioutil.ReadFile( file )
	if err != nil { return err }
	
	src, err = kifu.ConvertEncodingAuto( src )
	if err != nil { return err }

	err = checkFile( file, string(src) )
	if err != nil { return err }

	return nil
}

func main() {
	if len(os.Args) <= 1 {
		println( "./shogi [dir] ..." )
		os.Exit(0)
	}

	kifu.AddLoader( kifu.Loader{ []string{".ki2"}, ki2.Load } )
	kifu.AddLoader( kifu.Loader{ []string{".csa"}, csa.Load } )

	for _, file := range os.Args[1:] {
		err := check( file )
		if err != nil {
			fmt.Printf( "error: %s\n", err )
			os.Exit(1)
		}
	}
}
