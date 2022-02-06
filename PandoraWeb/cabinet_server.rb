# coding: utf-8
# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'

require 'base64'
require 'pp'
require 'google/protobuf'

require "omniauth"
require "omniauth-twitter"
require "omniauth-google-oauth2"
require "omniauth-openid"
require 'openid'
require 'openid/store/filesystem'

# $LOAD_PATH << './autogen'
# require 'game_pb'

require_relative 'toydea_cabinet'
require_relative 'sqlite_repository'

require_relative 'api'
require_relative 'admin'

# rubocop: disable Style/GlobalVars

# use Rack::Session::Cookie

class SinatraApp < Sinatra::Base
  configure do
    set :layout, :layout
    set :sessions, true
  end
  
use OmniAuth::Builder do
  # provider :open_id, :name => 'google', :identifier => 'https://www.google.com/accounts/o8/id'

  #provider :open_id, OpenID::Store::Filesystem.new('/tmp')
  provider :google_oauth2,  "108880317429-giti7kvabgisa0v05mgpn9skdejd5853.apps.googleusercontent.com",   "MN5vyKRUa1REnLv--1eXnkaJ"
  #provider :twitter,  ENV["GOOGLE_APP_ID"],   ENV["GOOGLE_APP_SECRET"]
end

get '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  STDERR.puts 'HOGE'
  # do whatever you want with the information!
end

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
end

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
  "%s.%d" % [title, slot]
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


SinatraApp.run! if __FILE__ == $0
