package;

/**
 * Main Phoenix router configuration
 * Demonstrates @:router annotation with pipeline and scope management
 */
@:router
class AppRouter {
    
    @:pipeline("browser", ["fetch_session", "protect_from_forgery"])
    @:pipeline("api", ["accept_json"])
    
    @:include_controller("UserController")
    @:include_controller("ProductController")
    
    // Router configuration is automatically generated
    // from controller @:route annotations
    public static function main() {
        trace("Phoenix Router DSL Example - App Router");
    }
}