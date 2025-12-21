package main

import (
	"fmt"
	"io/fs"
	"path/filepath"
)

type Result = struct {
	FileCount uint64
	Size      uint64
}

func main() {
	dir := "C:/Work/DE4/DE4"
	var acc Result
	filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error { return walk(&acc, path, d, err) })
	fmt.Printf("%v %v\n", acc.FileCount, acc.Size/(1024*1024))
}

func walk(acc *Result, path string, d fs.DirEntry, err error) error {
	if err != nil {
		return err
	}
	info, err := d.Info()
	acc.FileCount++
	acc.Size += uint64(info.Size())
	//println(path)
	return nil
}
