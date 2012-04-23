jan = require './jan'
libxmljs = require 'libxmljs'
fs = require 'fs'
zlib = require 'zlib'

# 天鳳の役番号
#  1:TSUMO
#  2:IPPATSU
#  4:RINSHAN
#  5:HAITEI
#  6:HOUTEI
#  7:PINFU
#  8:TANYAO
#  9:IIPEIKO
# 10-18:YAKUHAI
# 21:DOUBLE_REACH
# 25:SANSHOKU
# 28:TOITOI
# 52:DORA
# 53:REACH
# 54:AKADORA

# 参考URL: http://kmo2.cocolog-nifty.com/prog/2011/09/post-d8e6.html 「天鳳の牌譜の面子表記」

class Haifu
    constructor: (xml)->
        @kyoku = []
        dom = libxmljs.parseXmlString( xml )
        bakaze = 0
        oya = 0
        for node in dom.root().childNodes()
            switch node.name()
             # 局の開始
             when 'INIT'
                oldOya = oya
                oya = parseInt(node.attr('oya').value(),10)
                bakaze++ if oya == 0 and oldOya != 0
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
                if node.attr('yaku')
                    yaku = node.attr('yaku').value().split(',').map (s)->parseInt(s,10)
                    yakuStr = node.attr('yaku').value()
                    ippatsu = (node.attr('yaku').value().indexOf(',2,1,')>=0) # 一発
                    doubleReach = (node.attr('yaku').value().indexOf('21,2,')>=0) # ダブリー
                    houtei = rinshan = haitei = false
                    for i in [0...yaku.length/2]
                        rinshan = true if yaku[i*2] == 4 # 嶺上開花
                        haitei  = true if yaku[i*2] == 5 # 海底撈月
                        houtei  = true if yaku[i*2] == 6 # 河底

                else if node.attr('yakuman')
                    0
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
                    oya: who == oya,
                    reach: reachFlag[who] == true, doubleReach: doubleReach, ippatsu: ippatsu,
                    rinshan: rinshan, houtei: houtei, haitei: haitei,
                    pkBakaze: jan.TON+bakaze, pkJikaze: jan.TON+(4-oya+who)%4, yakuStr: yakuStr
                }

    @parseNTag: (n)->
        shuntsu = Math.floor( n % 8 / 4 )
        koutsu = Math.floor( n / 8 ) % 2
        kakan = Math.floor( n / 16 ) % 2
        nuki = Math.floor( n / 32 ) % 2
        if shuntsu == 1
            hai = Math.floor( Math.floor( n / 1024 ) / 3 )
            pk = Math.floor( hai / 7 ) * 9 + hai % 7
            idx0 = Math.floor( n /   8 ) % 4
            idx1 = Math.floor( n /  32 ) % 4
            idx2 = Math.floor( n / 128 ) % 4
            new jan.Mentsu( [jan.PaiId.fromKind(pk,idx0), jan.PaiId.fromKind(pk+1,idx1), jan.PaiId.fromKind(pk+2,idx2)], 1 )
        else if koutsu == 1
            pk = Math.floor( Math.floor( n / 512 ) / 3 )
            restIdx = Math.floor( n / 32 ) % 4 # 余り牌のインデックス
            if restIdx == 0
                new jan.Mentsu( [jan.PaiId.fromKind(pk,1), jan.PaiId.fromKind(pk,2), jan.PaiId.fromKind(pk,3)], 1 )
            else
                new jan.Mentsu( [jan.PaiId.fromKind(pk,0), jan.PaiId.fromKind(pk,1), jan.PaiId.fromKind(pk,2)], 1 )
        else if kakan == 1
            pk = Math.floor( Math.floor( n / 512 ) / 3 )
            new jan.Mentsu( [jan.PaiId.fromKind(pk,0), jan.PaiId.fromKind(pk,1), jan.PaiId.fromKind(pk,2), jan.PaiId.fromKind(pk,3)], 1 )
        else if nuki == 1
            puts 'nuki'
        else
            pi = Math.floor( n / 256 )
            pk = jan.PaiId.toKind(pi)
            dir = n % 4
            new jan.Mentsu( [jan.PaiId.fromKind(pk,0), jan.PaiId.fromKind(pk,1), jan.PaiId.fromKind(pk,2), jan.PaiId.fromKind(pk,3)], dir )

readHaifu = (file,func)->
    zlib.gunzip fs.readFileSync(file), (err,data)->
        func( err, new Haifu( data.toString() ) )

#haifu = new Haifu( fs.readFileSync( 'hoge.xml' ) )
#[ puts( h ) for h in haifu.kyoku ]

exports.Haifu = Haifu
exports.readHaifu = readHaifu