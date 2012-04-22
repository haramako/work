jan = require './jan'
vows = require 'vows'
assert = require 'assert'

# ショートカット
PaiId = jan.PaiId
PaiKind = jan.PaiKind
Mentsu = jan.Mentsu
Yaku = jan.Yaku

vows
    .describe('PaiKind')
    .addBatch
        'toString()': ->
            assert.equal PaiKind.toString(jan.MAN1), 'MAN1'

        'toSuit() should return kind from PaiSuit': ->
            assert.equal PaiKind.toSuit( jan.MAN1 ), jan.PaiSuit.MANZU
            assert.equal PaiKind.toSuit( jan.PIN1 ), jan.PaiSuit.PINZU
            assert.equal PaiKind.toSuit( jan.SOU1 ), jan.PaiSuit.SOUZU
            assert.equal PaiKind.toSuit( jan.TON ), jan.PaiSuit.JIHAI

        'fromReadableString() should return PaiKind from readable string': ->
            assert.equal PaiKind.fromReadable( '東' ), jan.TON

        'fromReadable() should allow space-splited string': ->
            assert.deepEqual PaiKind.fromReadable( '１２ ３' ),
                [[jan.SOU1, jan.SOU2], [jan.SOU3]]

        'fromReadable() should allow array of PaiKind': ->
            assert.deepEqual PaiKind.fromReadable( '一九①⑨１９東中' ),
                [jan.MAN1, jan.MAN9, jan.PIN1, jan.PIN9, jan.SOU1, jan.SOU9, jan.TON, jan.CHUN]

        'toReadable() should return short string from PaiKind': ->
            assert.equal PaiKind.toReadable( jan.TON), '東'

        'toReadable() should array of PaiKind': ->
            assert.equal PaiKind.toReadable( [jan.MAN1, jan.MAN9, jan.PIN1, jan.PIN9, jan.SOU1, jan.SOU9, jan.TON, jan.CHUN] ),
                '一九①⑨１９東中'


    .export module

vows
    .describe('PaiId')
    .addBatch
        'toKind()は、PaiIdをPaiKindに変換する': ->
            assert.equal PaiId.toKind( PaiId.MAN1_0 ), jan.MAN1
            assert.equal PaiId.toKind( PaiId.MAN1_1 ), jan.MAN1
            assert.equal PaiId.toKind( PaiId.CHUN_2 ), jan.CHUN
            assert.equal PaiId.toKind( PaiId.CHUN_3 ), jan.CHUN
        'toKind()は、PaiIdの配列も処理できる': ->
            assert.deepEqual PaiId.toKind( [PaiId.MAN1_0, PaiId.MAN2_0] ), [jan.MAN1, jan.MAN2]
    .export module

vows
    .describe('Mentsu')
    .addBatch
        'constructor should make Mentsu': ->
            mentsu = new Mentsu('shuntsu', jan.MAN1,0)
            assert.equal mentsu.type, 'shuntsu'
            assert.equal mentsu.pk, jan.MAN1
            assert.equal mentsu.furo, false
            assert.equal mentsu.dir, 0
            mentsu = new Mentsu('koutsu', jan.MAN2,1 )
            assert.equal mentsu.type, 'koutsu'
            assert.equal mentsu.pk, jan.MAN2
            assert.equal mentsu.dir, 1
            assert.equal mentsu.furo, true

        'fromArray() はPaiKindの配列からMentsuを作成する': ->
            assert.deepEqual Mentsu.fromArray( [jan.MAN1, jan.MAN2, jan.MAN3], 0 ), new Mentsu( 'shuntsu', jan.MAN1, 0 )
            assert.deepEqual Mentsu.fromArray( [jan.MAN1, jan.MAN1, jan.MAN1], 1 ), new Mentsu( 'koutsu', jan.MAN1, 1 )
            assert.deepEqual Mentsu.fromArray( [jan.MAN1, jan.MAN1, jan.MAN1, jan.MAN1] ), new Mentsu( 'kantsu', jan.MAN1, 0 )
            assert.deepEqual Mentsu.fromArray( [jan.MAN1, jan.MAN1] ), new Mentsu( 'toitsu', jan.MAN1, 0 )

        'fromArray() はPaiKindの配列の配列からMentsuの配列を作成する': ->
            assert.deepEqual Mentsu.fromArray( jan.PaiKind.fromReadable('１２３ ５５５') ), [new Mentsu( 'shuntsu', jan.SOU1, 0 ), new Mentsu( 'koutsu', jan.SOU5, 0 ) ]
    .export module

vows
    .describe('Yaku')
    .addBatch
        'info()は、薬の情報を返す':->
            info = jan.Yaku.info(jan.Yaku.PINFU)
            assert.equal info.name, '平和'
            assert.equal info.han, 1
            assert.equal info.id, 'PINFU'
    .export module

