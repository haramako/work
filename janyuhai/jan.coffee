janutil = require './janutil'

###
# 牌の種類（筒子、萬子、索子、字牌)を表すEnum.
###
PaiSuit = new janutil.Enum(['MANZU','PINZU','SOUZU','JIHAI'])

###
# 牌の種類（一萬、二萬・・・発、中）を表すEnum.
#
# # 牌の種類を取得する
# PaiKind.kind( PaiKind.MAN1 ) # => PaiKind.MANZU
#
# # 牌を読みやすい文字列と変換する
# PaiKind.fromReadable( '一①１東' ) # => [ PaiKind.MAN1, PaiKind.PIN1, PaiKind.SOU1, PaiKind.TON ]
# PaiKind.toReadable( [ PaiKind.MAN1, PaiKind.PIN1, PaiKind.SOU1, PaiKind.TON ] ) # =>'一①１東' )
#
# # fromReadable()/toReadable()は、配列や' 'で区切った文字列を分けて処理できる
# PaiKind.fromReadable( '一① １東' ) # => [ [PaiKind.MAN1, PaiKind.PIN1], [PaiKind.SOU1, PaiKind.TON] ] (配列の配列として返される)
# PaiKind.fromReadable( ['一①','１東'] ) # => [ [PaiKind.MAN1, PaiKind.PIN1], [PaiKind.SOU1, PaiKind.TON] ]
# PaiKind.toReadable( [ [PaiKind.MAN1, PaiKind.PIN1], [PaiKind.SOU1, PaiKind.TON] ] ) # => ['一①','１東']
#
###
PaiKind = new janutil.Enum([
        'MAN1','MAN2','MAN3','MAN4','MAN5','MAN6','MAN7','MAN8','MAN9',
        'PIN1','PIN2','PIN3','PIN4','PIN5','PIN6','PIN7','PIN8','PIN9',
        'SOU1','SOU2','SOU3','SOU4','SOU5','SOU6','SOU7','SOU8','SOU9',
        'TON', 'NAN', 'SHA', 'PEI', 'HAKU', 'HATSU', 'CHUN' ] ).exportTo( exports )

# Readableな文字列の対応表
PaiKind._strings = [
    '一','二','三','四','五','六','七','八','九',
    '①','②','③','④','⑤','⑥','⑦','⑧','⑨',
    '１','２','３','４','５','６','７','８','９',
    '東','南','西','北','白','発','中' ]

PaiKind.toSuit = (pk)->
    if pk >= PaiKind.MAN1 and pk <= PaiKind.MAN9
        PaiSuit.MANZU
    else if pk >= PaiKind.PIN1 and pk <= PaiKind.PIN9
        PaiSuit.PINZU
    else if pk >= PaiKind.SOU1 and pk <= PaiKind.SOU9
        PaiSuit.SOUZU
    else
        PaiSuit.JIHAI

PaiKind.toReadable = (num)->
    if typeof num == 'number'
        @_strings[num]
    else if num.map
        num.map( (n)-> PaiKind.toReadable(n) ).join('')
    else
        throw "argument error in PaiKind.toReadable(), argument = #{num}"

PaiKind.fromReadable = (str)->
    if typeof str == 'string'
        if str.indexOf(' ') >= 0
            PaiKind.fromReadable( str.split(' ') )
        else
            result = []
            for s in str
                for i in [0...@_strings.length]
                    if s == @_strings[i]
                        result.push i
                        break
            result
    else if str.map
        result = str.map (s)-> PaiKind.fromReadable(s)
    else
        throw "argument error in PaiKind.fromReadable(), argument = #{str}"

# 順子の開始となるかどうかの連想配列（つまり数牌で７以下かどうか)
PaiKind._shuntsuStarter = {}
for n in PaiKind.fromReadable('一二三四五六七１２３４５６７①②③④⑤⑥⑦')
    PaiKind._shuntsuStarter[n] = true

###
# 牌の個数分布(pai-table)に変換する.
#
# PaiKind.toPaiTable( [PaiKind.MAN1, PaiKind.MAN2, PaiKind.MAN2] ) # => [1,2,0,0,....]
# 引数は、PaiKindの配列
# 返り値は、インデックスがPaiKindで値がその牌の個数を表すような配列で、長さはPaiKind.MAXとなる。
###
PaiKind.toPaiTable = (pis)->
    result = []
    result[i] = 0 for i in [0...PaiKind.MAX]
    for pi in pis
        result[pi]++
    result

