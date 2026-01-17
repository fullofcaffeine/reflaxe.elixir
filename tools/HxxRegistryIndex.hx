package tools;

#if macro
import haxe.Json;
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.elixir.macros.RepoDiscovery;
import reflaxe.elixir.ast.transformers.HeexAssignsTypeLinterTransforms;
import phoenix.types.HXXComponentRegistry;
import sys.io.File;

/**
 * HxxRegistryIndex
 *
 * Macro-time exporter for editor tooling.
 *
 * Produces a small JSON index of:
 * - built-in HTML tags + allowed attrs (from `HXXComponentRegistry`)
 * - custom HTML tags registered via `@:hxxHtmlTags` + `@:hxxTagAttrs` + optional `@:hxxTagAttrKinds`
 * - hook/event registries (`@:phxHookNames` / `@:phxEventNames`)
 *
 * Run:
 *   haxe tools/HxxRegistryIndex.hxml
 */
class HxxRegistryIndex {
    static var sourceFileCache: Map<String, String> = new Map();

    public static function generate(outPath: String = "tmp/hxx-registry.json"): Void {
        #if !sys
        Context.error("HxxRegistryIndex requires sys for file output.", Context.currentPos());
        #end

        RepoDiscovery.run();
        var discovered = RepoDiscovery.getDiscovered();
        if (discovered == null) discovered = [];

        var customTags = collectCustomHtmlTags(discovered);
        var phxHookNames = collectConstStringRegistry(discovered, ":phxHookNames");
        var phxEventNames = collectConstStringRegistry(discovered, ":phxEventNames");
        var components = collectComponentIndex();

        if (Context.defined("hxx_index_debug")) {
            var shown = discovered.length > 50 ? discovered.slice(0, 50) : discovered;
            Context.warning('[hxx-index] discovered=' + discovered.length + ' [' + shown.join(", ") + (discovered.length > 50 ? ", …" : "") + ']', Context.currentPos());
            Context.warning('[hxx-index] customTags=' + customTags.length + ' components=' + components.length + ' phxHookNames=' + phxHookNames.length + ' phxEventNames=' + phxEventNames.length, Context.currentPos());
        }

        var htmlTags: Array<Dynamic> = [];
        for (tag in HXXComponentRegistry.listHtmlElements()) {
            var info = HXXComponentRegistry.getElementType(tag);
            htmlTags.push({
                name: tag,
                voidElement: info != null ? info.voidElement : false,
                attributeType: info != null ? info.attributeType : null,
                allowedAttributes: HXXComponentRegistry.getAllowedAttributes(tag)
            });
        }

        var data: Dynamic = {
            schemaVersion: 1,
            generatedAt: Date.now().toString(),
            discoveredCount: discovered.length,
            htmlTags: htmlTags,
            customTags: customTags,
            components: components,
            phxHookNames: phxHookNames,
            phxEventNames: phxEventNames
        };

        var dir = Path.directory(outPath);
        if (dir != null && dir.length > 0 && !sys.FileSystem.exists(dir)) sys.FileSystem.createDirectory(dir);
        sys.io.File.saveContent(outPath, Json.stringify(data, null, "  "));
        Context.info('[hxx-index] Wrote ' + outPath, Context.currentPos());
    }

    static function collectComponentIndex(): Array<Dynamic> {
        #if macro
        try {
            return HeexAssignsTypeLinterTransforms.exportComponentIndexForTooling();
        } catch (_:Dynamic) {
            return [];
        }
        #else
        return [];
        #end
    }

    static function collectConstStringRegistry(discovered: Array<String>, metaName: String): Array<String> {
        var out: Map<String, Bool> = new Map();
        for (typePath in discovered) {
            var t: Type = null;
            t = tryGetType(typePath);
            if (t == null && Context.defined("hxx_index_debug") && typePath.indexOf("CustomTags") != -1) {
                Context.warning('[hxx-index] tryGetType failed for ' + typePath, Context.currentPos());
            }
            if (t == null) continue;

            switch (TypeTools.follow(t)) {
                case TAbstract(aRef, _):
                    var abs = aRef.get();
                    if (abs == null || abs.meta == null || !abs.meta.has(metaName)) continue;
                    if (abs.impl == null) continue;
                    var impl = abs.impl.get();
                    if (impl != null) collectConstStringStaticsFromClass(impl, out);
                case TInst(cRef, _):
                    var cls = cRef.get();
                    if (cls == null || cls.meta == null || !cls.meta.has(metaName)) continue;
                    collectConstStringStaticsFromClass(cls, out);
                default:
            }
        }

        var list = [for (k in out.keys()) k];
        list.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
        return list;
    }

