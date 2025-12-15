package server.infrastructure;

/**
 * PhoenixHaxeExampleWeb HTTP endpoint.
 */
@:native("PhoenixHaxeExampleWeb.Endpoint")
@:endpoint
@:appName("phoenix_haxe_example")
class Endpoint {
    public static function static_paths(): Array<String> {
        return ["assets", "fonts", "images", "favicon.ico", "robots.txt"];
    }
}

