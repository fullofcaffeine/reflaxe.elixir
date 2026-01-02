package contexts;

import ecto.Changeset;
import ecto.TypedQuery;
import ecto.TypedQuery.SortDirection;
import contexts.AuditLogTypes.AuditAction;
import contexts.AuditLogTypes.AuditEntity;
import contexts.AuditLogTypes.AuditLogEntryParams;
import contexts.AuditLogTypes.AuditLogFilter;
import elixir.Kernel;
import elixir.types.Term;
import haxe.functional.Result;
import server.infrastructure.Repo;
import server.schemas.AuditLog;
import StringTools;
using reflaxe.elixir.macros.TypedQueryLambda;

/**
 * AuditLogs context (todo-app)
 *
 * WHAT
 * - Insert and query audit log entries for the todo-app showcase.
 *
 * WHY
 * - Keeps audit behavior out of LiveViews and schemas, while still allowing
 *   LiveViews to record actions with strong typing at the call site.
 *
 * HOW
 * - `record(...)` inserts an immutable AuditLog row.
 * - `listRecent(...)` provides a small, admin-facing query surface with simple filters.
 */

@:native("TodoApp.AuditLogs")
class AuditLogs {
    public static function record(params: AuditLogEntryParams): Result<AuditLog, Changeset<AuditLog, Term>> {
        var data: AuditLog = cast Kernel.struct(AuditLog);

        var insertParams: Term = {
            organization_id: params.organizationId,
            actor_id: params.actorId,
            action: params.action,
            entity: params.entity,
            entity_id: params.entityId,
            metadata: params.metadata
        };

        var changeset = AuditLog.changeset(data, insertParams);
        return Repo.insert(changeset);
    }

    public static function listRecent(organizationId: Int, ?filter: AuditLogFilter): Array<AuditLog> {
        var query = TypedQuery.from(AuditLog).where(a -> a.organizationId == organizationId);

        var limit = 50;
        if (filter != null) {
            if (filter.actorId != null) {
                query = query.where(a -> a.actorId == filter.actorId);
            }
            if (filter.action != null && StringTools.trim(filter.action) != "") {
                query = query.where(a -> a.action == filter.action);
            }
            if (filter.entity != null && StringTools.trim(filter.entity) != "") {
                query = query.where(a -> a.entity == filter.entity);
            }
            if (filter.limit != null && filter.limit > 0) {
                limit = filter.limit;
            }
        }

        query = query.orderBy(a -> [{field: a.id, direction: SortDirection.Desc}]).limit(limit);
        return Repo.all(query);
    }
}
