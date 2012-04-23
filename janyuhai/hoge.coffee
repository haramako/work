janutil = require './janutil'
_ = require 'underscore'

class Buffer
    constructor: (key)->
        @key = key.slice()
        @keyLength = @key.length
        @idx = 0

    crypt: (array)->
        result = []
        for c,i in array
            result.push ( c ^ @key[@idx] )
            @key[@idx] = ( @key[@idx] << 1 ) & 0xffff | ( @key[@idx] >> 15 )
            @idx = (@idx+1)%@keyLength
        result

    decrypt: (array)->@crypt(array)

data = (Math.floor(Math.random()*65536) for i in [0...999998])
key = (Math.floor(Math.random()*65536) for i in [0...8])
buf = new Buffer(key)

c = buf.crypt(data)
buf = new Buffer(key)
c2 = buf.decrypt(c)

if _.isEqual( data, c2 )
    puts 'ok'

###
puts c
puts c2
puts data
###
