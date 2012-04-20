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

cycle = (n,max)-> (n%max+max)%max

###
# プレイヤー一人を表すクラス.
###
class Player
    constructor: (idx,src)->
        @idx = undefined # 現在の座っている場所、場決めまで分からないので初期値はnull(0:東家,1:南家, 2:西家, 3:北家)
        @initIdx = idx # ゲーム開始時の位置(0-3のいずれか)
        @name = src # 名前
        @piKawahai =[] # 川牌（鳴かれた牌も含む）
        @reachIndex = undefined # リーチした牌のpiKawahaiのインデックス
        @reachDisplayIndex = undefined # リーチ表示牌のpiKawahaiのインデックス（鳴かれるとreadhIndexとずれる)
        @kawahaiState = [] # 鳴かれているかどうか(0:なにもない, 1:鳴かれている, 2:リーチ宣言牌)
        @tehaiNum = 0 # 手牌の数
        @furo = [] # 副露牌(Mentsuの配列)
        @score = undefined # 点数
        @isFirst = undefined # 初巡かどうか
        @s = # 秘密('s'ecret)情報、ゲームマスターもしくは自分の時だけ保持する
            piTehai: [] # 手牌

# 山牌の状態
YamaState = new janutil.Enum(['CLOSED','USED','OPENED'])

KawaState = new janutil.Enum(['NORMAL','NAKI','REACH'])

