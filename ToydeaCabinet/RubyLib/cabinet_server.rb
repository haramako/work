# coding: utf-8
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require 'sinatra/reloader' if development?

require 'base64'
require 'google/protobuf'

$LOAD_PATH << './autogen'
require 'game_pb'

require './toydea_cabinet'
require './sqlite_repository'
require 'pp'

require './api'
require './admin'

also_reload './*.rb'
dont_reload 'test.rb'

# rubocop: disable Style/GlobalVars

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  def t(time)
    if time
      time.strftime('%Y/%m/%d %H:%M')
    else
      '-'
    end
  end
end

set :layout, :layout

def db
  $db = SqliteRepository.new unless $db
  $db
end

def base_url
  ENV['BASE_URL'] || 'http://localhost:4567'
end

def base64(bin)
  Base64.encode64(bin).gsub(/\n/,'')
end

def validate_session
  id = params['id'].to_i
  session_key = request.env['HTTP_X_TC_SESSION_KEY']
  u = db.get_user(id)
  raise "Session key not match" if u.session_key.nil? || u.session_key != session_key
  u
end

def savedata_title(bin)
  type, slot = bin.unpack('cS>')
  title_by_type = {0=>'dr1', 1=>'dr2'}
  langs = {0=>'jp', 1=>'ch', 2=>'en'}
  
  type_bit = (type & 0x01)
  title_bit = (type & 0x20) >> 5
  lang_bit = (type & 0x06) >> 1
  
  if type_bit == 1
    title = title_by_type[title_bit] + '.' + langs[lang_bit]
  else
    title = 'unknown'    
  end
  slot = slot || 0
  "%s.%02d" % [title, slot]
end

def savedata_desc(bin)
  d = Game::SaveData.decode(bin)
  if d.is_smartphone
    saved_at = (Time.utc(1601,1,1,9) + (d.saved_at / 1000_000_0)).strftime('%Y-%m-%d %H:%M') # JSTのため9時間ずらしている
    "%s (scene %d:%d:%d) %s" % [d.subtitle, d.chapter, d.scene, d.subscene, saved_at]
  else
    "[Steam] %s" % [d.subtitle]
  end
end

def savedata_is_smartphone(bin)
  d = Game::SaveData.decode(bin)
  d.is_smartphone
end