###
#
###

###
# メンツに分ける.
#
# 面子で分解したときの候補すべてを返す
#
# splitMentsu( PaiKind.fromReadable('１１１２３４４４') )
# # => [
# #  [ [ 18, 18, 18 ], [ 19, 20, 21 ], [ 21, 21 ] ], # 一つの要素が分割のパターンひとつ、この場合は２パターンの分け方がある
# #  [ [ 18, 18 ], [ 18, 19, 20 ], [ 21, 21, 21 ] ]
# # ]
#
###
splitMentsu = (pks,opt)->
    allMentsu = []
    callNum = 0
    num = pks.length
    curMentsu = []
    paiTable = PaiKind.toPaiTable(pks)
    toitsuNum = 0
    # 再帰しながら面子を分解する関数
    split = (pkCur, withoutKoutsu)->
        callNum += 1
        # 終了判定
        if num <= 0 and toitsuNum == 1
            allMentsu.push curMentsu.slice()
            return
        return if pkCur >= PaiKind.MAX # 終了判定
        # 牌がなかったら次へ
        if paiTable[pkCur] == 0
            split( pkCur+1 )
            return
        # コーツの判定をする
        if not withoutKoutsu and paiTable[pkCur] >= 3
            paiTable[pkCur] -= 3
            num -= 3
            curMentsu.push [ pkCur, pkCur, pkCur ]
            split pkCur, false
            curMentsu.pop()
            num += 3
            paiTable[pkCur] += 3
        # 対子の判定をする
        if not withoutKoutsu and toitsuNum <= 0 and paiTable[pkCur] >= 2
            paiTable[pkCur] -= 2
            toitsuNum += 1
            num -= 2
            curMentsu.push [ pkCur, pkCur ]
            split pkCur, false
            curMentsu.pop()
            num += 2
            toitsuNum -= 1
            paiTable[pkCur] += 2
        # 順子の判定をする
        if PaiKind._shuntsuStarter[pkCur] and # 順子はじまりの牌
        paiTable[pkCur] >= 1 and paiTable[pkCur+1] >=1 and paiTable[pkCur+2] >=1
            paiTable[pkCur  ] -= 1
            paiTable[pkCur+1] -= 1
            paiTable[pkCur+2] -= 1
            num -= 3
            curMentsu.push [pkCur, pkCur+1, pkCur+2]
            split pkCur, true
            curMentsu.pop()
            num += 3
            paiTable[pkCur  ] += 1
            paiTable[pkCur+1] += 1
            paiTable[pkCur+2] += 1
    split 0
    # puts callNum
    allMentsu

###
# 面子をひとつ表すオブジェクト.
#
# type: 'toitsu', 'koutsu', 'kantsu', 'shuntsu'のいずれかの文字列
# from: 構成する牌のうち、一番数がすくないPaiKind（１２３の場合１となる）
# furo: 副露されているうかどうか（暗槓は連外的にfuro=falseとなる）
###
class Mentsu
    constructor: (type,from,furo=false)->
        @type = type
        @from = from
        @furo = furo

    ###
    # PaiKindの配列からMentsuを生成する.
    #
    # PaiKindの配列の配列などにも対応し、その場合は引数の配列の構造を維持する
    #
    # Mentsu.fromArray( [jan.MAN1, jan.MAN2, jan.MAN3] ) # => new Mentsu( 'shuntsu', jan.MAN1, false )と同等のオブジェクト
    # @param src PaiKindの配列（もしくは配列の配列、配列の配列の...）
    # @param furo 副露状態かどうか
    # @return Mentsuオブジェクトの配列（もしくは配列の配列、配列の配列の...）
    ###
    @fromArray: (src,furo=false)->
        if typeof src[0] == 'number'
            if src.length == 2 and src[0] == src[1]
                return new Mentsu( 'toitsu', src[0],furo )
            else if src.length == 3 and src[0] == src[1] and src[0] == src[2]
                return new Mentsu( 'koutsu', src[0],furo )
            else if src.length == 4 and src[0] == src[1] and src[0] == src[2] and src[0] == src[3]
                return new Mentsu( 'kantsu', src[0],furo )
            else if src.length == 3 and PaiKind._shuntsuStarter[src[0]] and src[0] == src[1]-1 and src[0] == src[2]-2
                return new Mentsu( 'shuntsu', src[0],furo)
            else
                throw "argument error in Mentsu.fromArray(), src=#{src}"
        else
            return src.map (x)->Mentsu.fromArray(x,furo)

    ###
    # 文字列に変換する
    ###
    toString: ->
        str = switch @type
            when 'toitsu'
                PaiKind.toReadable( [@from, @from] )
            when 'koutsu'
                PaiKind.toReadable( [@from, @from, @from] )
            when 'kantsu'
                PaiKind.toReadable( [@from, @from, @from, @from] )
            when 'shuntsu'
                PaiKind.toReadable( [@from, @from+1, @from+2] )
            else
                throw 'invalid type'
        if @furo
            "[#{str}]"
        else if @type == 'kantsu'
            "(#{str})" # 暗槓は()
        else
            str

