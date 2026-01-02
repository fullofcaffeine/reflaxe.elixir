package server.schemas;

import ecto.Changeset;
import elixir.DateTime.NaiveDateTime;

typedef OrganizationInviteParams = {
    ?organizationId: Int,
    ?email: String,
    ?role: String,
    ?acceptedAt: Null<NaiveDateTime>,
    ?acceptedByUserId: Null<Int>
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
@:native("TodoApp.OrganizationInvite")
@:schema("organization_invites")
@:timestamps
@:changeset(["organizationId", "email", "role", "acceptedAt", "acceptedByUserId"], ["organizationId", "email", "role"])
@:keep
class OrganizationInvite {
    @:field @:primary_key public var id: Int;
    @:field public var organizationId: Int;
    @:field public var email: String;
    @:field public var role: String = "user";
    @:field public var acceptedAt: Null<NaiveDateTime>;
    @:field public var acceptedByUserId: Null<Int>;

    public function new() {}

    extern public static function changeset(invite: OrganizationInvite, params: OrganizationInviteParams): Changeset<OrganizationInvite, OrganizationInviteParams>;
}

