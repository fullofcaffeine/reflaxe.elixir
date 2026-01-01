package;

import reflaxe.elixir.macros.HttpMethod;

/**
 * Type-safe Router DSL example demonstrating enhanced syntax
 * 
 * This example shows how to use HttpMethod enum and class references
 * instead of error-prone string literals for better compile-time safety.
 */
@:native("TodoAppWeb.Router")
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

    // Optional demo login + profile
    {
        name: "login",
        method: HttpMethod.LIVE,
        path: "/login",
        controller: "server.live.AuthLive",
        action: "index"
    },

    {
        name: "profile",
        method: HttpMethod.LIVE,
        path: "/profile",
        controller: "server.live.ProfileLive",
        action: "show"
    },

    {
        name: "users",
        method: HttpMethod.LIVE,
        path: "/users",
        controller: "server.live.UsersLive",
        action: "index"
    },

    // Session endpoints (set/clear Plug session)
    {
        name: "authLogin",
        method: HttpMethod.POST,
        path: "/auth/login",
        controller: "controllers.SessionController",
        action: "create"
    },

    // Optional GitHub OAuth login (requires env vars; demo login remains available)
    {
        name: "authGithub",
        method: HttpMethod.GET,
        path: "/auth/github",
        controller: "controllers.GithubOAuthController",
        action: "github"
    },

    {
        name: "authGithubCallback",
        method: HttpMethod.GET,
        path: "/auth/github/callback",
        controller: "controllers.GithubOAuthController",
        action: "github_callback"
    },

    {
        name: "authLogout",
        method: HttpMethod.POST,
        path: "/auth/logout",
        controller: "controllers.SessionController",
        action: "delete"
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
    
    // API endpoints temporarily removed until User context/schema stabilized
    
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
