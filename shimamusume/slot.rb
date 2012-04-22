#!/usr/env ruby
# coding: utf-8

require 'pp'

#
# 島娘の解析
#

# とりたいもの
# - 当たりやすいゲーム数
# - ときめき連以外のBIGの発生率（/ゲーム数)
# - 指定した条件（ゲーム数）から開始した場合、平均何ゲームでBIGにあたるか(ときめき連含む)
# - 指定した条件（ゲーム数）から開始した場合、平均何回REGをはさむか(ときめき連含む)
# - BIG単発後、０Gまたは１００Gから２００Gからはじめた場合の、次のBIGまでのゲーム数
# - すべての数字はは20G引いて、最低数は10G
# - BIG間200,400,600Gで打ち始めた時の次のBIGまで
# - 100G単位でのREGからの平均連チャン数
# - 突然ビッグの平均連チャン数、単発率

games = []

ARGF.readlines.each do |line|
  next if line[0] == '#'
  next if line.length <= 1
  gm = []
  line.split(/ +/).each do |e|
    if /(\d+)?(b?)/i === e
      if $2 == 'b' or $2 == 'B'
        type = 'B'
      else
        type = 'R'
      end
      if $1
        num = [$1.to_i-2,1].max
      else
        num = 0
      end
      gm.unshift [num,type]
    end
  end
  games.push gm
end

#pp games

# - ときめき連以外のBIGの発生率（/ゲーム数)
total = 0
reg_num = 0
big_num = 0
big_hatsu = 0
big_num_alone = 0
games.each do |gm|
  gm.each_with_index do |g,i|
    total += g[0]
    big_num += 1 if g[1] == 'B'
    reg_num += 1 if g[1] == 'R'
    big_hatsu += 1 if g[1] == 'B' and ( g[0]>0 or i<=0 or gm[i-1][1] == 'R')
    big_num_alone += 1 if g[1] == 'B' and g[0] > 1
  end
end
puts '='*80
puts '基本確率'
puts '='*80
puts "総ゲーム数    : %10dG"%(total*10)
puts "REG確率       : 1/%8.3fG"%(total.to_f / reg_num * 10)
puts "ビッグ確率    : 1/%8.3fG"%(total.to_f / big_num * 10)
puts "ビッグ初あたり: 1/%8.3fG"%(total.to_f / big_hatsu * 10)
puts "突然ビッグ確率: 1/%8.3fG"%(total.to_f / big_num_alone * 10)
puts "平均連チャン数: %11.3f"%(big_num.to_f / big_hatsu)

# - 当たりやすいゲーム数
total = 0
regavg = Array.new(116){0}
total_bonus = 0
games.each do |gm|
  gm.each do |g|
    total += g[0]
    if g[1] == 'R'
      total_bonus += 1
      regavg[g[0]] += 1
    end
  end
end
puts '='*80
puts '当たりやすいゲーム数( REGのみ)'
puts '='*80
puts 'G数     確率      到達時確率'
regavg.each_with_index do |g,n|
  g_rest = regavg[n..-1].inject(0){|x,i|x+i}
  puts "%03dG %8.3f%% %8.3f%% %s"%[ n*10, (100.0*g/total_bonus), (100.0*g/g_rest),  '#'*(20000*g/total)]
end

regavg2 = Array.new(24){0}
regavg.each_with_index do |gm,n|
  regavg2[n/5] += gm
end
puts '='*80
puts '当たりやすいゲーム数( REGのみ)'
puts '='*80
puts 'G数     確率      到達時確率'
regavg2.each_with_index do |g,n|
  g_rest = regavg2[n..-1].inject(0){|x,i|x+i}
  puts "%04dG-%04dG %8.3f%% %8.3f%% %s"%[ n*50,n*50+49, (100.0*g/total_bonus), (100.0*g/g_rest),  '#'*(5000*g/total)]
end

