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
        @choiseDiv = $("#choise")
        @haifuDiv = $('#haifu')

        # イベントハンドラの設定
        @takuDiv.on 'click', (ev)=>
            cls = $(ev.target).attr('class')
            if cls == 'hai'
                @onHaiClick( $(ev.target).data('pi') )
            else if cls == 'choise'
                @onChoiseClick( parseInt( $(ev.target).data('choise'),10) )

        # ゲームの開始
        @game = new game.Game([],{})
        haifu = JSON.parse '''
        [
        {"type":"BAGIME_SELECT","pub":[0,1,2,3]} ,
        {"type":"INIT_KYOKU","sec":{"piYama":[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,130,131,132,133,134,135]}} ,
        {"type":"WAREME_DICE","pub":[1,1]} ,
        {"type":"HAIPAI","pl":0,"sec":[0,1,2,3,16,17,18,19,32,33,34,35,48,52],"pub":14} ,
        {"type":"HAIPAI","pl":1,"sec":[4,5,6,7,20,21,22,23,36,37,38,39,49],"pub":13} ,
        {"type":"HAIPAI","pl":2,"sec":[8,9,10,11,24,25,26,27,40,41,42,43,50],"pub":13} ,
        {"type":"HAIPAI","pl":3,"sec":[12,13,14,15,28,29,30,31,44,45,46,47,51],"pub":13}
        ]
        '''
        # {"type":"DAHAI","pl":0,"pub":{"pi":0}}
        for com in haifu
            @game.progress com
        @showGame()

    showGame: ()->
        @stateDiv.text( "state=#{@game.state} curPlayer=#{@game.curPlayer}" )
        for player,i in @game.p
            html = "#{i}: "
            @tehaiDiv[i].attr('class','')
            if @game.curPlayer == i
                if @game.state == 'DAHAI'
                    @tehaiDiv[i].addClass 'active_dahai'
                else
                    @tehaiDiv[i].addClass 'active'

            html += @haiToHtml( player.s.piTehai )
            html += ' '+@mentsuToHtml( mentsu ) for mentsu in player.furo
            @tehaiDiv[i].html(html)
            html = @haiToHtml( player.piKawahai )

            @kawaDiv[i].html(html)

        @choiseDiv.empty()
        for c,i in @game.choises
            div = $('<div class="choise">').html( ''+i+':'+JSON.stringify(c) ).data({choise:i})
            @choiseDiv.append( div )

    send: (com)->
        @haifuDiv.append( JSON.stringify(com)+"\n" )
        @game.progress com
        if @game.choises.length == 1
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
    # @return html文字列
    haiToHtml: (pi)->
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
    window.game = game = new Game()
    puts 'ready'
