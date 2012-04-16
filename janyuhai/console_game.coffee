#!/usr/env coffee
game = require './game'
jan = require './jan'
janutiil = require './janutil'
fs = require 'fs'
optparse = require 'optparse'
_ = require 'underscore'

# コマンドライン引数の解析
opt = new optparse.OptionParser([
    ['-h','--help','show this messsage']
])
opt.banner = 'Usage: coffee console_game.coffee [Options] haifu.json, [haifu2.json ...]'
opt.on 'help', ->
    console.log opt.toString()
    process.exit 0

paths = opt.parse( process.argv.slice(2) )

# 牌譜ファイルの読み込み
if paths.length == 1
    haifu = JSON.parse( fs.readFileSync(paths[0],'utf-8'))
else if paths.length > 1
    puts 'haifu file must be specified only one'
    process.exit 1

game = new game.Game( [], {playerNum:4} )
if haifu
    for com in haifu
        game.progress com
else
    game.progress {type:'BAGIME_SELECT', pub:[0,1,2,3]}
    game.progress {type:'INIT_KYOKU', sec:{ piYama: [0...136] }}
    game.progress {type:'WAREME_DICE', pub:[1,1] }

choises = game.choises

printGame = (game)->
    puts '================================================'
    for player,pl in game.p
        puts "PLAYER#{pl}: #{jan.PaiKind.toReadable( jan.PaiId.toKind(player.s.piTehai) )} #{player.furo}"
    puts '----------------------'
    for c,i in game.choises
        puts "#{i}:",c

printGame game

process.stdout.write '[0-0]> '
process.stdin.resume()
process.stdin.setEncoding('utf-8')
process.stdin.on 'data', (data)->
    # 選択した
    num = parseInt(data,10)
    if num >= 0 and num < game.choises.length
        puts '*', game.choises[num]
        game.progress game.choises[num]
        # 選択肢がないならそのまますすめる
        while game.choises.length == 1
            puts '*', game.choises[0]
            game.progress game.choises[0]

        printGame game
        process.stdout.write "[0-#{game.choises.length-1}]> "
    else
        puts 'ERROR: invalid index'
        process.stdout.write "[0-#{game.choises.length-1}]> "

process.stdin.on 'end', ->
    puts "\n[\n"+game.haifu.map( (com)->JSON.stringify(com) ).join(",\n")+"\n]"


