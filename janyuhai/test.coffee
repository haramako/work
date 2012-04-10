vows = require 'vows'
assert = require 'assert'

class Enum
    constructor: ()->
        cur = 0
        @_indexToName = []
        for name in arguments
            pos = name.indexOf('=')
            if pos >= 0
                cur = parseInt(name.substring(pos+1))
                name = name.substring(0,pos)
            this[name] = cur
            @_indexToName[cur] = name
            cur++
    toString: (idx)->
        if typeof idx is 'number'
            @_indexToName[idx]
        else
            idx.map (i)=>@_indexToName[i]


PaiId = new Enum( 'MAN1=0x10', 'MAN2', 'MAN3', 'MAN4', 'MAN5' )
console.log PaiId
console.log PaiId.toString(16)
console.log PaiId.toString([16,17])

vows
    .describe( 'Person' )
    .addBatch
        'a basic instance':
            topic: ->
                new Enum('One','Two')

            'should get number from name': (topic)->
                assert.equal topic.One, 0
                assert.equal topic.Two, 1

            'should get name from number': (topic)->
                assert.equal topic.toString(0), 'One'
                assert.equal topic.toString(1), 'Two'

        'a number-specified instance': ->
            e = new Enum('One=1', 'Two', 'Five=5')
            assert.equal e.One, 1
            assert.equal e.Two, 2
            assert.equal e.Five, 5
            assert.equal e.toString(1),'One'
            assert.equal e.toString(2),'Two'
            assert.equal e.toString(5),'Five'
            assert.equal 0,1


    .export module
