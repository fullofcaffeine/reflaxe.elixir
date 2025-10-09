package reflaxe.elixir.ir;

#if (macro || reflaxe_runtime)

import haxe.ds.ObjectMap;
import reflaxe.elixir.ir.Symbol;
import reflaxe.elixir.ir.Scope;

/**
 * Hygiene: compute final variable names for Symbols.
 *
 * Input: Symbols with suggestedName, scope, used
 * Output: ObjectMap<Symbol, String> stable final names.
 */
class Hygiene {
    static var RESERVED = [
        "do","end","fn","when","and","or","not","in",
        "true","false","nil","case","cond","receive","try",
        "after","else","catch","rescue","with"
    ];

    static inline function isReserved(s:String):Bool {
        return RESERVED.indexOf(s) != -1;
    }

    static function toSnake(s:String):String {
        if (s == null || s.length == 0) return "v";
        var out = new StringBuf();
        var prevLower = false;
        for (i in 0...s.length) {
            var c = s.charAt(i);
            var upper = c.toUpperCase();
            var lower = c.toLowerCase();
            if (c != lower && c == upper) {
                // uppercase
                if (i > 0 && prevLower) out.add("_");
                out.add(lower);
                prevLower = false;
            } else if (c == "-" || c == " ") {
                out.add("_");
                prevLower = false;
            } else {
                out.add(lower);
                prevLower = true;
            }
        }
        var res = out.toString();
        // collapse repeats
        while (res.indexOf("__") != -1) res = StringTools.replace(res, "__", "_");
        // trim underscores
        while (res.length > 0 && res.charAt(0) == "_") res = res.substr(1);
        if (res.length == 0) res = "v";
        return res;
    }

    public static function computeFinalNames(symbols:Array<Symbol>, scopes:Array<Scope>):ObjectMap<Symbol,String> {
        var result = new ObjectMap<Symbol,String>();
        // Group symbols by scope id
        var byScope = new Map<Int, Array<Symbol>>();
        for (s in symbols) {
            var arr = byScope.get(s.scope);
            if (arr == null) { arr = []; byScope.set(s.scope, arr); }
            arr.push(s);
        }
        // Resolve names per scope independently (child scopes can reuse)
        for (scopeId in byScope.keys()) {
            var usedNames = new Map<String, Bool>();
            var syms = byScope.get(scopeId);
            if (syms == null) continue;
            for (sym in syms) {
                var base = toSnake(sym.suggestedName);
                if (!sym.used) {
                    if (base.charAt(0) != "_") base = "_" + base;
                }
                if (isReserved(base)) base = base + "_";
                var finalName = base;
                var suffix = 1;
                while (usedNames.exists(finalName)) {
                    finalName = base + "_" + suffix++;
                }
                usedNames.set(finalName, true);
                result.set(sym, finalName);
            }
        }
        return result;
    }
}

#end
