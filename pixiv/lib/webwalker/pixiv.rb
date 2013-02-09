# -*- coding: utf-8 -*-
require_relative 'walker'

module WebWalker::Plugin
  class Pixiv < WebWalker::Walker

    PIXIV_URL = URI('http://www.pixiv.net/')

    def login_pixiv
      #  puts @@agent.methods
      @agent.cookie_jar.load 'cookie.yaml'
      @agent.cookie_jar.jar['pixiv.net']['/']['PHPSESSID']
    rescue
      puts "login pixiv"
      @agent.post 'http://www.pixiv.net/login.php', { mode: 'login', pixiv_id: 'haramako', pass: 'mako0522', skip: 1 }
      @agent.cookie_jar.save_as 'cookie.yaml'
    end

    # ユーザーページ
    walker %r(^http://www\.pixiv\.net/member.php\?id=(\d+)) do |url,match|
      login_pixiv
      page = get url


      page.search('a').each do |e|
        href = e.attr('href')
        add_url PIXIV_URL+href[1..-1] if /\/member_illust\.php\?id=(\d)+/ === href
      end

      project_name page.search('h1.user').text
      expire 60*60*24*365
    end

    # イラスト一覧ページ
    walker %r(^http://www\.pixiv\.net/member_illust\.php\?id=(\d+)(&p=(\d+))?) do |url,match|
      login_pixiv
      page_no = match[3].to_i || 1
      page = get url
      page.search('a').each do |e|
        href = e.attr('href')
        add_url PIXIV_URL+e.attr('href') if /member_illust\.php\?id=(\d+)&p=(\d+)/ === e.attr('href')
        add_url PIXIV_URL+e.attr('href') if /member_illust\.php\?mode=medium&illust_id=(\d+)/ === e.attr('href')
      end

      expire 60*60*24*365
    end

    # イラストページ
    walker %r(^http://www\.pixiv\.net/member_illust.php\?mode=medium&illust_id=(\d+)) do |url,match|
      login_pixiv
      page = get url
      id = match[1]
      title = page.search('h1.title')[0].text
      author = page.search('div.user-unit h1').text

      if /mode=manga/ === page.search('div.works_display a').attr('href').to_s
        # TODO: 漫画モードは未対応
      else
        # 通常のイラスト
        image_url = page.search('div.works_display img')[0].attr('src').gsub( /_m\.(jpg|png|gif)$/){|x| x[2..-1] }

        ext = File.extname(image_url).gsub(/\?.+$/,'')
        add_image id.to_s+ext,  get( image_url )

        # open( project_path + (id.to_s + ext), 'w' ){ |f| f.write image }
        # db.prepare('REPLACE images ( id, title, author ) VALUES ( ?, ?, ? )').execute( id, title, author )
      end

      expire 60*60*24*365
    end

  end
end

