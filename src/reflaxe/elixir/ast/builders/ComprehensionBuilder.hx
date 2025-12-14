package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.context.BuildContext;
using reflaxe.elixir.ast.NameUtils;
using StringTools;

/**
 * ComprehensionBuilder: Array/List Comprehension Reconstruction
 * 
 * WHY: Haxe desugars array comprehensions (map/filter) into imperative loops.
 * We need to reconstruct idiomatic Elixir `for` comprehensions from these patterns.
 * This centralized module handles all comprehension detection and reconstruction.
 * 
 * WHAT: Core comprehension capabilities
 * - Detects desugared array.map/filter patterns
 * - Reconstructs Elixir `for` comprehensions
 * - Handles unrolled constant-range loops
 * - Processes conditional comprehensions with filters
 * - Manages nested comprehensions recursively
 * 
 * HOW: Pattern matching on AST structure
 * - Analyzes TypedExpr blocks for comprehension patterns
 * - Extracts loop variables, iterators, and bodies
 * - Builds idiomatic Elixir comprehension AST nodes
 * - Handles both simple and complex nested patterns
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles comprehension reconstruction
 * - Open/Closed: Easy to add new comprehension patterns
 * - Testability: Isolated comprehension logic
 * - Maintainability: Clear separation from other concerns
 * - Performance: Optimized pattern detection
 * 
 * EDGE CASES:
 * - Nested comprehensions within comprehensions
 * - Unrolled loops with constant ranges
 * - Conditional comprehensions with filtering
 * - Mixed imperative and functional patterns
 * - Variable shadowing in nested scopes
 */
@:nullSafety(Off)
class ComprehensionBuilder {
    
    // ================================================================
    // Main Entry Point
    // ================================================================
    
    /**
     * Try to build an array comprehension from a desugared block
     * 
     * WHY: Haxe desugars array.map/filter into imperative loops with push
     * WHAT: Reconstructs idiomatic Elixir `for` comprehensions
     * HOW: Detects patterns and builds appropriate comprehension AST
     * 
     * This function detects these patterns and reconstructs idiomatic Elixir `for` comprehensions
     */
    public static function tryBuildArrayComprehensionFromBlock(statements: Array<TypedExpr>, context: BuildContext): Null<ElixirAST> {
        if (statements.length < 2) return null;
        
        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension] tryBuildArrayComprehensionFromBlock called with ${statements.length} statements');
        #end
        #end
        
        // Use our pattern detection functions
        if (isComprehensionPattern(statements)) {
            #if debug_array_comprehension
            #if debug_ast_builder
            // DISABLED: trace('[Array Comprehension] Detected loop-with-push comprehension pattern');
            #end
            #end
            
            var data = extractComprehensionData(statements);
            if (data != null) {
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension] Extracted data - tempVar: ${data.tempVar}, loopVar: ${data.loopVar}');
                #end
                #end
                
                // Helper to build a value and prefer nested comprehensions when canonical
                function buildPossiblyNested(value: TypedExpr): ElixirAST {
                    switch (value.expr) {
                        case TBlock(stmts):
                            // Prefer strict nested reconstruction when the inner block is a
                            // canonical list-building shape (var g=[]; g = g ++ [...]; g)
                            if (looksLikeListBuildingBlock(stmts)) {
                                var nested = tryBuildArrayComprehensionFromBlock(stmts, context);
                                if (nested != null) return nested;
                            } else {
                                // Even if not strictly canonical, attempt nested reconstruction
                                var attempt = tryBuildArrayComprehensionFromBlock(stmts, context);
                                if (attempt != null) return attempt;
                                // Fallback: synthesize a list literal via loose extraction
                                var loose = extractListElementsLoose(stmts, context);
                                if (loose != null && loose.length > 0) return makeAST(EList(loose));
                            }
                            return context.getExpressionBuilder()(value);
                        case TCall(f, args) if (args.length == 0):
                            var iifeStmts = extractListBlockFromIIFE(value);
                            if (iifeStmts != null) {
                                if (looksLikeListBuildingBlock(iifeStmts)) {
                                    var nestedIIFE = tryBuildArrayComprehensionFromBlock(iifeStmts, context);
                                    if (nestedIIFE != null) return nestedIIFE;
                                    var looseIIFE = extractListElementsLoose(iifeStmts, context);
                                    if (looseIIFE != null && looseIIFE.length > 0) return makeAST(EList(looseIIFE));
                                } else {
                                    var attemptIIFE = tryBuildArrayComprehensionFromBlock(iifeStmts, context);
                                    if (attemptIIFE != null) return attemptIIFE;
                                }
                            }
                            return context.getExpressionBuilder()(value);
                        case TArrayDecl([inner]) if (switch (inner.expr) { case TBlock(_): true; default: false; }):
                            // Single-element array whose element is a list-building block.
                            // Reconstruct the inner block as a comprehension returning the list,
                            // then wrap it back into a list literal so the outer comprehension
                            // yields a list-of-lists deterministically.
                            var innerStmts = switch (inner.expr) { case TBlock(s): s; default: []; };
                            var innerBuilt = tryBuildArrayComprehensionFromBlock(innerStmts, context);
                            if (innerBuilt != null) {
                                return makeAST(EList([innerBuilt]));
                            }
                            return context.getExpressionBuilder()(value);
                        case TArrayDecl([inner2]) if (switch (inner2.expr) { case TCall(_, _): true; default: false; }):
                            var iifeStmts2 = extractListBlockFromIIFE(inner2);
                            if (iifeStmts2 != null) {
                                var nested2 = tryBuildArrayComprehensionFromBlock(iifeStmts2, context);
                                if (nested2 != null) return makeAST(EList([nested2]));
                                var loose2 = extractListElementsLoose(iifeStmts2, context);
                                if (loose2 != null && loose2.length > 0) return makeAST(EList([makeAST(EList(loose2))]));
                            }
                            return context.getExpressionBuilder()(value);
                        default:
                            return context.getExpressionBuilder()(value);
                    }
                }

                // Build the comprehension body with conditional filtering support and nested detection
                var body = if (data.condition != null) {
                    // Handle conditional push (filter pattern)
                    buildPossiblyNested(data.body);
                } else {
                    buildPossiblyNested(data.body);
                };
                
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension] Building EFor comprehension');
                #end
                #end
                
