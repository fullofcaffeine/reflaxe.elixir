package;

import haxe.extern.EitherType;

// Type alias for {:ok, T} tuples
private typedef Pair = {_0: Int, _1: Int};
// Type alias for {:some, T} produced by OptionWrap
private typedef Some<T> = {_0: elixir.types.Atom, _1: T};

// Typed OptionWrap parsing snapshots (no Dynamic)
// - parse_* functions authored in both switch/case and if/else forms
// - Return types use EitherType<{_0: Atom, _1: T}, Atom>
// - Bodies return typed Atom or typed tuple records so the OptionWrap pass
//   can wrap non-:none results to {:some, v}
class Main {
    static function main() {}

    // Case-authored: {Int, Int} | :none -> wraps to {:some, {Int, Int}} | :none
    public static function parseTuple_case(n: Int): EitherType<Pair, elixir.types.Atom> {
        return switch (n) {
            case 1: ({_0: 1, _1: n} : Pair);
            default: Atoms.NONE;
        }
    }

    // If/else-authored: {Int, Int} | :none -> wraps to {:some, {Int, Int}} | :none
    public static function parseTuple_if(n: Int): EitherType<Pair, elixir.types.Atom> {
        if (n == 1) {
            return ({_0: 1, _1: n} : Pair);
        } else {
            return Atoms.NONE;
        }
    }
}

// Local typed atom constants for tests
class Atoms {
    public static inline var NONE: elixir.types.Atom = "none";
}
