package main

import (
	"os"
	"testing"
)

func TestHoge(t *testing.T) {
	//t.Errorf("HOGE")
}

func TestSend(t *testing.T) {
	/*
		err := send("https://qiita.com/hanlio/items/0505c266c114127c6457")
		//err := send("https://www.google.com/")

		if err != nil {
			t.Error(err)
		}
	*/
}

func TestNewDownloader(t *testing.T) {
	dbpath := "test.db"
	os.Remove(dbpath)
	d, err := NewCacheRepository(dbpath)
	if err != nil {
		t.Error(err)
	}
	defer d.Close()

	url := "http://google.com"
	cache := Cache{Url: url, StatusCode: 200}
	if err = d.SaveCache(&cache); err != nil {
		t.Error(err)
	}

	cache2, err := d.FindCache(url)
	if err != nil {
		t.Error(err)
	}
	t.Logf("%v\n", cache2)

	cache3, err := d.FindCache("hoge")
	if err != nil {
		t.Error(err)
	}
	t.Logf("%v\n", cache3)
}
