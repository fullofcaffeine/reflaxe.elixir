package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
import reflaxe.elixir.ast.ElixirASTTransformer;

using StringTools;

/**
 * InstanceFieldLoweringTransforms
 *
 * WHAT
 * - Lowers class instance-field locals (e.g., `columns = columns ++ [...]`) into
 *   struct/map updates on the conventional receiver binder (`struct`).
 *
 * WHY
 * - The AST builder commonly lowers instance-field reads/writes as plain locals named after the field.
 *   In Elixir, this produces undefined-variable errors (`columns` never bound) and breaks semantics
 *   because instance state must live on the receiver struct/map.
 *
 * HOW
 * - Reads `instanceFields` from module metadata (provided by ElixirCompiler) as the authoritative
 *   set of snake_case instance field names for the module being compiled.
 * - For functions that have a `struct`/`_struct` receiver parameter (or constructors `new/*` which
 *   use a local `struct` binder), rewrites:
 *   - `field = <expr>` into `struct = %{struct | field: <expr'>}`
 *   - Any `field` variable reads in expression position into `struct.field`
 * - Excludes function parameters from rewriting to avoid param/field collisions (params are expected
 *   to be disambiguated as `*_param` when needed).
 *
 * EXAMPLES
 * Haxe:
 *   class Builder {
 *     var columns:Array<Int>;
 *     public function add(x:Int) {
 *       columns.push(x);
 *       return this;
 *     }
 *   }
 * Elixir (before):
 *   def add(struct, x) do
 *     columns = columns ++ [x]
 *     struct
 *   end
 * Elixir (after):
 *   def add(struct, x) do
 *     struct = %{struct | columns: struct.columns ++ [x]}
 *     struct
 *   end
 */
