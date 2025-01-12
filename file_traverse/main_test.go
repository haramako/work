package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"testing"
)

func TestSampleTest(t *testing.T) {
	var size int64 = 0
	count := 0
	root := "E:/Backup/Media"
	//root := "C:/Work/DE4"
	filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		count++
		info, err := d.Info()
		if err != nil {
			return err
		}
		size += info.Size()
		return nil
	})
}

const ROOT = "C:/Work/DE4"

func BenchmarkWalk(b *testing.B) {
	maxCount := 0
	for i := 0; i < b.N; i++ {
		count := 0
		filepath.WalkDir(ROOT, func(path string, d fs.DirEntry, err error) error {
			count++
			return nil
		})
		maxCount = count
	}
	_ = maxCount
}

func BenchmarkTraverse(b *testing.B) {
	for i := 0; i < b.N; i++ {
		entry, err := Traverse(ROOT)
		if err != nil {
			b.Error(err)
		}
		_ = entry
	}
}

func BenchmarkSave(b *testing.B) {
	b.Skip()
	for i := 0; i < b.N; i++ {
		entry, err := Traverse(ROOT)

		if err != nil {
			b.Error(err)
		}

		entry.Save("test.bin")
	}
}

func BenchmarkSave2(b *testing.B) {
	entry, err := Traverse(ROOT)
	if err != nil {
		b.Error(err)
	}
	b.ResetTimer()

	for i := 0; i < b.N; i++ {
		entry.Save2("test.bin")
	}
}

func BenchmarkSaveSqlite(b *testing.B) {
	entry, err := Traverse(ROOT)
	if err != nil {
		b.Error(err)
	}
	b.ResetTimer()

	for i := 0; i < b.N; i++ {

		err := os.Remove("test.db")
		if err != nil && err != os.ErrNotExist {
			b.Error(err)
		}

		//b.ResetTimer()

		err = entry.SaveSqlite("test.db")
		if err != nil {
			b.Error(err)
		}
	}
}
