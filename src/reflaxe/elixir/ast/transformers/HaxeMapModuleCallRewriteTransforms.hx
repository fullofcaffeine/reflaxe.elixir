package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * HaxeMapModuleCallRewriteTransforms
 *
 * WHAT
 * - Rewrites lowered Haxe stdlib map module calls (`IntMap.*`, `StringMap.*`, `ObjectMap.*`)
 *   to native Elixir `Map.*` operations.
 *
 * WHY
 * - The AST builder lowers Haxe map operations (e.g. `map.exists(k)`) to module calls like
 *   `IntMap.exists(map, k)`. We do not ship `IntMap/StringMap/ObjectMap` runtime modules, so
 *   Elixir compilation emits undefined-module warnings (fatal under `--warnings-as-errors`).
 * - Using the real `Map` module yields more idiomatic Elixir and avoids missing-module warnings.
 *
 * HOW
 * - Pattern-match remote calls targeting `IntMap/StringMap/ObjectMap` and rewrite:
 *   - `exists/2` → `Map.has_key?/2`
 *   - `get/2`    → `Map.get/2`
 *   - `keys/1`   → `Map.keys/1`
 * - For `set/3`, preserve Haxe "mutation" semantics by rebinding when the result is discarded:
 *   - `_ = IntMap.set(map, k, v)` → `map = Map.put(map, k, v)`
 * - Special-case a common lowered field-extraction shape:
 *   - `tmp = state.field; _ = IntMap.set(tmp, k, v)` → `state = %{state | field: Map.put(state.field, k, v)}`
 *
 * EXAMPLES
 * Haxe:
 *   if (state.userCache.exists(id)) state.userCache.set(id, user);
 * Elixir (before):
 *   if (_ = IntMap.exists(state.user_cache, id)) do
 *     _ = IntMap.set(state.user_cache, id, user)
 *   end
 * Elixir (after):
 *   if Map.has_key?(state.user_cache, id) do
 *     state = %{state | user_cache: Map.put(state.user_cache, id, user)}
 *   end
 */
class HaxeMapModuleCallRewriteTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                // Pattern: tmp = state.field; _ = IntMap.set(tmp, k, v)
                // Rewrite to: state = %{state | field: Map.put(state.field, k, v)}
                case EBlock(exprs) if (exprs != null && exprs.length >= 2):
                    var out: Array<ElixirAST> = [];
                    var changed = false;
                    var i = 0;
                    while (i < exprs.length) {
                        var current = exprs[i];
                        var next = (i + 1 < exprs.length) ? exprs[i + 1] : null;

                        var rewritten: Null<ElixirAST> = null;
                        if (next != null) {
                            rewritten = tryRewriteFieldTmpSet(current, next);
                        }
                        if (rewritten != null) {
                            out.push(rewritten);
                            changed = true;
                            i += 2;
                            continue;
                        }

                        out.push(current);
                        i++;
                    }
                    changed ? makeASTWithMeta(EBlock(out), node.metadata, node.pos) : node;

                // Pattern: _ = IntMap.set(map, k, v)  -> map = Map.put(map, k, v)
                case EMatch(PVar("_"), rhs):
                    switch (rhs.def) {
                        case ERemoteCall({def: EVar(modName)}, "set", args) if (isHaxeMapModule(modName) && args != null && args.length == 3):
                            switch (args[0].def) {
                                case EVar(mapVar):
                                    var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                                    makeASTWithMeta(EMatch(PVar(mapVar), putCall), node.metadata, node.pos);
                                case EField({def: EVar(receiverName)}, fieldName):
                                    // Direct field target (rare, but handle it): state.field = Map.put(state.field, k, v)
                                    var receiverVar = makeAST(EVar(receiverName));
                                    var currentField = makeAST(EField(receiverVar, fieldName));
                                    var putCall2 = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [currentField, args[1], args[2]]));
                                    var updated = makeAST(EStructUpdate(receiverVar, [{ key: fieldName, value: putCall2 }]));
                                    makeASTWithMeta(EMatch(PVar(receiverName), updated), node.metadata, node.pos);
                                default:
                                    // Fallback: keep match but rewrite to Map.put to avoid missing-module warnings.
                                    makeASTWithMeta(EMatch(PVar("_"), makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]))), node.metadata, node.pos);
                            }
                        case ECall(target, "set", args) if (target != null && target.def != null):
                            switch (target.def) {
                                case EVar(modName2) if (isHaxeMapModule(modName2) && args != null && args.length == 3):
                                    switch (args[0].def) {
                                        case EVar(mapVar2):
                                            var putCall3 = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                                            makeASTWithMeta(EMatch(PVar(mapVar2), putCall3), node.metadata, node.pos);
                                        default:
                                            makeASTWithMeta(EMatch(PVar("_"), makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]))), node.metadata, node.pos);
                                    }
                                default:
                                    node;
                            }
                        default:
                            node;
                    }

                // Same as above, but some builder paths represent `=` as an EBinary(Match, ...)
                case EBinary(Match, left, right):
                    switch (left.def) {
                        case EVar("_"):
                            switch (right.def) {
                                case ERemoteCall({def: EVar(modName)}, "set", args) if (isHaxeMapModule(modName) && args != null && args.length == 3):
                                    switch (args[0].def) {
                                        case EVar(mapVar):
                                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                                            makeASTWithMeta(EMatch(PVar(mapVar), putCall), node.metadata, node.pos);
                                        default:
                                            // Fallback: rewrite module to Map.put, preserving discard
                                            makeASTWithMeta(EBinary(Match, left, makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]))), node.metadata, node.pos);
                                    }
                                case ECall(target, "set", args) if (target != null):
                                    switch (target.def) {
                                        case EVar(modName2) if (isHaxeMapModule(modName2) && args != null && args.length == 3):
                                            switch (args[0].def) {
                                                case EVar(mapVar2):
                                                    var putCall2 = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                                                    makeASTWithMeta(EMatch(PVar(mapVar2), putCall2), node.metadata, node.pos);
                                                default:
                                                    makeASTWithMeta(EBinary(Match, left, makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]))), node.metadata, node.pos);
                                            }
                                        default:
                                            node;
                                    }
                                default:
                                    node;
                            }
                        default:
                            node;
                    }

                // Rewrite direct set calls to Map.put, rebinding when possible.
                case ERemoteCall({def: EVar(modName)}, "set", args) if (isHaxeMapModule(modName) && args != null && args.length == 3):
                    switch (args[0].def) {
                        case EVar(mapVar):
                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                            makeASTWithMeta(EMatch(PVar(mapVar), putCall), node.metadata, node.pos);
                        default:
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]), node.metadata, node.pos);
                    }
                case ECall(target, "set", args) if (target != null):
                    switch (target.def) {
                        case EVar(modName2) if (isHaxeMapModule(modName2) && args != null && args.length == 3):
                            switch (args[0].def) {
                                case EVar(mapVar2):
                                    var putCall2 = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]));
                                    makeASTWithMeta(EMatch(PVar(mapVar2), putCall2), node.metadata, node.pos);
                                default:
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "put", [args[0], args[1], args[2]]), node.metadata, node.pos);
                            }
                        default:
                            node;
                    }

                // Core rewrites: IntMap.exists/get/keys → Map.*
                case ERemoteCall({def: EVar(modName)}, funcName, args) if (isHaxeMapModule(modName) && args != null):
                    switch (funcName) {
                        case "exists" if (args.length == 2):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "has_key?", args), node.metadata, node.pos);
                        case "get" if (args.length == 2):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", args), node.metadata, node.pos);
                        case "keys" if (args.length == 1):
                            makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "keys", args), node.metadata, node.pos);
                        default:
                            node;
                    }
                case ECall(target, funcName, args) if (target != null && args != null):
                    switch (target.def) {
                        case EVar(modName2) if (isHaxeMapModule(modName2)):
                            switch (funcName) {
                                case "exists" if (args.length == 2):
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "has_key?", args), node.metadata, node.pos);
                                case "get" if (args.length == 2):
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "get", args), node.metadata, node.pos);
                                case "keys" if (args.length == 1):
                                    makeASTWithMeta(ERemoteCall(makeAST(EVar("Map")), "keys", args), node.metadata, node.pos);
                                default:
                                    node;
                            }
                        default:
                            node;
                    }

                default:
                    node;
            }
        });
    }

    static function isHaxeMapModule(modName: String): Bool {
        return modName == "IntMap" || modName == "StringMap" || modName == "ObjectMap";
    }

    static function extractVarAssign(node: ElixirAST): Null<{ name: String, rhs: ElixirAST }> {
        if (node == null || node.def == null) return null;
        return switch (node.def) {
            case EMatch(PVar(name), rhs):
                { name: name, rhs: rhs };
            case EBinary(Match, left, rhs):
                switch (left.def) {
                    case EVar(name2):
                        { name: name2, rhs: rhs };
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function tryRewriteFieldTmpSet(first: ElixirAST, second: ElixirAST): Null<ElixirAST> {
        // first: tmp = state.field
        var tmpName: Null<String> = null;
        var receiverName: Null<String> = null;
        var fieldName: Null<String> = null;

        var firstAssign = extractVarAssign(first);
        if (firstAssign != null) {
            switch (firstAssign.rhs.def) {
                case EField({def: EVar(r)}, f):
                    tmpName = firstAssign.name;
                    receiverName = r;
                    fieldName = f;
                default:
            }
        }

        if (tmpName == null || receiverName == null || fieldName == null) return null;

        // second: _ = IntMap.set(tmp, k, v)
        var secondAssign = extractVarAssign(second);
        if (secondAssign == null || secondAssign.name != "_") return null;
        switch (secondAssign.rhs.def) {
            case ERemoteCall({def: EVar(modName)}, "set", args) if (isHaxeMapModule(modName) && args != null && args.length == 3):
                switch (args[0].def) {
                    case EVar(v) if (v == tmpName):
                        var receiverVar = makeAST(EVar(receiverName));
                        var currentField = makeAST(EField(receiverVar, fieldName));
                        var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [currentField, args[1], args[2]]));
                        var updated = makeAST(EStructUpdate(receiverVar, [{ key: fieldName, value: putCall }]));
                        return makeASTWithMeta(EMatch(PVar(receiverName), updated), second.metadata, second.pos);
                    default:
                }
            case ECall(target, "set", args) if (target != null):
                switch (target.def) {
                    case EVar(modName2) if (isHaxeMapModule(modName2) && args != null && args.length == 3):
                        switch (args[0].def) {
                            case EVar(v2) if (v2 == tmpName):
                                var receiverVar2 = makeAST(EVar(receiverName));
                                var currentField2 = makeAST(EField(receiverVar2, fieldName));
                                var putCall2 = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [currentField2, args[1], args[2]]));
                                var updated2 = makeAST(EStructUpdate(receiverVar2, [{ key: fieldName, value: putCall2 }]));
                                return makeASTWithMeta(EMatch(PVar(receiverName), updated2), second.metadata, second.pos);
                            default:
                        }
                    default:
                }
            default:
        }

        return null;
    }
}

#end
