package myapp;

import haxe.ds.Option;
import phoenix.SafePubSub;

/**
 * Regression: SafePubSub.parseWithConverter accepts both function captures and
 * module.function identifiers as string/atom, with module resolved via Macro.camelize.
 *
 * This snapshot ensures the call sites compile and remain stable.
 */
class Main {
    static function main() {
        var msg:Dynamic = { type: "ok" };

        // String form: "todo_pub_sub.parse_msg"
        var _r1 = untyped __elixir__('Phoenix.SafePubSub.parse_with_converter({0}, {1})', msg, "todo_pub_sub.parse_msg");

        // Atom form: :"todo_pub_sub.parse_msg" (via inline Elixir)
        var atomIdent:Dynamic = untyped __elixir__(":\"todo_pub_sub.parse_msg\"");
        var _r2 = untyped __elixir__('Phoenix.SafePubSub.parse_with_converter({0}, {1})', msg, atomIdent);

        // Proper function capture (for completeness): &MyParser.parse/1
        var _r3:Option<String> = SafePubSub.parseWithConverter(msg, MyParser.parse);
    }
}

class MyParser {
    public static function parse(_msg:Dynamic):Option<String> {
        return None;
    }
}
