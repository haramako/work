# nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
    eval('var exports, global; exports = {}; window.game = exports; global = window;')

fs = require 'fs'
msgpack = require 'msgpack2'
_ = require 'underscore'
zlib = require 'zlib'

# 牌譜パックなどを行う
# 古いバージョンの情報などが溜まっていく可能性があるため、別のモジュールに分離している

# 牌譜JSONをパックする
# @param haifu 牌譜オブジェクト(jsonオブジェクト)
# @return パックされたhaifuオブジェクト(jsonオブジェクト)
packJson = (haifu)->
    result = _.clone(haifu)
    h = result.haifu
    # 一部のコマンドだけ数値の配列に置き換える
    h = h.map (com)->
        switch com.type
            when 'DAHAI'
                [0,com.pl,com.pub.pi]
            when 'TSUMO'
                [1,com.pl,com.sec]
            else
                com
    for com,i in h
        if h[i].length and h[i+1].length
            h[i+1] = h[i].concat(h[i+1])
            h[i] = null
    h = _.without( h, null )
    result.pack = '1000' # パックのバージョンを追加
    result.haifu = h
    result

# 牌譜JSONをアンパックする
unpackJson = (haifu)->
    result = _.clone(haifu)
    h = result.haifu
    # 一部のコマンドだけ数値の配列に置き換える
    h = h.map (com)->
        if com.length
            r = []
            i = 0
            while i < com.length
                if com[i] == 0
                    r.push {type:'DAHAI',pl:com[i+1],pub:{pi:com[i+2]}}
                    i += 3
                else if com[i]== 1
                    r.push {type:'TSUMO',pl:com[i+1],sec:com[i+2]}
                    i += 3
                else
                    throw 'error'
            r
        else
            com
    h = _.flatten( h, 1 )
    delete result.pack
    result.haifu = h
    result

# 牌譜の種類を自動判別してパックする
pack = (haifu, callback)->
    if haifu[0] == 0x1f and haifu[1] == 0x8b
        callback( 0, haifu )
    else
        haifu = packJson( haifu )
        zlib.gzip msgpack.pack(haifu), callback

# 牌譜の種類を自動判別してアンパックする
unpack = (haifu, callback)->
    unless haifu[0] == 0x1f and haifu[1] == 0x8b
        callback 0, JSON.parse( haifu )
    else
        zlib.gunzip haifu, (err,data)->
            haifu = unpackJson( msgpack.unpack(data) )
            callback 0, haifu

exports.pack = pack
exports.unpack = unpack