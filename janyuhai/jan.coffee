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

# インデックスの配列から、そのインデックスが含まれているかを判定する配列に変換する
# makeTable([1,4]) => [false,true,false,false,true] （[1]と[4]がtrueになる配列にする）
makeTable = (array)->
    result = []
    for i in array
        result[i] = true
    result

# 順子の開始となるかどうかの連想配列（つまり数牌で７以下かどうか)
SHUNTSU_STARTER_TABLE = makeTable( PaiKind.fromReadable('一二三四五六七①②③④⑤⑥⑦１２３４５６７') )
PaiKind.isShuntsuStarter = (pk)-> SHUNTSU_STARTER_TABLE[pk]

YAOCHU_TABLE = makeTable( PaiKind.fromReadable('一九１９①⑨東南西北白発中') )
PaiKind.isYaochu = (pk)->YAOCHU_TABLE[pk]

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

# PaiIdを初期化するためのリスト
PAI_ID_LIST = []
for pk in [0...PaiKind.MAX]
    for i in [0..3]
        PAI_ID_LIST.push "#{PaiKind.toString(pk)}_#{i}=#{pk*4+i}"

###
# 牌のひとつひとつまで識別するIDを表すEnum.
# 一種類の牌は、４つあるが、それぞれ MAN1_0, MAN1_1, MAN1_2, MAN1_3 として別に識別される。
# 主に、牌の同一性のためや、赤牌の識別などに利用される
#
#
###
PaiId = new janutil.Enum(PAI_ID_LIST)
PaiId.toKind = (pi)->
    if typeof pi == 'number'
        Math.floor( pi / 4 )
    else if pi.map
        pi.map (n)-> PaiId.toKind(n)
    else
        throw "argument error in PaiId.toKind(), pi=#{pi}"
PaiId.toIndex = (pi)-> pk % 4

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
        if PaiKind.isShuntsuStarter(pkCur) and # 順子はじまりの牌
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
    constructor: (type,pkFrom,furo=false)->
        @type = type
        @pkFrom = pkFrom
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
            else if src.length == 3 and PaiKind.isShuntsuStarter(src[0]) and src[0] == src[1]-1 and src[0] == src[2]-2
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
                PaiKind.toReadable( [@pkFrom, @pkFrom] )
            when 'koutsu'
                PaiKind.toReadable( [@pkFrom, @pkFrom, @pkFrom] )
            when 'kantsu'
                PaiKind.toReadable( [@pkFrom, @pkFrom, @pkFrom, @pkFrom] )
            when 'shuntsu'
                PaiKind.toReadable( [@pkFrom, @pkFrom+1, @pkFrom+2] )
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
    ['DORA'      , 'ドラ'      , 1 ],
    ['URADORA'   , '裏ドラ'      , 1 ],
    ['AKADORA'   , '赤ドラ'      , 1 ],
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
    ['DAISANGEN' , '大三元'    , 13 ],
    ['SHOUSUUSHII', '小四喜'   , 13 ],
    ['DAISUUSHII', '大四喜'    , 13 ],
    ['CHINROUTOU', '清老頭'    , 13 ],
    ['RYUUIISOU' , '緑一色'    , 13 ],
    ['TSUIISOU'  , '字一色'    , 13 ],
    ['CHUUREN'   , '九蓮宝燈'  , 13 ],
    ['SUUANKOU_TANKI', '四暗刻単騎', 13 ],
    ['KOKUSHI_13MEN', '国士無双１３面待ち', 13 ],
    ['JUNSEI_CHUUREN', '純正九蓮宝燈', 13 ]
]

###
# 役を表すEnum.
###
Yaku = new janutil.Enum( YAKU_TABLE.map( (y)->y[0] ) )
Yaku.info = (yaku)->
    info = YAKU_TABLE[yaku]
    { num: yaku, id: info[0], name: info[1], han: info[2] }


