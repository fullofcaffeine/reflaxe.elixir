package fixtures.hxxindex;

/**
 * HookName (tooling fixture)
 *
 * Minimal `@:phxHookNames` registry used by `tools/HxxRegistryIndex.hxml` so the JSON exporter
 * has at least one module-scoped template hook to report.
 */
@:phxHookNames
enum abstract HookName(String) from String to String {
    var Ping = "Ping";
}

