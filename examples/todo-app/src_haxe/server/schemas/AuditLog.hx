package server.schemas;

import ecto.Changeset;
import elixir.types.Term;

/**
 * AuditLog
 *
 * WHAT
 * - Immutable audit entries capturing "who did what" in the todo-app showcase.
 *
 * WHY
 * - Demonstrate a realistic, admin-facing feature that exercises:
 *   - typed Ecto schemas authored in Haxe
 *   - typed inserts and queries
 *   - LiveView RBAC guards (admin-only)
 *
 * HOW
 * - Store `organization_id` and `actor_id` to support multi-tenant scoping.
 * - Keep `metadata` flexible via JSON (`Term`) for small event payloads.
 */
// @:native (class): pins the generated Elixir module name to match Phoenix/Ecto runtime expectations.
@:native("TodoApp.AuditLog")
// @:schema: marks this class as an Ecto schema and declares its table.
@:schema("audit_logs")
// @:timestamps: enables Ecto timestamp fields (`inserted_at`/`updated_at`).
@:timestamps
class AuditLog {
	// @:field: includes this property as an Ecto schema field in generated output. @:primary_key: marks this schema field as the primary key.
	@:field @:primary_key public var id:Int;
	@:field public var organizationId:Int;
	@:field public var actorId:Int;
	@:field public var action:String;
	@:field public var entity:String;
	@:field public var entityId:Null<Int>;
	@:field public var metadata:Null<Term>;

	public function new() {}

	public static function changeset(entry:AuditLog, params:Term):Changeset<AuditLog, Term> {
		// Audit logs are immutable; this is used only for inserts.
		return ecto.Changeset.change(entry, params);
	}
}
