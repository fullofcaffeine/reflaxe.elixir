package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.naming.ElixirAtom;
import Type;

/**
 * LOOP TRANSFORMATION MODULE
 * 
 * WHY: Haxe's optimizer unrolls small constant loops before they reach our LoopBuilder,
 * resulting in sequential statements instead of proper loops. Also handles other loop
 * patterns that need transformation to idiomatic Elixir.
 * 
 * WHAT: Provides transformation passes for various loop patterns:
 * - Unrolled loops (sequential statements) → Enum.each
 * - While loops with empty bodies → Recursive functions
 * - String iteration patterns → String.to_charlist + Enum operations
 * 
 * HOW: Each pass detects specific patterns and transforms them to idiomatic Elixir
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: All loop transformations in one place
 * - Open/Closed: Easy to add new loop patterns without modifying core transformer
 * - Testability: Each transformation can be tested independently
 * - Maintainability: Clear separation from other transformation concerns
 * 
 * EDGE CASES:
 * - Preserves non-loop sequential statements
 * - Handles partial patterns gracefully
 * - Maintains correct variable scoping
 */
class LoopTransforms {
    
    /**
     * Helper function to manually transform children of an AST node
     * without using ElixirASTTransformer.transformNode to avoid infinite recursion
     */
    static function transformChildrenManually(node: ElixirAST, transformer: ElixirAST -> ElixirAST): ElixirAST {
        // Handle the most common node types that might contain unrolled loops
        switch(node.def) {
            case EIf(cond, thenBranch, elseBranch):
                return makeAST(EIf(
                    transformer(cond),
                    transformer(thenBranch),
                    elseBranch != null ? transformer(elseBranch) : null
                ));
                
            case ECase(expr, clauses):
                return makeAST(ECase(
                    transformer(expr),
                    clauses.map(c -> {
                        pattern: c.pattern,
                        guard: c.guard != null ? transformer(c.guard) : null,
                        body: transformer(c.body)
                    })
                ));
                
            case ECall(target, funcName, args):
                return makeAST(ECall(
                    target != null ? transformer(target) : null,
                    funcName,
                    args.map(a -> transformer(a))
                ));
                
            case ERemoteCall(module, funcName, args):
                return makeAST(ERemoteCall(
                    transformer(module),
                    funcName,
                    args.map(a -> transformer(a))
                ));
                
            case EList(elements):
                return makeAST(EList(elements.map(e -> transformer(e))));
                
            case ETuple(elements):
                return makeAST(ETuple(elements.map(e -> transformer(e))));
                
            case EMap(pairs):
                return makeAST(EMap(pairs.map(p -> {
                    key: transformer(p.key),
                    value: transformer(p.value)
                })));
                
            case EBinary(op, left, right):
                return makeAST(EBinary(op, transformer(left), transformer(right)));
                
            case EUnary(op, expr):
                return makeAST(EUnary(op, transformer(expr)));
                
            case EFn(clauses):
                return makeAST(EFn(clauses.map(c -> {
                    args: c.args,
                    guard: c.guard != null ? transformer(c.guard) : null,
                    body: transformer(c.body)
                })));
                
            case EDo(body):
                return makeAST(EDo(body.map(stmt -> transformer(stmt))));
                
            // Leaf nodes that don't need transformation
            case EVar(_) | EAtom(_) | EInteger(_) | EFloat(_) | EString(_) | ENil:
                return node;
                
            default:
                // For any unhandled cases, return the node as-is
                // This is safer than attempting to transform unknown structures
                return node;
        }
    }
    
