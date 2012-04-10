janutil = require './janutil'

###
# 牌の種類（筒子、萬子、索子、字牌)を表すEnum.
###
PaiKind = new janutil.Enum(['MANZU','PINZU','SOUZU','JIHAI']).exportTo( exports )

###
# 牌の種類（一萬、二萬・・・発、中）を表すEnum.
#
# # 牌の種類を取得する
# PaiId.kind( PaiId.MAN1 ) # => PaiKind.MANZU
#
# # 牌を読みやすい文字列と変換する
# PaiId.fromReadable( '一①１東' ) # => [ PaiId.MAN1, PaiId.PIN1, PaiId.SOU1, PaiId.TON ]
# PaiId.toReadable( [ PaiId.MAN1, PaiId.PIN1, PaiId.SOU1, PaiId.TON ] ) # =>'一①１東' )
#
# # fromReadable()/toReadable()は、配列や' 'で区切った文字列を分けて処理できる
# PaiId.fromReadable( '一① １東' ) # => [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ] (配列の配列として返される)
# PaiId.fromReadable( ['一①','１東'] ) # => [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ]
# PaiId.toReadable( [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ] ) # => ['一①','１東']
#
###
PaiId = new janutil.Enum([
        'MAN1','MAN2','MAN3','MAN4','MAN5','MAN6','MAN7','MAN8','MAN9',
        'PIN1','PIN2','PIN3','PIN4','PIN5','PIN6','PIN7','PIN8','PIN9',
        'SOU1','SOU2','SOU3','SOU4','SOU5','SOU6','SOU7','SOU8','SOU9',
        'TON', 'NAN', 'SHA', 'PEI', 'HAKU', 'HATSU', 'CHUN' ] ).exportTo( exports )

# Readableな文字列の対応表
PaiId._strings = [
    '一','二','三','四','五','六','七','八','九',
    '①','②','③','④','⑤','⑥','⑦','⑧','⑨',
    '１','２','３','４','５','６','７','８','９',
    '東','南','西','北','白','発','中' ]

PaiId.toKind = (pi)->
    if pi >= PaiId.MAN1 and pi <= PaiId.MAN9
        PaiKind.MANZU
    else if pi >= PaiId.PIN1 and pi <= PaiId.PIN9
        PaiKind.PINZU
    else if pi >= PaiId.SOU1 and pi <= PaiId.SOU9
        PaiKind.SOUZU
    else
        PaiKind.JIHAI

PaiId.toReadable = (num)->
    if typeof num == 'number'
        @_strings[num]
    else if num.map
        num.map( (n)-> PaiId.toReadable(n) ).join('')
    else
        throw "argument error in PaiId.toReadable(), argument = #{num}"

PaiId.fromReadable = (str)->
    if typeof str == 'string'
        if str.indexOf(' ') >= 0
            PaiId.fromReadable( str.split(' ') )
        else
            result = []
            for s in str
                for i in [0...@_strings.length]
                    if s == @_strings[i]
                        result.push i
                        break
            result
    else if str.map
        result = str.map (s)-> PaiId.fromReadable(s)
    else
        throw "argument error in PaiId.fromReadable(), argument = #{str}"

# 順子の開始となるかどうかの連想配列（つまり数牌で７以下かどうか)
PaiId._shuntsuStarter = {}
for n in PaiId.fromReadable('一二三四五六七１２３４５６７①②③④⑤⑥⑦')
    PaiId._shuntsuStarter[n] = true

###
# 牌の個数分布(pai-table)に変換する.
#
# PaiId.toPaiTable( [PaiId.MAN1, PaiId.MAN2, PaiId.MAN2] ) # => [1,2,0,0,....]
# 引数は、PaiIdの配列
# 返り値は、インデックスがPaiIdで値がその牌の個数を表すような配列で、長さはPaiId.MAXとなる。
###
PaiId.toPaiTable = (pis)->
    result = []
    result[i] = 0 for i in [0...PaiId.MAX]
    for pi in pis
        result[pi]++
    result

