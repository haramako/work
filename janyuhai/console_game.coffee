#!/usr/env coffee
game = require './game'
jan = require './jan'
janutil = require './janutil'
fs = require 'fs'
optparse = require 'optparse'
_ = require 'underscore'

PaiId = jan.PaiId
PaiKind = jan.PaiKind

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

# 牌譜/チート ファイルの読み込み
if paths.length == 1
    if paths[0].match(/\.cheat$/)
        haifu = game.Game.makeCheatHaifu( JSON.parse( fs.readFileSync(paths[0],'utf-8')) )
    else
        haifu = JSON.parse( fs.readFileSync(paths[0],'utf-8'))
else if paths.length > 1
    puts 'haifu file must be specified only one'
    process.exit 1

# ゲームの初期化
g = new game.Game( [], {playerNum:4} )
if haifu
    for com in haifu.haifu
        g.progress com

printG = (g)->
    puts '================================================'
    puts "#{PaiKind.toReadable(g.bakaze)}#{g.kyoku+1}局 #{g.honba}本場 ドラ:#{PaiKind.toReadable(g.pkDora)} 残り#{g.restPai()}枚 供託:#{g.kyotaku}点"
    for player,pl in g.p
        kawaStr = player.piKawahai.map (pi,i)->
            str = jan.PaiKind.toReadable( jan.PaiId.toKind(pi) )
            if player.kawahaiState[i] == game.KawaState.REACH
                '<'+str+'>'
            else if player.kawahaiState[i] == game.KawaState.NAKI
                '('+str+')'
            else
                str
        puts "プレイヤー#{pl}: #{PaiKind.toReadable(player.jikaze)} #{player.score}点"
        puts "       手牌: #{PaiKind.toReadable( PaiId.toKind(player.s.piTehai) )} #{player.furo}"
        puts "         河: #{kawaStr.join('')}"
    puts '----------------------'
    for c,i in g.choises
        puts "#{i}:",c

printG g

unless batch
    process.stdout.write '[0-0]> '
    process.stdin.resume()
    process.stdin.setEncoding('utf-8')
    process.stdin.on 'data', (data)->
        # 選択した
        num = parseInt(data,10)
        if num >= 0 and num < g.choises.length
            g.progress g.choises[num]
            puts '牌譜:', janutil.prettyPrintJson(g.record.haifu[g.record.haifu.length-1])
            # 選択肢がないならそのまますすめる
            while g.choises.length == 1
                g.progress g.choises[0]
                puts '牌譜:', janutil.prettyPrintJson(g.record.haifu[g.record.haifu.length-1])

            printG g
            process.stdout.write "[0-#{g.choises.length-1}]> "
        else
            puts 'ERROR: invalid index'
            process.stdout.write "[0-#{g.choises.length-1}]> "

    process.stdin.on 'end', ->
        puts '================================================'
        puts '牌譜'
        puts '================================================'
        puts janutil.prettyPrintJson( g.record ) if record
else
    puts '================================================'
    puts '牌譜'
    puts '================================================'
    puts janutil.prettyPrintJson( g.record ) if record