    /**
     * Comprehensive AST dumping for debugging
     * 
     * WHY: Need visibility into exact AST structure to understand pattern detection failures
     * WHAT: Recursively prints AST nodes with proper indentation and all details
     * HOW: Uses Sys.println for macro-time visibility, shows node types and values
     */
    static function dumpAST(ast: ElixirAST, prefix: String = "", depth: Int = 0): Void {
        #if sys
        var indent = "";
        for (i in 0...depth) indent += "  ";
        
        switch(ast.def) {
            case ERemoteCall(module, func, args):
                Sys.println(indent + prefix + 'ERemoteCall:');
                Sys.println(indent + '  module: ' + ElixirASTPrinter.print(module, 0));
                Sys.println(indent + '  func: ' + func);
                Sys.println(indent + '  args (' + args.length + '):');
                for (i in 0...args.length) {
                    dumpAST(args[i], 'arg[' + i + ']: ', depth + 2);
                }
                
            case ECall(target, func, args):
                Sys.println(indent + prefix + 'ECall:');
                if (target != null) {
                    Sys.println(indent + '  target: ' + ElixirASTPrinter.print(target, 0));
                }
                Sys.println(indent + '  func: ' + func);
                Sys.println(indent + '  args (' + args.length + '):');
                for (i in 0...args.length) {
                    dumpAST(args[i], 'arg[' + i + ']: ', depth + 2);
                }
                
            case EString(s):
                Sys.println(indent + prefix + 'EString: "' + s + '"');
                
            case EBinary(op, left, right):
                Sys.println(indent + prefix + 'EBinary: ' + op);
                dumpAST(left, 'left: ', depth + 1);
                dumpAST(right, 'right: ', depth + 1);
                
            case EVar(name):
                Sys.println(indent + prefix + 'EVar: ' + name);
                
            case EInteger(n):
                Sys.println(indent + prefix + 'EInteger: ' + n);
                
            case EFloat(f):
                Sys.println(indent + prefix + 'EFloat: ' + f);
                
            case EAtom(a):
                Sys.println(indent + prefix + 'EAtom: :' + a);
                
            case EList(elements):
                Sys.println(indent + prefix + 'EList (' + elements.length + ' elements):');
                for (i in 0...elements.length) {
                    dumpAST(elements[i], '[' + i + ']: ', depth + 1);
                }
                
            case ETuple(elements):
                Sys.println(indent + prefix + 'ETuple (' + elements.length + ' elements):');
                for (i in 0...elements.length) {
                    dumpAST(elements[i], '{' + i + '}: ', depth + 1);
                }
                
            case EMap(pairs):
                Sys.println(indent + prefix + 'EMap (' + pairs.length + ' pairs):');
                for (i in 0...pairs.length) {
                    Sys.println(indent + '  pair[' + i + ']:');
                    dumpAST(pairs[i].key, 'key: ', depth + 2);
                    dumpAST(pairs[i].value, 'value: ', depth + 2);
                }
                
            case EBlock(stmts):
                Sys.println(indent + prefix + 'EBlock (' + stmts.length + ' statements):');
                for (i in 0...Std.int(Math.min(stmts.length, 5))) {  // Limit to first 5 for brevity
                    dumpAST(stmts[i], 'stmt[' + i + ']: ', depth + 1);
                }
                if (stmts.length > 5) {
                    Sys.println(indent + '  ... and ' + (stmts.length - 5) + ' more statements');
                }
                
            case ENil:
                Sys.println(indent + prefix + 'ENil');
                
            default:
                // For any unhandled cases, print the constructor name
                Sys.println(indent + prefix + 'AST Node: ' + Type.enumConstructor(ast.def));
        }
        #else
        // Non-sys platforms use trace
        trace('[dumpAST not available on non-sys platforms]');
        #end
    }
    
