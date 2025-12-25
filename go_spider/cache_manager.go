package main

import (
	"database/sql"
	"fmt"
	"strconv"
	"time"

	_ "github.com/mattn/go-sqlite3"
)

type CacheRepository struct {
	db *sql.DB
}

func NewCacheRepository(dbpath string) (*CacheRepository, error) {
	db, err := sql.Open("sqlite3", dbpath)
	if err != nil {
		return nil, err
	}
	r := &CacheRepository{db: db}
	if err = r.initDatabase(); err != nil {
		return nil, err
	}
	return r, nil
}

const initDb1 = `
create table if not exists configs (
  key string primary key,
  value string not null
);
create table if not exists caches (
   url string primary key,
   status_code int not null,
   etag string not null,
   path string not null,
   expire_at date not null,
   created_at date not null,
   updated_at date not null
);
`

type Cache struct {
	Url        string `db:"url"`
	StatusCode int    `db:"status_code"`
	ETag       string `db:"etag"`
	Path       string
	ExpireAt   time.Time `db:"expire_at"`
	CreatedAt  time.Time `db:"created_at"`
	UpdatedAt  time.Time `db:"updated_at"`
}

func (r *CacheRepository) initDatabase() error {
	var version int
	versionStr, err := r.GetConfig("version")
	if err != nil {
		version = 0
	} else {
		version, err = strconv.Atoi(versionStr)
		if err != nil {
			return err
		}
	}

	if version <= 0 {
		if _, err := r.db.Exec(initDb1); err != nil {
			return fmt.Errorf("can't init database: %v", err)
		}
	}
	if err := r.SetConfig("version", strconv.Itoa(1)); err != nil {
		return err
	}
	return nil
}

func (r *CacheRepository) GetConfig(key string) (string, error) {
	rows, err := r.db.Query("select value from configs where key = ?", key)
	if err != nil {
		return "", fmt.Errorf("getConfig failed: %v", err)
	}
	defer rows.Close()

	if !rows.Next() {
		return "", fmt.Errorf("config key not found '%s'", key)
	}

	var value string
	if err = rows.Scan(&value); err != nil {
		return "", err
	}
	return value, nil
}

func (r *CacheRepository) SetConfig(key string, value string) error {
	_, err := r.db.Exec("insert or replace into configs(key, value) values (?,?)", key, value)
	if err != nil {
		return fmt.Errorf("setConfig failed: %v", err)
	}
	return nil
}

func (r *CacheRepository) FindCache(url string) (*Cache, error) {
	rows, err := r.db.Query("select status_code, etag, path, expire_at, created_at, updated_at from caches where url = ?", url)
	if err != nil {
		return nil, fmt.Errorf("select failed: %v", err)
	}
	defer rows.Close()
	if !rows.Next() {
		return nil, nil
	}
	cache := Cache{Url: url}
	if err = rows.Scan(&cache.StatusCode, &cache.ETag, &cache.Path, &cache.ExpireAt, &cache.CreatedAt, &cache.UpdatedAt); err != nil {
		return nil, fmt.Errorf("scan failed: %v", err)
	}
	return &cache, nil
}

func (r *CacheRepository) SaveCache(cache *Cache) error {
	_, err := r.db.Exec(
		"insert or replace into caches(url, status_code, etag, path, expire_at, created_at, updated_at) values (?,?,?,?,?,?,?)",
		cache.Url, cache.StatusCode, cache.ETag, cache.Path, cache.ExpireAt, cache.CreatedAt, cache.UpdatedAt)
	if err != nil {
		return fmt.Errorf("insert failed: %v", err)
	}
	return nil
}

func (r *CacheRepository) Close() error {
	if r.db != nil {
		if err := r.db.Close(); err != nil {
			return err
		}
	}
	return nil
}
