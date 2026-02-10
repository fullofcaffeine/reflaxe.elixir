package reflaxe.elixir.macros;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.ast.NameUtils;

using StringTools;

private enum abstract AssocKind(String) to String {
    var BelongsTo = "belongs_to";
    var HasMany = "has_many";
    var HasOne = "has_one";
    var ManyToMany = "many_to_many";
}

private typedef TypeIndex = {
    var classesByFqcn: Map<String, ClassType>;
    var classesByName: Map<String, Array<ClassType>>;
    var schemas: Array<ClassType>;
};

private typedef AssocArgs = {
    var assocName: String;
    var targetHint: Null<String>;
    var foreignKeyOverride: Null<String>;
};

/**
 * EctoSchemaAssociationValidator
 *
 * WHAT
 * - Validates Ecto schema association shapes at compile time for Haxe `@:schema` modules:
 *   - `@:belongs_to`: require a local `<assoc>_id` FK field (or an explicit override).
 *   - `@:has_many` / `@:has_one`: when the target schema is resolvable, require the expected FK field
 *     exists on the target schema (default: `<source>_id`, or an explicit override).
 *
 * WHY
 * - Ecto association declarations are easy to mis-specify (missing FK field, wrong FK name, wrong target).
 * - We can catch most "wrong relationship shape" bugs at compile time using macro-time type information,
 *   without needing a live database.
 *
 * HOW
 * - Register a single `Context.onAfterTyping` hook (once per compilation).
 * - Build an index of typed classes so string hints like `"Post"` can be resolved when possible.
 * - For each `@:schema` class, scan instance var fields for association metadata and validate:
 *   - FK fields by snake_case name equivalence (`user_id` and `userId` are treated the same).
 *
 * CONFIG
 * - Default: errors on missing FK fields.
 * - `-D ecto_assoc_warn_only`: downgrade errors to warnings.
 * - `-D ecto_no_assoc_validation` or `@:ecto_no_assoc_validation`: disable validation.
 */
class EctoSchemaAssociationValidator {
    static var afterTypingRegistered: Bool = false;

    public static function ensureAfterTypingHook(): Void {
        if (afterTypingRegistered) return;
        if (Context.defined("ecto_no_assoc_validation")) return;
        afterTypingRegistered = true;

        Context.onAfterTyping(validateAllTypedModules);
    }

    static function validateAllTypedModules(modules: Array<ModuleType>): Void {
        if (Context.defined("ecto_no_assoc_validation")) return;

        var index = buildTypeIndex(modules);
        if (index.schemas.length == 0) return;

        var warnOnly = Context.defined("ecto_assoc_warn_only");
        for (schema in index.schemas) {
            if (!schemaValidationEnabled(schema)) continue;
            validateSchema(schema, index, warnOnly);
        }
    }

    static function buildTypeIndex(modules: Array<ModuleType>): TypeIndex {
        var classesByFqcn: Map<String, ClassType> = new Map();
        var classesByName: Map<String, Array<ClassType>> = new Map();
        var schemas: Array<ClassType> = [];

        for (m in modules) {
            switch (m) {
                case TClassDecl(clsRef):
                    var cls = clsRef.get();
                    if (cls == null || cls.meta == null) continue;

                    var fqcn = classFqcn(cls);
                    classesByFqcn.set(fqcn, cls);

                    var bucket = classesByName.get(cls.name);
                    if (bucket == null) {
                        bucket = [];
                        classesByName.set(cls.name, bucket);
                    }
                    bucket.push(cls);

                    if (cls.meta.has(":schema")) schemas.push(cls);
                default:
            }
        }

        return {
            classesByFqcn: classesByFqcn,
            classesByName: classesByName,
            schemas: schemas
        };
    }

    static function schemaValidationEnabled(schema: ClassType): Bool {
        if (schema == null || schema.meta == null) return false;
        if (schema.meta.has(":ecto_no_assoc_validation") || schema.meta.has("ecto_no_assoc_validation")) return false;
        return true;
    }

