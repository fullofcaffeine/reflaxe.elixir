package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.io.Path;
using StringTools;

/**
 * RepoDiscovery
 *
 * WHAT
 * - Macro-phase discovery of Haxe extern classes annotated with @:repo and @:presence
 *   and force-typing them so they participate in normal compilation and transformation
 *   (repoTransformPass / presenceTransformPass).
 *
 * WHY
 * - Unreferenced externs may not be typed by Haxe, causing @:repo modules (e.g., <App>.Repo)
 *   or @:presence modules (e.g., <App>Web.Presence) to be omitted from moduleTypes and thus
 *   never emitted. This breaks runtime (no Repo/Presence module).
 *   Discovery + force-typing fixes this deterministically without iterator/file hacks.
 *
 * HOW
 * - At CompilerInit.Start(), call RepoDiscovery.run(). It discovers @:repo/@:presence externs,
 *   derives the module path (package + class), and calls Context.getType(mod) to force typing.
 * - Discovered module names are recorded for the compiler to append in filterTypes.
 */
class RepoDiscovery {
    static var discovered: Array<String> = [];

    public static function run(): Void {
        // Prevent duplicate runs
        if (discovered.length > 0) return;
        // Preferred: derive app modules and force-type <App>.Repo and <App>Web.Presence directly
        try {
            var app: Null<String> = null;
            try app = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (_:Dynamic) {}
            if (app != null && app.length > 0) {
                var repoMod = app + ".Repo";
                try Context.getType(repoMod) catch (_:Dynamic) {}
                if (discovered.indexOf(repoMod) == -1) discovered.push(repoMod);

                var presenceMod = app + "Web.Presence";
                try Context.getType(presenceMod) catch (_:Dynamic) {}
                if (discovered.indexOf(presenceMod) == -1) discovered.push(presenceMod);

                var telemetryMod = app + "Web.Telemetry";
                try Context.getType(telemetryMod) catch (_:Dynamic) {}
                if (discovered.indexOf(telemetryMod) == -1) discovered.push(telemetryMod);

                var endpointMod = app + "Web.Endpoint";
                try Context.getType(endpointMod) catch (_:Dynamic) {}
                if (discovered.indexOf(endpointMod) == -1) discovered.push(endpointMod);

                var routerMod = app + "Web.Router";
                try Context.getType(routerMod) catch (_:Dynamic) {}
                if (discovered.indexOf(routerMod) == -1) discovered.push(routerMod);

                var webMod = app + "Web";
                try Context.getType(webMod) catch (_:Dynamic) {}
                if (discovered.indexOf(webMod) == -1) discovered.push(webMod);
            }
        } catch (_:Dynamic) {}
        // Repository-wide fallback: find all src_haxe directories under repo root and scan for @:repo/@:presence
        try {
            var thisFile = Context.resolvePath("reflaxe/elixir/CompilerInit.hx");
            var d0 = Path.directory(thisFile);
            var d1 = Path.directory(d0);
            var d2 = Path.directory(d1);
            var repoRoot = Path.directory(d2);
            var roots = findDirsNamed(repoRoot, "src_haxe", 4);
            for (dir in roots) walkDir(dir);
        } catch (_:Dynamic) {}
    }

    public static function getDiscovered(): Array<String> {
        return discovered;
    }

    static function isProjectPath(p: String): Bool {
        if (p == null) return false;
        var lp = p.toLowerCase();
        // Exclude staged std, vendor, node_modules, haxe libs caches
        if (lp.indexOf('/std') != -1) return false;
        if (lp.indexOf('/vendor') != -1) return false;
        if (lp.indexOf('node_modules') != -1) return false;
        if (lp.indexOf('/haxe_libraries') != -1) return false;
        return true;
    }

    static function walkDir(dir: String): Void {
        try {
            for (entry in sys.FileSystem.readDirectory(dir)) {
                var path = Path.join([dir, entry]);
                if (sys.FileSystem.isDirectory(path)) {
                    walkDir(path);
                } else if (StringTools.endsWith(entry, '.hx')) {
                    processHxFile(path);
                }
            }
        } catch (_:Dynamic) {}
    }

