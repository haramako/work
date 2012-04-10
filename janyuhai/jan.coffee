janutil = require './janutil'

###
# PaiKind: 牌の種類（筒子、萬子、索子、字牌)を表すEnum
###
PaiKind = new janutil.Enum('MANZU','PINZU','SOUZU','JIHAI').exportTo( exports )

###
# PaiId: 牌の種類（一萬、二萬・・・発、中）を表すEnum
#
# # 牌の種類を取得する
# PaiId.kind( PaiId.MAN1 ) # => PaiKind.MANZU
#
# # 牌を読みやすい文字列と変換する
#
# PaiId.fromReadable( '一①１東' ) # => [ PaiId.MAN1, PaiId.PIN1, PaiId.SOU1, PaiId.TON ]
# PaiId.toReadable( [ PaiId.MAN1, PaiId.PIN1, PaiId.SOU1, PaiId.TON ] ) # =>'一①１東' )
#
# # fromReadable()/toReadable()は、配列や' 'で区切った文字列を分けて処理できる
# PaiId.fromReadable( '一① １東' ) # => [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ] (配列の配列として返される)
# PaiId.fromReadable( ['一①','１東'] ) # => [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ]
# PaiId.toReadable( [ [PaiId.MAN1, PaiId.PIN1], [PaiId.SOU1, PaiId.TON] ] ) # => ['一①','１東']
#
# # 牌の工数分布(pai-table)に変換する
# PaiId.toPaiTable( [
#
###
PaiId = new janutil.Enum(
    'MAN1','MAN2','MAN3','MAN4','MAN5','MAN6','MAN7','MAN8','MAN9',
    'PIN1','PIN2','PIN3','PIN4','PIN5','PIN6','PIN7','PIN8','PIN9',
    'SOU1','SOU2','SOU3','SOU4','SOU5','SOU6','SOU7','SOU8','SOU9',
    'TON', 'NAN', 'SHA', 'PEI', 'HAKU', 'HATSU', 'CHUN',
).exportTo( exports )

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
        throw "argument error in PaiId.toReadable, argument = #{num}"

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
        throw "argument error in PaiId.fromReadable, argument = #{str}"


PaiId._shuntsuStarter = {}
for n in PaiId.fromReadable('一二三四五六七１２３４５６７①②③④⑤⑥⑦')
    PaiId._shuntsuStarter[n] = true

PaiId.toPaiTable = (pis)->
    result = []
    result[i] = 0 for i in [0...PaiId.MAX]
    for pi in pis
        result[pi]++
    result

# メンツに分ける
#
splitMentsu = (pis,opt)->
    allMentsu = []
    callNum = 0
    num = pis.length
    curMentsu = []
    paiTable = PaiId.toPaiTable(pis)
    toitsuNum = 0
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
            curMentsu.push [piCur,piCur,piCur]
            split piCur, false
            curMentsu.pop()
            num += 3
            paiTable[piCur] += 3
        # 対子の判定をする
        if not withoutKoutsu and toitsuNum <= 0 and paiTable[piCur] >= 2
            paiTable[piCur] -= 2
            toitsuNum += 1
            num -= 2
            curMentsu.push [piCur,piCur]
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
            curMentsu.push [piCur,piCur+1,piCur+2]
            split piCur, true
            curMentsu.pop()
            num += 3
            paiTable[piCur  ] += 1
            paiTable[piCur+1] += 1
            paiTable[piCur+2] += 1
    split 0
    # puts callNum
    allMentsu


# console.log PaiId
#console.log PaiId.kind( 10 )
#puts toPaiTable([0,1,2,3,3])

exports.PaiId = PaiId
exports.PaiKind = PaiKind
exports.splitMentsu = splitMentsu