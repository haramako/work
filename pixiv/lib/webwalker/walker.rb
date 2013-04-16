# coding: utf-8

require 'pp'
require 'mechanize'
require 'digest/sha1'
require 'fileutils'
require 'uri'
require 'pathname'
require 'active_record'
require 'logger'

ActiveRecord::Base.establish_connection( 'adapter' => 'mysql',
                                         'database' => 'walker' )
# ActiveRecord::Base.logger = Logger.new( STDOUT )

IMG_DIR = Pathname('/var/walker/img/')

module WebWalker

  class Project < ActiveRecord::Base
    has_many :children, class_name: :Url, dependent: :destroy
    
    def path
      r = IMG_DIR + "%06d"%[id]
      FileUtils.mkdir_p r
      r
    end

  end

  class Url < ActiveRecord::Base
    belongs_to :project
    include ActiveRecord::Calculations
  end



  module Handler
    module_function

    def db
      return @@db if defined? @@db
      @@db = Mysql.new( '127.0.0.1', 'root', nil, 'walker' )
    end

    def add_url( project, url )
      new_url = Url.new( project_id: project.id, url: url, expire_at: Time.now )
      new_url.save!
    end

    @@walkers = []

    def self.walker( regexp, _class, &block )
      @@walkers << { _class: _class, regexp: regexp, block: block }
    end

    def self.walk( url )
      puts "walk: #{url}"
      @@walkers.each do |w|
        if match = w[:regexp].match( url )
          obj = w[:_class].new( url )
          obj.instance_exec( url, match,  &w[:block] )
          return obj
        end
      end
      puts "no url match for #{url}"
      nil
    end

    def self.walk_around
      while true
        url = Url.limit(1).find( :all, conditions: { status: ''}, order: :expire_at )
        break if url.size <= 0
        walk_one url[0]
      end
    end

    def self.walk_one( url )
      url = WebWalker::Url.find(url) unless url.is_a?(Url)
      x = walk url.url

      # 帰ってきた値に応じて動作する
      project = url.project
      x.result[:url].each do |new_url|
        next if Url.find( :all, conditions: { project_id: project.id, url: new_url } ).size > 0
        Url.new( project: project, url: new_url, created_at: Time.now, expire_at: Time.now ).save!
      end
      x.result[:image].each do |path,img|
        File.open( project.path + path, 'wb' ){|f| f.write img.body }
      end
      if x.result[:project_name]
        project.name = x.result[:project_name]
        project.save!
      end

      url.status = 'P'
      url.save!
    rescue Mechanize::ResponseCodeError, Errno::ETIMEDOUT
      url.status = 'F'
      url.save!
      pp $!
    rescue
      raise
    end

  end

  class Walker

    attr_reader :url, :result

    def initialize( url )
      @cur_url = url
      @agent = Mechanize.new
      @agent.request_headers['Accept-Language'] = 'ja,en-US'
      @result = { url: [], image: {} }
    end

    def get( url )
      if @cur_url.to_s.match %r(^http://g\.e-hentai\.org/)
        sleep 1
      end

      # puts "downloading #{url}"
      page = @agent.get url, [], 'http://www.pixiv.net/'

      case page
      when Mechanize::Image
        page
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

    def add_url( url )
      @result[:url] << url.to_s
    end

    def expire(val)
      @result[:expire] = val
    end

    def project_name(val)
      @result[:project_name] = val
    end

    def add_image(path,val)
      @result[:image][path] = val
    end

    def self.walker( regexp, &block )
      Handler.walker regexp, self, &block
    end

  end

end

# require_relative 'taikai'
require_relative 'pixiv'
require_relative 'e-hentai'

class Mechanize::Image
  def to_s
    filename
  end
end
