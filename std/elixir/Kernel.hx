package elixir;

#if (macro || reflaxe_runtime)

import elixir.types.Term;

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
    static function add(left: Term, right: Term): Term;
    
    @:native("-")
    static function subtract(left: Term, right: Term): Term;
    
    @:native("*")
    static function multiply(left: Term, right: Term): Term;
    
    @:native("/")
    static function divide(left: Float, right: Float): Float;
    
    @:native("div")
    static function intDivide(left: Int, right: Int): Int;
    
    @:native("rem")
    static function remainder(left: Int, right: Int): Int;
    
    // Comparison functions
    @:native("==")
    static function equal(left: Term, right: Term): Bool;
    
    @:native("!=")
    static function notEqual(left: Term, right: Term): Bool;
    
    @:native("===")
    static function strictEqual(left: Term, right: Term): Bool;
    
    @:native("!==")
    static function strictNotEqual(left: Term, right: Term): Bool;
    
    @:native("<")
    static function lessThan(left: Term, right: Term): Bool;
    
    @:native("<=")
    static function lessOrEqual(left: Term, right: Term): Bool;
    
    @:native(">")
    static function greaterThan(left: Term, right: Term): Bool;
    
    @:native(">=")
    static function greaterOrEqual(left: Term, right: Term): Bool;
    
    // Boolean operations
    @:native("and")
    static function logicalAnd(left: Bool, right: Bool): Bool;
    
    @:native("or")
    static function logicalOr(left: Bool, right: Bool): Bool;
    
    @:native("not")
    static function logicalNot(value: Bool): Bool;
    
    // Type checking
    @:native("is_atom")
    static function isAtom(term: Term): Bool;
    
    @:native("is_binary")
    static function isBinary(term: Term): Bool;
    
    @:native("is_bitstring")
    static function isBitstring(term: Term): Bool;
    
    @:native("is_boolean")
    static function isBoolean(term: Term): Bool;
    
    @:native("is_float")
    static function isFloat(term: Term): Bool;
    
    @:native("is_function")
    static function isFunction(term: Term): Bool;
    
    @:native("is_function")
    static function isFunctionArity(term: Term, arity: Int): Bool;
    
    @:native("is_integer")
    static function isInteger(term: Term): Bool;
    
    @:native("is_list")
    static function isList(term: Term): Bool;
    
    @:native("is_map")
    static function isMap(term: Term): Bool;
    
    @:native("is_nil")
    static function isNil(term: Term): Bool;
    
    @:native("is_number")
    static function isNumber(term: Term): Bool;
    
    @:native("is_pid")
    static function isPid(term: Term): Bool;
    
    @:native("is_port")
    static function isPort(term: Term): Bool;
    
    @:native("is_reference")
    static function isReference(term: Term): Bool;
    
    @:native("is_tuple")
    static function isTuple(term: Term): Bool;
    
    // Type conversion
    @:native("to_string")
    static function toString(term: Term): String;
    
    @:native("to_charlist")
    static function toCharlist(term: Term): Array<Int>;
    
    // Tuple operations
    @:native("elem")
    static function elem(tuple: Term, index: Int): Term;
    
    @:native("put_elem")
    static function putElem(tuple: Term, index: Int, value: Term): Term;
    
    @:native("tuple_size")
    static function tupleSize(tuple: Term): Int;
    
    // List operations
    @:native("hd")
    static function head(list: Array<Term>): Term;
    
    @:native("tl")
    static function tail(list: Array<Term>): Array<Term>;
    
    @:native("length")
    static function length(list: Array<Term>): Int;
    
    // Map operations
    @:native("map_size")
    static function mapSize(map: Term): Int;
    
    // Binary operations
    @:native("binary_part")
    static function binaryPart(binary: String, start: Int, length: Int): String;
    
    @:native("bit_size")
    static function bitSize(bitstring: Term): Int;
    
    @:native("byte_size")
    static function byteSize(binary: String): Int;
    
    // Process operations
    @:native("self")
    static function self(): Term; // Returns current process PID
    
    @:native("send")
    static function send(dest: Term, message: Term): Term;
    
    @:native("spawn")
    static function spawn(func: Void -> Void): Term; // Returns PID
    
    @:native("spawn")
    static function spawnModule(module: Term, func: String, args: Array<Term>): Term;
    
    @:native("spawn_link")
    static function spawnLink(func: Void -> Void): Term;
    
    @:native("spawn_monitor")
    static function spawnMonitor(func: Void -> Void): {_0: Term, _1: Term}; // {pid, ref}
    
    // Exception handling
    @:native("raise")
    static function raise(message: String): Void;
    
    @:native("raise")
    static function raiseException(exception: Term, attributes: Array<Term>): Void;
    
    @:native("throw")
    static function throwValue(value: Term): Void;
    
    @:native("exit")
    static function exit(reason: Term): Void;
    
    // Inspection and debugging
    @:native("inspect")
    static function inspect(term: Term, ?options: Map<String, Term>): String;
    
    @:native("dbg")
    static function dbg(value: Term): Term; // Debug helper (Elixir 1.14+)
    
    // Module operations
    @:native("apply")
    static function apply(module: Term, funName: String, args: Array<Term>): Term;
    
    @:native("function_exported?")
    static function functionExported(module: Term, funName: String, arity: Int): Bool;
    
    @:native("macro_exported?")
    static function macroExported(module: Term, macroName: String, arity: Int): Bool;
    
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
    static function max(a: Term, b: Term): Term;
    
    @:native("min")
    static function min(a: Term, b: Term): Term;
    
    // Node operations
    @:native("node")
    static function node(): Term; // Current node
    
    @:native("node")
    static function nodeOf(pid: Term): Term; // Node of a PID
    
    // Utility functions
    @:native("binding")
    static function binding(): Array<{_0: Term, _1: Term}>; // Current variable bindings
    
    @:native("get_in")
    static function getIn(data: Term, keys: Array<Term>): Term;
    
    @:native("put_in")
    static function putIn(data: Term, keys: Array<Term>, value: Term): Term;
    
    @:native("pop_in")
    static function popIn(data: Term, keys: Array<Term>): {_0: Term, _1: Term};
    
    @:native("update_in")
    static function updateIn(data: Term, keys: Array<Term>, func: Term -> Term): Term;
    
    @:native("struct")
    static function struct(module: Term, ?fields: Map<String, Term>): Term;
    
    @:native("struct!")
    static function structBang(module: Term, fields: Map<String, Term>): Term;
    
    // Range operations
    @:native("Range.new")
    static function range(first: Int, last: Int): Term;
    
    @:native("Range.new")
    static function rangeWithStep(first: Int, last: Int, step: Int): Term;
    
    // Helper functions for common operations
    public static inline function require(condition: Bool, message: String): Void {
        if (!condition) {
            raise(message);
        }
    }
    
    public static inline function ensure(value: Term, message: String): Term {
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
    
    public static inline function typeOf(value: Term): String {
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
