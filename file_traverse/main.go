package main

import (
	"flag"
	"fmt"
)

func main() {
	flag.Parse()
	for _, f := range flag.Args() {
		entry, err := Traverse(f)
		if err != nil {
			panic(err)
		}
		fmt.Printf("%s %d files, %d MB", f, entry.TotalCount(), entry.TotalSize()/(1024*1024))
		entry.Save("out.bin")
	}
}
