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

        # イベントハンドラの設定
        @takuDiv.on 'click', (ev)=>
            cls = $(ev.target).attr('class')
            if cls == 'hai'
                @onHaiClick( $(ev.target).data('pi') )

        @choiseDiv.on 'click', (ev)=>
            cls = $(ev.target).attr('class')
            if cls == 'choise'
                @onChoiseClick( parseInt( $(ev.target).data('choise'),10) )

        @game = new game.Game([],{})

    showGame: ()->
        @stateDiv.text( "state=#{@game.state} curPlayer=#{@game.curPlayer}" )
        for player,i in @game.p
            @tehaiDiv[i].removeClass('active_dahai')
            @tehaiDiv[i].removeClass('active')
            if @game.curPlayer == i
                if @game.state == 'DAHAI'
                    @tehaiDiv[i].addClass 'active_dahai'
                else
                    @tehaiDiv[i].addClass 'active'

            html = @haiToHtml( player.s.piTehai )
            html += ' '+@mentsuToHtml( mentsu ) for mentsu in player.furo
            @tehaiDiv[i].html(html)

            # 6枚ごとに分けて川牌を表示
            html = ''
            piFeeded = []
            piKawahai = player.piKawahai.slice(0)
            while piKawahai.length > 0
                piFeeded.push piKawahai[0..5]
                piKawahai = piKawahai[6..-1]
            html += @haiToHtml( pis )+"<br/>" for pis in piFeeded

            @kawaDiv[i].html(html)

        @choiseDiv.empty()
        for c,i in @game.choises
            div = $('<div class="choise">').html( ''+i+':'+JSON.stringify(c) ).data({choise:i})
            @choiseDiv.append( div )

    send: (com,skip=true)->
        @game.progress com
        @haifuDiv.append( JSON.stringify(com)+",\n" )

        # 理牌する
        if com.type == 'DAHAI' or com.type == 'HAIPAI'
            player = @game.p[com.pl]
            player.s.piTehai = _.sortBy(player.s.piTehai, (a,b)->a-b)

        # skipが真で選択肢がないなら勝手にすすめる
        if skip and @game.choises.length == 1
            @send @game.choises[0]
        else
            @showGame()

    onHaiClick: (pi)->
        if @game.state == 'DAHAI'
            player = @game.p[@game.curPlayer]
            if player.s.piTehai.indexOf(pi) >= 0
                @send { type:'DAHAI', pl:@game.curPlayer, pub:{pi:pi} }

    onChoiseClick: (idx)->
        @send @game.choises[idx]

    # 牌をHTMLに変換する.
    # @param pi PaiId(もしくはPaiIdの配列)
    # @param feed 折り返し枚数
    # @return html文字列
    haiToHtml: (pi,feed)->
        if typeof pi == 'number'
            pk = jan.PaiId.toKind(pi)
            img= if pk >= 10 then ''+pk else ('0'+pk)
            '<img class="hai" data-pi="'+pi+'" src="./img/'+img+'.gif" />'
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
        $.get param.haifu, (data)->
            window.game = game = new Game()
            for com in data
                game.send com, false
    else
        window.game = game = new Game()

    puts 'ready'
