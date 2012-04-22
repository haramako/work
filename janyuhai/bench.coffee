#!/usr/env coffee
_ = require 'underscore'
game = require './game'
jan = require './jan'

game = new game.Game( [], {playerNum:4} )
choises = game.progress {type:'BAGIME', pub:[0,1,2,3]}

kyoku = 0
agari = 0
cn = (0 for i in [0..30])
try
    count = 100*8*10000/60/15
    for i in [0...count]
        com = _.find( choises, (c)->c.type == 'RON' or c.type == 'TSUMO_AGARI' )
        if com
            agari++
        unless com
            com = choises[Math.floor(Math.random()*choises.length)]
        choises = game.progress com
        cn[choises.length] += 1
        if choises[0].type == 'INIT_KYOKU'
            kyoku++
            game.haifu = []
catch e
    haifu = game.record.haifu
    game.record = undefined
    puts game
    puts haifu.slice(haifu.length-3)
    throw e

puts kyoku
puts count/kyoku
puts cn
puts agari
