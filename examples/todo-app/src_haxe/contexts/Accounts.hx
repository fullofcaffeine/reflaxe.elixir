package contexts;

import ecto.Changeset;
import ecto.TypedQuery;
import elixir.Kernel;
import elixir.Enum;
import elixir.types.Term;
import haxe.functional.Result;
import server.infrastructure.Repo;
import server.schemas.Organization;
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
    static inline var DEMO_ORG_SLUG = "demo";

    public static function normalizeEmail(email: String): String {
        return StringTools.trim(email).toLowerCase();
    }

    public static function normalizeName(name: String): String {
        return StringTools.trim(name);
    }

    static function organizationSlugFromEmail(normalizedEmail: String): String {
        var atIndex = normalizedEmail.indexOf("@");
        if (atIndex == -1) return DEMO_ORG_SLUG;
        var slug = StringTools.trim(normalizedEmail.substr(atIndex + 1));
        return slug != "" ? slug : DEMO_ORG_SLUG;
    }

    static function getOrganizationBySlug(slug: String): Null<Organization> {
        var query = TypedQuery.from(Organization).where(o -> o.slug == slug);
        var orgs = Repo.all(query);
        return Enum.at(orgs, 0);
    }

    static function getOrCreateOrganization(slug: String): Result<Organization, Changeset<Organization, server.schemas.Organization.OrganizationParams>> {
        var existing = getOrganizationBySlug(slug);
        if (existing != null) return Ok(existing);

        var data: Organization = cast Kernel.struct(Organization);
        var params: server.schemas.Organization.OrganizationParams = {slug: slug, name: slug};
        var changeset = Organization.changeset(data, params);
        return Repo.insert(changeset);
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

        var orgSlug = organizationSlugFromEmail(normalizedEmail);
        var organization: Organization = switch (getOrCreateOrganization(orgSlug)) {
            case Ok(org): org;
            case Error(changeset):
                return Error(cast changeset);
        };

        var data: User = cast Kernel.struct(User);
        var params: Term = {name: normalizedName, email: normalizedEmail};
        var isFirstUserInOrg = Repo.all(TypedQuery.from(User).where(u -> u.organizationId == organization.id)).length == 0;
        var now = NaiveDateTime.truncate(NaiveDateTime.utc_now(), TimePrecision.Second);
        var changeset = User.changeset(data, params)
            .putChange("password_hash", generateDemoPasswordHash(normalizedEmail))
            .putChange("confirmed_at", now)
            .putChange("last_login_at", now)
            .putChange("organization_id", organization.id)
            .putChange("role", isFirstUserInOrg ? "admin" : "user");

        return Repo.insert(changeset);
    }

    static function generateDemoPasswordHash(email: String): String {
        // Demo-only (not used for auth); must be non-null to satisfy DB constraints.
        var timestamp = Date.now().getTime();
        var random = Math.floor(Math.random() * 1000000);
        return 'demo_${timestamp}_${random}_${email}';
    }
}
