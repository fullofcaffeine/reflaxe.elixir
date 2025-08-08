#if (elixir || reflaxe_runtime)

@:native("Simple")
extern class Simple {
    @:native("hello")
    static function hello(): String;

    @:native("echo")
    static function echo(arg0: Dynamic): Dynamic;

    @:native("no_spec_function")
    static function no_spec_function(): Dynamic;

}

#end
