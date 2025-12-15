package contexts;

import elixir.Kernel;
import elixir.types.Result;
import ecto.Changeset;
import ecto.TypedQuery;
import server.infrastructure.Repo;
import server.schemas.User;
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
        var filtered = if (filter == null) {
            base;
        } else {
            var byName = (filter.name != null) ? base.where(u -> u.name == '%${filter.name}%') : base;
            var byEmail = (filter.email != null) ? byName.where(u -> u.email == '%${filter.email}%') : byName;
            (filter.isActive != null) ? byEmail.where(u -> u.active == filter.isActive) : byEmail;
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

    // Placeholder/demo APIs (not currently wired into the todo-app UI).
    public static function searchUsers(_term: String): Array<User> return [];
    public static function userStats(): UserStats return {total: 0, active: 0, inactive: 0};
}