    static function validateSchema(schema: ClassType, index: TypeIndex, warnOnly: Bool): Void {
        var schemaFieldSnakes = collectInstanceVarSnakeNames(schema);

        for (field in schema.fields.get()) {
            if (field == null || field.meta == null) continue;

            var assocKind = detectAssociationKind(field);
            if (assocKind == null) continue;

            var metaName = ":" + Std.string(assocKind);
            var metaEntries = field.meta.extract(metaName);
            if (metaEntries == null || metaEntries.length == 0) continue;

            var entry = metaEntries[0];
            var args = parseAssocArgs(field, entry);

            switch (assocKind) {
                case BelongsTo:
                    validateBelongsTo(schema, field, args, schemaFieldSnakes, warnOnly, entry.pos);
                case HasMany, HasOne:
                    validateHasSide(schema, field, assocKind, args, index, warnOnly, entry.pos);
                case ManyToMany:
                    // many_to_many foreign keys are mediated by join tables; no compile-time FK validation.
            }
        }
    }

    static function detectAssociationKind(field: ClassField): Null<AssocKind> {
        if (field == null || field.meta == null) return null;
        if (field.meta.has(":belongs_to")) return BelongsTo;
        if (field.meta.has(":has_many")) return HasMany;
        if (field.meta.has(":has_one")) return HasOne;
        if (field.meta.has(":many_to_many")) return ManyToMany;
        return null;
    }

    static function parseAssocArgs(field: ClassField, entry: MetadataEntry): AssocArgs {
        var assocName = field.name;
        var targetHint: Null<String> = null;
        var foreignKeyOverride: Null<String> = null;

        var params = entry != null ? entry.params : null;
        if (params != null) {
            if (params.length >= 1) {
                switch (params[0].expr) {
                    case EConst(CString(name, _)):
                        assocName = name;
                    default:
                }
            }

            if (params.length >= 2) {
                switch (params[1].expr) {
                    case EConst(CString(name, _)):
                        targetHint = name;
                    default:
                }
            }

            if (params.length >= 3) {
                switch (params[2].expr) {
                    case EConst(CString(name, _)):
                        foreignKeyOverride = name;
                    default:
                }
            }

            // Support object-literal options like `{foreign_key: "user_id"}`.
            for (i in 1...params.length) {
                switch (params[i].expr) {
                    case EObjectDecl(fields):
                        for (f in fields) {
                            if (f == null) continue;
                            if (f.field != "foreign_key" && f.field != "foreignKey") continue;
                            switch (f.expr.expr) {
                                case EConst(CString(v, _)):
                                    foreignKeyOverride = v;
                                default:
                            }
                        }
                    default:
                }
            }
        }

        return {
            assocName: assocName,
            targetHint: targetHint,
            foreignKeyOverride: foreignKeyOverride
        };
    }

    static function validateBelongsTo(schema: ClassType, field: ClassField, args: AssocArgs, schemaFieldSnakes: Map<String, Bool>, warnOnly: Bool, pos: Position): Void {
        var expectedFk = args.foreignKeyOverride != null
            ? args.foreignKeyOverride
            : (args.assocName + "_id");
        var expectedFkSnake = NameUtils.toSnakeCase(expectedFk);

        if (!schemaFieldSnakes.exists(expectedFkSnake)) {
            reportProblem(
                warnOnly,
                'Ecto association validation: ${schema.name}.${field.name} is `@:belongs_to("${args.assocName}")` but the schema is missing a foreign key field named `${expectedFkSnake}` (accepts `...Id` as well).',
                pos
            );
        }
    }

    static function validateHasSide(schema: ClassType, field: ClassField, kind: AssocKind, args: AssocArgs, index: TypeIndex, warnOnly: Bool, pos: Position): Void {
        var expectedFkOnTarget = args.foreignKeyOverride != null
            ? args.foreignKeyOverride
            : (NameUtils.toSnakeCase(schema.name) + "_id");
        var expectedFkOnTargetSnake = NameUtils.toSnakeCase(expectedFkOnTarget);

        var target = resolveAssociationTarget(schema, field, kind, args, index, pos);
        if (target == null) return;

        if (target.meta == null || !target.meta.has(":schema")) {
            Context.warning(
                'Ecto association validation: ${schema.name}.${field.name} targets `${target.name}` but that type is not annotated with `@:schema`; skipping cross-schema foreign key validation.',
                pos
            );
            return;
        }

        var targetFieldSnakes = collectInstanceVarSnakeNames(target);
        if (!targetFieldSnakes.exists(expectedFkOnTargetSnake)) {
            reportProblem(
                warnOnly,
                'Ecto association validation: ${schema.name}.${field.name} is `@:${Std.string(kind)}("${args.assocName}")` but target schema `${target.name}` is missing expected foreign key field `${expectedFkOnTargetSnake}` (accepts `...Id` as well).',
                pos
            );
        }
    }

