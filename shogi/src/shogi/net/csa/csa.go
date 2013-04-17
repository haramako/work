package csa

import (
	"net"
	"fmt"
	"bufio"
	"strings"
	"errors"
	"shogi"
	"shogi/kifu/csa"
	shogi_net "shogi/net"
)

type Client struct {
	conn *net.TCPConn
	reader *bufio.Reader
	name string
	pass string
	gameId string
	playerNames [2]string
	myTeban shogi.Player
	position string
	board *shogi.Board
	callback shogi_net.ClientCallback
}

type Chunk struct {
	tag string
	body []string
	subChunk map[string]*Chunk
}

func NewClient( name, pass, addr string ) (shogi_net.Client, error) {
	c := new(Client)
	c.name = name
	c.pass = pass
	
	tcp_addr, err := net.ResolveTCPAddr("tcp4",addr)
	if err != nil { return nil, err }

	c.conn, err = net.DialTCP( "tcp", nil, tcp_addr )
	if err != nil { return nil, err }

	c.reader = bufio.NewReader(c.conn)
	
	return c, nil
}

func (c *Client) SetCallback( callback shogi_net.ClientCallback ) {
	c.callback = callback
}

func (c *Client) Send( line string ) {
	fmt.Printf( "%s>> %s\n", c.name, string(line) )
	c.conn.Write( []byte( line + "\n" ) )
}

func (c *Client) Recv() (string, error) {
	line, _, err := c.reader.ReadLine()
	fmt.Printf( "%s<< %s\n", c.name, string(line) )
	return string(line), err
}

func (c *Client) Run() error {
	defer c.conn.Close()

	c.Send( "LOGIN "+c.name+" "+c.pass )

	for {
		multi_line, err := c.Recv()
		if err != nil { return err }
		for _, line := range strings.Split(multi_line, ",") {
			err := c.doCommand( line )
			if err != nil { return err }
		}
	}
	
	return nil
}

func (c *Client) doCommand( line string ) error {
	if line == "" { return nil }
	com := strings.SplitN( line, " ", 2 )
	switch com[0] {
	case "BEGIN":
		chunk, err := c.getChunk( com[1] )
		if err != nil { return err }
		if err = c.doChunkCommand( chunk ); err != nil { return err }
	default:
		com := strings.SplitN( line, ":", 2 )
		switch( com[0] ){
		case "START":
			kifu, err := csa.Parse( c.position )
			if err != nil { return err }
			c.board = kifu.Board()
			c.Play()
		case "LOGIN":
		default:
			switch line[0] {
			case '+', '-':
				com, _ := shogi.ParseCommand( line )
				c.board.Progress( com )
				c.Play()
			case '#':
				switch line {
				case "#SENNICHITE":
				case "#ILLEGAL_MOVE","#LOSE","#WIN","#DRAW":
					fmt.Println( c.board )
					fmt.Printf( "%sの勝ち\n", shogi.PlayerReadableString[c.board.Teban.Switch()] )
					return errors.New(line)
				default:
					fmt.Println( "unknown command:", line )
				}
			case 'T':
				// DO NOTHING
			default:
				fmt.Println( "unknown command:", line )
			}
		}
	}
	return nil
}

func (c *Client) getChunk( tag string ) (*Chunk, error) {
	r := new(Chunk)
	r.tag = tag
	r.subChunk = make(map[string]*Chunk)
	
	for {
		line, err := c.Recv()
		if err != nil { return nil, err }
		if strings.HasPrefix(line, "END ") {
			return r, nil
		}else if strings.HasPrefix(line, "BEGIN ") {
			sub_tag := line[len("BEGIN "):]
			chunk, err := c.getChunk(sub_tag)
			if err != nil { return nil, err }
			r.subChunk[sub_tag] = chunk
		}else{
			r.body = append( r.body, line )
		}
	}
	return nil, nil
}

func parseKeyValue( body []string ) map[string]string {
	r := make( map[string]string, 16 )
	for _, line := range body {
		if line == "" { continue }
		vk := strings.SplitN( line, ":", 2 )
		r[vk[0]] = vk[1]
	}
	return r
}

func (c *Client) doChunkCommand( chunk *Chunk ) error {
	switch( chunk.tag ){
	case "Game_Summary":
		kv := parseKeyValue( chunk.body )
		c.gameId = kv["Game_ID"]
		c.playerNames[0] = kv["Name+"]
		c.playerNames[1] = kv["Name-"]
		if c.playerNames[0] == c.name {
			c.myTeban = shogi.Sente
		}else{
			c.myTeban = shogi.Gote
		}
		c.position = strings.Join( chunk.subChunk["Position"].body, "\n" )
		c.Send( "AGREE "+c.gameId )
	default:
		fmt.Println( "unknown chunk:", chunk.tag )
	}
	return nil
}

func (c *Client) Play(){
	if c.board.Teban == c.myTeban {
		com, _ := c.callback.Play( c.board )
		c.Send( com )
	}
}

