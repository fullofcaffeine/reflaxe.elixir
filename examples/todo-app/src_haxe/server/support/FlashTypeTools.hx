package server.support;

import phoenix.types.Flash.FlashType;

/**
 * Application-local flash type helpers expected by generated code.
 */
@:keep
@:native("TodoApp.FlashTypeTools")
class FlashTypeTools {
    public static function to_string(type:FlashType):String {
        return switch (type) {
            case Info: "info";
            case Success: "success";
            case Warning: "warning";
            case Error: "error";
        };
    }

    public static function from_string(str:String):FlashType {
        var lowered = (str != null) ? str.toLowerCase() : "";
        return switch (lowered) {
            case "success": Success;
            case "warning": Warning;
            case "error": Error;
            case _: Info;
        };
    }

    public static function to_phoenix_key(type:FlashType):String {
        return switch (type) {
            case Error: "error";
            case _: "info";
        };
    }
}
