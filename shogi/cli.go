package main

import (
	"fmt"
	"time"
	"math/rand"
	"os"
	"flag"
	"log"
	"os/exec"
	"bufio"
	"strings"
	"io"
	"strconv"
	"runtime/pprof"
	. "shogi"
	"shogi/net/csa"
)



func mainloop() error {
	name := fmt.Sprintf( "hoge%d", rand.Intn(1000) )
	//cli, err := csa.NewClient(name,name,"10.211.55.2:4081")
	cli, err := csa.NewClient(name,name,"192.168.11.4:4081")
	if err != nil { return err }
	mycli, err := NewMyClient()
	if err != nil { return err }
	cli.SetCallback( mycli )
	return cli.Run()
}

var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")

func main(){
	
    flag.Parse()
    if *cpuprofile != "" {
        f, err := os.Create(*cpuprofile)
        if err != nil {
            log.Fatal(err)
        }
        pprof.StartCPUProfile(f)
        defer pprof.StopCPUProfile()
    }

	rand.Seed(time.Now().UTC().UnixNano())

	for {
		err := mainloop()
		if err != nil {
			fmt.Printf( "error: %s\n", err )
		}
		break
	}

}

type MyClient struct {
}

func NewMyClient() (*MyClient, error) {
	c := new(MyClient)
	return c, nil
}

func (c *MyClient) Play( b *Board ) (string, error) {
	// cmd := exec.Command( "./think", "-p", "1", "pipe" )
	cmd := exec.Command( "../cshogi/shogi", "pipe" )
	pipeerr, err := cmd.StderrPipe()
	if err != nil { return "", err }
	go io.Copy( os.Stderr, pipeerr )
	pipein, err := cmd.StdinPipe()
	if err != nil { return "", err }
	pipeout_raw, err := cmd.StdoutPipe()
	if err != nil { return "", err }
	pipeout := bufio.NewReader( pipeout_raw )
	err = cmd.Start()
	if err != nil { return "", err }

	sign := 1
	if b.Teban == Gote { sign = -1 }

	level := 0
	rest_level := 4

	str := fmt.Sprintf( "%s %d %d 9999999 %d\n", b.SerializeHex(), level, rest_level, sign)
	fmt.Println( str )
	_, err = pipein.Write( []byte(str) )
	if err != nil { return "", err }
		
	line, _, err := pipeout.ReadLine()
	if err != nil { fmt.Println( line ); return "", err }
	fmt.Println( "THINK:", string(line) )

	s := strings.Split(string(line)," ")
	result_str := strings.Split(s[0],",")

	point, err := strconv.ParseFloat( s[1], 64 )
	if err != nil { return "", err }

	
	if point < -10000 {
		return "%TORYO", nil
	}
	return result_str[0], nil
}