    static function resolveAssociationTarget(schema: ClassType, field: ClassField, kind: AssocKind, args: AssocArgs, index: TypeIndex, pos: Position): Null<ClassType> {
        var targetFromType = resolveAssociationTargetFromFieldType(kind, field.type);
        if (targetFromType != null) return targetFromType;

        if (args.targetHint != null) {
            var resolved = resolveClassByHint(args.targetHint, index, pos);
            if (resolved != null) return resolved;
            Context.warning(
                'Ecto association validation: ${schema.name}.${field.name} references target `${args.targetHint}` but it could not be resolved to a Haxe type in this compilation; skipping cross-schema foreign key validation.',
                pos
            );
            return null;
        }

        Context.warning(
            'Ecto association validation: ${schema.name}.${field.name} uses a dynamic/unresolvable target type; skipping cross-schema foreign key validation.',
            pos
        );
        return null;
    }

    static function resolveClassByHint(hint: String, index: TypeIndex, pos: Position): Null<ClassType> {
        if (hint == null || hint.length == 0) return null;

        if (hint.indexOf(".") >= 0) {
            return index.classesByFqcn.get(hint);
        }

        var bucket = index.classesByName.get(hint);
        if (bucket == null || bucket.length == 0) return null;
        if (bucket.length == 1) return bucket[0];

        var candidates: Array<String> = [];
        for (cls in bucket) {
            candidates.push(classFqcn(cls));
        }
        candidates.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));

        Context.warning(
            'Ecto association validation: type name `${hint}` is ambiguous; candidates: ${candidates.join(", ")}. Skipping cross-schema validation.',
            pos
        );
        return null;
    }

    static function resolveAssociationTargetFromFieldType(kind: AssocKind, t: Type): Null<ClassType> {
        var unwrapped = unwrapNullType(t);
        return switch (kind) {
            case HasMany, ManyToMany:
                switch (unwrapped) {
                    case TInst(clsRef, params):
                        var cls = clsRef.get();
                        if (cls != null && cls.name == "Array" && params != null && params.length == 1) {
                            var elem = unwrapNullType(params[0]);
                            switch (elem) {
                                case TInst(elemRef, _):
                                    elemRef.get();
                                default:
                                    null;
                            }
                        } else {
                            null;
                        }
                    default:
                        null;
                }
            case BelongsTo, HasOne:
                switch (unwrapped) {
                    case TInst(clsRef, _):
                        clsRef.get();
                    default:
                        null;
                }
        };
    }

    static function unwrapNullType(t: Type): Type {
        return switch (t) {
            case TAbstract(absRef, params):
                var abs = absRef.get();
                if (abs != null && abs.name == "Null" && params != null && params.length == 1) {
                    unwrapNullType(params[0]);
                } else {
                    t;
                }
            case TType(typeRef, params):
                var td = typeRef.get();
                if (td != null && td.name == "Null" && params != null && params.length == 1) {
                    unwrapNullType(params[0]);
                } else {
                    t;
                }
            default:
                t;
        };
    }

    static function collectInstanceVarSnakeNames(classType: ClassType): Map<String, Bool> {
        var snakes: Map<String, Bool> = new Map();
        if (classType == null) return snakes;

        for (field in classType.fields.get()) {
            if (field == null) continue;
            switch (field.kind) {
                case FVar(_, _):
                    var snake = NameUtils.toSnakeCase(field.name);
                    snakes.set(snake, true);
                default:
            }
        }

        return snakes;
    }

    static function reportProblem(warnOnly: Bool, message: String, pos: Position): Void {
        if (warnOnly) {
            Context.warning(message, pos);
        } else {
            Context.error(message, pos);
        }
    }

    static function classFqcn(cls: ClassType): String {
        if (cls == null) return "";
        return cls.pack != null && cls.pack.length > 0
            ? cls.pack.join(".") + "." + cls.name
            : cls.name;
    }
}

#end

