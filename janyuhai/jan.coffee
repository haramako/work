# nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
    eval('var exports, global; exports = {}; window.jan = exports; global = window;')

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

PaiKind.next = (pk)->
    if pk == PaiKind.MAN9
        PaiKind.MAN1
    else if pk == PaiKind.PIN9
        PaiKind.PIN1
    else if pk == PaiKind.SOU9
        PaiKind.SOU1
    else if pk == PaiKind.PEI
        PaiKind.TON
    else if pk == PaiKind.CHUN
        PaiKind.HAKU
    else
        pk + 1


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
PaiId.fromKind = (pk,index=0)->
    if typeof pk == 'number'
        pk * 4 + index
    else if pk.map
        pk.map (n)-> PaiId.fromKind(n,index)
    else
        throw "argument error in PaiId.fromKind(), pi=#{pk}"
PaiId.index = (pi)-> pk % 4
PaiId.uniq = (pis)->
    if typeof pis[0] == 'number' or pis[0] == undefined
        usedTable = new Array(PaiId.MAX)
        for pi,i in pis
            continue unless pi
            while usedTable[pi]
                pi = (pi+1)%PaiId.MAX
                pis[i] = pi
            usedTable[pi] = true
        pis
    else if pis.map
        pis.map (a)->PaiId.uniq(a)
    else
        throw "argument error in PaiId.uniq(), pis=#{pis}"

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
splitMentsu = (pks,opt={})->
    allMentsu = []
    callNum = 0
    num = pks.length
    curMentsu = []
    paiTable = PaiKind.toPaiTable(pks)
    toitsuNum = 0
    allowRest = if opt.allowRest then 2 else 0
    # 再帰しながら面子を分解する関数
    split = (pkCur, withoutKoutsu)->
        callNum += 1
        found = false
        # 終了判定
        if num <= 0 and toitsuNum == 1
            allMentsu.push curMentsu.slice()
            return
        if pkCur == PaiKind.MAX # 終了判定
            if opt.allowRest
                rest = []
                for n,pk in paiTable
                    rest.push pk for i in [0...n]
                allMentsu.push [rest].concat(curMentsu)
            else
                allMentsu.push curMentsu.slice()
            return
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
        # 余り牌を許すなら続行
        if not found and allowRest >= paiTable[pkCur]
            allowRest -= paiTable[pkCur]
            split pkCur+1, false
            allowRest += paiTable[pkCur]

    split 0
    # puts callNum
    allMentsu

