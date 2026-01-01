package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * CreateOrganizations
 *
 * WHAT
 * - Adds an `organizations` table and a required `organization_id` foreign key to `users` and `todos`.
 *
 * WHY
 * - Enables multi-tenant scoping for the todo-app showcase: users collaborate within an org, and
 *   PubSub/Presence/topics can be isolated per-organization.
 *
 * HOW
 * - Creates `organizations` with a unique `slug`.
 * - Adds tenant scoping support (org_id fields) via follow-up migrations to keep
 *   ecto_migrations_exs bodies single-statement and transformer-friendly.
 */
@:migration({timestamp: "20260101004030"})
class CreateOrganizations extends Migration {
    public function up(): Void {
        createTable("organizations")
            .addColumn("slug", ColumnType.String(), {nullable: false})
            .addColumn("name", ColumnType.String(), {nullable: false})
            .addTimestamps()
            .addUniqueConstraint(["slug"], "organizations_slug_unique");
    }

    public function down(): Void {
        dropTable("organizations");
    }
}