@:nullSafety(Off)
class InstanceFieldLoweringTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attributes, body):
                    var instanceFieldSet = buildInstanceFieldSet(node.metadata);
                    if (instanceFieldSet == null) {
                        node;
                    } else {
                        var changed = false;
                        var newBody: Array<ElixirAST> = [];
                        for (child in body) {
                            var rewritten = rewriteModuleChild(child, instanceFieldSet);
                            if (rewritten != child) changed = true;
                            newBody.push(rewritten);
                        }
                        changed
                            ? makeASTWithMeta(EModule(name, attributes, newBody), node.metadata, node.pos)
                            : node;
                    }
                default:
                    node;
            }
        });
    }

    static function buildInstanceFieldSet(meta: ElixirMetadata): Null<Map<String, Bool>> {
        if (meta == null || meta.instanceFields == null || meta.instanceFields.length == 0) return null;
        var set: Map<String, Bool> = new Map();
        for (f in meta.instanceFields) set.set(f, true);
        return set;
    }

    static function rewriteModuleChild(node: ElixirAST, instanceFieldSet: Map<String, Bool>): ElixirAST {
        if (node == null) return node;
        return switch (node.def) {
            case EDef(name, args, guards, body):
                rewriteFunction(makeASTWithMeta(EDef(name, args, guards, body), node.metadata, node.pos), instanceFieldSet);
            case EDefp(name, args, guards, body):
                rewriteFunction(makeASTWithMeta(EDefp(name, args, guards, body), node.metadata, node.pos), instanceFieldSet);
            case EDefmacro(name, args, guards, body):
                rewriteFunction(makeASTWithMeta(EDefmacro(name, args, guards, body), node.metadata, node.pos), instanceFieldSet);
            case EDefmacrop(name, args, guards, body):
                rewriteFunction(makeASTWithMeta(EDefmacrop(name, args, guards, body), node.metadata, node.pos), instanceFieldSet);
            default:
                node;
        }
    }

    static function rewriteFunction(fnNode: ElixirAST, instanceFieldSet: Map<String, Bool>): ElixirAST {
        return switch (fnNode.def) {
            case EDef(name, args, guards, body):
                rewriteFunctionLike(fnNode, name, args, guards, body, instanceFieldSet);
            case EDefp(name, args, guards, body):
                rewriteFunctionLike(fnNode, name, args, guards, body, instanceFieldSet);
            case EDefmacro(name, args, guards, body):
                rewriteFunctionLike(fnNode, name, args, guards, body, instanceFieldSet);
            case EDefmacrop(name, args, guards, body):
                rewriteFunctionLike(fnNode, name, args, guards, body, instanceFieldSet);
            default:
                fnNode;
        }
    }

    static function rewriteFunctionLike(
        original: ElixirAST,
        name: String,
        args: Array<EPattern>,
        guards: Null<ElixirAST>,
        body: ElixirAST,
        instanceFieldSet: Map<String, Bool>
    ): ElixirAST {
        var paramNames = collectParamNames(args);

        // Only rewrite when the receiver binder exists in scope. For constructors `new/*`,
        // we assume a local `struct` binder exists (injected by ElixirCompiler).
        var receiverBinder = findStructBinder(args);
        if (receiverBinder == null && name != "new") return original;
        var structName = receiverBinder != null ? receiverBinder : "struct";

        var structVar = makeAST(EVar(structName));

        function resolveFieldKey(varName: String): Null<String> {
            if (varName == null || varName == "" || varName == structName) return null;
            if (instanceFieldSet.exists(varName)) return varName;
            if (varName.startsWith("_")) {
                var stripped = varName.substr(1);
                if (instanceFieldSet.exists(stripped)) return stripped;
            }
            return null;
        }

        function isParam(name: String, fieldKey: String): Bool {
            return (name != null && paramNames.exists(name)) || (fieldKey != null && paramNames.exists(fieldKey));
        }

        var newBody = ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(varName):
                    var fieldKey = resolveFieldKey(varName);
                    if (fieldKey != null && !isParam(varName, fieldKey)) {
                        makeASTWithMeta(EField(structVar, fieldKey), n.metadata, n.pos);
                    } else {
                        n;
                    }

                case EMatch(PVar(varName), rhs):
                    var fieldKey = resolveFieldKey(varName);
                    if (fieldKey != null && !isParam(varName, fieldKey)) {
                        // RHS already had children transformed (including field reads), so we can use it directly.
                        var updatedStruct = makeAST(EStructUpdate(structVar, [{ key: fieldKey, value: rhs }]));
                        makeASTWithMeta(EMatch(PVar(structName), updatedStruct), n.metadata, n.pos);
                    } else {
                        n;
                    }

                default:
                    n;
            }
        });

        if (newBody == body) return original;

        return switch (original.def) {
            case EDef(_, _, _, _):
                makeASTWithMeta(EDef(name, args, guards, newBody), original.metadata, original.pos);
            case EDefp(_, _, _, _):
                makeASTWithMeta(EDefp(name, args, guards, newBody), original.metadata, original.pos);
            case EDefmacro(_, _, _, _):
                makeASTWithMeta(EDefmacro(name, args, guards, newBody), original.metadata, original.pos);
            case EDefmacrop(_, _, _, _):
                makeASTWithMeta(EDefmacrop(name, args, guards, newBody), original.metadata, original.pos);
            default:
                original;
        }
    }

    static function findStructBinder(args: Array<EPattern>): Null<String> {
        if (args == null || args.length == 0) return null;
        // Receiver binder is conventionally the first argument.
        return switch (args[0]) {
            case PVar("struct"): "struct";
            case PVar("_struct"): "_struct";
            default: null;
        };
    }

    static function collectParamNames(args: Array<EPattern>): Map<String, Bool> {
        var out: Map<String, Bool> = new Map();
        if (args == null) return out;
        for (p in args) collectPatternVars(p, out);
        return out;
    }

    static function collectPatternVars(p: EPattern, out: Map<String, Bool>): Void {
        if (p == null) return;
        switch (p) {
            case PVar(name):
                if (name != null && name != "" && name != "_") out.set(name, true);
            case PLiteral(_):
            case PTuple(items):
                if (items != null) for (i in items) collectPatternVars(i, out);
            case PList(items):
                if (items != null) for (i in items) collectPatternVars(i, out);
            case PCons(head, tail):
                collectPatternVars(head, out);
                collectPatternVars(tail, out);
            case PMap(pairs):
                if (pairs != null) for (pair in pairs) collectPatternVars(pair.value, out);
            case PStruct(_, fields):
                if (fields != null) for (f in fields) collectPatternVars(f.value, out);
            case PPin(inner):
                collectPatternVars(inner, out);
            case PWildcard:
            case PAlias(varName, inner):
                if (varName != null && varName != "" && varName != "_") out.set(varName, true);
                collectPatternVars(inner, out);
            case PBinary(segments):
                if (segments != null) for (seg in segments) collectPatternVars(seg.pattern, out);
        }
    }
}

#end
