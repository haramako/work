package main

import (
	"fmt"
	"io"
	"net/http"

	_ "github.com/mattn/go-sqlite3"
)

type Downloader struct {
	repo *CacheRepository
}

func NewDownloader(dbpath string) (*Downloader, error) {
	repo, err := NewCacheRepository("sqlite3")
	if err != nil {
		return nil, err
	}
	return &Downloader{repo: repo}, nil
}

func (d *Downloader) Close() error {
	if d.repo != nil {
		if err := d.repo.Close(); err != nil {
			return err
		}
	}
	return nil
}

func (d *Downloader) Send(url string) error {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return err
	}

	req.Header.Set("Egag", "W/\"ce72074085ff1f00d9867ce84bc3d7d1\"")

	cli := http.Client{}
	resp, err := cli.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		fmt.Println("ステータス:", resp.Status)
		fmt.Println("ボディの最初の100文字:", string(body[:100])) // 文字化けの可能性あり
		fmt.Printf("%v\n", resp.Header.Get("ETag"))
		fmt.Printf("%v\n", resp.Header)
		return nil
	} else {
		return fmt.Errorf("HTTP error %v %s", resp.StatusCode, resp.Status)
	}
}
