enchant()

game = undefined

class Me
    constructor: ()->
        @count = 0
        @spr = new Sprite( 20, 30 )
        @spr.image = game.assets['bear.gif']
        @spr.scaleX = 2
        @spr.scaleY = 2
        @spr.addEventListener 'enterframe', =>
            @count += 1
            x = @spr.x
            y = @spr.y
            y -= 4 if game.input.up
            y += 4 if game.input.down
            x -= 4 if game.input.left
            x += 4 if game.input.right
            if game.input.up or game.input.down or game.input.left or game.input.right
                @spr.frame = (@count/4|0) % 3
            else
                @spr.frame = 0
            @spr.moveTo x, y


window.onload = ->
    game = new Game(480,640)
    game.preload( 'bear.gif' )
    game.onload = ->

        scene = new Scene()
        scene.backgroundColor = '#ddd'
        game.pushScene scene

        spr = new Me
        console.log( spr.spr )
        scene.addChild( spr.spr )

        pad = new enchant.ui.Pad()
        pad.moveTo 20, 500
        scene.addChild pad

    game.start()

