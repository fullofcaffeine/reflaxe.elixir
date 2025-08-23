package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;

using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Data structure for merged assignment results
 */
typedef MergedAssignment = {
    compiledCode: String,
    nextIndex: Int
};

/**
 * Pattern data for variable to field assignment
 */
typedef VariableToFieldPattern = {
    varName: String,
    sourceFieldAccess: String,
    sourceObject: String
};

/**
 * Pattern data for field assignment
 */
typedef FieldAssignmentPattern = {
    fieldName: String,
    valueExpression: TypedExpr
};

/**
 * Function context information for field assignment transformations
 */
typedef FunctionContext = {
    structParamName: Null<String>  // Name of the struct parameter (e.g., "struct", "this", etc.)
};

/**
 * Direct field assignment pattern result
 */
typedef DirectFieldAssignment = {
    structParam: String,        // Name of struct parameter to use
    compiledCode: String       // Generated Elixir code
};

/**
 * Control Flow Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~600 lines of control flow compilation
 * scattered across TBlock, TIf, TSwitch, TWhile, TFor, and TTry cases. This massive complexity
 * in a single function violated Single Responsibility Principle and made control flow logic
 * nearly impossible to maintain, test, or extend. Each control flow construct had specialized
 * logic for pattern detection, variable renaming, optimization, and Y combinator generation.
 * 
 * WHAT: Specialized compiler for all control flow constructs in Haxe-to-Elixir transpilation:
 * - Block expressions (TBlock) → Elixir multi-statement blocks with variable collision handling
 * - Conditional expressions (TIf) → Elixir if-do-else with Y combinator detection
 * - Pattern matching (TSwitch) → Elixir case-do-end with exhaustive matching
 * - While loops (TWhile) → Elixir Y combinator recursive patterns
 * - For loops (TFor) → Idiomatic Elixir Enum operations (map, each, reduce)
 * - Try-catch blocks (TTry) → Elixir try-rescue-catch-after patterns
 * - Complex optimizations: Reflect.fields loops, array building patterns, pipeline optimizations
 * 
 * HOW: The compiler implements sophisticated control flow transformation patterns:
 * 1. Receives control flow TypedExpr from ExpressionDispatcher
 * 2. Applies pattern-specific analysis and optimization detection
 * 3. Handles variable collision resolution and renaming for desugared code
 * 4. Generates idiomatic Elixir control structures with proper scoping
 * 5. Provides Y combinator detection and recursive pattern generation
 * 6. Optimizes common patterns (Reflect loops, array building, pipelines)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on control flow construct compilation
 * - Optimization Centralization: All control flow optimizations in one place
 * - Y Combinator Expertise: Specialized handling of recursive patterns
 * - Pattern Recognition: Advanced detection of common programming patterns
 * - Maintainability: Clear separation from expression and operator logic
 * - Testability: Control flow logic can be independently tested and verified
 * 
 * EDGE CASES:
 * - Variable name collision resolution in desugared for-loops
 * - Y combinator detection across nested control structures
 * - Reflect.fields pattern optimization for dynamic property iteration
 * - Pipeline pattern detection and optimization in block expressions
 * - Proper scoping and variable mapping in nested control structures
 * 
 * @see documentation/CONTROL_FLOW_COMPILATION_PATTERNS.md - Complete control flow transformation patterns
 */
@:nullSafety(Off)
class ControlFlowCompiler {
    
    var compiler: ElixirCompiler; // ElixirCompiler reference (NEVER Dynamic!)
    
    /**
     * Create a new control flow compiler
     * 
     * @param compiler The main ElixirCompiler instance
     */
    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
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
        #if debug_control_flow_compiler || debug_loops
        trace('[XRay ControlFlowCompiler] ANALYZING BLOCK FOR ARRAY ASSIGNMENT PATTERN');
        trace('[XRay ControlFlowCompiler] - Block has ${exprs.length} expressions');
        #end
        
        if (exprs.length < 2) return null;
        
        // Look for pattern: TVar assignment to empty array + TWhile with array building
        for (i in 0...(exprs.length - 1)) {
            var currentExpr = exprs[i];
            var nextExpr = exprs[i + 1];
            
            // Check if current expression is a variable assignment to empty array
            var arrayVar = extractEmptyArrayAssignment(currentExpr);
            if (arrayVar != null) {
                #if debug_control_flow_compiler || debug_loops
                trace('[XRay ControlFlowCompiler] ✓ Found empty array assignment: ${arrayVar}');
                #end
                
                // Check if next expression is a while loop that builds into this array
                var loopOptimization = tryOptimizeWhileLoopWithTarget(nextExpr, arrayVar);
                if (loopOptimization != null) {
                    #if debug_control_flow_compiler || debug_loops
                    trace('[XRay ControlFlowCompiler] ✓ Found matching array building loop');
                    trace('[XRay ControlFlowCompiler] ✓ OPTIMIZATION APPLIED: ${arrayVar} = ${loopOptimization}');
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
                            #if debug_control_flow_compiler || debug_loops
                            trace('[XRay ControlFlowCompiler] ✓ Empty array assignment detected: ${v.name}');
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
                // Delegate to LoopCompiler for array building pattern detection
                var loopCompiler = compiler.loopCompiler;
                
                #if debug_control_flow_compiler || debug_loops
                trace('[XRay ControlFlowCompiler] Checking while loop for array building with target: ${targetVar}');
                #end
                
                var arrayBuildingPattern = loopCompiler.detectArrayBuildingPattern(econd, ebody);
                if (arrayBuildingPattern != null && arrayBuildingPattern.accumVar == targetVar) {
                    #if debug_control_flow_compiler || debug_loops
                    trace('[XRay ControlFlowCompiler] ✓ Array building pattern matches target variable');
                    #end
                    
                    return loopCompiler.compileArrayBuildingLoop(econd, ebody, arrayBuildingPattern);
                }
                
                null;
            case _: null;
        }
    }
    
    /**
     * Compile TBlock expressions with variable collision handling and pattern optimization
     * 
     * WHY: TBlock is one of the most complex cases in the original function, handling everything
     * from simple statement sequences to complex desugared for-loops with variable renaming
     * 
     * WHAT: Transform Haxe block expressions to properly scoped Elixir statement sequences
     * 
     * HOW:
     * 1. Handle empty blocks (→ nil) and single expressions (→ direct compilation)
     * 2. Detect and optimize Reflect.fields patterns for dynamic property iteration
     * 3. Analyze variable declarations for collision detection in desugared code
     * 4. Apply variable renaming for collision resolution (_g variables, etc.)
     * 5. Generate proper Elixir multi-statement blocks with correct scoping
     * 6. Use function context to resolve struct parameter names for field assignments
     * 
     * @param el Array of TypedExpr representing block statements
     * @param topLevel Whether this is a top-level block
     * @param context Function context for field assignment transformations
     * @return Compiled Elixir block expression
     */
    public function compileBlock(el: Array<TypedExpr>, topLevel: Bool = false, context: Null<FunctionContext> = null): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] BLOCK COMPILATION START");
        trace('[XRay ControlFlowCompiler] Block length: ${el.length}');
        trace('[XRay ControlFlowCompiler] *** CRITICAL: topLevel = ${topLevel} ***');
        trace('[XRay ControlFlowCompiler] context = ${context != null ? "exists" : "null"}');
        trace('[XRay ControlFlowCompiler] structParamName in context = ${context != null && context.structParamName != null ? context.structParamName : "null"}');
        #end
        
