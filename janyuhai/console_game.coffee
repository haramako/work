#!/usr/env coffee
game = require './game'
jan = require './jan'
janutil = require './janutil'
fs = require 'fs'
optparse = require 'optparse'
_ = require 'underscore'

# コマンドライン引数の解析
batch = record = false
opt = new optparse.OptionParser([
    ['-h','--help','show this messsage']
    ['-b','--batch','batch mode']
    ['-r','--record','output haifu json finally']
])
opt.banner = 'Usage: coffee console_game.coffee [Options] haifu.json, [haifu2.json ...]'
opt.on 'help', ->
    console.log opt.toString()
    process.exit 0
opt.on 'batch', -> batch = true
opt.on 'record', -> record = true

paths = opt.parse( process.argv.slice(2) )

# 牌譜ファイルの読み込み
if paths.length == 1
    if paths[0].split(/\.cheat$/)
        haifu = game.Game.makeCheatHaifu( JSON.parse( fs.readFileSync(paths[0],'utf-8')) )
    else
        haifu = JSON.parse( fs.readFileSync(paths[0],'utf-8'))
else if paths.length > 1
    puts 'haifu file must be specified only one'
    process.exit 1

game = new game.Game( [], {playerNum:4} )
if haifu
    for com in haifu.haifu
        game.progress com
else
    game.progress {type:'BAGIME', pub:[0,1,2,3]}
    game.progress {type:'INIT_KYOKU', sec:{ piYama: [0...136] }, pub:{kyoku:0,bakaze:jan.PaiId.TON,kyotaku:0,score:[25000,25000,25000,25000]}}
    game.progress {type:'WAREME_DICE', pub:{dice:[1,1]} }

choises = game.choises

printGame = (game)->
    puts '================================================'
    puts "#{jan.PaiKind.toReadable(game.bakaze)}#{game.kyoku+1}局 #{game.honba}本場 ドラ:#{jan.PaiKind.toReadable(game.pkDora)} 残り#{game.restPai()}枚"
    for player,pl in game.p
        puts "プレイヤー#{pl}: #{jan.PaiKind.toReadable( jan.PaiId.toKind(player.s.piTehai) )} #{player.furo}"
        puts "         河> #{jan.PaiKind.toReadable( jan.PaiId.toKind(player.piKawahai) )}"
    puts '----------------------'
    for c,i in game.choises
        puts "#{i}:",c

printGame game

unless batch
    process.stdout.write '[0-0]> '
    process.stdin.resume()
    process.stdin.setEncoding('utf-8')
    process.stdin.on 'data', (data)->
        # 選択した
        num = parseInt(data,10)
        if num >= 0 and num < game.choises.length
            game.progress game.choises[num]
            puts '*', game.record.haifu[game.record.haifu.length-1]
            # 選択肢がないならそのまますすめる
            while game.choises.length == 1
                puts '*', game.record.haifu[game.record.haifu.length-1]
                game.progress game.choises[0]

            printGame game
            process.stdout.write "[0-#{game.choises.length-1}]> "
        else
            puts 'ERROR: invalid index'
            process.stdout.write "[0-#{game.choises.length-1}]> "

    process.stdin.on 'end', ->
        puts janutil.prettyPrintJson( game.record ) if record
else
    puts janutil.prettyPrintJson( game.record ) if record

