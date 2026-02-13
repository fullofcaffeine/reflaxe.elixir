package server.schemas;

import elixir.DateTime.NaiveDateTime;

typedef OrganizationInviteParams = {
	?organizationId:Int,
	?email:String,
	?role:String,
	?acceptedAt:Null<NaiveDateTime>,
	?acceptedByUserId:Null<Int>
}

/**
 * OrganizationInvite schema (todo-app)
 *
 * WHAT
 * - Represents an invitation for a user (by email) to join an organization.
 *
 * WHY
 * - Provides a small but realistic multi-tenant onboarding flow for the todo-app showcase:
 *   admins can invite users into their organization, and the login flow can accept
 *   pending invites automatically.
 *
 * HOW
 * - Invitations are matched by normalized email.
 * - `accepted_at` / `accepted_by_user_id` mark acceptance for auditability.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.

@:native("TodoApp.OrganizationInvite")
// @:schema: marks this class as an Ecto schema and declares its table.
@:schema("organization_invites")
// @:timestamps: enables Ecto timestamp fields (`inserted_at`/`updated_at`).
@:timestamps
// @:changeset: configures generated Ecto changeset casting/validation behavior.
@:changeset(["organizationId", "email", "role", "acceptedAt", "acceptedByUserId"], ["organizationId", "email", "role"])
class OrganizationInvite {
	// @:field: includes this property as an Ecto schema field in generated output. @:primary_key: marks this schema field as the primary key.
	@:field @:primary_key public var id:Int;
	@:field public var organizationId:Int;
	@:field public var email:String;
	@:field public var role:String = "user";
	@:field public var acceptedAt:Null<NaiveDateTime>;
	@:field public var acceptedByUserId:Null<Int>;

	public function new() {}
}
