package main

import (
	"encoding/binary"
	"math/rand"
	"os"
	"strconv"

	"github.com/syndtr/goleveldb/leveldb"
	"github.com/syndtr/goleveldb/leveldb/opt"
)

func check(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	n := 10000
	c := 1000
	if len(os.Args) > 2 {
		n64, err := strconv.ParseInt(os.Args[1], 10, 0)
		check(err)
		n = int(n64)

		c64, err := strconv.ParseInt(os.Args[1], 10, 0)
		check(err)
		c = int(c64)
	}

	dbFile := "level.db"
	err := os.RemoveAll(dbFile)
	check(err)

	db, err := leveldb.OpenFile(dbFile, nil)
	check(err)
	defer db.Close()

	var key [8]byte
	var value [16]byte

	rand.Seed(int64(1234))

	_, err = rand.Read(value[:])
	check(err)

	limit := n / 50
	wo := opt.WriteOptions{NoWriteMerge: false, Sync: false}

	for i := 0; i < n; i++ {
		id := rand.Int31n(int32(c))
		binary.BigEndian.PutUint64(key[:], uint64(id))
		err = db.Put(key[:], value[:], &wo)
		check(err)
		if i%limit == 0 {
			//print(".")
		}
	}

}
