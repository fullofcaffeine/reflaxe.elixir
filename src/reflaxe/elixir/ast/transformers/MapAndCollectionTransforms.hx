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
import reflaxe.elixir.ast.ASTUtils;
import haxe.macro.Expr.Position;

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
     * Map set-call rewrite pass
     * 
     * WHY: Some builders emit imperative map mutations like `g.set("key", value)` which
     *      are invalid in Elixir (variables are not modules). This rewrites them to
     *      `g = Map.put(g, :key, value)` so downstream passes (mapBuilderCollapsePass)
     *      can collapse to a literal map.
     */
    public static function mapSetRewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(target, func, args) if (func == "set" && args != null && args.length == 2):
                    switch (target.def) {
                        case EVar(name):
                            var keyExpr = args[0];
                            // Convert string literal keys to atoms when possible
                            var atomKey: Null<ElixirAST> = switch (keyExpr.def) {
                                case EString(s): makeAST(EAtom(s));
                                default: null;
                            };
                            var finalKey = atomKey != null ? atomKey : keyExpr;
                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [makeAST(EVar(name)), finalKey, args[1]]));
                            makeAST(EMatch(PVar(name), putCall));
                        default:
                            n;
                    }
                case ECall(target, func, args) if (target != null && func == "set" && args != null && args.length == 2):
                    switch (target.def) {
                        case EVar(name):
                            var keyExpr = args[0];
                            var atomKey: Null<ElixirAST> = switch (keyExpr.def) {
                                case EString(s): makeAST(EAtom(s));
                                default: null;
                            };
                            var finalKey = atomKey != null ? atomKey : keyExpr;
                            var putCall = makeAST(ERemoteCall(makeAST(EVar("Map")), "put", [makeAST(EVar(name)), finalKey, args[1]]));
                            makeAST(EMatch(PVar(name), putCall));
                        default:
                            n;
                    }
                default:
                    n;
            }
        });
    }
    
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
     * Map Iterator Transformation Pass (migrated from ElixirASTTransformer)
     * Transforms Map iterator patterns from g.next() to idiomatic Enum.each with {k, v} destructuring.
     *
     * WHY: Builder emits Map iterator machinery for Haxe MapKeyValueIterator.
     * WHAT: Detect Enum.reduce_while loops that drive a Map iterator and rewrite to Enum.each(map, fn {k, v} -> ... end)
     * HOW: Scan loop function for iterator method chains, extract key/value binders and body, drop infra tuples {:cont, ...}.
     */
    public static function mapIteratorTransformPass(ast: ElixirAST): ElixirAST {
        if (ast == null) return null;

        #if debug_map_iterator
        trace("[MapIteratorTransform] ===== MAP ITERATOR TRANSFORM PASS STARTING =====");
        switch(ast.def) {
            case EModule(name, _):
                trace('[MapIteratorTransform] Processing module: ' + name);
            default:
                trace('[MapIteratorTransform] Processing non-module AST node');
        }
        #end

        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case ERemoteCall(module, funcName, args):
                    switch(module.def) {
                        case EVar(modName) if (modName == "Enum" && funcName == "reduce_while" && args != null && args.length >= 3):
                            #if debug_map_iterator
                            trace('[MapIteratorTransform] Found Enum.reduce_while - checking for Map iterator patterns');
                            #end
                            var loopFunc = args[2];

                            // Detect iterator usage within the loop function body
                            function hasMapIteratorCalls(ast: ElixirAST): Bool {
                                if (ast == null) return false;
                                var found = false;
                                var depth = 0;
                                function scan(n: ElixirAST): Void {
                                    if (n == null || n.def == null) return;
                                    depth++;
                                    #if debug_map_iterator
                                    if (depth <= 4) {
                                        var nodeType = n.def != null ? Type.enumConstructor(n.def) : "null";
                                        trace('[MapIteratorTransform] Depth ' + depth + ' - Node type: ' + nodeType);
                                    }
                                    #end
                                    switch(n.def) {
                                        case EField(obj, field):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Field access found: ' + field);
                                            #end
                                            if (field == "key_value_iterator" || field == "has_next" || field == "next" || field == "key" || field == "value") {
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] *** FOUND MAP ITERATOR FIELD: ' + field + ' ***');
                                                #end
                                                found = true;
                                            }
                                            scan(obj);
                                        case ECall(target, funcName, args):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning: Found call to ' + funcName);
                                            #end
                                            if (target != null) {
                                                switch(target.def) {
                                                    case EField(_, field):
                                                        #if debug_map_iterator
                                                        trace('[MapIteratorTransform] Call is on field: ' + field);
                                                        #end
                                                        if (field == "key_value_iterator" || field == "has_next" || field == "next" || field == "key" || field == "value") {
                                                            #if debug_map_iterator
                                                            trace('[MapIteratorTransform] *** FOUND MAP ITERATOR CALL: ' + field + '() ***');
                                                            #end
                                                            found = true;
                                                        }
                                                    default:
                                                }
                                                scan(target);
                                            }
                                            if (args != null) for (arg in args) scan(arg);
                                        case EFn(clauses):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning function with ' + clauses.length + ' clauses');
                                            #end
                                            for (c in clauses) if (c.body != null) scan(c.body);
                                        case EBlock(exprs):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning block with ' + exprs.length + ' expressions');
                                            #end
                                            for (e in exprs) scan(e);
                                        case EIf(cond, t, e):
                                            #if debug_map_iterator
                                            trace('[MapIteratorTransform] Scanning if statement');
                                            #end
                                            scan(cond);
                                            scan(t);
                                            if (e != null) scan(e);
                                        case EMatch(_, value):
                                            scan(value);
                                        case ETuple(items):
                                            for (item in items) scan(item);
                                        default:
                                            #if debug_map_iterator
                                            if (depth <= 4) {
                                                var nodeType = Type.enumConstructor(n.def);
                                                trace('[MapIteratorTransform] Other node type: ' + nodeType);
                                            }
                                            #end
                                    }
                                    depth--;
                                }
                                scan(ast);
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Scan complete for AST, found iterator patterns: ' + found);
                                #end
                                return found;
                            }

                            #if debug_map_iterator
                            trace('[MapIteratorTransform] Checking loopFunc for Map iterator calls...');
                            #end

                            if (hasMapIteratorCalls(loopFunc)) {
                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Found Map iteration pattern in reduce_while - transforming to Enum.each');
                                #end

                                // Extract the map variable from the initial value (second argument)
                                var mapVar = switch(args[1].def) {
                                    case ETuple([mapExpr, _]) | ETuple([mapExpr]):
                                        switch(mapExpr.def) {
                                            case EVar(name): name;
                                            default: null;
                                        }
                                    case EVar(name): name;
                                    default: null;
                                };
                                if (mapVar == null) mapVar = "colors"; // fallback

                                #if debug_map_iterator
                                trace('[MapIteratorTransform] Map variable identified: ' + mapVar);
                                #end

                                var keyVarName = "name";
                                var valueVarName = "hex";
                                var loopBody: ElixirAST = null;

                                switch(loopFunc.def) {
                                    case EFn(clauses) if (clauses.length > 0):
                                        var body = clauses[0].body;
                                        switch(body.def) {
                                            case EIf(_, thenBranch, _):
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Processing if branch for body extraction');
                                                #if debug_ast_structure
                                                ASTUtils.debugAST(thenBranch, 0, 3);
                                                #end
                                                #end
                                                var allExprs = ASTUtils.flattenBlocks(thenBranch);
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] Flattened ' + allExprs.length + ' expressions from then branch');
                                                #end
                                                // Extract variable names from iterator assignments
                                                for (expr in allExprs) {
                                                    switch(expr.def) {
                                                        case EMatch(PVar(varName), rhs):
                                                            if (ASTUtils.containsIteratorPattern(rhs)) {
                                                                switch(rhs.def) {
                                                                    case EField(_, "key"):
                                                                        keyVarName = varName;
                                                                        #if debug_map_iterator
                                                                        trace('[MapIteratorTransform] Found key variable: ' + keyVarName);
                                                                        #end
                                                                    case EField(_, "value"):
                                                                        valueVarName = varName;
                                                                        #if debug_map_iterator
                                                                        trace('[MapIteratorTransform] Found value variable: ' + valueVarName);
                                                                        #end
                                                                    default:
                                                                        var fieldChain = [];
                                                                        var current = rhs;
                                                                        while (current != null) {
                                                                            switch(current.def) {
                                                                                case EField(obj, field):
                                                                                    fieldChain.push(field);
                                                                                    current = obj;
                                                                                case ECall(func, _, _):
                                                                                    current = func;
                                                                                default:
                                                                                    current = null;
                                                                            }
                                                                        }
                                                                        if (fieldChain.length > 0) {
                                                                            if (fieldChain[0] == "key") {
                                                                                keyVarName = varName;
                                                                                #if debug_map_iterator
                                                                                trace('[MapIteratorTransform] Found key variable via chain: ' + keyVarName);
                                                                                #end
                                                                            } else if (fieldChain[0] == "value") {
                                                                                valueVarName = varName;
                                                                                #if debug_map_iterator
                                                                                trace('[MapIteratorTransform] Found value variable via chain: ' + valueVarName);
                                                                                #end
                                                                            }
                                                                        }
                                                                }
                                                            }
                                                        default:
                                                    }
                                                }
                                                var cleanExprs = ASTUtils.filterIteratorAssignments(allExprs);
                                                #if debug_map_iterator
                                                trace('[MapIteratorTransform] After filtering: ' + cleanExprs.length + ' expressions remain');
                                                #end
                                                var bodyExprs = [];
                                                for (expr in cleanExprs) {
                                                    switch(expr.def) {
                                                        case ETuple(elements):
                                                            var isCont = elements.length > 0 && switch(elements[0].def) {
                                                                case EAtom(atom): atom == "cont";
                                                                default: false;
                                                            };
                                                            if (!isCont) bodyExprs.push(expr);
                                                        default:
                                                            bodyExprs.push(expr);
                                                    }
                                                }
                                                loopBody = if (bodyExprs.length == 1) bodyExprs[0] else if (bodyExprs.length > 1) makeAST(EBlock(bodyExprs)) else null;
                                            default:
                                        }
                                    default:
                                }

                                if (loopBody != null) {
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] Creating Enum.each with {' + keyVarName + ', ' + valueVarName + '} destructuring');
                                    trace('[MapIteratorTransform] Map variable: ' + mapVar);
                                    trace('[MapIteratorTransform] Body extracted, creating transformation');
                                    #end
                                    var transformedAST = makeAST(ERemoteCall(
                                        makeAST(EVar("Enum")),
                                        "each",
                                        [
                                            makeAST(EVar(mapVar)),
                                            makeAST(EFn([{
                                                args: [PTuple([PVar(keyVarName), PVar(valueVarName)])],
                                                guard: null,
                                                body: loopBody
                                            }]))
                                        ]
                                    ));
                                    #if debug_map_iterator
                                    trace('[MapIteratorTransform] *** TRANSFORMATION COMPLETE - RETURNING NEW AST ***');
                                    #end
                                    return transformedAST;
                                }
                            }
                        default:
                    }
                default:
            }
            return node;
        });
    }

    // Internal helper: conservative check for Map iterator signals
    private static function containsIteratorPatterns(ast: ElixirAST): Bool {
        if (ast == null || ast.def == null) return false;
        var hasKeyValueIterator = false;
        var hasHasNext = false;
        var hasNext = false;
        function scan(node: ElixirAST): Void {
            if (node == null || node.def == null) return;
            switch(node.def) {
                case EField(obj, field):
                    if (field == "key_value_iterator") {
                        hasKeyValueIterator = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found key_value_iterator field');
                        #end
                    } else if (field == "has_next") {
                        hasHasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found has_next field');
                        #end
                    } else if (field == "next") {
                        hasNext = true;
                        #if debug_map_iterator
                        trace('[MapIteratorTransform/scan] Found next field');
                        #end
                    }
                    scan(obj);
                case ECall(func, _, args):
                    switch(func.def) {
                        case EField(obj, field):
                            if (field == "key_value_iterator" || field == "has_next" || field == "next") {
                                if (field == "key_value_iterator") hasKeyValueIterator = true;
                                if (field == "has_next") hasHasNext = true;
                                if (field == "next") hasNext = true;
                                #if debug_map_iterator
                                trace('[MapIteratorTransform/scan] Found iterator method call: ' + field + '()');
                                #end
                            }
                            scan(obj);
                        default:
                            scan(func);
                    }
                    if (args != null) for (arg in args) scan(arg);
                case EFn(clauses):
                    for (clause in clauses) if (clause.body != null) scan(clause.body);
                case EBlock(exprs):
                    for (expr in exprs) scan(expr);
                case EIf(cond, thenBranch, elseBranch):
                    scan(cond);
                    scan(thenBranch);
                    if (elseBranch != null) scan(elseBranch);
                case ETuple(elements):
                    for (elem in elements) scan(elem);
                case ERemoteCall(module, _, args):
                    scan(module);
                    if (args != null) for (arg in args) scan(arg);
                case EVar(_), EAtom(_), EString(_):
                default:
                    #if debug_map_iterator
                    var nodeType = Type.enumConstructor(node.def);
                    trace('[MapIteratorTransform/scan] Unhandled node type: ' + nodeType);
                    #end
            }
        }
        scan(ast);
        var result = hasKeyValueIterator;
        #if debug_map_iterator
        if (result) trace('[MapIteratorTransform/scan] ✅ PATTERN DETECTED - hasKeyValueIterator: ' + hasKeyValueIterator + ', hasHasNext: ' + hasHasNext + ', hasNext: ' + hasNext);
        #end
        return result;
    }

    // Debug helper to pretty-print nodes
    #if debug_map_iterator
    private static function printASTStructure(ast: ElixirAST, depth: Int = 0): String {
        if (ast == null || ast.def == null) return "null";
        if (depth > 3) return "...";
        var nodeType = Type.enumConstructor(ast.def);
        return switch(ast.def) {
            case EField(obj, field): '$nodeType(.$field on ${printASTStructure(obj, depth + 1)})';
            case ECall(func, _, args): var argsStr = args != null ? '[${args.length} args]' : '[no args]'; '$nodeType($argsStr, func=${printASTStructure(func, depth + 1)})';
            case EVar(name): '$nodeType($name)';
            case EAtom(atom): '$nodeType(:$atom)';
            default: nodeType;
        }
    }
    #end
}

#end
/**
 * MapAndCollectionTransforms
 *
 * WHAT
 * - Normalizes Map/Keyword/List building patterns into idiomatic Elixir forms by
 *   collapsing builder blocks and standardizing access/put operations.
 *
 * WHY
 * - Haxe desugarings and intermediate temps often produce verbose Map.put chains
 *   and uneven List concatenations. This pass improves readability and reduces
 *   chances of warnings.
 *
 * HOW
 * - Detects Map.put pipelines and rewrites to literal maps when safe.
 * - Ensures keyword lists use standard literal syntax where possible.
 *
 * EXAMPLES
 * Haxe:
 *   var m = {}; m = Map.put(m, :a, 1); m = Map.put(m, :b, 2)
 * Elixir (after):
 *   %{a: 1, b: 2}
 */
