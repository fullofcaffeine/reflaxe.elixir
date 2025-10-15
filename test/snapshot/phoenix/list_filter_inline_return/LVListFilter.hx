package;

import Lambda;

/**
 * LVListFilter
 *
 * WHAT: Create a shape that triggers:
 *  - contains -> Enum.member?
 *  - member? then-branch filter self-compare t != t -> t != tag
 *  - inline return of filtered list instead of returning original
 */
class LVListFilter {
    public static function adjust(selected: Array<String>, tag: String): Array<String> {
        var ret = selected;
        if (Lambda.has(selected, tag)) {
            ret = Lambda.filter(ret, function(t) return t != t);
        }
        return ret;
    }
}

