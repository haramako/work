jan = require './jan'
vows = require 'vows'
assert = require 'assert'

vows
    .describe('PaiId')
    .addBatch
        'toString()': ->
            assert.equal jan.PaiId.toString(jan.MAN1), 'MAN1'

        'kind() should return kind from PaiId': ->
            assert.equal jan.PaiId.toKind( jan.MAN1 ), jan.MANZU
            assert.equal jan.PaiId.toKind( jan.PIN1 ), jan.PINZU
            assert.equal jan.PaiId.toKind( jan.SOU1 ), jan.SOUZU
            assert.equal jan.PaiId.toKind( jan.TON ), jan.JIHAI

        'fromReadableString() should return PaiId from readable string': ->
            assert.equal jan.PaiId.fromReadable( '東' ), jan.TON

        'fromReadable() should allow space-splited string': ->
            assert.deepEqual jan.PaiId.fromReadable( '１２ ３' ),
                [[jan.SOU1, jan.SOU2], [jan.SOU3]]

        'fromReadable() should allow array of PaiId': ->
            assert.deepEqual jan.PaiId.fromReadable( '一九①⑨１９東中' ),
                [jan.MAN1, jan.MAN9, jan.PIN1, jan.PIN9, jan.SOU1, jan.SOU9, jan.TON, jan.CHUN]

        'toReadable() should return short string from PaiId': ->
            assert.equal jan.PaiId.toReadable( jan.TON), '東'

        'toReadable() should array of PaiId': ->
            assert.equal jan.PaiId.toReadable( [jan.MAN1, jan.MAN9, jan.PIN1, jan.PIN9, jan.SOU1, jan.SOU9, jan.TON, jan.CHUN] ),
                '一九①⑨１９東中'


    .export module

vows
    .describe('Mentsu')
    .addBatch
        'constructor should make Mentsu': ->
            mentsu = new jan.Mentsu('shuntsu', jan.MAN1,true)
            assert.equal mentsu.type, 'shuntsu'
            assert.equal mentsu.from, jan.MAN1
            assert.equal mentsu.furo, true
            mentsu = new jan.Mentsu('koutsu', jan.MAN2 )
            assert.equal mentsu.type, 'koutsu'
            assert.equal mentsu.from, jan.MAN2
            assert.equal mentsu.furo, false

        'fromArray() はPaiIdの配列からMentsuを作成する': ->
            assert.deepEqual jan.Mentsu.fromArray( [jan.MAN1, jan.MAN2, jan.MAN3], false ), new jan.Mentsu( 'shuntsu', jan.MAN1, false )
            assert.deepEqual jan.Mentsu.fromArray( [jan.MAN1, jan.MAN1, jan.MAN1], true ), new jan.Mentsu( 'koutsu', jan.MAN1, true )
            assert.deepEqual jan.Mentsu.fromArray( [jan.MAN1, jan.MAN1, jan.MAN1, jan.MAN1] ), new jan.Mentsu( 'kantsu', jan.MAN1 )
            assert.deepEqual jan.Mentsu.fromArray( [jan.MAN1, jan.MAN1] ), new jan.Mentsu( 'toitsu', jan.MAN1 )

        'fromArray() はPaiIdの配列の配列からMentsuの配列を作成する': ->
            assert.deepEqual jan.Mentsu.fromArray( jan.PaiId.fromReadable('１２３ ５５５') ), [new jan.Mentsu( 'shuntsu', jan.SOU1 ), new jan.Mentsu( 'koutsu', jan.SOU5 ) ]
    .export module

vows
    .describe('package global')
    .addBatch
        'spliteMentsu() は面子を分解する': ->
            check = (from,to)->
                assert.deepEqual jan.splitMentsu( jan.PaiId.fromReadable(from) ), jan.PaiId.fromReadable(to)
            check '七七七八九①①①', ['七七 七八九 ①①①']
            check '１１１２３', ['１１ １２３']
            check '１１１２３４４４', ['１１１ ２３４ ４４','１１ １２３ ４４４']
            check '１１１２２２３３３４４', ['１１１ ２２２ ３３３ ４４','１１ １２３ ２３４ ２３４','１２３ １２３ １２３ ４４']
            check '東東東南南南白白白発発', ['東東東 南南南 白白白 発発']


    .export module


