#!/bin/sh
source ~/.bashrc # to load rbenv
export BASE_URL='http://133.242.225.63:10000'
ruby cabinet_server.rb -o '0.0.0.0' -p 10000
