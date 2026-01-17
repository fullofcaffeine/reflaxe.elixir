package fixtures.hxxindex;

/**
 * EventName (tooling fixture)
 *
 * Minimal `@:phxEventNames` registry used by `tools/HxxRegistryIndex.hxml` so the JSON exporter
 * has at least one module-scoped template event to report.
 */
@:phxEventNames
enum abstract EventName(String) from String to String {
    var Increment = "increment";
}

