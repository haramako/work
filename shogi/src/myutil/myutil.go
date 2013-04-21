package myutil

import (
	"flag"
	"os"
	"log"
	"runtime/pprof"
)

var cpuprofile = flag.String("cpuprofile", "", "write cpu profile to file")
var proffile *os.File

func Init(){
	if *cpuprofile != "" {
		println( "start profile", *cpuprofile )
        proffile, err := os.Create(*cpuprofile)
        if err != nil {
            log.Fatal(err)
        }
        pprof.StartCPUProfile(proffile)
	}
}

func Finish(){
	if *cpuprofile != "" {
        pprof.StartCPUProfile(proffile)
	}
}