    /**
     * UNROLLED LOOP TRANSFORMATION PASS
     * 
     * Detects patterns of sequential similar statements (like Log.trace with incrementing values)
     * and transforms them back into idiomatic Enum.each calls.
     * 
     * Common patterns:
     * - Log.trace("Iteration 0", ...)
     * - Log.trace("Iteration 1", ...)
     * - Log.trace("Iteration 2", ...)
     */
    public static function unrolledLoopTransformPass(ast: ElixirAST): ElixirAST {
        // Use Sys.println to ensure output is visible
        #if sys
        Sys.println('[XRay LoopTransforms] ============ UNROLLED LOOP TRANSFORM STARTED ============');
        #end
        
        function detectAndTransformUnrolledLoops(node: ElixirAST): ElixirAST {
            // Don't trace every node as it's too verbose
            // trace('[XRay LoopTransforms] Checking node type: ${node.def}');
            
            switch (node.def) {
                // Check modules
                case EModule(name, attributes, body):
                    trace('[XRay LoopTransforms] Found EModule: $name with ${body.length} body items');
                    var transformedBody = body.map(b -> detectAndTransformUnrolledLoops(b));
                    return makeAST(EModule(name, attributes, transformedBody));
                    
                case EDefmodule(name, doBlock):
                    trace('[XRay LoopTransforms] Found EDefmodule: $name');
                    var transformedBlock = detectAndTransformUnrolledLoops(doBlock);
                    return makeAST(EDefmodule(name, transformedBlock));
                    
                // Check function definitions for unrolled loops in their body
                case EDef(name, args, guards, body):
                    trace('[XRay LoopTransforms] Found EDef (public function): $name');
                    var transformedBody = detectAndTransformUnrolledLoops(body);
                    return makeAST(EDef(name, args, guards, transformedBody));
                    
                case EDefp(name, args, guards, body):
                    trace('[XRay LoopTransforms] Found EDefp (private function): $name');
                    var transformedBody = detectAndTransformUnrolledLoops(body);
                    return makeAST(EDefp(name, args, guards, transformedBody));
                    
                case EBlock(stmts):
                    #if sys
                    if (stmts.length > 2) {
                        Sys.println('[XRay LoopTransforms] Found EBlock with ' + stmts.length + ' statements');
                        // Print first few statements for debugging
                        var maxToShow = stmts.length < 3 ? stmts.length : 3;
                        for (i in 0...maxToShow) {
                            Sys.println('[XRay LoopTransforms]   Statement ' + i + ' type: ' + stmts[i].def);
                        }
                    }
                    #end
                    
                    // First check for nested unrolled loops (alternating pattern)
                    var nestedUnrolledLoop = detectNestedUnrolledLoop(stmts);
                    if (nestedUnrolledLoop != null) {
                        trace('[XRay LoopTransforms] ✅ DETECTED NESTED UNROLLED LOOP - transforming to nested Enum.each');
                        return nestedUnrolledLoop;
                    }
                    
                    // Then check for regular nested loops
                    var nestedLoop = NestedLoopDetector.detectNestedLoop(stmts);
                    if (nestedLoop != null) {
                        trace('[XRay LoopTransforms] ✅ DETECTED NESTED LOOP - transforming ${nestedLoop.count} statements');
                        // Process remaining statements after the nested loop
                        var remainingStmts = stmts.slice(nestedLoop.count);
                        if (remainingStmts.length > 0) {
                            var processedRemaining = remainingStmts.map(stmt -> detectAndTransformUnrolledLoops(stmt));
                            return makeAST(EBlock([nestedLoop.transformed].concat(processedRemaining)));
                        }
                        return nestedLoop.transformed;
                    }
                    
                    // Check if this might be an unrolled loop
                    var unrolledLoop = detectUnrolledLoop(stmts);
                    if (unrolledLoop != null) {
                        trace('[XRay LoopTransforms] ✅ DETECTED UNROLLED LOOP - transforming ${stmts.length} statements');
                        return unrolledLoop;
                    } else {
                        trace('[XRay LoopTransforms] ❌ Not an unrolled loop pattern');
                    }
                    
                    // Otherwise, recursively transform statements
                    var transformedStmts = stmts.map(stmt -> detectAndTransformUnrolledLoops(stmt));
                    return makeAST(EBlock(transformedStmts));
                    
                default:
                    // For other node types, manually transform children to avoid infinite recursion
                    // We don't use ElixirASTTransformer.transformNode here because that would create
                    // mutual recursion - transformNode calls transformer which calls transformNode again
                    return transformChildrenManually(node, detectAndTransformUnrolledLoops);
            }
        }
        
        return detectAndTransformUnrolledLoops(ast);
    }
    
