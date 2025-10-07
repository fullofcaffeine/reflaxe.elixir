package reflaxe.elixir.ast.transformers;

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTBuilder;
import reflaxe.elixir.ast.ElixirASTHelpers.*;

using reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * AssignmentExtractionTransforms: Handles extraction of assignments from expressions
 * 
 * WHY: Elixir doesn't allow assignments within arithmetic/binary expressions.
 * When Haxe's inline expansion creates patterns like `expr1 ||| index = call() &&& expr2`,
 * this causes compilation errors: "cannot invoke remote function :erlang.-/2 inside a match"
 * 
 * WHAT: Detects and extracts assignments (EMatch nodes) from within binary operations
 * and other expression contexts where they're not allowed. Hoists assignments before
 * the expression that uses them while preserving evaluation order.
 * 
 * HOW: 
 * - Recursively traverses expressions to find embedded EMatch nodes
 * - Collects assignments in evaluation order (left-to-right)
 * - Returns extracted assignments and cleaned expression
 * - Transforms blocks to include hoisted assignments before expressions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles assignment extraction
 * - Preserves Evaluation Order: Critical for inline expansion correctness
 * - Recursive Design: Handles deeply nested assignments
 * - Clean Separation: Doesn't modify other AST transformations
 * 
 * EDGE CASES:
 * - Nested assignments (index = i = i + 1)
 * - Multiple assignments in one expression
 * - Assignments in function arguments
 * - Assignments in both operands of binary operations
 */
@:nullSafety(Off)
class AssignmentExtractionTransforms {
    
    /**
     * Counter for generating unique temporary variable names.
     * 
     * WHY: When extracting complex pattern matches (not just PVar), we need a temp variable
     * to hold the value first before pattern matching, ensuring proper evaluation order.
     * 
     * HOW: Incremented each time we extract a complex pattern (e.g., PTuple, PArray)
     * to generate names like _extracted_0, _extracted_1, etc. These temps are only used
     * internally during the extraction process and don't conflict with user variables.
     */
    private static var extractionCounter: Int = 0;
    
    /**
     * Main transformation pass for extracting assignments from expressions
     * 
     * WHY: Entry point for the assignment extraction transformation
     * WHAT: Traverses the AST and extracts assignments from expression contexts
     * HOW: Uses transformNode to visit each node and apply extraction logic
     */
    public static function assignmentExtractionPass(ast: ElixirAST): ElixirAST {
        #if debug_assignment_extraction
        trace("[XRay AssignmentExtraction] Starting assignment extraction pass");
        #end
        
        return transformAssignments(ast);
    }
    
