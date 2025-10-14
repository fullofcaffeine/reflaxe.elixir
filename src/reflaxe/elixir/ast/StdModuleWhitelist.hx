package reflaxe.elixir.ast;

/**
 * StdModuleWhitelist
 *
 * WHAT
 * - Centralized whitelist of standard library and framework module roots that must
 *   never be qualified with <App>.* during code generation.
 *
 * WHY
 * - Prevents over-qualification such as <App>.Enum, <App>.Map, or <App>.Ecto.
 *   Consolidating this list avoids divergence between printer and transformer passes.
 *
 * HOW
 * - Provides helper functions to check single-segment roots (e.g., "Enum") and
 *   qualified names (e.g., "Ecto.Query" → root "Ecto"). Passes and the printer
 *   should consult this module before qualifying.
 *
 * EXAMPLES
 *   isWhitelistedRoot("Enum")        -> true
 *   isWhitelistedQualified("Ecto.Query") -> true (root Ecto)
 *   isWhitelistedRoot("Repo")        -> false (Repo should qualify to <App>.Repo)
 */
class StdModuleWhitelist {
    static var ROOTS: Map<String, Bool> = (function() {
        var m = new Map<String, Bool>();
        // Core and stdlib
        for (name in [
            "Kernel","Enum","Map","List","Bitwise","String","Integer","Float","IO","File","Path","System",
            "Process","Task","GenServer","Agent","Registry","Node","Application","Supervisor","DynamicSupervisor",
            "Logger","Date","DateTime","NaiveDateTime","Time","Calendar","URI","Code","Stream","Range","Regex",
            "Keyword","Access","Reflect","Type",
            // Common helper modules generated at top-level (project-local utilities)
            "StringTools","Log","SafeAssigns","TodoPubSub",
            // Framework roots
            "Ecto","Phoenix"
        ]) m.set(name, true);
        return m;
    })();

    public static inline function isWhitelistedRoot(name: String): Bool {
        return name != null && ROOTS.exists(name);
    }

    public static inline function isWhitelistedQualified(moduleName: String): Bool {
        if (moduleName == null) return false;
        var idx = moduleName.indexOf(".");
        if (idx <= 0) return isWhitelistedRoot(moduleName);
        var root = moduleName.substring(0, idx);
        return isWhitelistedRoot(root);
    }
}
