package elixir;

#if (macro || reflaxe_runtime)

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
    static function toCharlist(atom: Dynamic): Array<Int>;
    
    @:native("atom_to_binary")
    static function toString(atom: Dynamic): String;
    
    @:native("atom_to_binary")
    static function toStringWithEncoding(atom: Dynamic, encoding: String): String;
    
    @:native("list_to_atom")
    static function fromCharlist(charlist: Array<Int>): Dynamic;
    
    @:native("binary_to_atom")
    static function fromString(string: String): Dynamic;
    
    @:native("binary_to_atom")
    static function fromStringWithEncoding(string: String, encoding: String): Dynamic;
    
    @:native("list_to_existing_atom")
    static function existingFromCharlist(charlist: Array<Int>): Dynamic;
    
    @:native("binary_to_existing_atom")
    static function existingFromString(string: String): Dynamic;
    
    @:native("binary_to_existing_atom")
    static function existingFromStringWithEncoding(string: String, encoding: String): Dynamic;
    
    // Helper functions for common operations
    public static inline function create(name: String): Dynamic {
        return fromString(name);
    }
    
    public static inline function createSafe(name: String): Dynamic {
        // Use existing atom if available, otherwise create new
        try {
            return existingFromString(name);
        } catch (e: Dynamic) {
            return fromString(name);
        }
    }
    
    public static inline function exists(name: String): Bool {
        try {
            existingFromString(name);
            return true;
        } catch (e: Dynamic) {
            return false;
        }
    }
    
    public static inline function toStr(atom: Dynamic): String {
        return toString(atom);
    }
    
    public static inline function equals(atom1: Dynamic, atom2: Dynamic): Bool {
        return untyped __elixir__('{0} === {1}', atom1, atom2);
    }
}

/**
 * Common atoms used in Elixir
 */
class CommonAtoms {
    public static inline function ok(): Dynamic {
        return untyped __elixir__(':ok');
    }
    
    public static inline function error(): Dynamic {
        return untyped __elixir__(':error');
    }
    
    public static inline function nil(): Dynamic {
        return untyped __elixir__('nil');
    }
    
    public static inline function true_(): Dynamic {
        return untyped __elixir__('true');
    }
    
    public static inline function false_(): Dynamic {
        return untyped __elixir__('false');
    }
    
    public static inline function undefined(): Dynamic {
        return untyped __elixir__(':undefined');
    }
    
    public static inline function infinity(): Dynamic {
        return untyped __elixir__(':infinity');
    }
    
    public static inline function timeout(): Dynamic {
        return untyped __elixir__(':timeout');
    }
    
    public static inline function normal(): Dynamic {
        return untyped __elixir__(':normal');
    }
    
    public static inline function shutdown(): Dynamic {
        return untyped __elixir__(':shutdown');
    }
    
    public static inline function kill(): Dynamic {
        return untyped __elixir__(':kill');
    }
    
    public static inline function exit(): Dynamic {
        return untyped __elixir__(':exit');
    }
    
    public static inline function throw_(): Dynamic {
        return untyped __elixir__(':throw');
    }
    
    public static inline function badarg(): Dynamic {
        return untyped __elixir__(':badarg');
    }
    
    public static inline function badarith(): Dynamic {
        return untyped __elixir__(':badarith');
    }
    
    public static inline function badmatch(): Dynamic {
        return untyped __elixir__(':badmatch');
    }
    
    public static inline function function_clause(): Dynamic {
        return untyped __elixir__(':function_clause');
    }
    
    public static inline function case_clause(): Dynamic {
        return untyped __elixir__(':case_clause');
    }
    
    public static inline function undef(): Dynamic {
        return untyped __elixir__(':undef');
    }
    
    public static inline function noproc(): Dynamic {
        return untyped __elixir__(':noproc');
    }
    
    public static inline function all(): Dynamic {
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