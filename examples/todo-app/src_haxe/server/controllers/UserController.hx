package controllers;

import plug.Conn;
import contexts.Accounts;
import contexts.Users;
import ecto.SchemaStruct;
import elixir.ElixirMap;
import elixir.types.Term;
import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.TimePrecision;
import haxe.functional.Result;
import phoenix.Params;
import server.infrastructure.Repo;
import server.schemas.User;
import StringTools;

/**
 * UserController: Type-safe Phoenix controller showcasing Haxe→Elixir benefits
 * 
 * This controller demonstrates how Haxe brings compile-time type safety to Phoenix
 * web applications while generating idiomatic Elixir code that Phoenix developers
 * will find familiar and maintainable.
 * 
 * ## Annotations Explained
 * 
 * @:controller  
 * - **Purpose**: Marks this class as a Phoenix controller
 * - **Generated**: `defmodule TodoAppWeb.UserController do`
 * - **Why**: PhoenixHx derives the web namespace from `-D app_name=TodoApp`
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
// @:controller: marks this module as a Phoenix controller for HTTP actions.
@:controller
class UserController {
	static function error<TParams>(conn:Conn<TParams>, status:Int, message:String):Conn<TParams> {
		return conn.putStatus(status).json({error: message});
	}

	static function getStringParam(params:Term, key:String):Null<String> {
		return Params.getString(params, key);
	}

	static function getBoolParam(params:Term, key:String):Null<Bool> {
		return Params.getBool(params, key);
	}

	static function parseParamId(params:Term):Null<Int> {
		return Params.getInt(params, "id");
	}

	static function parseSessionUserId(term:Term):Null<Int> {
		return Params.intFromTerm(term);
	}

	static function currentUserFromSession<TParams>(conn:Conn<TParams>):Null<User> {
		var userIdTerm:Term = conn.getSession("user_id");
		var userId = parseSessionUserId(userIdTerm);
		if (userId == null)
			return null;

		var currentUser:Null<User> = Repo.get(User, userId);
		if (currentUser == null)
			return null;
		if (!currentUser.active)
			return null;
		return currentUser;
	}

	static function userJson(user:User):Term {
		return {
			id: user.id,
			name: user.name,
			email: user.email,
			bio: user.bio,
			role: user.role,
			organization_id: user.organizationId,
			active: user.active
		};
	}

	static function normalizeRole(value:Null<String>):String {
		if (value == null)
			return "user";
		var role = StringTools.trim(value).toLowerCase();
		return (role == "admin" || role == "user") ? role : "user";
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
	public static function index(conn:Conn<{}>, params:Term):Conn<{}> {
		var currentUser = currentUserFromSession(conn);
		if (currentUser == null)
			return error(conn, 401, "Unauthorized");
		if (currentUser.role != "admin")
			return error(conn, 403, "Forbidden");

		var users = Users.listUsersForOrganization(currentUser.organizationId, null);
		var safeUsers:Array<Term> = users.map(u -> userJson(u));
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
	public static function show(conn:Conn<{}>, params:Term):Conn<{}> {
		var currentUser = currentUserFromSession(conn);
		if (currentUser == null)
			return error(conn, 401, "Unauthorized");
		if (currentUser.role != "admin")
			return error(conn, 403, "Forbidden");

		var userId = parseParamId(params);
		if (userId == null)
			return error(conn, 400, "Invalid user id");

		var user = Users.getUserInOrganization(userId, currentUser.organizationId);
		if (user == null)
			return error(conn, 404, "User not found");

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
	public static function create(conn:Conn<{}>, params:Term):Conn<{}> {
		var currentUser = currentUserFromSession(conn);
		if (currentUser == null)
			return error(conn, 401, "Unauthorized");
		if (currentUser.role != "admin")
			return error(conn, 403, "Forbidden");

		var name = getStringParam(params, "name") ?? "";
		var email = getStringParam(params, "email") ?? "";

		var normalizedName = Accounts.normalizeName(name);
		var normalizedEmail = Accounts.normalizeEmail(email);

		if (StringTools.trim(normalizedName) == "" || StringTools.trim(normalizedEmail) == "") {
			return error(conn, 422, "Name and email are required");
		}

		var attrs:Term = {};
		attrs = ElixirMap.put(attrs, "name", normalizedName);
		attrs = ElixirMap.put(attrs, "email", normalizedEmail);

		var bio = getStringParam(params, "bio");
		if (bio != null) {
			var bioValue = StringTools.trim(bio);
			attrs = ElixirMap.put(attrs, "bio", bioValue == "" ? null : bioValue);
		}

		var userStruct = SchemaStruct.empty(User);
		var changeset = User.changeset(userStruct, attrs);

		var requestedActive = getBoolParam(params, "active");
		var now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), TimePrecision.Second);
		changeset = changeset.putChange("password_hash", Accounts.generateDemoPasswordHash(normalizedEmail))
			.putChange("confirmed_at", now)
			.putChange("organization_id", currentUser.organizationId)
			.putChange("role", normalizeRole(getStringParam(params, "role")))
			.putChange("active", requestedActive != null ? requestedActive : true);

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
	public static function update(conn:Conn<{}>, params:Term):Conn<{}> {
		var currentUser = currentUserFromSession(conn);
		if (currentUser == null)
			return error(conn, 401, "Unauthorized");
		if (currentUser.role != "admin")
			return error(conn, 403, "Forbidden");

		var userId = parseParamId(params);
		if (userId == null)
			return error(conn, 400, "Invalid user id");

		var user = Users.getUserInOrganization(userId, currentUser.organizationId);
		if (user == null)
			return error(conn, 404, "User not found");

		if (user.id == currentUser.id) {
			if (getBoolParam(params, "active") == false)
				return error(conn, 422, "Cannot deactivate your own account");
			var requestedRole = getStringParam(params, "role");
			if (requestedRole != null && normalizeRole(requestedRole) != currentUser.role) {
				return error(conn, 422, "Cannot change your own role");
			}
		}

		var requestedName = getStringParam(params, "name");
		var requestedEmail = getStringParam(params, "email");
		var nextName = requestedName != null ? Accounts.normalizeName(requestedName) : user.name;
		var nextEmail = requestedEmail != null ? Accounts.normalizeEmail(requestedEmail) : user.email;

		if (StringTools.trim(nextName) == "" || StringTools.trim(nextEmail) == "") {
			return error(conn, 422, "Name and email must be non-empty");
		}

		var attrs:Term = {};
		attrs = ElixirMap.put(attrs, "name", nextName);
		attrs = ElixirMap.put(attrs, "email", nextEmail);

		var requestedBio = getStringParam(params, "bio");
		if (requestedBio != null) {
			var bioValue = StringTools.trim(requestedBio);
			attrs = ElixirMap.put(attrs, "bio", bioValue == "" ? null : bioValue);
		}

		var changeset = User.changeset(user, attrs);

		var role = getStringParam(params, "role");
		if (role != null) {
			changeset = changeset.putChange("role", normalizeRole(role));
		}
		var active = getBoolParam(params, "active");
		if (active != null) {
			changeset = changeset.putChange("active", active);
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
	public static function delete(conn:Conn<{}>, params:Term):Conn<{}> {
		var currentUser = currentUserFromSession(conn);
		if (currentUser == null)
			return error(conn, 401, "Unauthorized");
		if (currentUser.role != "admin")
			return error(conn, 403, "Forbidden");

		var userId = parseParamId(params);
		if (userId == null)
			return error(conn, 400, "Invalid user id");
		if (userId == currentUser.id)
			return error(conn, 422, "Cannot delete your own account");

		var user = Users.getUserInOrganization(userId, currentUser.organizationId);
		if (user == null)
			return error(conn, 404, "User not found");

		return switch (Repo.delete(user)) {
			case Ok(_):
				final payload = {deleted: userId, success: true};
				conn.json(payload);
			case Error(reason):
				conn.putStatus(500).json({error: "Failed to delete user", reason: reason});
		};
	}
}
