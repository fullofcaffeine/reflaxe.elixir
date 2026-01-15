package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

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

        if (isSchema) {
            normalizeSchemaMetadata(cls);
            maybeInjectManyToManyJoinThrough(cls, fields);
            for (field in fields) {
                if (isSchemaField(field)) ensureSchemaFieldKept(field);
            }
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
                            }
                        }
                    default:
                }
            }

            if (hasJoinThrough) continue;

            final targetTypeName = extractAssociationTargetTypeName(field);
            if (targetTypeName == null) continue;

            final targetTableName = extractSchemaTableNameByTypeName(targetTypeName);
            if (targetTableName == null) continue;

            final expectedJoinTable = tableName + "_" + targetTableName;
            final joinThroughValue: Expr = { expr: EConst(CString(expectedJoinTable)), pos: field.pos };

            if (optionsExpr == null) {
                // Append a new options object.
                params.push({
                    expr: EObjectDecl([{
                        field: "through",
                        expr: joinThroughValue
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
                        expr: joinThroughValue
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
        try {
            final typed = Context.typeExpr(expr);
            return switch (typed.expr) {
                case TConst(TString(s)): s;
                default: null;
            }
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
