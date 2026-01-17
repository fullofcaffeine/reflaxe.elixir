package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.macros.MigrationRegistry;
import reflaxe.elixir.macros.LiveViewEventRegistry;
import reflaxe.elixir.macros.LiveViewTemplateUsageRegistry;

/**
 * AnnotatedModuleEnumerator
 *
 * WHAT
 * - Global build macro that marks framework-annotated modules (`@:repo`, `@:presence`, `@:endpoint`, etc.)
 *   as `@:keep` so Haxe DCE cannot eliminate them when they are referenced only indirectly at runtime.
 *
 * WHY
 * - Phoenix/Ecto/OTP modules are frequently referenced by strings or generated macros (supervision trees,
 *   `use AppWeb, ...`, etc.). From Haxe’s point of view, these modules can look unused and be removed by DCE,
 *   causing runtime failures like “module X was given as a child to a supervisor but it does not exist”.
 *
 * HOW
 * - Attached via `Compiler.addGlobalMetadata("", "@:build(...)")` in `CompilerInit.Start()`.
 * - For each built class, if it carries any of the supported framework annotations, add `@:keep` (and `@:used`)
 *   to preserve the type through DCE so it reaches the Elixir AST pipeline.
 *
 * EXAMPLES
 * Haxe:
 *   @:native("MyAppWeb.Presence")
 *   @:presence
 *   class Presence implements PresenceBehavior {}
 *
 * Elixir:
 *   defmodule MyAppWeb.Presence do
 *     use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
 *   end
 */
class AnnotatedModuleEnumerator {
    static final keepMetas: Array<String> = [
        ":schema",
        ":repo",
        ":presence",
        ":endpoint",
        ":router",
        ":phoenixWeb",
        ":phoenixWebModule",
        ":component",
        ":controller",
        ":channel",
        ":socket",
        ":liveview",
        ":phxHookNames",
        ":phxEventNames",
        ":application",
        ":supervisor",
        ":genserver"
    ];

