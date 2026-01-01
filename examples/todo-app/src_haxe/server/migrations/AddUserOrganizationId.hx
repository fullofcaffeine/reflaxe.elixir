package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * AddUserOrganizationId
 *
 * WHAT
 * - Adds a required `organization_id` column to the `users` table.
 *
 * WHY
 * - Users must belong to an organization to enable tenant-scoped queries.
 *
 * HOW
 * - Adds an integer `organization_id` with a default of 0 for demo/anonymous mode.
 *   Real organizations use positive ids from the `organizations` table.
 */
@:migration({timestamp: "20260101004031"})
class AddUserOrganizationId extends Migration {
    public function up(): Void {
        alterTable("users")
            .addColumn("organization_id", ColumnType.Integer, {nullable: false, defaultValue: 0});
    }

    public function down(): Void {
        alterTable("users")
            .removeColumn("organization_id");
    }
}

