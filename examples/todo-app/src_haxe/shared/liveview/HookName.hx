package shared.liveview;

/**
 * HookName
 *
 * Single source of truth for Phoenix LiveView `phx-hook` names used by the todo-app.
 *
 * WHY
 * - Keep server templates and the Genes client hook registry in sync.
 * - Make `phx-hook` refactors type-safe (rename once, compiler finds all usages).
 *
 * HOW
 * - Server: use `phx-hook=${HookName.Ping}` (compiles to `phx-hook="Ping"`).
 * - Client: keep hook keys aligned with these values.
 */
enum abstract HookName(String) from String to String {
    var AutoFocus = "AutoFocus";
    var Ping = "Ping";
    var CopyToClipboard = "CopyToClipboard";
    var ThemeToggle = "ThemeToggle";
}

