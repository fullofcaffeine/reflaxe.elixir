package server.schemas;

import ecto.Changeset;

typedef OrganizationParams = {
    ?slug: String,
    ?name: String
}

/**
 * Organization schema (todo-app)
 *
 * WHAT
 * - Minimal organization/tenant model for multi-tenant scoping.
 *
 * WHY
 * - Provides a stable `organization_id` foreign key for users/todos so runtime queries,
 *   PubSub topics, and Presence can be isolated per-tenant.
 *
 * HOW
 * - `slug` is a unique, stable identifier (used internally for lookups).
 * - `name` is the human-friendly label.
 */
@:native("TodoApp.Organization")
@:schema("organizations")
@:timestamps
@:changeset(["slug", "name"], ["slug", "name"])
@:keep
class Organization {
    @:field @:primary_key public var id: Int;
    @:field public var slug: String;
    @:field public var name: String;

    public function new() {}

    extern public static function changeset(org: Organization, params: OrganizationParams): Changeset<Organization, OrganizationParams>;
}
