package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Type-safe Router DSL example demonstrating enhanced syntax
 * 
 * This example shows how to use HttpMethod enum and class references
 * instead of error-prone string literals for better compile-time safety.
 */
@:router
@:build(reflaxe.elixir.macros.RouterBuildMacro.generateRoutes())
@:routes([
    // Type-safe method using HttpMethod enum
    {
        name: "root", 
        method: HttpMethod.LIVE, 
        path: "/", 
        controller: "server.live.TodoLive",  // this is not type safe, needs to be the actual controller type. This DSL should be as expressive as the Elixir one, but typesafe.
        action: "index"
    },
    
    // Standard HTTP methods with enum
    {
        name: "todosIndex", 
        method: HttpMethod.LIVE, 
        path: "/todos", 
        controller: "server.live.TodoLive", 
        action: "index"
    },
    
    {
        name: "todosShow", 
        method: HttpMethod.LIVE, 
        path: "/todos/:id", 
        controller: "server.live.TodoLive", 
        action: "show"
    },
    
    {
        name: "todosEdit", 
        method: HttpMethod.LIVE, 
        path: "/todos/:id/edit", 
        controller: "server.live.TodoLive", 
        action: "edit"
    },
    
    // API endpoints with real controller validation
    {
        name: "apiUsers", 
        method: HttpMethod.GET, 
        path: "/api/users", 
        controller: "controllers.UserController", 
        action: "index"
    },
    
    {
        name: "apiCreateUser", 
        method: HttpMethod.POST, 
        path: "/api/users", 
        controller: "controllers.UserController", 
        action: "create"
    },
    
    {
        name: "apiUpdateUser", 
        method: HttpMethod.PUT, 
        path: "/api/users/:id", 
        controller: "controllers.UserController", 
        action: "update"
    },
    
    {
        name: "apiDeleteUser", 
        method: HttpMethod.DELETE, 
        path: "/api/users/:id", 
        controller: "controllers.UserController", 
        action: "delete"
    },
    
    // Test invalid controller (should show warning)
    {
        name: "testInvalid", 
        method: HttpMethod.GET, 
        path: "/test", 
        controller: "NonExistentController", 
        action: "nonExistentAction"
    },
    
    // LiveDashboard with enum
    {
        name: "dashboard", 
        method: HttpMethod.LIVE_DASHBOARD, 
        path: "/dev/dashboard"
    }
])
class TodoAppRouter {
    // Functions auto-generated with type-safe route helpers!
    // 
    // Generated functions:
    // public static function root(): String { return "/"; }
    // public static function todosIndex(): String { return "/todos"; }
    // public static function apiTodos(): String { return "/api/todos"; }
    // etc.
}
