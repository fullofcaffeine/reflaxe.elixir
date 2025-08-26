#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Type.TVar;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.PatternMatchingCompiler.FunctionContext;
using StringTools;

/**
 * ExpressionVariantCompiler: Specialized expression compilation variations for complex patterns
 * 
 * WHY: ElixirCompiler contained 10+ specialized expression compilation methods (400-500 lines)
 *      that handle variations of the main compileExpression logic. These methods created
 *      maintenance complexity by mixing core compilation with specialized pattern handling.
 *      Centralized extraction improves code organization and enables focused testing.
 * 
 * WHAT: Provides specialized expression compilation methods for complex scenarios:
 * - Type-aware expression compilation with string concatenation handling
 * - TVar object-based variable substitution for precise variable mapping
 * - Switch expression compilation with pattern matching support
 * - Block expression handling with context preservation
 * - Mutation tracking for imperative-to-functional transformations
 * - Integration with existing SubstitutionCompiler for variable mapping
 * 
 * HOW: Implements focused compilation methods that handle specific expression patterns
 *      requiring special processing beyond the standard ExpressionDispatcher routing.
 *      Each method maintains state and context while delegating to appropriate helpers.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused entirely on expression compilation variations
 * - Open/Closed Principle: Easy to add new expression variants without modifying core logic
 * - Testability: Expression variants can be tested independently from main compilation
 * - Maintainability: Clear separation between standard and specialized expression handling
 * - Performance: Optimized compilation paths for specific expression patterns
 * 
 * EDGE CASES:
 * - Complex nested variable substitution in deeply nested expressions
 * - Type-aware string concatenation with mixed operand types
 * - Switch expressions with complex pattern matching and guard clauses
 * - Block expression context preservation across compilation boundaries
 * - TVar object comparison for precise variable identity matching
 * 
 * @see docs/03-compiler-development/EXPRESSION_VARIANT_COMPILATION.md - Complete patterns guide
 */
@:nullSafety(Off)
class ExpressionVariantCompiler {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    /**
     * Main expression implementation with _this mapping and state threading support
     * 
     * WHY: Critical entry point that handles _this parameter mapping consistently
     * WHAT: Routes expressions through state threading logic before standard compilation
     * HOW: Check _this mappings first, then delegate to expressionDispatcher
     */
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileExpressionImpl called');
        #end
        
        #if debug_orphan_elimination
        if (expr != null) {
            trace('[XRay ExpressionVariantCompiler] Received expr: ${Type.getClassName(Type.getClass(expr.expr))}');
            switch (expr.expr) {
                case TLocal(v): trace('[XRay ExpressionVariantCompiler] TLocal variable: ${v.name}');
                case _:
            }
        } else {
            trace('[XRay ExpressionVariantCompiler] Received expr: NULL - this should not happen!');
        }
        #end
        
