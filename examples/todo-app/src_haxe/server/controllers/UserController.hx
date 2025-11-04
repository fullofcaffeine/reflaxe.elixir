package controllers;

import plug.Conn;
import contexts.Users;
import contexts.Users.UserParams;
import elixir.types.Result;

// Type-safe parameter definitions for each action
typedef IndexParams = {}  // Empty params for index
typedef ShowParams = {id: String};
typedef CreateParams = UserParams;
typedef UpdateParams = {id: String} & UserParams;  // Combine ID with user params
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
     * Uses timestamp and random for uniqueness
     */
    private static function generateUniqueId(): String {
        // Use Haxe's standard library instead of __elixir__()
        var timestamp = Date.now().getTime();
        var random = Math.floor(Math.random() * 10000);
        return '${timestamp}_${random}';
    }
    
    /**
     * List all users (GET /api/users)
     * 
     * Traditional Phoenix:
     * ```elixir
     * def index(conn, _params) do
     *   users = Users.listUsers()
     *   json(conn, %{users: users})
     * end
     * ```
     * 
     * With Haxe, we get type-safe JSON responses and can refactor safely.
     */
    public static function index(conn: Conn<IndexParams>, _params: IndexParams): Conn<IndexParams> {
        // Fetch all users from database
        var users = Users.listUsers(null);
        return conn.json({users: users});
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
        // Fetch user from database
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user != null) {
            return conn.json({user: user});
        } else {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
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
        // Create user through Users context with database persistence
        var result = Users.createUser(params);
        
        return switch(result) {
            case Ok(value):
                conn
                    .putStatus(201)
                    .json({
                        user: value,
                        created: true,
                        message: "User created successfully"
                    });
                    
            case Error(reason):
                conn
                    .putStatus(422)
                    .json({
                        error: "Failed to create user",
                        changeset: reason
                    });
        }
    }
    
    /**
     * Update an existing user (PUT /api/users/:id)
     * 
     * Combines URL parameters (id) with body parameters.
     * Type-safe with UpdateParams ensuring id always exists.
     */
    public static function update(conn: Conn<UpdateParams>, params: UpdateParams): Conn<UpdateParams> {
        // Fetch existing user first
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user == null) {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
        
        // Update user through Users context
        var updateAttrs: UserParams = {
            name: params.name,
            email: params.email,
            age: params.age,
            active: params.active
        };
        
        var result = Users.updateUser(user, updateAttrs);
        
        return switch(result) {
            case Ok(value):
                // Use a named local to avoid any intermediate aliasing of the json/2 payload
                final payload = {
                    user: value,
                    updated: true,
                    message: 'User ${params.id} updated successfully'
                };
                conn.json(payload);
                
            case Error(reason):
                conn
                    .putStatus(422)
                    .json({
                        error: "Failed to update user",
                        changeset: reason
                    });
        }
    }
    
    /**
     * Delete a user (DELETE /api/users/:id)
     * 
     * Type-safe deletion - the compiler ensures 'id' exists.
     * No need for defensive programming or nil checks!
     */
    public static function delete(conn: Conn<DeleteParams>, params: DeleteParams): Conn<DeleteParams> {
        // Fetch user to delete
        var userId = Std.parseInt(params.id);
        var user = Users.getUserSafe(userId);
        
        if (user == null) {
            return conn
                .putStatus(404)
                .json({error: "User not found"});
        }
        
        // Delete user through Users context
        var result = Users.deleteUser(user);
        
        return switch(result) {
            case Ok(_value):
                // Use a named local to avoid any intermediate aliasing of the json/2 payload
                final payload = {
                    deleted: params.id,
                    success: true,
                    message: 'User ${params.id} deleted successfully'
                };
                conn.json(payload);
                
            case Error(_reason):
                conn
                    .putStatus(500)
                    .json({
                        error: "Failed to delete user",
                        success: false
                    });
        }
    }
}