vows
    .describe('package global')
    .addBatch
        'spliteMentsu() は面子を分解する': ->
            check = (from,to)->
                assert.deepEqual jan.splitMentsu( jan.PaiKind.fromReadable(from) ), jan.PaiKind.fromReadable(to)
            check '七七七八九①①①', ['七七 七八九 ①①①']
            check '１１１２３', ['１１ １２３']
            check '１１１２３４４４', ['１１１ ２３４ ４４','１１ １２３ ４４４']
            check '１１１２２２３３３４４', ['１１１ ２２２ ３３３ ４４','１１ １２３ ２３４ ２３４','１２３ １２３ １２３ ４４']
            check '東東東南南南白白白発発', ['東東東 南南南 白白白 発発']
        'apliteMentsu() は不完全な面子も分解する': ->
            check = (from,to)->
                result = jan.splitMentsu( jan.PaiKind.fromReadable(from), {allowRest:2} ).map (x)->x[0]
                assert.deepEqual result, jan.PaiKind.fromReadable(to)
            check '東東東南南南白白白発', '発 白発 南発 東発'
            check '１１２３４５５', '５５ ２５ １４ １１'
    .addBatch
        'calcYaku()は、役の計算をする': ->
            check = (pkStr, furo, opt, expect )->
                agari = jan.calcYaku( PaiKind.fromReadable(pkStr), Mentsu.fromArray( PaiKind.fromReadable(furo),1), opt )
                #puts '-'
                #puts pkStr, furo
                agari.yaku.sort()
                agari.yaku = Yaku.toString(agari.yaku)
                agari.yakuman.sort()
                agari.yakuman = Yaku.toString(agari.yakuman)
                expect.yaku.sort() if expect.yaku?
                expect.yaku = Yaku.toString(expect.yaku) if expect.yaku?
                expect.yakuman.sort() if expect.yakuman?
                expect.yakuman = Yaku.toString(expect.yakuman) if expect.yakuman?
                #puts yaku, expect
                for x of expect
                    if x == 'yaku' or x == 'yakuman'
                        assert.deepEqual agari[x], expect[x]
                    else
                        assert.equal agari[x], expect[x]
            check '１２３４５６６７８一二三四四', [], {pkLast: PaiKind.SOU1 }, { yaku:[Yaku.PINFU], fu:30 }
            check '１２３４５６６７８一二三四四', [], {pkLast: PaiKind.SOU2}, { yaku:[], machi:'kanchan', fu:40 }
            check '１１１２３４５６７８９９９９' , [], {pkLast: PaiKind.SOU8}, {}
            check '２３４３４５５６７⑦⑦⑧⑧⑧' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.TANYAO]}
            check '１１２２３３７７７⑦⑦⑧⑧⑧' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.IIPEIKOU]}
            check '１１２２３３②②③③④④⑧⑧' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.RYANPEIKOU]}
            check '１２３３４５５６７⑦⑦発発発' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.YAKUHAI]}
            check '１２３３４５東東東⑦⑦発発発' , [], {pkLast: PaiKind.SOU7, pkBakaze:jan.TON}, { yaku:[Yaku.YAKUHAI,Yaku.YAKUHAI] }
            check '１２３９９９①②③東東東発発' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.CHANTA] }
            check '１２３９９９①②③九九七八九' , [], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.JUNCHAN] }
            check '１１１９９９発発' , ['九九九','一一一'], {pkLast: PaiKind.SOU7}, { yaku:[Yaku.HONROUTOU, Yaku.TOITOI] }
            check '１１１９９９⑨⑨' , ['一一一','九九九'], {pkLast: PaiKind.SOU7}, { yakuman:[Yaku.CHINROUTOU] }
            check '東東東南南南発発' , ['西西西','白白白'], {pkLast: PaiKind.SOU7}, { yakuman:[Yaku.TSUIISOU] }
            check '２３４二三四②③④９９９一一' , [], {}, { yaku:[Yaku.SANSHOKU] }
            check '２２２二二二②②②７８９一一' , [], {}, { yaku:[Yaku.SANSHOKU_DOUKOU, Yaku.SANANKO] }
            check '１１１２２２４４４九九九白白' , [], {}, { yakuman:[Yaku.SUUANKOU] }
            check '１１１２２２白白' , ['九九九','４４４'], {}, { yaku:[Yaku.TOITOI] }
            check '５６７白白' , ['九九九九','４４４４','１１１１'], {}, { yaku:[Yaku.SANKANTSU] }
            check '白白' , ['九九九九','４４４４','１１１１','２２２２'], {}, { yakuman:[Yaku.SUUKANTSU] }
            check '⑨⑨' , ['発発発','白白白','中中中','２３４'], {}, { yakuman:[Yaku.DAISANGEN] }
            check '白白' , ['発発発','白白白','⑨⑨⑨','２３４'], {}, { yaku:[Yaku.SHOUSANGEN] }
            check '２２' , '東東東 南南南 西西西 北北北', {}, { yakuman:[Yaku.DAISUUSHII] }
            check '２３４北北' , '東東東 南南南 西西西', {}, { yakuman:[Yaku.SHOUSUUSHII] }

    .export module