# 役のリスト
# [ID, 表示名, 門前の飜数]の配列（飜数は13=役満、26=ダブル役満)
# 順序を守るために配列にしている
YAKU_TABLE = [
    ['PINFU'     , '平和'      , 1 ],
    ['TANYAO'    , 'タンヤオ'  , 1 ],
    ['IIPEIKOU'  , '一盃口'    , 1 ],
    ['REACH'     , 'リーチ'    , 1 ],
    ['IPPATSU'   , '一発'      , 1 ],
    ['TSUMO'     , '自摸'      , 1 ],
    ['YAKUHAI'   , '役牌'      , 1 ],
    ['HAITEI'    , '海底'      , 1 ],
    ['HOUTEI'    , '河底'      , 1 ],
    ['RINSHAN'   , '嶺上'      , 1 ],
    ['CHANKAN'   , '搶槓'      , 1 ],
    ['DOUBLE_REACH', 'ダブルリーチ', 2 ],
    ['CHITOITSU' , '七対子'    , 2 ],
    ['CHANTA'    , '全帯幺'    , 2 ],
    ['ITTSU'     , '一気通貫'  , 2 ],
    ['SANSHOKU'  , '三色同順'  , 2 ],
    ['SANSHOKU_DOUKOU', '三色同刻', 2 ],
    ['TOITOI'    , '対々和'    , 2 ],
    ['SANANKO'   , '三暗刻'    , 2 ],
    ['SANKANTSU' , '三槓子'    , 3 ],
    ['RYANPEIKOU', '二盃口'    , 3 ],
    ['HONITSU'   , '混一色'    , 3 ],
    ['JUNCHAN'   , '純全帯幺'  , 3 ],
    ['SHOUSANGEN', '小三元'    , 4 ],
    ['HONROUTOU' , '混老頭'    , 4 ],
    ['RENHOU'    , '人和'      , 4 ],
    ['CHINITSU'  , '清一色'    , 6 ],
    ['SUUANKOU'  , '四暗刻'    , 13 ],
    ['SUUKANTSU' , '四槓子'    , 13 ],
    ['KOKUSHI'   , '国士無双'  , 13 ],
    ['TENHOU'    , '天和'      , 13 ],
    ['CHIHOU'    , '地和'      , 13 ],
    ['SHOUSUUSHII', '小四喜'   , 13 ],
    ['DAISUUSHII', '大四喜'    , 13 ],
    ['CHINROUTOU', '清老頭'    , 13 ],
    ['RYUUIISOU' , '緑一色'    , 13 ],
    ['CHUUREN'   , '九蓮宝燈'  , 13 ],
    ['SUUANKOU_TANKI', '四暗刻単騎', 13 ],
    ['KOKUSHI_13MEN', '国士無双１３面待ち', 13 ],
    ['JUNSEI_CHUUREN', '純正九蓮宝燈', 13 ]
]

Yaku = new janutil.Enum( YAKU_TABLE.map( (y)->y[0] ) )
Yaku.info = (yaku)->
    info = YAKU_TABLE[yaku]
    { num: yaku, id: info[0], name: info[1], han: info[2] }

# console.log PaiKind
#console.log PaiKind.kind( 10 )
#puts toPaiTable([0,1,2,3,3])

exports.PaiSuit = PaiSuit
exports.PaiKind = PaiKind
exports.Mentsu = Mentsu
exports.Yaku = Yaku
exports.splitMentsu = splitMentsu
