package shared.liveview;

/**
 * EventName
 *
 * Single source of truth for Phoenix LiveView `phx-*` event names used by the todo-app.
 *
 * WHY
 * - Keep templates and `handle_event/3` logic in sync.
 * - Make event refactors type-safe (rename once, compiler finds all usages).
 *
 * HOW
 * - Templates: `phx-click=${EventName.ToggleForm}` (compiles to `phx-click="toggle_form"`).
 * - Server: compare `event == EventName.ToggleForm`.
 */
@:phxEventNames
enum abstract EventName(String) from String to String {
    // TodoLive
    var ToggleForm = "toggle_form";
    var CreateTodo = "create_todo";
    var SaveTodo = "save_todo";
    var EditTodo = "edit_todo";
    var DeleteTodo = "delete_todo";
    var CancelEdit = "cancel_edit";
    var ToggleTodo = "toggle_todo";

    var FilterTodos = "filter_todos";
    var SearchTodos = "search_todos";
    var SortTodos = "sort_todos";
    var ToggleTag = "toggle_tag";
    var SetPriority = "set_priority";

    var BulkComplete = "bulk_complete";
    var BulkDeleteCompleted = "bulk_delete_completed";
    var BulkSetPriority = "bulk_set_priority";

    // UsersLive
    var FilterUsers = "filter_users";
    var ToggleActive = "toggle_active";

    // OrganizationLive
    var SwitchOrg = "switch_org";
    var InviteOrg = "invite_org";
    var RevokeInvite = "revoke_invite";
    var SetUserRole = "set_user_role";

    // ProfileLive
    var SaveProfile = "save_profile";

    // AuditLogLive
    var FilterAudit = "filter_audit";
}
