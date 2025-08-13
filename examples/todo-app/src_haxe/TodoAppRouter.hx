package;

/**
 * Phoenix Router for TodoApp using Haxe Router DSL
 * 
 * Replaces manual router.ex with type-safe Haxe router definition.
 * Demonstrates @:router annotation and Phoenix routing patterns.
 */
@:router
class TodoAppRouter {
    
    /**
     * Browser pipeline routes - main application interface
     */
    @:route({method: "LIVE", path: "/", controller: "TodoLive", action: "index"})
    public static function root(): Void {}
    
    @:route({method: "LIVE", path: "/todos", controller: "TodoLive", action: "index"})
    public static function todosIndex(): Void {}
    
    @:route({method: "LIVE", path: "/todos/:id", controller: "TodoLive", action: "show"})
    public static function todosShow(): Void {}
    
    @:route({method: "LIVE", path: "/todos/:id/edit", controller: "TodoLive", action: "edit"})
    public static function todosEdit(): Void {}
    
    /**
     * Development routes
     */
    @:route({method: "LIVE_DASHBOARD", path: "/dev/dashboard", metrics: "TodoAppWeb.Telemetry"})
    public static function liveDashboard(): Void {}
}