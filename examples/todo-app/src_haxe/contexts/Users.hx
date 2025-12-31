package contexts;

import elixir.Kernel;
import ecto.Changeset;
import ecto.TypedQuery;
import haxe.functional.Result;
import server.infrastructure.Repo;
import server.schemas.User;
import StringTools;
using reflaxe.elixir.macros.TypedQueryLambda; // ensure extension where(...) is available

/**
 * Users context (todo-app)
 *
 * NOTE
 * - The canonical User schema for the todo-app lives in `server.schemas.User` and compiles to
 *   `TodoApp.User`. This context deliberately reuses that schema type to avoid generating a
 *   second `TodoApp.User` module from a different Haxe file (which causes module redefinition
 *   warnings at compile time).
 */

typedef UserFilter = {
    ?name: String,
    ?email: String,
    ?isActive: Bool
}

typedef UserParams = {
    ?name: String,
    ?email: String,
    ?age: Int,
    ?active: Bool
}

typedef UserStats = {
    total: Int,
    active: Int,
    inactive: Int
}

/**
 * UserChangeset provides a typed Changeset wrapper for building user forms.
 */
class UserChangeset {
    public static function changeset(user: User, attrs: UserParams): Changeset<User, UserParams> {
        return new Changeset(user, attrs);
    }
}

@:native("TodoApp.Users")
class Users {
    /**
     * Get all users with optional filtering.
     */
    public static function listUsers(?filter: UserFilter): Array<User> {
        var base = TypedQuery.from(User);
        if (filter == null) return Repo.all(base);

        var filtered = base;

        if (filter.name != null && StringTools.trim(filter.name) != "") {
            filtered = filtered.where(u -> u.name == filter.name);
        }

        if (filter.email != null && StringTools.trim(filter.email) != "") {
            filtered = filtered.where(u -> u.email == filter.email);
        }

        if (filter.isActive != null) {
            filtered = filtered.where(u -> u.active == filter.isActive);
        }

        return Repo.all(filtered);
    }

    /**
     * Create changeset for user (used by forms).
     *
     * `Ecto.Changeset.cast/4` requires a struct, so we synthesize an empty one when `user` is null.
     */
    public static function changeUser(?user: User): Changeset<User, UserParams> {
        var data: User = (user != null) ? user : cast Kernel.struct(User);
        return new Changeset(data, {});
    }

    /**
     * Get user by ID, returns null if not found.
     */
    public static function getUserSafe(id: Int): Null<User> {
        return Repo.get(User, id);
    }

    /**
     * Get user by ID with error handling.
     */
    public static function getUser(id: Int): User {
        var user = Repo.get(User, id);
        if (user == null) {
            throw 'User not found with id: $id';
        }
        return user;
    }

    /**
     * Create a new user.
     *
     * Note: Ecto requires a struct for changeset casting.
     */
    public static function createUser(attrs: UserParams): Result<User, Changeset<User, UserParams>> {
        var data: User = cast Kernel.struct(User);
        return Repo.insert(UserChangeset.changeset(data, attrs));
    }

    /**
     * Update existing user.
     */
    public static function updateUser(user: User, attrs: UserParams): Result<User, Changeset<User, UserParams>> {
        return Repo.update(UserChangeset.changeset(user, attrs));
    }

    /**
     * Delete user (hard delete from database).
     */
    public static function deleteUser(user: User): Result<User, Changeset<User, {}>> {
        return Repo.delete(user);
    }

    public static function searchUsers(term: String): Array<User> {
        var trimmed = StringTools.trim(term);
        if (trimmed == "") return listUsers(null);

        var query = trimmed.toLowerCase();
        var users = listUsers(null);
        return users.filter(user -> matchesQuery(user, query));
    }

    public static function userStats(): UserStats {
        var users = listUsers(null);
        var total = users.length;
        var active = 0;
        for (user in users) {
            if (user.active) active++;
        }
        return {
            total: total,
            active: active,
            inactive: total - active
        };
    }

    static function matchesQuery(user: User, queryLowercase: String): Bool {
        var name = user.name != null ? user.name.toLowerCase() : "";
        var email = user.email != null ? user.email.toLowerCase() : "";
        return StringTools.contains(name, queryLowercase) || StringTools.contains(email, queryLowercase);
    }
}
