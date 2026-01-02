package server.migrations;

import ecto.Migration;
import ecto.Migration.ColumnType;

/**
 * CreateAuditLogs
 *
 * WHAT
 * - Adds `audit_logs` to track admin/user actions (who did what, and when).
 *
 * WHY
 * - A lightweight audit log is a high-value Phoenix/Ecto showcase:
 *   - typed schema definition
 *   - typed insert/query flows from Haxe
 *   - admin-only LiveView access patterns
 *
 * HOW
 * - Store `organization_id` + `actor_id` so entries can be scoped to a tenant and user.
 * - Use `metadata` as JSON for small, typed-ish payloads (emails, role changes, etc.).
 * - Index common filter fields for fast admin queries.
 */
@:migration({timestamp: "20260102120000"})
class CreateAuditLogs extends Migration {
    public function up(): Void {
        createTable("audit_logs")
            .addColumn("organization_id", ColumnType.Integer, {nullable: false})
            .addColumn("actor_id", ColumnType.Integer, {nullable: false})
            .addColumn("action", ColumnType.String(), {nullable: false})
            .addColumn("entity", ColumnType.String(), {nullable: false})
            .addColumn("entity_id", ColumnType.Integer)
            .addColumn("metadata", ColumnType.Json)
            .addTimestamps()
            .addIndex(["organization_id"])
            .addIndex(["actor_id"])
            .addIndex(["action"])
            .addIndex(["entity"])
            .addIndex(["inserted_at"]);
    }

    public function down(): Void {
        dropTable("audit_logs");
    }
}

