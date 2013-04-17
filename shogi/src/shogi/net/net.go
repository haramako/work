package net

import "shogi"

type Client interface {
	Run() error
	SetCallback( ClientCallback )
}

type ClientCallback interface {
	Play( *shogi.Board ) (string, error)
}
