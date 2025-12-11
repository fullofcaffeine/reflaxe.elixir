package server.support;

/**
 * App-local Flash helpers used by generated Phoenix flash map tools.
 */
@:keep
@:native("TodoApp.Flash")
class Flash {
    public static function info(message:String, title:Dynamic):Dynamic {
        return build("info", message, title, null);
    }
    public static function success(message:String, title:Dynamic):Dynamic {
        return build("success", message, title, null);
    }
    public static function warning(message:String, title:Dynamic):Dynamic {
        return build("warning", message, title, null);
    }
    public static function error(message:String, title:Dynamic, details:Dynamic):Dynamic {
        return build("error", message, title, details);
    }

    static inline function build(kind:String, message:String, title:Dynamic, details:Dynamic):Dynamic {
        return {
            type: kind,
            message: message,
            title: title,
            details: details
        };
    }
}
