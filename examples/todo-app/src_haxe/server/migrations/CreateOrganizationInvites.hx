package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * CreateOrganizationInvites
 *
 * WHAT
 * - Adds `organization_invites` to support inviting users (by email) into an organization.
 *
 * WHY
 * - The todo-app is a multi-tenant Phoenix showcase. Invites demonstrate a realistic onboarding
 *   flow and exercise typed Ecto queries + schema changesets.
 *
 * HOW
 * - Store normalized `email` + desired `role`.
 * - Mark acceptance with `accepted_at` and `accepted_by_user_id`.
 * - Enforce one invite per org+email via a unique constraint.
 */
@:migration({timestamp: "20260101170000"})
class CreateOrganizationInvites extends Migration {
    public function up(): Void {
        createTable("organization_invites")
            .addColumn("organization_id", ColumnType.Integer, {nullable: false})
            .addColumn("email", ColumnType.String(), {nullable: false})
            .addColumn("role", ColumnType.String(), {nullable: false, defaultValue: "user"})
            .addColumn("accepted_at", ColumnType.DateTime)
            .addColumn("accepted_by_user_id", ColumnType.Integer)
            .addTimestamps()
            .addIndex(["organization_id"])
            .addIndex(["email"])
            .addUniqueConstraint(["organization_id", "email"], "organization_invites_org_email_unique");
    }

    public function down(): Void {
        dropTable("organization_invites");
    }
}

