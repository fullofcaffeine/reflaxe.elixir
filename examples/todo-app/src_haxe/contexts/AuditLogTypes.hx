package contexts;

import elixir.types.Term;

/**
 * AuditLogTypes (todo-app)
 *
 * WHAT
 * - Shared enums + param/filter shapes for the audit log showcase.
 *
 * WHY
 * - Keeps `contexts.AuditLogs` focused on behavior (insert/query), while allowing
 *   LiveViews to reference well-typed action/entity identifiers.
 *
 * HOW
 * - `AuditAction`/`AuditEntity` are string-backed enum abstracts so call sites
 *   get autocomplete + typo safety, while the DB stores plain strings.
 */
enum abstract AuditAction(String) from String to String {
    var OrganizationInviteCreated = "org.invite_created";
    var OrganizationInviteAccepted = "org.invite_accepted";
    var OrganizationInviteRevoked = "org.invite_revoked";
    var UserRoleUpdated = "user.role_updated";
}

enum abstract AuditEntity(String) from String to String {
    var OrganizationInviteEntity = "organization_invite";
    var UserEntity = "user";
}

typedef AuditLogEntryParams = {
    organizationId: Int,
    actorId: Int,
    action: AuditAction,
    entity: AuditEntity,
    ?entityId: Int,
    ?metadata: Term
}

typedef AuditLogFilter = {
    ?action: String,
    ?entity: String,
    ?actorId: Int,
    ?limit: Int
}