###
# 面子をひとつ表すオブジェクト.
#
# type: 'toitsu', 'koutsu', 'kantsu', 'shuntsu'のいずれかの文字列
# pk  : 構成する牌のうち、一番数がすくないPaiKind（１２３の場合１となる）
# furo: 副露されているうかどうか（暗槓は連外的にfuro=falseとなる）
# dir : 鳴いた方向(0:門前, 1:上家, 2:対面, 3:下家)
###
class Mentsu
    ###
    # コンストラクタ.
    # 下記の２つの呼び方がある
    # new Mentsu( 'mentsu', jan.PaiKind.MAN1, 0 )
    # new Mentsu( [jan.PaiId.MAN1_0, jan.PaiId.MAN2_0, jan.PaiId.MAN3_0], 0 )
    ###
    constructor: ()->
        if arguments.length == 3
            @type = arguments[0]
            @pk = arguments[1]
            @dir = arguments[2]
            @furo = ( @dir != 0 )
            throw "invalid dir, dir=#{@dir}" unless @dir == 0 or @dir == 1 or @dir == 2 or @dir == 3
            switch @type
                when 'shuntsu'
                    @pis = PaiId.fromKind( [@pk,@pk+1,@pk+2] )
                when 'toitsu'
                    @pis = PaiId.fromKind( [@pk,@pk] )
                when 'koutsu'
                    @pis = PaiId.fromKind( [@pk,@pk,@pk] )
                when 'kantsu'
                    @pis = PaiId.fromKind( [@pk,@pk,@pk,@pk] )
                else
                    throw "invalid type, type=#{@type}"
        else
            @pis = arguments[0]
            pkSorted = PaiId.toKind( @pis )
            pkSorted.sort (a,b)->a-b
            @dir = arguments[1]
            @furo = ( @dir != 0 )
            @pk = pkSorted[0]
            if pkSorted.length == 2 and @pk == pkSorted[1]
                @type = 'toitsu'
            else if pkSorted.length == 3 and @pk == pkSorted[1] and @pk == pkSorted[2]
                @type = 'koutsu'
            else if pkSorted.length == 4 and @pk == pkSorted[1] and @pk == pkSorted[2] and @pk == pkSorted[3]
                @type = 'kantsu'
            else if pkSorted.length == 3 and PaiKind.isShuntsuStarter(@pk) and @pk+1 == pkSorted[1] and @pk+2 == pkSorted[2]
                @type = 'shuntsu'
            else
                throw "argument error in new Mentsu(), arguments=#{[].slice.apply(arguments)}"

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
    @fromArray: (src,dir=0)->
        if typeof src[0] == 'number'
            new Mentsu( PaiId.fromKind(src), dir)
        else
            src.map (x)->Mentsu.fromArray(x,dir)

    # 特定のハイを何枚含むかを返す
    countPai: (pk)->
        switch @type
            when 'toitsu'
                if @pk == pk then 2 else 0
            when 'koutsu'
                if @pk == pk then 3 else 0
            when 'kantsu'
                if @pk == pk then 4 else 0
            when 'shuntsu'
                if @pk == pk or @pk+1 == pk or @pk+2 == pk then 1 else 0

    ###
    # 文字列に変換する
    ###
    toString: ->
        str = switch @type
            when 'toitsu'
                PaiKind.toReadable( [@pk, @pk] )
            when 'koutsu'
                PaiKind.toReadable( [@pk, @pk, @pk] )
            when 'kantsu'
                PaiKind.toReadable( [@pk, @pk, @pk, @pk] )
            when 'shuntsu'
                PaiKind.toReadable( [@pk, @pk+1, @pk+2] )
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
    ['URADORA'   , '裏ドラ'    , 1 ],
    ['AKADORA'   , '赤ドラ'    , 1 ],
    ['TANYAO'    , 'タンヤオ'  , 1 ],
    ['IIPEIKOU'  , '一盃口'    , 1 ],
    ['REACH'     , 'リーチ'    , 1 ],
    ['IPPATSU'   , '一発'      , 1 ],
    ['TSUMO'     , '門前自摸'  , 1 ],
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
#   pkDora: ドラの配列
#   pkUradora: 裏ドラの配列
#   akadora: 赤ドラの数
#   pkLast:最後にツモった牌
#   tsumo: 自摸かどうかの真偽値
#   pkBakaze: 場風（PaiKind.TON/NANのいずれか)
#   pkJikaze: 自風（PaiKind.TON/NAN/SHA/PEIのいずれか）
#   reach: リーチしているかどうか
#   ippatsu: 一発かどうか
#
# @param pkTehai 手牌を表すPaiKindの配列
# @param furo 副露牌を表すMensuの配列
# @param opt その他のオプション
# @return 役や飜数を表すオブジェクト
###
calcYaku = (pkTehai,furo,opt={})->

    # 手牌を分解
    tehaiMentsuList = Mentsu.fromArray( splitMentsu( pkTehai ), 0 )
    if tehaiMentsuList.length == 0
        throw "invalid arguments in calcYaku(), pkTehai=#{pkTehai}"
    result = []

    # 符/待ち形の計算
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
        koutsuAbsolutelyMenzenNum = 0
        mentsuAll = mentsu.concat( furo )
        for m in mentsuAll
            switch m.type
                when 'toitsu'
                    tanki = true if m.pk == opt.pkLast
                    fu += 2 if [PaiKind.HAKU,PaiKind.HATSU,PaiKind.CHUN].indexOf( m.pk ) >= 0
                    fu += 2 if opt.pkBakaze == m.pk or opt.pkJikaze == m.pk
                when 'shuntsu'
                    shuntsuNum++
                    shuntsuMenzenNum++ if not m.furo
                    kanchan = true if m.pk+1 == opt.pkLast
                    if not m.furo and ( m.pk == opt.pkLast or m.pk+2 == opt.pkLast )
                        if (PaiKind.isYaochu(m.pk) or PaiKind.isYaochu(m.pk+2)) and not PaiKind.isYaochu(opt.pkLast)
                            penchan = true
                        else
                            ryanmen = true

                when 'koutsu', 'kantsu'
                    koutsuNum++
                    isFuro = m.furo
                    isFuro = true if not opt.tsumo and m.pk == opt.pkLast # ロン和了りの場合、副露牌と判定する
                    m.furo = isFuro # TODO:とりあえず
                    m.dir = 1 if m.furo and not m.type=='kantsu'# TODO:とりあえず
                    if m.type == 'koutsu'
                        if PaiKind.isYaochu(m.pk)
                            fu += if isFuro then 4 else 8
                        else
                            fu += if isFuro then 2 else 4
                    else
                        if PaiKind.isYaochu(m.pk)
                            fu += if isFuro then 16 else 32
                        else
                            fu += if isFuro then 8 else 16
                    koutsuMenzenNum++ if not m.furo or m.dir == 0
                    koutsuAbsolutelyMenzenNum++ if not m.furo

        # puts "ryanme=#{ryanmen}, kanchan=#{kanchan}, penchan=#{penchan}, tanki=#{tanki}"
        # puts "shuntsuNum=#{shuntsuNum}, shuntsuMenzenNum=#{shuntsuMenzenNum}, koutsuNum=#{koutsuNum}, koutsuMenzenNum=#{koutsuMenzenNum}"

        yaku = []
        yakuman = []


        # 門前自摸
        if opt.tsumo and (shuntsuMenzenNum + koutsuMenzenNum == 4)
            yaku.push Yaku.TSUMO

        # 平和
        isPinfu = false
        if shuntsuMenzenNum == 4 and ryanmen and fu == 20
            yaku.push Yaku.PINFU
            isPinfu = true

        fu += 10 if ((shuntsuMenzenNum + koutsuMenzenNum) == 4) and not opt.tsumo # 門前ロンの10符
        fu += 2 if opt.tsumo # 自摸の2符

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
            tanyaoNum++ if not PaiKind.isYaochu(m.pk) and not ( m.type == 'shuntsu' and PaiKind.isYaochu(m.pk+2) )
        if tanyaoNum == 5
            yaku.push Yaku.TANYAO

        # 全帯幺/純全帯幺/混老頭/清老頭/字一色
        if tanyaoNum == 0
            jihaiNum = 0 # 字牌の面子の数
            yaochuNum = 0 # 幺九牌だけの面子の数
            for m in mentsuAll
                jihaiNum++ if PaiKind.toSuit( m.pk ) == PaiSuit.JIHAI
                yaochuNum++ if PaiKind.isYaochu(m.pk) and m.type != 'shuntsu'
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
        if furo.length == 0
            peikou = 0
            for m1 in mentsu
                for m2 in mentsu
                    if m1 != m2 and m1.type == 'shuntsu' and m2.type == 'shuntsu'
                        peikou++ if m1.pk == m2.pk
            if peikou >= 4
                yaku.push Yaku.RYANPEIKOU
            else if peikou == 2
                yaku.push Yaku.IIPEIKOU

        # 対々
        if koutsuAbsolutelyMenzenNum == 4
            yakuman.push Yaku.SUUANKOU
        else if koutsuAbsolutelyMenzenNum == 3
            yaku.push Yaku.SANANKO
        if koutsuNum == 4
            yaku.push Yaku.TOITOI

        # 三色同順/三色同刻/一気通貫
        shuntsuHead = []
        koutsuHead = []
        for m in mentsuAll
            if m.type == 'shuntsu'
                shuntsuHead[m.pk] = true
            else if m.type == 'koutsu' or m.type == 'koutsu'
                koutsuHead[m.pk] = true
        # 三色同順
        for i in [PaiKind.MAN1..PaiKind.MAN9]
            if shuntsuHead[i] and shuntsuHead[i+9] and shuntsuHead[i+18]
                yaku.push Yaku.SANSHOKU
                break
        # 三色同刻
        for i in [PaiKind.MAN1..PaiKind.MAN9]
            if koutsuHead[i] and koutsuHead[i+9] and koutsuHead[i+18]
                yaku.push Yaku.SANSHOKU_DOUKOU
                break
        # 一気通貫
        for i in [PaiKind.MAN1,PaiKind.PIN1,PaiKind.SOU1]
            if shuntsuHead[i] and shuntsuHead[i+3] and shuntsuHead[i+6]
                yaku.push Yaku.ITTSU
                break

        # 混一色/清一色
        suitNum = [0,0,0,0]
        for m in mentsuAll
            suitNum[ PaiKind.toSuit( m.pk )]++
        for suit in [PaiSuit.MANZU,PaiSuit.PINZU,PaiSuit.SOUZU]
            if suitNum[suit] == 5
                yaku.push Yaku.CHINITSU
            else if suitNum[suit] > 0 and suitNum[suit] + suitNum[PaiSuit.JIHAI] == 5
                yaku.push Yaku.HONITSU

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
                if [PaiKind.HAKU, PaiKind.HATSU, PaiKind.CHUN ].indexOf( m.pk ) >= 0
                    sangenNum++
                    yakuhaiNum++
        if sangenNum == 3
            yakuman.push Yaku.DAISANGEN
            yakuhaiNum -= 3
        else if sangenNum == 2
            for m in mentsu
                if m.type == 'toitsu' and [PaiKind.HAKU, PaiKind.HATSU, PaiKind.CHUN ].indexOf( m.pk ) >= 0
                    yaku.push Yaku.SHOUSANGEN
                    yakuhaiNum -= 2
        for i in [0...yakuhaiNum]
            yaku.push Yaku.YAKUHAI

        # 大四喜/小四喜/風牌
        yakuhaiNum = 0
        kazeNum = 0
        for m in mentsuAll
            if m.type == 'koutsu' or m.type == 'kantsu'
                kazeNum++ if [PaiKind.TON, PaiKind.NAN, PaiKind.SHA, PaiKind.PEI ].indexOf( m.pk ) >= 0
                yakuhaiNum++ if m.pk == opt.pkBakaze
                yakuhaiNum++ if m.pk == opt.pkJikaze
        if kazeNum == 4
            yakuman.push Yaku.DAISUUSHII
        else if kazeNum == 3
            for m in mentsu
                if m.type == 'toitsu'
                    if [PaiKind.TON, PaiKind.NAN, PaiKind.SHA, PaiKind.PEI ].indexOf( m.pk ) >= 0
                        yakuman.push Yaku.SHOUSUUSHII
        for i in [0...yakuhaiNum]
            yaku.push Yaku.YAKUHAI

        # ドラ/裏ドラ/赤ドラ
        for m in mentsuAll
            if opt.pkDora
                for pkDora in opt.pkDora
                    for n in [0...m.countPai( pkDora )]
                        yaku.push Yaku.DORA
            if opt.pkUradora
                for pkUradora in opt.pkUradora
                    for n in [0...m.countPai( pkUradora )]
                        yaku.push Yaku.URADORA
        for n in [0...opt.akadora]
            yaku.push Yaku.AKADORA
        for m in furo
            for pi in m.pis
                if pi == PaiId.MAN5_0 or pi == PaiId.PIN5_0 or pi == PaiId.SOU5_0
                    yaku.push Yaku.AKADORA

        # リーチ/ダブルリーチ/一発
        if opt.doubleReach
            yaku.push Yaku.DOUBLE_REACH
        else if opt.reach
            yaku.push Yaku.REACH
        yaku.push Yaku.IPPATSU if opt.ippatsu

        # 河底/海底/嶺上開花
        yaku.push Yaku.RINSHAN if opt.rinshan
        yaku.push Yaku.HAITEI if opt.haitei
        yaku.push Yaku.HOUTEI if opt.houtei

        # 符ハネ
        originalFu = fu
        fu = Math.ceil(fu/10)*10
        if isPinfu and opt.tsumo # 平和自摸なら20符
            fu = 20
        else
            fu = 30 if fu < 30

        # 飜数の計算
        han = 0
        for y in yaku
            han += Yaku.info(y).han
            # 門前でないとき-1飜になる役の処理
            if furo.length != 0 and [Yaku.SANSHOKU, Yaku.ITTSU, Yaku.SANSHOKU_DOUKOU, Yaku.HONITSU, Yaku.CHINITSU, Yaku.CHANTA ].indexOf(y) >= 0
                han -= 1

        score = scoreFromFuHan( fu, han, opt.oya, opt.tsumo )
        result.push { yaku:yaku, han:han, fu:fu, originalFu:originalFu, machi:machi, yakuman:yakuman, score: score }
    result[0]

