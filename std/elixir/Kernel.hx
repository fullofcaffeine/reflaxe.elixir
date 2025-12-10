package elixir;

#if (macro || reflaxe_runtime)

/**
 * Kernel module extern definitions for Elixir standard library
 * Provides type-safe interfaces for core Elixir functions
 * 
 * Maps to Elixir's Kernel module functions with proper type signatures
 * These are the most fundamental functions available in any Elixir module
 */
@:native("Kernel")
extern class Kernel {
    
    // Arithmetic operators (as functions)
    @:native("+")
    static function add(left: Dynamic, right: Dynamic): Dynamic;
    
    @:native("-")
    static function subtract(left: Dynamic, right: Dynamic): Dynamic;
    
    @:native("*")
    static function multiply(left: Dynamic, right: Dynamic): Dynamic;
    
    @:native("/")
    static function divide(left: Float, right: Float): Float;
    
    @:native("div")
    static function intDivide(left: Int, right: Int): Int;
    
    @:native("rem")
    static function remainder(left: Int, right: Int): Int;
    
    // Comparison functions
    @:native("==")
    static function equal(left: Dynamic, right: Dynamic): Bool;
    
    @:native("!=")
    static function notEqual(left: Dynamic, right: Dynamic): Bool;
    
    @:native("===")
    static function strictEqual(left: Dynamic, right: Dynamic): Bool;
    
    @:native("!==")
    static function strictNotEqual(left: Dynamic, right: Dynamic): Bool;
    
    @:native("<")
    static function lessThan(left: Dynamic, right: Dynamic): Bool;
    
    @:native("<=")
    static function lessOrEqual(left: Dynamic, right: Dynamic): Bool;
    
    @:native(">")
    static function greaterThan(left: Dynamic, right: Dynamic): Bool;
    
    @:native(">=")
    static function greaterOrEqual(left: Dynamic, right: Dynamic): Bool;
    
    // Boolean operations
    @:native("and")
    static function logicalAnd(left: Bool, right: Bool): Bool;
    
    @:native("or")
    static function logicalOr(left: Bool, right: Bool): Bool;
    
    @:native("not")
    static function logicalNot(value: Bool): Bool;
    
    // Type checking
    @:native("is_atom")
    static function isAtom(term: Dynamic): Bool;
    
    @:native("is_binary")
    static function isBinary(term: Dynamic): Bool;
    
    @:native("is_bitstring")
    static function isBitstring(term: Dynamic): Bool;
    
    @:native("is_boolean")
    static function isBoolean(term: Dynamic): Bool;
    
    @:native("is_float")
    static function isFloat(term: Dynamic): Bool;
    
    @:native("is_function")
    static function isFunction(term: Dynamic): Bool;
    
    @:native("is_function")
    static function isFunctionArity(term: Dynamic, arity: Int): Bool;
    
    @:native("is_integer")
    static function isInteger(term: Dynamic): Bool;
    
    @:native("is_list")
    static function isList(term: Dynamic): Bool;
    
    @:native("is_map")
    static function isMap(term: Dynamic): Bool;
    
    @:native("is_nil")
    static function isNil(term: Dynamic): Bool;
    
    @:native("is_number")
    static function isNumber(term: Dynamic): Bool;
    
    @:native("is_pid")
    static function isPid(term: Dynamic): Bool;
    
    @:native("is_port")
    static function isPort(term: Dynamic): Bool;
    
    @:native("is_reference")
    static function isReference(term: Dynamic): Bool;
    
    @:native("is_tuple")
    static function isTuple(term: Dynamic): Bool;
    
    // Type conversion
    @:native("to_string")
    static function toString(term: Dynamic): String;
    
    @:native("to_charlist")
    static function toCharlist(term: Dynamic): Array<Int>;
    
    // Tuple operations
    @:native("elem")
    static function elem(tuple: Dynamic, index: Int): Dynamic;
    
    @:native("put_elem")
    static function putElem(tuple: Dynamic, index: Int, value: Dynamic): Dynamic;
    
    @:native("tuple_size")
    static function tupleSize(tuple: Dynamic): Int;
    
    // List operations
    @:native("hd")
    static function head(list: Array<Dynamic>): Dynamic;
    
    @:native("tl")
    static function tail(list: Array<Dynamic>): Array<Dynamic>;
    
    @:native("length")
    static function length(list: Array<Dynamic>): Int;
    
    // Map operations
    @:native("map_size")
    static function mapSize(map: Map<Dynamic, Dynamic>): Int;
    
    // Binary operations
    @:native("binary_part")
    static function binaryPart(binary: String, start: Int, length: Int): String;
    
    @:native("bit_size")
    static function bitSize(bitstring: Dynamic): Int;
    
    @:native("byte_size")
    static function byteSize(binary: String): Int;
    
    // Process operations
    @:native("self")
    static function self(): Dynamic; // Returns current process PID
    
    @:native("send")
    static function send(dest: Dynamic, message: Dynamic): Dynamic;
    
    @:native("spawn")
    static function spawn(func: Void -> Void): Dynamic; // Returns PID
    
    @:native("spawn")
    static function spawnModule(module: Dynamic, func: String, args: Array<Dynamic>): Dynamic;
    
    @:native("spawn_link")
    static function spawnLink(func: Void -> Void): Dynamic;
    
    @:native("spawn_monitor")
    static function spawnMonitor(func: Void -> Void): {_0: Dynamic, _1: Dynamic}; // {pid, ref}
    
    // Exception handling
    @:native("raise")
    static function raise(message: String): Void;
    
    @:native("raise")
    static function raiseException(exception: Dynamic, attributes: Array<Dynamic>): Void;
    
    @:native("throw")
    static function throwValue(value: Dynamic): Void;
    
    @:native("exit")
    static function exit(reason: Dynamic): Void;
    
    // Inspection and debugging
    @:native("inspect")
    static function inspect(term: Dynamic, ?options: Map<String, Dynamic>): String;
    
    @:native("dbg")
    static function dbg(value: Dynamic): Dynamic; // Debug helper (Elixir 1.14+)
    
    // Module operations
    @:native("apply")
    static function apply(module: Dynamic, funName: String, args: Array<Dynamic>): Dynamic;
    
    @:native("function_exported?")
    static function functionExported(module: Dynamic, funName: String, arity: Int): Bool;
    
    @:native("macro_exported?")
    static function macroExported(module: Dynamic, macroName: String, arity: Int): Bool;
    
    // Math functions
    @:native("abs")
    static function abs(number: Float): Float;
    
    @:native("ceil")
    static function ceil(number: Float): Int;
    
    @:native("floor")
    static function floor(number: Float): Int;
    
    @:native("round")
    static function round(number: Float): Int;
    
    @:native("trunc")
    static function trunc(number: Float): Int;
    
    @:native("max")
    static function max(a: Dynamic, b: Dynamic): Dynamic;
    
    @:native("min")
    static function min(a: Dynamic, b: Dynamic): Dynamic;
    
    // Node operations
    @:native("node")
    static function node(): Dynamic; // Current node
    
    @:native("node")
    static function nodeOf(pid: Dynamic): Dynamic; // Node of a PID
    
    // Utility functions
    @:native("binding")
    static function binding(): Array<{_0: Dynamic, _1: Dynamic}>; // Current variable bindings
    
    @:native("get_in")
    static function getIn(data: Dynamic, keys: Array<Dynamic>): Dynamic;
    
    @:native("put_in")
    static function putIn(data: Dynamic, keys: Array<Dynamic>, value: Dynamic): Dynamic;
    
    @:native("pop_in")
    static function popIn(data: Dynamic, keys: Array<Dynamic>): {_0: Dynamic, _1: Dynamic};
    
    @:native("update_in")
    static function updateIn(data: Dynamic, keys: Array<Dynamic>, func: Dynamic -> Dynamic): Dynamic;
    
    @:native("struct")
    static function struct(module: Dynamic, ?fields: Map<String, Dynamic>): Dynamic;
    
    @:native("struct!")
    static function structBang(module: Dynamic, fields: Map<String, Dynamic>): Dynamic;
    
    // Range operations
    @:native("Range.new")
    static function range(first: Int, last: Int): Dynamic;
    
    @:native("Range.new")
    static function rangeWithStep(first: Int, last: Int, step: Int): Dynamic;
    
    // Helper functions for common operations
    public static inline function require(condition: Bool, message: String): Void {
        if (!condition) {
            raise(message);
        }
    }
    
    public static inline function ensure(value: Dynamic, message: String): Dynamic {
        if (isNil(value)) {
            raise(message);
        }
        return value;
    }
    
    public static inline function tap<T>(value: T, func: T -> Void): T {
        func(value);
        return value;
    }
    
    public static inline function then<T, R>(value: T, func: T -> R): R {
        return func(value);
    }
    
    public static inline function typeOf(value: Dynamic): String {
        if (isNil(value)) return "nil";
        if (isAtom(value)) return "atom";
        if (isBinary(value)) return "binary";
        if (isBoolean(value)) return "boolean";
        if (isFloat(value)) return "float";
        if (isFunction(value)) return "function";
        if (isInteger(value)) return "integer";
        if (isList(value)) return "list";
        if (isMap(value)) return "map";
        if (isPid(value)) return "pid";
        if (isPort(value)) return "port";
        if (isReference(value)) return "reference";
        if (isTuple(value)) return "tuple";
        return "unknown";
    }
}

#end