###
# 役の判定を行う.
#
# ここで判定しない役は、門前自摸、リーチ、ドラ、海底、河底、嶺上、搶槓。これらは、外部で判定する
#
# optには下記を指定する
#   dora: ドラの数
#   akadora: 赤ドラの数
#   uradora: 裏ドラの数
#   pkLast:最後にツモった牌
#   tsumo: 自摸かどうかの真偽値
#   bakaze: 場風（PaiKind.TON/NANのいずれか)
#   jikaze: 自風（PaiKind.TON/NAN/SHA/PEIのいずれか）
#
# @param pkTehai 手牌を表すPaiKindの配列
# @param furo 副露牌を表すMensuの配列
# @param opt その他のオプション
# @return 役や飜数を表すオブジェクト
###
calcYaku = (pkTehai,furo,opt={})->
    # チェック項目
    #  両面、単騎などの判定
    #  符の計算
    # 手牌を分解
    tehaiMentsuList = Mentsu.fromArray( splitMentsu( pkTehai ), false )
    if tehaiMentsuList.length == 0
        throw "invalid arguments in calcYaku(), pkTehai=#{pkTehai}"
    result = []
    for mentsu in tehaiMentsuList
        # 各順子などの数をカウント
        fu = 20
        menzen = ( furo.length == 0 ) # 門前かどうか
        ryanmen = false # 両面待ちにできるかどうか
        tanki = false
        kanchan = false
        penchan = false
        shuntsuNum = 0
        koutsuNum = 0
        shuntsuMenzenNum = 0
        koutsuMenzenNum = 0
        mentsuAll = mentsu.concat( furo )
        for m in mentsuAll
            switch m.type
                when 'toitsu'
                    tanki = true if m.pkFrom == opt.pkLast
                when 'shuntsu'
                    shuntsuNum++
                    shuntsuMenzenNum++ if not m.furo
                    kanchan = true if m.pkFrom+1 == opt.pkLast
                    kanchan = true if m.pkFrom+1 == opt.pkLast
                    if m.pkFrom == opt.pkLast or m.pkFrom+2 == opt.pkLast
                        if PaiKind.isYaochu(opt.pkLast)
                            ryanmen = true
                        else if PaiKind.isYaochu(m.pkFrom) or PaiKind.isYaochu(m.pkFrom+2)
                            penchan = true

                when 'koutsu', 'kantsu'
                    koutsuNum++
                    koutsuMenzenNum++ if not m.furo
                    if m.type == 'koutsu'
                        if PaiKind.isYaochu(m.pkFrom)
                            fu += if m.furo then 4 else 8
                        else
                            fu += if m.furo then 2 else 4
                    else
                        if PaiKind.isYaochu(m.pkFrom)
                            fu += if m.furo then 8 else 16
                        else
                            fu += if m.furo then 4 else 8

        # puts "ryanme=#{ryanmen}, kanchan=#{kanchan}, penchan=#{penchan}, tanki=#{tanki}"
        # puts "shuntsuNum=#{shuntsuNum}, shuntsuMenzenNum=#{shuntsuMenzenNum}, koutsuNum=#{koutsuNum}, koutsuMenzenNum=#{koutsuMenzenNum}"

        yaku = []
        yakuman = []

        # 平和
        isPinfu = false
        if shuntsuMenzenNum == 4 and ryanmen
            yaku.push Yaku.PINFU
            isPinfu = true

        # 平和判定が終わったので、待ち形の決定
        if isPinfu
            machi = 'ryanmen'
        else if tanki
            machi = 'tanki'
            fu += 2
        else if kanchan
            machi = 'kanchan'
            fu += 2
        else if penchan
            machi = 'penchan'
            fu += 2
        else if ryanmen
            machi = 'ryanmen'
        else
            machi = 'shanpon'

        # 断幺九
        tanyaoNum = 0 # 断幺対象の面子の数
        for m in mentsuAll
            tanyaoNum++ if not PaiKind.isYaochu(m.pkFrom) and not ( m.type == 'shuntsu' and PaiKind.isYaochu(m.pkFrom+2) )
        if tanyaoNum == 5
            yaku.push Yaku.TANYAO

        # 全帯幺/純全帯幺/混老頭/清老頭/字一色
        if tanyaoNum == 0
            jihaiNum = 0 # 字牌の面子の数
            yaochuNum = 0 # 幺九牌だけの面子の数
            for m in mentsuAll
                jihaiNum++ if PaiKind.toSuit( m.pkFrom ) == PaiSuit.JIHAI
                yaochuNum++ if PaiKind.isYaochu(m.pkFrom) and m.type != 'shuntsu'
            if jihaiNum == 0
                if yaochuNum == 5
                    yakuman.push Yaku.CHINROUTOU
                else
                    yaku.push Yaku.JUNCHAN
            else if jihaiNum == 5
                yakuman.push Yaku.TSUIISOU
            else
                if yaochuNum == 5
                    yaku.push Yaku.HONROUTOU
                else
                    yaku.push Yaku.CHANTA

        # 一盃口/二盃口
        peikou = 0
        for m1 in mentsu
            for m2 in mentsu
                if m1 != m2 and m1.type == 'shuntsu' and m2.type == 'shuntsu'
                    peikou++ if m1.pkFrom == m2.pkFrom
        if peikou >= 4
            yaku.push Yaku.RYANPEIKOU
        else if peikou == 2
            yaku.push Yaku.IIPEIKOU

        # 対々
        if koutsuMenzenNum == 4
            yakuman.push Yaku.SUUANKOU
        else if koutsuMenzenNum == 3
            yaku.push Yaku.SANANKO
        if koutsuNum == 4
            yaku.push Yaku.TOITOI

        # 三色同順/三色同刻
        shuntsuHead = []
        koutsuHead = []
        for m in mentsuAll
            if m.type == 'shuntsu'
                shuntsuHead[m.pkFrom] = true
            else if m.type == 'koutsu' or m.type == 'koutsu'
                koutsuHead[m.pkFrom] = true
        for i in [PaiKind.MAN1..PaiKind.MAN9]
            if shuntsuHead[i] and shuntsuHead[i+9] and shuntsuHead[i+18]
                yaku.push Yaku.SANSHOKU
                break
        for i in [PaiKind.MAN1..PaiKind.MAN9]
            if koutsuHead[i] and koutsuHead[i+9] and koutsuHead[i+18]
                yaku.push Yaku.SANSHOKU_DOUKOU
                break

        # 三槓子/四槓子
        kantsuNum = 0
        for m in mentsuAll
            kantsuNum++ if m.type == 'kantsu'
        if kantsuNum == 4
            yakuman.push Yaku.SUUKANTSU
        else if kantsuNum == 3
            yaku.push Yaku.SANKANTSU

        # 役牌/大三元/小三元
        yakuhaiNum = 0
        sangenNum = 0
        for m in mentsuAll
            if m.type == 'koutsu' or m.type == 'kantsu'
                if [PaiKind.HAKU, PaiKind.HATSU, PaiKind.CHUN ].indexOf( m.pkFrom ) >= 0
                    sangenNum++
                    yakuhaiNum++
        if sangenNum == 3
            yakuman.push Yaku.DAISANGEN
            yakuhaiNum -= 3
        else if sangenNum == 2
            for m in mentsu
                if m.type == 'toitsu' and [PaiKind.HAKU, PaiKind.HATSU, PaiKind.CHUN ].indexOf( m.pkFrom ) >= 0
                    yaku.push Yaku.SHOUSANGEN
                    yakuhaiNum -= 2
        for i in [0...yakuhaiNum]
            yaku.push Yaku.YAKUHAI

        # 大四喜/小四喜
        yakuhaiNum = 0
        kazeNum = 0
        for m in mentsuAll
            if m.type == 'koutsu' or m.type == 'kantsu'
                kazeNum++ if [PaiKind.TON, PaiKind.NAN, PaiKind.SHA, PaiKind.PEI ].indexOf( m.pkFrom ) >= 0
                yakuhaiNum++ if m.pkFrom == opt.bakaze
                yakuhaiNum++ if m.pkFrom == opt.jikaze

        if kazeNum == 4
            yakuman.push Yaku.DAISUUSHII
        else if kazeNum == 3
            for m in mentsu
                if m.type == 'toitsu'
                    if [PaiKind.TON, PaiKind.NAN, PaiKind.SHA, PaiKind.PEI ].indexOf( m.pkFrom ) >= 0
                        yakuman.push Yaku.SHOUSUUSHII
        else
            for i in [0...yakuhaiNum]
                yaku.push Yaku.YAKUHAI

        # 符ハネ
        originalFu = fu
        fu = Math.ceil(fu/10)*10
        fu = 30 if fu == 20 and not isPinfu # 平和以外なら３０符以上

        # 飜数の計算
        han = 0
        for y in yaku
            han += Yaku.info(y).han
            if [Yaku.SANSHOKU, Yaku.SANSHOKU_DOUKOU, Yaku.HONITSU, Yaku.CHINITSU ].indexOf(y) >= 0
                han -= 1 # 門前でないとき-1飜

        result.push { yaku:yaku, han:han, fu:fu, originalFu:originalFu, machi:machi, yakuman:yakuman }
    result[0]

