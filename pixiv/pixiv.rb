# -*- coding: utf-8 -*-
PIXIV_URL = URI('http://www.pixiv.net/')

def login_pixiv
#  puts @@agent.methods
  @@agent.cookie_jar.load 'cookie.yaml'
  @@agent.cookie_jar.jar['pixiv.net']['/']['PHPSESSID']
rescue
  puts "login pixiv"
  @@agent.post 'http://www.pixiv.net/login.php', { mode: 'login', pixiv_id: 'haramako', pass: 'mako0522', skip: 1 }
  @@agent.cookie_jar.save_as 'cookie.yaml'
end


# ユーザーページ
walker %r(^http://www\.pixiv\.net/member.php\?id=(\d+)) do |url,match|
  login_pixiv
  page = get url

  page.search('a').each do |e|
    href = e.attr('href')
    add_url PIXIV_URL+href[1..-1] if /\/member_illust\.php\?id=(\d)+/ === href
  end

  { expire: 60*60*24*365 }
end


# イラスト一覧ページ
walker %r(http://www\.pixiv\.net/member_illust\.php\?id=(\d+)(&p=(\d+))?) do |url,match|
  login_pixiv
  page_no = match[3] || 1
  page = get url
  page.search('a').each do |e|
    href = e.attr('href')
    add_url PIXIV_URL+e.attr('href') if /member_illust\.php\?id=(\d+)&p=(\d+)/ === e.attr('href')
    add_url PIXIV_URL+e.attr('href') if /member_illust\.php\?mode=medium&illust_id=(\d+)/ === e.attr('href')
  end
  { expire: 60*60*24*365 }
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
    image_url = page.search('div.works_display img')[0].attr('src').gsub( /_m\.jpg$/, '.jpg' )
    image = get image_url

    open( "#{IMG_DIR}#{id}.jpg", 'w' ){ |f| f.write image }
    db.prepare('REPLACE images ( id, title, author ) VALUES ( ?, ?, ? )').execute( id, title, author )
  end

  { expire: 60*60*24*365 }
end


#add_url 'http://www.pixiv.net/member.php?id=10264'

add_url 'http://www.pixiv.net/member.php?id=10264'
walk 'http://www.pixiv.net/member_illust.php?id=10264'

walk 'http://www.pixiv.net/member_illust.php?mode=medium&illust_id=7153283'

#walk 'http://www.pixiv.net/member_illust.php?id=396179'
#walk 'http://www.pixiv.net/member_illust.php?id=396179&p=2'
# walk 'http://i2.pixiv.net/img20/img/maim2/29198523.jpg'
#walk 'http://i2.pixiv.net/img20/img/maim2/26939305.jpg'
#walk 'http://www.pixiv.net/member_illust.php?mode=medium&illust_id=26939305'
#walk 'http://www.pixiv.net/member_illust.php?mode=medium&illust_id=1002898'

#walk 'http://www.pixiv.net/member_illust.php?mode=medium&illust_id=6517473'

add_url 'http://www.pixiv.net/member.php?id=84409'
walk_around

# walk 'http://www.pixiv.net/member_illust.php?mode=medium&illust_id=29215927'

=begin
add_url 'http://www.pixiv.net/member.php?id=133790'
add_url 'http://www.pixiv.net/member.php?id=5238'
add_url 'http://www.pixiv.net/member.php?id=169083'
add_url 'http://www.pixiv.net/member.php?id=43614'
add_url 'http://www.pixiv.net/member.php?id=14063'
add_url 'http://www.pixiv.net/member.php?id=9731'
add_url 'http://www.pixiv.net/member.php?id=417796'
add_url 'http://www.pixiv.net/member.php?id=2200242'
add_url 'http://www.pixiv.net/member.php?id=257090'
add_url 'http://www.pixiv.net/member.php?id=101608'
=end
