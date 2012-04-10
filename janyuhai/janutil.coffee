class Enum
    constructor: ()->
        cur = 0
        @_numberToName = []
        for name in arguments
            pos = name.indexOf('=')
            if pos >= 0
                cur = parseInt(name.substring(pos+1))
                name = name.substring(0,pos)
            this[name] = cur
            @_numberToName[cur] = name
            cur++
        @MAX = cur
    toString: (num)->
        if typeof num == 'number'
            @_numberToName[num]
        else if num.map
            num.map (i)=>this.toString( i )
        else
            num
    exportTo: (module, prefix )->
        prefix ?= ''
        for i in [0...@_numberToName.length]
            module[prefix + @_numberToName[i]] = i
        this

puts = -> console.log.apply console, arguments

exports.Enum = Enum
exports.puts = puts
global.puts = puts