# - 指定した条件（ゲーム数）から開始した場合、平均何ゲームでBIGにあたるか(ときめき連含む)
# - 指定した条件（ゲーム数）から開始した場合、平均何回REGをはさむか(ときめき連含む)
stats = []
[0,2,10,20,30,40,50,55,60,65,70,75,80].each do |start_game|
  stat = { start_game: start_game, reg:0, game:0, big:0 }
  games.each do |gm|
    gm.each_with_index do |g_start,i|
      next if g_start[0] < start_game
      next unless gm[i-1] and gm[i-1][1] == 'B'
      game_num = -start_game
      reg_num = 0
      gm[i..-1].each do |g|
        if g[1] == 'B'
          game_num += g[0]
          stat[:reg] += reg_num
          stat[:game] += game_num
          stat[:big] += 1
          break
        else
          game_num += g[0]
          reg_num += 1
        end
      end
    end
  end
  stats.push stat
end

puts '='*80
puts '指定したゲーム数から開始した場合、平均何ゲーム/REGでBIGにあたるか'
puts '='*80
stats.each_with_index do |stat,i|
  puts '%3dGはじめ: 候補=%4d個 ゲーム数=%7dG BIG/REG=%3.3f BIG/G=%5d'%
    [stat[:start_game]*10, stat[:big], stat[:game]*10, stat[:reg].to_f/stat[:big], stat[:game]*10.0/stat[:big]] rescue nil
end

# - BIG単発後、０Gまたは１００Gから２００Gからはじめた場合の、次のBIGまでのゲーム数
def isTanpatsu( gm, i )
  if gm[i][1] == 'R'
    false
  else
    if gm[i-1] and gm[i-1][1] == 'B' and gm[i][0] == 0
      false
    elsif gm[i+1] and gm[i+1][1] == 'B' and gm[i+1][0] == 0
      false
    else
      true
    end
  end
end

stats = []
[0,2,10,20,30,40,50,60,80,100,120,140,160,180].each do |start_game|
  stat = { start_game: start_game, reg:0, game:0, big:0 }
  games.each do |gm|
    gm.each_with_index do |g_start,i|
      # next if g_start[0] < start_game
      next unless isTanpatsu(gm,i)
      game_num = -start_game
      reg_num = 0
      gm[i+1..-1].each do |g|
        if g[1] == 'B'
          game_num += g[0]
          if game_num > 0
            stat[:reg] += reg_num
            stat[:game] += game_num 
            stat[:big] += 1
          end
          break
        else
          game_num += g[0]
          reg_num += 1
        end
      end
    end
  end
  stats.push stat
end

puts '='*80
puts 'BIG単発後、特定のBIG間ゲーム数からはじめた場合の、次のBIGまでのゲーム数'
puts '='*80
stats.each_with_index do |stat,i|
  puts '%3dGはじめ: 候補=%4d個 ゲーム数=%7dG BIG/REG=%3.3f BIG/G=%5d'%
    [stat[:start_game]*10, stat[:big], stat[:game]*10, stat[:reg].to_f/stat[:big], stat[:game]*10.0/stat[:big]] rescue nil
end

# - BIG間200,400,600Gで打ち始めた時の次のBIGまで
big_time = []
games.each do |gm|
  time = 0
  gm.each_with_index do |g,i|
    if g[1] == 'B' 
      if g[0] > 1 or !gm[i-1] or gm[i-1][1] == 'R'
        big_time.push g[0]+time
        time = 0
      else
        time += g[0]
      end
    else
      time+=g[0]
    end
  end
end

stats = []
[0,2,20,40,60,80,100,120,140,160,180,200].each do |start_game|
  stat = { start_game: start_game, game:0, num:0 }
  big_time.each do |gm|
    if gm > start_game
      stat[:num] += 1
      stat[:game] += gm - start_game
    end
  end
  stats.push stat
end

puts '='*80
puts '指定したBIG間ゲーム数から開始した場合、平均何ゲームでBIGにあたるか'
puts '='*80
stats.each_with_index do |stat,i|
  puts '%4dGはじめ: 候補=%4d個 BIG/G=%5d'%
    [stat[:start_game]*10, stat[:num], 10.0*stat[:game]/stat[:num]] rescue nil
end

