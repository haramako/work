#!/usr/bin/env coffee

_ = require 'underscore'
websocket = require 'websocket'
express = require 'express'
utils = require 'battle_ship/utils'
game = require 'battle_ship/game'

###
# ゲームサーバー.
#
###

DEFAULT_PORT = 30001

###
#
###
class Server
    ###
    # コンストラクタ.
    # opt:
    #   port: ポート(Default:20001)
    ###
    constructor: (opt={})->
        @opt = _.extend opt,
            port: DEFAULT_PORT

        # HTTPサーバーをつくる
        @httpServer = express.createServer()
        @_setupHttp()
        @httpServer.listen @opt.port

        # WebSocketサーバーをつくる
        @sv = new websocket.server( { httpServer: @httpServer, autoAcceptConnections: false })
        @sv
         .on 'request', (request)=>
            puts "request from #{request.remoteAddress}"
            switch request.resource
             when '/admin' # 管理セッション
                puts 'admin-client login'
                conn = request.accept('janyuhai-game-admin',request.origin)
                new AdminSession(conn,this)
             else # 通常のセッション
                conn = request.accept('janyuhai-game',request.origin)
                uuid = request.resource.substring(1)
                puts "login from #{request.remoteAddress}, uuid=#{uuid}"
                session = Session.findByUuid(uuid)
                session.addConnection( uuid, conn )

        @sessions = {}
        @sessionsByPlayerId = {}

    addSession: (session)->
        @sessions[session.sid] = session
        for player in session.players
            @sessionsByPlayerId[player.uuid] = session

    _setupHttp: ->
        sv = @httpServer
        sv.use express.logger()
        sv.use express.methodOverride()
        sv.use express.bodyParser()

###
# 管理セッション
###
class AdminSession
    constructor: (conn,server)->
        @server = server
        @conn = conn
        @conn
         .on 'message', (msg)=>
            return if msg.type != 'utf8'
            msg = JSON.parse(msg.utf8Data)
            switch msg.t
                when 'CREATE_SESSION'
                    agame = new game.Game()
                    s = new Session( msg.sid, msg.pids, agame )
                    @server.addSession s
                    @conn.send JSON.stringify({t:'CREATE_SESSION_R',id:msg.id})
                when 'SESSION_LIST'
                    result = []
                    for sid,s of @server.sessions
                        players = (p.uuid for p in s.players)
                        result.push {sid:sid, players:players}
                    @conn.send JSON.stringify({t:'SESSION_LIST_R', id:msg.id, sessions:result})
                else
                    throw "invalid msg.t=#{msg.t}"

         .on 'close', (reason,desc)=>
            puts "close admin-session readon=#{reason}, desc=#{desc}"

###
# セッション（一つの卓の１ゲームに対応）
###
class Session
    constructor: (sid, uuids,_game)->
        @sid = sid
        @players = for uuid,i in uuids
            {
                idx: i
                uuid: uuid
                conn: undefined
            }
        for p in @players
            Session.sessions[p.uuid] = this
        @choises = []
        @game = _game
        @finishCount = 0

    addConnection: (uuid,conn)->
        player = _.find(@players, (p)->p.uuid == uuid )
        player.conn = conn
        conn.send JSON.stringify({t:'LOGIN',idx:player.idx})
        if @game.state == game.GAME_STATE.INIT
            conn.send JSON.stringify( {t:'INIT_GAME' } )
        else
            conn.send JSON.stringify( {t:'START_GAME', game:@game.serialize() } )

        conn
         .on 'message', (msg)=>
            return if msg.type != 'utf8'
            # puts 'recv: '+m.utf8Data
            msg = JSON.parse(msg.utf8Data)
            player = _.find(@players, (p)->p.conn == conn )
            switch msg.t
                when 'INIT_GAME_R'
                    @finishCount += 1
                    @game.fields[msg.pl].ships = msg.ships
                    if @finishCount >= 2
                        @game.state = game.GAME_STATE.MAIN
                        for p in @players
                            p.conn.send JSON.stringify( {t:'START_GAME', game:@game.serialize() } )
                when 'ATTACK'
                    @game.fields[1-msg.pl].attack( msg.x, msg.y )
                    for p in @players
                        p.conn.send JSON.stringify( {t:'UPDATE', game:@game.serialize() } )
                else
                    throw "invalid msg.t=#{msg.t}"

         .on 'close', (reason,desc)=>
            player = _.find(@players, (p)->p.uuid == uuid )
            player.conn = undefined
            puts reason, desc

    @findByUuid: (uuid)->@sessions[uuid]
    @sessions = {}

server = new Server()