                // Build the EFor comprehension with optional filtering
                var filters = data.condition != null ? [context.getExpressionBuilder()(data.condition)] : [];
                return makeAST(EFor(
                    [{
                        pattern: PVar(data.loopVar),
                        expr: context.getExpressionBuilder()(data.iterator)
                    }],
                    filters,
                    body,
                    null,  // into: null for list comprehension
                    false  // uniq: false
                ));
            }
        }
        
        // Check for unrolled comprehension pattern
        if (isUnrolledComprehension(statements)) {
            #if debug_array_comprehension
            #if debug_ast_builder
            // DISABLED: trace('[Array Comprehension] Detected unrolled comprehension pattern');
            #end
            #end
            
            var elements = extractUnrolledElements(statements, context);
            if (elements != null && elements.length > 0) {
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension] Successfully extracted ${elements.length} unrolled elements');
                #end
                #end
                
                // Return as a list literal for now.
                // Note: this could potentially be reconstructed as a comprehension with a constant range.
                return makeAST(EList(elements));
            }
        }
        
        // Check for conditional comprehension pattern
        // This handles complex patterns where the condition is in a separate TBlock
        if (statements.length >= 3) {
            // Look for: var g = []; TBlock([if statements]); g
            var firstStmt = unwrapMetaParens(statements[0]);
            var lastStmt = unwrapMetaParens(statements[statements.length - 1]);
            
            // Check initialization
            switch(firstStmt.expr) {
                case TVar(v, {expr: TArrayDecl([])}):
                    // Check if last statement returns the temp var
                    switch(lastStmt.expr) {
                        case TLocal(returnVar) if (returnVar.name == v.name):
                            // Try to reconstruct from the middle statements
                            var middleStmts = statements.slice(1, statements.length - 1);
                            var result = tryReconstructConditionalComprehension(middleStmts, v.name, context);
                            if (result != null) {
                                #if debug_array_comprehension
                                #if debug_ast_builder
                                // DISABLED: trace('[Array Comprehension] Successfully reconstructed conditional comprehension');
                                #end
                                #end
                                return result;
                            }
                            // Fallback: scan middle for any TBlock that contains a for-loop pushing into v
                            for (mid in middleStmts) {
                                switch (unwrapMetaParens(mid).expr) {
                                    case TBlock(inner):
                                        for (s in inner) switch (unwrapMetaParens(s).expr) {
                                            case TFor(loopVar, iterator, body):
                                                var push = extractPushFromBody(body, v.name);
                                                if (push != null) {
                                                    #if debug_array_comprehension
                                                    #if debug_ast_builder
                                                    // DISABLED: trace('[Array Comprehension] Fallback: building EFor from scanned middle TBlock with loopVar=' + loopVar.name);
                                                    #end
                                                    #end
                                                    var filters = push.condition != null ? [context.getExpressionBuilder()(push.condition)] : [];
                                                    var valueAst = (function() {
                                                        switch (push.value.expr) {
                                                            case TBlock(nested) if (looksLikeListBuildingBlock(nested)):
                                                                var nestedComp = tryBuildArrayComprehensionFromBlock(nested, context);
                                                                if (nestedComp != null) return nestedComp;
                                                                var loose = extractListElementsLoose(nested, context);
                                                                return (loose != null && loose.length > 0) ? makeAST(EList(loose)) : context.getExpressionBuilder()(push.value);
                                                            default:
                                                                return context.getExpressionBuilder()(push.value);
                                                        }
                                                    })();
                                                    return makeAST(EFor([
                                                        { pattern: PVar(loopVar.name), expr: context.getExpressionBuilder()(iterator) }
                                                    ], filters, valueAst, null, false));
                                                }
                                            default:
                                        }
                                    default:
                                }
                            }
                        default:
                    }
                default:
            }
        }
        
        return null;
    }
    
    // ================================================================
    // Pattern Detection Functions
    // ================================================================
    
    /**
     * Check if statements match the comprehension pattern
     * 
     * WHY: Need to identify desugared array.map/filter patterns
     * WHAT: Checks for var _g = []; for(...) _g.push(...); _g pattern
     * HOW: Structural pattern matching without hardcoding variable names
     */
    static function isComprehensionPattern(statements: Array<TypedExpr>): Bool {
        if (statements.length < 3) return false;
        
        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension Detection] Checking ${statements.length} statements for comprehension pattern');
        #end
        #end
        
        var firstStmt = unwrapMetaParens(statements[0]);
        var lastStmt = unwrapMetaParens(statements[statements.length - 1]);
        
        // Check first statement: var _g = []
        var tempVarName: String = null;
        switch(firstStmt.expr) {
            case TVar(v, {expr: TArrayDecl([])}):
                tempVarName = v.name;
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension Detection] Found array initialization: var ${tempVarName} = []');
                #end
                #end
            default:
                return false;
        }
        
        // Check last statement: returns the temp var
        switch(lastStmt.expr) {
            case TLocal(v) if (v.name == tempVarName):
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension Detection] Last statement returns temp var: ${tempVarName}');
                #end
                #end
                // Continue checking middle statements
            default:
                return false;
        }
        
        // Check middle statements for loop with push
        for (i in 1...statements.length - 1) {
            var stmt = unwrapMetaParens(statements[i]);
            switch(stmt.expr) {
                case TFor(_, _, _) | TWhile(_, _, _):
                    #if debug_array_comprehension
                    #if debug_ast_builder
                    // DISABLED: trace('[Array Comprehension Detection] Found loop statement');
                    #end
                    #end
                    return true; // Found a loop, likely a comprehension pattern
                default:
            }
        }
        
        return false;
    }
    
    /**
     * Check if statements match unrolled comprehension pattern
     *
     * WHY: Haxe unrolls constant-range loops into sequential concatenations
     * WHAT: Detects BOTH old pattern (var g = []; g = g ++ [val]) AND new pattern (doubled = n = 1; [] ++ [n * 2])
     * HOW: Tries multiple detection strategies:
     *      1. Legacy pattern: var g = []; g = g ++ [val]; ... g
     *      2. New pattern: result = n = 1; [] ++ [n * 2]; n = 2; ... []
     *
     * EDGE CASES:
     * - Conditional comprehensions with if statements
     * - Both patterns can appear depending on Haxe optimization level
     */
    static function isUnrolledComprehension(statements: Array<TypedExpr>): Bool {
        if (statements.length < 3) return false;

        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension Detection] Checking for unrolled comprehension (${statements.length} statements)');
        #end
        #end

        // Try legacy pattern first (var g = []; g = g ++ [val]; g)
        if (isLegacyUnrolledComprehension(statements)) {
            #if debug_array_comprehension
            #if debug_ast_builder
            // DISABLED: trace('[Array Comprehension Detection] ✓ Matched legacy pattern');
            #end
            #end
            return true;
        }

        // Try new pattern (result = n = 1; [] ++ [n * 2]; n = 2; ...)
        if (isChainedAssignmentComprehension(statements)) {
            #if debug_array_comprehension
            #if debug_ast_builder
            // DISABLED: trace('[Array Comprehension Detection] ✓ Matched chained assignment pattern');
            #end
            #end
            return true;
        }

        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension Detection] ✗ No pattern matched');
        #end
        #end
        return false;
    }

    /**
     * Detect legacy unrolled comprehension pattern: var g = []; g = g ++ [val]; g
     */
    static function isLegacyUnrolledComprehension(statements: Array<TypedExpr>): Bool {
        var firstStmt = unwrapMetaParens(statements[0]);
        var lastStmt = unwrapMetaParens(statements[statements.length - 1]);

        // Check first statement: var _g = []
        var tempVarName: String = null;
        switch(firstStmt.expr) {
            case TVar(v, {expr: TArrayDecl([])}):
                tempVarName = v.name;
            default:
                return false;
        }

        // Check last statement: returns the temp var
        switch(lastStmt.expr) {
            case TLocal(v) if (v.name == tempVarName):
                // Continue checking
            default:
                return false;
        }

        // Check middle statements for concatenation pattern
        var hasConcatenation = false;
        for (i in 1...statements.length - 1) {
            var stmt = unwrapMetaParens(statements[i]);
            switch(stmt.expr) {
                case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, _) if (v.name == tempVarName):
                    hasConcatenation = true;
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, _)}) if (v.name == tempVarName):
                    hasConcatenation = true;
                case TIf(_, _, _):
                    // Could be conditional concatenation inside
                    hasConcatenation = true;
                default:
            }
        }

        return hasConcatenation;
    }

    /**
     * Detect new chained assignment pattern: result = n = 1; [] ++ [n * 2]; n = 2; ...
     *
     * WHY: Haxe's compile-time evaluation generates chained assignments
     * WHAT: Detects pattern where comprehension is unrolled into chained assignments and bare concatenations
     * HOW: Checks for:
     *      - First: Chained assignment (doubled = n = val)
     *      - Middle: Loop variable reassignments (n = 2, n = 3) OR bare concatenations ([] ++ [expr])
     *      - Last: Empty array ([])
     */
    static function isChainedAssignmentComprehension(statements: Array<TypedExpr>): Bool {
        if (statements.length < 3) return false;

        var firstStmt = unwrapMetaParens(statements[0]);
        var lastStmt = unwrapMetaParens(statements[statements.length - 1]);

        // Check first: Chained assignment (doubled = n = 1)
        var hasChainedAssignment = switch(firstStmt.expr) {
            case TBinop(OpAssign, {expr: TLocal(_)}, {expr: TBinop(OpAssign, {expr: TLocal(_)}, _)}):
                true;
            default:
                false;
        };

        if (!hasChainedAssignment) return false;

        // Check last: Empty array
        var endsWithEmptyArray = switch(lastStmt.expr) {
            case TArrayDecl([]): true;
            default: false;
        };

        if (!endsWithEmptyArray) return false;

        // Check middle: Should have bare concatenations ([] ++ [expr]) or loop var assignments
        var hasBareConcat = false;
        for (i in 1...statements.length - 1) {
            var stmt = unwrapMetaParens(statements[i]);
            switch(stmt.expr) {
                // Bare concatenation: [] ++ [expr]
                case TBinop(OpAdd, {expr: TArrayDecl([])}, {expr: TArrayDecl(_)}):
                    hasBareConcat = true;
                // Loop variable reassignment: n = 2
                case TBinop(OpAssign, {expr: TLocal(_)}, _):
                    // This is fine - loop variable updates
                default:
            }
        }

        return hasBareConcat;
    }
    
    /**
     * Check if a block looks like it's building a list through concatenations
     * 
     * WHY: Nested comprehensions create blocks that build lists
     * WHAT: Detects blocks that represent unrolled comprehensions
     * HOW: Checks for initialization + concatenations + return pattern
     */
    public static function looksLikeListBuildingBlock(stmts: Array<TypedExpr>): Bool {
        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension Detection] Checking block with ${stmts.length} statements');
        #end
        #end
        
        if (stmts.length < 3) return false;
        
        var firstStmt = unwrapMetaParens(stmts[0]);
        var lastStmt = unwrapMetaParens(stmts[stmts.length - 1]);
        
        // Check for: var g = []; ... ; g  OR  g = []; ... ; g
        var tempVar: String = null;
        switch(firstStmt.expr) {
            case TVar(v, {expr: TArrayDecl([])}):
                tempVar = v.name;
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension Detection] Found list init: var ${tempVar} = []');
                #end
                #end
            case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TArrayDecl([])}):
                tempVar = v.name;
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension Detection] Found list init: ${tempVar} = []');
                #end
                #end
            default:
                return false;
        }
        
        // Check if last statement returns the temp var
        switch(lastStmt.expr) {
            case TLocal(v) if (v.name == tempVar):
                #if debug_array_comprehension
                #if debug_ast_builder
                // DISABLED: trace('[Array Comprehension Detection] Block returns temp var ${tempVar}');
                #end
                #end
                // Check middle statements for concatenations
                for (i in 1...stmts.length - 1) {
                    var stmt = unwrapMetaParens(stmts[i]);
                    switch(stmt.expr) {
                        case TBinop(OpAdd, {expr: TLocal(v)}, _) if (v.name == tempVar):
                            #if debug_array_comprehension
                            #if debug_ast_builder
                            // DISABLED: trace('[Array Comprehension Detection] Found concatenation');
                            #end
                            #end
                            return true;
                        case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, _) if (v.name == tempVar):
                            #if debug_array_comprehension
                            #if debug_ast_builder
                            // DISABLED: trace('[Array Comprehension Detection] Found += concatenation');
                            #end
                            #end
                            return true;
                        default:
                    }
                }
            default:
        }
        
        return false;
    }
    
    // ================================================================
    // Data Extraction Functions
    // ================================================================
    
    /**
     * Extract comprehension data from matched pattern
     * 
     * WHY: Need structured data to build the comprehension
     * WHAT: Returns structured data about the comprehension
     * HOW: Pattern matches to extract relevant parts
     */
    static function extractComprehensionData(statements: Array<TypedExpr>): Null<{
        tempVar: String,
        loopVar: String,
        iterator: TypedExpr,
        body: TypedExpr,
        condition: Null<TypedExpr>
    }> {
        if (statements.length < 3) return null;
        
        var firstStmt = unwrapMetaParens(statements[0]);
        var tempVarName: String = null;
        
        // Get temp var name
        switch(firstStmt.expr) {
            case TVar(v, _):
                tempVarName = v.name;
            case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TArrayDecl([])}):
                tempVarName = v.name;
            default:
                return null;
        }
        
        // Find the loop statement
        for (i in 1...statements.length - 1) {
            var stmt = unwrapMetaParens(statements[i]);
            switch(stmt.expr) {
                case TFor(_, iterator, body):
                    // Check if body contains push to temp var
                    var pushData = extractPushFromBody(body, tempVarName);
                    if (pushData != null) {
                        var loopVar = switch(stmt.expr) {
                            case TFor(v, _, _): v.name;
                            default: "";
                        };
                        return {
                            tempVar: tempVarName,
                            loopVar: loopVar,
                            iterator: iterator,
                            body: pushData.value,
                            condition: pushData.condition
                        };
                    }
                case TWhile(_, body, _):
                    // Handle while loops that are actually for loops
                    // This is more complex and might need additional analysis
                    continue;
                default:
            }
        }
        
        return null;
    }
    
    /**
     * Extract push operation from loop body
     */
    public static function extractPushFromBody(body: TypedExpr, tempVar: String): Null<{value: TypedExpr, condition: Null<TypedExpr>}> {
        switch(body.expr) {
            case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, field))}, [value]) 
                if (v.name == tempVar && field.get().name == "push"):
                // Direct push
                return {value: value, condition: null};
            case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([value])})})
                if (v.name == tempVar && v2.name == tempVar):
                // Pattern: g = g ++ [value]
                return {value: value, condition: null};
            case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TArrayDecl([value])})
                if (v.name == tempVar):
                // Pattern: g += [value]
                return {value: value, condition: null};
                
            case TIf(condition, thenExpr, null):
                // Conditional push (filter pattern)
                var pushData = extractPushFromBody(thenExpr, tempVar);
                if (pushData != null) {
                    return {value: pushData.value, condition: condition};
                }
                
            case TBlock(stmts):
                // Check statements for push
                for (stmt in stmts) {
                    var pushData = extractPushFromBody(stmt, tempVar);
                    if (pushData != null) {
                        return pushData;
                    }
                }
                
            default:
        }
        return null;
    }
    
    /**
     * Extract elements from unrolled comprehension pattern
     * Handles both simple unrolled and conditional unrolled comprehensions
     */
    static function extractUnrolledElements(statements: Array<TypedExpr>, context: BuildContext): Null<Array<ElixirAST>> {
        if (statements.length < 3) return null;
        
        var tempVarName: String = null;
        var firstStmt = unwrapMetaParens(statements[0]);
        
        // Get temp var name
        switch(firstStmt.expr) {
            case TVar(v, _):
                tempVarName = v.name;
            default:
                return null;
        }
        
        var elements: Array<ElixirAST> = [];
        
        // Helper: build list AST from an inner block if it represents list-building
        inline function listFromBlock(blockStmts: Array<TypedExpr>): Null<ElixirAST> {
            // Prefer strict extractor
            var strictVals = extractListElements(blockStmts);
            if (strictVals != null && strictVals.length > 0) {
                var builtStrict = strictVals.map(v -> context.getExpressionBuilder()(v));
                return makeAST(EList(builtStrict));
            }
            // Try loose extractor (allows locals)
            var looseVals = extractListElementsLoose(blockStmts, context);
            if (looseVals != null && looseVals.length > 0) {
                return makeAST(EList(looseVals));
            }
            return null;
        }

        // Process middle statements
        for (i in 1...statements.length - 1) {
            var stmt = unwrapMetaParens(statements[i]);
            switch(stmt.expr) {
                case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TArrayDecl([value])}) if (v.name == tempVarName):
                    // g += [value]
                    // If the single element is a canonical inner list-building block, prefer nested comprehension
                    var built = switch (value.expr) {
                        case TBinop(OpAdd, l, r):
                            #if debug_array_comprehension
                            #if debug_ast_builder
                            // DISABLED: trace('[Array Comprehension] value is OpAdd inside unrolled element');
                            #end
                            #end
                            context.getExpressionBuilder()(value);
                        case TBlock(innerStmts):
                            var nested = tryBuildArrayComprehensionFromBlock(innerStmts, context);
                            if (nested != null) nested else (listFromBlock(innerStmts) != null ? listFromBlock(innerStmts) : context.getExpressionBuilder()(value));
                        default:
                            context.getExpressionBuilder()(value);
                    };
                    elements.push(built);
                
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([value])})}) 
                    if (v.name == tempVarName && v2.name == tempVarName):
                    // g = g ++ [value]
                    var built2 = switch (value.expr) {
                        case TBlock(innerStmts):
                            var nested2 = tryBuildArrayComprehensionFromBlock(innerStmts, context);
                            if (nested2 != null) nested2 else (listFromBlock(innerStmts) != null ? listFromBlock(innerStmts) : context.getExpressionBuilder()(value));
                        default:
                            context.getExpressionBuilder()(value);
                    };
                    elements.push(built2);
                
                case TIf(_, _, _):
                    // Conditional appends aren't safe to rewrite into a literal list; bail out.
                    return null;
                
                default:
            }
        }
        
        return elements.length > 0 ? elements : null;
    }
    
    /**
     * Try to reconstruct a conditional comprehension from a block
     * Pattern: var g = []; TBlock([if statements]); g
     * Reconstructs to: for i <- 0..9, rem(i, 2) == 0, do: i
     */
    public static function tryReconstructConditionalComprehension(statements: Array<TypedExpr>, tempVarName: String, context: BuildContext): Null<ElixirAST> {
        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension] tryReconstructConditionalComprehension called with ${statements.length} statements');
        #end
        #end
        
        if (statements.length == 0) return null;
        
        // Handle single TBlock statement containing conditional logic
        if (statements.length == 1) {
            switch(statements[0].expr) {
                case TBlock(innerStmts):
                    return tryReconstructConditionalComprehension(innerStmts, tempVarName, context);
                default:
            }
        }
        
        // Look for pattern: for loop with conditional concatenation
        for (stmt in statements) {
            switch(stmt.expr) {
                case TFor(_, iterator, body):
                    // Check if body contains conditional concatenation
                    var filterAndValue = extractConditionalConcatenation(body, tempVarName);
                    if (filterAndValue != null) {
                        #if debug_array_comprehension
                        #if debug_ast_builder
                        // DISABLED: trace('[Array Comprehension] Found conditional comprehension in for loop');
                        #end
                        #end
                        
                        var loopVarName = switch(stmt.expr) {
                            case TFor(v, _, _): v.name;
                            default: "";
                        };
                        return makeAST(EFor(
                            [{
                                pattern: PVar(loopVarName),
                                expr: context.getExpressionBuilder()(iterator)
                            }],
                            [context.getExpressionBuilder()(filterAndValue.condition)],
                            context.getExpressionBuilder()(filterAndValue.value),
                            null,  // into
                            false  // uniq
                        ));
                    }
                    
                case TWhile({expr: TBinop(OpLt, {expr: TLocal(indexVar)}, limit)}, body, _):
                    // While loop that's actually a for loop with index
                    // Look for initialization before the while
                    // This is complex and might need more context
                    continue;
                    
                default:
            }
        }
        
        return null;
    }
    
    /**
     * Extract conditional concatenation from a statement
     */
    static function extractConditionalConcatenation(stmt: TypedExpr, tempVarName: String): Null<{condition: TypedExpr, value: TypedExpr}> {
        switch(stmt.expr) {
            case TIf(condition, thenExpr, _):
                // Check if then branch contains concatenation
                switch(thenExpr.expr) {
                    case TBinop(OpAssignOp(OpAdd), {expr: TLocal(v)}, {expr: TArrayDecl([value])}) if (v.name == tempVarName):
                        return {condition: condition, value: value};
                    case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, _, {expr: TArrayDecl([value])})}) if (v.name == tempVarName):
                        return {condition: condition, value: value};
                    case TBlock(stmts):
                        // Recurse into block
                        for (s in stmts) {
                            var result = extractConditionalConcatenation(s, tempVarName);
                            if (result != null) return result;
                        }
                    default:
                }
            case TBlock(stmts):
                // Check statements
                for (s in stmts) {
                    var result = extractConditionalConcatenation(s, tempVarName);
                    if (result != null) return result;
                }
            default:
        }
        return null;
    }
    
    // ================================================================
    // List Element Extraction
    // ================================================================
    
    /**
     * Extract list elements from a list-building block
     * Returns the array of expressions that make up the list elements
     * 
     * WHY: When Haxe unrolls comprehensions, it creates blocks with bare concatenations
     * WHAT: Extracts the elements being concatenated and recursively processes nested blocks
     * HOW: Handles both direct concatenation (g ++ [val]) and assignment patterns (g = g ++ [val])
     *      Recursively processes nested blocks to handle deeply nested comprehensions
     * 
     * CRITICAL: Bare concatenations like `g ++ [0]` are NOT valid statements in Elixir!
     *           We must skip them or wrap them in assignments.
     */
    public static function extractListElements(stmts: Array<TypedExpr>): Null<Array<TypedExpr>> {
        if (!looksLikeListBuildingBlock(stmts)) return null;
        
        #if debug_array_comprehension
        #if debug_ast_builder
        // DISABLED: trace('[Array Comprehension] extractListElements: processing ${stmts.length} statements');
        #end
        #end
        
        var elements: Array<TypedExpr> = [];
        var encounteredUnsafe = false;

        inline function hasAnyLocal(e: TypedExpr): Bool {
            var found = false;
            function walk(te: TypedExpr): Void {
                if (found || te == null) return;
                switch (te.expr) {
                    case TLocal(_): found = true;
                    case TArrayDecl(arr): for (a in arr) walk(a);
                    case TBlock(bs): for (b in bs) walk(b);
                    case TBinop(_, l, r): walk(l); walk(r);
                    case TCall(t, args): walk(t); for (a in args) walk(a);
                    case TField(t, _): walk(t);
                    case TParenthesis(inner): walk(inner);
                    case TIf(c,t,eo): walk(c); walk(t); if (eo != null) walk(eo);
                    case TWhile(c,b,_): walk(c); walk(b);
                    case TFor(v, it, b): walk(it); walk(b);
                    case TMeta(_, inner): walk(inner);
                    default:
                }
            }
            walk(e);
            return found;
        }
        
        // Skip first (initialization) and last (return) statements
        for (i in 1...stmts.length - 1) {
            var stmt = unwrapMetaParens(stmts[i]);
            switch(stmt.expr) {
                case TBinop(OpAdd, {expr: TLocal(v)}, {expr: TArrayDecl([value])}) :
                    // Direct bare concatenation: g ++ [value]
                    // Extract the VALUE being concatenated, not the concatenation itself!
                    #if debug_array_comprehension
                    #if debug_ast_builder
                    // DISABLED: trace('[Array Comprehension] Found bare concatenation: ${v.name} ++ [value], extracting value');
                    #end
                    #end
                    // Check if the value itself is a block that builds a list
                    switch(value.expr) {
                        case TBlock(innerStmts) if (looksLikeListBuildingBlock(innerStmts)):
                            // Recursively extract elements from nested block
                            var nestedElements = extractListElements(innerStmts);
                            if (nestedElements != null && nestedElements.length > 0) {
                                // Create a proper list from the nested elements
                                var listExpr = {expr: TArrayDecl(nestedElements), pos: value.pos, t: value.t};
                                elements.push(listExpr);
                            } else {
                                elements.push(value);
                            }
                        default:
                            // IIFE returning a block that builds a list
                            var iifeInner = extractListBlockFromIIFE(value);
                            if (iifeInner != null && looksLikeListBuildingBlock(iifeInner)) {
                                var nestedIIFE = extractListElements(iifeInner);
                                if (nestedIIFE != null && nestedIIFE.length > 0) {
                                    var listExprIIFE = {expr: TArrayDecl(nestedIIFE), pos: value.pos, t: value.t};
                                    elements.push(listExprIIFE);
                                } else {
                                    elements.push(value);
                                }
                            } else {
                                // Avoid extracting values that reference inner locals (e.g., nested binders)
                                if (hasAnyLocal(value)) { encounteredUnsafe = true; } else elements.push(value);
                            }
                }
                case TBinop(OpAdd, _, {expr: TBlock(blockStmts)}):
                    // Direct concatenation with block: g ++ block
                    // Check if this block itself builds a list
                    if (looksLikeListBuildingBlock(blockStmts)) {
                        // Recursively extract elements
                        var nestedElements = extractListElements(blockStmts);
                        if (nestedElements != null && nestedElements.length > 0) {
                            // Create a proper list from the nested elements
                            var listExpr = {expr: TArrayDecl(nestedElements), pos: stmt.pos, t: stmt.t};
                            elements.push(listExpr);
                        } else {
                            elements.push({expr: TBlock(blockStmts), pos: stmt.pos, t: stmt.t});
                        }
                    } else {
                        // Not a list-building block, keep as-is
                        elements.push({expr: TBlock(blockStmts), pos: stmt.pos, t: stmt.t});
                    }
                case TBinop(OpAssign, _, rhs):
                    // Assignment: g = g ++ [value] or g = g ++ block
                    switch(rhs.expr) {
                        case TBinop(OpAdd, _, {expr: TArrayDecl([value])}):
                            // Check if the value itself is a block that builds a list
                            switch(value.expr) {
                                case TBlock(innerStmts) if (looksLikeListBuildingBlock(innerStmts)):
                                    // Recursively extract elements from nested block
                                    var nestedElements = extractListElements(innerStmts);
                                    if (nestedElements != null && nestedElements.length > 0) {
                                        // Create a proper list from the nested elements
                                        var listExpr = {expr: TArrayDecl(nestedElements), pos: value.pos, t: value.t};
                                        elements.push(listExpr);
                                    } else {
                                        elements.push(value);
                                    }
                                default:
                                    if (hasAnyLocal(value)) { encounteredUnsafe = true; } else elements.push(value);
                            }
                        case TBinop(OpAdd, _, {expr: TBlock(blockStmts)}):
                            // Assignment with block concatenation
                            if (looksLikeListBuildingBlock(blockStmts)) {
                                // Recursively extract elements
                                var nestedElements = extractListElements(blockStmts);
                                if (nestedElements != null && nestedElements.length > 0) {
                                    // Create a proper list from the nested elements
                                    var listExpr = {expr: TArrayDecl(nestedElements), pos: rhs.pos, t: rhs.t};
                                    elements.push(listExpr);
                                } else {
                                    elements.push({expr: TBlock(blockStmts), pos: rhs.pos, t: rhs.t});
                                }
                            } else {
                                elements.push({expr: TBlock(blockStmts), pos: rhs.pos, t: rhs.t});
                            }
                        default:
                    }
                default:
            }
        }
        
        if (encounteredUnsafe) return null;
        return elements;
    }

    /**
     * extractListElementsLoose
     *
     * WHAT
     * - Lenient extraction of list elements from a block that contains bare
     *   concatenation statements, even when the canonical "var g = []; ...; g"
     *   initialization/terminator pattern is missing or has been altered by
     *   downstream hygiene/underscore passes.
     *
     * WHY
     * - Some desugared nested comprehensions surface as sequences of
     *   concatenations where the accumulator variable initialization or the
     *   final reference has been optimized away or renamed (e.g. to `_`).
     *   Emitting those concatenations as statements produces invalid Elixir
     *   syntax. We must recover the intended list literal early.
     *
     * HOW
     * - Scan all statements and collect RHS values from patterns of the form:
     *     - g ++ [value]
     *     - g = g ++ [value]
     *     - g ++ (block) where block itself is a list-building block
     *     - g = g ++ (block) with nested list-building
     * - Recursively process nested blocks to construct list-of-lists when
     *   encountering inner list-building blocks.
     * - Return null if no elements can be extracted to avoid false positives.
     *
     * EXAMPLES
     * Haxe:
     *   [for (i in 0...2) [for (j in 0...2) i * 2 + j]]
     * Desugared (schematic):
     *   var g = [];
     *   g = g ++ [{ var g3 = []; g3 = g3 ++ [0]; g3 = g3 ++ [1]; g3 }];
     *   g = g ++ [{ var g3 = []; g3 = g3 ++ [2]; g3 = g3 ++ [3]; g3 }];
     *   g;
     * Loose extraction builds: [[0,1],[2,3]]
     */
    public static function extractListElementsLoose(stmts: Array<TypedExpr>, context: BuildContext): Null<Array<ElixirAST>> {
        var build = context.getExpressionBuilder();
        var out: Array<ElixirAST> = [];
        // NOTE: We deliberately allow local references (e.g., outer loop variable `i`) inside
        // values collected here. The loose extractor is only used to synthesize list literals
        // as elements within a larger expression, which is valid even with locals.

        for (stmt in stmts) {
            var s = unwrapMetaParens(stmt);
            switch (s.expr) {
                // Bare concatenation: g ++ [value]
                case TBinop(OpAdd, _, {expr: TArrayDecl([value])}):
                    out.push(build(value));
                // Bare concatenation with IIFE that returns a list-building block: g ++ ((fn -> ... end).())
                case TBinop(OpAdd, _, {expr: TCall(_, _) }):
                    var iifeSt = extractListBlockFromIIFE(s);
                    if (iifeSt != null) {
                        var nestedI = extractListElementsLoose(iifeSt, context);
                        if (nestedI != null && nestedI.length > 0) out.push(makeAST(EList(nestedI)));
                    }

                // Assignment with concatenation: g = g ++ [value]
                case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, {expr: TArrayDecl([value])})}):
                    out.push(build(value));
                // Assignment with IIFE: g = g ++ ((fn -> ... end).())
                case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, {expr: TCall(_, _)})}):
                    var iifeSt2 = extractListBlockFromIIFE(s);
                    if (iifeSt2 != null) {
                        var nestedI2 = extractListElementsLoose(iifeSt2, context);
                        if (nestedI2 != null && nestedI2.length > 0) out.push(makeAST(EList(nestedI2)));
                    }

                // Bare concatenation with nested block: g ++ (block)
                case TBinop(OpAdd, _, {expr: TBlock(blockStmts)}):
                    var nested: Null<Array<ElixirAST>> = null;
                    // Prefer strict extractor when shape is canonical; otherwise recurse loosely
                    if (looksLikeListBuildingBlock(blockStmts)) {
                        var nestedValues = extractListElements(blockStmts);
                        if (nestedValues != null) {
                            var built = nestedValues.map(v -> build(v));
                            nested = built;
                        }
                    }
                    if (nested == null) {
                        nested = extractListElementsLoose(blockStmts, context);
                    }
                    if (nested != null && nested.length > 0) {
                        out.push(makeAST(EList(nested)));
                    } else {
                        out.push(makeAST(EBlock(blockStmts.map(e -> build(e)))));
                    }

                // Assignment with concatenation and nested block: g = g ++ (block)
                case TBinop(OpAssign, _, {expr: TBinop(OpAdd, _, {expr: TBlock(blockStmts)})}):
                    var nested2: Null<Array<ElixirAST>> = null;
                    if (looksLikeListBuildingBlock(blockStmts)) {
                        var nestedValues2 = extractListElements(blockStmts);
                        if (nestedValues2 != null) {
                            var built2 = nestedValues2.map(v -> build(v));
                            nested2 = built2;
                        }
                    }
                    if (nested2 == null) {
                        nested2 = extractListElementsLoose(blockStmts, context);
                    }
                    if (nested2 != null && nested2.length > 0) {
                        out.push(makeAST(EList(nested2)));
                    } else {
                        out.push(makeAST(EBlock(blockStmts.map(e -> build(e)))));
                    }

                // Recurse into nested blocks if present as standalone statements
                case TBlock(blockStmts):
                    var nested3 = extractListElementsLoose(blockStmts, context);
                    if (nested3 != null && nested3.length > 0) {
                        out.push(makeAST(EList(nested3)));
                    }

                default:
            }
        }

        return out.length > 0 ? out : null;
    }
    
    // ================================================================
    // Helper Functions
    // ================================================================
    
    /**
     * Unwrap TMeta nodes with :mergeBlock or :implicitReturn
     * These are compiler-added metadata that we need to look through
     */
    static function unwrapMetaParens(expr: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            case TMeta({name: ":mergeBlock" | ":implicitReturn"}, e) | TParenthesis(e):
                unwrapMetaParens(e);
            default:
                expr;
        }
    }

    /**
     * Extract statements from an immediately-invoked anonymous function
     * returning a block. Pattern: (fn -> <TBlock> end)()
     */
    static function extractListBlockFromIIFE(expr: TypedExpr): Null<Array<TypedExpr>> {
        return switch (expr.expr) {
            case TCall(f, args) if (args.length == 0):
                switch (unwrapMetaParens(f).expr) {
                    case TFunction(tf):
                        switch (tf.expr.expr) {
                            case TBlock(stmts): stmts;
                            default: null;
                        }
                    default: null;
                }
            default: null;
        }
    }
}

#end