    static function transformAssignments(node: ElixirAST): ElixirAST {
        #if debug_assignment_extraction
        var nodeType = Type.enumConstructor(node.def);
        if (nodeType == "EMatch" || nodeType == "EBinary" || nodeType == "ECase") {
            trace('[XRay AssignmentExtraction] ⚡ Visiting ${nodeType} node');
        }
        #end
        
        // Special handling for ECase - we need to control how its clauses are transformed
        switch(node.def) {
            case ECase(expr, clauses):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Special ECase handling - preserving clause body statements");
                #end
                
                // Transform the expression being matched
                var transformedExpr = transformAssignments(expr);
                
                // Transform clauses but DON'T extract assignments from their bodies
                var transformedClauses = [];
                for (clause in clauses) {
                    // Transform guard if present
                    var transformedGuard = clause.guard != null ? transformAssignments(clause.guard) : null;
                    
                    // For the body, we just recursively transform but DON'T apply extraction
                    // because case clause bodies are statement contexts
                    var transformedBody = transformClauseBody(clause.body);
                    
                    transformedClauses.push({
                        pattern: clause.pattern,
                        guard: transformedGuard,
                        body: transformedBody
                    });
                }
                
                return makeASTWithMeta(
                    ECase(transformedExpr, transformedClauses),
                    node.metadata,
                    node.pos
                );
                
            default:
                // For all other nodes, use the standard recursive transformation
        }

        // For non-ECase nodes, first recurse into children, then check if this node needs transformation
        // IMPORTANT: We don't pass transformAssignments to avoid infinite recursion
        // Instead, we manually handle the recursion for the specific node types we care about
        var transformedNode = node;

        // Manually recurse for node types that can contain assignments
        switch(node.def) {
            case EBlock(expressions):
                // Combine adjacent concat+bind with immediate method call patterns in statement blocks
                var combinedExprs = [];
                var iBlk = 0;
                while (iBlk < expressions.length) {
                    var cur = expressions[iBlk];
                    var nxt = (iBlk + 1 < expressions.length) ? expressions[iBlk + 1] : null;
                    var matched = false;
                    switch (cur.def) {
                        case EMatch(PVar(assignName), concatExpr):
                            switch (concatExpr.def) {
                                case EBinary(StringConcat, leftExpr, rightExpr):
                                    switch (rightExpr.def) {
                                        case EMatch(PVar(tmpVar), tmpValue):
                                            switch (nxt != null ? nxt.def : null) {
                                                case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0)):
                                                    switch (tmpValue.def) {
                                                        case ERemoteCall({def: EVar(modName)}, fnName, args) if (modName == "DateTime" && fnName == "utc_now"):
                                                            var moduleNode = makeAST(EVar("DateTime"));
                                                            var converted = makeAST(ERemoteCall(moduleNode, methodName, [tmpValue]));
                                                            var newConcat = makeAST(EBinary(StringConcat, cur, converted)); // cur will be transformed later; keep structure
                                                            var newAssign = makeASTWithMeta(EMatch(PVar(assignName), makeAST(EBinary(StringConcat, leftExpr, converted))), cur.metadata, cur.pos);
                                                            combinedExprs.push(newAssign);
                                                            iBlk += 2;
                                                            matched = true;
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        default:
                    }
                    if (!matched) {
                        combinedExprs.push(cur);
                        iBlk++;
                    }
                }
                transformedNode = makeASTWithMeta(
                    EBlock(combinedExprs.map(transformAssignments)),
                    node.metadata,
                    node.pos
                );
            case EIf(cond, thenBranch, elseBranch):
                // Normalize condition: peel leading EBlock/EParen(EBlock) into pre-assignments
                var condTrans = transformAssignments(cond);
                var preExtract:Array<ElixirAST> = [];
                function peel(n:ElixirAST):ElixirAST {
                    return switch (n.def) {
                        case EBlock(sts) if (sts.length > 0):
                            for (i in 0...sts.length - 1) preExtract.push(sts[i]);
                            peel(sts[sts.length - 1]);
                        case EParen(inner):
                            var peeled = peel(inner);
                            if (preExtract.length > 0) makeAST(EVar("__peeled_marker__")); // marker no-op
                            peeled;
                        default:
                            n;
                    };
                }
                var condBase = peel(condTrans);
                #if debug_assignment_extraction
                if (preExtract.length > 0) {
                    trace('[XRay AssignmentExtraction] Hoisting ' + preExtract.length + ' pre-statements from if condition');
                }
                #end
                var condResult = extractAndTransformExpression(condBase);
                var cleanThen = transformAssignments(thenBranch);
                var cleanElse = elseBranch != null ? transformAssignments(elseBranch) : null;
                var rebuiltIf = makeASTWithMeta(
                    EIf(condResult.expression, cleanThen, cleanElse),
                    node.metadata,
                    node.pos
                );
                var hoisted = preExtract.copy();
                if (condResult.hasExtracted) for (s in condResult.extracted) hoisted.push(s);
                if (hoisted.length > 0) {
                    var stmts = hoisted.copy();
                    stmts.push(rebuiltIf);
                    transformedNode = makeASTWithMeta(EBlock(stmts), node.metadata, node.pos);
                } else {
                    transformedNode = rebuiltIf;
                }
            case EBinary(op, left, right):
                transformedNode = makeASTWithMeta(
                    EBinary(op, transformAssignments(left), transformAssignments(right)),
                    node.metadata,
                    node.pos
                );
            case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                // Recurse into try and its clauses so rescue bodies get assignment normalization
                var newRescues: Array<ERescueClause> = [];
                if (rescueClauses != null) {
                    for (rc in rescueClauses) {
                        var newBody = rc != null && rc.body != null ? transformAssignments(rc.body) : rc.body;
                        newRescues.push({ pattern: rc.pattern, varName: rc.varName, body: newBody });
                    }
                }
                var newCatches: Array<ECatchClause> = [];
                if (catchClauses != null) {
                    for (cc in catchClauses) {
                        var newBody = cc != null && cc.body != null ? transformAssignments(cc.body) : cc.body;
                        newCatches.push({ kind: cc.kind, pattern: cc.pattern, body: newBody });
                    }
                }
                transformedNode = makeASTWithMeta(
                    ETry(
                        body != null ? transformAssignments(body) : null,
                        newRescues,
                        newCatches,
                        afterBlock != null ? transformAssignments(afterBlock) : null,
                        elseBlock != null ? transformAssignments(elseBlock) : null
                    ),
                    node.metadata,
                    node.pos
                );
            default:
                // For other node types, keep as-is
                transformedNode = node;
        }

        // Handle null nodes (which can indicate removed nodes)
        if (transformedNode == null) {
            return null;
        }
        
        // Then check if this node itself needs transformation
        switch(transformedNode.def) {
            // Look for assignments that are direct statements
            case EMatch(pattern, value):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Found top-level EMatch");
                trace('[XRay AssignmentExtraction] Pattern: $pattern');
                trace('[XRay AssignmentExtraction] Value type: ${Type.enumConstructor(value.def)}');
                if (value.metadata?.sourceFile != null) {
                    trace('[XRay AssignmentExtraction] Source: ${value.metadata.sourceFile}:${value.metadata.sourceLine}');
                }
                // Special check for chained assignments like c = index = s.cca(...)
                switch(value.def) {
                    case EMatch(innerPattern, innerValue):
                        trace('[XRay AssignmentExtraction] Found chained assignment!');
                        trace('[XRay AssignmentExtraction] Inner pattern: $innerPattern');
                        trace('[XRay AssignmentExtraction] Inner value type: ${Type.enumConstructor(innerValue.def)}');
                    default:
                }
                #end
                // Check if the value contains assignments in binary expressions
                var result = extractAndTransformExpression(value);
                if (result.hasExtracted) {
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] Transforming top-level assignment");
                    trace('[XRay AssignmentExtraction] Extracted ${result.extracted.length} assignments');
                    #end
                    // Create a block with extracted assignments followed by the main assignment
                    var statements = result.extracted.copy();
                    statements.push(makeASTWithMeta(
                        EMatch(pattern, result.expression),
                        transformedNode.metadata,
                        transformedNode.pos
                    ));
                    return makeAST(EBlock(statements));
                }
                return transformedNode;
                
            // Binary operations might contain assignments that need extraction
            case EBinary(op, left, right):
                var result = extractAndTransformExpression(transformedNode);
                if (result.hasExtracted) {
                    // Create a block with extracted assignments followed by the expression
                    var statements = result.extracted.copy();
                    statements.push(result.expression);
                    return makeAST(EBlock(statements));
                }
                // Even without extractions, use the cleaned expression to preserve
                // structural normalizations (like operand parentheses)
                return result.expression;
                
            // Handle calls that might contain functions with assignments
            case ECall(_, _, _):
                var result = extractAndTransformExpression(transformedNode);
                if (result.hasExtracted) {
                    // Create a block with extracted assignments followed by the call
                    var statements = result.extracted.copy();
                    statements.push(result.expression);
                    return makeAST(EBlock(statements));
                }
                return transformedNode;
                
            // Handle remote calls (like Enum.reduce_while) that might contain functions with assignments
            case ERemoteCall(_, _, _):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Processing ERemoteCall at top level");
                #end
                var result = extractAndTransformExpression(transformedNode);
                if (result.hasExtracted) {
                    // Create a block with extracted assignments followed by the remote call
                    var statements = result.extracted.copy();
                    statements.push(result.expression);
                    return makeAST(EBlock(statements));
                }
                return transformedNode;
                
            // Handle case expressions - need special handling for clause bodies
            case ECase(expr, clauses):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Processing top-level ECase");
                trace('[XRay AssignmentExtraction] Number of clauses: ${clauses.length}');
                #end
                
                // Process the matched expression for any embedded assignments
                var exprResult = extractAndTransformExpression(expr);
                
                // Process clauses but preserve variable declarations in their bodies
                var processedClauses = [];
                for (clause in clauses) {
                    var transformedBody = transformClauseBody(clause.body);
                    processedClauses.push({
                        pattern: clause.pattern,
                        guard: clause.guard,
                        body: transformedBody
                    });
                }
                
                // If the expression had extractions, hoist them
                if (exprResult.hasExtracted) {
                    var statements = exprResult.extracted.copy();
                    statements.push(makeASTWithMeta(
                        ECase(exprResult.expression, processedClauses),
                        transformedNode.metadata,
                        transformedNode.pos
                    ));
                    return makeAST(EBlock(statements));
                } else {
                    // Return the ECase with original clause bodies 
                    return transformedNode;
                }
                
            // Handle if expressions that might contain assignments in conditions
            case EIf(condition, thenBranch, elseBranch):
                #if debug_assignment_extraction
                trace("[XRay AssignmentExtraction] Processing top-level EIf");
                trace('[XRay AssignmentExtraction] Condition type: ${Type.enumConstructor(condition.def)}');
                #end
                
                // First check if the condition is a parenthesized expression
                var actualCondition = switch(condition.def) {
                    case EParen(inner): inner;
                    default: condition;
                };
                
                #if debug_assignment_extraction
                trace('[XRay AssignmentExtraction] Actual condition type: ${Type.enumConstructor(actualCondition.def)}');
                #end
                
                // Extract assignments from the condition
                var condResult = extractAndTransformExpression(actualCondition);
                
                if (condResult.hasExtracted) {
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Extracted ${condResult.extracted.length} assignments from if condition');
                    #end
                    // Create a block with extracted assignments followed by the if expression
                    var statements = condResult.extracted.copy();
                    
                    // Re-wrap in parentheses if needed
                    var newCondition = switch(condition.def) {
                        case EParen(_): makeASTWithMeta(EParen(condResult.expression), condition.metadata, condition.pos);
                        default: condResult.expression;
                    };
                    
                    statements.push(makeASTWithMeta(
                        EIf(newCondition, thenBranch, elseBranch),
                        transformedNode.metadata,
                        transformedNode.pos
                    ));
                    return makeAST(EBlock(statements));
                }
                return transformedNode;
                
            default:
                // Return the already-transformed node
                return transformedNode;
        }
    }
    
    /**
     * Transform a case clause body recursively without extracting assignments
     * 
     * Case clause bodies are statement contexts where variable declarations
     * should be preserved, not extracted.
     */
    static function transformClauseBody(body: ElixirAST): ElixirAST {
        // Null safety check
        if (body == null || body.def == null) {
            return body;
        }

        #if debug_assignment_extraction
        trace('[XRay AssignmentExtraction] Transforming clause body type: ${Type.enumConstructor(body.def)}');
        #end

        // Simply recurse through the AST structure without extraction
        switch(body.def) {
            case EBlock(statements):
                #if debug_assignment_extraction
                trace('[XRay AssignmentExtraction] Clause body is EBlock with ${statements.length} statements - preserving all');
                #end
                // Transform each statement recursively but keep them all
                var transformedStatements = [];
                for (stmt in statements) {
                    var transformedStmt = transformClauseBody(stmt);
                    if (shouldDropTempAssignment(transformedStmt)) {
                        #if debug_assignment_extraction
                        trace('[XRay AssignmentExtraction] Dropping temp assignment statement');
                        #end
                        continue;
                    }
                    transformedStatements.push(transformedStmt);
                }
                return makeASTWithMeta(
                    EBlock(transformedStatements),
                    body.metadata,
                    body.pos
                );
                
            // For other node types, apply standard transformation
            default:
                return ElixirASTTransformer.transformAST(body, transformAssignments);
        }
    }

    static function shouldDropTempAssignment(stmt: ElixirAST): Bool {
        if (stmt == null || stmt.def == null) {
            return false;
        }

        return switch(stmt.def) {
            case EMatch(pattern, value):
                switch pattern {
                    case PVar(name):
                        var valueVar = switch(value.def) {
                            case EVar(varName): varName;
                            default: null;
                        };

                        if (ElixirASTBuilder.isTempPatternVarName(name)) {
                            return true;
                        }

                        if (valueVar != null) {
                            if (valueVar == name) {
                                return true;
                            }
                            if (ElixirASTBuilder.isTempPatternVarName(valueVar)) {
                                return true;
                            }
                        }
                        false;
                    default:
                        false;
                };
            default:
                false;
        };
    }
    
    /**
     * Extract assignments from an expression and return both extracted assignments and cleaned expression
     * 
     * Context-aware version: Builds a parent map first to understand context,
     * then only extracts assignments when in expression contexts.
     */
    static function extractAndTransformExpression(expr: ElixirAST): {extracted: Array<ElixirAST>, expression: ElixirAST, hasExtracted: Bool} {
        var extracted = [];
        
        // Phase 1: Build parent map to understand context
        var parentOf = new haxe.ds.ObjectMap<ElixirAST, ElixirAST>();
        
        function buildParentMap(node: ElixirAST, parent: Null<ElixirAST>): Void {
            // Skip null nodes
            if (node == null || node.def == null) {
                return;
            }

            if (parent != null) {
                parentOf.set(node, parent);
            }

            switch(node.def) {
                case ECase(expr, clauses):
                    buildParentMap(expr, node);
                    if (clauses != null) {
                        for (clause in clauses) {
                            // The clause body's parent is the ECase, which is important for context
                            if (clause != null && clause.body != null) {
                                buildParentMap(clause.body, node);
                            }
                            if (clause != null && clause.guard != null) {
                                buildParentMap(clause.guard, node);
                            }
                        }
                    }
                    
                case EBlock(statements):
                    if (statements != null) {
                        for (stmt in statements) {
                            if (stmt != null) {
                                buildParentMap(stmt, node);
                            }
                        }
                    }
                    
                case EIf(condition, thenBranch, elseBranch):
                    buildParentMap(condition, node);
                    buildParentMap(thenBranch, node);
                    if (elseBranch != null) {
                        buildParentMap(elseBranch, node);
                    }
                    
                case EBinary(_, left, right):
                    buildParentMap(left, node);
                    buildParentMap(right, node);
                    
                case EUnary(_, operand):
                    buildParentMap(operand, node);
                    
                case ECall(target, _, args):
                    if (target != null) buildParentMap(target, node);
                    for (arg in args) {
                        buildParentMap(arg, node);
                    }
                    
                case ERemoteCall(module, _, args):
                    buildParentMap(module, node);
                    for (arg in args) {
                        buildParentMap(arg, node);
                    }
                    
                case EFn(clauses):
                    for (clause in clauses) {
                        buildParentMap(clause.body, node);
                        if (clause.guard != null) {
                            buildParentMap(clause.guard, node);
                        }
                    }
                    
                case EParen(inner):
                    buildParentMap(inner, node);
                    
                case EMatch(_, value):
                    buildParentMap(value, node);
                    
                default:
                    // Leaf nodes or nodes we don't need to traverse
            }
        }
        
        // Build the parent map
        buildParentMap(expr, null);
        
        // Helper: Check if we're in a statement context (where variable declarations are allowed)
        function isInStatementContext(node: ElixirAST): Bool {
            // Statement context is determined by the direct parent relationship only.
            // This prevents leaking statement privileges into expression positions such as
            // if/cond conditions, binary operands, etc.
            var parent = parentOf.get(node);
            if (parent == null) return true; // Top-level
            return switch (parent.def) {
                case EBlock(_): true;          // Direct child of block
                case ECase(_, _): true;        // Direct clause body attached to case
                case EFn(_): true;             // Direct function clause body
                default: false;                // All other direct parents are expression contexts
            };
        }
        
        // Helper: Replace all occurrences of a variable with a replacement expression
        function substituteVar(node: ElixirAST, varName: String, replacement: ElixirAST): ElixirAST {
            if (node == null || node.def == null) return node;
            return switch(node.def) {
                case EVar(name) if (name == varName):
                    // Replace variable reference with the replacement expression
                    replacement;
                case EBlock(statements):
                    makeASTWithMeta(EBlock([for (s in statements) substituteVar(s, varName, replacement)]), node.metadata, node.pos);
                case EIf(cond, thenB, elseB):
                    makeASTWithMeta(EIf(
                        substituteVar(cond, varName, replacement),
                        substituteVar(thenB, varName, replacement),
                        elseB != null ? substituteVar(elseB, varName, replacement) : null
                    ), node.metadata, node.pos);
                case ECase(target, branches):
                    makeASTWithMeta(ECase(
                        substituteVar(target, varName, replacement),
                        [for (b in branches) { pattern: b.pattern, guard: b.guard, body: substituteVar(b.body, varName, replacement) }]
                    ), node.metadata, node.pos);
                case EBinary(op, left, right):
                    makeASTWithMeta(EBinary(op, substituteVar(left, varName, replacement), substituteVar(right, varName, replacement)), node.metadata, node.pos);
                case EUnary(op, operand):
                    makeASTWithMeta(EUnary(op, substituteVar(operand, varName, replacement)), node.metadata, node.pos);
                case ECall(target, name, args):
                    makeASTWithMeta(ECall(target != null ? substituteVar(target, varName, replacement) : null, name, [for (a in args) substituteVar(a, varName, replacement)]), node.metadata, node.pos);
                case ERemoteCall(mod, name, args):
                    makeASTWithMeta(ERemoteCall(substituteVar(mod, varName, replacement), name, [for (a in args) substituteVar(a, varName, replacement)]), node.metadata, node.pos);
                case EParen(inner):
                    makeASTWithMeta(EParen(substituteVar(inner, varName, replacement)), node.metadata, node.pos);
                case EMatch(pat, value):
                    // Do not substitute within pattern; only substitute in value
                    makeASTWithMeta(EMatch(pat, substituteVar(value, varName, replacement)), node.metadata, node.pos);
                default:
                    node;
            };
        }

        // Phase 2: Extract assignments with context awareness
        function extractFromExpr(e: ElixirAST, inStmtContext: Bool = false): ElixirAST {
            switch(e.def) {
                case EMatch(pattern, value):
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] 🔍 Found embedded assignment");
                    trace('[XRay AssignmentExtraction] Pattern: $pattern');
                    trace('[XRay AssignmentExtraction] Pattern type: ${Type.enumConstructor(pattern)}');
                    trace('[XRay AssignmentExtraction] Value type: ${Type.enumConstructor(value.def)}');
                    #end
                    
                    // First extract any assignments from the value expression itself
                    var cleanValue = extractFromExpr(value, false);

                    // Skip extraction for temp pattern variables (g, g1, etc.)
                    switch pattern {
                        case PVar(name) if (ElixirASTBuilder.isTempPatternVarName(name)):
                            #if debug_assignment_extraction
                            trace('[XRay AssignmentExtraction] ⚠️ Skipping temp pattern assignment for $name');
                            #end
                            return cleanValue;
                        case PVar(name):
                            switch(cleanValue.def) {
                                case EVar(varName) if (varName == name):
                                    #if debug_assignment_extraction
                                    trace('[XRay AssignmentExtraction] ⚠️ Skipping redundant self-assignment: $name = $varName');
                                    #end
                                    return cleanValue;
                                default:
                            }
                        default:
                    }
                    
                    // Then extract this assignment
                    extracted.push(makeASTWithMeta(
                        EMatch(pattern, cleanValue),
                        e.metadata,
                        e.pos
                    ));
                    
                    // Return variable reference
                    switch(pattern) {
                        case PVar(name):
                            #if debug_assignment_extraction
                            trace('[XRay AssignmentExtraction] 🔄 Replacing assignment with variable: $name');
                            #end
                            return makeAST(EVar(name));
                        default:
                            /**
                             * Complex pattern handling (PTuple, PArray, PObject, etc.)
                             * 
                             * WHY: Complex patterns like {x, y} = func() need special handling
                             * because we can't directly return a variable reference for them.
                             * 
                             * HOW: We use a two-step extraction:
                             * 1. First assign the value to a temp variable: _extracted_0 = func()
                             * 2. Then pattern match from the temp: {x, y} = _extracted_0
                             * 3. Return the temp variable reference for use in expressions
                             * 
                             * This preserves both the pattern matching and proper evaluation order
                             * while ensuring the extracted value can be used in the parent expression.
                             */
                            var tempVar = '_extracted_${extractionCounter++}';
                            
                            // Replace the last extraction (the full pattern match)
                            // with a simple temp variable assignment
                            extracted[extracted.length - 1] = makeASTWithMeta(
                                EMatch(PVar(tempVar), cleanValue),
                                e.metadata,
                                e.pos
                            );
                            
                            // Then add the actual pattern match from the temp variable
                            // This ensures the pattern destructuring still happens
                            extracted.push(makeASTWithMeta(
                                EMatch(pattern, makeAST(EVar(tempVar))),
                                e.metadata,
                                e.pos
                            ));
                            
                            // Return reference to the temp variable for use in parent expression
                            return makeAST(EVar(tempVar));
                    }
                    
                case EUnary(op, operand):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing EUnary operator: $op');
                    trace('[XRay AssignmentExtraction] Operand type: ${Type.enumConstructor(operand.def)}');
                    #end
                    
                    // Special handling for EBlock inside unary operators
                    switch(operand.def) {
                        case EBlock(_):
                            #if debug_assignment_extraction
                            trace('[XRay AssignmentExtraction] Found EBlock in unary - delegating to extractFromExpr');
                            #end
                            
                            // Let extractFromExpr handle the block properly
                            // It will extract assignments and return the cleaned expression
                            var cleanOperand = extractFromExpr(operand, inStmtContext);
                            
                            #if debug_assignment_extraction
                            trace('[XRay AssignmentExtraction] After extraction, applying unary to: ${Type.enumConstructor(cleanOperand.def)}');
                            trace('[XRay AssignmentExtraction] Total extracted so far: ${extracted.length}');
                            #end
                            
                            return makeASTWithMeta(
                                EUnary(op, cleanOperand),
                                e.metadata,
                                e.pos
                            );
                            
                        default:
                            // Regular unary processing
                            var cleanOperand = extractFromExpr(operand, inStmtContext);
                            
                            return makeASTWithMeta(
                                EUnary(op, cleanOperand),
                                e.metadata,
                                e.pos
                            );
                    }
                    
                case EBinary(op, left, right):
                    // Handle binary match (assignment) specially when in expression context
                    if (op == Match) {
                        // Transform RHS first
                        var cleanRight = extractFromExpr(right, false);
                        switch (left.def) {
                            case EVar(varName):
                                if (inStmtContext) {
                                    // Safe to keep as an assignment
                                    return makeASTWithMeta(EBinary(Match, left, cleanRight), e.metadata, e.pos);
                                } else {
                                    // Hoist assignment and return variable reference
                                    extracted.push(makeASTWithMeta(EMatch(PVar(varName), cleanRight), e.metadata, e.pos));
                                    return makeAST(EVar(varName));
                                }
                            default:
                                // Non-variable left-hand side: keep as assignment with cleaned RHS
                                // Avoid hoisting to prevent type issues with non-pattern LHS
                                return makeASTWithMeta(EBinary(Match, left, cleanRight), e.metadata, e.pos);
                        }
                    }
                    #if debug_assignment_extraction
                    trace("[XRay AssignmentExtraction] Processing binary in expression: " + Type.enumConstructor(op));
                    trace('[XRay AssignmentExtraction] Left: ${left.def}');
                    trace('[XRay AssignmentExtraction] Right: ${right.def}');
                    
                    // Check if left or right contains assignments
                    var hasLeftAssignment = switch(left.def) {
                        case EMatch(_, _): true;
                        default: false;
                    };
                    var hasRightAssignment = switch(right.def) {
                        case EMatch(_, _): true;
                        default: false;
                    };
                    trace('[XRay AssignmentExtraction] Has left assignment: $hasLeftAssignment');
                    trace('[XRay AssignmentExtraction] Has right assignment: $hasRightAssignment');
                    #end
                    var cleanLeft = extractFromExpr(left, false);
                    var cleanRight = extractFromExpr(right, false);

                    // Parenthesize nested do-end expressions used as operands to avoid
                    // parser ambiguities like "... if case ... do ... end >= 0 do"
                    inline function requiresParen(expr: ElixirAST): Bool {
                        if (expr == null || expr.def == null) return false;
                        return switch (expr.def) {
                            case EIf(_, _, _): true;
                            case ECase(_, _): true;
                            case ECond(_): true;
                            case EWith(_, _, _): true;
                            case ETry(_, _, _, _, _): true;
                            // Receive has a do/end block as well
                            case EReceive(_, _): true;
                            default: false;
                        };
                    }

                    var leftOperand = requiresParen(cleanLeft) ? makeASTWithMeta(EParen(cleanLeft), cleanLeft.metadata, cleanLeft.pos) : cleanLeft;
                    var rightOperand = requiresParen(cleanRight) ? makeASTWithMeta(EParen(cleanRight), cleanRight.metadata, cleanRight.pos) : cleanRight;

                    return makeASTWithMeta(
                        EBinary(op, leftOperand, rightOperand),
                        e.metadata,
                        e.pos
                    );
                    
                case ECall(target, funcName, args):
                    #if debug_assignment_extraction
                    if (funcName == "reduce_while") {
                        trace('[XRay AssignmentExtraction] 🎯 Processing Enum.reduce_while call!');
                        trace('[XRay AssignmentExtraction] Args count: ${args.length}');
                        for (i in 0...args.length) {
                            trace('[XRay AssignmentExtraction] Arg $i type: ${Type.enumConstructor(args[i].def)}');
                            switch(args[i].def) {
                                case EMatch(_, _):
                                    trace('[XRay AssignmentExtraction] Found assignment in arg $i');
                                case EFn(clauses):
                                    trace('[XRay AssignmentExtraction] 🔥 Found anonymous function in arg $i with ${clauses.length} clauses');
                                    if (clauses.length > 0) {
                                        trace('[XRay AssignmentExtraction] First clause body type: ${Type.enumConstructor(clauses[0].body.def)}');
                                    }
                                default:
                            }
                        }
                    }
                    #end
                    var cleanTarget = target != null ? extractFromExpr(target, false) : null;
                    var cleanArgs = [for (a in args) extractFromExpr(a, false)];
                    
                    return makeASTWithMeta(
                        ECall(cleanTarget, funcName, cleanArgs),
                        e.metadata,
                        e.pos
                    );
                    
                case ERemoteCall(module, funcName, args):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing remote call: ${funcName}');
                    if (funcName == "reduce_while") {
                        trace('[XRay AssignmentExtraction] 🎯 Found Enum.reduce_while!');
                        for (i in 0...args.length) {
                            trace('[XRay AssignmentExtraction] Arg $i type: ${Type.enumConstructor(args[i].def)}');
                        }
                    }
                    #end
                    var cleanModule = extractFromExpr(module, false);
                    var cleanArgs = [for (a in args) extractFromExpr(a, false)];
                    
                    return makeASTWithMeta(
                        ERemoteCall(cleanModule, funcName, cleanArgs),
                        e.metadata,
                        e.pos
                    );
                    
                case EIf(condition, thenBranch, elseBranch):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing if condition');
                    trace('[XRay AssignmentExtraction] Condition type: ${Type.enumConstructor(condition.def)}');
                    #end
                    
                    // Extract assignments from the condition
                    var cleanCondition = extractFromExpr(condition, false);
                    var cleanThen = extractFromExpr(thenBranch, true);
                    var cleanElse = elseBranch != null ? extractFromExpr(elseBranch, true) : null;
                    
                    return makeASTWithMeta(
                        EIf(cleanCondition, cleanThen, cleanElse),
                        e.metadata,
                        e.pos
                    );
                    
                case EParen(inner):
                    // First extract from the inner expression
                    var cleanInner = extractFromExpr(inner, inStmtContext);
                    
                    // If we extracted assignments, don't wrap in parentheses anymore
                    // since the extracted assignments need to be at statement level
                    if (extracted.length > 0) {
                        return cleanInner;
                    } else {
                        return makeASTWithMeta(
                            EParen(cleanInner),
                            e.metadata,
                            e.pos
                        );
                    }
                    
                case EFn(clauses):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing anonymous function with ${clauses.length} clauses');
                    #end
                    
                    // Process each clause body for assignments
                    var cleanClauses = [];
                    for (clause in clauses) {
                        #if debug_assignment_extraction
                        trace('[XRay AssignmentExtraction] Processing clause body type: ${Type.enumConstructor(clause.body.def)}');
                        #end
                        
                        // Extract assignments from the clause body
                        var result = extractAndTransformExpression(clause.body);
                        
                        if (result.hasExtracted) {
                            #if debug_assignment_extraction
                            trace('[XRay AssignmentExtraction] Extracted ${result.extracted.length} assignments from fn clause');
                            #end
                            
                            // Create a block with extracted assignments followed by the cleaned expression
                            var statements = result.extracted.copy();
                            statements.push(result.expression);
                            var cleanBody = makeAST(EBlock(statements));
                            
                            cleanClauses.push({
                                args: clause.args,
                                guard: clause.guard,
                                body: cleanBody
                            });
                        } else {
                            // Even if no top-level extractions, the body might have been cleaned internally
                            cleanClauses.push({
                                args: clause.args,
                                guard: clause.guard,
                                body: result.expression  // Use the cleaned expression
                            });
                        }
                    }
                    
                    return makeASTWithMeta(
                        EFn(cleanClauses),
                        e.metadata,
                        e.pos
                    );
                    
                case EBlock(statements):
                    #if debug_assignment_extraction
                    trace('[XRay AssignmentExtraction] Processing EBlock in expression context with ${statements.length} statements');
                    for (i in 0...statements.length) {
                        trace('[XRay AssignmentExtraction] Statement $i: ${Type.enumConstructor(statements[i].def)}');
                    }
                    var inStatementContext = inStmtContext; // honor caller-provided context for expression vs statement
                    trace('[XRay AssignmentExtraction] Block is in statement context (from caller): $inStatementContext');
                    #end
                    
                    // Only extract assignments if we're NOT in a statement context
                    // In statement contexts (like case clause bodies), preserve the block as-is
                    // Peephole (works in both expression and statement contexts):
                    // Concat + inline binding + immediate method call
                    // Pattern:
                    //   [ ts = left <> (tmp = DateTime.utc_now()), tmp.to_iso8601() ]
                    // Rewrite to:
                    //   ts = left <> DateTime.to_iso8601(DateTime.utc_now())
                    if (statements.length == 2) {
                        switch (statements[0].def) {
                            case EMatch(PVar(assignName), concatExpr):
                                switch (concatExpr.def) {
                                    case EBinary(StringConcat, leftExpr, rightExpr):
                                        switch (rightExpr.def) {
                                            case EMatch(PVar(tmpVar), tmpValue):
                                                // Check second statement: tmpVar.method()
                                                switch (statements[1].def) {
                                                    case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0)):
                                                        // Detect DateTime.utc_now() on the RHS to build DateTime.to_iso8601(tmpValue)
                                                        switch (tmpValue.def) {
                                                            case ERemoteCall({def: EVar(modName)}, fnName, args) if (modName == "DateTime" && fnName == "utc_now"):
                                                                var moduleNode = makeAST(EVar("DateTime"));
                                                                var converted = makeAST(ERemoteCall(moduleNode, methodName, [tmpValue]));
                                                                var newConcat = makeAST(EBinary(StringConcat, extractFromExpr(leftExpr, false), converted));
                                                                // Rebuild the assignment and return a single-node block if we are in statement context
                                                                var newAssign = makeASTWithMeta(EMatch(PVar(assignName), newConcat), statements[0].metadata, statements[0].pos);
                                                                return inStmtContext ? makeAST(EBlock([newAssign])) : newAssign;
                                                            default:
                                                        }
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                    }

                    if (!isInStatementContext(e)) {
                        // Peephole: Inline simple bind-then-use blocks inside expression contexts
                        // Pattern: [x = <value>, <expr-using-x>] -> substitute <value> into <expr-using-x>
                        if (statements.length == 2) {
                            switch (statements[0].def) {
                                case EMatch(PVar(varName), assignedValue):
                                    // Clean the assigned value first (may extract deeper assignments)
                                    var cleanAssigned = extractFromExpr(assignedValue, false);
                                    var inlinedSecond = substituteVar(statements[1], varName, cleanAssigned);
                                    return extractFromExpr(inlinedSecond, inStmtContext);
                                default:
                                    // Fall through to generic extraction
                                    null;
                            }
                        }

                        // Peephole: Concat + inline binding + immediate method call
                        // Pattern:
                        //   [ ts = left <> (tmp = DateTime.utc_now()), tmp.to_iso8601() ]
                        // Rewrite to:
                        //   ts = left <> DateTime.to_iso8601(DateTime.utc_now())
                        if (statements.length == 2) {
                            switch (statements[0].def) {
                                case EMatch(PVar(assignName), concatExpr):
                                    switch (concatExpr.def) {
                                        case EBinary(StringConcat, leftExpr, rightExpr):
                                            switch (rightExpr.def) {
                                                case EMatch(PVar(tmpVar), tmpValue):
                                                    // Check second statement: tmpVar.method()
                                                    switch (statements[1].def) {
                                                        case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0)):
                                                            // Detect DateTime.utc_now() on the RHS to build DateTime.to_iso8601(tmpValue)
                                                            switch (tmpValue.def) {
                                                                case ERemoteCall({def: EVar(modName)}, fnName, args) if (modName == "DateTime" && fnName == "utc_now"):
                                                                    var moduleNode = makeAST(EVar("DateTime"));
                                                                    var converted = makeAST(ERemoteCall(moduleNode, methodName, [tmpValue]));
                                                                    var newConcat = makeAST(EBinary(StringConcat, extractFromExpr(leftExpr, false), converted));
                                                                    return makeASTWithMeta(EMatch(PVar(assignName), newConcat), statements[0].metadata, statements[0].pos);
                                                                default:
                                                            }
                                                        default:
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                default:
                            }
                        }
                        // Generic case: if the first statement is an assignment, hoist it
                        if (statements.length == 2) {
                            var first = statements[0];
                            var isAssign = switch (first.def) {
                                case EMatch(_, _): true;
                                case EBinary(Match, _, _): true;
                                default: false;
                            };
                            if (isAssign) {
                                extracted.push(first);
                                return extractFromExpr(statements[1], inStmtContext);
                            }
                        }
                    } else {
                        #if debug_assignment_extraction
                        trace('[XRay AssignmentExtraction] Block is in statement context - preserving all statements');
                        #end
                    }
                    
                    // General block processing
                    // First, combine adjacent concat+bind with immediate method call patterns
                    var combinedStatements = [];
                    var i = 0;
                    while (i < statements.length) {
                        var current = statements[i];
                        var nextStmt = (i + 1 < statements.length) ? statements[i + 1] : null;
                        var combined = false;
                        switch (current.def) {
                            case EMatch(PVar(assignName), concatExpr):
                                switch (concatExpr.def) {
                                    case EBinary(StringConcat, leftExpr, rightExpr):
                                        switch (rightExpr.def) {
                                            case EMatch(PVar(tmpVar), tmpValue):
                                                switch (nextStmt != null ? nextStmt.def : null) {
                                                    case ECall({def: EVar(callVar)}, methodName, callArgs) if (callVar == tmpVar && (callArgs == null || callArgs.length == 0)):
                                                        switch (tmpValue.def) {
                                                            case ERemoteCall({def: EVar(modName)}, fnName, args) if (modName == "DateTime" && fnName == "utc_now"):
                                                                var moduleNode = makeAST(EVar("DateTime"));
                                                                var converted = makeAST(ERemoteCall(moduleNode, methodName, [tmpValue]));
                                                                var newConcat = makeAST(EBinary(StringConcat, extractFromExpr(leftExpr, false), converted));
                                                                var newAssign = makeASTWithMeta(EMatch(PVar(assignName), newConcat), current.metadata, current.pos);
                                                                combinedStatements.push(newAssign);
                                                                i += 2; // Skip next statement
                                                                combined = true;
                                                            default:
                                                        }
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            default:
                        }
                        if (!combined) {
                            combinedStatements.push(current);
                            i++;
                        }
                    }

                    // If in expression context, hoist all non-last statements (assignments or otherwise)
                    if (!inStmtContext) {
                        if (combinedStatements.length == 0) return makeAST(ENil);
                        // Hoist all but last
                        for (i in 0...(combinedStatements.length - 1)) {
                            var s = combinedStatements[i];
                            extracted.push(extractFromExpr(s, true));
                        }
                        // The condition/value is the last expression
                        return extractFromExpr(combinedStatements[combinedStatements.length - 1], false);
                    }

                    // Statement context: retain block structure but still clean internals
                    var cleanStatements = [];
                    for (i in 0...combinedStatements.length) {
                        var stmt = combinedStatements[i];
                        var isLast = (i == combinedStatements.length - 1);
                        if (isLast) {
                            var cleanStmt = extractFromExpr(stmt, inStmtContext);
                            cleanStatements.push(cleanStmt);
                        } else {
                            switch(stmt.def) {
                                case EMatch(_, _) | EBinary(Match, _, _):
                                    var cleanStmt = extractFromExpr(stmt, inStmtContext);
                                default:
                                    cleanStatements.push(extractFromExpr(stmt, inStmtContext));
                            }
                        }
                    }

                    if (cleanStatements.length == 1) {
                        return cleanStatements[0];
                    } else if (cleanStatements.length == 0) {
                        return makeAST(ENil);
                    } else {
                        return makeASTWithMeta(EBlock(cleanStatements), e.metadata, e.pos);
                    }
                    
                default:
                    return e;
            }
        }
        
        var cleanExpr = extractFromExpr(expr);
        
        #if debug_assignment_extraction
        if (extracted.length > 0) {
            trace('[XRay AssignmentExtraction] ✅ Extracted ${extracted.length} assignments from expression');
            for (i in 0...extracted.length) {
                trace('[XRay AssignmentExtraction] Extracted[$i]: ${Type.enumConstructor(extracted[i].def)}');
            }
            trace('[XRay AssignmentExtraction] Cleaned expression: ${Type.enumConstructor(cleanExpr.def)}');
        }
        #end
        
        return {
            extracted: extracted,
            expression: cleanExpr,
            hasExtracted: extracted.length > 0
        };
    }
}