    public static function ensureKept(): Null<Array<Field>> {
        #if eval
        final clsRef = Context.getLocalClass();
        if (clsRef == null) return null;

        final cls = clsRef.get();
        final meta = cls.meta;
        if (meta == null) return null;

        final fields = Context.getBuildFields();
        final isSchema = meta.has(":schema");
        final isLiveView = meta.has(":liveview");

        if (isSchema) {
            normalizeSchemaMetadata(cls);
            validateSchemaTableNameIfKnown(cls);
            maybeInjectManyToManyJoinThrough(cls, fields);
            for (field in fields) {
                if (isSchemaField(field)) ensureSchemaFieldKept(field);
            }
        }

        if (isLiveView) {
            registerLiveViewEvents(cls, fields);
            registerLiveViewTemplatePhxUsage(cls, fields);
        }

        var shouldKeepModule = false;
        for (metaName in keepMetas) {
            if (meta.has(metaName)) {
                shouldKeepModule = true;
                break;
            }
        }

        if (!isSchema && !shouldKeepModule) return null;

        #if debug_annotated_module_enumerator
        trace('[AnnotatedModuleEnumerator] keep ' + ((cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name));
        #end

        if (!shouldKeepModule) return fields;

        final keepAllPublicStatic = meta.has(":controller")
            || meta.has(":channel")
            || meta.has(":socket")
            || meta.has(":router")
            || meta.has(":endpoint")
            || meta.has(":phoenixWeb")
            || meta.has(":phoenixWebModule");

        final keepOnlyComponentFunctions = meta.has(":component");
        final keepNames = buildKeepNameSet(meta);

        for (field in fields) {
            if (keepAllPublicStatic) {
                ensureFieldKept(field);
                continue;
            }
            if (keepOnlyComponentFunctions) {
                if (fieldMetaHas(field.meta, ":component")) ensureFieldKept(field);
                continue;
            }
            if (keepNames.exists(field.name)) ensureFieldKept(field);
        }

        if (!meta.has(":keep")) meta.add(":keep", [], cls.pos);
        if (!meta.has(":used")) meta.add(":used", [], cls.pos);
        return fields;
        #end
        return null;
    }

    static function registerLiveViewEvents(cls: haxe.macro.Type.ClassType, fields: Array<Field>): Void {
        // Register LiveView event names from `handle_event/3` switch cases.
        //
        // Supported shapes:
        // - `return switch (event) { case "increment": ... }`
        // - `switch (event) { case EventName.Increment: ... }` (compile-time string constants)
        //
        // NOTE: This is intentionally conservative. It does not attempt to infer events from
        // dynamic expressions or from template strings; it only harvests compile-time constants.
        final moduleName = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
        if (fields == null) return;

        for (field in fields) {
            if (field == null) continue;
            if (field.name != "handle_event" && field.name != "handleEvent") continue;

            // Prefer `@:native("handle_event")` static functions, but accept canonical name too.
            if (!isPublicStatic(field)) continue;

            var eventVarName: Null<String> = null;
            final expr = switch (field.kind) {
                case FFun(f):
                    if (f != null && f.args != null && f.args.length > 0) {
                        eventVarName = f.args[0].name;
                    }
                    f.expr;
                default:
                    null;
            }
            if (expr == null) continue;
            if (eventVarName == null || eventVarName.length == 0) eventVarName = "event";

            var events: Array<String> = [];
            collectSwitchCaseConstants(expr, eventVarName, events);
            if (events.length > 0) {
                LiveViewEventRegistry.registerMany(moduleName, events, field.pos);
            }
        }
    }

    static function registerLiveViewTemplatePhxUsage(cls: haxe.macro.Type.ClassType, fields: Array<Field>): Void {
        // Best-effort: scan `render/1` bodies for HXX.hxx(...) templates and record `phx-*` names
        // used in those templates for editor tooling indexes.
        //
        // This intentionally operates on the *Haxe AST* (pre-Elixir pipeline) so it can run in
        // tooling-only macro contexts (e.g. docs:hxx:index) without needing to run the full compiler.
        final moduleName = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
        if (fields == null) return;

        for (field in fields) {
            if (field == null) continue;
            if (field.name != "render") continue;
            var body: Null<Expr> = switch (field.kind) {
                case FFun(f): f != null ? f.expr : null;
                default: null;
            };
            if (body == null) continue;

            var templates: Array<Expr> = [];
            collectHxxTemplateArguments(body, templates);
            if (templates.length == 0) continue;

            for (t in templates) {
                if (t == null) continue;
                var buf = new StringBuf();
                collectConstTemplateText(t, buf);
                var reconstructed = buf.toString();
                if (reconstructed != null && reconstructed.length > 0) {
                    scanTemplateForPhxUsage(moduleName, reconstructed, field.pos);
                }
            }
        }
    }

    static function collectHxxTemplateArguments(expr: Expr, out: Array<Expr>): Void {
        if (expr == null || expr.expr == null) return;
        switch (expr.expr) {
            case EReturn(e):
                collectHxxTemplateArguments(e, out);
            case ECall(fn, args):
                if (isHxxStaticCall(fn, "hxx") && args != null && args.length > 0) {
                    out.push(args[0]);
                }
                collectHxxTemplateArguments(fn, out);
                if (args != null) for (a in args) collectHxxTemplateArguments(a, out);
            case EBlock(exprs):
                if (exprs != null) for (e in exprs) collectHxxTemplateArguments(e, out);
            case EIf(cond, eThen, eElse):
                collectHxxTemplateArguments(cond, out);
                collectHxxTemplateArguments(eThen, out);
                if (eElse != null) collectHxxTemplateArguments(eElse, out);
            case ESwitch(target, cases, def):
                collectHxxTemplateArguments(target, out);
                if (cases != null) {
                    for (c in cases) {
                        if (c == null) continue;
                        if (c.values != null) for (v in c.values) collectHxxTemplateArguments(v, out);
                        if (c.expr != null) collectHxxTemplateArguments(c.expr, out);
                    }
                }
                if (def != null) collectHxxTemplateArguments(def, out);
            case EWhile(cond, body, _):
                collectHxxTemplateArguments(cond, out);
                collectHxxTemplateArguments(body, out);
            case EFor(it, body):
                collectHxxTemplateArguments(it, out);
                collectHxxTemplateArguments(body, out);
            case ETry(e, catches):
                collectHxxTemplateArguments(e, out);
                if (catches != null) {
                    for (c in catches) if (c != null && c.expr != null) collectHxxTemplateArguments(c.expr, out);
                }
            case EBinop(_, a, b):
                collectHxxTemplateArguments(a, out);
                collectHxxTemplateArguments(b, out);
            case EUnop(_, _, a):
                collectHxxTemplateArguments(a, out);
            case EParenthesis(a):
                collectHxxTemplateArguments(a, out);
            case EMeta(_, a):
                collectHxxTemplateArguments(a, out);
            default:
        }
    }

    static function isHxxStaticCall(fn: Expr, name: String): Bool {
        if (fn == null || fn.expr == null) return false;
        return switch (fn.expr) {
            case EField(owner, fieldName):
                if (fieldName != name) return false;
                if (owner == null || owner.expr == null) return false;
                switch (owner.expr) {
                    case EConst(CIdent("HXX")):
                        true;
                    case EField(_, "HXX"):
                        true;
                    default:
                        false;
                }
            case EMeta(_, inner):
                isHxxStaticCall(inner, name);
            case EParenthesis(inner):
                isHxxStaticCall(inner, name);
            default:
                false;
        };
    }

    static function collectConstTemplateText(expr: Expr, buf: StringBuf): Void {
        if (expr == null || expr.expr == null) return;
        switch (expr.expr) {
            case EConst(CString(s, _)):
                buf.add(s);
            case EBinop(OpAdd, a, b):
                collectConstTemplateText(a, buf);
                collectConstTemplateText(b, buf);
            case EParenthesis(inner):
                collectConstTemplateText(inner, buf);
            case EMeta(_, inner):
                collectConstTemplateText(inner, buf);
            default:
                // Only inline compile-time known string constants; skip dynamic inserts (assigns, etc.)
                var s = tryEvalConstString(expr);
                if (s != null) buf.add(s);
        }
    }

    static function scanTemplateForPhxUsage(moduleName: String, template: String, pos: haxe.macro.Expr.Position): Void {
        if (moduleName == null || moduleName.length == 0) return;
        if (template == null || template.length == 0) return;

        // Keep aligned with HEEx attribute validation.
        final eventAttrs: Array<String> = [
            "phx-click", "phx-submit", "phx-change", "phx-blur", "phx-focus",
            "phx-keydown", "phx-keyup", "phx-window-keydown", "phx-window-keyup",
            "phx-click-away"
        ];

        inline function isWs(ch: String): Bool return ch != null && ~/^\\s$/.match(ch);
        inline function isAttrChar(ch: String): Bool {
            if (ch == null || ch.length == 0) return false;
            var c = ch.charCodeAt(0);
            return (c >= "A".code && c <= "Z".code)
                || (c >= "a".code && c <= "z".code)
                || (c >= "0".code && c <= "9".code)
                || ch == "-" || ch == "_";
        }
        function isEventAttr(name: String): Bool {
            for (ev in eventAttrs) if (ev == name) return true;
            return false;
        }

        var i = 0;
        while (i < template.length) {
            var idx = template.indexOf("phx-", i);
            if (idx == -1) break;
            var j = idx;
            while (j < template.length && isAttrChar(template.charAt(j))) j++;
            var attrName = template.substr(idx, j - idx);
            var isHook = attrName == "phx-hook";
            var isEvent = isEventAttr(attrName);
            if (!isHook && !isEvent) { i = j; continue; }

            var k = j;
            while (k < template.length && isWs(template.charAt(k))) k++;
            if (k >= template.length || template.charAt(k) != "=") { i = j; continue; }
            k++;
            while (k < template.length && isWs(template.charAt(k))) k++;
            if (k >= template.length) break;

            var value: Null<String> = null;
            var ch = template.charAt(k);
            if (ch == "\"" || ch == "'") {
                var q = ch;
                k++;
                var start = k;
                while (k < template.length && template.charAt(k) != q) k++;
                if (k < template.length) value = template.substr(start, k - start);
                i = k + 1;
            } else if (ch == "{") {
                // Only record constant forms like {"..."} / {'...'}.
                var exprStart = k + 1;
                k++;
                var depth = 1;
                while (k < template.length && depth > 0) {
                    var ch2 = template.charAt(k);
                    if (ch2 == "{") depth++;
                    else if (ch2 == "}") depth--;
                    k++;
                }
                var exprEndExclusive = k - 1;
                if (exprEndExclusive > exprStart) {
                    var inner = StringTools.trim(template.substr(exprStart, exprEndExclusive - exprStart));
                    if (inner.length >= 2) {
                        var q0 = inner.charAt(0);
                        var q1 = inner.charAt(inner.length - 1);
                        if ((q0 == "\"" && q1 == "\"") || (q0 == "'" && q1 == "'")) {
                            value = inner.substr(1, inner.length - 2);
                        }
                    }
                }
                i = k;
            } else {
                // Bareword until whitespace or tag end.
                var start2 = k;
                while (k < template.length) {
                    var ch2 = template.charAt(k);
                    if (isWs(ch2) || ch2 == ">" || ch2 == "/") break;
                    k++;
                }
                if (k > start2) value = template.substr(start2, k - start2);
                i = k;
            }

            if (value != null) {
                var trimmed = StringTools.trim(value);
                if (trimmed.length > 0) {
                    // HXX attribute interpolations commonly appear as `${ConstName.Value}` inside the
                    // template string (not Haxe string interpolation). If the inner expression is a
                    // compile-time string constant, record the resolved value; otherwise, skip.
                    if (StringTools.startsWith(trimmed, "${") && StringTools.endsWith(trimmed, "}")) {
                        var inner = StringTools.trim(trimmed.substr(2, trimmed.length - 3));
                        var resolved: Null<String> = null;
                        try {
                            var parsed = Context.parse(inner, pos);
                            resolved = tryEvalConstString(parsed);
                        } catch (_: Dynamic) {
                            resolved = null;
                        }
                        if (resolved == null) {
                            // Do not record dynamic values.
                            trimmed = "";
                        } else {
                            trimmed = StringTools.trim(resolved);
                        }
                    }

                    if (trimmed.length > 0) {
                        if (isHook) LiveViewTemplateUsageRegistry.registerHook(moduleName, trimmed);
                        else if (isEvent) LiveViewTemplateUsageRegistry.registerEvent(moduleName, trimmed);
                    }
                }
            }
        }
        var _ = pos;
    }

    static function collectSwitchCaseConstants(expr: Expr, switchVarName: String, out: Array<String>): Void {
        if (expr == null) return;
        if (expr.expr == null) return;
        switch (expr.expr) {
            case EReturn(e):
                collectSwitchCaseConstants(e, switchVarName, out);
            case ESwitch(target, cases, _default):
                // Only collect events from `switch(<eventVar>)` to avoid false positives from
                // other unrelated switches inside handle_event bodies.
                if (switchTargetIsVar(target, switchVarName)) {
                    for (c in cases) {
                        if (c == null || c.values == null) continue;
                        for (v in c.values) {
                            var s = tryEvalConstString(v);
                            if (s != null) out.push(s);
                        }
                    }
                }

                // Always recurse into case bodies to find additional event switches (e.g. nested logic).
                for (c in cases) {
                    if (c == null) continue;
                    if (c.expr != null) collectSwitchCaseConstants(c.expr, switchVarName, out);
                }
                if (_default != null) collectSwitchCaseConstants(_default, switchVarName, out);
            case EBlock(exprs):
                if (exprs != null) for (e in exprs) collectSwitchCaseConstants(e, switchVarName, out);
            case EIf(cond, eThen, eElse):
                collectSwitchCaseConstants(cond, switchVarName, out);
                collectSwitchCaseConstants(eThen, switchVarName, out);
                if (eElse != null) collectSwitchCaseConstants(eElse, switchVarName, out);
            case EWhile(cond, body, _):
                collectSwitchCaseConstants(cond, switchVarName, out);
                collectSwitchCaseConstants(body, switchVarName, out);
            case EFor(it, body):
                collectSwitchCaseConstants(it, switchVarName, out);
                collectSwitchCaseConstants(body, switchVarName, out);
            case ETry(e, catches):
                collectSwitchCaseConstants(e, switchVarName, out);
                if (catches != null) {
                    for (c in catches) if (c != null && c.expr != null) collectSwitchCaseConstants(c.expr, switchVarName, out);
                }
            case ECall(fn, args):
                collectSwitchCaseConstants(fn, switchVarName, out);
                if (args != null) for (a in args) collectSwitchCaseConstants(a, switchVarName, out);
            case EBinop(_, a, b):
                collectSwitchCaseConstants(a, switchVarName, out);
                collectSwitchCaseConstants(b, switchVarName, out);
            case EUnop(_, _, a):
                collectSwitchCaseConstants(a, switchVarName, out);
            case EParenthesis(a):
                collectSwitchCaseConstants(a, switchVarName, out);
            case EMeta(_, a):
                collectSwitchCaseConstants(a, switchVarName, out);
            case _:
        }
    }

    static function switchTargetIsVar(expr: Expr, varName: String): Bool {
        if (expr == null || varName == null || varName.length == 0) return false;
        if (expr.expr == null) return false;
        return switch (expr.expr) {
            case EConst(CIdent(name)):
                name == varName;
            case EParenthesis(inner):
                switchTargetIsVar(inner, varName);
            case EMeta(_, inner):
                switchTargetIsVar(inner, varName);
            default:
                false;
        };
    }

    static function normalizeSchemaMetadata(cls: haxe.macro.Type.ClassType): Void {
        // Normalize @:schema(<const>) to @:schema("...") when possible so downstream phases
        // can rely on a single representation.
        //
        // This enables typed, constant-based usage such as:
        //   enum abstract DbTable(String) { var Posts = "posts"; }
        //   @:schema(DbTable.Posts)
        //
        // NOTE: We intentionally restrict normalization to *compile-time* string constants.
        final schemaMetas = cls.meta.extract(":schema");
        if (schemaMetas == null || schemaMetas.length == 0) return;

        final params = schemaMetas[0].params;
        if (params == null || params.length == 0) return;

        final first = params[0];
        switch (first.expr) {
            case EConst(CString(_, _)):
                return;
            default:
        }

        final constString = tryEvalConstString(first);
        if (constString == null) return;

        schemaMetas[0].params[0] = { expr: EConst(CString(constString)), pos: first.pos };
    }

    static function validateSchemaTableNameIfKnown(cls: haxe.macro.Type.ClassType): Void {
        final tableName = extractSchemaTableName(cls);
        if (tableName == null) return;
        MigrationRegistry.validateTableExistsDeferred(tableName, cls.pos);
    }

    static function maybeInjectManyToManyJoinThrough(cls: haxe.macro.Type.ClassType, fields: Array<Field>): Void {
        final tableName = extractSchemaTableName(cls);
        if (tableName == null) return;

        for (field in fields) {
            final manyToMany = findMeta(field.meta, ":many_to_many");
            if (manyToMany == null) continue;

            final params = manyToMany.params;
            if (params == null) continue;

            // Normalize string-constant expressions inside params when possible.
            for (i in 0...params.length) {
                final s = tryEvalConstString(params[i]);
                if (s != null) {
                    params[i] = { expr: EConst(CString(s)), pos: params[i].pos };
                }
            }

            // Detect existing options object and whether it contains join_through/through.
            var optionsExpr: Null<Expr> = null;
            var hasJoinThrough = false;
            var joinThroughValue: Null<String> = null;

            for (p in params) {
                switch (p.expr) {
                    case EObjectDecl(pairs):
                        optionsExpr = p;
                        // Normalize option values like `{through: DbTable.PostsTags}` to string literals when possible.
                        for (pair in pairs) {
                            final s = tryEvalConstString(pair.expr);
                            if (s != null) {
                                pair.expr = { expr: EConst(CString(s)), pos: pair.expr.pos };
                            }
                        }
                        for (pair in pairs) {
                            if (pair.field == "join_through" || pair.field == "through") {
                                hasJoinThrough = true;
                                switch (pair.expr.expr) {
                                    case EConst(CString(v, _)):
                                        joinThroughValue = v;
                                    default:
                                }
                            }
                        }
                    default:
                }
            }

            if (hasJoinThrough) {
                if (joinThroughValue != null) {
                    MigrationRegistry.validateTableExistsDeferred(joinThroughValue, field.pos);
                }
                continue;
            }

            final targetTypeName = extractAssociationTargetTypeName(field);
            if (targetTypeName == null) continue;

            final targetTableName = extractSchemaTableNameByTypeName(targetTypeName);
            if (targetTableName == null) continue;

            final expectedJoinTable = tableName + "_" + targetTableName;
            final joinThroughExpr: Expr = { expr: EConst(CString(expectedJoinTable)), pos: field.pos };
            MigrationRegistry.validateTableExistsDeferred(expectedJoinTable, field.pos);

            if (optionsExpr == null) {
                // Append a new options object.
                params.push({
                    expr: EObjectDecl([{
                        field: "through",
                        expr: joinThroughExpr
                    }]),
                    pos: field.pos
                });
                continue;
            }

            // Mutate existing options object to add through: "...".
            switch (optionsExpr.expr) {
                case EObjectDecl(pairs):
                    pairs.push({
                        field: "through",
                        expr: joinThroughExpr
                    });
                default:
            }
        }
    }

    static function extractSchemaTableName(cls: haxe.macro.Type.ClassType): Null<String> {
        final schemaMetas = cls.meta.extract(":schema");
        if (schemaMetas == null || schemaMetas.length == 0) return null;

        final params = schemaMetas[0].params;
        if (params == null || params.length == 0) return null;

        switch (params[0].expr) {
            case EConst(CString(table, _)):
                return table;
            default:
                return tryEvalConstString(params[0]);
        }
    }

    static function extractSchemaTableNameByTypeName(typeName: String): Null<String> {
        try {
            final t = Context.getType(typeName);
            return switch (t) {
                case TInst(ct, _):
                    extractSchemaTableName(ct.get());
                case _:
                    null;
            }
        } catch (_: Dynamic) {
            return null;
        }
    }

    static function extractAssociationTargetTypeName(field: Field): Null<String> {
        final t = switch (field.kind) {
            case FVar(ct, _) | FProp(_, _, ct, _):
                ct;
            default:
                null;
        }
        if (t == null) return null;

        // Handle Array<T> (has_many / many_to_many) and direct types (belongs_to / has_one).
        return switch (t) {
            case TPath(p):
                if (p.name == "Array" && p.params != null && p.params.length == 1) {
                    switch (p.params[0]) {
                        case TPType(TPath(inner)):
                            inner.pack != null && inner.pack.length > 0
                                ? inner.pack.join(".") + "." + inner.name
                                : inner.name;
                        default:
                            null;
                    }
                } else {
                    p.pack != null && p.pack.length > 0 ? p.pack.join(".") + "." + p.name : p.name;
                }
            default:
                null;
        }
    }

    static function findMeta(meta: Null<Array<MetadataEntry>>, name: String): Null<MetadataEntry> {
        if (meta == null) return null;
        for (m in meta) {
            if (m.name == name) return m;
        }
        return null;
    }

    static function tryEvalConstString(expr: Expr): Null<String> {
        if (expr == null || expr.expr == null) return null;

        // Fast path: literal string.
        switch (expr.expr) {
            case EConst(CString(s, _)):
                return s;
            default:
        }

        function extractStringConst(expr: Null<TypedExpr>): Null<String> {
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

        function extractTypePath(expr: Expr): Null<String> {
            if (expr == null || expr.expr == null) return null;
            return switch (expr.expr) {
                case EConst(CIdent(name)):
                    name;
                case EField(inner, name):
                    var base = extractTypePath(inner);
                    base != null ? (base + "." + name) : null;
                case EParenthesis(inner):
                    extractTypePath(inner);
                case EMeta(_, inner):
                    extractTypePath(inner);
                default:
                    null;
            };
        }

        // Best-effort: if this is a type-path field access (`DbTable.Posts`), resolve by reading the
        // owner's static field expr. This avoids "Type is not ready to be accessed" failures.
        switch (expr.expr) {
            case EField(owner, fieldName):
                var ownerTypePath = extractTypePath(owner);
                if (ownerTypePath != null && ownerTypePath.length > 0 && fieldName != null && fieldName.length > 0) {
                    try {
                        var ownerType = Context.getType(ownerTypePath);
                        switch (haxe.macro.TypeTools.follow(ownerType)) {
                            case TAbstract(aRef, _):
                                var abs = aRef.get();
                                if (abs != null && abs.impl != null) {
                                    var impl = abs.impl.get();
                                    if (impl != null) {
                                        for (f in impl.statics.get()) {
                                            if (f != null && f.name == fieldName) {
                                                var s = extractStringConst(f.expr());
                                                if (s != null) return s;
                                            }
                                        }
                                    }
                                }
                            case TInst(cRef, _):
                                var cls = cRef.get();
                                if (cls != null) {
                                    for (f in cls.statics.get()) {
                                        if (f != null && f.name == fieldName) {
                                            var s = extractStringConst(f.expr());
                                            if (s != null) return s;
                                        }
                                    }
                                }
                            default:
                        }
                    } catch (_: Dynamic) {}
                }
            default:
        }

        // Fallback: ask Haxe to type the expression (can fail in some macro ordering cases).
        try {
            final typed = Context.typeExpr(expr);
            return extractStringConst(typed);
        } catch (_: Dynamic) {
            return null;
        }
    }

    static function ensureFieldKept(field: Field): Void {
        if (!isPublicStatic(field)) return;
        if (field.meta == null) field.meta = [];
        if (!fieldMetaHas(field.meta, ":keep")) {
            field.meta.push({ name: ":keep", params: [], pos: field.pos });
        }
    }

    static function ensureSchemaFieldKept(field: Field): Void {
        if (field.access != null) {
            for (a in field.access) {
                if (a == APrivate) return;
            }
        }
        if (field.meta == null) field.meta = [];
        if (!fieldMetaHas(field.meta, ":keep")) {
            field.meta.push({ name: ":keep", params: [], pos: field.pos });
        }
    }

    static function isSchemaField(field: Field): Bool {
        return switch (field.kind) {
            case FVar(_, _) | FProp(_, _, _, _):
                fieldMetaHas(field.meta, ":field")
                    || fieldMetaHas(field.meta, ":virtual")
                    || fieldMetaHas(field.meta, ":belongs_to")
                    || fieldMetaHas(field.meta, ":has_many")
                    || fieldMetaHas(field.meta, ":has_one")
                    || fieldMetaHas(field.meta, ":many_to_many");
            default:
                false;
        }
    }

    static function isPublicStatic(field: Field): Bool {
        if (field.access == null) return false;
        var isStatic = false;
        for (a in field.access) {
            if (a == AStatic) isStatic = true;
            if (a == APrivate) return false;
        }
        return isStatic;
    }

    static function fieldMetaHas(meta: Null<Array<MetadataEntry>>, metaName: String): Bool {
        if (meta == null) return false;
        for (m in meta) {
            if (m.name == metaName) return true;
        }
        return false;
    }

    static function buildKeepNameSet(classMeta: haxe.macro.Type.MetaAccess): Map<String, Bool> {
        final names: Map<String, Bool> = new Map();

        if (classMeta.has(":application")) {
            names.set("start", true);
            names.set("stop", true);
            names.set("prep_stop", true);
            names.set("prepStop", true);
            names.set("config_change", true);
            names.set("configChange", true);
        }

        if (classMeta.has(":supervisor")) {
            names.set("child_spec", true);
            names.set("childSpec", true);
            names.set("start_link", true);
            names.set("startLink", true);
            names.set("init", true);
        }

        if (classMeta.has(":genserver")) {
            names.set("child_spec", true);
            names.set("childSpec", true);
            names.set("start_link", true);
            names.set("startLink", true);
            names.set("init", true);
            names.set("handle_call", true);
            names.set("handleCall", true);
            names.set("handle_cast", true);
            names.set("handleCast", true);
            names.set("handle_info", true);
            names.set("handleInfo", true);
            names.set("handle_continue", true);
            names.set("handleContinue", true);
            names.set("terminate", true);
            names.set("code_change", true);
            names.set("codeChange", true);
        }

        if (classMeta.has(":liveview")) {
            names.set("mount", true);
            names.set("render", true);
            names.set("handle_event", true);
            names.set("handleEvent", true);
            names.set("handle_info", true);
            names.set("handleInfo", true);
            names.set("handle_params", true);
            names.set("handleParams", true);
            names.set("terminate", true);
        }

        return names;
    }
}

#end
