package controllers;

import plug.Conn;
import contexts.Accounts;
import contexts.Users;
import elixir.ElixirMap;
import elixir.Kernel;
import elixir.types.Term;
import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.TimePrecision;
import haxe.functional.Result;
import server.infrastructure.Repo;
import server.schemas.User;
import StringTools;

// Type-safe parameter definitions for each action
typedef IndexParams = {}  // Empty params for index
typedef ShowParams = {id: String};
typedef CreateParams = {
    name: String,
    email: String,
    ?bio: String,
    ?role: String,
    ?active: Bool
};
typedef UpdateParams = {
    id: String,
    ?name: String,
    ?email: String,
    ?bio: String,
    ?role: String,
    ?active: Bool
};
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
	    static function error<TParams>(conn: Conn<TParams>, status: Int, message: String): Conn<TParams> {
	        return conn
	            .putStatus(status)
	            .json({error: message});
	    }

	    static function parseSessionUserId(term: Term): Null<Int> {
	        if (term == null) return null;
	        var parsed = Std.parseInt(Std.string(term));
	        return parsed;
	    }

	    static function currentUserFromSession<TParams>(conn: Conn<TParams>): Null<User> {
	        var userIdTerm: Term = conn.getSession("user_id");
	        var userId = parseSessionUserId(userIdTerm);
	        if (userId == null) return null;

	        var currentUser: Null<User> = Repo.get(User, userId);
	        return currentUser;
	    }

	    static function userJson(user: User): Term {
	        return cast {
	            id: user.id,
	            name: user.name,
	            email: user.email,
	            bio: user.bio,
	            role: user.role,
	            organization_id: user.organizationId,
	            active: user.active
	        };
	    }

	    static function normalizeRole(value: Null<String>): String {
	        if (value == null) return "user";
	        var role = StringTools.trim(value).toLowerCase();
	        return (role == "admin" || role == "user") ? role : "user";
	    }
	    
	    /**
	     * Generate a unique ID for new users
	     * Uses timestamp and random for uniqueness
     */
    private static function generateUniqueId(): String {
        // Use Haxe's standard library (avoid raw Elixir injection)
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
	    public static function index(conn: Conn<IndexParams>, params: IndexParams): Conn<IndexParams> {
	        var currentUser = currentUserFromSession(conn);
	        if (currentUser == null) return error(conn, 401, "Unauthorized");
	        if (currentUser.role != "admin") return error(conn, 403, "Forbidden");

	        var users = Users.listUsersForOrganization(currentUser.organizationId, null);
	        var safeUsers: Array<Term> = users.map(u -> userJson(u));
	        return conn.json({users: safeUsers});
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
	        var currentUser = currentUserFromSession(conn);
	        if (currentUser == null) return error(conn, 401, "Unauthorized");
	        if (currentUser.role != "admin") return error(conn, 403, "Forbidden");

	        var userId = Std.parseInt(params.id);
	        if (userId == null) return error(conn, 400, "Invalid user id");

	        var user = Users.getUserInOrganization(userId, currentUser.organizationId);
	        if (user == null) return error(conn, 404, "User not found");

	        return conn.json({user: userJson(user)});
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
	        var currentUser = currentUserFromSession(conn);
	        if (currentUser == null) return error(conn, 401, "Unauthorized");
	        if (currentUser.role != "admin") return error(conn, 403, "Forbidden");

	        var normalizedName = Accounts.normalizeName(params.name);
	        var normalizedEmail = Accounts.normalizeEmail(params.email);

	        if (StringTools.trim(normalizedName) == "" || StringTools.trim(normalizedEmail) == "") {
	            return error(conn, 422, "Name and email are required");
	        }

	        var attrs: Term = {};
	        attrs = ElixirMap.put(attrs, "name", normalizedName);
	        attrs = ElixirMap.put(attrs, "email", normalizedEmail);

	        if (params.bio != null) {
	            var bioValue = StringTools.trim(params.bio);
	            attrs = ElixirMap.put(attrs, "bio", bioValue == "" ? null : bioValue);
	        }

	        var userStruct: User = cast Kernel.struct(User);
	        var changeset = User.changeset(userStruct, attrs);

	        var now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), TimePrecision.Second);
	        changeset = changeset
	            .putChange("password_hash", Accounts.generateDemoPasswordHash(normalizedEmail))
	            .putChange("confirmed_at", now)
	            .putChange("organization_id", currentUser.organizationId)
	            .putChange("role", normalizeRole(params.role))
	            .putChange("active", params.active != null ? params.active : true);

	        return switch (Repo.insert(changeset)) {
	            case Ok(user):
	                final payload = {user: userJson(user), created: true};
	                conn.putStatus(201).json(payload);
	            case Error(changesetError):
	                conn.putStatus(422).json({error: "Failed to create user", changeset: changesetError});
	        };
	    }
    
    /**
     * Update an existing user (PUT /api/users/:id)
     * 
     * Combines URL parameters (id) with body parameters.
     * Type-safe with UpdateParams ensuring id always exists.
     */
	    public static function update(conn: Conn<UpdateParams>, params: UpdateParams): Conn<UpdateParams> {
	        var currentUser = currentUserFromSession(conn);
	        if (currentUser == null) return error(conn, 401, "Unauthorized");
	        if (currentUser.role != "admin") return error(conn, 403, "Forbidden");

	        var userId = Std.parseInt(params.id);
	        if (userId == null) return error(conn, 400, "Invalid user id");

	        var user = Users.getUserInOrganization(userId, currentUser.organizationId);
	        if (user == null) return error(conn, 404, "User not found");

	        if (user.id == currentUser.id) {
	            if (params.active == false) return error(conn, 422, "Cannot deactivate your own account");
	            if (params.role != null && normalizeRole(params.role) != currentUser.role) {
	                return error(conn, 422, "Cannot change your own role");
	            }
	        }

	        var nextName = params.name != null ? Accounts.normalizeName(params.name) : user.name;
	        var nextEmail = params.email != null ? Accounts.normalizeEmail(params.email) : user.email;

	        if (StringTools.trim(nextName) == "" || StringTools.trim(nextEmail) == "") {
	            return error(conn, 422, "Name and email must be non-empty");
	        }

	        var attrs: Term = {};
	        attrs = ElixirMap.put(attrs, "name", nextName);
	        attrs = ElixirMap.put(attrs, "email", nextEmail);

	        if (params.bio != null) {
	            var bioValue = StringTools.trim(params.bio);
	            attrs = ElixirMap.put(attrs, "bio", bioValue == "" ? null : bioValue);
	        }

	        var changeset = User.changeset(user, attrs);

	        if (params.role != null) {
	            changeset = changeset.putChange("role", normalizeRole(params.role));
	        }
	        if (params.active != null) {
	            changeset = changeset.putChange("active", params.active);
	        }

	        return switch (Repo.update(changeset)) {
	            case Ok(updated):
	                final payload = {user: userJson(updated), updated: true};
	                conn.json(payload);
	            case Error(changesetError):
	                conn.putStatus(422).json({error: "Failed to update user", changeset: changesetError});
	        };
	    }
    
    /**
     * Delete a user (DELETE /api/users/:id)
     * 
     * Type-safe deletion - the compiler ensures 'id' exists.
     * No need for defensive programming or nil checks!
     */
	    public static function delete(conn: Conn<DeleteParams>, params: DeleteParams): Conn<DeleteParams> {
	        var currentUser = currentUserFromSession(conn);
	        if (currentUser == null) return error(conn, 401, "Unauthorized");
	        if (currentUser.role != "admin") return error(conn, 403, "Forbidden");

	        var userId = Std.parseInt(params.id);
	        if (userId == null) return error(conn, 400, "Invalid user id");
	        if (userId == currentUser.id) return error(conn, 422, "Cannot delete your own account");

	        var user = Users.getUserInOrganization(userId, currentUser.organizationId);
	        if (user == null) return error(conn, 404, "User not found");

	        return switch (Repo.delete(user)) {
	            case Ok(_):
	                final payload = {deleted: userId, success: true};
	                conn.json(payload);
	            case Error(reason):
	                conn.putStatus(500).json({error: "Failed to delete user", reason: reason});
	        };
	    }
	}
