jan = require './jan'
janutil = require './janutil'
tenhou = require './tenhou'
fs = require 'fs'

check = (haifu)->
    i = 0
    for kyoku in haifu.kyoku
        akadora = 0
        for pi in kyoku.piTehai
            if pi == jan.PaiId.MAN5_0 or pi == jan.PaiId.PIN5_0 or pi == jan.PaiId.SOU5_0
                akadora++
        yakuData = jan.calcYaku( jan.PaiId.toKind(kyoku.piTehai), kyoku.mentsu,
            {pkLast: kyoku.pkMachi, pkDora: kyoku.pkDora, pkUradora: kyoku.pkUradora, oya:kyoku.oya,
            akadora: akadora, reach: kyoku.reach, ippatsu: kyoku.ippatsu, tsumo:kyoku.tsumo,
            pkBakaze:kyoku.pkBakaze, pkJikaze: kyoku.pkJikaze } )

        if kyoku.tsumo
            score = yakuData.score[2]+yakuData.score[3]*2
        else
            score = yakuData.score[1]

        if score == kyoku.score or (kyoku.score==11600 and score==12000) or (kyoku.score==11700 and score==12000) or (kyoku.score==7700 and score==8000) or (kyoku.score==7900 and score==8000)
        else
            puts '----'+i
            yakuData.yaku = jan.Yaku.toString( yakuData.yaku )
            kyoku.pkMachi = jan.PaiKind.toReadable( kyoku.pkMachi )
            kyoku.pkDora = jan.PaiKind.toReadable( kyoku.pkDora )
            puts jan.PaiKind.toReadable( jan.PaiId.toKind(kyoku.piTehai) ), kyoku.mentsu.toString()
            puts yakuData
            puts kyoku
            puts '----'
        i++


dir = '/Users/makoto/Downloads/mjlog_pf4-20_n3'
fs.readdirSync( dir ).slice(0,20).map (path)->
    # return if ['2009071920gm-0041-0000-83db6aaa&tw=3.mjlog','2009071921gm-0041-0000-ef1ec722&tw=3.mjlog'].indexOf(path) >= 0
    ((path2)->
        tenhou.readHaifu dir+'/'+path, (err,haifu)->
            puts path2
            check(haifu)
    )(path)