    static function collectConstStringStaticsFromClass(cls: haxe.macro.Type.ClassType, out: Map<String, Bool>): Void {
        if (cls == null) return;
        for (field in cls.statics.get()) {
            if (field == null) continue;
            var value = extractStringConst(field.expr());
            if (value == null || value.length == 0) value = extractStringConstFromSource(field);
            if (value != null && value.length > 0) out.set(value, true);
        }
    }

    static function collectCustomHtmlTags(discovered: Array<String>): Array<Dynamic> {
        var tags: Map<String, { attrs: Array<String>, kinds: Map<String, String> }> = new Map();
        if (Context.defined("hxx_index_debug")) {
            Context.warning("[hxx-index] collectCustomHtmlTags()", Context.currentPos());
            Context.warning("[hxx-index] collectCustomHtmlTags discovered=[" + (discovered != null ? discovered.join(", ") : "<null>") + "]", Context.currentPos());
        }

        for (typePath in discovered) {
            var t: Type = null;
            t = tryGetType(typePath);
            if (t == null) continue;

            var followed = TypeTools.follow(t);
            if (Context.defined("hxx_index_debug") && typePath.indexOf("CustomTags") != -1) {
                var kind = switch (followed) {
                    case TInst(_, _): "TInst";
                    case TAbstract(_, _): "TAbstract";
                    case TEnum(_, _): "TEnum";
                    case TType(_, _): "TType";
                    case TFun(_, _): "TFun";
                    case TAnonymous(_): "TAnonymous";
                    case TDynamic(_): "TDynamic";
                    case TLazy(_): "TLazy";
                    case TMono(_): "TMono";
                }
                Context.warning('[hxx-index] type=' + typePath + ' follow=' + kind, Context.currentPos());
            }

            switch (followed) {
                case TInst(cRef, _):
                    var cls = cRef.get();
                    if (Context.defined("hxx_index_debug") && cls != null) {
                        var has = cls.meta != null ? cls.meta.has(":hxxHtmlTags") : false;
                        if (typePath.indexOf("CustomTags") != -1) {
                            Context.warning('[hxx-index] type=' + typePath + ' metaHasHxxHtmlTags=' + has, Context.currentPos());
                        }
                    }
                    if (cls == null || cls.meta == null || !cls.meta.has(":hxxHtmlTags")) continue;
                    collectCustomTagsFromClass(cls, tags);
                case TAbstract(aRef, _):
                    var abs = aRef.get();
                    if (abs == null || abs.meta == null || !abs.meta.has(":hxxHtmlTags")) continue;
                    if (abs.impl == null) continue;
                    var impl = abs.impl.get();
                    if (impl != null) collectCustomTagsFromClass(impl, tags);
                default:
            }
        }

        var out: Array<Dynamic> = [];
        var names = [for (k in tags.keys()) k];
        names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
        for (tag in names) {
            var info = tags.get(tag);
            var kindsObj: Dynamic = {};
            for (k in info.kinds.keys()) Reflect.setField(kindsObj, k, info.kinds.get(k));
            out.push({
                name: tag,
                allowedAttributes: info.attrs,
                attributeKinds: kindsObj
            });
        }
        return out;
    }

    static function tryGetType(typePath: String): Null<Type> {
        if (typePath == null || typePath.length == 0) return null;

        try {
            return Context.getType(typePath);
        } catch (_:Dynamic) {}

        var lastDot = typePath.lastIndexOf(".");
        if (lastDot <= 0 || lastDot >= typePath.length - 1) return null;

        var modulePath = typePath.substr(0, lastDot);
        var typeName = typePath.substr(lastDot + 1);

        var moduleTypes: Array<Type> = null;
        try moduleTypes = Context.getModule(modulePath) catch (_:Dynamic) moduleTypes = null;
        if (moduleTypes == null) return null;

        for (mt in moduleTypes) {
            var followed = TypeTools.follow(mt);
            switch (followed) {
                case TInst(cRef, _):
                    var cls = cRef.get();
                    if (cls != null && cls.name == typeName) return mt;
                case TAbstract(aRef, _):
                    var abs = aRef.get();
                    if (abs != null && abs.name == typeName) return mt;
                case TEnum(eRef, _):
                    var en = eRef.get();
                    if (en != null && en.name == typeName) return mt;
                case TType(tRef, _):
                    var td = tRef.get();
                    if (td != null && td.name == typeName) return mt;
                default:
            }
        }

        return null;
    }