###
# 符と飜から点数を返す.
#
# @param fu 符
# @param han 飜
# @param oya 親かどうか
# @param tsumo 自摸かどうか
# @return 点数を返す[和了りの種類, ロン点数, 親の支払い点数, 子の支払点]（和了りの種類は'normal','mangan','haneman','baiman','sanbaiman','yakuman'のいずれか)
###
scoreFromFuHan = (fu,han,oya)->
    if han >= 13
        type = 'yakuman'
        score = 8000
    else if han >= 11
        type = 'sanbaieman'
        score = 6000
    else if han >= 8
        type = 'baieman'
        score = 4000
    else if han >= 6
        type = 'haneman'
        score = 3000
    else if han >= 5 or ( han == 4 and fu >= 30 ) or ( han == 3 and fu >= 60 ) or (han == 2 and fu >= 120 )
        type = 'mangan'
        score = 2000
    else
        type = 'normal'
        score = 4 * fu * Math.pow(2,han)

    if oya
        [type, Math.ceil( score*6/100 )*100, Math.ceil( score*2/100 )*100, Math.ceil( score*2/100 )*100]
    else
        [type, Math.ceil( score*4/100 )*100, Math.ceil( score*2/100 )*100, Math.ceil( score  /100 )*100]

#for fu in [20,30,40,50,60] # ,70,80,90,100]
#    for han in [1..8]
#        puts "#{fu}符 #{han}飜 親ツモ "+scoreFromFuHan( fu,han, true, true ).slice(1)+
#            " 親ロン "+scoreFromFuHan( fu,han, true, false )[1]
#        puts "#{fu}符 #{han}飜 子ツモ "+scoreFromFuHan( fu,han, false, true ).slice(1)+
#            " 子ロン "+scoreFromFuHan( fu,han, false, false )[1]

isTenpai = (pks)->

exports.PaiSuit = PaiSuit
exports.PaiKind = PaiKind
exports.PaiId = PaiId
exports.Mentsu = Mentsu
exports.Yaku = Yaku
exports.splitMentsu = splitMentsu
exports.calcYaku = calcYaku
exports.scoreFromFuHan = scoreFromFuHan