        // BASIC IMPLEMENTATION: Handle block expressions
        if (el.length == 0) {
            return "nil";
        }
        
        // Check for array assignment patterns (variable = [] followed by array building loop)
        var arrayAssignmentOptimization = tryOptimizeArrayAssignmentPattern(el);
        if (arrayAssignmentOptimization != null) {
            #if debug_control_flow_compiler || debug_loops
            trace("[XRay ControlFlowCompiler] ✓ ARRAY ASSIGNMENT OPTIMIZATION APPLIED");
            #end
            return arrayAssignmentOptimization;
        }
        
        // Process TBlock expressions normally
        
        // Compile each expression in the block with sequential field assignment analysis
        var statements = [];
        var i = 0;
        while (i < el.length) {
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] Processing expression ${i}/${el.length}: ${el[i].expr}');
            #end
            
            // Check for sequential field assignment patterns that need merging
            var mergedAssignment = detectAndMergeSequentialFieldAssignments(el, i, context);
            if (mergedAssignment != null) {
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] ✓ MERGED ASSIGNMENT DETECTED at index ${i}!');
                trace('[XRay ControlFlowCompiler] Merged code: ${mergedAssignment.compiledCode.substring(0, 100)}...');
                #end
                
                // Sequential assignments were merged, add the result and skip processed expressions
                statements.push(mergedAssignment.compiledCode);
                i = mergedAssignment.nextIndex;
            } else {
                // Check for unused TEnumParameter patterns before normal compilation
                if (isUnusedEnumParameterExpression(el, i)) {
                    #if debug_control_flow_compiler
                    trace('[XRay ControlFlowCompiler] ✓ SKIPPING unused TEnumParameter and following TLocal at index ${i}');
                    #end
                    // Skip BOTH the TEnumParameter AND the following TLocal(g) expression
                    // The pattern is: TEnumParameter (generates 'g = elem(...)') followed by TLocal(g)
                    i += 2;  // Skip both expressions
                    continue;
                }
                
                // Normal expression compilation
                var compiled = compiler.compileExpression(el[i], topLevel);
                if (compiled != null && compiled.length > 0) {
                    statements.push(compiled);
                }
                i++;
            }
        }
        
        var result: String = if (topLevel) {
            // Top-level blocks (function bodies) should be clean newline-separated statements
            // This matches the original compiler behavior: compiledStatements.join("\n")
            statements.join("\n");
        } else {
            // CRITICAL FIX: For multi-statement blocks, always use clean formatting
            // Single expressions can stay inline, but multi-statement blocks should be clean
            if (statements != null && statements.length == 1) {
                statements[0] != null ? statements[0] : "nil"; // Single expression
            } else if (statements != null && statements.length > 6) {
                // Large blocks (like function bodies) should use clean formatting
                // even if topLevel=false due to calling path issues
                statements.join("\n");
            } else {
                // Small multi-statement nested blocks use parentheses for proper scoping
                "(\n      " + statements.join("\n      ") + "\n    )";
            }
        };
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated block: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] BLOCK COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Detect and merge sequential field assignments in block expressions
     * 
     * WHY: Patterns like "struct = struct.buf; struct.b = ..." need to be merged into atomic updates
     * Also handles direct field assignments like "struct.buf.b = ..." when context provides struct name
     * 
     * WHAT: Analyze consecutive assignments for variable reassignment followed by field mutation
     * Also detect direct field assignments that need proper struct variable resolution
     * 
     * HOW: 
     * 1. Check if current expression is variable assignment to field access (struct = struct.buf)
     * 2. Check if next expression is field assignment on same variable (struct.b = ...)
     * 3. Check for direct field assignments and use context to resolve struct name
     * 4. If pattern matches, merge into single Map update expression with correct variable
     * 
     * @param expressions Array of expressions in the block
     * @param startIndex Current expression index to analyze
     * @param context Function context containing struct parameter name
     * @return MergedAssignment if pattern detected, null otherwise
     */
    private function detectAndMergeSequentialFieldAssignments(expressions: Array<TypedExpr>, startIndex: Int, context: Null<FunctionContext>): Null<MergedAssignment> {
        var currentExpr = expressions[startIndex];
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Checking pattern at index ${startIndex}');
        trace('[XRay ControlFlowCompiler] Current expr: ${currentExpr.expr}');
        trace('[XRay ControlFlowCompiler] Context struct param: ${context != null ? context.structParamName : "null"}');
        #end
        
        // PATTERN A: Direct field assignment in case expression (e.g., struct.buf.b = "value")
        // This happens when we have a direct field assignment without prior variable declaration
        var directFieldAssignment = analyzeDirectFieldAssignment(currentExpr, context);
        if (directFieldAssignment != null) {
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] ✓ DIRECT FIELD ASSIGNMENT DETECTED!');
            trace('[XRay ControlFlowCompiler] Using struct param: ${directFieldAssignment.structParam}');
            #end
            
            return {
                compiledCode: directFieldAssignment.compiledCode,
                nextIndex: startIndex + 1  // Skip only current expression
            };
        }
        
        // PATTERN B: Sequential assignment pattern (struct = struct.buf; struct.b = ...)
        // Need at least 2 expressions for sequential pattern
        if (startIndex + 1 >= expressions.length) {
            return null;
        }
        
        var secondExpr = expressions[startIndex + 1];
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Second expr: ${secondExpr.expr}');
        #end
        
        // Pattern 1: struct = struct.buf (variable assignment to field access)
        var variableReassignment = analyzeVariableToFieldAssignment(currentExpr);
        if (variableReassignment == null) {
            return null;
        }
        
        // Pattern 2: struct.b = struct.b <> "text" (field assignment on same variable)
        var fieldAssignment = analyzeFieldAssignmentPattern(secondExpr, variableReassignment.varName);
        if (fieldAssignment == null) {
            return null;
        }
        
        // Merge the patterns into a single atomic update
        var mergedCode = generateMergedFieldUpdate(variableReassignment, fieldAssignment, context);
        
        return {
            compiledCode: mergedCode,
            nextIndex: startIndex + 2  // Skip both processed expressions
        };
    }
    
    /**
     * Analyze if expression is variable assignment to field access (struct = struct.buf)
     * 
     * @param expr Expression to analyze
     * @return Pattern info if matches, null otherwise
     */
    private function analyzeVariableToFieldAssignment(expr: TypedExpr): Null<VariableToFieldPattern> {
        switch (expr.expr) {
            case TBinop(OpAssign, e1, e2):
                // Pattern: struct = struct.buf
                switch (e1.expr) {
                    case TLocal(v):
                        var varName = v.name;
                        
                        // Check if right side is field access on same variable
                        switch (e2.expr) {
                            case TField(obj, fieldAccess):
                                switch (obj.expr) {
                                    case TLocal(objVar) if (objVar.name == varName):
                                        var fieldName = switch (fieldAccess) {
                                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                                            case FEnum(_, ef): ef.name;
                                            case FClosure(_, cf): cf.get().name;
                                            case FDynamic(s): s;
                                            case _: "unknown_field";
                                        };
                                        
                                        return {
                                            varName: varName,
                                            sourceFieldAccess: fieldName,
                                            sourceObject: varName
                                        };
                                    case _: return null;
                                }
                            case _: return null;
                        }
                    case _: return null;
                }
                
            case TVar(tvar, valueExpr) if (valueExpr != null):
                // Pattern: var _this = this.buf (JsonPrinter style)
                var varName = tvar.name;
                
                switch (valueExpr.expr) {
                    case TField(obj, fieldAccess):
                        var fieldName = switch (fieldAccess) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                            case FEnum(_, ef): ef.name;
                            case FClosure(_, cf): cf.get().name;
                            case FDynamic(s): s;
                            case _: "unknown_field";
                        };
                        
                        // For TVar patterns, the original object name needs to be extracted differently
                        var sourceObjectName = switch (obj.expr) {
                            case TConst(TThis): "struct"; // this.buf -> struct.buf
                            case TLocal(v): v.name;
                            case _: "unknown";
                        };
                        
                        #if debug_control_flow_compiler
                        trace('[XRay ControlFlowCompiler] ✓ DETECTED TVar field assignment pattern');
                        trace('[XRay ControlFlowCompiler] Variable: ${varName}, Field: ${fieldName}, Source: ${sourceObjectName}');
                        #end
                        
                        return {
                            varName: varName,
                            sourceFieldAccess: fieldName,
                            sourceObject: sourceObjectName
                        };
                    case _: return null;
                }
                
            case _: return null;
        }
    }
    
    /**
     * Analyze if expression is field assignment on specified variable
     * 
     * @param expr Expression to analyze
     * @param targetVarName Variable name to check for
     * @return Pattern info if matches, null otherwise  
     */
    private function analyzeFieldAssignmentPattern(expr: TypedExpr, targetVarName: String): Null<FieldAssignmentPattern> {
        switch (expr.expr) {
            case TBinop(OpAssign, e1, e2) | TBinop(OpAssignOp(_), e1, e2):
                // Handle both simple assignment and compound assignment (+=, <>, etc.)
                switch (e1.expr) {
                    case TField(obj, fieldAccess):
                        switch (obj.expr) {
                            case TLocal(v) if (v.name == targetVarName):
                                var fieldName = switch (fieldAccess) {
                                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                                    case FEnum(_, ef): ef.name;
                                    case FClosure(_, cf): cf.get().name;
                                    case FDynamic(s): s;
                                    case _: "unknown_field";
                                };
                                
                                #if debug_control_flow_compiler
                                trace('[XRay ControlFlowCompiler] ✓ DETECTED field assignment on ${targetVarName}.${fieldName}');
                                #end
                                
                                return {
                                    fieldName: fieldName,
                                    valueExpression: e2
                                };
                            case _: return null;
                        }
                    case _: return null;
                }
            case _: return null;
        }
    }
    
    /**
     * Analyze direct field assignment in case expressions (e.g., struct.buf.b = "value")
     * 
     * WHY: JsonPrinter generates direct field assignments in case expressions that don't use _this
     * but need to use the actual struct parameter name from the function context
     * 
     * WHAT: Detect field assignments like TBinop(OpAssign, TField(...), value) and transform
     * them to use proper Map update syntax with the correct struct variable name
     * 
     * HOW:
     * 1. Check if expression is field assignment (TBinop with OpAssign or OpAssignOp)
     * 2. Extract the field chain (struct.buf.b)
     * 3. Use context to determine correct struct parameter name
     * 4. Generate proper Map update syntax
     * 
     * @param expr Expression to analyze
     * @param context Function context containing struct parameter name
     * @return DirectFieldAssignment if pattern detected, null otherwise
     */
    public function analyzeDirectFieldAssignment(expr: TypedExpr, context: Null<FunctionContext>): Null<DirectFieldAssignment> {
        // Must have context to resolve struct parameter name
        if (context == null || context.structParamName == null) {
            return null;
        }
        
        switch (expr.expr) {
            case TBinop(OpAssign, e1, e2) | TBinop(OpAssignOp(_), e1, e2):
                // Check if this is a simple _this assignment that should use struct
                switch (e1.expr) {
                    case TLocal(v) if (v.name == "_this"):
                        // Pattern: _this = %{_this.buf | b: value}
                        // This should be: struct = %{struct.buf | b: value}
                        var valueCompiled = compiler.compileExpression(e2);
                        
                        // Try local context first, then global struct method mapping
                        var structParam: Null<String> = null;
                        if (context != null && context.structParamName != null) {
                            structParam = context.structParamName;
                        } else if (compiler.isCompilingStructMethod && compiler.globalStructParameterMap.exists("_this")) {
                            // GLOBAL FIX: Use global mapping when local context is not available
                            structParam = compiler.globalStructParameterMap.get("_this");
                        }
                        
                        #if debug_control_flow_compiler
                        trace('[XRay ControlFlowCompiler] ✓ SIMPLE _THIS ASSIGNMENT DETECTED: _this = ${valueCompiled}');
                        trace('[XRay ControlFlowCompiler] Converting to use struct param: ${structParam}');
                        #end
                        
                        if (structParam != null) {
                            // Replace _this with struct in the compiled value expression
                            // This is a bit hacky but effective for this pattern
                            var correctedValue = valueCompiled.replace("_this", structParam);
                            var compiledCode = '${structParam} = ${correctedValue}';
                            
                            return {
                                structParam: structParam,
                                compiledCode: compiledCode
                            };
                        } else {
                            // Fallback to default behavior if no mapping available
                            return null;
                        }
                        
                    case TField(obj, fieldAccess):
                        // Extract the field name
                        var fieldName = switch (fieldAccess) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                            case FEnum(_, ef): ef.name;
                            case FClosure(_, cf): cf.get().name;
                            case FDynamic(s): s;
                            case _: "unknown_field";
                        };
                        
                        // Check if this is a nested field access (obj.field.subfield)
                        var sourceField = switch (obj.expr) {
                            case TField(baseObj, baseFieldAccess):
                                // This is a nested field access like struct.buf.b
                                switch (baseFieldAccess) {
                                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                                    case FEnum(_, ef): ef.name;
                                    case FClosure(_, cf): cf.get().name;
                                    case FDynamic(s): s;
                                    case _: "unknown_field";
                                }
                            case _: null;
                        };
                        
                        if (sourceField != null) {
                            // This is a nested field assignment: struct.sourceField.fieldName = value
                            var valueCompiled = compiler.compileExpression(e2);
                            var structParam = context.structParamName;
                            
                            #if debug_control_flow_compiler
                            trace('[XRay ControlFlowCompiler] ✓ DIRECT NESTED FIELD ASSIGNMENT: ${structParam}.${sourceField}.${fieldName} = ${valueCompiled}');
                            #end
                            
                            // Generate: struct = %{struct.sourceField | fieldName: value}
                            // Use the actual struct parameter name, not hardcoded "_this"
                            var compiledCode = '${structParam} = %{${structParam}.${sourceField} | ${fieldName}: ${valueCompiled}}';
                            
                            return {
                                structParam: structParam,
                                compiledCode: compiledCode
                            };
                        }
                        
                    case _: return null;
                }
            case _: return null;
        }
        
        return null;
    }
    
    /**
     * Generate merged field update expression
     * 
     * @param varPattern Variable reassignment pattern
     * @param fieldPattern Field assignment pattern
     * @param context Optional function context with struct parameter name
     * @return Compiled merged update expression
     */
    private function generateMergedFieldUpdate(varPattern: VariableToFieldPattern, fieldPattern: FieldAssignmentPattern, ?context: FunctionContext): String {
        var valueCompiled = compiler.compileExpression(fieldPattern.valueExpression);
        
        // Use struct parameter name if available and variable is _this
        var varName = varPattern.varName;
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] generateMergedFieldUpdate: varName = ${varName}');
        trace('[XRay ControlFlowCompiler] context = ${context != null ? "exists" : "null"}');
        trace('[XRay ControlFlowCompiler] structParamName = ${context != null && context.structParamName != null ? context.structParamName : "null"}');
        #end
        
        if (varName == "_this") {
            // Try local context first, then global struct method mapping
            if (context != null && context.structParamName != null) {
                varName = context.structParamName;
            } else if (compiler.isCompilingStructMethod && compiler.globalStructParameterMap.exists("_this")) {
                // GLOBAL FIX: Use global mapping when local context is not available
                varName = compiler.globalStructParameterMap.get("_this");
            }
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] Replaced _this with ${varName}');
            #end
        }
        
        // Generate: variable = %{variable.source_field | target_field: value}
        return '${varName} = %{${varName}.${varPattern.sourceFieldAccess} | ${fieldPattern.fieldName}: ${valueCompiled}}';
    }
    
    /**
     * Compile TIf expressions with Y combinator detection
     * 
     * WHY: Conditional expressions need special handling for Y combinator patterns and proper Elixir syntax
     * 
     * @param econd Condition expression
     * @param eif Then branch expression  
     * @param eelse Else branch expression (nullable)
     * @return Compiled Elixir if-do-else expression
     */
    public function compileIfExpression(econd: TypedExpr, eif: TypedExpr, eelse: Null<TypedExpr>): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] IF COMPILATION START");
        trace('[XRay ControlFlowCompiler] Has else branch: ${eelse != null}');
        #end
        
        // IDIOMATIC IMPLEMENTATION: Convert to Elixir if-else patterns
        var condition = compiler.compileExpression(econd);
        var thenBranch = compiler.compileExpression(eif);
        var elseBranch = eelse != null ? compiler.compileExpression(eelse) : "nil";
        
        // Generate idiomatic Elixir if-else
        var result = if (elseBranch != "nil") {
            'if ${condition} do\n      ${thenBranch}\n    else\n      ${elseBranch}\n    end';
        } else {
            'if ${condition} do\n      ${thenBranch}\n    end';
        };
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated if: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] IF COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TSwitch expressions to Elixir case-do-end patterns
     * 
     * WHY: Pattern matching requires specialized handling for exhaustive case analysis
     * 
     * @param e Switch target expression
     * @param cases Array of case patterns and expressions
     * @param edef Default case expression (nullable)
     * @param context Optional function context for field assignment transformation
     * @return Compiled Elixir case-do-end expression
     */
    public function compileSwitchExpression(e: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, edef: Null<TypedExpr>, ?context: FunctionContext): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] SWITCH COMPILATION START");
        trace('[XRay ControlFlowCompiler] Cases count: ${cases.length}');
        trace('[XRay ControlFlowCompiler] Has default: ${edef != null}');
        trace('[XRay ControlFlowCompiler] Has context: ${context != null}');
        trace('[XRay ControlFlowCompiler] Switch expression type: ${e.expr}');
        if (context != null) {
            trace('[XRay ControlFlowCompiler] Context struct param: ${context.structParamName}');
        }
        #end
        
        // CRITICAL FIX: Detect TSwitch(TEnumIndex(expr)) patterns early to prevent double-nested case expressions
        // This must happen BEFORE the switch expression gets compiled by EnumIntrospectionCompiler
        // Debug output removed
        
        // Unwrap TParenthesis and TMeta layers to find underlying TEnumIndex
        var unwrappedExpr = e;
        while (true) {
            switch (unwrappedExpr.expr) {
                case TParenthesis(innerExpr):
                    unwrappedExpr = innerExpr;
                case TMeta(_, innerExpr):
                    unwrappedExpr = innerExpr;
                case _:
                    break;
            }
        }
        
        // Debug output removed
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Unwrapped expression type: ${Type.enumConstructor(unwrappedExpr.expr)}');
        #end
        
        switch (unwrappedExpr.expr) {
            case TEnumIndex(innerExpr):
                // Found TEnumIndex in switch - check for Result/Option types
                #if debug_control_flow_compiler
                trace("[XRay ControlFlowCompiler] ✓ DETECTED TEnumIndex in switch - checking for Result/Option types");
                trace('[XRay ControlFlowCompiler] Inner expression type: ${innerExpr.t}');
                #end
                
                // Check if this is a Result or Option type that should be compiled directly
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] Checking inner expression type: ${Type.enumConstructor(innerExpr.t)}');
                #end
                
                switch (innerExpr.t) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        #if debug_control_flow_compiler
                        trace('[XRay ControlFlowCompiler] Found TEnum with name: ${enumType.name}');
                        #end
                        if (enumType.name == "Result" || enumType.name == "Option") {
                            #if debug_control_flow_compiler
                            trace('[XRay ControlFlowCompiler] ✓ FOUND ${enumType.name} TYPE - compiling direct patterns');
                            #end
                            
                            // Compile directly without enum index conversion - bypass double-nesting
                            return compileDirectResultOptionSwitch(innerExpr, enumType.name, cases, edef, context);
                        } else {
                            #if debug_control_flow_compiler
                            trace('[XRay ControlFlowCompiler] TEnum type is: ${enumType.name} (not Result/Option)');
                            #end
                        }
                    case _:
                        // Not a TEnum type, use standard compilation
                        #if debug_control_flow_compiler
                        trace('[XRay ControlFlowCompiler] Not a TEnum type, falling through to standard compilation');
                        #end
                        #if debug_control_flow_compiler
                        trace("[XRay ControlFlowCompiler] Not a TEnum type, using standard compilation");
                        #end
                }
            case _:
                // Not a TEnumIndex expression, use standard compilation
                #if debug_control_flow_compiler
                trace("[XRay ControlFlowCompiler] Not a TEnumIndex expression, using standard compilation");
                #end
        }
        
        // CRITICAL FIX: Clear any incorrect g -> g_counter mapping before switch compilation
        // This prevents the switch from using the wrong variable name
        var savedGMapping = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            var existingMapping = compiler.currentFunctionParameterMap.get("g");
            if (StringTools.endsWith(existingMapping, "_counter")) {
                trace('[XRay ControlFlowCompiler] ⚠️ REMOVING incorrect g -> ${existingMapping} mapping before switch compilation');
                compiler.currentFunctionParameterMap.remove("g");
                savedGMapping = existingMapping;
            }
        }
        
        // Standard compilation for non-Result/Option switches
        var result = compiler.compileSwitchExpression(e, cases, edef);
        
        // Don't restore the incorrect mapping
        if (savedGMapping != null) {
            trace('[XRay ControlFlowCompiler] ✓ NOT restoring incorrect g -> ${savedGMapping} mapping');
        }
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated switch: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] SWITCH COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile Result/Option switches directly without TEnumIndex double-nesting
     * 
     * WHY: TEnumIndex creates double-nested case expressions like:
     *      case (case g do {:ok, _} -> 0; {:error, _} -> 1; _ -> -1 end) do
     *      We want clean patterns like: case g do {:ok, value} -> ...; {:error, error} -> ... end
     * 
     * WHAT: Bypass EnumIntrospectionCompiler and generate direct Result/Option patterns
     * 
     * HOW: Convert integer case patterns (0, 1) to semantic patterns ({:ok, _}, {:error, _})
     * 
     * @param innerExpr The expression containing the Result/Option value  
     * @param enumTypeName "Result" or "Option"
     * @param cases Array of switch cases with integer patterns
     * @param edef Optional default case expression
     * @param context Function context for parameter mapping
     * @return Clean Elixir case statement without double-nesting
     */
    private function compileDirectResultOptionSwitch(
        innerExpr: TypedExpr,
        enumTypeName: String, 
        cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
        edef: Null<TypedExpr>,
        ?context: FunctionContext
    ): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] ✓ DIRECT RESULT/OPTION COMPILATION START");
        trace('[XRay ControlFlowCompiler] Enum type: ${enumTypeName}');
        trace('[XRay ControlFlowCompiler] Cases to convert: ${cases.length}');
        #end
        
        // Clean variable mapping for common variables like 'g' to prevent conflicts
        var savedGMapping: Null<String> = null;
        if (compiler.currentFunctionParameterMap.exists("g")) {
            savedGMapping = compiler.currentFunctionParameterMap.get("g");
            compiler.currentFunctionParameterMap.remove("g");
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] Temporarily removed g mapping: g -> ${savedGMapping}');
            #end
        }
        
        // CRITICAL FIX: Use proper variable compilation to apply snake_case mappings
        // Don't extract raw names - use VariableCompiler which handles:
        // - camelCase to snake_case conversion (bulkAction -> bulk_action)
        // - Variable name mappings from currentFunctionParameterMap
        // - Proper handling of special variables like 'g'
        var innerExprStr = switch (innerExpr.expr) {
            case TLocal(localVar): 
                // Use VariableCompiler to properly compile the variable reference
                // This ensures camelCase variables are converted to snake_case
                var variableCompiler = new VariableCompiler(compiler);
                variableCompiler.compileLocalVariable(localVar);
            case _: 
                // Fallback to regular compilation for non-local expressions
                compiler.compileExpression(innerExpr);
        };
        // Final variable name extracted for case statement
        
        // Restore g mapping if it wasn't a counter variable
        if (savedGMapping != null && !StringTools.endsWith(savedGMapping, "_counter")) {
            compiler.currentFunctionParameterMap.set("g", savedGMapping);
        }
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Inner expression compiled to: ${innerExprStr}');
        #end
        
        // Convert integer-based cases to semantic patterns
        var caseStrings: Array<String> = [];
        
        for (caseData in cases) {
            for (value in caseData.values) {
                var pattern = switch (value.expr) {
                    case TConst(TInt(0)): // Success constructor (Ok/Some)
                        if (enumTypeName == "Result") "{:ok, _}" else "{:ok, _}";
                    case TConst(TInt(1)): // Error/None constructor
                        if (enumTypeName == "Result") "{:error, _}" else ":error";
                    case _: "_"; // Default/catch-all pattern
                };
                
                // Compile the case body with specialized handling for Result/Option types
                var body = compileResultOptionCaseBody(caseData.expr, innerExprStr, enumTypeName, value.expr);
                caseStrings.push('  ${pattern} -> ${body}');
                
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] Generated direct pattern: ${pattern} -> [compiled body]');
                #end
            }
        }
        
        // Add default case if present
        if (edef != null) {
            var defaultBody = compiler.compileExpression(edef);
            caseStrings.push('  _ -> ${defaultBody}');
            #if debug_control_flow_compiler
            trace("[XRay ControlFlowCompiler] Added default case");
            #end
        }
        
        var result = 'case ${innerExprStr} do\n${caseStrings.join("\n")}\nend';
        
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] ✓ DIRECT RESULT/OPTION COMPILATION END");
        trace('[XRay ControlFlowCompiler] Generated clean case: ${result.substring(0, 100)}...');
        #end
        
        return result;
    }
    
    /**
     * Compile case body for Result/Option switches with direct value extraction
     * 
     * WHY: Standard expression compilation generates nested case expressions for 
     *      TEnumParameter expressions, creating double-nested patterns. We need
     *      direct value extraction instead.
     * WHAT: Analyzes case body AST and generates appropriate direct value access
     * HOW: Detects TEnumParameter patterns and replaces with direct tuple access
     * 
     * @param expr Case body expression (may contain TEnumParameter)
     * @param varName Variable name being matched (e.g., "g")
     * @param enumTypeName "Result" or "Option" for pattern-specific extraction
     * @param caseValue The case pattern value expression (TInt(0), TInt(1), etc.)
     */
    function compileResultOptionCaseBody(expr: TypedExpr, varName: String, enumTypeName: String, caseValue: TypedExprDef): String {
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Compiling Result/Option case body with direct extraction');
        trace('[XRay ControlFlowCompiler] Case expression type: ${Type.enumConstructor(expr.expr)}');
        #end
        
        // Analyze the case body for TEnumParameter patterns
        return switch (expr.expr) {
            case TEnumParameter(e, ef, index):
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] Found TEnumParameter - generating direct extraction');
                trace('[XRay ControlFlowCompiler] Enum field: ${ef.name}, index: ${index}');
                #end
                
                // Generate direct tuple access based on the case type
                switch (caseValue) {
                    case TConst(TInt(0)): // Success case - extract value from tuple
                        if (enumTypeName == "Result") {
                            // For {:ok, value} pattern, extract the value directly
                            'elem(${varName}, 1)';
                        } else {
                            // For {:ok, value} pattern in Option, extract the value
                            'elem(${varName}, 1)';
                        }
                    case TConst(TInt(1)): // Error/None case - extract error value
                        if (enumTypeName == "Result") {
                            // For {:error, reason} pattern, extract the error
                            'elem(${varName}, 1)';
                        } else {
                            // Option None case - no value to extract
                            'nil';
                        }
                    case _:
                        // Fallback to regular compilation for complex patterns
                        compiler.compileExpression(expr);
                };
                
            case _:
                // For non-TEnumParameter expressions, use regular compilation
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] Non-TEnumParameter case body - using standard compilation');
                #end
                compiler.compileExpression(expr);
        };
    }
    
    /**
     * Compile TWhile expressions to Y combinator recursive patterns
     * 
     * WHY: While loops in functional languages require recursive patterns rather than imperative loops.
     *      Additionally, Haxe desugars array operations into while loops that should be detected
     *      and converted to idiomatic Enum functions.
     * 
     * @param econd Loop condition expression
     * @param ebody Loop body expression
     * @param normalWhile Whether this is a normal while loop (vs do-while)
     * @return Compiled Elixir code (Enum function or Y combinator pattern)
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] WHILE COMPILATION START");
        trace('[XRay ControlFlowCompiler] Normal while: ${normalWhile}');
        trace('[XRay ControlFlowCompiler] Delegating to LoopCompiler for pattern detection...');
        #end
        
        // Delegate to LoopCompiler for pattern detection and optimization
        // LoopCompiler will check for desugared array operations and generate
        // idiomatic Enum functions when possible
        var result = compiler.loopCompiler.compileWhileLoop(econd, ebody, normalWhile);
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] LoopCompiler result: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] WHILE COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TFor expressions to idiomatic Elixir Enum operations
     * 
     * WHY: For loops require sophisticated pattern detection and optimization for
     *      idiomatic Elixir code generation. This functionality is specialized in LoopCompiler.
     * 
     * WHAT: Delegates to LoopCompiler which provides comprehensive optimization:
     *       - Pattern detection (map, filter, find, count, Reflect.fields)
     *       - Variable substitution for clean lambda parameters
     *       - Enum function selection based on loop body analysis
     *       - Y combinator patterns for complex loops
     * 
     * HOW: Direct delegation to specialized LoopCompiler ensures consistent
     *      optimization patterns and maintains centralized loop logic.
     * 
     * @param tvar Loop variable
     * @param iterExpr Iterable expression
     * @param blockExpr Loop body expression
     * @return Compiled Elixir Enum operation with appropriate optimizations
     */
    public function compileForLoop(tvar: TVar, iterExpr: TypedExpr, blockExpr: TypedExpr): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] DELEGATING FOR COMPILATION TO LoopCompiler");
        trace('[XRay ControlFlowCompiler] Loop variable: ${tvar.name}');
        #end
        
        // DELEGATE to LoopCompiler for sophisticated pattern detection and optimization
        var result = compiler.loopCompiler.compileForLoop(tvar, iterExpr, blockExpr);
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] LoopCompiler result: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] FOR COMPILATION DELEGATION COMPLETE");
        #end
        
        return result;
    }
    
    /**
     * Compile TTry expressions to Elixir try-rescue-catch-after patterns
     * 
     * WHY: Exception handling requires proper transformation to Elixir's try-rescue syntax
     * 
     * @param e Try block expression
     * @param catches Array of catch clauses
     * @return Compiled Elixir try-rescue expression
     */
    public function compileTryExpression(e: TypedExpr, catches: Array<{v: TVar, expr: TypedExpr}>): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] TRY COMPILATION START");
        trace('[XRay ControlFlowCompiler] Catch clauses: ${catches.length}');
        #end
        
        // IDIOMATIC IMPLEMENTATION: Convert to Elixir try-rescue patterns
        var tryBody = compiler.compileExpression(e);
        
        // Convert catches to idiomatic Elixir rescue clauses
        var rescueClauses = [];
        for (c in catches) {
            // Simplified exception handling for now
            var catchVar = c.v.name;
            var catchBody = compiler.compileExpression(c.expr);
            rescueClauses.push('${catchVar} -> ${catchBody}');
        }
        
        var result = if (rescueClauses.length > 0) {
            'try do\n      ${tryBody}\n    rescue\n      ${rescueClauses.join("\n      ")}\n    end';
        } else {
            tryBody; // No catches, just return the try body
        };
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated try: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] TRY COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Detect desugared array operation patterns (filter/map)
     * 
     * WHY: Haxe desugars array.filter() and array.map() into TBlock with specific structure.
     *      We need to detect this pattern and generate idiomatic Enum functions.
     * 
     * @param el Array of expressions in block
     * @return Pattern info with generated code or null if not detected
     */
    /**
     * Detect desugared array operation patterns in TBlock expressions
     * 
     * WHY: Haxe desugars array.filter/map into complex TBlock/TWhile patterns
     * WHAT: Detects the 3-expression pattern and extracts components  
     * HOW: Analyzes TBlock structure for accumulator, loop, and assignment
     */
    private function detectDesugarredArrayOperation(el: Array<TypedExpr>): Null<{type: String, code: String}> {
        #if debug_array_desugaring
        trace('[ControlFlowCompiler] DETECTING DESUGARED ARRAY OPERATION - ${el.length} expressions');
        
        // Debug: Show the pattern structure
        for (i in 0...el.length) {
            var expr = el[i];
            switch(expr.expr) {
                case TVar(v, e):
                    var initStr = e != null ? "= " + (switch(e.expr) { case TArrayDecl([]): "[]"; case _: "other"; }) : "uninitialized";
                    trace('[ControlFlowCompiler] [${i}] TVar ${v.name} ${initStr}');
                case TBlock(_):
                    trace('[ControlFlowCompiler] [${i}] TBlock');
                case TLocal(v):
                    trace('[ControlFlowCompiler] [${i}] TLocal ${v.name}');
                case _:
                    trace('[ControlFlowCompiler] [${i}] ${Type.enumConstructor(expr.expr)}');
            }
        }
        #end
        // Looking for pattern:
        // [0] TVar _g = []  (accumulator)
        // [1] TBlock containing:
        //     - TVar _g1 = 0 (index)
        //     - TVar _g2 = source_array
        //     - TWhile(condition, body)
        // [2] TLocal _g (return accumulator)
        
        if (el.length < 3) return null;
        
        // Check first element: TVar _g = []
        var accumulatorVar: String = null;
        switch(el[0].expr) {
            case TVar(tvar, init) if (init != null):
                // Check if initializing to empty array
                switch(init.expr) {
                    case TArrayDecl([]):
                        accumulatorVar = CompilerUtilities.toElixirVarName(tvar);
                    case _:
                        return null;
                }
            case _:
                return null;
        }
        
        // Check second element: TBlock with while loop
        var sourceArray: TypedExpr = null;
        var whileLoop: TypedExpr = null;
        var indexVar: String = null;
        
        switch(el[1].expr) {
            case TBlock(innerExprs):
                #if debug_array_desugaring
                trace('[ControlFlowCompiler] Found TBlock with ${innerExprs.length} inner expressions');
                #end
                if (innerExprs.length >= 2) {
                    // Find index variable and while loop
                    for (expr in innerExprs) {
                        switch(expr.expr) {
                            case TVar(tvar, init) if (init != null):
                                // This should be index variable initialization (g1 = 0)
                                switch(init.expr) {
                                    case TConst(TInt(0)):
                                        indexVar = CompilerUtilities.toElixirVarName(tvar);
                                    case _:
                                        // Skip other variable types
                                }
                            case TWhile(econd, ebody, normalWhile):
                                whileLoop = expr;
                                // Extract source array from while condition
                                sourceArray = extractSourceArrayFromCondition(econd, indexVar);
                            case _:
                                // Skip other expressions
                        }
                    }
                }
            case _:
                return null;
        }
        
        if (sourceArray == null || whileLoop == null) return null;
        
        // Check if we have the pattern components (may be in different positions)
        // The third element varies - could be TLocal, TBinop, or something else
        #if debug_array_desugaring
        trace('[ControlFlowCompiler] Pattern check: accumulatorVar=${accumulatorVar}, sourceArray=${sourceArray != null}, whileLoop=${whileLoop != null}');
        #end
        
        if (sourceArray == null || whileLoop == null) {
            #if debug_array_desugaring
            trace('[ControlFlowCompiler] Missing components, not an array operation pattern');
            #end
            return null;
        }
        
        #if debug_array_desugaring
        trace('[ControlFlowCompiler] ✓ FOUND ARRAY OPERATION PATTERN!');
        #end
        
        // Now analyze the while loop to determine if it's filter or map
        var patternType = analyzeWhileLoopPattern(whileLoop);
        if (patternType == null) return null;
        
        // Generate idiomatic Enum function
        var arrayExpr = compiler.compileExpression(sourceArray);
        var code = switch(patternType.type) {
            case "filter":
                var condition = compiler.compileExpression(patternType.condition);
                'Enum.filter(${arrayExpr}, fn ${patternType.itemVar} -> ${condition} end)';
            case "map":
                var transformation = compiler.compileExpression(patternType.transformation);
                'Enum.map(${arrayExpr}, fn ${patternType.itemVar} -> ${transformation} end)';
            case _:
                null;
        };
        
        if (code == null) return null;
        
        return {type: patternType.type, code: code};
    }
    
    /**
     * Extract source array from while loop condition
     * 
     * WHY: The source array isn't a separate TVar - it's embedded in condition like (g1 < items.length)
     * WHAT: Analyzes TBinop condition to extract the array being iterated
     * HOW: Looks for pattern index < array.length and extracts array
     */
    private function extractSourceArrayFromCondition(condition: TypedExpr, indexVar: String): Null<TypedExpr> {
        switch(condition.expr) {
            case TBinop(OpLt, indexExpr, lengthExpr):
                // Expected pattern: indexVar < sourceArray.length
                switch(indexExpr.expr) {
                    case TLocal(indexVarRef):
                        var condIndexVar = CompilerUtilities.toElixirVarName(indexVarRef);
                        if (condIndexVar == indexVar) {
                            // Found matching index variable, extract array from length expression
                            switch(lengthExpr.expr) {
                                case TField(arrayExpr, field):
                                    // Check if this is accessing the length field
                                    // Use string representation as fallback since field access varies
                                    var fieldStr = compiler.compileExpression(lengthExpr);
                                    if (fieldStr != null && fieldStr.indexOf(".length") >= 0) {
                                        return arrayExpr; // This is our source array!
                                    }
                                case _:
                            }
                        }
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Analyze while loop to determine array operation type
     * 
     * @param whileExpr The while loop expression
     * @return Pattern info or null
     */
    private function analyzeWhileLoopPattern(whileExpr: TypedExpr): Null<{
        type: String,
        itemVar: String,
        condition: TypedExpr,
        transformation: TypedExpr
    }> {
        switch(whileExpr.expr) {
            case TWhile(econd, ebody, normalWhile):
                // Analyze body for filter/map pattern
                switch(ebody.expr) {
                    case TBlock(bodyExprs) if (bodyExprs.length >= 3):
                        // First: var v = array[index]
                        var itemVar: String = null;
                        if (bodyExprs.length > 0) {
                            switch(bodyExprs[0].expr) {
                                case TVar(tvar, init):
                                    itemVar = CompilerUtilities.toElixirVarName(tvar);
                                case _:
                            }
                        }
                        
                        if (itemVar == null) return null;
                        
                        // Third element (after increment): operation
                        if (bodyExprs.length > 2) {
                            switch(bodyExprs[2].expr) {
                                // Filter pattern: if (condition) push
                                case TIf(cond, thenExpr, null):
                                    return {
                                        type: "filter",
                                        itemVar: itemVar,
                                        condition: cond,
                                        transformation: null
                                    };
                                // Map pattern: push(transformation)
                                case TCall(e, [arg]):
                                    return {
                                        type: "map",
                                        itemVar: itemVar,
                                        condition: null,
                                        transformation: arg
                                    };
                                case _:
                            }
                        }
                    case _:
                }
            case _:
        }
        return null;
    }
    
    /**
     * Detect if a TEnumParameter expression is unused (orphaned 'g' variable pattern)
     * 
     * WHY: Haxe generates TEnumParameter expressions for enum destructuring even in empty 
     *      case bodies with only comments. This creates unused 'g = elem(spec, 1)' followed
     *      by standalone 'g' references that serve no purpose.
     * 
     * WHAT: Analyze the upcoming expressions to detect if this TEnumParameter:
     *       1. Extracts a parameter that gets assigned to 'g' variable
     *       2. Is followed by a standalone 'g' local reference  
     *       3. Has no other meaningful usage of the extracted parameter
     * 
     * HOW: Look ahead in the expression list to find the pattern:
     *      - TEnumParameter → generates 'g = elem(...)'
     *      - TLocal(g) → generates standalone 'g' 
     *      - No other usage → indicates orphaned variable
     * 
     * EDGE CASES:
     *      - Must have at least 2 expressions (TEnumParameter + TLocal)
     *      - Only affects 'g' variables (from loop transformations)
     *      - Validates no subsequent meaningful usage
     * 
     * @param expressions Array of expressions to analyze
     * @param currentIndex Current position in the expression array
     * @return True if this TEnumParameter should be skipped to prevent orphaned variables
     */
    private function isUnusedEnumParameterExpression(expressions: Array<TypedExpr>, currentIndex: Int): Bool {
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] CHECKING FOR UNUSED ENUM PARAMETER at index ${currentIndex}');
        #end
        
        if (currentIndex >= expressions.length) return false;
        
        var currentExpr = expressions[currentIndex];
        
        // Check if current expression is TEnumParameter and extract details
        var enumParamInfo = switch (currentExpr.expr) {
            case TEnumParameter(enumExpr, enumField, index): 
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] ✓ Found TEnumParameter');
                trace('[XRay ControlFlowCompiler]   - Enum field: ${enumField.name}');
                trace('[XRay ControlFlowCompiler]   - Parameter index: ${index}');
                #end
                {isEnum: true, fieldName: enumField.name, paramIndex: index};
            case _: 
                {isEnum: false, fieldName: "", paramIndex: -1};
        };
        
        if (!enumParamInfo.isEnum) {
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] ❌ Not a TEnumParameter expression');
            #end
            return false;
        }
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Checking if ${enumParamInfo.fieldName} parameter ${enumParamInfo.paramIndex} is orphaned...');
        #end
        
        // Look ahead for the orphaned variable pattern
        // Pattern: TEnumParameter followed by TLocal(g) with no meaningful usage
        var nextIndex = currentIndex + 1;
        if (nextIndex >= expressions.length) return false;
        
        var nextExpr = expressions[nextIndex];
        
        // Check if next expression is a TLocal reference to 'g' 
        // The orphaned pattern specifically involves 'g' variables from loop transformations
        var hasOrphanedLocal = switch (nextExpr.expr) {
            case TLocal(tvar): 
                // Be precise: Only 'g' variables from loop transformations are affected
                // These are typically named: g, _g, _g_1, _g_2, etc.
                var isGVariable = (tvar.name == "g" || 
                                  tvar.name == "_g" || 
                                  tvar.name.startsWith("_g_") ||
                                  tvar.name.startsWith("g_"));
                
                #if debug_control_flow_compiler
                if (isGVariable) {
                    trace('[XRay ControlFlowCompiler] ✓ Found orphaned local variable: ${tvar.name}');
                    trace('[XRay ControlFlowCompiler] Variable ID: ${tvar.id}');
                } else {
                    trace('[XRay ControlFlowCompiler] ❌ Local variable not orphaned pattern: ${tvar.name}');
                }
                #end
                isGVariable;
            case _: 
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] ❌ Next expression not TLocal');
                #end
                false;
        };
        
        if (!hasOrphanedLocal) return false;
        
        // Check if there are no meaningful expressions after the orphaned local
        // This indicates the parameter extraction serves no purpose
        var hasSubsequentUsage = false;
        for (i in (nextIndex + 1)...expressions.length) {
            var expr = expressions[i];
            switch (expr.expr) {
                case TConst(TString(_)): continue; // Skip string constants (comments)
                case TConst(TNull): continue;      // Skip null constants
                case TBlock([]): continue;         // Skip empty blocks
                case _: 
                    hasSubsequentUsage = true;
                    break;
            }
        }
        
        var isOrphaned = !hasSubsequentUsage;
        
        #if debug_control_flow_compiler
        if (isOrphaned) {
            trace('[XRay ControlFlowCompiler] ⚠️  DETECTED ORPHANED ENUM PARAMETER - will skip compilation');
        } else {
            trace('[XRay ControlFlowCompiler] ✓ Enum parameter has subsequent usage - will compile normally');
        }
        #end
        
        return isOrphaned;
    }
    
    /**
     * TODO: Future implementation will contain additional extracted logic:
     * 
     * - Full TBlock compilation with variable collision detection
     * - Reflect.fields pattern optimization  
     * - Y combinator detection and generation
     * - Pipeline pattern optimization
     * - Complex control flow nesting handling
     * - Debug tracing and pattern recognition
     * 
     * Each method above will be filled with the actual extracted logic
     * from the original compileElixirExpressionInternal function.
     */
}

#end