# - REGからのBIGはずし何回で
stats = []
(1..8).each do |reg_hazushi|
  stat = { reg_hazushi: reg_hazushi, big:0, game:0 }
  games.each do |gm|
    gm.each_with_index do |g_start,i|
      next if g_start[1] == 'B'
      next if i < reg_hazushi
      finish = false
      (1..reg_hazushi).each do |n|
        finish = true if gm[i-n][1] == 'B'
      end
      next if finish
      game = 0
      gm[i..-1].each do |g|
        if g[1] == 'B'
          game += g[0]
          stat[:big]+=1
          stat[:game]+=game
          break
        else
          game += g[0]
        end
      end
    end
  end
  stats.push stat
end

puts '='*80
puts '指定した回数REGをはずした場合、平均何ゲームでBIGにあたるか'
puts '='*80
stats.each_with_index do |stat,i|
  puts '%4d回はずし: 候補=%4d個 BIG/G=%5d'%
    [stat[:reg_hazushi], stat[:big], 10.0*stat[:game]/stat[:big]] rescue nil
end

# - 100G単位でのREGからの平均連チャン数
stats = Array.new(12){[0,0,0]}
games.each do |gm|
  gm.each_with_index do |g_start,i|
    next if g_start[1] != 'R'
    renchan = 0
    gm[i+1..-1].each do |g|
      if g[1] == 'B' and g[0] == 0
        renchan += 1
      else
        break
      end
    end
    stats[g_start[0]/10][2] += 1
    if renchan > 0
      stats[g_start[0]/10][0] += 1
      stats[g_start[0]/10][1] += renchan
    end
  end
end

puts '='*80
puts '100G単位でのREGからの平均連チャン数'
puts '='*80
stats.each_with_index do |stat,i|
  puts '%4dG-%4dG: 候補=%4d個 平均連数=%5.3f ヒット率=%5.3f'%
    [i*100, i*100+99, stat[0], 1.0*stat[1]/stat[0], 1.0*stat[0]/stat[2]]
end
stat = stats.inject([0,0,0]){|x,m|[x[0]+m[0],x[1]+m[1],x[2]+m[2]]}
puts '合計       : 候補=%4d個 平均連数=%5.3f ヒット率=%5.3f'%[stat[0], 1.0*stat[1]/stat[0], 1.0*stat[0]/stat[2]]

# - 突然ビッグの平均連チャン数、単発率
stat = [0,0,0]
games.each do |gm|
  gm.each_with_index do |g_start,i|
    next if g_start[1] != 'B' or g_start[0] == 0
    renchan = 1
    gm[i+1..-1].each do |g|
      if g[1] == 'B' and g[0] == 0
        renchan += 1
      else
        break
      end
    end
    stat[2] += 1
    if renchan > 1
      stat[0] += 1
      stat[1] += renchan
    end
  end
end
puts '='*80
puts '突然ビッグの平均連チャン数、単発率'
puts '='*80
puts '合計       : 候補=%4d個 平均連数=%5.3f ヒット率=%5.3f'%[stat[0], 1.0*stat[1]/stat[0], 1.0*stat[0]/stat[2]]

# - 突然BIG単発後の次回ビッグまでの平均ゲーム数
big_num = 0
game_num = 0
reg_num = 0
games.each do |gm|
  time = 0
  ok = false
  gm.each_with_index do |g,i|
    if isTanpatsu(gm,i) and g[0]>0
      if ok
        big_num += 1
        game_num += time + g[0]
        ok = false
      end
      ok = true
      time = 0
    elsif g[1] == 'B'
      if ok
        big_num += 1
        game_num += time + g[0]
        ok = false
      end
    else
      if ok
        reg_num += 1
        time+=g[0]
      end
    end
  end
end

puts '='*80
puts '突然BIG単発後の次回ビッグまでの平均ゲーム数,REG数'
puts '='*80
puts "候補=%3d ゲーム数=%8d REG数=%4d BIG/G=%8.3f BIG/REG=%5.3f"%[big_num,game_num*10,reg_num, 10.0*game_num/big_num, 1.0*reg_num/big_num]
