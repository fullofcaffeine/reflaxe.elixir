package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * AddTodoOrganizationId
 *
 * WHAT
 * - Adds a required `organization_id` column to the `todos` table.
 *
 * WHY
 * - Enables tenant scoping for shared todo lists (org-level collaboration).
 *
 * HOW
 * - Adds an integer `organization_id` with a default of 0 for demo/anonymous mode.
 */
@:migration({timestamp: "20260101004032"})
class AddTodoOrganizationId extends Migration {
    public function up(): Void {
        alterTable("todos")
            .addColumn("organization_id", ColumnType.Integer, {nullable: false, defaultValue: 0});
    }

    public function down(): Void {
        alterTable("todos")
            .removeColumn("organization_id");
    }
}

