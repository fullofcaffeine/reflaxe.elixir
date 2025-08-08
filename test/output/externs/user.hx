package myapp;

#if (elixir || reflaxe_runtime)

// Type definitions
typedef T = Dynamic;

typedef UserStruct = {
    ?id: Dynamic,
    ?name: Dynamic,
    ?email: Dynamic,
    ?age: Dynamic,
    ?active: Dynamic,
}

@:native("MyApp.User")
extern class User {
    @:native("create")
    static function create(arg0: String, arg1: String): Dynamic;

    @:native("create_with_age")
    static function create_with_age(arg0: String, arg1: String, arg2: Int): Dynamic;

    @:native("get_by_id")
    static function get_by_id(arg0: Int): Tuple3<String, Dynamic, String>;

    @:native("update_email")
    static function update_email(arg0: Dynamic, arg1: String): Dynamic;

    @:native("activate")
    static function activate(arg0: Dynamic): Dynamic;

    @:native("deactivate")
    static function deactivate(arg0: Dynamic): Dynamic;

    @:native("is_adult?")
    static function isAdult(arg0: Dynamic): Bool;

    @:native("list_all")
    static function list_all(): Array<Dynamic>;

    @:native("validate_email")
    static function validate_email(arg0: String): Dynamic;

    @:native("some_function_without_spec")
    static function some_function_without_spec(arg0: Dynamic): Dynamic;

}

#end
