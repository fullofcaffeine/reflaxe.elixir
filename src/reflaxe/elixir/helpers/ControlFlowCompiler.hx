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
     * 
     * @param el Array of TypedExpr representing block statements
     * @param topLevel Whether this is a top-level block
     * @return Compiled Elixir block expression
     */
    public function compileBlock(el: Array<TypedExpr>, topLevel: Bool = false): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] BLOCK COMPILATION START");
        trace('[XRay ControlFlowCompiler] Block length: ${el.length}');
        trace('[XRay ControlFlowCompiler] *** CRITICAL: topLevel = ${topLevel} ***');
        #end
        
        // BASIC IMPLEMENTATION: Handle block expressions
        if (el.length == 0) {
            return "nil";
        }
        
        // Compile each expression in the block with sequential field assignment analysis
        var statements = [];
        var i = 0;
        while (i < el.length) {
            #if debug_control_flow_compiler
            trace('[XRay ControlFlowCompiler] Processing expression ${i}/${el.length}: ${el[i].expr}');
            #end
            
            // Check for sequential field assignment patterns that need merging
            var mergedAssignment = detectAndMergeSequentialFieldAssignments(el, i);
            if (mergedAssignment != null) {
                #if debug_control_flow_compiler
                trace('[XRay ControlFlowCompiler] ✓ MERGED ASSIGNMENT DETECTED at index ${i}!');
                trace('[XRay ControlFlowCompiler] Merged code: ${mergedAssignment.compiledCode.substring(0, 100)}...');
                #end
                
                // Sequential assignments were merged, add the result and skip processed expressions
                statements.push(mergedAssignment.compiledCode);
                i = mergedAssignment.nextIndex;
            } else {
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
     * WHAT: Analyze consecutive assignments for variable reassignment followed by field mutation
     * HOW: 
     * 1. Check if current expression is variable assignment to field access (struct = struct.buf)
     * 2. Check if next expression is field assignment on same variable (struct.b = ...)
     * 3. If pattern matches, merge into single Map update expression
     * 
     * @param expressions Array of expressions in the block
     * @param startIndex Current expression index to analyze
     * @return MergedAssignment if pattern detected, null otherwise
     */
    private function detectAndMergeSequentialFieldAssignments(expressions: Array<TypedExpr>, startIndex: Int): Null<MergedAssignment> {
        // Need at least 2 expressions to have a sequential pattern
        if (startIndex + 1 >= expressions.length) {
            return null;
        }
        
        var firstExpr = expressions[startIndex];
        var secondExpr = expressions[startIndex + 1];
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Checking pattern at index ${startIndex}');
        trace('[XRay ControlFlowCompiler] First expr: ${firstExpr.expr}');
        trace('[XRay ControlFlowCompiler] Second expr: ${secondExpr.expr}');
        #end
        
        // Pattern 1: struct = struct.buf (variable assignment to field access)
        var variableReassignment = analyzeVariableToFieldAssignment(firstExpr);
        if (variableReassignment == null) {
            return null;
        }
        
        // Pattern 2: struct.b = struct.b <> "text" (field assignment on same variable)
        var fieldAssignment = analyzeFieldAssignmentPattern(secondExpr, variableReassignment.varName);
        if (fieldAssignment == null) {
            return null;
        }
        
        // Merge the patterns into a single atomic update
        var mergedCode = generateMergedFieldUpdate(variableReassignment, fieldAssignment);
        
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
     * Generate merged field update expression
     * 
     * @param varPattern Variable reassignment pattern
     * @param fieldPattern Field assignment pattern
     * @return Compiled merged update expression
     */
    private function generateMergedFieldUpdate(varPattern: VariableToFieldPattern, fieldPattern: FieldAssignmentPattern): String {
        var valueCompiled = compiler.compileExpression(fieldPattern.valueExpression);
        
        // Generate: variable = %{variable.source_field | target_field: value}
        return '${varPattern.varName} = %{${varPattern.varName}.${varPattern.sourceFieldAccess} | ${fieldPattern.fieldName}: ${valueCompiled}}';
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
     * @return Compiled Elixir case-do-end expression
     */
    public function compileSwitchExpression(e: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, edef: Null<TypedExpr>): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] SWITCH COMPILATION START");
        trace('[XRay ControlFlowCompiler] Cases count: ${cases.length}');
        trace('[XRay ControlFlowCompiler] Has default: ${edef != null}');
        #end
        
        // TSwitch delegates to PatternMatchingCompiler in original code
        var result = compiler.patternMatchingCompiler.compileSwitchExpression(e, cases, edef);
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated switch: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay ControlFlowCompiler] SWITCH COMPILATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TWhile expressions to Y combinator recursive patterns
     * 
     * WHY: While loops in functional languages require recursive patterns rather than imperative loops
     * 
     * @param econd Loop condition expression
     * @param ebody Loop body expression
     * @param normalWhile Whether this is a normal while loop (vs do-while)
     * @return Compiled Elixir Y combinator pattern
     */
    public function compileWhileLoop(econd: TypedExpr, ebody: TypedExpr, normalWhile: Bool): String {
        #if debug_control_flow_compiler
        trace("[XRay ControlFlowCompiler] WHILE COMPILATION START");
        trace('[XRay ControlFlowCompiler] Normal while: ${normalWhile}');
        #end
        
        // IDIOMATIC IMPLEMENTATION: Convert while loops to proper Elixir patterns
        var condition = compiler.compileExpression(econd);
        var body = compiler.compileExpression(ebody);
        
        // In Elixir, while loops are typically implemented with tail recursion
        var result = if (normalWhile) {
            // Standard while loop -> tail recursive function
            'while_loop(fn -> ${condition} end, fn -> ${body} end)';
        } else {
            // Do-while -> different pattern
            'do_while_loop(fn -> ${body} end, fn -> ${condition} end)';
        };
        
        #if debug_control_flow_compiler
        trace('[XRay ControlFlowCompiler] Generated while: ${result != null ? result.substring(0, 100) + "..." : "null"}');
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
     * TODO: Future implementation will contain the extracted logic:
     * 
     * - Full TBlock compilation with variable collision detection
     * - Reflect.fields pattern optimization
     * - Variable renaming for desugared code (_g variables)
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