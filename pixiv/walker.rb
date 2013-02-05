# coding: utf-8

require 'pp'
require 'mechanize'
require 'digest/sha1'
require 'fileutils'
require 'mysql'
require 'uri'
require 'pathname'

CACHE_DIR = Pathname('/tmp/walker/cache/')
IMG_DIR = Pathname('/var/walker/img/')
FileUtils.mkdir_p IMG_DIR

$cache_enable = true

module Handler
  module_function

  def db
    return @@db if defined? @@db
    @@db = Mysql.new( 'localhost', 'root', nil, 'walker' )
  end

  def add_url( project, url )
    puts "add_url: #{url}"
    url = url.to_s
    db.query 'BEGIN'

    # プロジェクトを取得する
    res = db.prepare('SELECT id FROM projects WHERE url = ?').execute( project.url )
    if res.num_rows > 0
      row = res.fetch
      project.id = row[0]
    else
      db.prepare( 'INSERT INTO projects ( url, name, created_at ) VALUES ( ?, ?, NULL )' ).execute( url, project.name )
      project.id = db.insert_id
    end

    if db.prepare('SELECT COUNT(*) FROM urls WHERE url = ?').execute( url ).fetch[0].to_i == 0
      db.prepare( 'INSERT INTO urls ( url, project_id, expire_at, created_at ) VALUES ( ?, ?, NOW(), NULL )' ).execute( url, project.id )
    end
    db.query 'COMMIT'
  end

  @@walkers = []

  def self.walker( regexp, _class, &block )
    @@walkers << { _class: _class, regexp: regexp, block: block }
  end

  def self.walk( project, url )
    puts "walk: #{url}"
    @@walkers.each do |w|
      if match = w[:regexp].match( url )
        obj = w[:_class].new( project, url )
        obj.instance_exec( url, match,  &w[:block] )
        return
      end
    end
    puts "no url match for #{url}"
  rescue
    raise $!
    # STDERR.puts $!, $!.backtrace
  end

  def self.walk_around
    while true
      begin
        db.query 'BEGIN'
        row =  db.query("SELECT * FROM urls WHERE status = '' ORDER BY expire_at LIMIT 1 FOR UPDATE" ).fetch_hash
        break unless row
        db.prepare("UPDATE urls SET status = 'P' WHERE url = ? ").execute( row['url'] )
        project_row =  db.prepare("SELECT id, name, url FROM projects WHERE id = ?").execute(row['project_id']).fetch
        project = Project.new( project_row[1], project_row[2] )
        project.id = project_row[0]
        walk project, row['url']
        db.commit
      rescue Mechanize::ResponseCodeError, Errno::ETIMEDOUT
        db.prepare("UPDATE urls SET status = 'F' WHERE url = ? ").execute( row['url'] )
        db.commit
        pp $!
      rescue
        db.rollback
        raise
      end
    end
  end

end

class Project
  attr_accessor :id
  attr_reader :url, :name

  def initialize( name, url )
    @id = nil
    @name = name
    @url = url
  end

  def self.default
    project = Project.new( '', 'unknown' )
    project.id = 1
    project
  end

end

class Walker

  attr_reader :project, :url

  def initialize( project, url )
    @project = project
    @cur_url = url
    @agent = Mechanize.new
    @agent.request_headers['Accept-Language'] = 'ja,en-US'
  end

  def get( url )
    if @cur_url.to_s.match %r(^http://g\.e-hentai\.org/)
      sleep 1
    end

    FileUtils.mkdir_p CACHE_DIR
    filename = Digest::SHA1.hexdigest(url)
    path = CACHE_DIR+filename
    if $cache_enable and File.exists? path
      html = File.open( path, 'r:utf-8' ){|f| f.read }
      if html[0] == '<'
        Nokogiri::HTML( html )
      else
        html
      end
    else
      puts "downloading #{url}"
      page = @agent.get url, [], 'http://www.pixiv.net/'

      open( path, 'w' ){|f| f.write page.body }
      case page
      when Mechanize::Image
        page.body
      else
        html = page.root.to_s
        if html.match(/The ban expires/) # Banが終わるまで待つ
          puts 'wait!'
          sleep 60*60
          get( url )
        end

        page.root
      end
    end
  end

  def project_path
    path = IMG_DIR + "%06d"%[project.id]
    FileUtils.mkdir_p path
    path
  end

  def add_url( url )
    Handler.add_url @project, url
  end

  def self.walker( regexp, &block )
    Handler.walker regexp, self, &block
  end

end

# require_relative 'taikai'
require_relative 'pixiv'
# require_relative 'e-hentai'

