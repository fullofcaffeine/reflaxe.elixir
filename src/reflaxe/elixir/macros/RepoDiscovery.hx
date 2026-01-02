package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.crypto.Md5;
import haxe.io.Path;
import haxe.io.Eof;
import haxe.Json;
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
    static var afterInitScheduled: Bool = false;
    static var pendingTypePaths: Array<String> = [];

    static final metaTokens: Array<String> = [
        "@:repo",
        "@:presence",
        "@:endpoint",
        "@:router",
        "@:phoenixWeb",
        "@:phoenixWebModule",
        "@:component",
        "@:phxHookNames",
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

        var scanRoots: Array<String> = [];
        for (classPath in classPaths) {
            if (!shouldScanClassPath(classPath)) continue;
            scanRoots.push(classPath);
        }

        var fastBoot = Context.defined("fast_boot");
        if (fastBoot) {
            var cached = loadCache(scanRoots);
            if (cached != null) {
                for (typePath in cached) {
                    forceType(typePath);
                }
                return;
            }
        }

        for (classPath in scanRoots) {
            try walkDir(classPath) catch (_) {}
        }

        if (fastBoot) {
            saveCache(scanRoots, discovered);
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
            var typeName: Null<String> = null;
            var classRe = ~/^(?:extern\s+)?class\s+([A-Za-z0-9_]+)/;
            var enumAbstractRe = ~/^enum\s+abstract\s+([A-Za-z0-9_]+)/;
            var enumRe = ~/^enum\s+([A-Za-z0-9_]+)/;
            var abstractRe = ~/^abstract\s+([A-Za-z0-9_]+)/;

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

                if (typeName == null) {
                    if (classRe.match(t)) {
                        typeName = classRe.matched(1);
                    } else if (enumAbstractRe.match(t)) {
                        typeName = enumAbstractRe.matched(1);
                    } else if (enumRe.match(t)) {
                        typeName = enumRe.matched(1);
                    } else if (abstractRe.match(t)) {
                        typeName = abstractRe.matched(1);
                    }
                }

                if (hasRelevantMeta && typeName != null) break;
            }

            if (!hasRelevantMeta || typeName == null) return;

            var mod = (pkg.length > 0) ? (pkg + "." + typeName) : typeName;
            forceType(mod);
        } catch (e: Eof) {
            // EOF
        } catch (_) {}
        try if (file != null) file.close() catch (_) {}
    }

    static function hasRelevantMetadataToken(line: String): Bool {
        // Migration-only `.exs` build: avoid force-typing non-migration Phoenix modules.
        // This keeps `priv/repo/migrations/` clean (Ecto loads every `.exs` there).
        if (Context.defined("ecto_migrations_exs")) {
            return line.indexOf("@:migration") != -1;
        }

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
        #if debug_repo_discovery
        trace('[RepoDiscovery] discovered ' + typePath);
        #end
        #if (haxe_ver >= 5)
        // Haxe 5 forbids `Context.getType` in initialization macros. We stage the
        // discovered types and force typing once init macros complete.
        pendingTypePaths.push(typePath);

        if (!afterInitScheduled) {
            afterInitScheduled = true;
            Context.onAfterInitMacros(function() {
                for (pendingTypePath in pendingTypePaths) {
                    try {
                        Context.getType(pendingTypePath);
                    } catch (e) {
                        #if debug_repo_discovery
                        trace('[RepoDiscovery] failed to type ' + pendingTypePath + ': ' + Std.string(e));
                        #end
                    }
                }
            });
        }
        #else
        try {
            Context.getType(typePath);
        } catch (e) {
            #if debug_repo_discovery
            trace('[RepoDiscovery] failed to type ' + typePath + ': ' + Std.string(e));
            #end
        }
        #end
    }

    static function loadCache(scanRoots: Array<String>): Null<Array<String>> {
        var cacheFile = cacheFilePath(scanRoots);
        if (cacheFile == null) return null;
        try {
            if (!sys.FileSystem.exists(cacheFile)) return null;
        } catch (_) {
            return null;
        }

        try {
            var parsed: Dynamic = Json.parse(sys.io.File.getContent(cacheFile));
            if (parsed == null || parsed.types == null) return null;

            var types: Array<String> = [];
            for (entry in (cast parsed.types : Array<Dynamic>)) {
                if (entry == null) continue;
                types.push(Std.string(entry));
            }

            return types.length > 0 ? types : null;
        } catch (_) {
            return null;
        }
    }

    static function saveCache(scanRoots: Array<String>, types: Array<String>): Void {
        var cacheFile = cacheFilePath(scanRoots);
        if (cacheFile == null) return;

        try {
            var payload = {
                version: 1,
                roots: scanRoots,
                types: types
            };
            sys.io.File.saveContent(cacheFile, Json.stringify(payload));
        } catch (_) {}
    }

    static function cacheFilePath(scanRoots: Array<String>): Null<String> {
        var cacheDir = cacheDirPath();
        if (cacheDir == null) return null;

        try {
            if (!sys.FileSystem.exists(cacheDir)) sys.FileSystem.createDirectory(cacheDir);
        } catch (_) {
            return null;
        }

        var normalizedRoots = scanRoots.map(normalizePath);
        normalizedRoots.sort(Reflect.compare);
        var keySource = normalizedRoots.join("|") + "##" + metaTokens.join(",");
        var hash = Md5.encode(keySource);
        return Path.join([cacheDir, 'repo_discovery_${hash}.json']);
    }

    static function cacheDirPath(): Null<String> {
        var tmp = Sys.getEnv("TMPDIR");
        if (tmp == null || tmp.length == 0) tmp = Sys.getEnv("TEMP");
        if (tmp == null || tmp.length == 0) tmp = Sys.getEnv("TMP");
        if (tmp == null || tmp.length == 0) tmp = "/tmp";

        if (tmp == null || tmp.length == 0) return null;
        return Path.join([tmp, "reflaxe_elixir_cache"]);
    }
}

#end
