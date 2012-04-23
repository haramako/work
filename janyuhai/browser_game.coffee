# nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
    eval('var exports, global; exports = {}; window.browser_game = exports; global = window;')

_ = require 'underscore'
janutil = require './janutil'
jan = require './jan'
game = require './game'

class Game
    constructor: ()->
        # HTMLエレメントの取得
        @takuDiv = $('#taku')
        @stateDiv = $('#state')
        @tehaiDiv = ($("#tehai#{i}") for i in [0..3])
        @kawaDiv = ($("#kawa#{i}") for i in [0..3] )
        @choiseDiv = $("#choises")
        @haifuDiv = $('#haifu')
        @autoplay = [false,true,true,true]

        # イベントハンドラの設定
        @takuDiv.on 'click', (ev)=>
            cls = $(ev.target).attr('class')
            if cls == 'hai'
                @onHaiClick( $(ev.target).data('pi') )
            else if cls == 'autoplay'
                idx = parseInt( $(ev.target).data('idx'), 10 )
                @autoplay[idx] = !@autoplay[idx]
            true

        @choiseDiv.on 'click', (ev)=>
            cls = $(ev.target).attr('class')
            if cls == 'choise'
                @onChoiseClick( parseInt( $(ev.target).data('choise'),10) )
            true

        @game = new game.Game(game.GameMode.MASTER, [],{})

    showGame: ()->
        # ログの表示
        @haifuDiv.text( janutil.prettyPrint(@game.record) )

        # 状態の表示
        pos = @game.splitPos(@game.tsumoPos)
        @stateDiv.html "state=#{@game.state} curPlayer=#{@game.curPlayer} tsumoPos=#{@game.tsumoPos}\n"+
            "残り#{@game.restPai()}枚 ツモ位置[#{'東南西北'[pos.yama]},#{pos.ton},#{if pos.top then '上' else '下'}]\n"+
            "ドラ表示牌: #{@haiToHtml(@game.piDoraIndicator)}"

        for player,i in @game.p
            @tehaiDiv[i].removeClass('active_dahai')
            @tehaiDiv[i].removeClass('active')
            if @game.curPlayer == i
                if @game.state == 'DAHAI'
                    @tehaiDiv[i].addClass 'active_dahai'
                else
                    @tehaiDiv[i].addClass 'active'

            # 手牌/副露牌を表示
            html = @haiToHtml( player.s.piTehai )
            html += ' '+@mentsuToHtml( mentsu ) for mentsu in player.furo
            @tehaiDiv[i].html(html)

            # 名前を表示
            nameDiv = $("<div>").text("P[#{player.initIdx}]　")
            $('<input type="checkbox" class="autoplay" data-idx="'+i+'" '+(if @autoplay[i] then 'checked="checked"' else'')+'">自動</input>').appendTo(nameDiv)
            nameDiv.append("　#{player.score}点")
            @tehaiDiv[i].prepend(nameDiv)

            # 6枚ごとに分けて川牌を表示
            html = ''
            for pi,n in player.piKawahai
                if player.kawahaiState[n] == game.KawaState.NAKI
                    html += @haiToHtml( pi, 'naki' )
                else if player.kawahaiState[n] == game.KawaState.REACH
                    html += @haiToHtml( pi, 'reach' )
                else
                    html += @haiToHtml( pi )
                html += "<br/>" if n % 6 == 5

            @kawaDiv[i].html(html)

        @choiseDiv.empty()
        for c,i in @game.choises
            div = $('<div class="choise">').html( ''+i+':'+JSON.stringify(c) ).data({choise:i})
            @choiseDiv.append( div )

    send: (com,skip=true,display=true,autoplay=true)->
        @game.progress com

        # 理牌する
        if com.type == 'DAHAI' or com.type == 'HAIPAI'
            player = @game.p[com.pl]
            player.s.piTehai.sort (a,b)->a-b

        # skipが真で選択肢がないなら勝手にすすめる
        if skip and @game.choises.length == 1
            @send @game.choises[0]
        else
            # 自動プレイならすすめる
            choises = _.filter( @game.choises, (c)=>( c.pl? and not @autoplay[c.pl] ) )
            if autoplay and choises.length == 0
                @send @game.choises[0]
            else
                # 選択肢がのこってるなら選択する
                @showGame() if display

    onHaiClick: (pi)->
        if @game.state == 'DAHAI'
            player = @game.p[@game.curPlayer]
            if player.s.piTehai.indexOf(pi) >= 0
                @send { type:'DAHAI', pl:@game.curPlayer, pub:{pi:pi} }

    onChoiseClick: (idx)->
        @send @game.choises[idx]

    # 牌をHTMLに変換する.
    # @param pi PaiId(もしくはPaiIdの配列)
    # @param cls クラス
    # @return html文字列
    haiToHtml: (pi,cls)->
        if typeof pi == 'number'
            pk = jan.PaiId.toKind(pi)
            img= if pk >= 10 then ''+pk else ('0'+pk)
            if pi == jan.PaiId.MAN5_3 or pi == jan.PaiId.PIN5_3 or pi == jan.PaiId.SOU5_3
                img += 'r'
            c = 'hai'
            c += ' '+cls if cls
            '<img class="'+c+'" data-pi="'+pi+'" src="./img/'+img+'.gif" />'
        else
            pi.map( (piOne)=>@haiToHtml(piOne) ).join('')

    # 面子をHTMLに変換する
    # @param mentsu 対象のMentsuオブジェクト
    # @return html文字列
    mentsuToHtml: (mentsu)->
        @haiToHtml( mentsu.pis )

$(document).ready ->
    param = {}
    for s in document.location.search.substring(1).split('&')
        kv = s.split('=')
        param[kv[0]] = kv[1]
    if param.haifu
        $.getJSON param.haifu, (data)->
            window.g = g = new Game()
            unless data.version
                data = game.Game.makeCheatHaifu( data )
            for com in data.haifu
                g.send com, false, false, false
            g.showGame()

    else
        window.g = g = new Game()
        g.showGame()

    puts 'ready'
