# -*- coding: utf-8 -*-

TAIKAI_URL = 'http://www.taikaisyu.com/'

def get_image( url )
  image = get url
  path = url.gsub( /^http:\/\//, '' )
  dir = File.dirname( path )
  FileUtils.mkdir_p( "#{IMG_DIR}#{dir}" )
  open( "#{IMG_DIR}#{path}", 'w' ){ |f| f.write image }
end

# 画像
walker %r(^http://www\.taikaisyu\.com/.*\.jpg) do |url,match|
  get_image url
  { expire: 60*60*24*365 }
end

# インデックス
walker %r(^http://www\.taikaisyu\.com/) do |url,match|
  page = get url

  page.search('a').each do |e|
    href = URI.join( url, e.attr('href') ).to_s
    next unless href.start_with?( TAIKAI_URL )
    add_url href
    # puts href
  end

  page.search('img').each do |e|
    src = URI.join( url, e.attr('src') ).to_s
    next unless /\/\d+\.jpg$/ === src 
    add_url src
  end

  { expire: 60*60*24*365 }
end


walk 'http://www.taikaisyu.com/'
#walk 'http://www.taikaisyu.com/soukan/map.html'
#walk 'http://www.taikaisyu.com/27-03/15.jpg'
walk_around
