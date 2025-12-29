package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.io.Path;
import haxe.io.Eof;
using StringTools;

/**
 * RepoDiscovery
 *
 * WHAT
 * - Macro-phase discovery of Haxe modules annotated with Phoenix/Ecto metadata (e.g. @:repo,
 *   @:presence, @:router, @:endpoint, @:phoenixWebModule) and force-typing them so they are
 *   available to the normal AST pipeline (Builder → Transformer → Printer).
 *
 * WHY
 * - Some Phoenix modules are referenced only at runtime (e.g., via supervision trees or `use AppWeb, ...`)
 *   and therefore appear “unused” to Haxe. If they are never typed, later passes cannot transform them
 *   and they will not be emitted, breaking runtime (missing Repo/Endpoint/Presence/etc).
 * - Forcing typing makes the behavior deterministic without requiring users to list every module in hxml.
 *
 * HOW
 * - At CompilerInit.Start(), call RepoDiscovery.run().
 * - RepoDiscovery scans *project* classpaths for `.hx` files containing the relevant metadata,
 *   parses the Haxe type path (package + class), and calls `Context.getType(typePath)` to force typing.
 * - DCE preservation happens elsewhere:
 *   - RepoEnumerator marks `@:repo` modules as `@:keep`.
 *   - LiveViewPreserver adds `@:keep` to common Phoenix modules (endpoint/router/presence/components).
 *
 * EXAMPLES
 * Haxe (unreferenced at compile time):
 *   @:native("MyApp.Repo")
 *   @:repo({ adapter: Postgres, json: Jason, extensions: [], poolSize: 10 })
 *   extern class Repo {}
 *
 * Outcome:
 * - RepoDiscovery forces typing of `myapp.Repo` so the repoTransformPass can emit `MyApp.Repo`.
 */
class RepoDiscovery {
    static var discovered: Array<String> = [];
    static var hasRun: Bool = false;

    static final metaTokens: Array<String> = [
        "@:repo",
        "@:presence",
        "@:endpoint",
        "@:router",
        "@:phoenixWeb",
        "@:phoenixWebModule",
        "@:component",
        "@:controller",
        "@:channel",
        "@:socket",
        "@:liveview",
        "@:application"
    ];

    public static function run(): Void {
        if (hasRun) return;
        hasRun = true;

        var classPaths: Array<String> = [];
        try classPaths = Context.getClassPath() catch (_) return;

        for (classPath in classPaths) {
            if (!shouldScanClassPath(classPath)) continue;
            try walkDir(classPath) catch (_) {}
        }
    }

    public static function getDiscovered(): Array<String> {
        return discovered;
    }

    static function shouldScanClassPath(classPath: String): Bool {
        if (classPath == null || classPath.length == 0) return false;

        try {
            if (!sys.FileSystem.isDirectory(classPath)) return false;
        } catch (_) {
            return false;
        }

        var normalized = normalizePath(classPath);
        // Skip common dependency/cache roots
        if (normalized.indexOf("/node_modules") != -1) return false;
        if (normalized.indexOf("/haxe_libraries") != -1) return false;
        if (normalized.indexOf("/.haxelib") != -1) return false;

        // Skip this compiler's own source roots (prevents scanning thousands of library files).
        // This is library-specific (safe), not app-specific.
        if (looksLikeCompilerSourceRoot(classPath)) return false;
        if (looksLikeCompilerStdRoot(classPath)) return false;

        return true;
    }

    static function normalizePath(path: String): String {
        if (path == null) return "";
        return path.split("\\").join("/").toLowerCase();
    }

    static function looksLikeCompilerSourceRoot(classPath: String): Bool {
        return sys.FileSystem.exists(Path.join([classPath, "reflaxe", "elixir", "CompilerInit.hx"]));
    }

    static function looksLikeCompilerStdRoot(classPath: String): Bool {
        return sys.FileSystem.exists(Path.join([classPath, "elixir", "otp", "TypeSafeChildSpec.hx"]));
    }

    static function shouldSkipDirName(name: String): Bool {
        if (name == null) return true;
        return name == ".git" || name == "node_modules" || name == "_build" || name == "deps" || name == ".haxelib" || name == "haxe_libraries";
    }

    static function walkDir(dir: String): Void {
        try {
            for (entry in sys.FileSystem.readDirectory(dir)) {
                var path = Path.join([dir, entry]);
                if (sys.FileSystem.isDirectory(path)) {
                    if (shouldSkipDirName(entry)) continue;
                    walkDir(path);
                } else if (StringTools.endsWith(entry, '.hx')) {
                    processHxFile(path);
                }
            }
        } catch (_) {}
    }

    static function processHxFile(filePath: String): Void {
        var file: Null<sys.io.FileInput> = null;
        try {
            file = sys.io.File.read(filePath, false);

            var inBlock = false;
            var hasRelevantMeta = false;
            var pkg = "";
            var cls: Null<String> = null;
            var classRe = ~/^(?:extern\s+)?class\s+([A-Za-z0-9_]+)/;

            while (true) {
                var line = file.readLine();
                var t = StringTools.trim(line);

                if (t.length == 0) continue;

                if (inBlock) {
                    if (t.indexOf("*/") != -1) inBlock = false;
                    continue;
                }
                if (t.startsWith("/*")) {
                    if (t.indexOf("*/") == -1) inBlock = true;
                    continue;
                }
                if (t.startsWith("//")) continue;

                if (pkg.length == 0 && t.startsWith("package ")) {
                    var rest = t.substr("package ".length);
                    var semi = rest.indexOf(";");
                    if (semi != -1) rest = rest.substr(0, semi);
                    pkg = StringTools.trim(rest);
                }

                if (!hasRelevantMeta && hasRelevantMetadataToken(t)) {
                    hasRelevantMeta = true;
                }

                if (cls == null && classRe.match(t)) {
                    cls = classRe.matched(1);
                }

                if (hasRelevantMeta && cls != null) break;
            }

            if (!hasRelevantMeta || cls == null) return;

            var mod = (pkg.length > 0) ? (pkg + "." + cls) : cls;
            forceType(mod);
        } catch (e: Eof) {
            // EOF
        } catch (_) {}
        try if (file != null) file.close() catch (_) {}
    }

    static function hasRelevantMetadataToken(line: String): Bool {
        for (token in metaTokens) {
            if (line.indexOf(token) != -1) return true;
        }
        // Phoenix generator convention: Telemetry module is often referenced only via strings.
        if (line.indexOf("@:native(") != -1 && line.indexOf("Web.Telemetry") != -1) return true;
        return false;
    }

    static function forceType(typePath: String): Void {
        if (typePath == null || typePath.length == 0) return;
        if (discovered.indexOf(typePath) != -1) return;
        discovered.push(typePath);
        try Context.getType(typePath) catch (_) {}
    }
}

#end