    /**
     * Detect nested unrolled loops where outer loop is unrolled but inner loops are already Enum.each
     * 
     * WHY: When Haxe unrolls nested loops with ≤3 iterations, the outer loop gets unrolled
     *      but inner loops may already be transformed to Enum.each calls
     * WHAT: Detects alternating pattern (statement, Enum.each, statement, Enum.each...)
     * HOW: Checks for regular alternation and consistent index progression in outer statements
     * 
     * Pattern example:
     *   trace("Outer: 0")
     *   Enum.each(0..2, fn y -> trace("Inner (0, #{y})") end)
     *   trace("Outer: 1")  
     *   Enum.each(0..2, fn y -> trace("Inner (1, #{y})") end)
     */
    static function detectNestedUnrolledLoop(stmts: Array<ElixirAST>): Null<ElixirAST> {
        if (stmts.length < 4) return null; // Need at least 2 pairs
        
        #if debug_loop_unrolling
        trace('[XRay LoopTransforms] detectNestedUnrolledLoop: Checking ${stmts.length} statements for alternating pattern');
        #end
        
        // Check if we have alternating pattern: statement, Enum.each, statement, Enum.each...
        var outerStatements: Array<ElixirAST> = [];
        var innerLoops: Array<ElixirAST> = [];
        var expectedIndex = 0;
        
        var i = 0;
        while (i < stmts.length - 1) { // -1 because we check pairs
            var stmt = stmts[i];
            var nextStmt = stmts[i + 1];
            
            // Check if this is a valid pair (outer statement + inner Enum.each)
            var isEnumEach = isEnumEachCall(nextStmt);
            
            if (!isEnumEach) {
                #if debug_loop_unrolling
                trace('[XRay LoopTransforms] No alternating pattern at index $i - next statement is not Enum.each');
                #end
                return null;
            }
            
            // Verify the outer statement has the expected index
            if (!containsIndex(stmt, expectedIndex)) {
                #if debug_loop_unrolling
                trace('[XRay LoopTransforms] Outer statement at index $i does not contain expected index $expectedIndex');
                #end
                return null;
            }
            
            #if debug_loop_unrolling
            trace('[XRay LoopTransforms] ✓ Found pair at index $i: outer with index $expectedIndex + inner Enum.each');
            #end
            
            outerStatements.push(stmt);
            innerLoops.push(nextStmt);
            
            expectedIndex++;
            i += 2; // Move to next pair
        }
        
        // Need at least 2 complete pairs for a nested loop pattern
        if (outerStatements.length < 2) {
            #if debug_loop_unrolling
            trace('[XRay LoopTransforms] Only ${outerStatements.length} pairs found, need at least 2');
            #end
            return null;
        }
        
        #if debug_loop_unrolling
        trace('[XRay LoopTransforms] ✅ DETECTED NESTED UNROLLED LOOP: ${outerStatements.length} outer iterations with inner loops');
        #end
        
        // Reconstruct as nested Enum.each
        return reconstructNestedLoop(outerStatements, innerLoops);
    }
    
    /**
     * Check if an AST node is an Enum.each call
     */
    static function isEnumEachCall(ast: ElixirAST): Bool {
        return switch(ast.def) {
            case ERemoteCall(module, func, _):
                switch(module.def) {
                    case EAtom(atom): 
                        // ElixirAtom converts to String, check if it's "Enum"
                        var atomStr: String = atom;
                        atomStr == "Enum" && func == "each";
                    default: false;
                }
            default: false;
        };
    }
    
    /**
     * Check if a statement contains a specific index value
     */
    static function containsIndex(ast: ElixirAST, index: Int): Bool {
        var indexStr = Std.string(index);
        
        // Recursively check the AST for the index
        function checkAST(node: ElixirAST): Bool {
            return switch(node.def) {
                case EInteger(i): i == index;
                case EString(s): s.indexOf(indexStr) >= 0;
                case ERemoteCall(_, _, args):
                    Lambda.exists(args, a -> checkAST(a));
                case ECall(_, _, args):
                    Lambda.exists(args, a -> checkAST(a));
                case EBlock(stmts):
                    Lambda.exists(stmts, s -> checkAST(s));
                case EList(elements):
                    Lambda.exists(elements, e -> checkAST(e));
                default: false;
            };
        }
        
        return checkAST(ast);
    }
    
