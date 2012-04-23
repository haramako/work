#!/usr/env coffee
_ = require 'underscore'
game = require './game'
jan = require './jan'


HANCHAN_NUM = 18
agari = 0
cn = (0 for i in [0..30])
total = 0
console.time 'all'
try
    for i in [0...HANCHAN_NUM]
        g = new game.Game( game.GameMode.MASTER, [], {playerNum:4} )
        while g.state != 'FINISHED'
            com = _.find( g.choises, (c)->c.type == 'RON' or c.type == 'TSUMO_AGARI' )
            if com
                agari++
            unless com
                com = g.choises[Math.floor(Math.random()*g.choises.length)]
            g.progress com
            cn[g.choises.length] += 1
            total++
catch e
    # エラーが起きたら詳細を表示
    haifu = g.record.haifu
    g.record = undefined
    puts g
    puts haifu.slice(haifu.length-3)
    throw e

console.timeEnd 'all'

puts "total=#{total}"
puts "HANCHAN_NUM=#{HANCHAN_NUM}"
puts "choise num freq=#{cn}"
puts "agari=#{agari}"
