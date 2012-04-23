# nodeとブラウザの両対応用, nodeの場合はそのままで,ブラウザの場合はwindowをexportsとする
if typeof(module) == 'undefined' and typeof(exports) == 'undefined'
    eval('var exports, global; exports = {}; window.janutil = exports; global = window;')

class Enum
    constructor: (names)->
        cur = 0
        @_numberToName = []
        for name in names
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

combinate = (a,i=0)->
    if i == a.length-1
        a[i]
    else
        result = []
        for rest in combinate(a,i+1)
            for head in a[i]
                result.push [head].concat(rest)
        result

prettyPrint = (val,indent='  ')->
    str = JSON.stringify(val)
    if str.length < 500
        str
    else
        if val.length and val.map
            '[\n'+val.map( (x)->indent+ prettyPrint(x,indent+'  ') ).join(',\n')+'\n'+indent[0...-2]+']'
        else if typeof val == 'object'
            result = []
            for k,v of val
                result.push indent+'"'+k+'":'+ prettyPrint(v,indent+'  ')
            '{\n'+result.join(',\n')+'\n'+indent[0...-2]+'}'
        else
            str

pp = (val)->
    puts prettyPrint(val)

exports.Enum = Enum
exports.puts = puts
exports.combinate = combinate
exports.prettyPrint = prettyPrint
exports.pp = pp
global.puts = puts
