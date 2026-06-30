package server.schemas;

typedef OrganizationParams = {
	?slug:String,
	?name:String
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
// @:schema: marks this class as an Ecto schema and declares its table.

@:schema("organizations")
// @:timestamps: enables Ecto timestamp fields (`inserted_at`/`updated_at`).
@:timestamps
// @:changeset: configures generated Ecto changeset casting/validation behavior.
@:changeset(["slug", "name"], ["slug", "name"])
class Organization {
	// @:field: includes this property as an Ecto schema field in generated output. @:primary_key: marks this schema field as the primary key.
	@:field @:primary_key public var id:Int;
	@:field public var slug:String;
	@:field public var name:String;

	public function new() {}
}
