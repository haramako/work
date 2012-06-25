enchant();

var game;

// 表示する座標に、画像の中心をあわせるようにするモンキーパッチ
Sprite.prototype.center = function(){
  this._element.style['margin-top'] = -this._width / 2;
  this._element.style['margin-left'] = -this._height / 2;
  return this;
};

// 自機
var MyChar = Class.create( Sprite, {
  // 初期化
  initialize: function(){
    Sprite.call( this, 60, 60 );
    this.center();
    this.shootWait = 0;
    this.image = game.assets['mychar.png'];
    this.state = 0;
    this.wait = 0;
  },
  // １フレームごとの処理
  onenterframe: function(){
    // 移動する
    var speed = 8;
    if( game.input.up ){ this.y -= speed; }
    if( game.input.down ){ this.y += speed; }
    if( game.input.left ){ this.x -= speed; }
    if( game.input.right ){ this.x += speed; }

    // 弾を撃つ
    if( this.shootWait <= 0 ){
      if( game.input.a ){
        var shoot = new MyShoot();
        shoot.moveTo( this.x, this.y-30 );
        this.scene.myshoots.addChild( shoot );
      }
      this.shootWait = 3;
    }else{
      this.shootWait -= 1;
    }

    // 敵の弾との当たり判定
    if( this.state == 0 ){
      var shoots = this.scene.enshoots.childNodes;
      for( var i=0; i<shoots.length; i++ ){
        var s = shoots[i];
        if( Math.abs( s.x - this.x ) < 8 && Math.abs( s.y - this.y ) < 8 ){
          s.parentNode.removeChild( s );
          this.state = 1;
          this.wait = 60;
          break;
        }
      }
    }

    //
    if( this.state == 1 ){
      this.wait -= 1;
      if( this.wait % 2 == 1 ){
        this._element.style.visibility = 'hidden';
      }else{
        this._element.style.visibility = 'visible';
      }
      if( this.wait <= 0 ){
        this.state = 0;
      }
    }
    
  }
});

// 自分の弾
var MyShoot = Class.create( Sprite, {
  // 初期化
  initialize: function(){
    Sprite.call( this, 16, 16 );
    this.center();
    this.image = game.assets['bullet1.png'];
  },
  // １フレームごとの処理
  onenterframe: function(){
    this.moveTo( this.x, this.y - 32 );
    if( this.y < 0 ){
      this.parentNode.removeChild( this );
    }
  }
});

var Enemy1 = Class.create( Sprite, {
  // 初期化
  initialize: function(){
    Sprite.call( this, 60, 60 );
    this.center();
    this.image = game.assets['mychar.png'];
  },
  // １フレームごとの処理
  onenterframe: function(){
    // 移動
    this.moveTo( this.x, this.y+4 );

    // 弾を打つ
    if( Math.random() < 0.2 ){
      var shoot = new EnemyShoot();
      shoot.moveTo( this.x, this.y );
      var me = this.scene.me;
      var dx = me.x - shoot.x;
      var dy = me.y - shoot.y;
      var len = Math.sqrt( dx*dx + dy*dy );
      shoot.vx = dx / len * 8;
      shoot.vy = dy / len * 8;
      this.scene.enshoots.addChild( shoot );
    }
    
    // 画面外に出たら消える
    if( this.y > 640 ){
      this.parentNode.removeChild( this );
      return;
    }
    
    // 自機の弾との当たり判定
    var shoots = this.scene.myshoots.childNodes;
    for( var i=0; i<shoots.length; i++ ){
      var s = shoots[i];
      if( Math.abs( s.x - this.x ) < 32 && Math.abs( s.y - this.y ) < 32 ){
        this.parentNode.removeChild( this );
        s.parentNode.removeChild( s );
        return;
      }
    }
  }
});

// 敵の弾
var EnemyShoot = Class.create( Sprite, {
  // 初期化
  initialize: function(){
    Sprite.call( this, 16, 16 );
    this.center();
    this.image = game.assets['bullet1.png'];
    this.frame = 12;
  },
  // １フレームごとの処理
  onenterframe: function(){
    // 移動する
    this.moveTo( this.x + this.vx, this.y + this.vy );
    // 画面外に出たら消える
    if( this.x < 0 || this.x > 480 || this.y < 0 || this.y > 640 ){
      this.parentNode.removeChild( this );
    }
  }
});

window.onload = function(){
  game = new Game(480,640);
  game.preload( 'bear.gif', 'mychar.png', 'shoot.png', 'bullet1.png' );
  
  game.onload = function(){
    
    var scene = new Scene();
    scene.backgroundColor = '#ddd';
    game.pushScene( scene );

    scene.me = new MyChar();
    scene.me.moveTo( 240, 540 );
    scene.addChild( scene.me );

    scene.enemies = new Group();
    scene.addChild( scene.enemies );

    scene.myshoots = new Group();
    scene.addChild( scene.myshoots );

    scene.enshoots = new Group();
    scene.addChild( scene.enshoots );

    scene.onenterframe = function(){
      if( Math.random() < 0.03 ){
        var enemy = new Enemy1();
        enemy.moveTo( Math.random()*480, 0 );
        scene.enemies.addChild( enemy );
      }
    };
    
    var pad = new enchant.ui.Pad();
    pad.moveTo( 20, 500 );
    scene.addChild( pad );
    
    game.keybind('Z'.charCodeAt(0), 'a' );
    game.keybind('X'.charCodeAt(0), 'b' );

  };
  game.start();
};