    static function collectCustomTagsFromClass(
        cls: haxe.macro.Type.ClassType,
        out: Map<String, { attrs: Array<String>, kinds: Map<String, String> }>
    ): Void {
        if (cls == null) return;
        for (field in cls.statics.get()) {
            if (field == null) continue;
            var tag = extractStringConst(field.expr());
            if (tag == null || tag.length == 0) tag = extractStringConstFromSource(field);
            if ((tag == null || tag.length == 0) && Context.defined("hxx_index_debug")) {
                var posInfos = Context.getPosInfos(field.pos);
                var where = posInfos != null ? (posInfos.file + ":" + posInfos.min + "-" + posInfos.max) : "<no-pos>";
                Context.warning('[hxx-index] customTag: failed to extract initializer from ' + cls.name + "." + field.name + " @ " + where, Context.currentPos());
            }
            if (tag == null || tag.length == 0) continue;

            var attrs: Array<String> = [];
            var kinds: Map<String, String> = new Map();

            if (field.meta != null && field.meta.has(":hxxTagAttrs")) {
                for (entry in field.meta.extract(":hxxTagAttrs")) {
                    if (entry == null || entry.params == null) continue;
                    attrs = mergeUniqueStrings(attrs, extractStringArrayConst(entry.params));
                }
            }

            if (field.meta != null && field.meta.has(":hxxTagAttrKinds")) {
                for (entry in field.meta.extract(":hxxTagAttrKinds")) {
                    if (entry == null || entry.params == null) continue;
                    kinds = mergeKindMaps(kinds, extractStringToStringMapConst(entry.params));
                }
            }

            for (k in kinds.keys()) attrs = mergeUniqueStrings(attrs, [k]);

            var key = tag.toLowerCase();
            if (out.exists(key)) {
                var existing = out.get(key);
                attrs = mergeUniqueStrings(existing.attrs, attrs);
                kinds = mergeKindMaps(existing.kinds, kinds);
            }
            out.set(key, { attrs: attrs, kinds: kinds });
        }
    }

    static function extractStringConstFromSource(field: haxe.macro.Type.ClassField): Null<String> {
        if (field == null) return null;

        var posInfos = Context.getPosInfos(field.pos);
        if (posInfos == null || posInfos.file == null || posInfos.file.length == 0) return null;

        var content = readSourceFile(posInfos.file);
        if (content == null) return null;

        var min = posInfos.min;
        var max = posInfos.max;
        if (min < 0) min = 0;
        if (max > content.length) max = content.length;
        if (min >= max) return null;

        return extractInitializerStringLiteral(content, min, max);
    }

    static function readSourceFile(path: String): Null<String> {
        if (path == null || path.length == 0) return null;
        if (sourceFileCache.exists(path)) return sourceFileCache.get(path);
        if (!sys.FileSystem.exists(path)) return null;
        var content = File.getContent(path);
        sourceFileCache.set(path, content);
        return content;
    }

    /**
     * Best-effort extraction of a simple string literal from a field initializer inside [min, max).
     *
     * Specifically targets patterns like:
     *   var X = "value";
     *   public static final X = "value";
     *
     * This intentionally ignores earlier string literals in metadata by anchoring on the `=`.
     */
    static function extractInitializerStringLiteral(source: String, min: Int, max: Int): Null<String> {
        if (source == null) return null;
        var eq = source.indexOf("=", min);
        if (eq == -1 || eq >= max) return null;

        var i = eq + 1;
        while (i < max) {
            var c = source.charCodeAt(i);
            if (c == '"'.code) break;
            i++;
        }
        if (i >= max) return null;

        i++; // after opening quote
        var out = new StringBuf();
        var escaping = false;

        while (i < max) {
            var c = source.charCodeAt(i);
            if (escaping) {
                escaping = false;
                switch (c) {
                    case 'n'.code: out.addChar('\n'.code);
                    case 'r'.code: out.addChar('\r'.code);
                    case 't'.code: out.addChar('\t'.code);
                    case '\\'.code: out.addChar('\\'.code);
                    case '"'.code: out.addChar('"'.code);
                    default: out.addChar(c);
                }
                i++;
                continue;
            }

            if (c == '\\'.code) {
                escaping = true;
                i++;
                continue;
            }

            if (c == '"'.code) return out.toString();

            out.addChar(c);
            i++;
        }

        return null;
    }

