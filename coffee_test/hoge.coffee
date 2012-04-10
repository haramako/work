'use strict'

# console.log のエイリアス
puts = -> console.log.apply console, arguments

class Enum
    constructor: (ids)->
        cur = 0
        for id in ids
            this[id] = cur
            cur++
        this.MAX = cur

PaiKind = new Enum(['MANZU','PINZU','SOUZU','JIHAI'])

PaiId = new Enum([
    'MAN1','MAN2','MAN3','MAN4','MAN5','MAN6','MAN7','MAN8','MAN9'
    'PIN1','PIN2','PIN3','PIN4','PIN5','PIN6','PIN7','PIN8','PIN9'
    'SOU1','SOU2','SOU3','SOU4','SOU5','SOU6','SOU7','SOU8','SOU9'
    'TON', 'NAN', 'SHA', 'PEI', 'HAKU', 'HATSU', 'CHUN'
    ])

PaiId.kind = (pi)->
    if pi >= @MAN1 and pi <= @MAN9
        PaiKind.MANZU
    else if pi >= @PIN1 and pi <= @PIN9
        PaiKind.PINZU
    else if pi >= @SOU1 and pi <= @SOU9
        PaiKind.SOUZU
    else
        PaiKind.JIHAI


toPaiTable = (pis)->
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
    paiTable = toPaiTable(pis)
    toitsuNum = 0
    split = (piCur)->
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
        # 対子の判定をする
        if toitsuNum <= 0 and paiTable[piCur] >= 2
            paiTable[piCur] -= 3
            toitsuNum += 1
            num -= 2
            curMentsu.push [piCur,piCur]
            split piCur
            curMentsu.pop()
            num += 2
            toitsuNum -= 1
            paiTable[piCur] += 3

        # コーツの判定をする
        if paiTable[piCur] >= 3
            paiTable[piCur] -= 3
            num -= 3
            curMentsu.push [piCur,piCur,piCur]
            split piCur
            curMentsu.pop()
            num += 3
            paiTable[piCur] += 3
        # 順子の判定をする
        if paiTable[piCur] >= 1 and paiTable[piCur+1] >=1 and paiTable[piCur+2] >=1
            paiTable[piCur  ] -= 1
            paiTable[piCur+1] -= 1
            paiTable[piCur+2] -= 1
            num -= 3
            curMentsu.push [piCur,piCur+1,piCur+2]
            split piCur
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

puts splitMentsu [0,0,0,1,2,3,3,3]


