# -*- coding: utf-8 -*-

module WebWalker::Plugin
  class EHentai < WebWalker::Walker
    BASE_URL = URI('http://g.e-hentai.org/')

    # ユーザーページ
    walker %r(^http://g\.e-hentai\.org/g/(\d+)/([0-9a-f]+)/) do |url,match|
      page = get url

      page.search('a').each do |e|
        href = e.attr('href')
        add_url href if href and href.match %r(^http://g\.e-hentai\.org/s/)
        add_url href if href and href.match %r(^http://g.e-hentai.org/g/.*/\?p=\d+)
      end

      project_name page.search('h1#gn').text
      expire 60*60*24*365
    end

    walker %r(^http://g\.e-hentai\.org/s/([0-9a-z]+)/(\d+)-(\d+)) do |url,match|
      page = get url
      _, _, id, page_no = *match
      page_no = page_no.to_i
      page.search('div#i3 img').each do |e|
        image = get e['src']
        add_image "%04d.jpg" % page_no, image
      end
    end
  end
end