    /**
     * Reconstruct nested Enum.each from detected unrolled pattern
     */
    static function reconstructNestedLoop(outerStatements: Array<ElixirAST>, innerLoops: Array<ElixirAST>): ElixirAST {
        var count = outerStatements.length;
        
        // Extract the pattern from the first inner loop (they should all be similar)
        var firstInnerLoop = innerLoops[0];
        var firstOuterStmt = outerStatements[0];
        
        // Build the nested structure: Enum.each(0..count-1, fn x -> ... end)
        var outerRange = makeAST(ERange(
            makeAST(EInteger(0)), 
            makeAST(EInteger(count - 1)),
            false  // inclusive range
        ));
        
        // Build function body: execute outer statement then inner loop
        var bodyStatements: Array<ElixirAST> = [];
        
        // Add the substituted outer statement
        var substitutedOuterStmt = substituteIndex(firstOuterStmt, 0, makeAST(EVar("x")));
        bodyStatements.push(substitutedOuterStmt);
        
        // Add the substituted inner loop
        bodyStatements.push(makeVariableSubstitutedLoop(firstInnerLoop, "x"));
        
        var functionBody = makeAST(EBlock(bodyStatements));
        
        // Create the anonymous function with proper pattern
        var fnClause: EFnClause = {
            args: [PVar("x")],
            guard: null,
            body: functionBody
        };
        var outerFunction = makeAST(EFn([fnClause]));
        
        // Create the Enum atom properly
        var enumAtom = new ElixirAtom("Enum");
        
        return makeAST(ERemoteCall(
            makeAST(EAtom(enumAtom)),
            "each",
            [outerRange, outerFunction]
        ));
    }
    
    /**
     * Substitute a specific index value with a variable reference in an AST
     */
    static function substituteIndex(ast: ElixirAST, oldIndex: Int, newVar: ElixirAST): ElixirAST {
        var indexStr = Std.string(oldIndex);
        
        function substitute(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EInteger(i) if (i == oldIndex): 
                    newVar;
                case EString(s) if (s.indexOf(indexStr) >= 0):
                    // Simple string replacement - more sophisticated implementation would handle interpolation
                    makeAST(EString(s.split(indexStr).join("#{x}")));
                case ERemoteCall(module, func, args):
                    makeAST(ERemoteCall(module, func, args.map(a -> substitute(a))));
                case ECall(target, func, args):
                    makeAST(ECall(target, func, args.map(a -> substitute(a))));
                case EBlock(stmts):
                    makeAST(EBlock(stmts.map(s -> substitute(s))));
                case EList(elements):
                    makeAST(EList(elements.map(e -> substitute(e))));
                default: 
                    node;
            };
        }
        
