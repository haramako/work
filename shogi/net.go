package main

import (
	"net"
	"fmt"
	"os"
	"io"
	"bufio"
	"strings"
	_ "shogi"
)

func doLine( line string ) []string {
	if line == "" { return nil }
	r := []string{}
	com := strings.Split( line, " " )
	switch com[0] {
	case "LOGIN":
		r = append( r,
			fmt.Sprintf("LOGIN:%s OK", com[1]),
			"BEGIN Game_Summary",
			"Protocol_Version:1.1",
			"Protocol_Mode:Server",
			"Format:Shogi 1.0",
			"Name+:SENTE",
			"Neme-:GOTE",
			"Your_Turn:+",
			"Rematch_On_Draw:NO",
			"To_Move:+",
			"BEGIN Time",
			"Time_Unit:1sec",
			"Total_Time:1500",
			"END Time",
			"BEGIN Position",
			"P1-KY-KE-GI-KI-OU-KI-GI-KE-KY",
			"P2 * -HI *  *  *  *  * -KA * ",
			"P3-FU-FU-FU-FU-FU-FU-FU-FU-FU",
			"P4 *  *  *  *  *  *  *  *  * ",
			"P5 *  *  *  *  *  *  *  *  * ",
			"P6 *  *  *  *  *  *  *  *  * ",
			"P7+FU+FU+FU+FU+FU+FU+FU+FU+FU",
			"P8 * +KA *  *  *  *  * +HI * ",
			"P9+KY+KE+GI+KI+OU+KI+GI+KE+KY",
			"P+",
			"P-",
			"+",
			"END Position",
			"END Game_Summary",
			)
	case "LOOUT":
		r = append( r, "LOGOUT:completed" )
	case "AGREE":
		r = append( r, "START:" )
	default:
		fmt.Println( "unknown command: ", line )
	}
	return r
}

func handler(conn net.Conn) {
	defer conn.Close()

	reader := bufio.NewReader(conn)

	for {
		line, _, err := reader.ReadLine()
		if err != nil {
			if err == io.EOF {
				fmt.Println( "disconnected" )
				break
			}else{
				fmt.Printf("%s\n", err)
				break
			}
		}
		fmt.Println( string(line) )
		for _, result := range doLine( string(line) ) {
			fmt.Println( "->", result )
			conn.Write( []byte(result+"\n") )
		}
	}
	
}

func main() {
	sock, err := net.Listen("tcp", "0.0.0.0:4081")
	if err != nil {
		fmt.Printf("error %s", err)
		os.Exit(1)
	}
	for {
		conn, err := sock.Accept()
		if err != nil {
			fmt.Printf("error %s", err)
			continue
		}
		go handler(conn)
	}
}