package main

import (
	"fmt"
	"os"
	"testing"
)

var cachedRoot *Tree

const testRoot = "C:/Work/work"

func getRoot() *Tree {
	if cachedRoot != nil {
		return cachedRoot
	}

	entry, err := Traverse(testRoot)
	if err != nil {
		panic(err)
	}
	return entry
}

func getTestRoot() *Entry {
	root := &Entry{Filename: "root", Children: map[string]*Entry{}}
	hoge := root.AddDummyChild("hoge", 1)
	hoge.AddDummyChild("fuga", 2)
	root.AddDummyChild("piyo", 3)
	return root
}

func TestDummy(t *testing.T) {
	root := getTestRoot()
	_ = root.Walk(func(path []string, e *Entry) error {
		t.Logf("%v %v", path, e.Filename)
		return nil
	})
	t.Logf("%v %v", root.TotalCount(), root.TotalSize())

	if root.TotalCount() != 4 {
		t.Error("TotalCount must be 4")
	}
	if root.TotalSize() != 6 {
		t.Error("TotalSize must be 6")
	}
}

func TestGetEntry(t *testing.T) {
	root := getTestRoot()
	entry, err := root.GetEntry("hoge", false)
	if err != nil {
		t.Error(err)
	}
	if entry.Filename != "hoge" {
		t.Error("hoge not found")
	}

	paths := SplitPath("hoge\\fuga")
	t.Log(paths)
	entry, err = root.GetEntry("hoge\\fuga", false)
	if err != nil {
		t.Error(err)
	}
	if entry.Filename != "fuga" {
		t.Error("fuga not found")
	}
}

func TestEntry(t *testing.T) {
	tree := getRoot()
	root := tree.Root
	t.Logf("totalCount %v size %v", root.TotalCount(), root.TotalSize())
	if root.TotalCount() < 1000 {
		t.Error("total count must > 1000")
	}
	if root.TotalSize() < 100000000 {
		t.Error("total sizet must > 100000000")
	}
}

func TestWalk(t *testing.T) {
	root := getRoot()
	count := 0
	err := root.Root.Walk(func(path []string, e *Entry) error {
		count++
		t.Logf("%v %v", path, e.Filename)
		if count > 10 {
			t.Log("finished")
			return fmt.Errorf("finished")
		}
		return nil
	})
	if err == nil {
		t.Errorf("Must return error")
	}
}

func TestSave(t *testing.T) {
	root := getRoot()
	root.Save("test.bin")
}

func TestSave2(t *testing.T) {
	t.Skip()
	root := getRoot()
	root.Save2("test.bin")
}

func TestSqlite(t *testing.T) {
	root := getRoot()
	os.Remove("test.db")
	err := root.SaveSqlite("test.db")
	if err != nil {
		t.Error(err)
	}
	//t.Fail()
}
