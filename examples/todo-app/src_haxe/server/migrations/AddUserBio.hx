package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * AddUserBio
 *
 * WHAT
 * - Adds an optional `bio` text column to the `users` table.
 *
 * WHY
 * - Supports a richer profile showcase (name + bio) without changing the demo auth flow.
 *
 * HOW
 * - Uses the typed Migration DSL to alter `users` and add a nullable text column.
 */
@:migration({timestamp: "20251231230017"})
class AddUserBio extends Migration {
    public function up(): Void {
        alterTable("users")
            .addColumn("bio", ColumnType.Text);
    }

    public function down(): Void {
        alterTable("users")
            .removeColumn("bio");
    }
}

