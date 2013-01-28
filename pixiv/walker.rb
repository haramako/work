# coding: utf-8

require 'pp'
require 'mechanize'
require 'digest/sha1'
require 'fileutils'
require 'mysql'
require 'uri'

CACHE_DIR = '/tmp/walker/cache/'
IMG_DIR = '/tmp/walker/img/'

$cache_enable = true

module Walker

  module_function

  @@agent = Mechanize.new
  @@agent.request_headers['Accept-Language'] = 'ja,en-US'
  @@walkers = []

  def add_url( url )
    puts "add_url: #{url}"
    url = url.to_s
    db.query 'BEGIN'
    if db.prepare('SELECT COUNT(*) FROM urls WHERE url = ?').execute( url ).fetch[0].to_i == 0
      db.prepare( 'INSERT INTO urls ( url, expire_at ) VALUES ( ?, NOW() )' ).execute( url )
    end
    db.query 'COMMIT'
  end

  def walker( regexp, &block )
    @@walkers << { regexp: regexp, block: block }
  end

  def get( url )
    FileUtils.mkdir_p CACHE_DIR
    filename = Digest::SHA1.hexdigest(url)
    path = CACHE_DIR+filename
    if $cache_enable and File.exists? path
      html = File.open( path, 'r:utf-8' ){|f| f.read }
      Nokogiri::HTML( html )
    else
      puts "downloading #{url}"
      page = @@agent.get url, [], 'http://www.pixiv.net/'
      open( path, 'w' ){|f| f.write page.body }
      case page
      when Mechanize::Image
        page.body
      else
        page.root
      end
    end
  end

  def walk( url )
    puts "walk: #{url}"
    @@walkers.each do |w|
      if match = w[:regexp].match( url )
        w[:block].call url, match
        break
      end
    end
  rescue
    raise $!
    # STDERR.puts $!, $!.backtrace
  end

  def walk_around
    while true
      begin
        db.query 'BEGIN'
        row =  db.query("SELECT * FROM urls WHERE status = '' ORDER BY expire_at LIMIT 1 FOR UPDATE" ).fetch_hash
        break unless row
        db.prepare("UPDATE urls SET status = 'P' WHERE url = ? ").execute( row['url'] )
        walk row['url']
        db.commit
      rescue Mechanize::ResponseCodeError
        db.prepare("UPDATE urls SET status = 'F' WHERE url = ? ").execute( row['url'] )
        db.commit
        pp $!
      rescue
        db.rollback
        raise
      end
    end
  end

  private 
  
  def db
    return @@db if defined? @@db
    @@db = Mysql.new( 'localhost', 'root', nil, 'walker' )
  end

end

include Walker


# require_relative 'taikai'
require_relative 'pixiv'

