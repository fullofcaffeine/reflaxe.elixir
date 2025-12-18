package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

/**
 * Atom module extern definitions for Elixir standard library
 * Provides type-safe interfaces for atom operations
 * 
 * Maps to Elixir's :erlang atom functions with proper type signatures
 * Atoms are constants with a name, used extensively in Elixir
 */
@:native(":erlang")
extern class Atom {
    
    // Atom conversion
    @:native("atom_to_list")
    static function toCharlist(atom: Term): Array<Int>;
    
    @:native("atom_to_binary")
    static function toString(atom: Term): String;
    
    @:native("atom_to_binary")
    static function toStringWithEncoding(atom: Term, encoding: String): String;
    
    @:native("list_to_atom")
    static function fromCharlist(charlist: Array<Int>): Term;
    
    @:native("binary_to_atom")
    static function fromString(string: String): Term;
    
    @:native("binary_to_atom")
    static function fromStringWithEncoding(string: String, encoding: String): Term;
    
    @:native("list_to_existing_atom")
    static function existingFromCharlist(charlist: Array<Int>): Term;
    
    @:native("binary_to_existing_atom")
    static function existingFromString(string: String): Term;
    
    @:native("binary_to_existing_atom")
    static function existingFromStringWithEncoding(string: String, encoding: String): Term;
    
    // Helper functions for common operations
    public static inline function create(name: String): Term {
        return fromString(name);
    }
    
    public static inline function createSafe(name: String): Term {
        // Use existing atom if available, otherwise create new
        try {
            return existingFromString(name);
        } catch (_: haxe.Exception) {
            return fromString(name);
        }
    }
    
    public static inline function exists(name: String): Bool {
        try {
            existingFromString(name);
            return true;
        } catch (_: haxe.Exception) {
            return false;
        }
    }
    
    public static inline function toStr(atom: Term): String {
        return toString(atom);
    }
    
    public static inline function equals(atom1: Term, atom2: Term): Bool {
        return untyped __elixir__('{0} === {1}', atom1, atom2);
    }
}

/**
 * Common atoms used in Elixir
 */
class CommonAtoms {
    public static inline function ok(): Term {
        return untyped __elixir__(':ok');
    }
    
    public static inline function error(): Term {
        return untyped __elixir__(':error');
    }
    
    public static inline function nil(): Term {
        return untyped __elixir__('nil');
    }
    
    public static inline function true_(): Term {
        return untyped __elixir__('true');
    }
    
    public static inline function false_(): Term {
        return untyped __elixir__('false');
    }
    
    public static inline function undefined(): Term {
        return untyped __elixir__(':undefined');
    }
    
    public static inline function infinity(): Term {
        return untyped __elixir__(':infinity');
    }
    
    public static inline function timeout(): Term {
        return untyped __elixir__(':timeout');
    }
    
    public static inline function normal(): Term {
        return untyped __elixir__(':normal');
    }
    
    public static inline function shutdown(): Term {
        return untyped __elixir__(':shutdown');
    }
    
    public static inline function kill(): Term {
        return untyped __elixir__(':kill');
    }
    
    public static inline function exit(): Term {
        return untyped __elixir__(':exit');
    }
    
    public static inline function throw_(): Term {
        return untyped __elixir__(':throw');
    }
    
    public static inline function badarg(): Term {
        return untyped __elixir__(':badarg');
    }
    
    public static inline function badarith(): Term {
        return untyped __elixir__(':badarith');
    }
    
    public static inline function badmatch(): Term {
        return untyped __elixir__(':badmatch');
    }
    
    public static inline function function_clause(): Term {
        return untyped __elixir__(':function_clause');
    }
    
    public static inline function case_clause(): Term {
        return untyped __elixir__(':case_clause');
    }
    
    public static inline function undef(): Term {
        return untyped __elixir__(':undef');
    }
    
    public static inline function noproc(): Term {
        return untyped __elixir__(':noproc');
    }
    
    public static inline function all(): Term {
        return untyped __elixir__(':all');
    }
    
    public static inline function any(): Dynamic {
        return untyped __elixir__(':any');
    }
    
    public static inline function none(): Dynamic {
        return untyped __elixir__(':none');
    }
}

#end
