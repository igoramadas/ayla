# SERVER: JSON PATH
# -----------------------------------------------------------------------------
# A JSON implementation for XPath. More info at http://goessner.net/articles/JsonPath/
# Converted to CoffeeScript to keep Ayla's code consistent.

jsonPath = (obj, expr, arg) ->
    P =
        resultType: arg and arg.resultType or "VALUE"
        result: []

        normalize: (expr) ->
            subx = []

            expr.replace(/[\['](\??\(.*?\))[\]']|\['(.*?)'\]/g, ($0, $1, $2) ->
                "[#" + (subx.push($1 or $2) - 1) + "]"
            ).replace(/'?\.'?|\['?/g, ";").replace(/;;;|;;/g, ";..;").replace(/;$|'?\]|'$/g, "").replace /#([0-9]+)/g, ($0, $1) ->
                subx[$1]

        asPath: (path) ->
            x = path.split(";")
            p = "$"
            i = 1
            n = x.length

            while i < n
                p += (if /^[0-9*]+$/.test(x[i]) then ("[" + x[i] + "]") else ("['" + x[i] + "']"))
                i++
            p

        store: (p, v) ->
            P.result[P.result.length] = (if P.resultType is "PATH" then P.asPath(p) else v)  if p
            !!p

        trace: (expr, val, path) ->
            if expr is ""
                P.store path, val
                return

            x = expr.split(";")
            loc = x.shift()
            x = x.join(";")

            if val and val.hasOwnProperty(loc)
                P.trace x, val[loc], path + ";" + loc
            else if loc is "*"
                P.walk loc, x, val, path, (m, l, x, v, p) ->
                    P.trace m + ";" + x, v, p
                    return

            else if loc is ".."
                P.trace x, val, path
                P.walk loc, x, val, path, (m, l, x, v, p) ->
                    typeof v[m] is "object" and P.trace("..;" + x, v[m], p + ";" + m)
                    return

            else if /^\(.*?\)$/.test(loc) # [(expr)]
                P.trace P.eval(loc, val, path.substr(path.lastIndexOf(";") + 1)) + ";" + x, val, path
            else if /^\?\(.*?\)$/.test(loc) # [?(expr)]
                P.walk loc, x, val, path, (m, l, x, v, p) -> # issue 5 resolved
                    P.trace m + ";" + x, v, p  if P.eval(l.replace(/^\?\((.*?)\)$/, "$1"), (if v instanceof Array then v[m] else v), m)
                    return

            else if /^(-?[0-9]*):(-?[0-9]*):?([0-9]*)$/.test(loc) # [start:end:step]  phyton slice syntax
                P.slice loc, x, val, path
            else if /,/.test(loc) # [name1,name2,...]
                s = loc.split(/'?,'?/)
                i = 0
                n = s.length

                while i < n
                    P.trace s[i] + ";" + x, val, path
                    i++

            return

        walk: (loc, expr, val, path, f) ->
            if val instanceof Array
                i = 0
                n = val.length

                while i < n
                    f i, loc, expr, val, path  if i of val
                    i++
            else if typeof val is "object"
                for m of val
                    continue
            return

        slice: (loc, expr, val, path) ->
            if val instanceof Array
                len = val.length
                start = 0
                end = len
                step = 1
                loc.replace /^(-?[0-9]*):(-?[0-9]*):?(-?[0-9]*)$/g, ($0, $1, $2, $3) ->
                    start = parseInt($1 or start)
                    end = parseInt($2 or end)
                    step = parseInt($3 or step)
                    return

                start = (if (start < 0) then Math.max(0, start + len) else Math.min(len, start))
                end = (if (end < 0) then Math.max(0, end + len) else Math.min(len, end))
                i = start

                while i < end
                    P.trace i + ";" + expr, val, path
                    i += step
            return

        eval: (x, _v) ->
            try
                return $ and _v and eval_(x.replace(/(^|[^\\])@/g, "$1_v").replace(/\\@/g, "@"))
            catch e
                throw new SyntaxError("jsonPath: " + e.message + ": " + x.replace(/(^|[^\\])@/g, "$1_v").replace(/\\@/g, "@"))
            return

    $ = obj
    if expr and obj and (P.resultType is "VALUE" or P.resultType is "PATH")
        P.trace P.normalize(expr).replace(/^\$;?/, ""), obj, "$"
        (if P.result.length then P.result else null)

module.exports = exports = jsonPath