###
# 麻雀のゲーム進行を司るクラス.
###
class Game
    ###
    # コンストラクタ
    # rule
    #   playerNum: プレイヤー数(3or4)
    ###
    constructor: (players, rule={})->
        # ルールの設定
        @rule = _.clone(rule)
        @rule.playerNum ?= 4

        @initialPlayers = for i in [0...4]
            p = new Player(i)
            p.score = 25000
            p
        @p = @initialPlayers.slice()
        @s =
            haipai: [[],[],[],[]] # 配牌を保存する(PaiIdの配列の配列)
            piYama: undefined # 山牌(PaiIdの配列)
        @state = 'INITIALIZED' # 現在の状態
        @tsumoPos = undefined # 次の自摸の位置
        @wanpaiPos = undefined # 王牌の一番右上牌の位置
        @nextDoraPos = undefined # 次のドラの位置
        @yamaState = undefined # 山の状態(YamaStateの配列)
        @pkDora = [] # ドラの配列(PaiKind)
        @piDoraIndicator = [] # ドラ表示牌の配列(PaiId)
        @isMaster = true # ゲームマスターかどうか
        @curPlayer = undefined # 現在のプレイヤー番号
        @kyoku = 0 # 局番号(0はじまり)
        @honba = 0 # 本場（積み棒の数)
        @kyotaku = 0 # 供託点棒
        @bakaze = PaiKind.TON # 場風(PaiKind.TON/NAN/SHA/PEIのいずれか)
        @lastStehai = undefined # 最後の捨牌
        @record = # 記録された牌譜ファイルの内容とほぼ同一のもの
            version: 1000 # バージョン番号*1000
            rule: @rule
            kyoku: [] # 局ごとの情報（上がり牌姿など）
            haifu: []



    # 山廃の位置位置情報をインデックスに変換する.
    # @param yama プレイヤー番号
    # @param ton 右端からのトン数(0始まり)
    # @param top 上牌ならtrue
    # @return 山牌の位置(0-135)
    makePos: (yama,ton,top)-> cycle((-yama*34) + ton*2 + (if top then 0 else 1),PaiId.MAX)

    # 山牌の位置をわかりやすい情報に変換する.
    # @param pos 山廃の位置(0-135)
    # @return 位置情報( {yama: プレイヤー番号, ton: 右端からのトン数(0始まり), top: 上牌ならtrue} )
    splitPos: (pos)->
        pos = cycle(pos,PaiId.MAX)
        { yama: cycle(-(Math.floor(pos/34)),4), ton: Math.floor(pos%34/2), top: (pos%2==0) }

    tsumoFromYama: ->
        pi = @s.piYama[@tsumoPos]
        throw "tsumo must be closed! tsumoPos=#{@tsumoPos}" if @yamaState[@tsumoPos] != YamaState.CLOSED
        @yamaState[@tsumoPos] = YamaState.USED
        @tsumoPos = cycle(@tsumoPos+1,PaiId.MAX)
        pi

    # プレイヤーの秘密情報が見れるかどうかを返す.
    isOwner: (pl)-> @isMaster or @owner.idx == pl

    # ドラ表示牌からドラに変換する
    indicateDora: (pi)->PaiKind.next(PaiId.toKind(pi))

    # 残り枚数
    restPai: ->cycle(@wanpaiPos-@tsumoPos,PaiId.MAX)

    # 正しいStateかを判断する.
    # 引数は、Stateを複数指定できる。指定されていないStateの場合は、例外を投げる
    _validateState: ()->
        for st in arguments
            return if st == @state
        throw "invalid state, expects #{[].slice.apply(arguments)} but #{@state}"

    # 次のプレイヤー番号を返す.
    nextPlayer: (pl,n=1)->cycle(pl+n,4)

    # 最後の捨牌を返す(捨牌、搶槓牌が対象).
    lastSutehai: ->@lastStehai

    # cycle()の人数省略バージョン
    cycle: (pl)->cycle(pl,@rule.playerNum)


    ###
    # 牌譜コマンド１つ分すすめる.
    #
    # TODO: ロン>ポン>チーの優先順位はリアルタイムでクライアントの選択がキャンセルされる例外
    # TODO: 場決めの牌選択はリアルタイム例外
    #
    # BAGIME       : 場決め
    # OYAGIME_DICE : 親決めのダイス
    # INIT_KYOKU   : 局の初期化
    # WAREME_DICE  : 割れ目を決めるサイコロを振る
    # HAIPAI       : 配牌を一人分配る
    # DAHAI        : 打牌
    # TSUMO        : 自摸
    # CHI          : チー
    # PON          : ポン
    # TSUMO_AGERI  : ツモ和了り
    # RON          : ロン和了り
    # RYUKYOKU     : 流局
    # KYUSHU       : 九種九牌
    # SUFU_RENDA   : 四風子連打
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
            @record.haifu.push com
            @choises = func.apply( this, [com] )
            #if @choises.length > 1
            #    puts c for c in @choises
            @choises
        else
            throw "invalid type in Game.progress(), type=#{com.type}"

    ###
    # 各牌譜コマンドに対応する関数群.
    #
    # '<MASTER>'と付いているものは、オプションパラメータで、ない場合はゲームマスターがその場で決めるもの。
    # サイコロの目や配牌がそれにあたる。
    #
    # '<PLAYER>'と付いているものは、オプションパラメータで、マスターからの選択肢の時点では存在しないが、
    # 打牌時の手出し位置などがそれにあたる。（プレイヤーは理牌情報の詳細を通知しないため）
    ###
    commandFunc:
        # 場決めの牌を選択する
        # comパラメータ
        #   pl: なし
        #   pub: 場決めの順番( 初期化プレイヤー番号の要素数4の配列 )
        #   sec: なし
        BAGIME: (com)->
            if @isMaster and not com.pub
                com.pub = [0,1,2,3]
            @_validateState 'INITIALIZED'
            for i in [0...com.pub.length]
                @p[i] = @initialPlayers[com.pub[i]]
                @p[i].idx = i
            @state = 'INIT_KYOKU'
            if @isMaster
                @nextKyoku 'init'
        # 局の初期化.
        # 基本的にどの状態から呼ばれても局の開始として初期化できるようにしてある。
        # これは、牌譜再生のときに指定された局にとべるようにするため。
        # comパラメータ
        #   pl: なし
        #   pub:
        #     bakaze: 場風(PaiKind.TON,NAN,SHA,PAIのいずれか)
        #     kyoku: 局番号(0はじまり)
        #     honba: 本場
        #     score: 各プレイヤーのスコア(長さ４の配列、インデックスは初期プレイヤー番号）
        #     kyotaku: 供託点
        #   sec:
        #     piYama: <MASTER>山牌(PaiIdの配列)
        INIT_KYOKU: (com)->
            @_validateState 'INIT_KYOKU', 'AGARI', 'NAKI', 'KYUSHU', 'SUFU_RENDA'
            # プレイヤー情報の初期化
            for player in @p
                player.s.piTehai = []
                player.piKawahai = []
                player.kawahaiState = []
                player.furo = []
                player.isFirst = true
            @yamaState = (YamaState.CLOSED for i in [0...PaiId.MAX])
            @bakaze = com.pub.bakaze
            @kyooku = com.pub.kyoku
            @kyotaku = com.pub.kyotaku
            @honba = com.pub.honba
            @state = 'WAREME_DICE'
            if @isMaster
                if com.sec and com.sec.piYama
                    @s.piYama = com.sec.piYama
                else
                    @s.piYama = _.shuffle([0...PaiId.MAX])
                    com.sec = { piYama: @s.piYama }
                [{type:'WAREME_DICE'}]
        # 割れ目決めのサイコロを振る.
        # comパラメータ
        #   pl: なし
        #   pub:
        #     dice: <MASTER>サイコロの目([サイコロ１の目,サイコロ２の目])
        #     piDoraIndicator: <MASTER>ドラ表示牌の配列(PaiId)
        #   sec: なし
        WAREME_DICE: (com)->
            @_validateState 'WAREME_DICE'
            # サイコロの情報がなかったら、ここで振る
            com.pub ?= {}
            if @isMaster and not com.pub.dice
                com.pub.dice = [Math.floor(Math.random()*6)+1, Math.floor(Math.random()*6)+1]
            @dice = com.pub.dice.slice()
            dice = @dice[0]+@dice[1]
            # 自摸/王牌/ドラ表示牌の位置設定
            @tsumoPos = @makePos(dice-1, dice, true )
            @wanpaiPos = cycle(@tsumoPos-7*2,PaiId.MAX)
            @nextDoraPos = cycle(@tsumoPos-5*2,PaiId.MAX)
            # ドラをめくる
            if @isMaster and not com.pub.piDoraIndicator
                com.pub.piDoraIndicator = [@s.piYama[@nextDoraPos]]
            @yamaState[@nextDoraPos] = YamaState.OPENED
            @piDoraIndicator = com.pub.piDoraIndicator
            @pkDora = [@indicateDora(@piDoraIndicator[0])]

            @curPlayer = 0
            @state = 'HAIPAI'
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
        # 配牌（一人分）.
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub: 配られた手牌の数
        #   sec: 手牌（PaiIdの配列)
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
        # 打牌.
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub:
        #     pi: 捨てた牌(PaiId)
        #     idx: 捨てた牌の手出し位置
        #   sec: なし
        DAHAI: (com)->
            @_validateState 'DAHAI'
            player = @p[com.pl]
            pi = com.pub.pi
            if @isOwner(com.pl)
                player.s.piTehai = _.without( player.s.piTehai, pi )
            player.tehaiNum -= 1
            player.piKawahai.push pi
            player.kawahaiState.push KawaState.NORMAL
            @lastStehai = pi
            @state = 'NAKI'
            if @isMaster
                # 流局処理
                if @restPai() <= 0
                    return [{type:'RYUKYOKU'}]
                # 四風子連打
                if player.idx == 3
                    sufu = true
                    for p in @p
                        unless p.piKawahai.length == 1 and [PaiKind.TON,PaiKind.NAN,PaiKind.SHA,PaiKind.PEI].indexOf(PaiId.toKind(p.piKawahai[0])) >= 0
                            sufu = false
                    if sufu
                        return [{type:'SUFU_RENDA'}]
                # 捨牌候補を決める
                pl = @nextPlayer(@curPlayer,1)
                result= [{type:'TSUMO', pl:pl, sec:@tsumoFromYama()}]
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, true ) )
                pl = @nextPlayer(@curPlayer,2)
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, false ) )
                pl = @nextPlayer(@curPlayer,3)
                result = result.concat( @chooseNaki( pl, @p[pl].s.piTehai, com.pub.pi, false ) )
                result
        # 自摸.
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub: なし
        #   sec: ツモった牌(PaiId)
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
        # チー.
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub: 使用した牌(PaiIdの長さ２の配列）
        #   sec: なし
        CHI: (com)->
            @_validateState 'NAKI'
            piLast = @lastSutehai()
            @p[@curPlayer].kawahaiState[@p[@curPlayer].kawahaiState.length] = KawaState.NAKI # 牌の状態を変える
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
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub: 使用した牌(PaiIdの長さ２の配列）
        #   sec: なし
        PON: (com)-> @commandFunc['CHI'].apply( this, [com] ) # TODO: とりあえずチーとおなじ
        # カン
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub: 使用した牌(PaiIdの長さ３の配列）
        #   sec: なし
        KAN: (com)->
            com.pub.shift()
            @commandFunc['CHI'].apply( this, [com] ) # TODO: とりあえずチーとおなじ
        # ツモ和了り
        # comパラメータ
        #   pl: プレイヤー番号
        #   pub:
        #     piTehai: 手牌(PaiIdの配列）
        #     yaku: 役（Yakuの配列）
        #     score: 点数情報( jan.calcYakuの返り値のscoreとおなじ)
        #   sec: なし
        TSUMO_AGARI: (com)->
            @_validateState 'DAHAI','NAKI' # DAHAIはTUSMOAGARI, NAKIはRONのときのみ
            if com.type == 'RON'
                from = @curPlayer
            @agari(com.pl,com.pub.score,from)
            @state = 'AGARI'
            if @isMaster
                @nextKyoku 'oyanagare'
        # ロン
        RON: (com)-> @commandFunc['TSUMO_AGARI'].apply( this, [com] ) # TODO: とりあえずツモと一緒
        # 流局
        RYUKYOKU: (com)->
            # @honba += 1
            if @isMaster
                @nextKyoku 'oyanagare'
        # 九種九牌
        KYUSHU: (com)->
            @_validateState 'DAHAI'
            @state = 'KYUSHU'
            @nextKyoku 'oyanagare'
        # 九種九牌
        SUFU_RENDA: (com)->
            @_validateState 'NAKI'
            @state = 'SUFU_RENDA'
            @nextKyoku 'oyanagare'

    #========================================================
    # ここから下は、ゲームマスターの時しか使わない関数
    #========================================================

    # 和了りの処理
    # @param from 振り込んだ人のプレイヤー番号、ツモの場合はundefined
    # @param score 点数情報(jan.calcYakuの返り値のscoreとおなじ)
    agari: (pl,score,from)->
        if from
            # ロン和了り
            @p[from].score -= score[1] + @honba * 300
            @p[pl].score += score[1] + @honba * 300
        else
            # ツモ和了り
            total = 0
            for pl2 in [0...4]
                continue if pl2 == pl # 自分は飛ばす
                if pl == 0
                    # 親の支払い
                    total += score[2] + @honba * 100
                    @p[pl2].score -= score[2] + @honba * 100
                else
                    # 子の支払い
                    total += score[3] + @honba * 100
                    @p[pl2].score -= score[3] + @honba * 100
            @p[pl].score += total

    # 次の局のINIT_KYOKUコマンドを返す.
    # @param type 流れのタイプ( 'init':半荘のはじまり, 'oyanagare':親流れの流局 のいずれか)
    nextKyoku: (type)->
        if type == 'oyanagare'
            @kyoku = @kyoku + 1
            if @kyoku >= 4
                @bakaze += 1
                @kyoku = 0

        [{type:'INIT_KYOKU',pub:{ bakaze:@bakaze, kyoku:@kyoku, honba:@honba, score:_.pluck(@p,'score'), kyotaku:@kyotaku }}]

    # ツモったあとの自摸/打牌/リーチ/暗槓などの選択を行う
    chooseDahai: (player)->
        # 通常の打牌
        result = player.s.piTehai.map (pi,i)->
            {type:'DAHAI', pl:player.idx, pub:{pi:pi} }
        # ツモ和了の判定
        if jan.splitMentsu( PaiId.toKind( player.s.piTehai ) ).length > 0
            agari = jan.calcYaku( PaiId.toKind(player.s.piTehai), player.furo, @calcYakuOption({tsumo:true}) )
            result.unshift
                type: 'TSUMO_AGARI'
                pl: player.idx
                pub:
                    piTehai: player.s.piTehai
                    yaku: agari.yaku
                    score: agari.score
        # 初巡なら、９種９牌の判定
        if player.isFirst
            if _.uniq( PaiId.toKind(player.s.piTehai) ).filter( (pk)->PaiKind.isYaochu(pk) ).length > 9
                result.push {type:'KYUSHU', pl:player.idx, pub:player.s.piTehai}
        result

    # 鳴きの選択を行う
    # @return 牌譜コマンドの配列
    chooseNaki: (pl,piTehai,piKawa,enableChi)->
        paiTable = PaiKind.toPaiTable(PaiId.toKind(piTehai))
        pkKawa = PaiId.toKind(piKawa)
        result = []
        # チー
        if enableChi
            pkNakiList = []
            # 鳴けるパターンを探す
            if PaiKind.isShuntsuStarter(pkKawa) and paiTable[pkKawa+1]>0 and paiTable[pkKawa+2]
                pkNakiList.push [pkKawa+1, pkKawa+2]
            if PaiKind.isShuntsuStarter(pkKawa-1) and  paiTable[pkKawa-1]>0 and paiTable[pkKawa+1]
                pkNakiList.push [pkKawa-1, pkKawa+1]
            if PaiKind.isShuntsuStarter(pkKawa-2) and  paiTable[pkKawa-2]>0 and paiTable[pkKawa-1]
                pkNakiList.push [pkKawa-2, pkKawa-1]
            # pkNakiListの組み合わせを満たす,組み合わせを調べあげる
            piChiList = pkNakiList.map (pkNaki)=>
                piCombi = pkNaki.map (pk)-> _.filter( piTehai, (pi)->PaiId.toKind(pi) == pk )
                janutil.combinate( piCombi )
            for chi in _.flatten(piChiList,true)
                result.push {type:'CHI', pl:pl, pub:chi}

        # ポン
        if paiTable[pkKawa]>=2
            piCombi =  _.filter( piTehai, (pi)->PaiId.toKind(pi) == pkKawa )
            if piCombi.length == 2
                piPonList = [piCombi]
            else
                piPonList = [ [piCombi[0],piCombi[1]], [piCombi[0],piCombi[2]], [piCombi[1], piCombi[2]] ]
            for pon in piPonList
                result.push {type:'PON', pl:pl, pub:pon}

        # 大明カン
        if paiTable[pkKawa]>=3
            kan = piTehai.filter (pi)->PaiId.toKind(pi) == pkKawa
            result.push {type:'KAN', pl:pl, pub:kan}

        # ロン
        pkTehaiAll = PaiId.toKind( piTehai.concat( [piKawa] ) )
        if jan.splitMentsu( pkTehaiAll ).length > 0
            player = @p[pl]
            agari = jan.calcYaku( pkTehaiAll, player.furo, @calcYakuOption({tsumo:true} ))
            result.unshift
                type: 'RON'
                pl: pl
                pub:
                    piTehai: player.s.piTehai
                    yaku: agari.yaku
                    score: agari.score

        result

    calcYakuOption: (opt)->
        _.extend opt,
            hoge: false

    #========================================================
    # ここから下は、クラスメソッド
    #========================================================

    # チート山牌を作成する
    @makeCheatYama: (piTehai, dice=[1,1])->
        piYama = new Array(PaiId.MAX)
        diceNum = dice[0]+dice[1]
        pos = cycle( -(diceNum-1)*34+diceNum*2, PaiId.MAX )
        # 牌を山に置く
        putPai = (pi)->
            piYama[pos] = pi
            pos = cycle( pos+1, PaiId.MAX )

        for i in [0...3] # 3回
            for pl in [0...piTehai.length]
                for j in [0...4] # ４枚ずつ
                    putPai piTehai[pl].shift()
        restNum = _.reduce( piTehai, ((i,a)->i+a.length), 0 )
        for i in [0...restNum]
            for pl in [0...piTehai.length]
                putPai piTehai[pl].shift()

        # 使ってない牌を調べる
        usedTable = [0...PaiId.MAX]
        for pi in piYama
            usedTable[pi] = false if pi
        usedTable = _.without( usedTable, false )

        # 空きを使っていない牌で埋める
        for pi,i in piYama
            piYama[i] = usedTable.shift() unless pi

        piYama

    # チート牌譜ファイルを作成する.
    # Game.makeCheatHaifu( [PaiId.uniq(PaiId.fromKind(PaiKind.fromReadable('東東東南南南西西西北北北白'))),[],[],[]] )
    @makeCheatHaifu: (cheat)->
        piTehai = (PaiId.uniq( PaiId.fromKind(PaiKind.fromReadable(str)) ) for str in cheat.pai)
        dice = cheat.dice
        piYama = Game.makeCheatYama( piTehai, dice )
        {
            haifu: [
                {"type":"BAGIME","pub":[0,1,2,3]},
                {"type":"INIT_KYOKU","sec":{"piYama":piYama},pub:{kyoku:0,bakaze:PaiKind.TON,kyotaku:0,score:[25000,25000,25000,25000],honba:0}},
                {"type":"WAREME_DICE","pub":{dice:dice}}
            ]
        }

exports.Game = Game
