enchant()

window.onload = ->
    game = new Game(320,320);
    game.preload( 'bear.gif' )
    game.onload = ->

        scene = new Scene()
        scene.backgroundColor = '#ddd'
        game.pushScene scene

        spr = new Sprite(20,30)
        spr.image = game.assets['bear.gif']
        spr.count = 0
        spr.scaleX = 2
        spr.scaleY = 2
        spr.addEventListener 'enterframe', ->
            spr.count += 1
            x = spr.x
            y = spr.y
            y -= 4 if game.input.up
            y += 4 if game.input.down
            x -= 4 if game.input.left
            x += 4 if game.input.right
            if game.input.up or game.input.down or game.input.left or game.input.right
                spr.frame = (spr.count/4|0) % 3
            else
                spr.frame = 0
            spr.moveTo x, y
        scene.addChild( spr )

        pad = new enchant.ui.Pad()
        pad.moveTo 20, 200
        scene.addChild pad

    game.start()


