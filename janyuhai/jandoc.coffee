#!/bin/env coffee
#
# 雀友牌のプログラムで使う定数群をHTMLで書きだす.
#

jan = require './jan'

template = '''
<html>
<head>
    <title>雀友牌 番号表</title>
<body>
<style>
table { border-collapse: collapse; margin: 20px; font-size: 8pt; }
th { background-color: #bbb; }
td, th { border: solid 1px #888; }
</style>
<table style="float:left;">
    <tr><th width="30">PaiKind</th><th width="80">PaiId</th><th width="30">牌</th><th width="120">ID</th></tr>
    PAI_LIST
</table>
<table style="float:left;">
    <tr><th>番号</th><th>表示名</th><th>飜</th></tr>
    YAKU_LIST
</table>
</body>
</html>
'''

yakuList = [0...jan.Yaku.MAX].map (yaku)->
    info = jan.Yaku.info( yaku )
    "<tr><td>#{info.num}</td><td>#{info.name}</td><td>#{info.han}</td></tr>"

paiList = [0...jan.PaiKind.MAX].map (pk)->
    "<tr><td>#{pk}</td><td>#{pk*4}..#{pk*4+3}</td><td>#{jan.PaiKind.toReadable(pk)}</td><td>#{jan.PaiKind.toString(pk)}</td></tr>"

template = template.replace( 'PAI_LIST', paiList.join('\n') )
template = template.replace( 'YAKU_LIST', yakuList.join('\n') )

puts template