        // CRITICAL: Always check for _this mapping first, regardless of state threading status
        // This handles cases where expressions are compiled after state threading is disabled
        switch (expr.expr) {
            case TLocal(v) if (v.name == "_this"):
                // Try local function parameter map first
                var mappedName = compiler.currentFunctionParameterMap.get("_this");
                if (mappedName != null) {
                    #if debug_expression_variants
                    trace('[XRay ExpressionVariantCompiler] ✓ Local _this replacement: _this -> ${mappedName}');
                    #end
                    return mappedName;
                }
                
                // GLOBAL FIX: Try global struct method mapping if we're compiling a struct method
                if (compiler.isCompilingStructMethod) {
                    var globalMappedName = compiler.globalStructParameterMap.get("_this");
                    if (globalMappedName != null) {
                        #if debug_expression_variants
                        trace('[XRay ExpressionVariantCompiler] ✓ GLOBAL _this replacement: _this -> ${globalMappedName}');
                        #end
                        return globalMappedName;
                    }
                }
                
                // Still no mapping found - log for debugging
                #if debug_expression_variants
                trace('[XRay ExpressionVariantCompiler] ⚠️ Found _this but NO MAPPING available');
                trace('[XRay ExpressionVariantCompiler] ⚠️ State threading enabled: ${compiler.isStateThreadingEnabled()}');
                trace('[XRay ExpressionVariantCompiler] ⚠️ Global struct method: ${compiler.isCompilingStructMethod}');
                trace('[XRay ExpressionVariantCompiler] ⚠️ Local parameter map size: ${compiler.currentFunctionParameterMap != null ? Lambda.count(compiler.currentFunctionParameterMap) : 0}');
                trace('[XRay ExpressionVariantCompiler] ⚠️ Global parameter map size: ${Lambda.count(compiler.globalStructParameterMap)}');
                trace('[XRay ExpressionVariantCompiler] ⚠️ Expression position: ${expr.pos}');
                #end
                
            // CRITICAL FIX: Handle general TLocal variables with TVar.id mappings
            // This ensures loop desugaring variables get their proper mapped names
            case TLocal(v):
                #if debug_expression_variants
                trace('[XRay ExpressionVariantCompiler] TLocal variable reference: ${v.name} (id: ${v.id})');
                #end
                
                // Use VariableCompiler's ID mapping system to resolve the variable name
                // This handles loop desugaring mappings (g_counter, g_array) and other ID-based mappings
                var compiledName = compiler.variableCompiler.compileVariableReference(v);
                
                #if debug_expression_variants
                trace('[XRay ExpressionVariantCompiler] ✓ Variable resolved to: ${compiledName}');
                #end
                
                return compiledName;
                
            case _:
                // Continue with normal compilation
        }
        
