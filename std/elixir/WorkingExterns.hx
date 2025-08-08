package elixir;

#if (macro || reflaxe_runtime)

/**
 * Working Elixir standard library extern definitions
 * Uses simple Dynamic types to avoid Haxe built-in conflicts
 */

// Elixir Enumerable functions
extern class Enumerable {
    @:native("Enum.map")
    public static function map<T, U>(enumerable: Array<T>, func: T -> U): Array<U>;
    
    @:native("Enum.filter")
    public static function filter<T>(enumerable: Array<T>, func: T -> Bool): Array<T>;
    
    @:native("Enum.reduce")
    public static function reduce<T, A>(enumerable: Array<T>, acc: A, func: (T, A) -> A): A;
    
    @:native("Enum.count")
    public static function count<T>(enumerable: Array<T>): Int;
    
    @:native("Enum.find")
    public static function find<T>(enumerable: Array<T>, func: T -> Bool): Null<T>;
    
    @:native("Enum.member?")
    public static function member<T>(enumerable: Array<T>, element: T): Bool;
}

// Elixir Map functions using Dynamic to avoid conflicts
extern class ElixirMap {
    @:native("Map.new")
    public static function new_(): Dynamic;
    
    @:native("Map.put")
    public static function put(map: Dynamic, key: Dynamic, value: Dynamic): Dynamic;
    
    @:native("Map.get")
    public static function get(map: Dynamic, key: Dynamic): Dynamic;
    
    @:native("Map.has_key?")
    public static function hasKey(map: Dynamic, key: Dynamic): Bool;
    
    @:native("Map.size")
    public static function size(map: Dynamic): Int;
    
    @:native("Map.keys")
    public static function keys(map: Dynamic): Array<Dynamic>;
    
    @:native("Map.values")
    public static function values(map: Dynamic): Array<Dynamic>;
}

// Elixir List functions
extern class ElixirList {
    @:native("List.first")
    public static function first<T>(list: Array<T>): Null<T>;
    
    @:native("List.last")
    public static function last<T>(list: Array<T>): Null<T>;
    
    @:native("List.flatten")
    public static function flatten<T>(list: Array<Array<T>>): Array<T>;
    
    @:native("List.duplicate")
    public static function duplicate<T>(element: T, count: Int): Array<T>;
    
    @:native("List.insert_at")
    public static function insertAt<T>(list: Array<T>, index: Int, value: T): Array<T>;
}

// Elixir String functions using Dynamic to avoid conflicts
extern class ElixirString {
    @:native("String.length")
    public static function length(string: String): Int;
    
    @:native("String.trim")
    public static function trim(string: String): String;
    
    @:native("String.downcase")
    public static function downcase(string: String): String;
    
    @:native("String.upcase")
    public static function upcase(string: String): String;
    
    @:native("String.split")
    public static function split(string: String): Array<String>;
    
    @:native("String.contains?")
    public static function contains(string: String, substring: String): Bool;
    
    @:native("String.starts_with?")
    public static function startsWith(string: String, prefix: String): Bool;
    
    @:native("String.replace")
    public static function replace(string: String, pattern: String, replacement: String): String;
}

// Elixir Process functions
extern class ElixirProcess {
    @:native("Process.self")
    public static function self(): Dynamic;
    
    @:native("Process.spawn")
    public static function spawn(func: Void -> Void): Dynamic;
    
    @:native("Process.send")
    public static function send(dest: Dynamic, message: Dynamic): Dynamic;
    
    @:native("Process.alive?")
    public static function alive(pid: Dynamic): Bool;
}

// ElixirAtom enum for GenServer return tuples
enum ElixirAtom {
    OK;
    STOP;
    REPLY;
    NOREPLY; 
    CONTINUE;
    HIBERNATE;
}

// Elixir GenServer functions with ElixirAtom types
extern class GenServer {
    @:native("GenServer.start")
    public static function start(module: String, initArg: Dynamic): Dynamic;
    
    @:native("GenServer.call")
    public static function call(serverRef: Dynamic, request: Dynamic): Dynamic;
    
    @:native("GenServer.cast")
    public static function sendCast(serverRef: Dynamic, request: Dynamic): ElixirAtom;
    
    @:native("GenServer.stop")
    public static function stop(serverRef: Dynamic): ElixirAtom;
    
    // Constants
    public static inline var OK: ElixirAtom = ElixirAtom.OK;
    public static inline var REPLY: ElixirAtom = ElixirAtom.REPLY;
    public static inline var NOREPLY: ElixirAtom = ElixirAtom.NOREPLY;
    public static inline var STOP: ElixirAtom = ElixirAtom.STOP;
    public static inline var CONTINUE: ElixirAtom = ElixirAtom.CONTINUE;
    public static inline var HIBERNATE: ElixirAtom = ElixirAtom.HIBERNATE;
    
    // Helper functions
    public static inline function replyTuple<T, S>(reply: T, state: S): {_0: ElixirAtom, _1: T, _2: S} {
        return {_0: REPLY, _1: reply, _2: state};
    }
    
    public static inline function noreplyTuple<S>(state: S): {_0: ElixirAtom, _1: S} {
        return {_0: NOREPLY, _1: state};
    }
    
    public static inline function stopTuple<R, S>(reason: R, state: S): {_0: ElixirAtom, _1: R, _2: S} {
        return {_0: STOP, _1: reason, _2: state};
    }
    
    public static inline function continueTuple<S, C>(state: S, continue_: C): {_0: ElixirAtom, _1: S, _2: C} {
        return {_0: CONTINUE, _1: state, _2: continue_};
    }
    
    public static inline function hibernateTuple<S>(state: S): {_0: ElixirAtom, _1: S, _2: ElixirAtom} {
        return {_0: NOREPLY, _1: state, _2: HIBERNATE};
    }
}

#end