jan = require './jan'
janutil = require './janutil'
tenhou = require './tenhou'
fs = require 'fs'

check = (path,haifu)->
    ok = 0
    ng = 0
    i = 0
    for kyoku in haifu.kyoku
        try
            akadora = 0
            for pi in kyoku.piTehai
                if pi == jan.PaiId.MAN5_0 or pi == jan.PaiId.PIN5_0 or pi == jan.PaiId.SOU5_0
                    akadora++
            yakuData = jan.calcYaku( jan.PaiId.toKind(kyoku.piTehai), kyoku.mentsu,
                {pkLast: kyoku.pkMachi,  oya:kyoku.oya,
                pkDora: kyoku.pkDora, pkUradora: kyoku.pkUradora, akadora: akadora,
                reach: kyoku.reach, doubleReach: kyoku.doubleReach, ippatsu: kyoku.ippatsu, tsumo:kyoku.tsumo,
                rinshan: kyoku.rinshan, haitei: kyoku.haitei, houtei: kyoku.houtei,
                pkBakaze:kyoku.pkBakaze, pkJikaze: kyoku.pkJikaze } )

            if kyoku.tsumo
                score = yakuData.score[2]+yakuData.score[3]*2
            else
                score = yakuData.score[1]

            if score == kyoku.score or (kyoku.score==11600 and score==12000) or (kyoku.score==11700 and score==12000) or (kyoku.score==7700 and score==8000) or (kyoku.score==7900 and score==8000)
                ok++
            else
                ng++
                puts '----'
                puts "#{path} (#{i})"
                yakuData.yaku = jan.Yaku.toString( yakuData.yaku )
                kyoku.pkMachi = jan.PaiKind.toReadable( kyoku.pkMachi )
                kyoku.pkDora = jan.PaiKind.toReadable( kyoku.pkDora )
                puts jan.PaiKind.toReadable( jan.PaiId.toKind(kyoku.piTehai) ), kyoku.mentsu.toString()
                puts yakuData
                puts kyoku
                puts '----'
            i++
        catch e
            puts 'error' # TODO: 七対とかまだ未対応
    [ok,ng]

serialDo = (array,every,final)->
    doOne = (array,i,every,final)->
        if i == array.length
            final()
        else
            every array[i], ->
                doOne(array,i+1,every,final)
    doOne(array,0,every,final)
# serialDo [1,2,3], ((n,next)->puts(n);next()), (->puts 'finish')

dir = '/Users/makoto/Downloads/mjlog_pf4-20_n3'
ok = 0
ng = 0

files = fs.readdirSync( dir ).slice(0,20)
serialDo files, (path,next)->
    tenhou.readHaifu dir+'/'+path, (err,haifu)->
        result = check(path,haifu)
        ok += result[0]
        ng += result[1]
        next()
, ->
    puts "ok=#{ok} ng=#{ng}"