###
# メンツに分ける.
#
# 面子で分解したときの候補すべてを返す
#
# splitMentsu( PaiId.fromReadable('１１１２３４４４') )
# # => [
# #  [ [ 18, 18, 18 ], [ 19, 20, 21 ], [ 21, 21 ] ], # 一つの要素が分割のパターンひとつ、この場合は２パターンの分け方がある
# #  [ [ 18, 18 ], [ 18, 19, 20 ], [ 21, 21, 21 ] ]
# # ]
#
###
splitMentsu = (pis,opt)->
    allMentsu = []
    callNum = 0
    num = pis.length
    curMentsu = []
    paiTable = PaiId.toPaiTable(pis)
    toitsuNum = 0
    # 再帰しながら面子を分解する関数
    split = (piCur, withoutKoutsu)->
        callNum += 1
        # 終了判定
        if num <= 0 and toitsuNum == 1
            allMentsu.push curMentsu.slice()
            return
        return if piCur >= PaiId.MAX # 終了判定
        # 牌がなかったら次へ
        if paiTable[piCur] == 0
            split( piCur+1 )
            return
        # コーツの判定をする
        if not withoutKoutsu and paiTable[piCur] >= 3
            paiTable[piCur] -= 3
            num -= 3
            curMentsu.push [ piCur, piCur, piCur ]
            split piCur, false
            curMentsu.pop()
            num += 3
            paiTable[piCur] += 3
        # 対子の判定をする
        if not withoutKoutsu and toitsuNum <= 0 and paiTable[piCur] >= 2
            paiTable[piCur] -= 2
            toitsuNum += 1
            num -= 2
            curMentsu.push [ piCur, piCur ]
            split piCur, false
            curMentsu.pop()
            num += 2
            toitsuNum -= 1
            paiTable[piCur] += 2
        # 順子の判定をする
        if PaiId._shuntsuStarter[piCur] and # 順子はじまりの牌
        paiTable[piCur] >= 1 and paiTable[piCur+1] >=1 and paiTable[piCur+2] >=1
            paiTable[piCur  ] -= 1
            paiTable[piCur+1] -= 1
            paiTable[piCur+2] -= 1
            num -= 3
            curMentsu.push [piCur, piCur+1, piCur+2]
            split piCur, true
            curMentsu.pop()
            num += 3
            paiTable[piCur  ] += 1
            paiTable[piCur+1] += 1
            paiTable[piCur+2] += 1
    split 0
    # puts callNum
    allMentsu

###
# 面子をひとつ表すオブジェクト.
#
# type: 'toitsu', 'koutsu', 'kantsu', 'shuntsu'のいずれかの文字列
# from: 構成する牌のうち、一番数がすくないPaiId（１２３の場合１となる）
# furo: 副露されているうかどうか（暗槓は連外的にfuro=falseとなる）
###
class Mentsu
    constructor: (type,from,furo=false)->
        @type = type
        @from = from
        @furo = furo

    ###
    # PaiIdの配列からMentsuを生成する.
    #
    # PaiIdの配列の配列などにも対応し、その場合は引数の配列の構造を維持する
    #
    # Mentsu.fromArray( [jan.MAN1, jan.MAN2, jan.MAN3] ) # => new Mentsu( 'shuntsu', jan.MAN1, false )と同等のオブジェクト
    # @param src PaiIdの配列（もしくは配列の配列、配列の配列の...）
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
            else if src.length == 3 and PaiId._shuntsuStarter[src[0]] and src[0] == src[1]-1 and src[0] == src[2]-2
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
                PaiId.toReadable( [@from, @from] )
            when 'koutsu'
                PaiId.toReadable( [@from, @from, @from] )
            when 'kantsu'
                PaiId.toReadable( [@from, @from, @from, @from] )
            when 'shuntsu'
                PaiId.toReadable( [@from, @from+1, @from+2] )
            else
                throw 'invalid type'
        if @furo
            "[#{str}]"
        else if @type == 'kantsu'
            "(#{str})" # 暗槓は()
        else
            str





# console.log PaiId
#console.log PaiId.kind( 10 )
#puts toPaiTable([0,1,2,3,3])

exports.PaiId = PaiId
exports.PaiKind = PaiKind
exports.Mentsu = Mentsu
exports.splitMentsu = splitMentsu