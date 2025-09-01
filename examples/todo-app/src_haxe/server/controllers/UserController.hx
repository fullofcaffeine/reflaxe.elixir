package controllers;

import plug.Conn;

// Type-safe parameter definitions for each action
typedef IndexParams = Dynamic;  // No specific params for index
typedef ShowParams = {id: String};
typedef CreateParams = {name: String, email: String, ?age: Int};
typedef UpdateParams = {id: String, ?name: String, ?email: String, ?age: Int};
typedef DeleteParams = {id: String};

/**
 * UserController: Type-safe Phoenix controller showcasing Haxe→Elixir benefits
 * 
 * This controller demonstrates how Haxe brings compile-time type safety to Phoenix
 * web applications while generating idiomatic Elixir code that Phoenix developers
 * will find familiar and maintainable.
 * 
 * ## Annotations Explained
 * 
 * @:native("TodoAppWeb.UserController")
 * - **Purpose**: Specifies the exact Elixir module name to generate
 * - **Why**: Phoenix expects controllers in the `AppNameWeb` namespace
 * - **Benefit**: Follows Phoenix conventions while keeping Haxe package structure clean
 * - **Generated**: `defmodule TodoAppWeb.UserController do`
 * 
 * @:controller  
 * - **Purpose**: Marks this class as a Phoenix controller
 * - **Why**: Triggers controller-specific compilation (adds `use TodoAppWeb, :controller`)
 * - **Benefit**: Automatic Phoenix controller boilerplate and proper action signatures
 * - **Generated**: Includes all Phoenix.Controller functionality
 * 
 * ## Type Safety Benefits
 * 
 * Traditional Phoenix controllers have no compile-time parameter validation:
 * ```elixir
 * def show(conn, %{"id" => id}) do  # Runtime crash if "id" missing
 * ```
 * 
 * With Haxe, we get compile-time guarantees:
 * ```haxe
 * function show(conn: Conn, params: {id: String}): Conn  // Won't compile without id
 * ```
 * 
 * ## Best Practices
 * 
 * 1. **Type your params**: Use anonymous structures for known parameters
 * 2. **Return Conn**: All actions must return a Conn for the pipeline
 * 3. **Use Conn methods**: conn.json(), conn.render(), conn.redirect()
 * 4. **Leverage type inference**: Let Haxe catch missing fields at compile time
 * 
 * @see https://hexdocs.pm/phoenix/Phoenix.Controller.html
 */
@:native("TodoAppWeb.UserController")
@:controller
class UserController {
    
    /**
     * Generate a unique ID for new users
     * Uses Elixir's System.unique_integer for uniqueness
     */
    private static function generateUniqueId(): String {
        return untyped __elixir__('Integer.to_string(System.unique_integer([:positive]))');
    }
    
    /**
     * List all users (GET /api/users)
     * 
     * Traditional Phoenix:
     * ```elixir
     * def index(conn, _params) do
     *   json(conn, %{users: []})
     * end
     * ```
     * 
     * With Haxe, we get type-safe JSON responses and can refactor safely.
     */
    public static function index(conn: Conn<IndexParams>, params: IndexParams): Conn<IndexParams> {
        // Return JSON response with empty users array
        return conn.json({users: []});
    }
    
    /**
     * Show a specific user (GET /api/users/:id)
     * 
     * Notice the type-safe params structure - we KNOW at compile time
     * that 'id' must exist. No runtime pattern matching needed!
     * 
     * @param conn The request connection (typed with ShowParams)
     * @param params Must contain 'id' field (compile-time enforced)
     * @return JSON response with user data
     */
    public static function show(conn: Conn<ShowParams>, params: ShowParams): Conn<ShowParams> {
        // In a real app, you'd fetch from database
        // The type system ensures params.id is always available
        return conn.json({
            user: {
                id: params.id, 
                name: "User " + params.id,
                email: 'user${params.id}@example.com'
            }
        });
    }
    
    /**
     * Create a new user (POST /api/users)
     * 
     * In production, you'd define a proper User type:
     * ```haxe
     * typedef UserParams = {
     *     name: String,
     *     email: String,
     *     ?age: Int  // Optional field
     * }
     * function create(conn: Conn, params: UserParams): Conn
     * ```
     * 
     * This gives you compile-time validation of required fields!
     */
    public static function create(conn: Conn<CreateParams>, params: CreateParams): Conn<CreateParams> {
        // In production: validate, insert to database, return created user
        // Type system ensures params.name and params.email exist!
        return conn.json({
            user: {
                id: generateUniqueId(),
                name: params.name,
                email: params.email,
                age: params.age  // Optional field - may be null
            },
            created: true,
            message: "User created successfully"
        });
    }
    
    /**
     * Update an existing user (PUT /api/users/:id)
     * 
     * Combines URL parameters (id) with body parameters.
     * Type-safe with UpdateParams ensuring id always exists.
     */
    public static function update(conn: Conn<UpdateParams>, params: UpdateParams): Conn<UpdateParams> {
        // The 'id' comes from the URL, other params from request body
        // Type system guarantees params.id exists
        
        // In production: validate, update database, return updated user
        return conn.json({
            user: {
                id: params.id,
                name: params.name != null ? params.name : "Existing Name",
                email: params.email != null ? params.email : "existing@email.com",
                age: params.age
            },
            updated: true,
            message: "User " + params.id + " updated successfully"
        });
    }
    
    /**
     * Delete a user (DELETE /api/users/:id)
     * 
     * Type-safe deletion - the compiler ensures 'id' exists.
     * No need for defensive programming or nil checks!
     */
    public static function delete(conn: Conn<DeleteParams>, params: DeleteParams): Conn<DeleteParams> {
        // In production: delete from database, handle constraints
        return conn.json({
            deleted: params.id, 
            success: true,
            message: 'User ${params.id} deleted successfully'
        });
    }
}