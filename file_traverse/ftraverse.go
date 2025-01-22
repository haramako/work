package main

import (
	"bufio"
	"bytes"
	"database/sql"
	"encoding/binary"
	"encoding/gob"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	_ "github.com/mattn/go-sqlite3"
	_ "modernc.org/sqlite"
)

type Tree struct {
	Root    *Entry
	BaesDir string
}

type Entry struct {
	Parent     *Entry
	Filename   string
	Size       int64
	Children   map[string]*Entry
	totalSize  int64
	totalCount int
	aggregated bool
}

func (e *Entry) AddChild(child *Entry) {
	e.Children[child.Filename] = child
	child.Parent = e
}

func (e *Entry) AddDummyChild(name string, size int64) *Entry {
	newEntry := &Entry{Filename: name, Size: size, Children: map[string]*Entry{}}
	e.Children[name] = newEntry
	return newEntry
}

func Traverse(root string) (*Tree, error) {
	root = filepath.Clean(root)
	tree := &Tree{}
	rootEntry := &Entry{Filename: root, Children: map[string]*Entry{}}
	count := 0
	walkErr := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		count++
		info, err := d.Info()
		if err != nil {
			return err
		}
		if path != "" {
			parent, err := rootEntry.GetEntry(path[len(root):], true)
			if err != nil {
				return err
			}
			entry := &Entry{Filename: d.Name(), Size: info.Size(), Children: make(map[string]*Entry)}
			parent.AddChild(entry)
		}
		return nil
	})
	if walkErr != nil {
		return nil, walkErr
	}
	tree.Root = rootEntry
	return tree, nil
}

func SplitPath(path string) []string {
	return strings.Split(strings.ReplaceAll(path, "\\", "/"), "/")
}

func (e *Entry) GetEntry(path string, createIfNotFound bool) (*Entry, error) {
	paths := SplitPath(path)
	return e.GetEntryByList(paths, createIfNotFound)
}

func (e *Entry) GetEntryByList(path []string, createIfNotFound bool) (*Entry, error) {
	if len(path) == 0 {
		return e, nil
	} else {
		child, ok := e.Children[path[0]]
		if !ok {
			if createIfNotFound {
				child = &Entry{Parent: e, Filename: path[0], Children: map[string]*Entry{}}
				e.Children[child.Filename] = child
			} else {
				return nil, fmt.Errorf("%s not found in %s", e.Filename, path[0])
			}
		}
		return child.GetEntryByList(path[1:], createIfNotFound)
	}
}

func (e *Entry) Aggregate() {
	if e.aggregated {
		return
	}

	if len(e.Children) == 0 {
		e.totalCount = 1
		e.totalSize = e.Size
	} else {
		e.totalCount = 1
		e.totalSize = e.Size
		for _, c := range e.Children {
			e.totalCount += c.TotalCount()
			e.totalSize += c.TotalSize()
		}
	}
	e.aggregated = true
}

func (e *Entry) TotalCount() int {
	e.Aggregate()
	return e.totalCount
}

func (e *Entry) TotalSize() int64 {
	e.Aggregate()
	return e.totalSize
}

type WalkFunc func([]string, *Entry) error

func (e *Entry) Walk(f WalkFunc) error {
	return walkInner([]string{}, e, f)
}

func walkInner(path []string, e *Entry, f WalkFunc) error {
	err := f(path, e)
	if err != nil {
		return err
	}
	path = append(path, e.Filename)
	for _, c := range e.Children {
		err = walkInner(path, c, f)
		if err != nil {
			return err
		}
	}
	return nil
}

func (e *Entry) Save(path string) {
	buf := bytes.NewBuffer(nil)
	e.Walk(func(_ []string, e *Entry) error {
		e.Parent = nil
		return nil
	})
	gob.NewEncoder(buf).Encode(e)
	os.WriteFile(path, buf.Bytes(), 0666)
}

func (e *Entry) Save2(path string) {
	f, _ := os.OpenFile(path, os.O_CREATE, 0666)
	buf := bufio.NewWriter(f)
	//buf := bytes.NewBuffer(nil)
	e.Walk(func(_ []string, e *Entry) error {
		buf.WriteString(e.Filename)
		binary.Write(buf, binary.LittleEndian, e.Size)
		return nil
	})
	_ = buf.Flush()
	//os.WriteFile("test.bin", buf.Bytes(), 0666)
}

func (e *Entry) SaveSqlite(path string) error {
	//db, err := sql.Open("sqlite3", path)
	db, err := sql.Open("sqlite", path)
	if err != nil {
		return err
	}
	defer db.Close()

	_, err = db.Exec("CREATE TABLE files (path TEXT, size INTEGER)")
	if err != nil {
		return err
	}

	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()

	stInsert, err := tx.Prepare("INSERT INTO files (path, size) VALUES (?, ?)")
	if err != nil {
		return err
	}

	err = e.Walk(func(_ []string, e *Entry) error {
		_, err := stInsert.Exec(e.Filename, e.Size)
		if err != nil {
			//println(e.Filename, e.Size)
			return err
		}
		return nil
	})
	if err != nil {
		return err
	}

	err = tx.Commit()
	if err != nil {
		return err
	}

	return nil
}
