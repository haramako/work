(function() {
  var AdminSession, DEFAULT_PORT, Server, Session, express, game, server, utils, websocket, _;

  _ = require('underscore');

  websocket = require('websocket');

  express = require('express');

  utils = require('battle_ship/utils');

  game = require('battle_ship/game');

  /*
  # ゲームサーバー.
  #
  */

  DEFAULT_PORT = 30001;

  /*
  #
  */

  Server = (function() {
    /*
        # コンストラクタ.
        # opt:
        #   port: ポート(Default:20001)
    */
    function Server(opt) {
      var _this = this;
      if (opt == null) opt = {};
      this.opt = _.extend(opt, {
        port: DEFAULT_PORT
      });
      this.httpServer = express.createServer();
      this._setupHttp();
      this.httpServer.listen(this.opt.port);
      this.sv = new websocket.server({
        httpServer: this.httpServer,
        autoAcceptConnections: false
      });
      this.sv.on('request', function(request) {
        var conn, session, uuid;
        puts("request from " + request.remoteAddress);
        switch (request.resource) {
          case '/admin':
            puts('admin-client login');
            conn = request.accept('janyuhai-game-admin', request.origin);
            return new AdminSession(conn, _this);
          default:
            conn = request.accept('janyuhai-game', request.origin);
            uuid = request.resource.substring(1);
            puts("login from " + request.remoteAddress + ", uuid=" + uuid);
            session = Session.findByUuid(uuid);
            return session.addConnection(uuid, conn);
        }
      });
      this.sessions = {};
      this.sessionsByPlayerId = {};
    }

    Server.prototype.addSession = function(session) {
      var player, _i, _len, _ref, _results;
      this.sessions[session.sid] = session;
      _ref = session.players;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        player = _ref[_i];
        _results.push(this.sessionsByPlayerId[player.uuid] = session);
      }
      return _results;
    };

    Server.prototype._setupHttp = function() {
      var sv;
      sv = this.httpServer;
      sv.use(express.logger());
      sv.use(express.methodOverride());
      return sv.use(express.bodyParser());
    };

    return Server;

  })();

  /*
  # 管理セッション
  */

  AdminSession = (function() {

    function AdminSession(conn, server) {
      var _this = this;
      this.server = server;
      this.conn = conn;
      this.conn.on('message', function(msg) {
        var agame, p, players, result, s, sid, _ref;
        if (msg.type !== 'utf8') return;
        msg = JSON.parse(msg.utf8Data);
        switch (msg.t) {
          case 'CREATE_SESSION':
            agame = new game.Game();
            s = new Session(msg.sid, msg.pids, agame);
            _this.server.addSession(s);
            return _this.conn.send(JSON.stringify({
              t: 'CREATE_SESSION_R',
              id: msg.id
            }));
          case 'SESSION_LIST':
            result = [];
            _ref = _this.server.sessions;
            for (sid in _ref) {
              s = _ref[sid];
              players = (function() {
                var _i, _len, _ref2, _results;
                _ref2 = s.players;
                _results = [];
                for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
                  p = _ref2[_i];
                  _results.push(p.uuid);
                }
                return _results;
              })();
              result.push({
                sid: sid,
                players: players
              });
            }
            return _this.conn.send(JSON.stringify({
              t: 'SESSION_LIST_R',
              id: msg.id,
              sessions: result
            }));
          default:
            throw "invalid msg.t=" + msg.t;
        }
      }).on('close', function(reason, desc) {
        return puts("close admin-session readon=" + reason + ", desc=" + desc);
      });
    }

    return AdminSession;

  })();

  /*
  # セッション（一つの卓の１ゲームに対応）
  */

  Session = (function() {

    function Session(sid, uuids, _game) {
      var i, p, uuid, _i, _len, _ref;
      this.sid = sid;
      this.players = (function() {
        var _len, _results;
        _results = [];
        for (i = 0, _len = uuids.length; i < _len; i++) {
          uuid = uuids[i];
          _results.push({
            idx: i,
            uuid: uuid,
            conn: void 0
          });
        }
        return _results;
      })();
      _ref = this.players;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        Session.sessions[p.uuid] = this;
      }
      this.choises = [];
      this.game = _game;
      this.finishCount = 0;
    }

    Session.prototype.addConnection = function(uuid, conn) {
      var player,
        _this = this;
      player = _.find(this.players, function(p) {
        return p.uuid === uuid;
      });
      player.conn = conn;
      conn.send(JSON.stringify({
        t: 'LOGIN',
        idx: player.idx
      }));
      if (this.game.state === game.GAME_STATE.INIT) {
        conn.send(JSON.stringify({
          t: 'INIT_GAME'
        }));
      } else {
        conn.send(JSON.stringify({
          t: 'START_GAME',
          game: this.game.serialize()
        }));
      }
      return conn.on('message', function(msg) {
        var p, _i, _j, _len, _len2, _ref, _ref2, _results, _results2;
        if (msg.type !== 'utf8') return;
        msg = JSON.parse(msg.utf8Data);
        player = _.find(_this.players, function(p) {
          return p.conn === conn;
        });
        switch (msg.t) {
          case 'INIT_GAME_R':
            _this.finishCount += 1;
            _this.game.fields[msg.pl].ships = msg.ships;
            if (_this.finishCount >= 2) {
              _this.game.state = game.GAME_STATE.MAIN;
              _ref = _this.players;
              _results = [];
              for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                p = _ref[_i];
                _results.push(p.conn.send(JSON.stringify({
                  t: 'START_GAME',
                  game: _this.game.serialize()
                })));
              }
              return _results;
            }
            break;
          case 'ATTACK':
            _this.game.fields[1 - msg.pl].attack(msg.x, msg.y);
            _ref2 = _this.players;
            _results2 = [];
            for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
              p = _ref2[_j];
              _results2.push(p.conn.send(JSON.stringify({
                t: 'UPDATE',
                game: _this.game.serialize()
              })));
            }
            return _results2;
            break;
          default:
            throw "invalid msg.t=" + msg.t;
        }
      }).on('close', function(reason, desc) {
        player = _.find(_this.players, function(p) {
          return p.uuid === uuid;
        });
        player.conn = void 0;
        return puts(reason, desc);
      });
    };

    Session.findByUuid = function(uuid) {
      return this.sessions[uuid];
    };

    Session.sessions = {};

    return Session;

  })();

  server = new Server();

}).call(this);
