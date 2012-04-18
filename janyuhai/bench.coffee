#!/usr/env coffee
_ = require 'underscore'
game = require './game'
jan = require './jan'

game = new game.Game( [], {playerNum:4} )
game.progress {type:'BAGIME', pub:[0,1,2,3]}
game.progress {type:'INIT_KYOKU', sec:{ piYama: [0...136] }}
choises = game.progress {type:'WAREME_DICE', pub:[1,1] }

kyoku = 0
agari = 0
cn = (0 for i in [0..30])
try
    for i in [0...100*8*30000/60/15]
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
    puts game.p
    puts game.haifu.slice(game.haifu.length-3)
    throw e

puts kyoku
puts cn
puts agari
