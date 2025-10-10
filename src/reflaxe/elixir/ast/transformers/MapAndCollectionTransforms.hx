package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.ElixirMetadata;
import reflaxe.elixir.ast.ElixirAST.EMapPair;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTBuilder;
import haxe.macro.Expr.Position;
import Type;

/**
 * MapAndCollectionTransforms: AST transformation passes for maps and collections
 * 
 * WHY: Map and collection operations in Haxe may generate verbose imperative patterns
 *      that should be transformed into idiomatic Elixir functional patterns.
 * 
 * WHAT: Contains transformation passes that optimize map and collection operations:
 *       - Map builder collapse: Convert Map.put sequences to literal maps
 *       - List effect lifting: Extract side-effects from list literals
 * 
 * HOW: Each pass analyzes patterns involving maps and collections and transforms
 *      them into more idiomatic Elixir equivalents.
 * 
 * ARCHITECTURE BENEFITS:
 * - Separation of Concerns: Collection logic isolated from main transformer
 * - Single Responsibility: Each pass handles one collection pattern
 * - Idiomatic Output: Generates functional Elixir patterns
 * - Performance: Eliminates unnecessary intermediate variables
 */
class MapAndCollectionTransforms {
    
    /**
     * Map builder collapse pass
     * 
     * WHY: Sequential Map.put calls create verbose imperative code
     * WHAT: Collapses Map.put builder patterns into literal map syntax
     * HOW: Detects temp map variable with sequential puts and converts to literal
     * 
     * PATTERN:
     * Before:
     *   temp = %{}
     *   temp = Map.put(temp, :key1, value1)
     *   temp = Map.put(temp, :key2, value2)
     *   temp
     * 
     * After:
     *   %{key1: value1, key2: value2}
     */
    public static function mapBuilderCollapsePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EBlock(statements):
                    var collapsed = tryCollapseMapBuilder(statements, node.metadata, node.pos);
                    if (collapsed != null) {
                        return collapsed;
                    }
                    return node;
                default:
                    return node;
            }
        });
    }

    
    private static function tryCollapseMapBuilder(statements: Array<ElixirAST>, metadata: ElixirMetadata, pos: Position): Null<ElixirAST> {
        if (statements == null || statements.length < 2) {
            return null;
        }

        var tempName: String = null;
        var pairs: Array<EMapPair> = null;

        switch(statements[0].def) {
            case EMatch(pattern, initExpr):
                switch pattern {
                    case PVar(name):
                        tempName = name;
#if debug_map_literal
                        trace('[MapCollapse] temp var=' + tempName);
#end
                    default:
                        return null;
                }

                switch(initExpr.def) {
                    case EMap(initialPairs):
                        pairs = initialPairs.copy();
#if debug_map_literal
                        trace('[MapCollapse] initial pairs count=' + pairs.length);
#end
                    default:
                        return null;
                }
            default:
                return null;
        }

        if (tempName == null) {
            return null;
        }

        for (i in 1...statements.length - 1) {
            var stmt = statements[i];
            switch(stmt.def) {
                case EBinary(Match, leftExpr, rightExpr):
                    switch(leftExpr.def) {
                        case EVar(varName) if (varName == tempName):
#if debug_map_literal
                            trace('[MapCollapse] assignment to ' + varName);
#end
                        default:
                            return null;
                    }

                    switch(rightExpr.def) {
                        case ERemoteCall(moduleExpr, funcName, args) if (funcName == "put" && args.length == 3):
#if debug_map_literal
                            trace('[MapCollapse] Map.put detected');
#end
                            switch(moduleExpr.def) {
                                case EVar(moduleName) if (moduleName == "Map"):
                                default:
                                    return null;
                            }

                            switch(args[0].def) {
                                case EVar(varName) if (varName == tempName):
                                default:
                                    return null;
                            }

                            pairs.push({key: args[1], value: args[2]});
#if debug_map_literal
                            trace('[MapCollapse] appended pair #' + pairs.length);
#end
                        default:
                            return null;
                    }
                default:
                    return null;
            }
        }

        switch(statements[statements.length - 1].def) {
            case EVar(varName) if (varName == tempName):
#if debug_map_literal
                trace('[MapCollapse] success - collapsing to literal');
#end
                return makeASTWithMeta(EMap(pairs), metadata, pos);
            default:
                return null;
        }
    }
    
    /**
     * List effect lifting pass
     * 
     * WHY: Side-effecting expressions in list literals can cause evaluation order issues
     * WHAT: Lifts side-effects out of list literals into temporary variables
     * HOW: Detects complex expressions in lists and extracts them to temp vars
     * 
     * PATTERN:
     * Before: [compute(), other.method(), value]
     * After:
     *   tmp1 = compute()
     *   tmp2 = other.method()
     *   [tmp1, tmp2, value]
     */
    public static function listEffectLiftingPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            switch(node.def) {
                case EList(items):
                    var needsLifting = false;
                    for (item in items) {
                        if (hasComplexExpression(item)) {
                            needsLifting = true;
                            break;
                        }
                    }
                    
                    if (needsLifting) {
                        var statements: Array<ElixirAST> = [];
                        var newItems: Array<ElixirAST> = [];
                        var tempCounter = 0;
                        
                        for (item in items) {
                            if (hasComplexExpression(item)) {
                                var tempVar = "tmp_list_" + tempCounter++;
                                statements.push(makeAST(EMatch(PVar(tempVar), item)));
                                newItems.push(makeAST(EVar(tempVar)));
                            } else {
                                newItems.push(item);
                            }
                        }
                        
                        statements.push(makeAST(EList(newItems)));
                        return makeAST(EBlock(statements));
                    }
                    
                    return node;
                default:
                    return node;
            }
        });
    }

    // (Old wrapper removed in favor of migrated implementation below)
    
    private static function hasComplexExpression(ast: ElixirAST): Bool {
        return switch(ast.def) {
            case ECall(_, _, _): true;
            case ERemoteCall(_, _, _): true;
            case EBinary(_, _, _): true;
            case EUnary(_, _): true;
            case ECase(_, _): true;
            case EIf(_, _, _): true;
            case ECond(_): true;
            case EBlock(_): true;
            default: false;
        };
    }

    /**
     * Map Iterator Transformation Pass
     *
     * WHAT: Transforms Map iterator patterns (key_value_iterator/has_next/next) that appear
     *       in reduce_while loop functions into idiomatic Enum.each over map entries with
     *       destructured {key, value} tuples.
     * WHY: Haxe's Map iteration infra leaks target-agnostic iterator calls that look imperative.
     *      Elixir prefers high-level Enum iteration with tuple destructuring, which is clearer
     *      and aligns with idiomatic style.
     * HOW: Scans for Enum.reduce_while with a loop function that contains iterator method calls.
     *      When detected, extracts the map variable and reconstructs an Enum.each(map, fn {k,v} -> ... end)
     *      using the loop body (then branch) content with iterator plumbing stripped. Non-matching
     *      nodes are returned unchanged.
     * CONTEXT: Runs after loop/unrolled transforms and before late cleanups. Designed to be
     *          independent and structural — no app-specific names.
     */
    public static function mapIteratorTransformPass(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;

        #if debug_map_iterator
        trace("[MapIteratorTransform] ===== MAP ITERATOR TRANSFORM PASS STARTING =====");
        switch(ast.def) {
            case EModule(name, _):
                trace('[MapIteratorTransform] Processing module: $name');
                if (name == "Main") trace('[MapIteratorTransform] *** MAIN MODULE DETECTED - LOOKING FOR MAP PATTERNS ***');
            default:
                trace('[MapIteratorTransform] Processing non-module AST node');
        }
        #end

        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    #if debug_map_iterator
                    switch(module.def) {
                        case EVar(modName): trace('[MapIteratorTransform] Found remote call: $modName.$funcName with ${args.length} args');
                        default:
                    }
                    #end
                    switch(module.def) {
                        case EVar(modName):
                            #if debug_map_iterator
                            if (modName == "Enum") trace('[MapIteratorTransform] Found Enum.$funcName call with ${args?.length} args');
                            #end
                            if (modName == "Enum" && funcName == "reduce_while" && args != null && args.length >= 3) {
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Found Enum.reduce_while - checking for Map iterator patterns');
                                #end
                                var loopFunc = args[2];

                                function containsIteratorPattern(n: ElixirAST): Bool {
                                    if (n == null) return false;
                                    var hasPattern = false;
                                    function check(x: ElixirAST): Void {
                                        if (x == null || x.def == null) return;
                                        switch(x.def) {
                                            case EField(obj, field):
                                                if (field == "key_value_iterator" || field == "has_next" || field == "next" || field == "key" || field == "value") {
                                                    hasPattern = true;
                                                }
                                                check(obj);
                                            case ECall(func, _, argz):
                                                // Check func and args
                                                switch(func.def) {
                                                    case EField(obj, field):
                                                        if (field == "key_value_iterator" || field == "has_next" || field == "next") hasPattern = true;
                                                        check(obj);
                                                    default:
                                                        check(func);
                                                }
                                                if (argz != null) for (a in argz) check(a);
                                            default:
                                                // Recurse typical containers
                                                switch(x.def) {
                                                    case EFn(clauses): for (c in clauses) if (c.body != null) check(c.body);
                                                    case EBlock(exprs): for (e in exprs) check(e);
                                                    case EIf(c,t,e): check(c); check(t); if (e != null) check(e);
                                                    case ETuple(els): for (el in els) check(el);
                                                    case ERemoteCall(m,_,argx): check(m); if (argx != null) for (a in argx) check(a);
                                                    default:
                                                }
                                        }
                                    }
                                    check(n);
                                    return hasPattern;
                                }

                                if (containsIteratorPattern(loopFunc)) {
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Found Map iteration pattern in reduce_while - transforming to Enum.each');
                                    #end

                                    // Extract map var and body from loop function
                                    var mapVar: String = null;
                                    var bodyExprs: Array<ElixirAST> = null;

                                    function identifyMapVar(n: ElixirAST): Void {
                                        if (n == null || n.def == null) return;
                                        switch(n.def) {
                                            case EField(obj, field) if (field == "key_value_iterator"):
                                                switch(obj.def) {
                                                    case EVar(name): mapVar = name;
                                                    default:
                                                }
                                            default:
                                                ElixirASTTransformer.iterateAST(n, identifyMapVar);
                                        }
                                    }
                                    identifyMapVar(loopFunc);
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Map variable identified: ' + mapVar);
                                    #end

                                    function flattenThenBranch(expr: ElixirAST): Array<ElixirAST> {
                                        return switch(expr.def) {
                                            case EBlock(all): all;
                                            default: [expr];
                                        };
                                    }

                                    var keyVarName: String = "key";
                                    var valueVarName: String = "value";

                                    // Extract body from loop function clauses (assume single-clause fn)
                                    switch(loopFunc.def) {
                                        case EFn(clauses):
                                            if (clauses.length > 0) {
                                                var clause = clauses[0];
                                                // Heuristic: look for if with body performing work; otherwise use clause.body
                                                switch(clause.body.def) {
                                                    case EIf(_, thenBranch, _):
                                                        var allExprs = flattenThenBranch(thenBranch);
                                                        var cleanExprs = [];
                                                        for (e in allExprs) switch(e.def) {
                                                            case EMatch(PVar(name), {def: EField(_, field)}) if (field == "key" || field == "value"):
                                                                if (field == "key") keyVarName = name; else valueVarName = name;
                                                            default: cleanExprs.push(e);
                                                        }
                                                        bodyExprs = cleanExprs;
                                                    default:
                                                        bodyExprs = flattenThenBranch(clause.body);
                                                }
                                            }
                                        default:
                                    }

                                    // Build: Enum.each(mapVar, fn {keyVarName, valueVarName} -> <bodyExprs> end)
                                    var destruct = makeAST(ETuple([makeAST(EVar(keyVarName)), makeAST(EVar(valueVarName))]));
                                    var fnClause = {
                                        args: [PVarTuple([PVar(keyVarName), PVar(valueVarName)])],
                                        guard: null,
                                        body: bodyExprs != null ? (bodyExprs.length == 1 ? bodyExprs[0] : makeAST(EBlock(bodyExprs))) : makeAST(ENil)
                                    };
                                    var fnExpr = makeAST(EFn([fnClause]));
                                    var enumEach = makeAST(ERemoteCall(makeAST(EVar("Enum")), "each", [makeAST(EVar(mapVar)), fnExpr]));
                                    return enumEach;
                                }
                            }
                        default:
                    }
                default:
            }

            return node;
        });
    }
}

#end