    static function findDirsNamed(root:String, name:String, maxDepth:Int): Array<String> {
        var out: Array<String> = [];
        function loop(dir:String, depth:Int): Void {
            if (depth < 0) return;
            var entries: Array<String> = [];
            try entries = sys.FileSystem.readDirectory(dir) catch (_:Dynamic) {}
            for (e in entries) {
                var p = Path.join([dir, e]);
                if (!sys.FileSystem.exists(p)) continue;
                if (sys.FileSystem.isDirectory(p)) {
                    if (e == name) out.push(p);
                    loop(p, depth - 1);
                }
            }
        }
        loop(root, maxDepth);
        return out;
    }

    static function processHxFile(filePath: String): Void {
        try {
            var content = sys.io.File.getContent(filePath);
            if (content == null) return;

            // Fast reject if no token
            if (content.indexOf('@:repo(') == -1 && content.indexOf('@:presence') == -1 && content.indexOf('@:endpoint') == -1 && content.indexOf('@:router') == -1 && content.indexOf('@:phoenixWeb') == -1 && content.indexOf('@:phoenixWebModule') == -1 && (content.indexOf('@:native(') == -1 || (content.indexOf('Web.Telemetry') == -1 && content.indexOf('Web.Endpoint') == -1 && content.indexOf('Web.Router') == -1 && (content.indexOf('TodoAppWeb') == -1 && content.indexOf('Web\")') == -1)))) return;

            // Filter comments (line and block) in a lightweight way
            var hasRepo = false;
            var hasPresence = false;
            var hasEndpoint = false;
            var hasRouter = false;
            var hasPhoenixWeb = false;
            var hasPhoenixWebModule = false;
            var hasTelemetryNative = false;
            var inBlock = false;
            var pkg = '';
            var cls: Null<String> = null;
            for (line in content.split('\n')) {
                var raw = line;
                var t = StringTools.trim(raw);
                // block comment handling
                if (inBlock) {
                    if (t.indexOf('*/') != -1) inBlock = false;
                    continue;
                }
                if (t.startsWith('/*')) {
                    if (t.indexOf('*/') == -1) inBlock = true;
                    continue;
                }
                if (t.startsWith('//')) continue;

                if (!hasRepo && t.indexOf('@:repo(') != -1) hasRepo = true;
                if (!hasPresence && t.indexOf('@:presence') != -1) hasPresence = true;
                if (!hasEndpoint && t.indexOf('@:endpoint') != -1) hasEndpoint = true;
                if (!hasRouter && t.indexOf('@:router') != -1) hasRouter = true;
                if (!hasPhoenixWeb && t.indexOf('@:phoenixWeb') != -1) hasPhoenixWeb = true;
                if (!hasPhoenixWebModule && t.indexOf('@:phoenixWebModule') != -1) hasPhoenixWebModule = true;
                if (!hasTelemetryNative && t.indexOf('@:native(') != -1 && (t.indexOf('Web.Telemetry') != -1 || t.indexOf('Web.Endpoint') != -1 || t.indexOf('Web.Router') != -1 || t.indexOf('TodoAppWeb') != -1)) hasTelemetryNative = true;

                if (pkg == '' && t.startsWith('package ')) {
                    var semi = t.indexOf(';');
                    pkg = semi > 0 ? t.substr(8, semi - 8) : t.substr(8);
                    pkg = StringTools.trim(pkg);
                }
                if (cls == null) {
                    // Match class declaration
                    var re = ~/^(?:extern\s+)?class\s+([A-Za-z0-9_]+)/;
                    if (re.match(t)) {
                        cls = re.matched(1);
                    }
                }
            }

            if (!(hasRepo || hasPresence || hasEndpoint || hasRouter || hasPhoenixWeb || hasPhoenixWebModule || hasTelemetryNative) || cls == null) return;
            var mod = (pkg != null && pkg.length > 0) ? (pkg + '.' + cls) : cls;

            // Force typing so the module becomes available for the compiler
            try Context.getType(mod) catch (_:Dynamic) {}

            // Record discovered module
            if (discovered.indexOf(mod) == -1) discovered.push(mod);
        } catch (_:Dynamic) {}
    }
}

#end
