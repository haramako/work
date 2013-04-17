package main

import (
	"fmt"
	"time"
	"math/rand"
	"shogi"
	"shogi/net/csa"
)



func mainloop() error {
	name := fmt.Sprintf( "zako%d", rand.Intn(1000) )
	cli, err := csa.NewClient(name,name,"localhost:4081")
	if err != nil { return err }
	cli.SetCallback( new(MyClient) )
	return cli.Run()
}

func main(){
	rand.Seed(time.Now().UTC().UnixNano())

	for {
		err := mainloop()
		if err != nil {
			fmt.Printf( "error: %s\n", err )
			// break
		}
	}

}

type MyClient struct{}

func (c *MyClient) Play( b *shogi.Board ) (string, error) {
	coms := b.ListMovableAll( b.Teban )
	com := coms[rand.Intn(len(coms))]
	return com.String(), nil
}
