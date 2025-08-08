#if (elixir || reflaxe_runtime)

// Type definitions
typedef Number = Dynamic;
typedef Calculation_result = Tuple3<String, Dynamic, String>;

typedef MathHelperStruct = {
    ?value: Dynamic,
    ?precision: Dynamic,
}

@:native("MathHelper")
extern class MathHelper {
    @:native("add")
    static function add(arg0: Int, arg1: Int): Int;

    @:native("multiply")
    static function multiply(arg0: Float, arg1: Float): Float;

    @:native("divide")
    static function divide(arg0: Float, arg1: Float): Dynamic;

    @:native("is_positive?")
    static function isPositive(arg0: Float): Bool;

    @:native("square!")
    static function squareUnsafe(arg0: Float): Float;

    @:native("sum_list")
    static function sum_list(arg0: Array<Float>): Float;

    @:native("get_stats")
    static function get_stats(arg0: Array<Float>): Dynamic;

    @:native("format_number")
    static function format_number(arg0: Float, arg1: Int): String;

    @:native("helper_function")
    static function helper_function(arg0: Dynamic, arg1: Dynamic): Dynamic;

}

#end