        return substitute(ast);
    }
    
    /**
     * Helper to substitute variables in inner loop for nested structure
     * 
     * WHY: Inner loops need to reference the outer loop variable
     * WHAT: Replaces hardcoded indices in inner loop body with outer variable reference
     * HOW: Traverses the inner loop AST and substitutes integer patterns
     */
    static function makeVariableSubstitutedLoop(innerLoop: ElixirAST, outerVar: String): ElixirAST {
        // For Enum.each calls, we need to substitute in the function body
        return switch(innerLoop.def) {
            case ERemoteCall(module, func, args) if (func == "each" && args.length >= 2):
                // The second argument should be the anonymous function
                var substitutedArgs = args.copy();
                if (args.length >= 2) {
                    substitutedArgs[1] = substituteInFunction(args[1], outerVar);
                }
                makeAST(ERemoteCall(module, func, substitutedArgs));
            default:
                innerLoop;
        };
    }
    
    /**
     * Substitute variables within anonymous function bodies
     */
    static function substituteInFunction(fnAst: ElixirAST, outerVar: String): ElixirAST {
        return switch(fnAst.def) {
            case EFn(clauses):
                var newClauses = clauses.map(clause -> {
                    var newBody = substituteOuterIndex(clause.body, outerVar);
                    {args: clause.args, guard: clause.guard, body: newBody};
                });
                makeAST(EFn(newClauses));
            default:
                fnAst;
        };
    }
    
    /**
     * Substitute outer index references in inner loop body
     */
    static function substituteOuterIndex(ast: ElixirAST, outerVar: String): ElixirAST {
        // This would need to be more sophisticated to handle complex interpolations
        // For now, we'll do basic substitution of string patterns containing indices
        function substitute(node: ElixirAST): ElixirAST {
            return switch(node.def) {
                case EString(s) if (s.indexOf("#{0}") >= 0 || s.indexOf("#{1}") >= 0 || s.indexOf("#{2}") >= 0):
                    // Replace #{0} with #{outerVar}
                    var newStr = s;
                    for (i in 0...3) {
                        var searchPattern = '#{$i}';
                        var replacePattern = '#{$outerVar}';
                        newStr = newStr.split(searchPattern).join(replacePattern);
                    }
                    makeAST(EString(newStr));
                case ERemoteCall(module, func, args):
                    makeAST(ERemoteCall(module, func, args.map(a -> substitute(a))));
                case ECall(target, func, args):
                    makeAST(ECall(target, func, args.map(a -> substitute(a))));
                case EBlock(stmts):
                    makeAST(EBlock(stmts.map(s -> substitute(s))));
                default: 
                    node;
            };
        }
        
        return substitute(ast);
    }
    
    /**
     * Detect if a block of statements represents an unrolled loop
     * Now handles partial matches - identifies consecutive similar statements with incrementing indices
     */
    static function detectUnrolledLoop(stmts: Array<ElixirAST>): Null<ElixirAST> {
        if (stmts.length < 2) return null;
        
        #if sys
        Sys.println('[XRay LoopTransforms] detectUnrolledLoop: Analyzing ' + stmts.length + ' statements');
        #end
        
        // Try to find groups of similar consecutive statements
        var i = 0;
        var transformedStmts: Array<ElixirAST> = [];
        
        while (i < stmts.length) {
            // Try to detect a loop starting at position i
            var loopGroup = detectLoopGroup(stmts, i);
            
            if (loopGroup != null) {
                trace('[XRay LoopTransforms] ✅ Found loop group at position $i with ${loopGroup.count} iterations');
                transformedStmts.push(loopGroup.transformed);
                i += loopGroup.count;
            } else {
                // Not part of a loop, keep original statement
                transformedStmts.push(stmts[i]);
                i++;
            }
        }
        
        // If we transformed anything, return a new block
        if (transformedStmts.length != stmts.length) {
            trace('[XRay LoopTransforms] Transformed block: ${stmts.length} statements → ${transformedStmts.length} statements');
            return makeAST(EBlock(transformedStmts));
        }
        
        return null;
    }
    
    /**
     * Detect a group of consecutive similar statements that form an unrolled loop
     * Returns the transformed loop and the count of statements it consumed
     */
    static function detectLoopGroup(stmts: Array<ElixirAST>, startIdx: Int): Null<{transformed: ElixirAST, count: Int}> {
        if (startIdx >= stmts.length) return null;
        
        var firstCall = extractFunctionCall(stmts[startIdx]);
        if (firstCall == null) return null;
        
        trace('[XRay LoopTransforms] detectLoopGroup: Checking from index $startIdx, first call: ${firstCall.module}.${firstCall.func}');
        
        // Count how many consecutive statements match the pattern
        var count = 0;
        var expectedIndex = 0;
        
        for (i in startIdx...stmts.length) {
            var call = extractFunctionCall(stmts[i]);
            
            // Stop if not a function call or different function
            if (call == null || call.module != firstCall.module || call.func != firstCall.func) {
                break;
            }
            
            // Check if it has the expected index
            if (call.args.length > 0) {
                var hasExpectedIndex = checkForIndex(call.args[0], expectedIndex);
                if (!hasExpectedIndex) {
                    // Index pattern broken, stop here
                    break;
                }
                trace('[XRay LoopTransforms]   ✓ Statement ${i} matches with index $expectedIndex');
            }
            
            count++;
            expectedIndex++;
        }
        
        // Need at least 2 consecutive statements to be considered a loop
        if (count < 2) {
            trace('[XRay LoopTransforms] detectLoopGroup: Only $count matching statements, not enough for a loop');
            return null;
        }
        
        trace('[XRay LoopTransforms] ✅ DETECTED LOOP GROUP: ${firstCall.module}.${firstCall.func} with $count iterations');
        
        // Transform this group to Enum.each
        var transformed = transformToEnumEach(firstCall, count);
        return {transformed: transformed, count: count};
    }
    
    /**
     * Check if an AST node contains a specific index value
     * 
     * WHY: Haxe unrolls small loops, generating sequential statements with incrementing indices
     * WHAT: Detects if an AST node contains a specific index value (0, 1, 2, etc.)
     * HOW: Uses exact string matching first, then handles interpolation and binary concatenation
     */
    static function checkForIndex(ast: ElixirAST, expectedIndex: Int): Bool {
        trace('[XRay LoopTransforms] checkForIndex: Looking for index ' + expectedIndex + ' in ' + ast.def);
        
        switch (ast.def) {
            case EString(s):
                // First try exact string match
                var exactPattern = 'Iteration ' + expectedIndex;
                if (s == exactPattern) {
                    trace('[XRay LoopTransforms]   ✓ EXACT match found: "' + s + '"');
                    return true;
                }
                
                // Check for interpolation pattern (exact match)
                var interpolationPattern = 'Iteration #{' + expectedIndex + '}';
                if (s == interpolationPattern) {
                    trace('[XRay LoopTransforms]   ✓ EXACT interpolation match: "' + s + '"');
                    return true;
                }
                
                // Check for just the index placeholder
                var placeholderPattern = '#{' + expectedIndex + '}';
                if (s == placeholderPattern) {
                    trace('[XRay LoopTransforms]   ✓ EXACT placeholder match: "' + s + '"');
                    return true;
                }
                
                // Check if string is just the index number
                var indexStr = Std.string(expectedIndex);
                if (s == indexStr) {
                    trace('[XRay LoopTransforms]   ✓ EXACT index string match: "' + s + '"');
                    return true;
                }
                
                // Only use contains as absolute fallback
                // This handles cases where the pattern might be part of a larger string
                if (s.indexOf(exactPattern) != -1 || 
                    s.indexOf(interpolationPattern) != -1 ||
                    s.indexOf(placeholderPattern) != -1) {
                    trace('[XRay LoopTransforms]   ✓ Found index via contains fallback in: "' + s + '"');
                    return true;
                }
                
                trace('[XRay LoopTransforms]   ✗ No match in string: "' + s + '"');
                return false;
                
            case EBinary(StringConcat, left, right):
                // For concatenation, check both parts
                // This handles cases like "Iteration " + index
                var leftHas = checkForIndex(left, expectedIndex);
                var rightHas = checkForIndex(right, expectedIndex);
                if (leftHas || rightHas) {
                    trace('[XRay LoopTransforms]   ✓ Found index in binary concat');
                }
                return leftHas || rightHas;
                
            case EInteger(n):
                // Direct integer comparison - exact match only
                if (n == expectedIndex) {
                    trace('[XRay LoopTransforms]   ✓ Found exact index as integer: ' + n);
                    return true;
                }
                trace('[XRay LoopTransforms]   ✗ Integer ' + n + ' does not match expected ' + expectedIndex);
                return false;
                
            case EVar(name):
                // Check if variable name contains the index
                // This might happen if the index is in a variable
                var indexStr = Std.string(expectedIndex);
                if (name == indexStr || name == 'i' + indexStr) {
                    trace('[XRay LoopTransforms]   ✓ Found index in variable name: ' + name);
                    return true;
                }
                trace('[XRay LoopTransforms]   ✗ Variable ' + name + ' does not match index');
                return false;
                
            case ERaw(rawString):
                // ERaw contains raw Elixir code with string interpolation
                // Check for the index in the raw string
                var indexStr = Std.string(expectedIndex);
                
                // Check for various patterns that include the index
                var patterns = [
                    'Iteration #{' + indexStr + '}',    // Exact interpolation pattern
                    '#{' + indexStr + '}',               // Just the interpolation
                    'Iteration ' + indexStr,            // Plain text version
                    'Value: #{' + indexStr + '}',       // Other patterns
                    'Pair: #{' + indexStr + '}'         // Pair pattern
                ];
                
                for (pattern in patterns) {
                    if (rawString.indexOf(pattern) != -1) {
                        trace('[XRay LoopTransforms]   ✓ Found index in ERaw string: "' + rawString + '" (matched: "' + pattern + '")');
                        return true;
                    }
                }
                
                // Also check if the index appears anywhere in the string
                var interpolationPattern = '#{' + indexStr + '}';
                if (rawString.indexOf(interpolationPattern) != -1) {
                    trace('[XRay LoopTransforms]   ✓ Found index interpolation in ERaw: "' + rawString + '"');
                    return true;
                }
                
                trace('[XRay LoopTransforms]   ✗ No index ' + expectedIndex + ' found in ERaw: "' + rawString + '"');
                return false;
                
            default:
                // For other AST types, log for debugging but return false
                trace('[XRay LoopTransforms]   ⚠ Unhandled AST type in checkForIndex: ' + Type.enumConstructor(ast.def));
                return false;
        }
    }
    
    /**
     * Extract function call information from an AST node
     */
    static function extractFunctionCall(ast: ElixirAST): Null<{module: String, func: String, args: Array<ElixirAST>}> {
        switch (ast.def) {
            case ERemoteCall({def: EVar(module)}, funcName, args):
                return {module: module, func: funcName, args: args};
            case ECall(target, funcName, args):
                return {module: "", func: funcName, args: args};
            default:
                return null;
        }
    }
    
    /**
     * Transform an unrolled loop pattern back to Enum.each
     */
    static function transformToEnumEach(callInfo: {module: String, func: String, args: Array<ElixirAST>}, count: Int): ElixirAST {
        // Create range: 0..(count-1)
        var range = makeAST(ERange(
            makeAST(EInteger(0)),
            makeAST(EInteger(count - 1)),
            false
        ));
        
        // Create the function body that recreates the original call
        var loopVar = "i";
        
        // Transform the first argument to use the loop variable
        var bodyArgs = [];
        if (callInfo.args.length > 0) {
            // Detect the pattern in the first argument and replace with loop variable
            // We need to create proper Elixir string interpolation
            var firstArg = callInfo.args[0];
            
            // Check what pattern was in the original
            var transformedArg = switch(firstArg.def) {
                case ERaw(s):
                    // Replace the index placeholder with the loop variable
                    // e.g., "Iteration #{0}" becomes "Iteration #{i}"
                    var pattern = ~/#{[0-9]+}/;
                    var replaced = pattern.replace(s, '#{' + loopVar + '}');
                    makeAST(ERaw(replaced));
                    
                case EString(s):
                    // Plain string, create interpolation
                    makeAST(ERaw(s + '#{' + loopVar + '}'));
                    
                default:
                    // Fallback - use string concatenation
                    makeAST(ERaw('Iteration #{' + loopVar + '}'));
            };
            
            bodyArgs.push(transformedArg);
            
            // Add remaining arguments unchanged
            for (i in 1...callInfo.args.length) {
                bodyArgs.push(callInfo.args[i]);
            }
        }
        
        // Create the function body
        var body = if (callInfo.module != "") {
            makeAST(ERemoteCall(
                makeAST(EVar(callInfo.module)),
                callInfo.func,
                bodyArgs
            ));
        } else {
            makeAST(ECall(null, callInfo.func, bodyArgs));
        };
        
        // Create the anonymous function: fn i -> body end
        var clause: EFnClause = {
            args: [PVar(loopVar)],
            body: body
        };
        var func = makeAST(EFn([clause]));
        
        // Create Enum.each(range, func)
        return makeAST(ERemoteCall(
            makeAST(EVar("Enum")),
            "each",
            [range, func]
        ));
    }
    
    
    /**
     * WHILE LOOP TRANSFORMATION PASS
     * 
     * Transforms while loops with empty or trivial bodies into appropriate
     * recursive functions or Enum operations.
     */
    public static function whileLoopTransformPass(ast: ElixirAST): ElixirAST {
        #if debug_while_loops
        trace('[WhileLoopTransform] Starting pass');
        #end
        
        function transformWhileLoops(node: ElixirAST): ElixirAST {
            switch (node.def) {
                case ERemoteCall({def: EVar("Enum")}, "reduce_while", args) if (args.length >= 3):
                    // Check if this is an empty reduce_while
                    var hasEmptyBody = switch (args[2].def) {
                        case EFn(clauses) if (clauses.length > 0):
                            switch (clauses[0].body.def) {
                                case ENil: true;
                                case EBlock([]): true;
                                default: false;
                            }
                        default: false;
                    };
                    
                    if (hasEmptyBody) {
                        #if debug_while_loops
                        trace('[WhileLoopTransform] Found empty reduce_while, transforming to recursive function');
                        #end
                        // Transform to a simpler pattern or remove entirely
                        return makeAST(ENil); // Placeholder - needs proper implementation
                    }
                    
                    // Otherwise, recursively transform
                    return ElixirASTTransformer.transformNode(node, transformWhileLoops);
                    
                default:
                    return ElixirASTTransformer.transformNode(node, transformWhileLoops);
            }
        }
        
        return transformWhileLoops(ast);
    }
}

#end