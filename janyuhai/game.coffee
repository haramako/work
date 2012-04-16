# nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
    eval('var exports, global; exports = {}; window.game = exports; global = window;')

janutil = require './janutil'
jan = require './jan'
_ = require 'underscore'

PaiId = jan.PaiId
PaiKind = jan.PaiKind
Mentsu = jan.Mentsu
Yaku = jan.Yaku
cycle = (n,max)-> (n+max)%max

class Player
    constructor: (idx,src)->
        @idx = idx
        @initIdx = idx
        @name = src
        @piKawahai =[]
        @reachIndex = null
        @tehaiNum = 0
        @furo = [] # 副露牌(Mentsuの配列)
        @s =
            piTehai: []

###
# 麻雀のゲーム進行を司るクラス.
###
class Game
    ###
    # コンストラクタ
    # rule
    #   playerNum: プレイヤー数(3or4)
    #
    #   piCheatYama: 山牌(PaiIdの配列、要素数は136)
    #   cheatDice: ダイスの目([ダイス１の目,ダイス２の目])
    #
    ###
    constructor: (players, rule={})->
        # ルールの設定
        @rule = _.clone(rule)
        @rule.playerNum ?= 4

        @initialPlayers = [ new Player(0), new Player(1), new Player(2), new Player(3) ]
        @p = @initialPlayers.slice()
        @s = {}
        @state = 'INITIALIZED'
        @tsumoPos = 0
        @isMaster = true
        @curPlayer = null
        @haifu = []
        @lastStehai = null # 最後の捨牌

    makePos: (yama,pos,top)->

    splitPos: (idx)->
        idx = cycle(idx,PaiId.MAX)
        { yama: Math.floor(idx/36), pos: Math.floor(idx%4/2), pos: (idx%2==0) }

    tsumoFromYama: ->
        pi = @s.piYama[@tsumoPos]
        @tsumoPos = cycle(@tsumoPos+1,136)
        pi

    isOwner: (pl)-> @isMaster or @owner.idx == pl

    ###
    # 牌譜コマンド１つ分すすめる.
    #
    # TODO: ロン>ポン>チーの優先順位はリアルタイムでクライアントの選択がキャンセルされる例外
    # TODO: 場決めの牌選択はリアルタイム例外
    #
    # BAGIME_SELECT:
    # OYAGIME_DICE: 親決めのダイス
    # INIT_KYOKU: 牌を配る
    #   piYama: 山牌(PaiIdの配列、要素数は136)
    #
    # @return 選択肢を返す(コマンドの配列の配列,最初の添字はユーザー番号(0..3)
    #
    ###
    progress: (com)->
        #puts '==='
        #puts "state=#{@state}, curPlayer=#{@curPlayer} com=", com
        #puts '---'
        func = @commandFunc[com.type]
        if func
            @haifu.push com
            @choises = func.apply( this, [com] )
            #if @choises.length > 1
            #    puts c for c in @choises
            @choises
        else
            throw "invalid type in Game.progress(), type=#{com.type}"

    _validateState: ()->
        for st in arguments
            return if st == @state
        throw "invalid state, expects #{[].slice.apply(arguments)} but #{@state}"

    commandFunc:
        # 場決めのサイコロを振る
        BAGIME_SELECT: (com)->
            @_validateState 'INITIALIZED'
            for i in [0...com.pub.length]
                @p[i] = @initialPlayers[com.pub[i]]
                @p[i].idx = i
            @state = 'INIT_KYOKU'
            if @isMaster
                [{type:'INIT_KYOKU'}]
        # 局の初期化
        INIT_KYOKU: (com)->
            @_validateState 'INIT_KYOKU'
            @state = 'WAREME_DICE'
            if @isMaster
                if com.sec.piYama
                    @s.piYama = com.sec.piYama
                else
                    @s.piYama = _.shuffle([0...PaiId.MAX])
                [{type:'WAREME_DICE'}]
        # 山決めのサイコロを振る
        WAREME_DICE: (com)->
            @_validateState 'WAREME_DICE'
            # サイコロの情報がなかったら、ここで振る
            if @isMaster and not com.pub
                @dice = [Math.floor(Math.random()*6)+1, Math.floor(Math.random()*6)+1]
            @dice = com.pub.slice()
            dice = @dice[0]+@dice[1]
            @state = 'HAIPAI'
            @curPlayer = 0
            if @isMaster
                # 配牌を先に作成する
                @s.haipai = [[],[],[],[]]
                # ４枚x3回ずつとる
                for i in [1..3]
                    for pl in [0...@rule.playerNum]
                        @s.haipai[pl].push @tsumoFromYama() for n in [0...4]
                # チョンチョン
                for i in [0..4]
                    @s.haipai[i%4].push @tsumoFromYama()
                [{type:'HAIPAI', pl:0, sec: @s.haipai[0], pub:@s.haipai[0].length} ]
        # 配牌
        HAIPAI: (com)->
            @_validateState 'HAIPAI'
            @curPlayer = @nextPlayer(@curPlayer)
            if @isOwner(com.pl)
                player = @p[com.pl]
                player.s.piTehai = com.sec.slice()
                player.tehaiNum = player.s.piTehai.length
            @state = 'DAHAI' if com.pl == 3
            if @isMaster
                if com.pl == 3
                    @chooseDahai(@p[0])
                else
                    [{type:'HAIPAI', pl:com.pl+1, sec:@s.haipai[com.pl+1], pub:@s.haipai[com.pl+1].length } ]
        # 打牌
        DAHAI: (com)->
            @_validateState 'DAHAI'
            player = @p[com.pl]
            if @isOwner(com.pl)
                player.s.piTehai = _.without( player.s.piTehai, com.pub.pi )
            player.tehaiNum -= 1
            @lastStehai = com.pub.pi
            @state = 'NAKI'
            if @isMaster
                pl = @nextPlayer(@curPlayer,1)
                result = [{type:'TSUMO', pl:pl, sec:@tsumoFromYama()}]
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, true ) )
                pl = @nextPlayer(@curPlayer,2)
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, false ) )
                pl = @nextPlayer(@curPlayer,3)
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, false ) )
                result
        # 自摸
        TSUMO: (com)->
            @_validateState 'NAKI'
            player = @p[com.pl]
            if @isOwner(com.pl)
                player.s.piTehai.push com.sec
            player.tehaiNum -= 1
            @state = 'DAHAI'
            @curPlayer = player.idx
            if @isMaster
                @chooseDahai(player)
        # チー
        CHI: (com)->
            @_validateState 'NAKI'
            piLast = @lastSutehai()
            player = @p[com.pl]
            player.furo.push new Mentsu( [piLast,com.pub[0],com.pub[1]], @cycle(@curPlayer-player.idx) )
            player.tehaiNum -= 2
            if @isOwner(com.pl)
                for piMentsu in com.pub
                    player.s.piTehai = _.without( player.s.piTehai, piMentsu )
            @state = 'DAHAI'
            @curPlayer = player.idx
            if @isMaster
                @chooseDahai(@p[@curPlayer])
        # ポン
        PON: (com)->
            @commandFunc['CHI'].apply( this, [com] )

    nextPlayer: (pl,n=1)->cycle(pl+n,4)

    lastSutehai: ->@lastStehai

    # cycle()の人数省略バージョン
    cycle: (pl)->cycle(pl,@rule.playerNum)

    #========================================================
    # ここから下は、ゲームマスターの時しか使わない関数
    #========================================================

    # ツモったあとの自摸/打牌/リーチ/暗槓などの選択を行う
    chooseDahai: (player)->
        #[{type:'DAHAI', pl:player.idx }]
        player.s.piTehai.map (pi,i)->
            {type:'DAHAI', pl:player.idx, pub:{pi:pi} }

    # 鳴きの選択を行う
    # @return 牌譜コマンドの配列
    chooseNaki: (pl,piTehai,piKawa,enableChi)->
        paiTable = PaiKind.toPaiTable(PaiId.toKind(piTehai))
        pkKawa = PaiId.toKind(piKawa)
        result = []
        # チー
        if enableChi
            pkNakiList = []
            if PaiKind.isShuntsuStarter(pkKawa) and paiTable[pkKawa+1]>0 and paiTable[pkKawa+2]
                pkNakiList.push [pkKawa+1, pkKawa+2]
            if PaiKind.isShuntsuStarter(pkKawa-1) and  paiTable[pkKawa-1]>0 and paiTable[pkKawa+1]
                pkNakiList.push [pkKawa-1, pkKawa+1]
            if PaiKind.isShuntsuStarter(pkKawa-2) and  paiTable[pkKawa-2]>0 and paiTable[pkKawa-1]
                pkNakiList.push [pkKawa-2, pkKawa-1]
            chiList = _.flatten( pkNakiList.map( (pkNaki)=>Game.getCombination(piTehai,pkNaki) ), true )
            for chi in chiList
                result.push {type:'CHI', pl:pl, pub:chi}

        # ポン
        if paiTable[pkKawa]>=2
            ponList = Game.getCombination(piTehai,[pkKawa,pkKawa])
            for pon in ponList
                result.push {type:'PON', pl:pl, pub:pon}

        # 大明カン
        if paiTable[pkKawa]>=3
            kan = piTehai.filter (pi)->PaiId.toKind(pi) == pkKawa
            result.push {type:'KAN', pl:pl, pub:kan}

        result

    ###
    # PaiIDの配列の中から、指定されたPaiKindを選ぶ組み合わせを返す.
    #
    # # '一0一1二0二1'の組み合わせから, '一0二0','一1二0','一0二1','一1二1' の4通りの組み合わせを出す
    # Game.getCombination( [PaiId.MAN1_0, PaiID.MAN1_1, PaiId.MAN2_0, PaiID.MAN2_1], PaiKind.MAN1, PaiKind.MAN2 )
    #  # => [[MAN1_0,MAN2_0], [MAN1_1,MAN2_0], [MAN1_0,MAN2_1], [MAN1_1,MAN2_1]]
    ###
    @getCombination: (piFrom, pks)->
        piCombi = pks.map (pk)-> _.filter( piFrom, (pi)->PaiId.toKind(pi) == pk )
        janutil.combinate( piCombi )

###
game = new Game( [], {} )

# puts game.chooseNaki( 0, [0,1,4,9,10,11,12], 8, true )

game.progress {type:'BAGIME_SELECT', pub:[0,1,2,3]}
game.progress {type:'INIT_KYOKU', sec:{ piYama: [0...136] }}
#game.progress {type:'INIT_KYOKU', sec:{ }}
h = game.progress {type:'WAREME_DICE', pub:[1,1] }
for i in [0..80]
    com = h[0]
    if h[1] and (h[1].type == 'CHI' or h[1].type == 'PON' )
        com = h[1]
    if com.type == 'DAHAI'
        com = _.clone( com )
        com.pub = {pi:game.p[game.curPlayer].s.piTehai[0]}
    h = game.progress( com )

###

exports.Game = Game