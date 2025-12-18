package elixir;

import elixir.types.Term;

/**
 * Jason: Type-safe extern for Elixir's Jason JSON library
 * 
 * WHY: Provide type-safe access to Elixir's native JSON encoding/decoding
 * without using __elixir__() directly. This is the proper way to integrate
 * with native Elixir libraries.
 * 
 * WHAT: Extern definitions for Jason's encode, decode, and related functions
 * 
 * HOW: Uses @:native metadata to map directly to Jason module functions
 * 
 * @see https://hexdocs.pm/jason/Jason.html
 */
@:native("Jason")
extern class Jason {
    /**
     * Encode a value to JSON string
     * Returns {:ok, json} or {:error, reason}
     */
    @:native("encode")
    public static function encode(term: Term, ?opts: JasonOptions): ElixirResult<String, Term>;
    
    /**
     * Encode a value to JSON string, raises on error
     * @throws JasonEncodeError if encoding fails
     */
    @:native("encode!")
    public static function encodeStrict(term: Term, ?opts: JasonOptions): String;
    
    /**
     * Decode a JSON string
     * Returns {:ok, value} or {:error, reason}
     */
    @:native("decode")
    public static function decode(json: String, ?opts: JasonDecodeOptions): ElixirResult<Term, Term>;
    
    /**
     * Decode a JSON string, raises on error
     * @throws JasonDecodeError if decoding fails
     */
    @:native("decode!")
    public static function decodeStrict(json: String, ?opts: JasonDecodeOptions): Term;
}

/**
 * Options for Jason.encode
 */
typedef JasonOptions = {
    /**
     * Pretty print with indentation
     */
    ?pretty: Bool,
    
    /**
     * Escape mode: :json, :javascript_safe, :html_safe, :unicode_safe
     */
    ?escape: JasonEscapeMode,
    
    /**
     * Map ordering: :unsorted or a custom sort function
     */
    ?maps: Term
}

/**
 * Options for Jason.decode
 */
typedef JasonDecodeOptions = {
    /**
     * How to decode keys: :atoms, :atoms!, :strings, or a custom function
     */
    ?keys: JasonKeyMode,
    
    /**
     * How to decode strings: :copy or :reference
     */
    ?strings: JasonStringMode,
    
    /**
     * How to decode floats: :native or :decimals
     */
    ?floats: JasonFloatMode
}

/**
 * Jason escape modes
 */
enum abstract JasonEscapeMode(String) to String {
    var Json = "json";
    var JavascriptSafe = "javascript_safe";
    var HtmlSafe = "html_safe";
    var UnicodeSafe = "unicode_safe";
}

/**
 * Jason key decoding modes
 */
enum abstract JasonKeyMode(String) to String {
    var Atoms = "atoms";
    var AtomsStrict = "atoms!";
    var Strings = "strings";
}

/**
 * Jason string decoding modes
 */
enum abstract JasonStringMode(String) to String {
    var Copy = "copy";
    var Reference = "reference";
}

/**
 * Jason float decoding modes
 */
enum abstract JasonFloatMode(String) to String {
    var Native = "native";
    var Decimals = "decimals";
}

/**
 * Elixir result type for {:ok, value} or {:error, reason}
 */
@:native("")
extern class ElixirResult<T, E> {
    /**
     * Check if result is {:ok, _}
     */
    public function isOk(): Bool;
    
    /**
     * Check if result is {:error, _}
     */
    public function isError(): Bool;
    
    /**
     * Get the value from {:ok, value}, throws if error
     */
    public function unwrap(): T;
    
    /**
     * Get the error from {:error, error}, throws if ok
     */
    public function unwrapError(): E;
    
    /**
     * Get the value or a default
     */
    public function unwrapOr(defaultValue: T): T;
    
    /**
     * Pattern match helper
     */
    public function match<R>(onOk: (value: T) -> R, onError: (error: E) -> R): R;
}