tenho = (n)->
    result = {}
    result.shuntsu = shuntsu = Math.floor( n % 8 / 4 )
    if shuntsu == 1
        hai = Math.floor( n / 1024 )
        result.nakiNum = hai % 3
        result.pk = PaiKind.toString( Math.floor( hai / 3 ) )
    else
        hai = Math.floor( n / 512 )
        result.nakiNum = hai % 3
        result.pk = PaiKind.toString( Math.floor( hai / 3 ) )
    result





class Tenho
    @parseNTag: (n)->
        shuntsu = Math.floor( n % 8 / 4 )
        if shuntsu == 1
            hai = Math.floor( n / 1024 )
            return new Mentsu( 'shuntsu', Math.floor( hai / 3 ), true )
        else
            hai = Math.floor( n / 512 )
            return new Mentsu( 'koutsu', Math.floor( hai / 3 ), true )

libxmljs = require 'libxmljs'
fs = require 'fs'
xml = fs.readFileSync( 'hoge.xml' )
# xml = '<hoge>hoge</hoge>'
dom = libxmljs.parseXmlString( xml )
for agari in dom.find('//AGARI')
    pis = agari.attr('hai').value().split(',').map (s)->parseInt(s,10)
    pks = PaiId.toKind( pis )
    if agari.attr('m')
        mentsu = agari.attr('m').value().split(',').map (s)->Tenho.parseNTag(s)
    else
        mentsu = []
    pkMachi = PaiId.toKind( parseInt( agari.attr('machi'), 10 ) )
    ten = agari.attr('ten').value().split(',').map (s)->parseInt(s,10)
    fu = ten[0]
    score = ten[1]
    dora = parseInt( agari.attr('doraHai').value(), 10 )
    puts PaiKind.toReadable( pks )
    puts calcYaku( pks, mentsu, {pkLast:pkMachi} ), score

exports.PaiSuit = PaiSuit
exports.PaiKind = PaiKind
exports.PaiId = PaiId
exports.Mentsu = Mentsu
exports.Yaku = Yaku
exports.splitMentsu = splitMentsu
exports.calcYaku = calcYaku