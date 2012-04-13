jan = require './jan'
janutil = require './janutil'
libxmljs = require 'libxmljs'
fs = require 'fs'
zlib = require 'zlib'

#  1:TSUMO
#  2:IPPATSU
#  7:PINFU
#  8:TANYAO
#  9:IIPEIKO
# 10-18:YAKUHAI
# 25:SANSHOKU
# 28:TOITOI
# 52:DORA
# 53:REACH
# 54:AKADORA

class Haifu
    constructor: (xml)->
        @kyoku = []
        dom = libxmljs.parseXmlString( xml )
        for node in dom.root().childNodes()
            switch node.name()
             # 曲の開始
             when 'INIT'
                oya = parseInt(node.attr('oya').value(),10)
                reachFlag = []
             # リーチ
             when 'REACH'
                if node.attr('step').value() == '2'
                    reachFlag[parseInt(node.attr('who').value(),10)] = true
             # 和了
             when 'AGARI'
                piTehai = node.attr('hai').value().split(',').map (s)->parseInt(s,10)
                if node.attr('m')
                    mentsu = node.attr('m').value().split(',').map (s)->Haifu.parseNTag(s)
                else
                    mentsu = []
                pkMachi = jan.PaiId.toKind( parseInt( node.attr('machi').value(), 10 ) )
                yakuStr = node.attr('yaku').value()
                ippatsu = (node.attr('yaku').value().indexOf(',2,1,')>=0) # 一発
                ba = node.attr('ba').value().split(',').map (s)->parseInt(s,10)
                ten = node.attr('ten').value().split(',').map (s)->parseInt(s,10)
                fu = ten[0]
                score = ten[1]
                pkDora = jan.PaiId.toKind( node.attr('doraHai').value().split(',').map( (s)->parseInt(s,10) ) ).map( (pk)->jan.PaiKind.next(pk) )
                uradora = node.attr('doraHaiUra')
                pkUradora = if uradora then jan.PaiId.toKind( uradora.value().split(',').map( (s)->parseInt(s,10) ) ).map( (pk)->jan.PaiKind.next(pk) ) else []
                who = parseInt( node.attr('who').value(), 10 )
                fromWho = parseInt( node.attr('fromWho').value(), 10 )
                @kyoku.push {
                    piTehai:piTehai, mentsu:mentsu, pkMachi:pkMachi, fu:fu, score:score,
                    pkDora:pkDora, pkUradora:pkUradora, tsumo: who == fromWho,
                    oya: who == oya, reach: reachFlag[who] == true, ippatsu: ippatsu,
                    pkBakaze: jan.TON, pkJikaze: jan.TON+(4-oya+who)%4, yakuStr: yakuStr
                }

    @parseNTag: (n)->
        shuntsu = Math.floor( n % 8 / 4 )
        if shuntsu == 1
            hai = Math.floor( Math.floor( n / 1024 ) / 3 )
            hai = Math.floor( hai / 7 ) * 9 + hai % 7
            return new jan.Mentsu( 'shuntsu', hai, true )
        else
            hai = Math.floor( Math.floor( n / 512 ) / 3 )
            return new jan.Mentsu( 'koutsu', hai, true )

readHaifu = (file,func)->
    zlib.gunzip fs.readFileSync(file), (err,data)->
        func( err, new Haifu( data.toString() ) )

#haifu = new Haifu( fs.readFileSync( 'hoge.xml' ) )
#[ puts( h ) for h in haifu.kyoku ]

exports.Haifu = Haifu
exports.readHaifu = readHaifu