    static function extractStringConst(expr: Null<haxe.macro.TypedExpr>): Null<String> {
        if (expr == null) return null;
        return switch (expr.expr) {
            case TConst(TString(s)):
                s;
            case TMeta(_, inner):
                extractStringConst(inner);
            case TCast(inner, _):
                extractStringConst(inner);
            case TParenthesis(inner):
                extractStringConst(inner);
            default:
                null;
        };
    }

    static function mergeUniqueStrings(existing: Array<String>, next: Array<String>): Array<String> {
        var out = existing != null ? existing.copy() : [];
        if (next == null) return out;
        var seen: Map<String, Bool> = new Map();
        for (s in out) if (s != null) seen.set(s.toLowerCase(), true);
        for (s in next) {
            if (s == null) continue;
            var k = s.toLowerCase();
            if (seen.exists(k)) continue;
            seen.set(k, true);
            out.push(s);
        }
        return out;
    }

    static function extractStringArrayConst(params: Array<Expr>): Array<String> {
        var out: Array<String> = [];
        if (params == null || params.length == 0) return out;

        function addExpr(e: Expr): Void {
            if (e == null) return;
            switch (e.expr) {
                case EConst(CString(s, _)):
                    if (s != null && s.length > 0) out.push(s);
                case EMeta(_, inner):
                    addExpr(inner);
                case EParenthesis(inner):
                    addExpr(inner);
                default:
            }
        }

        if (params.length == 1) {
            switch (params[0].expr) {
                case EArrayDecl(items):
                    for (i in items) addExpr(i);
                    return out;
                default:
            }
        }

        for (p in params) addExpr(p);
        return out;
    }

    static function extractStringToStringMapConst(params: Array<Expr>): Map<String, String> {
        var out: Map<String, String> = new Map();
        if (params == null || params.length == 0) return out;

        function setPair(key: String, value: String): Void {
            var canonical = HXXComponentRegistry.toHtmlAttribute(key);
            if (canonical == null) return;
            out.set(canonical, value);
        }

        if (params.length == 1) {
            switch (params[0].expr) {
                case EObjectDecl(fields):
                    if (fields == null) return out;
                    for (f in fields) {
                        if (f == null) continue;
                        var key = f.field;
                        var value: Null<String> = null;
                        switch (f.expr.expr) {
                            case EConst(CString(s, _)):
                                value = s;
                            case EParenthesis(inner):
                                switch (inner.expr) {
                                    case EConst(CString(s, _)):
                                        value = s;
                                    default:
                                }
                            default:
                        }
                        if (key != null && key.length > 0 && value != null && value.length > 0) {
                            setPair(key, value);
                        }
                    }
                    return out;
                default:
            }
        }

        var i = 0;
        while (i + 1 < params.length) {
            var key: Null<String> = null;
            var value: Null<String> = null;
            switch (params[i].expr) {
                case EConst(CString(s, _)):
                    key = s;
                default:
            }
            switch (params[i + 1].expr) {
                case EConst(CString(s, _)):
                    value = s;
                default:
            }
            if (key != null && key.length > 0 && value != null && value.length > 0) {
                setPair(key, value);
            }
            i += 2;
        }
        return out;
    }

    static function mergeKindMaps(existing: Map<String, String>, next: Map<String, String>): Map<String, String> {
        var out: Map<String, String> = new Map();
        if (existing != null) for (k in existing.keys()) out.set(k, existing.get(k));
        if (next == null) return out;
        for (k in next.keys()) {
            var left = out.exists(k) ? out.get(k) : null;
            var right = next.get(k);
            if (left == null || left.length == 0) {
                out.set(k, right);
            } else if (right != null && right.length > 0 && left != right) {
                out.set(k, mergeKindUnion(left, right));
            }
        }
        return out;
    }

    static function mergeKindUnion(left: String, right: String): String {
        if (left == null || right == null) return "unknown";
        if (left == "unknown" || right == "unknown") return "unknown";

        var seen: Map<String, Bool> = new Map();
        var ordered: Array<String> = [];

        function addParts(k: String): Void {
            if (k == null || k.length == 0) return;
            var parts = k.split("|");
            for (part in parts) {
                var trimmed = part != null ? StringTools.trim(part) : "";
                if (trimmed.length == 0) continue;
                if (seen.exists(trimmed)) continue;
                seen.set(trimmed, true);
                ordered.push(trimmed);
            }
        }

        addParts(left);
        addParts(right);

        return ordered.length == 1 ? ordered[0] : ordered.join("|");
    }
}
#end