        return compiler.expressionDispatcher.compileExpression(expr, topLevel);
    }

    /**
     * Compile expression with type-aware string concatenation handling
     * 
     * WHY: String concatenation needs special handling to use Elixir's <> operator
     * WHAT: Detects string operations and generates appropriate concatenation syntax
     * HOW: Check operand types and convert to proper Elixir string operations
     */
    public function compileExpressionWithTypeAwareness(expr: TypedExpr): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileExpressionWithTypeAwareness called');
        #end
        
        if (expr == null) return "nil";
        
        // For binary operations, check if we need special handling
        switch (expr.expr) {
            case TBinop(OpAdd, e1, e2):
                // Check if either operand is a string type
                var e1IsString = compiler.isStringType(e1.t);
                var e2IsString = compiler.isStringType(e2.t);
                var isStringConcat = e1IsString || e2IsString;
                
                if (isStringConcat) {
                    // Handle string constants directly to preserve quotes
                    var left = switch (e1.expr) {
                        case TConst(TString(s)): 
                            // Properly escape and quote the string
                            var escaped = StringTools.replace(s, '\\', '\\\\');
                            escaped = StringTools.replace(escaped, '"', '\\"');
                            escaped = StringTools.replace(escaped, '\n', '\\n');
                            escaped = StringTools.replace(escaped, '\r', '\\r');
                            escaped = StringTools.replace(escaped, '\t', '\\t');
                            '"${escaped}"';
                        case _: compileExpressionWithTypeAwareness(e1);
                    };
                    
                    var right = switch (e2.expr) {
                        case TConst(TString(s)): 
                            // Properly escape and quote the string
                            var escaped = StringTools.replace(s, '\\', '\\\\');
                            escaped = StringTools.replace(escaped, '"', '\\"');
                            escaped = StringTools.replace(escaped, '\n', '\\n');
                            escaped = StringTools.replace(escaped, '\r', '\\r');
                            escaped = StringTools.replace(escaped, '\t', '\\t');
                            '"${escaped}"';
                        case _: compileExpressionWithTypeAwareness(e2);
                    };
                    
                    // Convert non-string operands to strings
                    if (!e1IsString && e2IsString) {
                        left = compiler.convertToString(e1, left);
                    } else if (e1IsString && !e2IsString) {
                        right = compiler.convertToString(e2, right);
                    }
                    
                    return '${left} <> ${right}';
                } else {
                    var left = compileExpressionWithTypeAwareness(e1);
                    var right = compileExpressionWithTypeAwareness(e2);
                    return '${left} + ${right}';
                }
                
            case TBinop(op, e1, e2):
                var left = compileExpressionWithTypeAwareness(e1);
                var right = compileExpressionWithTypeAwareness(e2);
                return '${left} ${compiler.compileBinop(op)} ${right}';
                
            case _:
                // For all other cases, use regular compilation
                return compiler.compileExpression(expr);
        }
    }

    /**
     * Compile expression with variable mapping (DELEGATED to SubstitutionCompiler)
     * 
     * WHY: Variable mapping logic centralized in SubstitutionCompiler for maintainability
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithVarMapping()
     * HOW: Simple delegation preserving the exact same public interface
     */
    public function compileExpressionWithVarMapping(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ delegating to SubstitutionCompiler.compileExpressionWithVarMapping');
        #end
        return compiler.substitutionCompiler.compileExpressionWithVarMapping(expr, sourceVar, targetVar);
    }

    /**
     * Compile expression with aggressive variable substitution (DELEGATED to SubstitutionCompiler)
     * 
     * WHY: Aggressive substitution logic centralized in SubstitutionCompiler for maintainability
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithAggressiveSubstitution()
     * HOW: Simple delegation preserving the exact same public interface
     */
    public function compileExpressionWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ delegating to SubstitutionCompiler.compileExpressionWithAggressiveSubstitution');
        #end
        return compiler.substitutionCompiler.compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }

    /**
     * Compile expression with variable renaming (DELEGATED to SubstitutionCompiler)
     * 
     * WHY: Variable renaming logic centralized in SubstitutionCompiler for maintainability
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithRenaming()
     * HOW: Simple delegation preserving the exact same public interface
     */
    public function compileExpressionWithRenaming(expr: TypedExpr, renamings: Map<String, String>): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ delegating to SubstitutionCompiler.compileExpressionWithRenaming');
        #end
        return compiler.substitutionCompiler.compileExpressionWithRenaming(expr, renamings);
    }

    /**
     * Compile expression with variable substitution (DELEGATED to SubstitutionCompiler)
     * 
     * WHY: Variable substitution logic centralized in SubstitutionCompiler for maintainability
     * WHAT: Delegates to SubstitutionCompiler.compileExpressionWithSubstitution()
     * HOW: Simple delegation preserving the exact same public interface
     */
    public function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ delegating to SubstitutionCompiler.compileExpressionWithSubstitution');
        #end
        return compiler.substitutionCompiler.compileExpressionWithSubstitution(expr, sourceVar, targetVar);
    }

    /**
     * Compile expression with TVar object-based variable substitution for precise variable mapping
     * 
     * WHY: Reliable lambda parameter substitution requires TVar object comparison, not just string names
     * WHAT: Uses TVar object identity to precisely identify variables for substitution
     * HOW: Compare TVar objects directly, fallback to name matching, handle all expression types
     */
    public function compileExpressionWithTVarSubstitution(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileExpressionWithTVarSubstitution called');
        #end
        
        switch (expr.expr) {
            case TLocal(v):
                // Debug output to understand what variables we're dealing with
                var varName = compiler.getOriginalVarName(v);
                var sourceVarName = compiler.getOriginalVarName(sourceTVar);
                // TVar-based variable identification for reliable lambda parameter substitution
                
                // Enhanced matching: try exact object match first, then fallback to more permissive matching
                if (v == sourceTVar) {
                    // Exact object match - this is definitely the same variable
                    // Exact TVar match - replace with target variable name
                    return targetVarName;
                }
                
                // Fallback: check if this is likely the same logical variable
                // If both have the same original name, they're likely the same logical variable
                if (varName == sourceVarName && varName != null && varName != "") {
                    // Name-based fallback match - same variable name
                    return targetVarName;
                }
                
                // Use helper function for aggressive substitution as fallback
                if (compiler.shouldSubstituteVariable(varName, null, true)) {
                    // Aggressive fallback - pattern-based substitution
                    return targetVarName;
                }
                
                // Not a match - compile normally
                // No match found - compile variable normally
                return compiler.compileExpression(expr);
            case TBinop(op, e1, e2):
                // Handle assignment operations specially - we want the right-hand side value, not the assignment
                if (op == OpAssign) {
                    // For assignments in ternary contexts, return just the right-hand side value
                    return compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                }
                
                // Recursively substitute in binary operations with type awareness
                if (op == OpAdd) {
                    // Check if this is string concatenation
                    var e1IsString = compiler.isStringType(e1.t);
                    var e2IsString = compiler.isStringType(e2.t);
                    var isStringConcat = e1IsString || e2IsString;
                    
                    if (isStringConcat) {
                        var left = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                        var right = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                        
                        // Convert non-string operands to strings
                        if (!e1IsString && e2IsString) {
                            left = compiler.convertToString(e1, left);
                        } else if (e1IsString && !e2IsString) {
                            right = compiler.convertToString(e2, right);
                        }
                        
                        return '${left} <> ${right}';
                    }
                }
                
                // For non-string addition or other operators
                var left = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                var right = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                return '${left} ${compiler.compileBinop(op)} ${right}';
            case TField(e, fa):
                // Handle field access on substituted variables
                // Handle field access with variable substitution
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var fieldName = compiler.getFieldName(fa);
                // Field access on substituted variable
                return '${obj}.${fieldName}';
            case TCall(e, args):
                // Handle method calls with substitution
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var compiledArgs = args.map(arg -> compileExpressionWithTVarSubstitution(arg, sourceTVar, targetVarName));
                return '${obj}(${compiledArgs.join(", ")})';
            case TArray(e1, e2):
                // Handle array access with substitution
                var arr = compileExpressionWithTVarSubstitution(e1, sourceTVar, targetVarName);
                var index = compileExpressionWithTVarSubstitution(e2, sourceTVar, targetVarName);
                return 'Enum.at(${arr}, ${index})';
            case TConst(c):
                // Constants don't need substitution
                return compiler.expressionDispatcher.literalCompiler.compileConstant(c);
            case TIf(econd, eif, eelse):
                // Handle conditionals with substitution
                var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case TBlock(exprs):
                // Handle blocks with substitution
                var compiledExprs = exprs.map(e -> compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName));
                return compiledExprs.join('\n');
            case TParenthesis(e):
                // Handle parenthesized expressions with substitution
                return "(" + compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName) + ")";
            case TUnop(op, postFix, e):
                // Handle unary operations with substitution (like !variable)
                // Handle unary operations with variable substitution
                var operand = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                
                // Compile unary operator inline (from main compileExpression logic)
                var result = switch (op) {
                    case OpIncrement: '${operand} + 1';
                    case OpDecrement: '${operand} - 1'; 
                    case OpNot: '!${operand}';
                    case OpNeg: '-${operand}';
                    case OpNegBits: 'bnot(${operand})';
                    case _: operand;
                };
                
                // Unary operation with substituted operand
                return result;
            case _:
                // For other cases, fall back to regular compilation
                return compiler.compileExpression(expr);
        }
    }

    /**
     * Compile switch expression with state threading context support
     * 
     * WHY: Switch expressions need state threading context for pattern matching
     * WHAT: Handles switch compilation with proper context management
     * HOW: Create context based on state threading mode and delegate to pattern matcher
     */
    public function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileSwitchExpression called');
        #end
        
        // CRITICAL: Pre-analyze ALL switch cases to set pattern usage context BEFORE any compilation
        // This is the key fix for the orphaned enum parameters issue - context must be available
        // when TEnumParameter expressions are compiled, which happens early in case processing
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] Pre-analyzing switch cases for pattern usage context');
        #end
        
        for (caseData in cases) {
            var usedVariables = compiler.patternMatchingCompiler.findUsedVariables(caseData.expr);
            if (usedVariables != null && Lambda.count(usedVariables) > 0) {
                // Found variables used in at least one case - set global context
                // This context will be available when TEnumParameter expressions are compiled
                compiler.patternUsageContext = usedVariables;
                #if debug_expression_variants
                var usedVarNames = [for (name in usedVariables.keys()) name];
                trace('[XRay ExpressionVariantCompiler] ✓ Set global pattern usage context: [${usedVarNames.join(", ")}]');
                #end
                break; // Only need to set context once
            }
        }
        
        // If no variables found in any case, ensure context indicates empty usage
        if (compiler.patternUsageContext == null) {
            compiler.patternUsageContext = new Map<String, Bool>();
            #if debug_expression_variants
            trace('[XRay ExpressionVariantCompiler] ✓ Set empty pattern usage context (no variables used)');
            #end
        }
        
        // Create FunctionContext with struct parameter name if we're in state threading mode
        var context: Null<FunctionContext> = null;
        
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] Checking for _this mapping');
        trace('[XRay ExpressionVariantCompiler] isStateThreadingEnabled: ${compiler.isStateThreadingEnabled()}');
        trace('[XRay ExpressionVariantCompiler] currentFunctionParameterMap size: ${Lambda.count(compiler.currentFunctionParameterMap)}');
        for (key in compiler.currentFunctionParameterMap.keys()) {
            trace('[XRay ExpressionVariantCompiler] Map key: ${key} -> ${compiler.currentFunctionParameterMap.get(key)}');
        }
        #end
        
        // Check if we have a struct parameter mapping for _this
        if (compiler.currentFunctionParameterMap.exists("_this")) {
            var structParamName = compiler.currentFunctionParameterMap.get("_this");
            context = {
                structParamName: structParamName
            };
            #if debug_expression_variants
            trace('[XRay ExpressionVariantCompiler] ✓ Found _this mapping to ${structParamName}');
            trace('[XRay ExpressionVariantCompiler] Created context with structParamName: ${structParamName}');
            #end
        } else if (compiler.isStateThreadingEnabled()) {
            // If state threading is enabled but no _this mapping, use "struct" as default
            context = {
                structParamName: "struct"
            };
            #if debug_expression_variants
            trace('[XRay ExpressionVariantCompiler] State threading enabled but no _this mapping, using default "struct"');
            #end
        } else {
            #if debug_expression_variants
            trace('[XRay ExpressionVariantCompiler] ✗ No _this mapping found and state threading not enabled');
            #end
        }
        
        var result = compiler.patternMatchingCompiler.compileSwitchExpression(switchExpr, cases, defaultExpr, context);
        
        // CRITICAL: Clear the global pattern usage context after switch compilation
        // This prevents context pollution between different compilation units
        compiler.patternUsageContext = null;
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ Cleared global pattern usage context after switch compilation');
        #end
        
        return result;
    }

    /**
     * Compile block expressions with context preservation
     * 
     * WHY: Block expressions need to maintain inline context across expressions
     * WHAT: Compiles each expression while preserving context state
     * HOW: Iterate through expressions without saving/restoring context
     */
    public function compileBlockExpressionsWithContext(expressions: Array<TypedExpr>): Array<String> {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileBlockExpressionsWithContext called with ${expressions.length} expressions');
        #end
        
        var compiledStatements = [];
        
        // Compile each expression while maintaining inline context
        // DO NOT save/restore context - we want inline context to persist across expressions
        for (i in 0...expressions.length) {
            var compiled = compiler.compileExpression(expressions[i]);
            if (compiled != null && compiled.trim() != "") {
                compiledStatements.push(compiled);
            }
        }
        
        return compiledStatements;
    }

    /**
     * Compile expression with mutation tracking (backward compatibility delegation)
     * 
     * WHY: Legacy function moved to WhileLoopCompiler but still needed for compatibility
     * WHAT: Simple mutation tracking for basic expression types
     * HOW: Handle blocks by joining expressions, delegate other types to regular compilation
     */
    public function compileExpressionWithMutationTracking(expr: TypedExpr, updates: Map<String, String>): String {
        #if debug_expression_variants
        trace('[XRay ExpressionVariantCompiler] ✓ compileExpressionWithMutationTracking called');
        #end
        
        // This function was moved to WhileLoopCompiler but needs to be accessible here for backward compatibility
        // This is a temporary delegation that should be replaced with direct calls to WhileLoopCompiler when possible
        return switch (expr.expr) {
            case TBlock(exprs):
                #if debug_loops
                trace('[XRay ExpressionVariantCompiler] TBlock with ${exprs.length} expressions');
                #end
                
                // Check for variable assignment followed by array building loop pattern
                var optimizedBlock = tryOptimizeArrayAssignmentPattern(exprs);
                if (optimizedBlock != null) {
                    #if debug_loops
                    trace('[XRay ExpressionVariantCompiler] ✓ Array assignment optimization applied');
                    #end
                    return optimizedBlock;
                }
                
                // CRITICAL FIX: Check for temp variable patterns that need scoping fixes
                // This fixes undefined variables in if-else blocks (temp_array, temp_array1, etc.)
                trace('[XRay ExpressionVariantCompiler] Checking for temp variable patterns in ${exprs.length} expressions...');
                var tempVarName = compiler.tempVariableOptimizer.detectTempVariablePattern(exprs);
                if (tempVarName != null) {
                    trace('[XRay ExpressionVariantCompiler] ✓ TEMP VAR PATTERN DETECTED: ${tempVarName}');
                    return compiler.tempVariableOptimizer.optimizeTempVariablePattern(tempVarName, exprs);
                }
                trace('[XRay ExpressionVariantCompiler] ❌ NO TEMP VAR PATTERN FOUND');
                
                #if debug_loops
                trace('[XRay ExpressionVariantCompiler] No array assignment optimization - proceeding normally');
                #end
                
                var results = [];
                for (e in exprs) {
                    results.push(compiler.compileExpression(e));
                }
                results.join("\n");
            case _:
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Try to optimize array assignment patterns where a variable is assigned an empty array
     * and immediately followed by a loop that builds into that array
     * 
     * ARRAY ASSIGNMENT OPTIMIZATION
     * 
     * WHY: Haxe for-loops desugar into patterns like:
     *      var evens = [];
     *      while (g_counter < numbers.length) { evens.push(numbers[g_counter]); }
     *      This should become: evens = Enum.filter(numbers, ...)
     * 
     * WHAT: Detects TVar assignment to empty array followed by array-building while loop
     * HOW: Analyze block expressions for this specific pattern and generate direct assignment
     * EDGE CASES: Only works for simple empty array assignments followed by loops
     * 
     * @param exprs Array of expressions in a TBlock
     * @return Optimized block code or null if no optimization possible
     */
    private function tryOptimizeArrayAssignmentPattern(exprs: Array<TypedExpr>): Null<String> {
        #if debug_loops
        trace('[XRay ArrayAssignment] ANALYZING BLOCK FOR ARRAY ASSIGNMENT PATTERN');
        trace('[XRay ArrayAssignment] - Block has ${exprs.length} expressions');
        #end
        
        if (exprs.length < 2) return null;
        
        // Look for pattern: TVar assignment to empty array + TWhile with array building
        for (i in 0...(exprs.length - 1)) {
            var currentExpr = exprs[i];
            var nextExpr = exprs[i + 1];
            
            // Check if current expression is a variable assignment to empty array
            var arrayVar = extractEmptyArrayAssignment(currentExpr);
            if (arrayVar != null) {
                #if debug_loops
                trace('[XRay ArrayAssignment] ✓ Found empty array assignment: ${arrayVar}');
                #end
                
                // Check if next expression is a while loop that builds into this array
                var loopOptimization = tryOptimizeWhileLoopWithTarget(nextExpr, arrayVar);
                if (loopOptimization != null) {
                    #if debug_loops
                    trace('[XRay ArrayAssignment] ✓ Found matching array building loop');
                    trace('[XRay ArrayAssignment] ✓ OPTIMIZATION APPLIED: ${arrayVar} = ${loopOptimization}');
                    #end
                    
                    // Generate optimized assignment: arrayVar = Enum.function(...)
                    var optimizedAssignment = '${arrayVar} = ${loopOptimization}';
                    
                    // Compile remaining expressions normally
                    var remainingResults = [];
                    remainingResults.push(optimizedAssignment);
                    
                    for (j in (i + 2)...exprs.length) {
                        remainingResults.push(compiler.compileExpression(exprs[j]));
                    }
                    
                    // Include expressions before the pattern
                    var beforeResults = [];
                    for (k in 0...i) {
                        beforeResults.push(compiler.compileExpression(exprs[k]));
                    }
                    
                    return (beforeResults.concat(remainingResults)).join("\n");
                }
            }
        }
        
        return null; // No optimization found
    }
    
    /**
     * Extract variable name from empty array assignment (TVar to empty array)
     * 
     * @param expr Expression to analyze
     * @return Variable name if it's an empty array assignment, null otherwise
     */
    private function extractEmptyArrayAssignment(expr: TypedExpr): Null<String> {
        return switch (expr.expr) {
            case TVar(v, initExpr):
                if (initExpr != null) {
                    switch (initExpr.expr) {
                        case TArrayDecl([]): // Empty array literal
                            #if debug_loops
                            trace('[XRay ArrayAssignment] ✓ Empty array assignment detected: ${v.name}');
                            #end
                            v.name;
                        case _: null;
                    }
                } else {
                    null;
                }
            case _: null;
        }
    }
    
    /**
     * Try to optimize a while loop expression with a specific target array variable
     * 
     * @param expr While loop expression to analyze
     * @param targetVar Target variable name that should be built into
     * @return Enum function call if optimization possible, null otherwise
     */
    private function tryOptimizeWhileLoopWithTarget(expr: TypedExpr, targetVar: String): Null<String> {
        return switch (expr.expr) {
            case TWhile(econd, ebody, normalWhile):
                // Delegate to UnifiedLoopCompiler for while loop compilation
                // The UnifiedLoopCompiler handles array building pattern detection internally
                
                #if debug_loops
                trace('[XRay ArrayAssignment] Checking while loop for array building with target: ${targetVar}');
                #end
                
                // UnifiedLoopCompiler will detect and optimize array building patterns internally
                // We just need to compile the while loop and it will return the optimized version
                var compiledLoop = compiler.unifiedLoopCompiler.compileWhileLoop(econd, ebody, normalWhile);
                
                // Check if this was an array building pattern for our target variable
                // For now, return the compiled loop if it's non-empty
                if (compiledLoop != null && compiledLoop != "") {
                    #if debug_loops
                    trace('[XRay ArrayAssignment] ✓ While loop compiled, checking if it builds array for target');
                    #end
                    
                    return compiledLoop;
                }
                
                null;
            case _: null;
        }
    }
    
    /**
     * Extract transformation logic from mapping body (TVar-based version)
     * 
     * WHY: Delegates to SubstitutionCompiler for centralized variable handling
     * WHAT: Extracts transformation from expression body using TVar-based substitution
     * HOW: Direct delegation to substitutionCompiler instance
     */
    public function extractTransformationFromBodyWithTVar(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        return compiler.substitutionCompiler.extractTransformationFromBodyWithTVar(expr, sourceTVar, targetVarName);
    }
    
    /**
     * Extract transformation logic from mapping body (string-based version)
     * 
     * WHY: Delegates to SubstitutionCompiler for centralized variable handling
     * WHAT: Extracts transformation from expression body using string-based substitution
     * HOW: Direct delegation to substitutionCompiler instance
     */
    public function extractTransformationFromBody(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        return compiler.substitutionCompiler.extractTransformationFromBody(expr, sourceVar, targetVar);
    }
    
}

#end