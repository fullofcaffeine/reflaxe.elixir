package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
using StringTools;

/**
 * LiveViewTemplateUsageRegistry
 *
 * WHAT
 * - Compile-time registry of `phx-*` names *used in templates* (typically inside LiveView `render/1` HXX),
 *   derived by scanning `@:liveview` module bodies.
 *
 * WHY
 * - TSX-level UX depends on editor tooling being able to offer completions that are relevant to the
 *   current module/template, not just a global registry.
 * - LiveViews tend to use typed registries (`@:phxEventNames` / `@:phxHookNames`) in templates
 *   (`phx-click=${EventName.Save}`, `phx-hook=${HookName.Ping}`), which gives us a reliable way to
 *   derive the exact runtime strings.
 *
 * HOW
 * - `AnnotatedModuleEnumerator` scans `render` bodies and registers:
 *   - event names referenced via `@:phxEventNames` registries
 *   - hook names referenced via `@:phxHookNames` registries
 * - `tools/HxxRegistryIndex.hx` exports the per-module lists for editor tooling.
 *
 * EXAMPLES
 * Haxe:
 *   @:phxHookNames enum abstract HookName(String) { var Ping = "Ping"; }
 *   @:liveview class MyLive { function render(a) return HXX.hxx('<div phx-hook=${HookName.Ping}></div>'); }
 *
 * Output (exported JSON):
 *   { module: "MyLive", hooks: ["Ping"] }
 */
class LiveViewTemplateUsageRegistry {
    static var moduleToHooks: Map<String, Map<String, Bool>> = new Map();
    static var moduleToEvents: Map<String, Map<String, Bool>> = new Map();

    public static function registerHook(moduleName: String, hook: String): Void {
        register(moduleToHooks, moduleName, hook);
    }

    public static function registerEvent(moduleName: String, event: String): Void {
        register(moduleToEvents, moduleName, event);
    }

    public static function getHooksForModule(moduleName: String): Map<String, Bool> {
        var hooks = moduleToHooks.get(moduleName);
        return hooks != null ? hooks : new Map();
    }

    public static function getEventsForModule(moduleName: String): Map<String, Bool> {
        var events = moduleToEvents.get(moduleName);
        return events != null ? events : new Map();
    }

    static function register(map: Map<String, Map<String, Bool>>, moduleName: String, value: String): Void {
        if (moduleName == null || moduleName.length == 0) return;
        if (value == null) return;
        var name = StringTools.trim(value);
        if (name.length == 0) return;

        var set = map.get(moduleName);
        if (set == null) {
            set = new Map();
            map.set(moduleName, set);
        }
        set.set(name, true);
    }
}

#end
