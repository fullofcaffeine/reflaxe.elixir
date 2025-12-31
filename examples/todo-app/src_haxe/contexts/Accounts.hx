package contexts;

import ecto.Changeset;
import ecto.TypedQuery;
import elixir.Kernel;
import elixir.Enum;
import elixir.types.Term;
import haxe.functional.Result;
import server.infrastructure.Repo;
import server.schemas.User;
import StringTools;
import elixir.DateTime.NaiveDateTime;
import elixir.DateTime.TimePrecision;
using reflaxe.elixir.macros.TypedQueryLambda;

/**
 * Accounts context (todo-app)
 *
 * WHAT
 * - Minimal demo authentication context used by the todo-app showcase.
 *
 * WHY
 * - We want an "optional login" experience that demonstrates typed Ecto queries,
 *   Repo interactions, and Plug session integration without pulling in a full
 *   auth stack (tokens, password hashing, email confirmations).
 *
 * HOW
 * - "Sign in" is email-based: we find-or-create a user by email, touch `last_login_at`,
 *   and let the SessionController persist `:user_id` in the Plug session.
 */
@:native("TodoApp.Accounts")
class Accounts {
    public static function normalizeEmail(email: String): String {
        return StringTools.trim(email).toLowerCase();
    }

    public static function normalizeName(name: String): String {
        return StringTools.trim(name);
    }

    public static function getUserByEmail(email: String): Null<User> {
        var query = TypedQuery.from(User).where(u -> u.email == email);
        var users = Repo.all(query);
        return Enum.at(users, 0);
    }

    /**
     * Find or create a user for the demo login flow.
     *
     * Returns a `Result` so callers can surface changeset errors as flash messages.
     */
    public static function getOrCreateUserForLogin(email: String, name: String): Result<User, Changeset<User, Term>> {
        var normalizedEmail = normalizeEmail(email);
        var normalizedName = normalizeName(name);

        var existing = getUserByEmail(normalizedEmail);
        if (existing != null) {
            // Touch last_login_at for demo observability.
            return switch (Repo.update(User.loginChangeset(existing))) {
                case Ok(updated): Ok(updated);
                case Error(changeset): Error(changeset);
            };
        }

        var data: User = cast Kernel.struct(User);
        var params: Term = {name: normalizedName, email: normalizedEmail};
        var now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), TimePrecision.Second);
        var changeset = User.changeset(data, params)
            .putChange("password_hash", generateDemoPasswordHash(normalizedEmail))
            .putChange("confirmed_at", now)
            .putChange("last_login_at", now);

        return Repo.insert(changeset);
    }

    static function generateDemoPasswordHash(email: String): String {
        // Demo-only (not used for auth); must be non-null to satisfy DB constraints.
        var timestamp = Date.now().getTime();
        var random = Math.floor(Math.random() * 1000000);
        return 'demo_${timestamp}_${random}_${email}';
    }
}
