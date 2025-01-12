enchant()
Easing = enchant.Easing

game = null

# 中心に点を置く
Sprite.prototype.centered = ->
    @_element.style['margin-left'] = - @width / 2
    @_element.style['margin-top']  = - @height / 2
    @

# addEventListener() のエイリアス
EventTarget.prototype.on = EventTarget.prototype.addEventListener

# 0以上n未満の乱数を返す
rand = (n)-> Math.random() * n

# ゲームシーン
class GameScene extends Scene
    constructor: ->
        super
        @backgroundColor = '#000'
        @count = 0

        @fireworks = new Group
        @addChild @fireworks
        @chain = 0

    onenterframe: ->
        @chainCount -= 1
        if @chainCount <= 0 and @chain > 0
            if @chain > 3
                case @chain
                 when 4...6
                    info = new Info('た〜まや〜')
                 when 7...10
                    info = new Info('か〜ぎや〜')
                 when 10
                    info = new Info('よ、大統領')
                info.moveTo game.width / 2, game.height / 2
                @addChild info
            @chain = 0

        @count -= 1
        if @count <= 0
            firework = new Firework( 1.5+rand(3) )
            firework.x = rand(game.width)
            firework.y = game.height
            @fireworks.addChild firework
            @count = 10+rand(10)

    ontouchstart: (e)-> @ontouch e
    ontouchmove: (e)-> @ontouch e

    ontouch: (e)->
        for obj in @fireworks.childNodes
            if Math.abs(e.localX - obj.x) < 20 && Math.abs(e.localY - obj.y) < 20
                obj.explode(0)

    fireworkExploded: (chain)->
        @chainCount = 30
        if chain > @chain
            @chain = chain



# 花火
class Firework extends Sprite
    constructor: (speed)->
        super 20,30
        @image = game.assets['bear.gif']
        @centered()
        @size = 0
        @speed = speed
        @exploded = false
        @touchEnabled = false
        @chain = 0 # 連鎖数

    onenterframe: ->
        @y -= @speed

        for obj in @scene.fireworks.childNodes
            if obj != @ and !obj.exploded and @within( obj, @size )
                obj.explode(@chain)

        if @y < 0
            @parentNode.removeChild @

    explode: (chain)->
        return if @exploded
        @chain = chain+1
        for i in [0...16]
            fire = new Sprite(20,30)
            fire.image = game.assets['bear.gif']
            fire.centered()
            fire.x = @x
            fire.y = @y
            fire.tl.tween
                x: @x + Math.cos(i/16*Math.PI*2) * 100,
                y: @y - Math.sin(i/16*Math.PI*2) * 100
                easing: Easing.QUAD_EASEOUT
                opacity: 0
                time: 30
            .removeFromScene()
            @scene.addChild fire
        @exploded = true
        @speed = 0
        @visible = false
        @tl.tween
            size: 100
            easing: Easing.QUAD_EASEOUT
            time: 20
        .then => @parentNode.removeChild @

        @scene.fireworkExploded( @chain )

# た〜まや〜
class Info extends Label
    constructor: ->
        super
        @color = '#f00'
        @text = 'た〜まや〜!'
        @tl.tween
            time: 30
        .removeFromScene()

# エントリポイント
window.onload = ->
    game = new Game(320,480)
    game.preload( 'bear.gif' )
    game.onload = ->
        scene = new GameScene()
        game.pushScene scene

    game.start()
