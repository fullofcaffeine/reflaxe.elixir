package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * AddUserRole
 *
 * WHAT
 * - Adds a `role` column to `users` for a simple user/admin authorization showcase.
 *
 * WHY
 * - Enables an admin-only dashboard route and demonstrates access guards in LiveView.
 *
 * HOW
 * - Uses an `alter table` migration to add a NOT NULL role with a default of "user".
 */
@:migration({timestamp: "20251231233414"})
class AddUserRole extends Migration {
    public function up(): Void {
        alterTable("users")
            .addColumn("role", ColumnType.String(), {nullable: false, defaultValue: "user"});
    }

    public function down(): Void {
        alterTable("users")
            .removeColumn("role");
    }
}

