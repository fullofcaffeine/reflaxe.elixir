package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirAST.emptyMetadata;
import reflaxe.elixir.ast.ElixirASTPatterns;
import reflaxe.elixir.ast.ElixirASTPrinter;
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.naming.ElixirNaming;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.ast.ReentrancyGuard;
// Import builder modules
import reflaxe.elixir.ast.builders.ArrayBuilder;
import reflaxe.elixir.ast.builders.CoreExprBuilder;
import reflaxe.elixir.ast.builders.BinaryOpBuilder;
import reflaxe.elixir.ast.builders.LoopBuilder;
import reflaxe.elixir.ast.builders.PatternBuilder;
import reflaxe.elixir.ast.builders.EnumHandler;
import reflaxe.elixir.ast.builders.ComprehensionBuilder;
import reflaxe.elixir.ast.builders.LiteralBuilder;
import reflaxe.elixir.ast.builders.ControlFlowBuilder;
import reflaxe.elixir.ast.builders.CallExprBuilder;
import reflaxe.elixir.ast.builders.VariableBuilder;
import reflaxe.elixir.ast.builders.FieldAccessBuilder;
import reflaxe.elixir.ast.builders.SwitchBuilder;
import reflaxe.elixir.ast.builders.ExceptionBuilder;
import reflaxe.elixir.ast.builders.ReturnBuilder;
import reflaxe.elixir.ast.builders.BlockBuilder;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import reflaxe.elixir.ast.optimizers.LoopOptimizer;
import reflaxe.elixir.ast.intent.LoopIntent;
import reflaxe.elixir.ast.intent.LoopIntent.*;  // Import all enum constructors
import reflaxe.elixir.ast.transformers.DesugarredForDetector;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.helpers.PatternDetector;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;
using StringTools;

// ClauseContext has been extracted to src/reflaxe/elixir/ast/context/ClauseContext.hx

/**
 * ElixirASTBuilder: TypedExpr to ElixirAST Converter (Analysis Phase)
 * 
 * WHY: Bridge between Haxe's TypedExpr and our ElixirAST representation
 * - Preserves all semantic information from Haxe's type system
 * - Enriches nodes with metadata for later transformation phases
 * - Separates AST construction from string generation
 * - Enables multiple transformation passes on strongly-typed structure
 * - Handles synthetic bindings for Elixir-only temporaries
 * 
 * WHAT: Converts Haxe TypedExpr nodes to corresponding ElixirAST nodes
 * - Handles all expression types (literals, variables, operations, calls)
 * - Captures type information and source positions
 * - Detects patterns that need special handling (e.g., array operations)
 * - Maintains context through metadata enrichment
 * - Generates synthetic bindings for variables only used in Elixir injections
 * 
 * HOW: Recursive pattern matching on TypedExpr with metadata preservation
 * - Each TypedExpr constructor maps to one or more ElixirAST nodes
 * - Metadata carries context through the entire pipeline
 * - Complex expressions decomposed into simpler AST nodes
 * - Pattern detection integrated into conversion process
 * - Synthetic bindings wrapped around case clause bodies as needed
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only converts AST formats, no code generation
 * - Open/Closed: Easy to add new node types without modifying existing
 * - Testability: Can test AST conversion independently of generation
 * - Maintainability: Clear separation from transformation and printing
 * - Robustness: Handles Haxe optimizer removing "unused" variables
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */
class ElixirASTBuilder {
    // All state has been moved to CompilationContext - no more static variables!
    // This eliminates static state contamination during parallel test execution.

    // Module-level state (will be migrated to context in future)
    public static var currentModule: String = null;
    public static var currentModuleHasPresence: Bool = false;
    // REMOVED: currentClauseContext - Now using context.currentClauseContext for proper context propagation
    public static var switchNestingLevel: Int = 0; // Track how deep we are in nested switches

    // ================================================================
    // Compilation Instrumentation for Hanging Diagnosis
    // ================================================================
    #if debug_compilation_hang
    private static var recursionDepth: Int = 0;
    private static var maxRecursionDepth: Int = 0;
    private static var nodeProcessingCount: Map<String, Int> = new Map();
    private static var currentNodeStack: Array<String> = [];
    private static var lastProgressTime: Float = 0;
    private static var progressInterval: Float = 1000; // Log every 1 second
    private static var compilationStartTime: Float = 0;
    private static var totalNodesProcessed: Int = 0;
    private static var cycleDetectionMap: Map<String, Int> = new Map();
    private static var MAX_SAME_NODE_VISITS: Int = 100; // Detect cycles
    private static var MAX_TOTAL_NODES: Int = 100000; // Hang detection threshold

    private static function logCompilationProgress(message: String) {
        var now = haxe.Timer.stamp() * 1000;
        var elapsed = now - compilationStartTime;
        Sys.println('[HANG DEBUG ${elapsed}ms] Depth:${recursionDepth}/${maxRecursionDepth} Nodes:${totalNodesProcessed} - ${message}');
        lastProgressTime = now;
    }

    private static function enterNode(nodeType: String, exprDetails: String = "") {
        recursionDepth++;
        totalNodesProcessed++;
        if (recursionDepth > maxRecursionDepth) {
            maxRecursionDepth = recursionDepth;
        }

        // Check for compilation hang
        if (totalNodesProcessed > MAX_TOTAL_NODES) {
            Sys.println('[HANG DETECTED] Compilation exceeded ${MAX_TOTAL_NODES} nodes');
            Sys.println('[HANG DETECTED] Last node type: ${nodeType}');
            Sys.println('[HANG DETECTED] Expression details: ${exprDetails}');
            Sys.println('[HANG DETECTED] Stack depth: ${recursionDepth}');
            Sys.println('[HANG DETECTED] Current stack:');
            for (i in 0...Math.floor(Math.min(10, currentNodeStack.length))) {
                var idx = currentNodeStack.length - 1 - i;
                Sys.println('  [${idx}] ${currentNodeStack[idx]}');
            }
            throw 'Compilation hang detected after processing ${totalNodesProcessed} nodes. Possible infinite loop in AST processing.';
        }

        // Log progress every 10k nodes
        if (totalNodesProcessed % 10000 == 0) {
            logCompilationProgress('Processing node ${totalNodesProcessed}: ${nodeType}');
        }

        var nodeKey = '${nodeType}@depth${recursionDepth}';
        currentNodeStack.push(nodeKey);

        // Track visit count for cycle detection
        var visitCount = nodeProcessingCount.get(nodeType);
        if (visitCount == null) visitCount = 0;
        visitCount++;
        nodeProcessingCount.set(nodeType, visitCount);

        // Detect potential infinite loops
        if (visitCount > MAX_SAME_NODE_VISITS) {
            Sys.println('[HANG DEBUG] ⚠️ POTENTIAL INFINITE LOOP: ${nodeType} visited ${visitCount} times!');
            Sys.println('[HANG DEBUG] Current stack: ${currentNodeStack.join(" -> ")}');
            if (exprDetails != "") {
                Sys.println('[HANG DEBUG] Expression details: ${exprDetails}');
            }
        }

        // Progress logging
        var now = haxe.Timer.stamp() * 1000;
        if (now - lastProgressTime > progressInterval) {
            logCompilationProgress('Processing ${nodeType} ${exprDetails}');
        }

        // Log entry for significant nodes
        if (recursionDepth <= 3 || nodeType.indexOf("Module") >= 0 || nodeType.indexOf("Class") >= 0) {
            Sys.println('[HANG DEBUG] → Entering ${nodeType} at depth ${recursionDepth} ${exprDetails}');
        }
    }

    private static function exitNode(nodeType: String) {
        if (currentNodeStack.length > 0) {
            currentNodeStack.pop();
        }
        recursionDepth--;

        // Log exit for significant nodes
        if (recursionDepth <= 2 || nodeType.indexOf("Module") >= 0 || nodeType.indexOf("Class") >= 0) {
            Sys.println('[HANG DEBUG] ← Exiting ${nodeType} at depth ${recursionDepth}');
        }
    }

    private static function detectCycle(nodeId: String): Bool {
        var count = cycleDetectionMap.get(nodeId);
        if (count == null) count = 0;
        count++;
        cycleDetectionMap.set(nodeId, count);

        if (count > 10) { // Same exact node processed too many times
            Sys.println('[HANG DEBUG] 🔄 CYCLE DETECTED: Node ${nodeId} processed ${count} times!');
            return true;
        }
        return false;
    }
    #end
    
    /**
     * Reference to the compiler for dependency tracking
     * Set by ElixirCompiler when calling buildFromTypedExpr
     */
    @:allow(reflaxe.elixir.ElixirCompiler)
    @:allow(reflaxe.elixir.ast.builders.ModuleBuilder)
    public static var compiler: reflaxe.elixir.ElixirCompiler = null;
    
    /**
     * BehaviorTransformer: Pluggable behavior transformation system
     * 
     * WHY: Phoenix.Presence and other Elixir behaviors inject local functions
     * that have different calling conventions than their module counterparts.
     * The main compiler shouldn't have hardcoded knowledge of specific behaviors.
     * 
     * WHAT: Manages behavior-specific method call transformations based on
     * module metadata (@:presence, @:genserver, etc.) instead of hardcoded logic.
     * 
     * HOW: When compiling a module with behavior annotations, the transformer
     * is activated and intercepts method calls for behavior-specific handling.
     * 
     * @see reflaxe.elixir.behaviors.BehaviorTransformer
     * @see reflaxe.elixir.behaviors.PresenceBehaviorTransformer
     */
    public static var behaviorTransformer: reflaxe.elixir.behaviors.BehaviorTransformer = null;
    
    /**
     * Track module dependency when generating remote calls
     * 
     * WHY: Need to ensure modules are loaded in correct order for scripts
     * WHAT: Records that the current module depends on the specified module
     * HOW: Updates the compiler's moduleDependencies map
     */
    static function trackDependency(moduleName: String): Void {
        // Skip built-in Elixir modules that don't need loading
        var builtins = ["Map", "Enum", "String", "Kernel", "List", "IO", 
                        "Process", "GenServer", "Supervisor", "Agent", 
                        "File", "Path", "System", "Code", "Module", "Application",
                        "Integer", "Float", "Regex", "Date", "DateTime", "NaiveDateTime"];
        
        if (builtins.indexOf(moduleName) >= 0) {
            return; // Don't track built-in modules
        }
        
        if (currentContext.compiler != null && currentContext.compiler.currentCompiledModule != null) {
            var deps = currentContext.compiler.moduleDependencies.get(currentContext.compiler.currentCompiledModule);
            if (deps != null && moduleName != currentContext.compiler.currentCompiledModule) {
                // Don't track self-dependencies
                deps.set(moduleName, true);
                
                #if debug_dependencies
                #if debug_ast_builder
                trace('[ElixirASTBuilder] Module ${compiler.currentCompiledModule} depends on ${moduleName}');
                #end
                #end
            }
        }
    }
    
    /**
     * Get variable initialization value with infrastructure variable support
     * 
     * WHY: Infrastructure variables (_g, _g1) need their actual initialization values
     *      not their names when building accumulators
     * WHAT: Returns the tracked init value for infrastructure vars, or EVar for regular vars
     * HOW: Checks context.infrastructureVarInitValues map first, falls back to EVar
     * 
     * @param varName The variable name to get value for
     * @param context The current compilation context with tracking info
     * @return ElixirAST representing the variable's initial value
     */
    static function getVariableInitValue(varName: String, context: CompilationContext): ElixirAST {
        if (context.infrastructureVarInitValues != null && context.infrastructureVarInitValues.exists(varName)) {
            // Use the tracked initialization value (e.g., 0 for _g, 5 for _g1)
            return context.infrastructureVarInitValues.get(varName);
        } else {
            // For regular variables, use the variable reference
            return makeAST(EVar(varName));
        }
    }
    
    /**
     * Main entry point: Convert TypedExpr to ElixirAST
     * 
     * WHY: Single entry point for all AST conversion
     * WHAT: Recursively converts TypedExpr tree to ElixirAST tree
     * HOW: Pattern matches on expr type and delegates to specific handlers
     */
    /**
     * Replace TLocal references to a temp var with inline null coalescing pattern
     */
    static function replaceNullCoalVar(expr: TypedExpr, varId: Int, initExpr: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            case TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr) if (v.id == varId):
                // Replace with inline null coalescing that includes the init expression
                {
                    expr: TBinop(OpNullCoal, initExpr, defaultExpr),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TVar(v, init) if (init != null):
                // Variable declaration with initialization - recurse into init
                {
                    expr: TVar(v, replaceNullCoalVar(init, varId, initExpr)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TObjectDecl(fields):
                // Object declaration - recurse into field values
                var newFields = [for (field in fields) {
                    name: field.name,
                    expr: replaceNullCoalVar(field.expr, varId, initExpr)
                }];
                {
                    expr: TObjectDecl(newFields),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case _:
                // No transformation needed
                expr;
        }
    }
    
    /**
     * Substitute all occurrences of a variable with another expression.
     * Used for eliminating infrastructure variables by replacing them with their init expressions.
     */
    static function substituteVariable(expr: TypedExpr, varToReplace: TVar, replacement: TypedExpr): TypedExpr {
        return switch(expr.expr) {
            case TLocal(v) if (v.id == varToReplace.id):
                // Replace this local variable reference with the replacement expression
                replacement;
                
            case TSwitch(e, cases, edef):
                // Substitute in the switch expression and all cases
                var newExpr = substituteVariable(e, varToReplace, replacement);
                var newCases = [for (c in cases) {
                    values: [for (v in c.values) substituteVariable(v, varToReplace, replacement)],
                    expr: c.expr != null ? substituteVariable(c.expr, varToReplace, replacement) : null
                }];
                var newDefault = edef != null ? substituteVariable(edef, varToReplace, replacement) : null;
                {
                    expr: TSwitch(newExpr, newCases, newDefault),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TBlock(exprs):
                // Substitute in all block expressions
                {
                    expr: TBlock([for (e in exprs) substituteVariable(e, varToReplace, replacement)]),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TCall(e, args):
                // Substitute in function and arguments
                {
                    expr: TCall(substituteVariable(e, varToReplace, replacement),
                               [for (a in args) substituteVariable(a, varToReplace, replacement)]),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TField(e, fa):
                // Substitute in the object being accessed
                {
                    expr: TField(substituteVariable(e, varToReplace, replacement), fa),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TIf(cond, thenExpr, elseExpr):
                // Substitute in all branches
                {
                    expr: TIf(substituteVariable(cond, varToReplace, replacement),
                             substituteVariable(thenExpr, varToReplace, replacement),
                             elseExpr != null ? substituteVariable(elseExpr, varToReplace, replacement) : null),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TBinop(op, e1, e2):
                // Substitute in both operands
                {
                    expr: TBinop(op, 
                                substituteVariable(e1, varToReplace, replacement),
                                substituteVariable(e2, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TVar(v, init):
                // Don't substitute in variable declarations, but do substitute in init
                {
                    expr: TVar(v, init != null ? substituteVariable(init, varToReplace, replacement) : null),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TParenthesis(e):
                // Substitute in the inner expression of parenthesis
                {
                    expr: TParenthesis(substituteVariable(e, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TMeta(m, e):
                // Substitute in the expression with metadata
                {
                    expr: TMeta(m, substituteVariable(e, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TReturn(e):
                // Substitute in the return expression
                {
                    expr: TReturn(e != null ? substituteVariable(e, varToReplace, replacement) : null),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TUnop(op, postFix, e):
                // Substitute in unary operation
                {
                    expr: TUnop(op, postFix, substituteVariable(e, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TArray(e, index):
                // Substitute in array access
                {
                    expr: TArray(substituteVariable(e, varToReplace, replacement),
                                substituteVariable(index, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TEnumIndex(e):
                // Substitute in enum index operation
                {
                    expr: TEnumIndex(substituteVariable(e, varToReplace, replacement)),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TEnumParameter(e, ef, index):
                // Substitute in enum parameter extraction
                {
                    expr: TEnumParameter(substituteVariable(e, varToReplace, replacement), ef, index),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TCast(e, module):
                // Substitute in cast expression
                {
                    expr: TCast(substituteVariable(e, varToReplace, replacement), module),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TObjectDecl(fields):
                // Substitute in object declaration fields
                {
                    expr: TObjectDecl([for (f in fields) {
                        name: f.name,
                        expr: substituteVariable(f.expr, varToReplace, replacement)
                    }]),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case TArrayDecl(el):
                // Substitute in array declaration elements
                {
                    expr: TArrayDecl([for (e in el) substituteVariable(e, varToReplace, replacement)]),
                    pos: expr.pos,
                    t: expr.t
                };
                
            case _:
                // No substitution needed for other expression types
                expr;
        }
    }
    
    // Store the current context for recursive calls
    private static var currentContext: reflaxe.elixir.CompilationContext = null;

    // Public entry point for the compiler
    public static function buildFromTypedExpr(expr: TypedExpr, context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if debug_compilation_hang
        if (compilationStartTime == 0) {
            compilationStartTime = haxe.Timer.stamp() * 1000;
            Sys.println('[HANG DEBUG] === COMPILATION STARTED ===');
        }
        #end

        return buildFromTypedExprWithContext(expr, context);
    }

    // Helper for recursive calls - creates context from usage map if needed (for backward compatibility)
    private static function buildFromTypedExprHelper(expr: TypedExpr, usageMapOrContext: Dynamic): ElixirAST {
        // Check if we got a context or a usage map
        if (Std.isOfType(usageMapOrContext, reflaxe.elixir.CompilationContext)) {
            return buildFromTypedExprWithContext(expr, cast usageMapOrContext);
        } else {
            // Legacy call with usage map - use current context
            if (currentContext != null) {
                // Update the usage map in current context if provided
                if (usageMapOrContext != null) {
                    currentContext.variableUsageMap = cast usageMapOrContext;
                }
                return buildFromTypedExprWithContext(expr, currentContext);
            } else {
                // This shouldn't happen, but create a minimal context
                var ctx = new reflaxe.elixir.CompilationContext();
                ctx.variableUsageMap = cast usageMapOrContext;
                return buildFromTypedExprWithContext(expr, ctx);
            }
        }
    }

    private static function buildFromTypedExprWithContext(expr: TypedExpr, context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if debug_compilation_hang
        var exprType = Type.enumConstructor(expr.expr);
        var exprId = '${exprType}_${expr.pos}';

        // Debug circular reference issue
        if (exprType == "TParenthesis" || exprType == "TVar" || exprType == "TBinop") {
            Sys.println('[HANG DEBUG] Processing ${exprType} at ${expr.pos}');
            switch(expr.expr) {
                case TVar(v, _):
                    Sys.println('[HANG DEBUG]   TVar: ${v.name} (id: ${v.id})');
                case TParenthesis(e):
                    Sys.println('[HANG DEBUG]   TParenthesis wrapping: ${Type.enumConstructor(e.expr)}');
                case TBinop(op, _, _):
                    Sys.println('[HANG DEBUG]   TBinop operator: ${op}');
                default:
            }
        }

        // Only detect and report cycles - don't interfere with compilation
        detectCycle(exprId);
        enterNode(exprType, exprId);
        #end

        // Ensure compiler reference is set in context
        if (context.compiler == null && compiler != null) {
            context.compiler = compiler;
        }
        
        // Store context for recursive calls
        var previousContext = currentContext;
        currentContext = context;

        // Store the compilation context's usage map for context-aware variable naming
        // If no usage map provided in context, analyze now
        if (context.variableUsageMap != null) {
            // variableUsageMap is accessed via currentContext
        } else {
            // TODO: Restore when VariableUsageAnalyzer is available
            // Analyze usage for this expression if not already done
            // var variableUsageMap = reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(expr);
            // context.variableUsageMap = variableUsageMap;
            context.variableUsageMap = new Map();  // Temporary empty map
        }

        // Set compiler reference from context
        compiler = context.compiler;

        // Set behavior transformer from context
        behaviorTransformer = context.behaviorTransformer;

        // Also copy over other critical state from context to static variables
        // This is temporary during the migration phase
        // tempVarRenameMap is accessed via currentContext
        // underscorePrefixedVars is accessed via currentContext
        // Context fields are accessed via currentContext
        // Method context is now properly set by ElixirCompiler
        currentModule = context.currentModule;
        currentModuleHasPresence = context.currentModuleHasPresence;
        // No need to set currentClauseContext here - it's already part of the context

        #if debug_ast_builder
        trace('[XRay AST Builder] Converting TypedExpr: ${expr.expr}');
        if (currentContext.variableUsageMap != null) {
            #if debug_ast_builder
            trace('[XRay AST Builder] Using variable usage map with ${Lambda.count(currentContext.variableUsageMap)} entries');
            #end
        }
        #end

        // Do the actual conversion
        var metadata = createMetadata(expr);
        var astDef = convertExpression(expr);

        // CRITICAL FIX: If conversion returns null (skipped assignment), propagate the null
        // This allows TBlock to properly filter out redundant assignments
        if (astDef == null) {
            // Restore context before returning null
            currentContext = previousContext;
            return null;
        }

        // ONLY mark metadata - NO transformation in builder!
        // Check both direct enum constructor calls AND function calls that return idiomatic enums
        switch(expr.expr) {
            case TCall(e, _) if (e != null && PatternDetector.isEnumConstructor(e) && hasIdiomaticMetadata(e)):
                // Direct enum constructor call (e.g., ModuleRef("MyModule"))
                metadata.requiresIdiomaticTransform = true;
                metadata.idiomaticEnumType = switch(e.expr) {
                    case TField(_, FEnum(enumRef, _)): enumRef.get().name;
                    default: "";
                };
                #if debug_ast_builder
                trace('[AST Builder] Marked direct enum constructor for transformer: ${metadata.idiomaticEnumType}');
                #end
            case TCall(_, _):
                // Function call - check if it returns an idiomatic enum
                switch(expr.t) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        if (enumType.meta.has(":elixirIdiomatic")) {
                            metadata.requiresIdiomaticTransform = true;
                            metadata.idiomaticEnumType = enumType.name;
                            #if debug_ast_builder
                            trace('[AST Builder] Marked function return value as idiomatic enum: ${enumType.name}');
                            #end
                        }
                    default:
                }
            default:
        }

        var result = makeASTWithMeta(astDef, metadata, expr.pos);

        #if debug_ast_builder
        trace('[XRay AST Builder] Generated AST: ${astDef}');
        #end

        // Restore previous context
        currentContext = previousContext;

        #if debug_compilation_hang
        exitNode(exprType);
        #end

        return result;
    }
    
    /**
     * Convert TypedExprDef to ElixirASTDef
     */
    static function convertExpression(expr: TypedExpr): ElixirASTDef {
        #if debug_compilation_hang
        var nodeType = Type.enumConstructor(expr.expr);
        if (nodeType == "TSwitch" || nodeType == "TEnumIndex" || nodeType == "TWhile" || nodeType == "TFor") {
            Sys.println('[HANG DEBUG] 🎯 Processing critical node: ${nodeType} at pos ${expr.pos}');
        }
        #end

        return switch(expr.expr) {
            // ================================================================
            // Literals and Constants
            // ================================================================
            case TConst(c):
                // Delegate to LiteralBuilder for all constant handling
                LiteralBuilder.buildConst(c, expr, currentContext);
                
            // ================================================================
            // Variables and Binding
            // ================================================================
            case TLocal(v):
                // TLocal represents a local variable reference (reading/using a variable)
                // 
                // DIFFERENCE FROM TVar:
                // - TLocal: Variable usage/reference - when you READ a variable (x in "x + 1")
                // - TVar: Variable declaration/assignment - when you WRITE to a variable (var x = 5)
                //
                // EXAMPLES:
                // var x = 5;        // TVar(x, TConst(5)) - declaration with init
                // x = 10;           // TVar(x, TConst(10)) - assignment (reassignment in Elixir)
                // return x + 1;     // TLocal(x) in the expression - reading the variable
                // if (x > 0) ...    // TLocal(x) in the condition - reading the variable
                //
                // In Elixir both compile to the variable name, but the distinction helps
                // the compiler track declarations vs references for analysis purposes.
                var varName = VariableAnalyzer.toElixirVarName(v.name);
                EVar(varName);
                
            case TVar(v, init):
                // Delegate simple variable declarations to VariableBuilder
                // Complex patterns (blocks, comprehensions) are handled below
                if (init == null || isSimpleInit(init)) {
                    var result = VariableBuilder.buildVariableDeclaration(v, init, currentContext);
                    if (result != null) {
                        return result;
                    }
                }
                
                // COMPLETE FIX: Eliminate ALL infrastructure variable assignments at source
                // Use centralized detection from TypedExprPreprocessor
                var isInfrastructureVar = reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(v.name);
                
                // Debug: trace all infrastructure variable assignments to understand their structure
                #if debug_infrastructure_vars
                if (isInfrastructureVar && init != null) {
                    trace('[Infrastructure Variable Debug] TVar ${v.name} (id: ${v.id}) init type: ${Type.enumConstructor(init.expr)}');
                    switch(init.expr) {
                        case TField(obj, fa):
                            trace('[Infrastructure Variable Debug]   TField detected');
                        case TLocal(lv):
                            trace('[Infrastructure Variable Debug]   TLocal: ${lv.name}');
                        case _:
                            trace('[Infrastructure Variable Debug]   Other init type');
                    }
                }
                #end
                
                // CRITICAL: Track infrastructure variable mappings for switch targets
                // When _g = msg.type, we need to know that _g should use msg_type in the switch
                if (isInfrastructureVar && init != null) {
                    // First check if this is a field access that will be extracted in patterns
                    switch(init.expr) {
                        case TField(obj, fa):
                            // This is _g = something.field
                            // In switch patterns, this field will be extracted as a variable
                            var fieldName = extractFieldName(fa);
                            switch(obj.expr) {
                                case TLocal(localVar):
                                    // Pattern like _g = msg.type
                                    // When the switch extracts msg fields, type becomes msg_type
                                    var extractedVarName = VariableAnalyzer.toElixirVarName(localVar.name) + "_" + reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                                    
                                    // Store this mapping for later use in switch expressions
                                    // CRITICAL: Use variable NAME as key, not ID, since Haxe creates different IDs for the same variable
                                    if (currentContext.tempVarRenameMap == null) {
                                        currentContext.tempVarRenameMap = new Map();
                                    }
                                    // Map the infrastructure variable name to the extracted variable name
                                    currentContext.tempVarRenameMap.set(v.name, extractedVarName);
                                    
                                    #if debug_infrastructure_vars
                                    trace('[Infrastructure Variable Mapping] ${v.name} (id: ${v.id}) = ${localVar.name}.${fieldName} -> will use ${extractedVarName}');
                                    trace('[Infrastructure Variable Mapping] Storing in tempVarRenameMap: key="${v.name}" (name, not ID) value="${extractedVarName}"');
                                    #end
                                    
                                    // Still skip the assignment itself - we just tracked the mapping
                                    return null;
                                default:
                                    // Field access on something other than a local variable
                            }
                        case TEnumParameter(_, _, _):
                            // This is the problematic pattern: g = elem(tuple, index)
                            // In most cases, we skip it because the pattern already extracts these values
                            // BUT: We need to keep it if the variable is actually referenced later
                            #if debug_ast_builder
                            trace('[Infrastructure Variable Fix] TEnumParameter assignment for: ${v.name}');
                            #end
                            // Don't skip - let it be processed normally
                            // The assignment might be needed for later references
                            
                        case TLocal(localVar):
                            // Check if assigning from another infrastructure variable
                            var sourceVar = localVar.name;
                            if (sourceVar == "g" || sourceVar == "_g" || 
                                (sourceVar.length > 1 && sourceVar.charAt(0) == 'g') ||
                                (sourceVar.length > 2 && sourceVar.substr(0, 2) == "_g")) {
                                // Skip infrastructure variable chains like: g1 = g
                                #if debug_ast_builder
                                trace('[Infrastructure Variable Fix] Skipping chain assignment: ${v.name} = ${sourceVar}');
                                #end
                                return null;
                            }
                            
                        default:
                            // Other uses of infrastructure variables might be legitimate
                    }
                }
                
                #if debug_variable_usage
                if (v.name == "value" || v.name == "msg" || v.name == "err") {
                    #if debug_ast_builder
                    trace('[AST Builder] Processing TVar: ${v.name} (id: ${v.id})');
                    #end
                }
                #end

                // Don't register renamed variables here - we'll register them where we decide to emit clean names
                // This avoids false positives from legitimate variable names like "this1"
                #if debug_variable_renaming
                var renamedPattern = ~/^(.+?)(\d+)$/;
                if (renamedPattern.match(v.name)) {
                    #if debug_ast_builder
                    trace('[RENAME DEBUG] TVar: Found variable with numeric suffix "${v.name}" (id: ${v.id}) - will be handled at emission point');
                    #end
                }
                #end
                
                #if debug_loop_bodies
                // Debug TVar declarations that might be lost in loop bodies
                if (v.name == "meta" || v.name == "entry" || v.name == "userId") {
                    #if debug_ast_builder
                    trace('[XRay LoopBody] TVar declaration: ${v.name} = ${init != null ? "..." : "null"}');
                    #end
                    if (init != null) {
                        #if debug_ast_builder
                        trace('[XRay LoopBody] Init type: ${Type.enumConstructor(init.expr)}');
                        #end
                    }
                }
                #end
                
                #if debug_null_coalescing
                #if debug_ast_builder
                trace('[AST Builder] TVar: ${v.name}, init type: ${init != null ? Type.enumConstructor(init.expr) : "null"}');
                #end
                #end
                
                #if debug_assignment_context
                #if debug_ast_builder
                trace('[XRay AssignmentContext] TVar: ${v.name}');
                #end
                if (init != null) {
                    #if debug_ast_builder
                    trace('[XRay AssignmentContext] Init expr: ${Type.enumConstructor(init.expr)}');
                    #end
                    switch(init.expr) {
                        case TField(e, _):
                            #if debug_ast_builder
                            trace('[XRay AssignmentContext] TField access detected - likely in expression context');
                            #end
                        case _:
                    }
                }
                #end
                
                #if debug_ast_pipeline
                if (v.name == "p1" || v.name == "p2" || v.name == "p" || v.name == "p_1" || v.name == "p_2") {
                    #if debug_ast_builder
                    trace('[AST Builder] TVar declaration: name="${v.name}", id=${v.id}');
                    #end
                }
                #end
                
                #if debug_array_patterns
                if (init != null) {
                    #if debug_ast_builder
                    trace('[XRay ArrayPattern] TVar ${v.name} init: ${Type.enumConstructor(init.expr)}');
                    #end
                    // Check if this is an array map/filter initialization
                    switch(init.expr) {
                        case TBlock(exprs):
                            #if debug_ast_builder
                            trace('[XRay ArrayPattern] TVar contains TBlock with ${exprs.length} expressions');
                            #end
                        case _:
                    }
                }
                #end
                
                // Check for conditional comprehension pattern: var evens = { var g = []; if statements; g }
                if (init != null) {
                    switch(init.expr) {
                        case TBlock(blockStmts) if (blockStmts.length >= 3):
#if debug_map_literal
                            #if debug_ast_builder
                            trace('[MapLiteral Debug] TVar name=${v.name} id=${v.id} with block init (length=${blockStmts.length})');
                            #end
                            for (i in 0...blockStmts.length) {
                                #if debug_ast_builder
                                trace('  stmt[' + i + '] = ' + Type.enumConstructor(blockStmts[i].expr));
                                #end
                                switch(blockStmts[i].expr) {
                                    case TVar(tempVar, tempInit):
                                        var initKind = tempInit != null ? Type.enumConstructor(tempInit.expr) : "null";
                                        #if debug_ast_builder
                                        trace('    TVar ' + tempVar.name + ' init=' + initKind);
                                        #end
                                    case TBinop(op, lhs, rhs):
                                        #if debug_ast_builder
                                        trace('    TBinop op=' + Std.string(op) + ' lhs=' + Type.enumConstructor(lhs.expr) + ' rhs=' + Type.enumConstructor(rhs.expr));
                                        #end
                                    case TCall(func, args):
                                        #if debug_ast_builder
                                        trace('    TCall func=' + Type.enumConstructor(func.expr) + ' args=' + [for (a in args) Type.enumConstructor(a.expr)].join(","));
                                        #end
                                    case TLocal(localVar):
                                        #if debug_ast_builder
                                        trace('    TLocal name=' + localVar.name);
                                        #end
                                    case _:
                                }
                            }
#end
                            var mapLiteral = tryBuildMapLiteralFromBlock(blockStmts, currentContext);
                            if (mapLiteral != null) {
                                return EMatch(PVar(VariableAnalyzer.toElixirVarName(v.name)), mapLiteral);
                            }
                            // Check if this is a conditional comprehension pattern
                            var isConditionalComp = false;
                            var tempVarName = "";
                            
                            // First: var g = []
                            switch(blockStmts[0].expr) {
                                case TVar(tempVar, tempInit) if (tempInit != null && (tempVar.name.startsWith("g") || tempVar.name.startsWith("_g"))):
                                    switch(tempInit.expr) {
                                        case TArrayDecl([]):
                                            tempVarName = tempVar.name;
                                            
                                            // Check middle: TBlock with if statements
                                            if (blockStmts.length >= 3) {
                                                switch(blockStmts[1].expr) {
                                                    case TBlock(ifStmts):
                                                        // Check if all are if statements
                                                        var allIfs = true;
                                                        for (stmt in ifStmts) {
                                                            switch(stmt.expr) {
                                                                case TIf(_, _, null): // if with no else
                                                                    continue;
                                                                default:
                                                                    allIfs = false;
                                                                    break;
                                                            }
                                                        }
                                                        
                                                        // Check last: return g
                                                        if (allIfs && blockStmts.length > 2) {
                                                            switch(blockStmts[blockStmts.length - 1].expr) {
                                                                case TLocal(retVar) if (retVar.name == tempVarName):
                                                                    isConditionalComp = true;
                                                                default:
                                                            }
                                                        }
                                                    default:
                                                }
                                            }
                                        default:
                                    }
                                default:
                            }
                            
                            if (isConditionalComp) {
                                // trace('[DEBUG] Found conditional comprehension for var ${v.name}');
                                var reconstructed = ComprehensionBuilder.tryReconstructConditionalComprehension(blockStmts, tempVarName, currentContext);
                                if (reconstructed != null) {
                                    // trace('[DEBUG] Successfully reconstructed as for comprehension');
                                    return EMatch(PVar(VariableAnalyzer.toElixirVarName(v.name)), reconstructed);
                                }
                            }
                        default:
                    }
                }
                
                // Special handling for enum extraction patterns with variable origin tracking
                // When Haxe compiles case Ok(value), it generates:
                // 1. TVar(_g, TEnumParameter(...)) - extracts to temp (ExtractionTemp origin)
                // 2. TVar(value, TLocal(_g)) - assigns temp to actual variable (PatternBinder origin)
                // We track the origin to distinguish legitimate "g" variables from temp vars
                var isEnumExtraction = false;
                var extractedFromTemp = "";
                var shouldSkipRedundantExtraction = false;
                var varOrigin: ElixirAST.VarOrigin = UserDefined;  // Default to user-defined
                var tempToBinderMap: Map<Int, Int> = null;

                if (init != null) {
                    switch(init.expr) {
                        case TEnumParameter(e, _, index):
                            // This is the temp extraction: _g = result.elem(1)
                            isEnumExtraction = true;
                            varOrigin = ExtractionTemp;  // Mark as extraction temp

                            // Check if this is extracting from a pattern variable in a switch case
                            // Temp vars follow the pattern: g, g1, g2, etc.
                            var tempVarName = VariableAnalyzer.toElixirVarName(v.name);

                            #if debug_variable_origin
                            #if debug_ast_builder
                            trace('[Variable Origin] TEnumParameter extraction:');
                            #end
                            #if debug_ast_builder
                            trace('  - Variable: ${v.name} (id=${v.id})');
                            #end
                            #if debug_ast_builder
                            trace('  - Temp name: $tempVarName');
                            #end
                            #if debug_ast_builder
                            trace('  - Origin: ExtractionTemp');
                            #end
                            #if debug_ast_builder
                            trace('  - Index: $index');
                            #end
                            #end

                            // CRITICAL: Register pattern binding with ClauseContext
                            // When patterns use temp vars (g), we must track which TVar they map to
                            if (currentContext.currentClauseContext != null && tempVarName.charAt(0) == 'g') {
                                // This temp var will be used in the pattern, register the binding
                                // The pattern will have 'g' and this TVar extracts to 'g'
                                currentContext.currentClauseContext.pushPatternBindings([{varId: v.id, binderName: tempVarName}]);

                                #if debug_clause_context
                                #if debug_ast_builder
                                trace('[ClauseContext Integration] Registered pattern binding for TEnumParameter:');
                                #end
                                #if debug_ast_builder
                                trace('  - TVar ID ${v.id} maps to pattern var "$tempVarName"');
                                #end
                                #end
                            }

                            // Check if EnumBindingPlan already provides this variable
                            // If so, the pattern already extracts it correctly and we should skip this assignment
                            if (currentContext.currentClauseContext != null && currentContext.currentClauseContext.enumBindingPlan != null) {
                                var plan = currentContext.currentClauseContext.enumBindingPlan;
                                if (plan.exists(index)) {
                                    // The binding plan already handles this extraction in the pattern
                                    shouldSkipRedundantExtraction = true;
                                    #if debug_enum_extraction
                                    #if debug_ast_builder
                                    trace('[TVar] Skipping redundant TEnumParameter extraction - binding plan provides variable at index $index');
                                    #end
                                    #end
                                    return null; // Skip this assignment entirely
                                }
                            }

                            // Only treat as temp if it matches the g/g1/g2 pattern
                            if ((tempVarName == "g" || (tempVarName.length > 1 && tempVarName.charAt(0) == "g" &&
                                tempVarName.charAt(1) >= '0' && tempVarName.charAt(1) <= '9'))) {
                                // This variable assignment is redundant - the pattern already extracted it
                                shouldSkipRedundantExtraction = true;
                                #if debug_redundant_extraction
                                #if debug_ast_builder
                                trace('[TVar] Detected redundant extraction for $tempVarName (will be filtered at TBlock level)');
                                #end
                                #end
                            }

                        case TLocal(tempVar):
                            // Check if this is assignment from a temp var
                            if (tempVar.name.startsWith("_g") || tempVar.name == "g" || ~/^g\d+$/.match(tempVar.name)) {
                                // This is assignment from temp: value = g
                                extractedFromTemp = tempVar.name;
                                varOrigin = PatternBinder;  // This is the actual pattern variable

                                // CRITICAL: Update pattern binding in ClauseContext
                                // This is the second assignment: value = g
                                // After this point, references should use 'value' not 'g'
                                if (currentContext.currentClauseContext != null) {
                                    // Override the temp var binding with the user variable name
                                    var userVarName = VariableAnalyzer.toElixirVarName(v.name);
                                    currentContext.currentClauseContext.pushPatternBindings([{varId: v.id, binderName: userVarName}]);

                                    #if debug_clause_context
                                    #if debug_ast_builder
                                    trace('[ClauseContext Integration] Updated pattern binding after assignment:');
                                    #end
                                    #if debug_ast_builder
                                    trace('  - TVar ID ${v.id} now maps to user var "$userVarName" (was temp "${tempVar.name}")');
                                    #end
                                    #end
                                }

                                // If we have an EnumBindingPlan, these assignments are redundant
                                // because the pattern already uses the correct names
                                if (currentContext.currentClauseContext != null && currentContext.currentClauseContext.enumBindingPlan != null) {
                                    #if debug_enum_extraction
                                    #if debug_ast_builder
                                    trace('[TVar] Skipping redundant temp assignment ${v.name} = ${tempVar.name} - binding plan handles it');
                                    #end
                                    #end
                                    return null; // Skip this assignment entirely
                                }

                                // Create mapping from temp var ID to pattern var ID
                                if (tempToBinderMap == null) {
                                    tempToBinderMap = new Map<Int, Int>();
                                }
                                tempToBinderMap.set(tempVar.id, v.id);

                                #if debug_variable_origin
                                #if debug_ast_builder
                                trace('[Variable Origin] Pattern assignment from temp:');
                                #end
                                #if debug_ast_builder
                                trace('  - Pattern var: ${v.name} (id=${v.id})');
                                #end
                                #if debug_ast_builder
                                trace('  - Temp var: ${tempVar.name} (id=${tempVar.id})');
                                #end
                                #if debug_ast_builder
                                trace('  - Origin: PatternBinder');
                                #end
                                #if debug_ast_builder
                                trace('  - Mapping: ${tempVar.id} -> ${v.id}');
                                #end
                                #end
                            } else {
                                // Regular local assignment, check if the source is a pattern variable
                                // from an enum constructor (like RGB(r, g, b))
                                varOrigin = UserDefined;

                                #if debug_variable_origin
                                #if debug_ast_builder
                                trace('[Variable Origin] Regular local assignment:');
                                #end
                                #if debug_ast_builder
                                trace('  - Variable: ${v.name} (id=${v.id})');
                                #end
                                #if debug_ast_builder
                                trace('  - From: ${tempVar.name}');
                                #end
                                #if debug_ast_builder
                                trace('  - Origin: UserDefined');
                                #end
                                #end
                            }

                        case TSwitch(switchExpr, cases, edef):
                            #if debug_ast_builder
                            trace('[TSwitch] Switch expression detected in TVar init - delegating to SwitchBuilder');
                            trace('[TSwitch]   Switch has ${cases.length} cases');
                            trace('[TSwitch]   Has default: ${edef != null}');
                            #end
                            
                            // EverythingIsExprSanitizer lifts switch expressions to temp vars
                            // We need to properly build the switch expression here
                            varOrigin = UserDefined;

                            #if debug_everythingisexpr
                            trace('[TVar] Switch expression lifted by EverythingIsExprSanitizer detected');
                            trace('[TVar] Variable: ${v.name} will hold switch result');
                            trace('[TVar] Building proper case expression using SwitchBuilder');
                            #end

                            // CRITICAL FIX: Delegate to SwitchBuilder for proper handling
                            // Without this, the switch body is lost and only "value" appears
                            // This handles cases like unwrapOr where EverythingIsExprSanitizer lifts the switch

                        case _:
                            varOrigin = UserDefined;  // Default for other cases
                    }
                }
                
                // DON'T rename underscore variables in TVar - keep them as-is
                // The underscore indicates they are compiler-generated temporaries
                // and should be preserved to maintain consistency
                var varName = v.name;
                var idKey = Std.string(v.id);
                
                // Don't trust Reflaxe's unused metadata for TVar declarations
                // It's often incorrect for variables used in complex expressions
                //
                // EXAMPLE: In BalancedTree.balance(), variables like this:
                //   var k = match.k;  // TVar declaration, marked as -reflaxe.unused
                //   var v = match.v;  // TVar declaration, marked as -reflaxe.unused
                //   return new Node(k, v, left, right);  // Used here in TNew!
                //
                // The variables ARE used in the Node constructor call, but Reflaxe's
                // MarkUnusedVariablesImpl only detects TLocal references, missing TNew usage.
                // This causes incorrect underscore prefixing (_k, _v) while references
                // remain as (k, v), resulting in undefined variable errors.
                //
                // SOLUTION: We need the full function body context to properly detect usage,
                // which we don't have at TVar declaration time. That's why we handle this
                // in TFunction (lines 1100+) where we have access to the complete body
                // and can use our UsageDetector to accurately determine unused parameters.
                //
                var isUnused = false; // Disabled - proper detection happens at function level
                
                // For renamed temp variables, use the name directly without further conversion
                // Otherwise apply toElixirVarName for CamelCase conversion
                var baseName = if (currentContext.tempVarRenameMap.exists(idKey)) {
                    currentContext.tempVarRenameMap.get(idKey); // Use mapped name
                } else {
                    // Check if we have usage information from VariableUsageAnalyzer
                    var isUsed = if (currentContext.variableUsageMap != null) {
                        currentContext.variableUsageMap.exists(v.id) && currentContext.variableUsageMap.get(v.id);
                    } else {
                        true; // Conservative default: assume used if no usage map
                    };
                    
                    // For _g variables from Haxe, always strip the underscore
                    // Haxe generates _g, _g1, etc. for temporaries but in Elixir we want g, g1
                    // This keeps the names consistent between declaration and reference
                    if (varName.charAt(0) == "_" && varName.charAt(1) == "g") {
                        // Always strip underscore from _g variables for consistency
                        VariableAnalyzer.toElixirVarName(varName, false); // false = strip underscore
                    } else {
                        // For non-_g variables, normal conversion
                        VariableAnalyzer.toElixirVarName(varName, false);
                    }
                };
                
                // Check if variable is used
                var isActuallyUsed = if (currentContext.variableUsageMap != null && currentContext.variableUsageMap.exists(v.id)) {
                    currentContext.variableUsageMap.get(v.id);
                } else {
                    true; // Conservative: assume used if not in map
                };
                
                // Special handling for enum parameter extraction patterns
                // Even if marked as unused, these variables might be needed for pattern consistency
                var isEnumParameterExtraction = false;
                if (init != null) {
                    switch(init.expr) {
                        case TLocal(tempVar) if (tempVar.name.startsWith("_g") || tempVar.name == "g" || 
                                                 ~/^g\d*$/.match(tempVar.name)):
                            // This is assignment from temp: changeset = g 
                            // This is critical for enum pattern matching - we need this variable
                            // even if it appears unused, because it establishes the pattern variable name
                            isEnumParameterExtraction = true;
                            #if debug_variable_usage
                            #if debug_ast_builder
                            trace('[TVar] Variable ${v.name} is enum parameter extraction from ${tempVar.name}');
                            #end
                            #end
                        case _:
                    }
                }
                
                // If this variable is unused, prefix it with underscore to prevent Elixir warnings
                // EXCEPTION: Don't skip enum parameter extractions even if marked unused
                // This applies to:
                // 1. Variables extracted from enum parameters (changeset = g) - ALWAYS GENERATE
                // 2. Direct enum parameter extractions (g = result.elem(1))
                // 3. Any other unused variables detected by the analyzer
                var finalVarName = if (!isActuallyUsed && !isEnumParameterExtraction) {
                    #if debug_variable_usage
                    #if debug_ast_builder
                    trace('[TVar] Variable ${v.name} (id=${v.id}) is UNUSED, adding underscore prefix');
                    #end
                    #end
                    // Re-enable underscore prefixing for 1.0 quality
                    var underscoreName = "_" + baseName;
                    currentContext.tempVarRenameMap.set(Std.string(v.id), underscoreName);
                    underscoreName;
                } else {
                    // For used variables, also register to ensure consistency
                    // This prevents TLocal from applying different transformations
                    currentContext.tempVarRenameMap.set(Std.string(v.id), baseName);
                    baseName;
                };


                // Handle variable initialization
                var matchNode = if (init != null) {
                    #if debug_everythingisexpr
                    #if debug_ast_builder
                    trace('[TVar init] Processing init for ${v.name}, type: ${Type.enumConstructor(init.expr)}');
                    #end

                    // Check if this looks like a lifted switch (static methods returning switches often get this pattern)
                    if (v.name.startsWith("_g") || v.name == "temp_result" || v.name.contains("result")) {
                        #if debug_ast_builder
                        trace('[TVar init] Possible lifted switch variable: ${v.name}');
                        #end

                        // Log what we actually have
                        switch(init.expr) {
                            case TLocal(localVar):
                                #if debug_ast_builder
                                trace('[TVar init]   Init is TLocal: ${localVar.name}');
                                #end
                                // This is the problem - EverythingIsExprSanitizer replaced the switch with just a local reference
                            case TBlock(exprs):
                                #if debug_ast_builder
                                trace('[TVar init]   Init is TBlock with ${exprs.length} expressions');
                                #end
                                for (i in 0...exprs.length) {
                                    #if debug_ast_builder
                                    trace('[TVar init]     Expr[$i]: ${Type.enumConstructor(exprs[i].expr)}');
                                    #end
                                }
                            case TSwitch(e, cases, edef):
                                #if debug_ast_builder
                                trace('[TVar init]   TSwitch detected with ${cases.length} cases, default: ${edef != null}');
                                #end
                            default:
                                #if debug_ast_builder
                                trace('[TVar init]   Other type: ${Type.enumConstructor(init.expr)}');
                                #end
                        }
                    }
                    #end

                    // Check if init is a TBlock with null coalescing pattern
                    var initValue = switch(init.expr) {
                        case TBlock([{expr: TVar(tmpVar, tmpInit)}, {expr: TBinop(OpNullCoal, {expr: TLocal(localVar)}, defaultExpr)}])
                            if (localVar.id == tmpVar.id && tmpInit != null):
                            // This is null coalescing pattern: generate inline if expression
                            var tmpVarName = VariableAnalyzer.toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                            var initAst = buildFromTypedExpr(tmpInit, currentContext);
                            var defaultAst = buildFromTypedExpr(defaultExpr, currentContext);
                            
                            // Generate: if (tmp = init) != nil, do: tmp, else: default
                            var ifExpr = makeAST(EIf(
                                makeAST(EBinary(NotEqual, 
                                    makeAST(EMatch(PVar(tmpVarName), initAst)),
                                    makeAST(ENil)
                                )),
                                makeAST(EVar(tmpVarName)),
                                defaultAst
                            ));
                            // Mark as inline for null coalescing
                            if (ifExpr.metadata == null) ifExpr.metadata = {};
                            ifExpr.metadata.keepInlineInAssignment = true;
                            ifExpr;
                            
                        case _:
                            // Check if init is an unrolled array comprehension pattern
                            // Pattern: TBlock containing "g = []" followed by "g = g ++ [value]" statements
                            var initExpr = switch(init.expr) {
                                case TBlock(stmts) if (stmts.length > 2):
                                    #if debug_array_patterns
                                    #if debug_ast_builder
                                    trace('[XRay ArrayPattern] Checking TBlock with ${stmts.length} statements for unrolled comprehension');
                                    #end
                                    for (i in 0...stmts.length) {
                                        #if debug_ast_builder
                                        trace('[XRay ArrayPattern]   stmt[$i]: ${Type.enumConstructor(stmts[i].expr)}');
                                        #end
                                        // Check if stmt[1] is a nested TBlock
                                        if (i == 1) {
                                            switch(stmts[i].expr) {
                                                case TBlock(innerStmts):
                                                    #if debug_ast_builder
                                                    trace('[XRay ArrayPattern]     stmt[1] is a TBlock with ${innerStmts.length} inner statements');
                                                    #end
                                                    for (j in 0...Std.int(Math.min(3, innerStmts.length))) {
                                                        #if debug_ast_builder
                                                        trace('[XRay ArrayPattern]       inner[$j]: ${Type.enumConstructor(innerStmts[j].expr)}');
                                                        #end
                                                    }
                                                default:
                                            }
                                        }
                                    }
                                    #end
                                    
                                    // Check for unrolled comprehension pattern:
                                    // 1. First stmt: var g = []
                                    // 2. Middle stmts: g = g ++ [value]
                                    // 3. Last stmt: g (return the temp var)
                                    var isUnrolled = false;
                                    var tempVarName = "";
                                    var values = [];
                                    
                                    // Check first statement
                                    if (stmts.length > 0) {
                                        switch(stmts[0].expr) {
                                            case TVar(v, initExpr) if (initExpr != null && (v.name.startsWith("g") || v.name.startsWith("_g"))):
                                                #if debug_array_patterns
                                                #if debug_ast_builder
                                                trace('[XRay ArrayPattern] Found TVar for ${v.name}, checking init type: ${initExpr != null ? Type.enumConstructor(initExpr.expr) : "null"}');
                                                #end
                                                #end
                                                switch(initExpr.expr) {
                                                    case TArrayDecl([]):
                                                        isUnrolled = true;
                                                        tempVarName = v.name;
                                                        #if debug_array_patterns
                                                        #if debug_ast_builder
                                                        trace('[XRay ArrayPattern] First statement matches: var ${v.name} = []');
                                                        #end
                                                        #end
                                                    default:
                                                        #if debug_array_patterns
                                                        #if debug_ast_builder
                                                        trace('[XRay ArrayPattern] First statement init is not empty array');
                                                        #end
                                                        #end
                                                }
                                            default:
                                                #if debug_array_patterns
                                                #if debug_ast_builder
                                                trace('[XRay ArrayPattern] First statement is not a TVar with g-prefix');
                                                #end
                                                #end
                                        }
                                    }
                                    
                                    // If first statement matches, check for concatenations
                                    // Note: The concatenations might be in a nested TBlock at position 1
                                    if (isUnrolled && stmts.length > 1) {
                                        var concatStatements = [];
                                        
                                        // Check if stmt[1] is a nested TBlock
                                        switch(stmts[1].expr) {
                                            case TBlock(innerStmts):
                                                // Concatenations are inside this nested block
                                                concatStatements = innerStmts;
                                            default:
                                                // Concatenations are directly in the main block
                                                concatStatements = [for (i in 1...stmts.length - 1) stmts[i]];
                                        }
                                        
                                        // Now check all concatenation/push statements
                                        for (stmt in concatStatements) {
                                            switch(stmt.expr) {
                                                // Pattern 1: g = g ++ [value]
                                                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([elem])})})
                                                    if (v.name == tempVarName && v2.name == tempVarName):
                                                    // Found concatenation: g = g ++ [value]
                                                    values.push(elem);
                                                    
                                                // Pattern 2: g.push(value) - this is what Haxe generates for constant ranges
                                                case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, [arg])
                                                    if (v.name == tempVarName && cf.get().name == "push"):
                                                    // Found push: g.push(value)
                                                    values.push(arg);
                                                    
                                                default:
                                                    // Not a concatenation or push, continue
                                            }
                                        }
                                        
                                        // If we found no values, it's not an unrolled comprehension
                                        if (values.length == 0) {
                                            isUnrolled = false;
                                        }
                                    }
                                    
                                    // Check last statement returns the temp var
                                    if (isUnrolled && stmts.length > 0) {
                                        switch(stmts[stmts.length - 1].expr) {
                                            case TLocal(v) if (v.name == tempVarName):
                                                // Valid pattern
                                            default:
                                                isUnrolled = false;
                                        }
                                    }
                                    
                                    if (isUnrolled && values.length > 0) {
                                        #if debug_array_patterns
                                        #if debug_ast_builder
                                        trace('[XRay ArrayPattern] TVar init detected as unrolled comprehension with ${values.length} values');
                                        #end
                                        #end
                                        
                                        // Build a proper list from the extracted values
                                        var valueASTs = [for (v in values) buildFromTypedExpr(v, currentContext)];
                                        makeAST(EList(valueASTs));
                                    } else {
                                        // Not an unrolled comprehension, build normally
                                        buildFromTypedExpr(init, currentContext);
                                    }
                                    
                                case TSwitch(_, _, _):
                                    // Special handling for switch expressions lifted by EverythingIsExprSanitizer
                                    // These need to be built as complete case expressions
                                    #if debug_everythingisexpr
                                    #if debug_ast_builder
                                    trace('[TVar init] Building TSwitch expression for ${v.name}');
                                    #end
                                    #end

                                    // Build the switch expression directly
                                    var switchAST = buildFromTypedExpr(init, currentContext);

                                    #if debug_everythingisexpr
                                    if (switchAST != null) {
                                        #if debug_ast_builder
                                        trace('[TVar init] Switch AST generated successfully');
                                        #end
                                    } else {
                                        #if debug_ast_builder
                                        trace('[TVar init] WARNING: Switch AST is null!');
                                        #end
                                    }
                                    #end

                                    switchAST;

                                default:
                                    // Regular init expression
                                    buildFromTypedExpr(init, currentContext);
                            };

                            initExpr;
                    };
                    
                    // Check if we should skip this assignment
                    // Following Codex's architecture guidance: use ID-based tracking
                    var shouldSkipAssignment = false;

                    // ID-BASED TRACKING: Check if this TVar ID is satisfied by pattern extraction
                    if (init != null && currentContext.currentClauseContext != null &&
                        currentContext.currentClauseContext.isVarIdSatisfiedByPattern(v.id)) {

                        // This variable is already extracted by the pattern - skip redundant assignment
                        shouldSkipAssignment = true;

                        #if debug_redundant_extraction
                        #if debug_ast_builder
                        trace('[TVar] ID-based detection: Skipping assignment for TVar ${v.id} (${v.name}) - already satisfied by pattern');
                        #end
                        #end
                    } else if (init != null) {
                        // Fallback: Check for self-assignments that would be problematic
                        switch(init.expr) {
                            case TEnumParameter(e, ef, index):
                                // CRITICAL: Check what TEnumParameter would return BEFORE building it
                                // This avoids creating g = g assignments
                                if (currentContext.currentClauseContext != null) {
                                    var hasPlan = currentContext.currentClauseContext.enumBindingPlan.exists(index);

                                    if (hasPlan) {
                                        var info = currentContext.currentClauseContext.enumBindingPlan.get(index);

                                        if (info.finalName == finalVarName) {
                                            // This would create g = g
                                            shouldSkipAssignment = true;
                                        } else {
                                            // Fall through to check initValue
                                        }

                                        if (!shouldSkipAssignment && info.finalName != null && info.finalName.length > 0) {
                                            var planIsTemp = PatternDetector.isTempPatternVarName(info.finalName);
                                            var lhsIsTemp = PatternDetector.isTempPatternVarName(finalVarName);
                                            if (lhsIsTemp && !planIsTemp) {
                                                shouldSkipAssignment = true;
                                            }
                                        }
                                    }
                                }

                                // Fallback: check the already-built initValue
                                if (!shouldSkipAssignment && initValue != null) {
                                    switch(initValue.def) {
                                        case EVar(varName):
                                            if (varName == finalVarName) {
                                                // This would create a self-assignment like "g = g"
                                                shouldSkipAssignment = true;
                                                #if debug_enum_extraction
                                                #if debug_ast_builder
                                                trace('[TVar] Skipping self-assignment from TEnumParameter: $finalVarName = $varName');
                                                #end
                                                #end
                                            }
                                        case _:
                                            // Normal extraction, keep it
                                            #if debug_enum_extraction
                                            #if debug_ast_builder
                                            trace('[TVar] Keeping TEnumParameter extraction: $finalVarName');
                                            #end
                                            #end
                                    }
                                } else if (!shouldSkipAssignment) {
                                    // TEnumParameter already returned null, skip the assignment
                                    shouldSkipAssignment = true;
                                    #if debug_enum_extraction
                                    #if debug_ast_builder
                                    trace('[TVar] Skipping TEnumParameter assignment - initValue is null');
                                    #end
                                    #end
                                }
                            default:
                        }

                        // Fallback TLocal handling (separate from enum-specific logic above)
                        if (!shouldSkipAssignment && init != null) {
                            switch(init.expr) {
                                case TLocal(tempVar):
                                var tempVarName = tempVar.name;

                                #if debug_ast_builder
                                trace('[DEBUG EMBEDDED] Checking assignment: $finalVarName = $tempVarName');
                                #end
                                #if debug_ast_builder
                                trace('[DEBUG EMBEDDED] Is in case clause: ${currentContext.currentClauseContext != null}');
                                #end
                                #if debug_enum_extraction
                                #if debug_ast_builder
                                trace('[TVar TLocal] Checking assignment: $finalVarName = $tempVarName');
                                #end
                                #if debug_ast_builder
                                trace('[TVar TLocal] Is in case clause: ${currentContext.currentClauseContext != null}');
                                #end
                                #end

                                // FIX: When patterns use canonical names, assignments from temp vars that don't exist
                                // should be skipped entirely. The pattern already binds the correct variable.
                                // Example: pattern {:ok, value} already binds value, so "value = g" is wrong (g doesn't exist)
                                // Handle both bare "g" patterns and underscore-prefixed "_g" patterns
                                var isTempVar = false;
                                if (tempVarName == "g" || tempVarName == "_g") {
                                    isTempVar = true;
                                } else if (tempVarName.length > 1) {
                                    // Check for g1, g2, etc. OR _g1, _g2, etc.
                                    if (tempVarName.charAt(0) == "g" && tempVarName.charAt(1) >= '0' && tempVarName.charAt(1) <= '9') {
                                        isTempVar = true;
                                    } else if (tempVarName.length > 2 && tempVarName.charAt(0) == "_" &&
                                               tempVarName.charAt(1) == "g" && tempVarName.charAt(2) >= '0' && tempVarName.charAt(2) <= '9') {
                                        isTempVar = true;
                                    }
                                }

                                #if debug_ast_builder
                                trace('[DEBUG EMBEDDED] Temp analysis -> tempVar? $isTempVar, lhsTemp? ${PatternDetector.isTempPatternVarName(finalVarName)}');
                                #end

                                #if debug_enum_extraction
                                #if debug_ast_builder
                                trace('[TVar TLocal] Is temp var: $isTempVar');
                                #end
                                #end

                                if (isTempVar) {
                                    // This is trying to assign from a temp var (g, g1, g2, _g, _g1, _g2, etc.)
                                    // Check if we're assigning to a variable that was already bound by the pattern
                                    var elixirTempName = VariableAnalyzer.toElixirVarName(tempVarName);

                                    // EMBEDDED SWITCH FIX: Skip assignments where pattern already extracted the value
                                    // Pattern {:some, action} already binds "action", so "action = g" is invalid
                                    if (elixirTempName == "g" ||
                                        (elixirTempName.charAt(0) == "g" && elixirTempName.length > 1 &&
                                         elixirTempName.charAt(1) >= '0' && elixirTempName.charAt(1) <= '9')) {
                                        shouldSkipAssignment = true;
                                        #if debug_ast_builder
                                        trace('[DEBUG EMBEDDED] WILL SKIP: $finalVarName = $elixirTempName');
                                        #end
                                        #if debug_enum_extraction
                                        #if debug_ast_builder
                                        trace('[TVar TLocal] EMBEDDED SWITCH FIX: Skipping invalid temp var assignment: $finalVarName = $elixirTempName');
                                        #end
                                        #end
                                    }

                                    // Additional check: Skip redundant self-assignments like "value = value"
                                    if (finalVarName == tempVarName) {
                                        shouldSkipAssignment = true;
                                        #if debug_enum_extraction
                                        #if debug_ast_builder
                                        trace('[TVar] Skipping redundant self-assignment: $finalVarName = $tempVarName');
                                        #end
                                        #end
                                    }
                                } else {
                                    // Check if this is a non-temp var assignment that creates redundancy
                                    // For example, when pattern uses canonical names and we try to assign from them
                                    if (finalVarName == tempVarName) {
                                        // Skip self-assignments like "value = value"
                                        shouldSkipAssignment = true;
                                        #if debug_enum_extraction
                                        #if debug_ast_builder
                                        trace('[TVar] Skipping redundant self-assignment: $finalVarName = $tempVarName');
                                        #end
                                        #end
                                    }
                                }
                                case _:
                                    // Other init expressions
                            }
                        }
                    }

                    // Note: Redundant enum extraction is now handled at TBlock level
                    // We generate the assignment here, but TBlock will filter it out if redundant
                    #if debug_ast_builder
                    trace('[DEBUG TVar] Final decision for ${finalVarName}: shouldSkipAssignment=${shouldSkipAssignment}');
                    #end
                    var result = if (shouldSkipAssignment) {
                        // Skip the assignment, return null to be filtered out by TBlock
                        // The TBlock handler at line 3036 filters out null expressions
                        null;
                    } else if (initValue == null) {
                        // If initValue is null (e.g., from skipped TEnumParameter or failed TCall), handle carefully
                        #if debug_ast_builder
                        trace('[DEBUG EMBEDDED TVar] WARNING: initValue is null for: $finalVarName (extractedFromTemp: $extractedFromTemp)');
                        trace('[TVar] This will cause undefined variable errors in generated code!');
                        #end
                        
                        // CRITICAL FIX: When initialization expression fails to build (returns null),
                        // we need to provide a fallback value to prevent undefined variables in the generated code.
                        // This typically happens with complex expressions like TodoPubSub.subscribe(TodoUpdates)
                        // that fail to build in certain contexts.
                        // 
                        // Generate a descriptive error value that will make the issue visible
                        // rather than silently producing broken code with undefined variables.
                        var fallbackValue = makeAST(ERaw('{:error, "[Compiler Error] Failed to build initialization for ' + finalVarName + '"}'));
                        
                        #if debug_ast_builder
                        trace('[TVar] Using fallback error tuple for null initValue to prevent undefined variable');
                        #end
                        
                        // Create the assignment with the fallback value
                        var matchNode = makeAST(EMatch(
                            PVar(finalVarName),
                            fallbackValue
                        ));
                        
                        // Add metadata to indicate this is a fallback
                        if (matchNode.metadata == null) matchNode.metadata = {};
                        // Using requiresTempVar to indicate special handling (isFallbackInit field doesn't exist)
                        matchNode.metadata.requiresTempVar = true;
                        matchNode.metadata.varOrigin = varOrigin;
                        matchNode.metadata.varId = v.id;
                        
                        // But if this was supposed to be an assignment from a temp var, we have a problem!
                        if (extractedFromTemp != null) {
                            #if debug_ast_builder
                            trace('[DEBUG g=g] ERROR: initValue is null but we need assignment from temp var $extractedFromTemp to $finalVarName');
                            #end
                        }
                        
                        matchNode;
                    } else {
                        // Check for self-assignment right before creating the match node
                        var shouldSkipSelfAssignment = false;
                        #if debug_ast_builder
                        trace('[DEBUG TVar Assignment] Checking assignment: $finalVarName = ${initValue.def}');
                        #end
                        switch(initValue.def) {
                            case EVar(varName):
                                #if debug_ast_builder
                                trace('[DEBUG TVar Assignment] Comparing: finalVarName="$finalVarName" vs varName="$varName"');
                                #end
                                if (varName == finalVarName) {
                                    // This is a self-assignment like "g = g" or "content = content"
                                    shouldSkipSelfAssignment = true;
                                    #if debug_ast_builder
                                    trace('[DEBUG TVar Assignment] SKIPPING self-assignment: $finalVarName = $varName');
                                    #end
                                }
                            case _:
                                #if debug_ast_builder
                                trace('[DEBUG TVar Assignment] Not a var assignment: ${initValue.def}');
                                #end
                                // Normal assignment
                        }

                        if (shouldSkipSelfAssignment) {
                            null;  // Skip self-assignments
                        } else {
                            var matchNode = makeAST(EMatch(
                            PVar(finalVarName),
                            initValue
                        ));

                        // Add variable origin metadata for use in transformer and printer phases
                        if (matchNode.metadata == null) matchNode.metadata = {};
                        matchNode.metadata.varOrigin = varOrigin;
                        matchNode.metadata.varId = v.id;
                        if (tempToBinderMap != null) {
                            matchNode.metadata.tempToBinderMap = tempToBinderMap;
                        }

                        #if debug_variable_origin
                        #if debug_ast_builder
                        trace('[Variable Origin] Added metadata to match node:');
                        #end
                        #if debug_ast_builder
                        trace('  - Variable: $finalVarName');
                        #end
                        #if debug_ast_builder
                        trace('  - Origin: $varOrigin');
                        #end
                        #if debug_ast_builder
                        trace('  - ID: ${v.id}');
                        #end
                        if (tempToBinderMap != null) {
                            #if debug_ast_builder
                            trace('  - Mappings: $tempToBinderMap');
                            #end
                        }
                        #end

                        matchNode;
                        }  // end shouldSkipSelfAssignment check
                    };
                    result;
                } else {
                    // Uninitialized variable - use nil
                    makeAST(EMatch(
                        PVar(finalVarName),
                        makeAST(ENil)
                    ));
                };
                if (matchNode != null) {
                    matchNode.def;  // Return the ElixirASTDef for TVar case  
                } else {
                    // Handle uninitialized variable declaration
                    EMatch(PVar(finalVarName), makeAST(ENil));
                }
                
            // ================================================================
            // Binary Operations
            // ================================================================
            case TBinop(op, e1, e2):
                // Handle assignments specially since they need pattern extraction
                var result = switch(op) {
                    case OpAssign:
                        // Assignment needs pattern extraction for the left side
                        var pattern = PatternBuilder.extractPattern(e1);
                        var rightAST = buildFromTypedExpr(e2, currentContext);
                        var shouldSkipAssign = false;
                        switch(pattern) {
                            case PVar(name):
                                var valueName = switch(rightAST != null ? rightAST.def : null) {
                                    case EVar(varName): varName;
                                    default: null;
                                };

                                if (PatternDetector.isTempPatternVarName(name)) {
                                    shouldSkipAssign = switch(rightAST != null ? rightAST.def : null) {
                                        case EVar(varName) if (varName == name || PatternDetector.isTempPatternVarName(varName)):
                                            true;
                                        default:
                                            false;
                                    };
                                } else if (valueName != null) {
                                    if (valueName == name) {
                                        shouldSkipAssign = true;
                                    } else if (PatternDetector.isTempPatternVarName(valueName)) {
                                        shouldSkipAssign = true;
                                    }
                                }
                            default:
                        }

                        if (shouldSkipAssign) {
                            null;
                        } else {
                            EMatch(pattern, rightAST);
                        }

                    case OpAssignOp(innerOp):
                        // Compound assignment: x += 1 becomes x = x + 1
                        var pattern = PatternBuilder.extractPattern(e1);
                        var leftAST = buildFromTypedExpr(e1, currentContext);
                        var rightAST = buildFromTypedExpr(e2, currentContext);

                        // Build the inner binary operation
                        var innerBinop = BinaryOpBuilder.buildBinopFromAST(
                            innerOp, leftAST, rightAST,
                            e1, e2,
                            function(s) return reflaxe.elixir.ast.NameUtils.toSnakeCase(s)
                        );
                        EMatch(pattern, innerBinop);

                    default:
                        // Regular binary operations
                        var leftAST = buildFromTypedExpr(e1, currentContext);
                        var rightAST = buildFromTypedExpr(e2, currentContext);

                        // Pass pre-built ASTs to BinaryOpBuilder
                        var ast = BinaryOpBuilder.buildBinopFromAST(
                            op, leftAST, rightAST,
                            e1, e2,  // Keep original exprs for type checking
                            function(s) return reflaxe.elixir.ast.NameUtils.toSnakeCase(s)
                        );
                        ast.def;
                };
                result;

            // ================================================================
            // Unary Operations
            // ================================================================
            case TUnop(op, postFix, e):
                // Special handling for OpNot with TBlock
                // This happens when Haxe desugars complex expressions like !map.exists(key)
                switch(op) {
                    case OpNot:
                        switch(e.expr) {
                            case TBlock([]):
                                // Empty block - just return not(nil)
                                EUnary(Not, makeAST(ENil));
                            case TBlock(exprs) if (exprs.length == 1):
                                // Single expression block - unwrap it
                                EUnary(Not, buildFromTypedExpr(exprs[0], currentContext));
                            case TBlock(exprs):
                                // Multiple expressions - this is the problematic case
                                // Extract all but the last expression as statements
                                var statements = [];
                                for (i in 0...exprs.length - 1) {
                                    statements.push(buildFromTypedExpr(exprs[i], currentContext));
                                }
                                // Apply not to the last expression
                                var lastExpr = buildFromTypedExpr(exprs[exprs.length - 1], currentContext);
                                statements.push(makeAST(EUnary(Not, lastExpr)));
                                // Return a block with statements
                                EBlock(statements);
                            default:
                                // Normal case - just apply not
                                var expr = buildFromTypedExpr(e, currentContext).def;
                                EUnary(Not, makeAST(expr));
                        }
                    case OpNeg: 
                        var expr = buildFromTypedExpr(e, currentContext).def;
                        EUnary(Negate, makeAST(expr));
                    case OpNegBits:
                        var expr = buildFromTypedExpr(e, currentContext).def;
                        EUnary(BitwiseNot, makeAST(expr));
                    case OpIncrement, OpDecrement:
                        // Elixir is immutable, so we need to handle increment/decrement carefully
                        // Pre-increment (++x): returns the incremented value
                        // Post-increment (x++): returns the original value (not supported in Elixir)
                        var one = makeAST(EInteger(1));
                        var builtExpr = buildFromTypedExpr(e, currentContext);
                        
                        if (!postFix) {
                            // Pre-increment/decrement: just return the computed value
                            // When used in TVar(i, TUnop(OpIncrement, g)), this becomes: i = g + 1
                            var operation = if (op == OpIncrement) {
                                EBinary(Add, builtExpr, one);
                            } else {
                                EBinary(Subtract, builtExpr, one);
                            };
                            operation;
                        } else {
                            // Post-increment/decrement: return the computed value
                            // When used in TVar context, let TVar handle the assignment
                            // This avoids double assignment like "i = g = g + 1"
                            var operation = if (op == OpIncrement) {
                                EBinary(Add, builtExpr, one);
                            } else {
                                EBinary(Subtract, builtExpr, one);
                            };
                            operation;
                        };
                    case OpSpread:
                        // Spread operator for destructuring
                        var builtExpr = buildFromTypedExpr(e, currentContext);
                        EUnquoteSplicing(builtExpr);
                }
                
            // ================================================================
            // Function Calls
            // ================================================================
            case TCall(e, el):
                // Delegated to CallExprBuilder for modularization
                CallExprBuilder.buildCall(e, el, currentContext);

            // ================================================================
            // Field Access
            // ================================================================
            case TField(e, fa):
                // Delegate simple field access to FieldAccessBuilder
                // But keep complex cases (ExUnit test context) here for now
                
                // Check if this is a simple case we can delegate
                var isSimpleCase = switch(fa) {
                    case FEnum(_, _): true;  // Enum constructors - delegate
                    case FStatic(_, _): !currentContext.isInExUnitTest;  // Static fields - delegate unless in test
                    case FAnon(_): !currentContext.isInExUnitTest;  // Anonymous fields - delegate unless in test  
                    case FInstance(_, _, _): !currentContext.isInExUnitTest;  // Instance fields - delegate unless in test
                    case FDynamic(_): true;  // Dynamic fields - delegate
                    case FClosure(_, _): true;  // Closures - delegate
                };
                
                if (isSimpleCase) {
                    var result = FieldAccessBuilder.build(e, fa, currentContext);
                    if (result != null) {
                        result;  // Return delegated result
                    } else {
                        // Fallback to original implementation if builder returns null
                        switch(fa) {
                            case FEnum(enumType, ef):
                                // Enum constructor reference (no arguments)
                                // Check if this enum is marked as @:elixirIdiomatic
                                var enumT = enumType.get();
                                if (enumT.meta.has(":elixirIdiomatic")) {
                                    // For idiomatic enums, generate atoms instead of tuples
                                    // OneForOne → :one_for_one
                                    var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                                    EAtom(atomName);
                                } else {
                                    // Regular enums: check if constructor has parameters
                                    // Simple constructors (no params) → :atom
                                    // Parameterized constructors → {:atom}
                                    
                                    // Check if the enum constructor has parameters
                                    var hasParameters = switch(ef.type) {
                                        case TFun(args, _): args.length > 0;
                                        default: false;
                                    };
                                    
                                    var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                                    
                                    if (hasParameters) {
                                        // Parameterized constructor - generate tuple
                                        // RGB(r, g, b) → {:rgb}  (parameters come later)
                                        ETuple([makeAST(EAtom(atomName))]);
                                    } else {
                                        // Simple constructor - generate plain atom
                                        // Red → :red
                                        // None → :none
                                        EAtom(atomName);
                                    }
                                }
                            default:
                                null;  // Other cases will fall through to original implementation
                        }
                    }
                } else {
                    // Complex cases (ExUnit test context) - keep original implementation
                    switch(fa) {
                    case FEnum(enumType, ef):
                        // This shouldn't happen since enum cases are simple, but keep as fallback
                        var enumT = enumType.get();
                        if (enumT.meta.has(":elixirIdiomatic")) {
                            var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                            EAtom(atomName);
                        } else {
                            var hasParameters = switch(ef.type) {
                                case TFun(args, _): args.length > 0;
                                default: false;
                            };
                            var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                            if (hasParameters) {
                                ETuple([makeAST(EAtom(atomName))]);
                            } else {
                                EAtom(atomName);
                            }
                        }
                    case FStatic(classRef, cf):
                        // Static field access
                        var className = classRef.get().name;
                        var fieldName = extractFieldName(fa);
                        
                        #if debug_ast_builder
                        trace('[AST TField] FStatic - className: $className, fieldName: $fieldName');
                        #if debug_ast_builder
                        trace('[AST TField] cf.get().name: ${cf.get().name}');
                        #end
                        #end
                        
                        #if debug_atom_generation
                        #if debug_ast_builder
                        trace('[Atom Debug TField] FStatic access: ${className}.${fieldName}');
                        #end
                        #end
                        
                        /**
                         * ENUM ABSTRACT WITH ATOM TYPE DETECTION
                         * 
                         * WHY: Enum abstract fields like TimeUnit.Millisecond lose their
                         * abstract type information when accessed. We need to check if
                         * the field's value should be an atom.
                         * 
                         * WHAT: Check if the field's type indicates it should be an Atom
                         * and if it has a constant string value.
                         * 
                         * HOW: 
                         * 1. Check the field's type to see if it's elixir.types.Atom
                         * 2. If it has a constant expression, extract the string value
                         * 3. Generate an EAtom instead of a field access
                         */
                        var field = cf.get();
                        var isAtomField = false;
                        
                        // Check if the field's type is elixir.types.Atom
                        // For enum abstract fields, the field type resolves to String,
                        // so we also need to check the containing class
                        switch (field.type) {
                            case TAbstract(abstractRef, _):
                                var abstractType = abstractRef.get();
                                if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Atom") {
                                    isAtomField = true;
                                }
                            case _:
                        }
                        
                        // If not detected via field type, check the containing class
                        // This handles enum abstract fields like TimeUnit.Millisecond
                        if (!isAtomField) {
                            var classType = classRef.get();
                            #if debug_atom_generation
                            #if debug_ast_builder
                            trace('[Atom Debug TField] Checking class ${classType.name} kind: ${classType.kind}');
                            #end
                            #end
                            switch (classType.kind) {
                                case KAbstractImpl(abstractRef):
                                    // Get the abstract type definition
                                    var abstractType = abstractRef.get();
                                    #if debug_atom_generation
                                    #if debug_ast_builder
                                    trace('[Atom Debug TField] Found abstract impl: ${abstractType.name}');
                                    #end
                                    #if debug_ast_builder
                                    trace('[Atom Debug TField] Abstract type: ${abstractType.type}');
                                    #end
                                    #end
                                    // Check the underlying type of the abstract
                                    switch (abstractType.type) {
                                        case TAbstract(underlyingRef, _):
                                            var underlyingType = underlyingRef.get();
                                            #if debug_atom_generation
                                            #if debug_ast_builder
                                            trace('[Atom Debug TField] Underlying type: ${underlyingType.pack.join(".")}.${underlyingType.name}');
                                            #end
                                            #end
                                            if (underlyingType.pack.join(".") == "elixir.types" && underlyingType.name == "Atom") {
                                                isAtomField = true;
                                                #if debug_atom_generation
                                                #if debug_ast_builder
                                                trace('[Atom Debug TField] DETECTED: Field is Atom type!');
                                                #end
                                                #end
                                            }
                                        case _:
                                    }
                                case _:
                            }
                        }
                        
                        // If this is an Atom-typed field with a constant value, generate an atom
                        if (isAtomField && field.expr() != null) {
                            #if debug_atom_generation
                            #if debug_ast_builder
                            trace('[Atom Debug TField] Field has expr, extracting value...');
                            #end
                            #end
                            // Get the field's expression value
                            switch (field.expr().expr) {
                                case TConst(TString(s)):
                                    // This is the string value of the enum abstract field
                                    // Generate an atom directly
                                    #if debug_atom_generation
                                    #if debug_ast_builder
                                    trace('[Atom Debug TField] Extracted string value: "${s}" -> generating atom :${s}');
                                    #end
                                    #end
                                    EAtom(s);
                                case _:
                                    #if debug_atom_generation
                                    #if debug_ast_builder
                                    trace('[Atom Debug TField] Field expr is not TConst(TString), falling through');
                                    #end
                                    #end
                                    // Not a string constant, fall back to normal field access
                                    fieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                                    var target = buildFromTypedExpr(e, currentContext);
                                    EField(target, fieldName);
                            }
                        } else {
                            #if debug_atom_generation
                            #if debug_ast_builder
                            trace('[Atom Debug TField] Not an atom field or no expr, using normal field access');
                            #end
                            #end
                            // Normal static field access
                            // Convert to snake_case for Elixir function names
                            fieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                            
                            // Always use full qualification for function references
                            // When a static method is passed as a function reference (not called directly),
                            // it needs to be fully qualified even within the same module
                            if (false) { // Disabled for now - always qualify
                                // Same module - just use the function name without module prefix
                                // This allows private functions to be called without qualification
                                EVar(fieldName);
                            } else {
                                // Different module or no current module context - use full qualification
                                
                                // CRITICAL FIX: For static fields on regular (non-extern) classes,
                                // we need to generate the module name directly when the base expression
                                // is TTypeExpr. This handles cases like TodoPubSub.subscribe properly.
                                var target = if (e != null) {
                                    switch(e.expr) {
                                        case TTypeExpr(m):
                                            // Direct module reference - use the module name
                                            var moduleName = moduleTypeToString(m);
                                            makeAST(EVar(moduleName));
                                        default:
                                            // Other expressions - build normally
                                            buildFromTypedExpr(e, currentContext);
                                    }
                                } else {
                                    null;
                                };
                                
                                // If target is null, we can't generate a proper field access
                                if (target == null) {
                                    #if debug_ast_builder
                                    trace('[ERROR TField] Failed to build target for static field ${className}.${fieldName}');
                                    #end
                                    // Return a placeholder that will be caught by TCall
                                    EVar("UnknownModule." + fieldName);
                                } else {
                                    // For static fields on extern classes with @:native, we already have the full module name
                                    // in the target. Just return EField which will be handled properly by TCall
                                    // when this is used in a function call context.
                                    //
                                    // The TCall handler will detect that this is a static method call on an extern class
                                    // and will generate the proper ERemoteCall.
                                    //
                                    // Note: Function references are now handled at the TCall level
                                    // when a function is passed as an argument to another function
                                    EField(target, fieldName);
                                }
                            }
                        }
                    case FAnon(cf):
                        // Anonymous field access - check for tuple pattern
                        var fieldName = cf.get().name;
                        var target = buildFromTypedExpr(e, currentContext);
                        
                        if (~/^_\d+$/.match(fieldName)) {
                            // This is a tuple field access like tuple._1, tuple._2
                            // Convert to elem(tuple, index) where index is 0-based
                            var index = Std.parseInt(fieldName.substr(1)) - 1; // _1 -> 0, _2 -> 1
                            ECall(null, "elem", [target, makeAST(EInteger(index))]);
                        } else {
                            // Regular anonymous field access - convert to snake_case
                            fieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                            EField(target, fieldName);
                        }
                    default:
                        // Regular field access (includes FInstance for instance methods)
                        var target = buildFromTypedExpr(e, currentContext);
                        var fieldName = extractFieldName(fa);
                        
                        // Convert to snake_case for Elixir method names
                        // This ensures struct.setLoop becomes struct.set_loop
                        var originalFieldName = fieldName;
                        fieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                        
                        #if debug_field_names
                        if (originalFieldName != fieldName) {
                            #if debug_ast_builder
                            trace('[AST Builder] Converting field name: $originalFieldName -> $fieldName');
                            #end
                        }
                        #end
                        
                        #if debug_ast_pipeline
                        // Debug field access on p1/p2 variables
                        switch(e.expr) {
                            case TLocal(v) if (v.name == "p1" || v.name == "p2"):
                                #if debug_ast_builder
                                trace('[AST Builder] Field access: ${v.name}.${fieldName} (id=${v.id})');
                                #end
                            default:
                        }
                        #end
                        
                        // Special handling for ExUnit test instance variable access
                        // In ExUnit tests, instance variables are accessed via the context map
                        // Transform: this.test_data -> context[:test_data]
                        if (currentContext.isInExUnitTest) {
                            #if debug_exunit
                            trace('[AST Builder] TField in ExUnit test - field: ${fieldName}, e.expr: ${Type.enumConstructor(e.expr)}');
                            switch(e.expr) {
                                case TLocal(v): trace('[AST Builder]   TLocal var: ${v.name}');
                                default:
                            }
                            #end
                            switch(e.expr) {
                                case TConst(TThis):
                                    // This is an instance variable access in an ExUnit test
                                    // Generate context[:field_name] pattern
                                    #if debug_exunit
                                    trace('[AST Builder] ExUnit instance field access via this: context[:${fieldName}]');
                                    #end
                                    // Convert field name to snake_case for Elixir
                                    var snakeFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                                    // Return context[:field_name] pattern
                                    EAccess(makeAST(EVar("context")), makeAST(EAtom(snakeFieldName)));
                                case TLocal(v) if (v.name == "struct"):
                                    // Sometimes the compiler generates a local variable named "struct"
                                    // In ExUnit tests, this should also map to context
                                    #if debug_exunit
                                    trace('[AST Builder] ExUnit field access via struct var: context[:${fieldName}]');
                                    #end
                                    var snakeFieldName = reflaxe.elixir.ast.NameUtils.toSnakeCase(fieldName);
                                    EAccess(makeAST(EVar("context")), makeAST(EAtom(snakeFieldName)));
                                default:
                                    // Not a 'this' reference, handle normally
                                    if (fieldName == "elem") {
                                        // Mark this as a tuple element access for later transformation
                                        // The transformer will convert this to proper elem() calls
                                        EField(target, fieldName);
                                    } else if (isMapAccess(e.t)) {
                                        // Detect map/struct access patterns
                                        EAccess(target, makeAST(EAtom(fieldName)));
                                    } else {
                                        EField(target, fieldName);
                                    }
                            }
                        } else {
                            // Special handling for tuple.elem(N) field access
                            // This occurs when switch statements on Result enums generate field access
                            // We need to prepare for transformation to elem(tuple, N) function calls
                            if (fieldName == "elem") {
                                // Mark this as a tuple element access for later transformation
                                // The transformer will convert this to proper elem() calls
                                EField(target, fieldName);
                            } else if (isMapAccess(e.t)) {
                                // Detect map/struct access patterns
                                EAccess(target, makeAST(EAtom(fieldName)));
                            } else {
                                EField(target, fieldName);
                            }
                        }
                    }  // Close switch(fa) for complex cases
                }
                
            // ================================================================
            // Array Operations (Delegated to ArrayBuilder)
            // ================================================================
            case TArrayDecl(el):
                ArrayBuilder.buildArrayDecl(el, currentContext);
                
            case TArray(e, index):
                ArrayBuilder.buildArrayAccess(e, index, currentContext);
                
            // ================================================================
            // Control Flow (Basic)
            // ================================================================
            case TIf(econd, eif, eelse):
                // Delegated to ControlFlowBuilder for modularization
                ControlFlowBuilder.buildIf(econd, eif, eelse, currentContext);
                
            case TBlock(el):
                // Delegate to BlockBuilder for modular handling
                var result = BlockBuilder.build(el, currentContext);
                if (result != null) {
                    return result;
                }
                
                // Fallback to legacy implementation (will be removed after testing)
                // Debug: Log ALL blocks to understand Haxe's desugaring patterns
                #if debug_ast_pipeline
                if (el.length > 0) {
                    trace('[XRay TBlock] ======= BLOCK START (${el.length} elements) =======');
                    for (i in 0...el.length) {
                        var exprStr = switch(el[i].expr) {
                            case TVar(v, init): 'TVar(${v.name}, init=${init != null ? "present" : "null"})';
                            case TSwitch(e, _, _): 
                                var switchOn = switch(e.expr) {
                                    case TLocal(v): 'TLocal(${v.name})';
                                    case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)): 
                                        var objStr = switch(obj.expr) {
                                            case TLocal(v): 'var:${v.name}';
                                            case TConst(TThis): 'this';
                                            default: 'obj';
                                        };
                                        'TField($objStr.${cf.get().name})';
                                    default: Std.string(e.expr).split("(")[0];
                                };
                                'TSwitch($switchOn, ...)';
                            case TLocal(v): 'TLocal(${v.name})';
                            case TField(e, FAnon(cf)) | TField(e, FInstance(_, _, cf)): 'TField(...${cf.get().name})';
                            default: Std.string(el[i].expr).split("(")[0];
                        };
                        trace('[XRay TBlock]   [$i]: $exprStr');
                    }
                    
                    // Check for infrastructure variable patterns regardless of block size
                    if (el.length >= 2) {
                        // Check last two elements for switch pattern
                        var checkIndex = el.length - 2;
                        switch([el[checkIndex].expr, el[checkIndex + 1].expr]) {
                            case [TVar(v, init), TSwitch(e, _, _)] if (reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(v.name)):
                                trace('[XRay TBlock] FOUND infrastructure var pattern: ${v.name} = ... ; switch(${v.name})');
                            default:
                        }
                    }
                    
                    // Check if we have a direct switch on field
                    if (el.length > 0) {
                        switch(el[el.length - 1].expr) {
                            case TSwitch(e, _, _):
                                switch(e.expr) {
                                    case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)):
                                        trace('[XRay TBlock] WARNING: FOUND direct switch on field: switch(obj.${cf.get().name})');
                                        trace('[XRay TBlock]   This should have been desugared but wasn\'t!');
                                    default:
                                }
                            default:
                            break;
                        }
                    }
                    #end
                    
                    // Debug: Log ALL blocks to understand Haxe's desugaring patterns
                    #if debug_ast_pipeline
                    if (el.length > 0) {
                        trace('[XRay TBlock] ======= BLOCK START (${el.length} elements) =======');
                        for (i in 0...el.length) {
                            var exprStr = switch(el[i].expr) {
                                case TVar(v, init): 'TVar(${v.name}, init=${init != null ? "present" : "null"})';
                                case TSwitch(e, _, _): 
                                    var switchOn = switch(e.expr) {
                                        case TLocal(v): 'TLocal(${v.name})';
                                        case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)): 
                                            var objStr = switch(obj.expr) {
                                                case TLocal(v): 'var:${v.name}';
                                                case TConst(TThis): 'this';
                                                default: 'obj';
                                            };
                                            'TField($objStr.${cf.get().name})';
                                        default: Std.string(e.expr).split("(")[0];
                                    };
                                    'TSwitch($switchOn, ...)';
                                case TLocal(v): 'TLocal(${v.name})';
                                case TField(e, FAnon(cf)) | TField(e, FInstance(_, _, cf)): 'TField(...${cf.get().name})';
                                default: Std.string(el[i].expr).split("(")[0];
                            };
                            trace('[XRay TBlock]   [$i]: $exprStr');
                        }
                        
                        // Check for infrastructure variable patterns regardless of block size
                        if (el.length >= 2) {
                            // Check last two elements for switch pattern
                            var checkIndex = el.length - 2;
                            switch([el[checkIndex].expr, el[checkIndex + 1].expr]) {
                                case [TVar(v, init), TSwitch(e, _, _)] if (reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(v.name)):
                                    trace('[XRay TBlock] FOUND infrastructure var pattern: ${v.name} = ... ; switch(${v.name})');
                                default:
                            }
                        }
                        
                        // Check if we have a direct switch on field
                        if (el.length > 0) {
                            switch(el[el.length - 1].expr) {
                                case TSwitch(e, _, _):
                                    switch(e.expr) {
                                        case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)):
                                            trace('[XRay TBlock] WARNING: FOUND direct switch on field: switch(obj.${cf.get().name})');
                                            trace('[XRay TBlock]   This should have been desugared but wasn\'t!');
                                        default:
                                    }
                                default:
                            }
                        }
                        trace('[XRay TBlock] ======= BLOCK END =======');
                    }
                    #end
                    
                    #if debug_null_coalescing
                    #if debug_ast_builder
                    trace('[AST Builder] TBlock with ${el.length} expressions');
                    #end
                    for (i in 0...el.length) {
                        #if debug_ast_builder
                        trace('[AST Builder]   Block[$i]: ${Type.enumConstructor(el[i].expr)}');
                        #end
                    }
                    #end
                    
                    // CRITICAL: Check for Map iteration pattern FIRST (before regular for loops)
                    // This detects patterns like: var iterator = map.keyValueIterator(); while(iterator.hasNext()) { var kv = iterator.next(); ... }
                    // and generates idiomatic Elixir: Enum.each(map, fn {key, value} -> ... end)
                    
                    // Actually check for Map iteration pattern as the comment says we should
                    if (el.length >= 2) {
                        // Add debug to see what expressions we're checking
                        #if debug_map_iteration
                        trace('[ElixirASTBuilder] Checking TBlock for Map iteration pattern...');
                        trace('  Block has ${el.length} expressions');
                        for (i in 0...Math.ceil(Math.min(3, el.length))) {
                            trace('  Expr[$i]: ${el[i].expr}');
                        }
                        #end
                        
                        // Delegate to LoopOptimizer for Map iteration detection
                        var mapPattern = LoopOptimizer.detectMapIterationPattern(el);
                        if (mapPattern != null) {
                            #if debug_map_iteration
                            trace('[ElixirASTBuilder] ✓ Detected Map iteration pattern, generating idiomatic Elixir');
                            trace('  Map expr: ${mapPattern.mapExpr}');
                            trace('  Key var: ${mapPattern.keyVar}');
                            trace('  Value var: ${mapPattern.valueVar}');
                            #end
                            return buildMapIteration(mapPattern, currentContext).def;
                        } else {
                            #if debug_map_iteration
                            trace('[ElixirASTBuilder] No Map iteration pattern detected in this block');
                            #end
                        }
                    }
                    
                    // CRITICAL: Check for desugared for loop pattern NEXT
                    // This detects patterns like: var g=0; var g1=5; while(g<g1){...}
                    // and generates idiomatic Elixir (Enum.each or comprehensions)
                    
                    #if debug_loop_detection
                    var featureEnabled = currentContext != null ? currentContext.isFeatureEnabled("loop_builder_enabled") : false;
                    trace('[ElixirASTBuilder] TBlock loop detection check: context=${currentContext != null}, elements=${el.length}, loop_builder=${featureEnabled}');
                    #end
                    
                    if (currentContext != null && currentContext.isFeatureEnabled("loop_builder_enabled")) {
                        #if debug_loop_detection
                        trace('[DesugarredForDetector] Attempting detection on TBlock with ${el.length} elements');
                        #end
                        var forPattern = DesugarredForDetector.detectAndEliminate(el);
                        if (forPattern != null) {
                            #if debug_loop_detection
                            trace('[ElixirASTBuilder] Detected desugared for loop at TBlock level with elimination data');
                            trace('  Counter: ${forPattern.counterVar} maps to user var: ${forPattern.userVar}');
                            trace('  Limit: ${forPattern.limitVar} to ${forPattern.endValue.expr}');
                            trace('  Is simple range: ${forPattern.eliminationData.isSimpleRange}');
                            trace('  Is array iteration: ${forPattern.eliminationData.isArrayIteration}');
                            #end
                            
                            // Create LoopIntent to capture the semantic intent of the loop
                            var loopIntent: LoopIntent = null;
                            var metadata: LoopIntentMetadata = {
                                wasDesugared: true,
                                infrastructureVars: [forPattern.counterVar, forPattern.limitVar],
                                sourcePos: expr.pos
                            };
                            
                            // Extract the while loop body using enhanced data
                            switch(forPattern.whileExpr.expr) {
                                case TWhile(cond, body, _):
                                    // Use the enhanced userVar from detectAndEliminate
                                    var userVarName: String = forPattern.userVar;
                                    #if debug_loop_intent
                                    trace('[LoopIntent] Using enhanced userVar from detectAndEliminate: ${userVarName}');
                                    #end
                                    if (userVarName == null) {
                                        // Fallback: check if it's array iteration or use default
                                        userVarName = forPattern.eliminationData.isArrayIteration ? "item" : "i";
                                        #if debug_loop_intent
                                        trace('[LoopIntent] No userVar found, using fallback: ${userVarName}');
                                        #end
                                    }
                                    
                                    // Determine loop type based on elimination data
                                    if (forPattern.eliminationData.isArrayIteration && forPattern.arrayVar != null) {
                                        // Array iteration pattern - use CollectionLoop
                                        var arrayExpr: TypedExpr = {
                                            expr: TLocal({
                                                id: 0, 
                                                name: forPattern.arrayVar, 
                                                t: null, 
                                                capture: false, 
                                                extra: null,
                                                meta: null,
                                                isStatic: false
                                            }), 
                                            pos: expr.pos, 
                                            t: null
                                        };
                                        
                                        loopIntent = CollectionLoop(userVarName, arrayExpr, body);
                                        #if debug_loop_intent
                                        trace('[LoopIntent] Created CollectionLoop for array iteration');
                                        #end
                                    } else if (forPattern.eliminationData.isSimpleRange) {
                                        // Simple range iteration
                                        loopIntent = RangeLoop(
                                            userVarName,
                                            forPattern.startValue,
                                            forPattern.endValue,
                                            body,
                                            false  // exclusive range (start...end)
                                        );
                                        #if debug_loop_intent
                                        trace('[LoopIntent] Created RangeLoop for simple range');
                                        #end
                                    } else {
                                        // Complex loop - keep as while
                                        #if debug_loop_intent
                                        trace('[LoopIntent] Complex pattern, keeping as while loop');
                                        #end
                                        return buildFromTypedExpr(forPattern.whileExpr, currentContext).def;
                                    }
                                default:
                                    #if debug_loop_intent
                                    trace('[LoopIntent] Unexpected while structure, fallback to default compilation');
                                    #end
                                    return buildFromTypedExpr(forPattern.whileExpr, currentContext).def;
                            }
                            
                            // TODO: Connect LoopIntent to LoopBuilder
                            // The LoopBuilder doesn't have a build method that takes LoopIntent yet
                            // This would need to be implemented to complete the loop optimization
                            /*
                            if (loopIntent != null) {
                                #if debug_loop_intent
                                trace('[LoopIntent] Using LoopBuilder to generate idiomatic Elixir');
                                #end
                                var result = LoopBuilder.build(loopIntent, currentContext);
                                return result;
                            }
                            */
                        }
                    }
                
                #if debug_ast_builder
                trace('[DEBUG EMBEDDED] TIf - currentContext.currentClauseContext exists: ${currentContext.currentClauseContext != null}');
                #end
                #if debug_loop_transformation
                // Debug nested if statements in loop bodies - specifically for meta variable issue
                #if debug_ast_builder
                trace('[XRay LoopTransform] TIf condition: ${Type.enumConstructor(econd.expr)}');
                #end
                switch(econd.expr) {
                    case TBinop(op, e1, e2):
                        #if debug_ast_builder
                        trace('[XRay LoopTransform]   Condition is TBinop: $op');
                        #end
                        #if debug_ast_builder
                        trace('[XRay LoopTransform]   Left side: ${Type.enumConstructor(e1.expr)}');
                        #end
                        #if debug_ast_builder
                        trace('[XRay LoopTransform]   Right side: ${Type.enumConstructor(e2.expr)}');
                        #end
                        switch(e1.expr) {
                            case TLocal(v):
                                #if debug_ast_builder
                                trace('[XRay LoopTransform]     Left is TLocal: ${v.name}');
                                #end
                            case TBinop(innerOp, ie1, ie2):
                                #if debug_ast_builder
                                trace('[XRay LoopTransform]     Left is inner TBinop: $innerOp');
                                #end
                            case _:
                        }
                    case TLocal(v):
                        #if debug_ast_builder
                        trace('[XRay LoopTransform]   Condition is TLocal: ${v.name}');
                        #end
                    case _:
                }
                switch(eif.expr) {
                    case TBlock(exprs):
                        #if debug_ast_builder
                        trace('[XRay LoopTransform] TIf then branch is TBlock with ${exprs.length} expressions');
                        #end
                        for (i in 0...exprs.length) {
                            switch(exprs[i].expr) {
                                case TVar(v, _):
                                    #if debug_ast_builder
                                    trace('[XRay LoopTransform]   TBlock[$i]: TVar ${v.name}');
                                    #end
                                default:
                                    #if debug_ast_builder
                                    trace('[XRay LoopTransform]   TBlock[$i]: ${Type.enumConstructor(exprs[i].expr)}');
                                    #end
                            }
                        }
                    case TVar(v, _):
                        #if debug_ast_builder
                        trace('[XRay LoopTransform] TIf then branch: TVar ${v.name}');
                        #end
                    default:
                        #if debug_ast_builder
                        trace('[XRay LoopTransform] TIf then branch: ${Type.enumConstructor(eif.expr)}');
                        #end
                }
                #end
                
                // Continue with the real TBlock implementation
                // Debug: Log ALL blocks to understand Haxe's desugaring patterns
                #if debug_ast_pipeline
                if (el.length > 0) {
                    trace('[XRay TBlock] ======= BLOCK START (${el.length} elements) =======');
                    for (i in 0...el.length) {
                        var exprStr = switch(el[i].expr) {
                            case TVar(v, init): 'TVar(${v.name}, init=${init != null ? "present" : "null"})';
                            case TSwitch(e, _, _): 
                                var switchOn = switch(e.expr) {
                                    case TLocal(v): 'TLocal(${v.name})';
                                    case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)): 
                                        var objStr = switch(obj.expr) {
                                            case TLocal(v): 'var:${v.name}';
                                            case TConst(TThis): 'this';
                                            default: 'obj';
                                        };
                                        'TField($objStr.${cf.get().name})';
                                    default: Std.string(e.expr).split("(")[0];
                                };
                                'TSwitch($switchOn, ...)';
                            case TLocal(v): 'TLocal(${v.name})';
                            case TField(e, FAnon(cf)) | TField(e, FInstance(_, _, cf)): 'TField(...${cf.get().name})';
                            default: Std.string(el[i].expr).split("(")[0];
                        };
                        trace('[XRay TBlock]   [$i]: $exprStr');
                    }
                    
                    // Check for infrastructure variable patterns regardless of block size
                    if (el.length >= 2) {
                        // Check last two elements for switch pattern
                        var checkIndex = el.length - 2;
                        switch([el[checkIndex].expr, el[checkIndex + 1].expr]) {
                            case [TVar(v, init), TSwitch(e, _, _)] if (reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(v.name)):
                                trace('[XRay TBlock] FOUND infrastructure var pattern: ${v.name} = ... ; switch(${v.name})');
                            default:
                        }
                    }
                    
                    // Check if we have a direct switch on field
                    if (el.length > 0) {
                        switch(el[el.length - 1].expr) {
                            case TSwitch(e, _, _):
                                switch(e.expr) {
                                    case TField(obj, FAnon(cf)) | TField(obj, FInstance(_, _, cf)):
                                        trace('[XRay TBlock] WARNING: FOUND direct switch on field: switch(obj.${cf.get().name})');
                                        trace('[XRay TBlock]   This should have been desugared but wasn\'t!');
                                    default:
                                }
                            default:
                        }
                    }
                    trace('[XRay TBlock] ======= BLOCK END =======');
                }
                #end
                
                #if debug_null_coalescing
                #if debug_ast_builder
                trace('[AST Builder] TBlock with ${el.length} expressions');
                #end
                for (i in 0...el.length) {
                    #if debug_ast_builder
                    trace('[AST Builder]   Block[$i]: ${Type.enumConstructor(el[i].expr)}');
                    #end
                }
                #end
                
                // CRITICAL: Check for Map iteration pattern FIRST (before regular for loops)
                // This detects patterns like: var iterator = map.keyValueIterator(); while(iterator.hasNext()) { var kv = iterator.next(); ... }
                // and generates idiomatic Elixir: Enum.each(map, fn {key, value} -> ... end)
                
                // Actually check for Map iteration pattern as the comment says we should
                if (el.length >= 2) {
                    // Add debug to see what expressions we're checking
                    #if debug_map_iteration
                    trace('[ElixirASTBuilder] Checking TBlock for Map iteration pattern...');
                    trace('  Block has ${el.length} expressions');
                    for (i in 0...Math.ceil(Math.min(3, el.length))) {
                        trace('  Expr[$i]: ${el[i].expr}');
                    }
                    #end
                    
                    // Delegate to LoopOptimizer for Map iteration detection
                    var mapPattern = LoopOptimizer.detectMapIterationPattern(el);
                    if (mapPattern != null) {
                        #if debug_map_iteration
                        trace('[ElixirASTBuilder] ✓ Detected Map iteration pattern, generating idiomatic Elixir');
                        trace('  Map expr: ${mapPattern.mapExpr}');
                        trace('  Key var: ${mapPattern.keyVar}');
                        trace('  Value var: ${mapPattern.valueVar}');
                        #end
                        return buildMapIteration(mapPattern, currentContext).def;
                    } else {
                        #if debug_map_iteration
                        trace('[ElixirASTBuilder] No Map iteration pattern detected in this block');
                        #end
                    }
                }
                
                // CRITICAL: Check for desugared for loop pattern NEXT
                // This detects patterns like: var g=0; var g1=5; while(g<g1){...}
                // and generates idiomatic Elixir (Enum.each or comprehensions)
                
                #if debug_loop_detection
                var featureEnabled = currentContext != null ? currentContext.isFeatureEnabled("loop_builder_enabled") : false;
                trace('[ElixirASTBuilder] TBlock loop detection check: context=${currentContext != null}, elements=${el.length}, loop_builder=${featureEnabled}');
                #end
                
                if (currentContext != null && currentContext.isFeatureEnabled("loop_builder_enabled")) {
                    #if debug_loop_detection
                    trace('[DesugarredForDetector] Attempting detection on TBlock with ${el.length} elements');
                    #end
                    var forPattern = DesugarredForDetector.detectAndEliminate(el);
                    if (forPattern != null) {
                        #if debug_loop_detection
                        trace('[ElixirASTBuilder] Detected desugared for loop at TBlock level with elimination data');
                        trace('  Counter: ${forPattern.counterVar} maps to user var: ${forPattern.userVar}');
                        trace('  Limit: ${forPattern.limitVar} to ${forPattern.endValue.expr}');
                        trace('  Is simple range: ${forPattern.eliminationData.isSimpleRange}');
                        trace('  Is array iteration: ${forPattern.eliminationData.isArrayIteration}');
                        #end
                        
                        // Create LoopIntent to capture the semantic intent of the loop
                        var loopIntent: LoopIntent = null;
                        var metadata: LoopIntentMetadata = {
                            wasDesugared: true,
                            infrastructureVars: [forPattern.counterVar, forPattern.limitVar],
                            sourcePos: expr.pos
                        };
                        
                        // Extract the while loop body using enhanced data
                        switch(forPattern.whileExpr.expr) {
                            case TWhile(cond, body, _):
                                // Use the enhanced userVar from detectAndEliminate
                                var userVarName = forPattern.userVar;
                                #if debug_loop_intent
                                trace('[LoopIntent] Using enhanced userVar from detectAndEliminate: ${userVarName}');
                                #end
                                if (userVarName == null) {
                                    // Fallback: check if it's array iteration or use default
                                    userVarName = forPattern.eliminationData.isArrayIteration ? "item" : "i";
                                    #if debug_loop_intent
                                    trace('[LoopIntent] No userVar found, using fallback: ${userVarName}');
                                    #end
                                }
                                
                                // Determine loop type based on elimination data
                                if (forPattern.eliminationData.isArrayIteration && forPattern.arrayVar != null) {
                                    // Array iteration pattern - use CollectionLoop
                                    var arrayExpr: TypedExpr = {
                                        expr: TLocal({
                                            id: 0, 
                                            name: forPattern.arrayVar, 
                                            t: null, 
                                            capture: false, 
                                            extra: null,
                                            meta: null,
                                            isStatic: false
                                        }), 
                                        pos: expr.pos, 
                                        t: null
                                    };
                                    loopIntent = CollectionLoop(
                                        userVarName,
                                        arrayExpr,
                                        body
                                    );
                                    #if debug_loop_detection
                                    trace('[ElixirASTBuilder] Creating CollectionLoop intent for array: ${forPattern.arrayVar}');
                                    #end
                                } else {
                                    // Range loop pattern
                                    loopIntent = RangeLoop(
                                        userVarName,
                                        forPattern.startValue,
                                        forPattern.endValue,
                                        body,
                                        false  // exclusive range (0...n)
                                    );
                                    #if debug_loop_detection
                                    trace('[ElixirASTBuilder] Creating RangeLoop intent');
                                    #end
                                }
                                
                                // Apply variable substitution using the mapping
                                metadata.variableMapping = forPattern.variableMapping;
                                
                                // Process the loop intent
                                var result = processLoopIntent(loopIntent, metadata, currentContext);
                                
                                #if debug_loop_detection
                                trace('[ElixirASTBuilder] Generated idiomatic loop via enhanced LoopIntent');
                                #end
                                
                                // CRITICAL FIX: Build a complete block with ALL non-infrastructure statements
                                // We must preserve buffer.add() calls, fields = Reflect.fields(), etc.
                                var blockStatements: Array<ElixirAST> = [];
                                
                                // Process all statements in order
                                for (i in 0...el.length) {
                                    if (el[i] == forPattern.whileExpr) {
                                        // Replace the while loop with our transformed version
                                        blockStatements.push(result);
                                    } else {
                                        // Check if this is an infrastructure variable
                                        var isInfrastructure = false;
                                        switch(el[i].expr) {
                                            case TVar(tvar, _):
                                                // Skip infrastructure variables
                                                if (tvar.name == forPattern.counterVar || 
                                                    tvar.name == forPattern.limitVar ||
                                                    (forPattern.arrayVar != null && tvar.name == forPattern.arrayVar)) {
                                                    isInfrastructure = true;
                                                    #if debug_loop_detection
                                                    trace('[ElixirASTBuilder] Skipping infrastructure variable: ${tvar.name}');
                                                    #end
                                                }
                                            default:
                                        }
                                        
                                        if (!isInfrastructure) {
                                            // Build this statement and add it to the block
                                            var stmt = buildFromTypedExpr(el[i], currentContext);
                                            if (stmt != null) {
                                                blockStatements.push(stmt);
                                                #if debug_loop_detection
                                                trace('[ElixirASTBuilder] Preserving statement: ${Type.enumConstructor(el[i].expr)}');
                                                #end
                                            }
                                        }
                                    }
                                }
                                
                                // Return the complete block
                                #if debug_loop_detection
                                trace('[ElixirASTBuilder] Returning complete block with ${blockStatements.length} statements');
                                #end
                                return EBlock(blockStatements);
                            default:
                        }
                    }
                }
                
                // CRITICAL: Track infrastructure variable initialization values
                // Haxe's desugaring creates variables like _g = 0, _g1 = 5 for loops
                // We must capture these values for use in reduce_while accumulators
                for (expr in el) {
                    switch(expr.expr) {
                        case TVar(v, init) if (init != null):
                            // Check if this is an infrastructure variable
                            if (v.name == "g" || v.name.startsWith("_g") || v.name.indexOf("g") >= 0) {
                                // Build the initialization AST and store it
                                var initAST = buildFromTypedExpr(init, currentContext);
                                currentContext.infrastructureVarInitValues.set(v.name, initAST);
                                
                                #if debug_infrastructure_vars
                                trace('[Infrastructure Variables] Tracked ${v.name} = ${ElixirASTPrinter.printAST(initAST)}');
                                #end
                            }
                        case _:
                            // Not a variable declaration, skip
                    }
                }
                
                // CRITICAL: Try to reconstruct array comprehensions from desugared imperative code
                // This handles nested comprehensions that Haxe has already desugared
                var comprehension = ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(el, currentContext);
                if (comprehension != null) {
                    #if debug_ast_builder
                    // trace('[AST Builder] Successfully reconstructed array comprehension from imperative block');
                    #end
                    comprehension.def;
                }
                
                // CRITICAL: Check for array building pattern FIRST
                // Haxe desugars array.map() into a TBlock containing:
                // 1. var _g = []
                // 2. var _g1 = 0  
                // 3. var _g2 = sourceArray
                // 4. while(_g1 < _g2.length) { ... }
                // 5. _g (return value)
                if (el.length >= 5) {
                    var hasEmptyArray = false;
                    var hasZeroInit = false;
                    var hasSourceAssign = false;
                    var hasWhileLoop = false;
                    var returnsResult = false;
                    var sourceArray: TypedExpr = null;
                    var whileBody: TypedExpr = null;
                    var resultVarName: String = null;
                    
                    for (i in 0...el.length) {
                        switch(el[i].expr) {
                            case TVar(v, init) if (init != null && v.name.startsWith("_g")):
                                switch(init.expr) {
                                    case TArrayDecl([]): 
                                        hasEmptyArray = true;
                                        resultVarName = v.name;
                                    case TConst(TInt(i)) if (i == 0): 
                                        hasZeroInit = true;
                                    case TLocal(_): 
                                        hasSourceAssign = true;
                                        sourceArray = init;
                                    case _:
                                }
                            case TWhile(_, body, _):
                                hasWhileLoop = true;
                                whileBody = body;
                            case TLocal(v) if (v.name == resultVarName && i == el.length - 1):
                                returnsResult = true;
                            case _:
                        }
                    }
                    
                    var isArrayPattern = hasEmptyArray && hasZeroInit && hasSourceAssign && hasWhileLoop && returnsResult;
                    
                    #if debug_array_patterns
                    #if debug_ast_builder
                    trace('[XRay ArrayPattern] TBlock check: empty=$hasEmptyArray, zero=$hasZeroInit, source=$hasSourceAssign, while=$hasWhileLoop, returns=$returnsResult');
                    #end
                    #end
                    
                    if (isArrayPattern && sourceArray != null && whileBody != null) {
                        var operation = ElixirASTPatterns.detectArrayOperationPattern(whileBody);
                        
                        #if debug_array_patterns
                        #if debug_ast_builder
                        trace('[XRay ArrayPattern] Detected operation: $operation');
                        #end
                        #end
                        
                        if (operation != null) {
                            // Generate idiomatic Enum call instead of the block
                            return generateIdiomaticEnumCall(sourceArray, operation, whileBody);
                        }
                    }
                }
                
                // Check for null coalescing pattern: TVar followed by TBinop(OpNullCoal) using that var
                // This pattern is generated by Haxe when the left side of ?? isn't simple
                if (el.length == 2) {
                    switch([el[0].expr, el[1].expr]) {
                        case [TVar(tmpVar, init), TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr)] 
                            if (v.id == tmpVar.id && init != null):
                            // This is the null coalescing pattern with temp variable
                            // Don't generate a block - generate inline if expression
                            var initAst = buildFromTypedExpr(init, currentContext);
                            var defaultAst = buildFromTypedExpr(defaultExpr, currentContext);
                            var tmpVarName = VariableAnalyzer.toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                            
                            // Generate: if (tmp = init) != nil, do: tmp, else: default
                            var ifExpr = makeAST(EIf(
                                makeAST(EBinary(NotEqual, 
                                    makeAST(EMatch(PVar(tmpVarName), initAst)),
                                    makeAST(ENil)
                                )),
                                makeAST(EVar(tmpVarName)),
                                defaultAst
                            ));
                            // Mark as inline for null coalescing
                            if (ifExpr.metadata == null) ifExpr.metadata = {};
                            ifExpr.metadata.keepInlineInAssignment = true;
                            return ifExpr.def;
                        case _:
                            // Not the null coalescing pattern
                    }
                }
                
                // Check for inline expansion pattern at TypedExpr level
                if (ElixirASTPatterns.isInlineExpansionBlock(el)) {
                    return ElixirASTPatterns.transformInlineExpansion(el, function(e) return buildFromTypedExpr(e, currentContext), function(name) return VariableAnalyzer.toElixirVarName(name));
                }
                
                // Check if this block is building a list through concatenations
                // Pattern: g = []; g ++ [val1]; g ++ [val2]; ...; g
                #if debug_array_comprehension
                #if debug_ast_builder
                trace('[Array Comprehension] TBlock analysis: checking ${el.length} statements');
                #end
                #end
                #if debug_ast_builder
                trace('[AST Builder] Checking if block with ${el.length} statements is list-building');
                #end
                #if debug_unrolled_comprehension
                #if debug_ast_builder
                trace('[DEBUG] TBlock with ${el.length} statements');
                #end
                for (i in 0...el.length) {
                    #if debug_ast_builder
                    trace('[DEBUG]   Statement $i: ${el[i].expr}');
                    #end
                }
                #end
                
                // Special case: Check for conditional comprehension pattern first
                // This is when we have var g = []; followed by a nested block with if statements
                // trace('[DEBUG] Checking TBlock with ${el.length} elements for conditional comprehension');
                if (el.length >= 2) {
                    var isConditionalComprehension = false;
                    var tempVarName = "";
                    
                    #if debug_array_comprehension
                    #if debug_ast_builder
                    trace('[Array Comprehension] Checking for conditional comprehension pattern in TBlock with ${el.length} statements');
                    #end
                    #end
                    
                    // Check first statement for var g = []
                    switch(el[0].expr) {
                        case TVar(v, init) if (init != null && (v.name.startsWith("g") || v.name.startsWith("_g"))):
                            switch(init.expr) {
                                case TArrayDecl([]):
                                    tempVarName = v.name;
                                    
                                    #if debug_array_comprehension
                                    #if debug_ast_builder
                                    trace('[Array Comprehension] Found initialization: var $tempVarName = []');
                                    #end
                                    #end
                                    
                                    // Check if second statement is a block containing if statements
                                    if (el.length >= 3) {
                                        #if debug_array_comprehension
                                        #if debug_ast_builder
                                        trace('[Array Comprehension] Checking statement 1 for TBlock: ${el[1].expr}');
                                        #end
                                        #end
                                        
                                        switch(el[1].expr) {
                                            case TBlock(innerStmts):
                                                #if debug_array_comprehension
                                                #if debug_ast_builder
                                                trace('[Array Comprehension] Found TBlock with ${innerStmts.length} inner statements');
                                                #end
                                                #end
                                                // Check if inner statements are all if statements with concatenations
                                                var allIfs = true;
                                                for (stmt in innerStmts) {
                                                    switch(stmt.expr) {
                                                        case TIf(_, thenExpr, null):
                                                            // Check if then branch does concatenation
                                                            switch(thenExpr.expr) {
                                                                case TBinop(OpAssign, {expr: TLocal(v)}, rhs) if (v.name == tempVarName):
                                                                    switch(rhs.expr) {
                                                                        case TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([_])}) if (v2.name == tempVarName):
                                                                            // Good - it's a concatenation
                                                                        default:
                                                                            allIfs = false;
                                                                    }
                                                                default:
                                                                    allIfs = false;
                                                            }
                                                        default:
                                                            allIfs = false;
                                                    }
                                                }
                                                
                                                // Check last statement returns the temp var
                                                if (allIfs && el.length > 2) {
                                                    switch(el[el.length - 1].expr) {
                                                        case TLocal(v) if (v.name == tempVarName):
                                                            isConditionalComprehension = true;
                                                        default:
                                                    }
                                                }
                                            default:
                                        }
                                    }
                                default:
                            }
                        default:
                    }
                    
                    if (isConditionalComprehension) {
                        #if debug_array_comprehension
                        #if debug_ast_builder
                        trace('[Array Comprehension] ✓ DETECTED conditional comprehension pattern!');
                        #end
                        #end
                        
                        // Try to reconstruct the conditional comprehension
                        #if debug_ast_builder
                        trace('[DEBUG] Attempting to reconstruct conditional comprehension with tempVar: $tempVarName');
                        #end
                        var reconstructed = ComprehensionBuilder.tryReconstructConditionalComprehension(el, tempVarName, currentContext);
                        if (reconstructed != null) {
                            #if debug_array_comprehension
                            #if debug_ast_builder
                            trace('[Array Comprehension] Successfully reconstructed conditional comprehension');
                            #end
                            #end
                            return reconstructed.def;
                        }
                    }
                }
                
                if (ComprehensionBuilder.looksLikeListBuildingBlock(el)) {
                    #if debug_array_comprehension
                    #if debug_ast_builder
                    trace('[Array Comprehension] ✓ DETECTED unrolled comprehension pattern!');
                    #end
                    #if debug_ast_builder
                    trace('[Array Comprehension]   Will mark block with metadata for transformer');
                    #end
                    #end
                    #if debug_ast_builder
                    trace('[AST Builder] Detected list-building block, marking with metadata');
                    #end
                    
                    // Extract pattern information for metadata
                    var listElements = ComprehensionBuilder.extractListElements(el);
                    if (listElements != null && listElements.length > 0) {
                        // Build the block statements normally but mark with metadata
                        var blockStmts = [for (e in el) buildFromTypedExpr(e, currentContext)];
                        
                        // Create block with metadata marking it as unrolled comprehension
                        var blockAST = makeAST(EBlock(blockStmts));
                        
                        // Add metadata to indicate this is an unrolled comprehension
                        // The transformer will use this to reconstruct proper for comprehension
                        if (blockAST.metadata == null) blockAST.metadata = {};
                        blockAST.metadata.isUnrolledComprehension = true;
                        blockAST.metadata.comprehensionElements = listElements.length;
                        
                        #if debug_array_comprehension
                        #if debug_ast_builder
                        trace('[Array Comprehension] Block marked with metadata:');
                        #end
                        #if debug_ast_builder
                        trace('[Array Comprehension]   isUnrolledComprehension: true');
                        #end
                        #if debug_ast_builder
                        trace('[Array Comprehension]   comprehensionElements: ${listElements.length}');
                        #end
                        #end
                        
                        return blockAST.def;
                    }
                } else {
                    #if debug_ast_builder
                    if (el.length > 0 && el.length < 10) {
                        #if debug_ast_builder
                        trace('[AST Builder] Not a list-building block. First stmt: ${el[0].expr}');
                        #end
                        if (el.length > 1) trace('[AST Builder] Second stmt: ${el[1].expr}');
                    }
                    #end
                }
                
                // Special handling for TBlock in expression contexts
                // When Haxe desugars expressions like !map.exists(key), it creates:
                // TBlock([TVar(tmp, key), map.has_key(tmp)])
                // In expression contexts, this needs special handling to avoid invalid syntax
                // 
                // IMPORTANT: Skip this optimization for blocks that are inside loops
                // or other contexts where variable declarations must be preserved for
                // proper state threading transformation
                var isInLoopContext = false; // We could track this with a context variable if needed
                
                #if debug_ast_builder
                if (el.length > 0) {
                    trace('[TBlock] Processing block with ${el.length} elements');
                    for (i in 0...Std.int(Math.min(3, el.length))) {
                        trace('[TBlock]   Element $i: ${Std.string(el[i].expr).split("(")[0]}');
                    }
                }
                #end
                
                if (el.length == 2 && !isInLoopContext) {
                    switch([el[0].expr, el[1].expr]) {
                        case [TVar(v, init), expr]:
                            // This is a temporary variable pattern
                            // Handle both when init is not null AND when it is null
                            #if debug_ast_builder
                            trace('[TBlock 2-element] Found TVar(${v.name}, init=${init != null ? Type.enumConstructor(init.expr) : "null"}');
                            #end
                            
                            // Check if this is an infrastructure variable first
                            // Use centralized detection from TypedExprPreprocessor
                            if (reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(v.name)) {
                                
                                // CRITICAL FIX: Build infrastructure variable assignment instead of skipping
                                // This ensures _g = expr is generated before case _g in for loops
                                #if debug_ast_builder
                                trace('[Infrastructure Variable Fix] TBlock building infrastructure var assignment: ${v.name}');
                                #end
                                
                                // Handle common pattern: g = expr followed by switch(g)
                                if (init != null) {
                                    switch(el[1].expr) {
                                        case TSwitch(e, cases, edef):
                                            switch(e.expr) {
                                                case TLocal(localVar) if (localVar.id == v.id):
                                                    // Check if the init is a field access - if so, we need special handling
                                                    switch(init.expr) {
                                                        case TField(rootObj, FAnon(cf)) | TField(rootObj, FInstance(_, _, cf)):
                                                            // This is switching on a field value - we need to transform to object pattern matching
                                                            #if debug_ast_builder
                                                            trace('[Infrastructure Variable Fix] Detected switch on field access: ${cf.get().name}');
                                                            trace('[Infrastructure Variable Fix] Will transform to object pattern matching');
                                                            trace('[Infrastructure Variable Fix] rootObj type: ${Std.string(rootObj.expr).split("(")[0]}');
                                                            switch(rootObj.expr) {
                                                                case TLocal(v): trace('[Infrastructure Variable Fix]   rootObj is TLocal: ${v.name}');
                                                                default:
                                                            }
                                                            #end
                                                            
                                                            // Build the switch on the root object instead of the field
                                                            // and transform the cases to use field patterns
                                                            return buildFieldPatternSwitch(rootObj, cf.get().name, cases, edef, el[1].pos, currentContext);
                                                            
                                                        default:
                                                            // FIXED: Build BOTH the assignment AND the switch
                                                            // This preserves the infrastructure variable for use in for loops
                                                            #if debug_ast_builder
                                                            trace('[Infrastructure Variable Fix] Building assignment and switch for ${v.name}');
                                                            #end
                                                            
                                                            // Build the infrastructure variable assignment
                                                            var varName = VariableAnalyzer.toElixirVarName(v.name.charAt(0) == "_" ? v.name.substr(1) : v.name);
                                                            var initAST = buildFromTypedExpr(init, currentContext);
                                                            var assignment = makeAST(EMatch(PVar(varName), initAST));
                                                            
                                                            // Build the switch with the infrastructure variable
                                                            var switchAST = buildFromTypedExpr(el[1], currentContext);
                                                            
                                                            // Return a block with both the assignment and the switch
                                                            return EBlock([assignment, switchAST]);
                                                    }
                                                default:
                                            }
                                        default:
                                    }
                                }
                                
                                // Fallback: substitute the infrastructure variable in the body
                                // This handles cases where the infrastructure variable is used but not in a switch
                                if (init != null) {
                                    #if debug_ast_builder
                                    trace('[Infrastructure Variable Fix] Substituting ${v.name} in body expression');
                                    trace('[Infrastructure Variable Fix] Init type: ${Type.enumConstructor(init.expr)}');
                                    #end
                                    
                                    // First, build the init expression to see what we're substituting
                                    var initAST = buildFromTypedExpr(init, currentContext);
                                    if (initAST == null) {
                                        #if debug_ast_builder
                                        trace('[Infrastructure Variable Fix] CRITICAL: Failed to build init expression!');
                                        trace('[Infrastructure Variable Fix] Falling back to building body without substitution');
                                        #end
                                        // If we can't build the init, just build the body as-is
                                        var result = buildFromTypedExpr(el[1], currentContext);
                                        if (result == null) {
                                            #if debug_ast_builder
                                            trace('[Infrastructure Variable Fix] WARNING: buildFromTypedExpr returned null for fallback body expression');
                                            #end
                                            // Return a nil expression as fallback
                                            return ENil;
                                        }
                                        return result.def;
                                    }
                                    
                                    #if debug_ast_builder
                                    trace('[Infrastructure Variable Fix] Init AST: ${initAST.def}');
                                    #end
                                    
                                    // We need to substitute all occurrences of the infrastructure variable
                                    // with the init expression in el[1]
                                    var substituted = substituteVariable(el[1], v, init);
                                    var result = buildFromTypedExpr(substituted, currentContext);
                                    if (result == null) {
                                        #if debug_ast_builder
                                        trace('[Infrastructure Variable Fix] WARNING: buildFromTypedExpr returned null for substituted expression');
                                        #end
                                        // Return a nil expression as fallback
                                        return ENil;
                                    }
                                    return result.def;
                                } else {
                                    // No init, just compile the body
                                    var result = buildFromTypedExpr(el[1], currentContext);
                                    if (result == null) {
                                        #if debug_ast_builder
                                        trace('[Infrastructure Variable Fix] WARNING: buildFromTypedExpr returned null for body expression');
                                        #end
                                        // Return a nil expression as fallback
                                        return ENil;
                                    }
                                    return result.def;
                                }
                            }
                            
                            // Special check for TodoPubSub.subscribe pattern
                            if (init != null) {
                                switch(init.expr) {
                                    case TCall(e, _):
                                        switch(e.expr) {
                                            case TField(_, FStatic(classRef, cf)):
                                                var className = classRef.get().name;
                                                var methodName = cf.get().name;
                                                if (className == "TodoPubSub" && methodName == "subscribe") {
                                                    trace('[TBlock 2-element] CRITICAL: Found TodoPubSub.subscribe in TVar init!');
                                                }
                                            default:
                                        }
                                    default:
                                }
                            }
                            
                            // Check if the variable is unused and add underscore prefix
                            var isUsed = if (currentContext.variableUsageMap != null && currentContext.variableUsageMap.exists(v.id)) {
                                currentContext.variableUsageMap.get(v.id);
                            } else {
                                true; // Conservative: assume used if not in map
                            };
                            
                            // Build the assignment
                            var baseName = VariableAnalyzer.toElixirVarName(v.name);
                            var varName = if (!isUsed) {
                                #if debug_variable_usage
                                #if debug_ast_builder
                                trace('[TBlock] Variable ${v.name} (id=${v.id}) is UNUSED, adding underscore prefix');
                                #end
                                #end
                                // M0 STABILIZATION: Disable underscore prefixing
                                baseName; // "_" + baseName;
                            } else {
                                baseName;
                            };
                            
                            var initExpr = if (init != null) {
                                var built = buildFromTypedExpr(init, currentContext);
                                if (built == null && init != null) {
                                    // Check specifically for TodoPubSub.subscribe
                                    switch(init.expr) {
                                        case TCall(e, _):
                                            switch(e.expr) {
                                                case TField(_, FStatic(classRef, cf)):
                                                    var className = classRef.get().name;
                                                    var methodName = cf.get().name;
                                                    trace('[TBlock] ERROR: buildFromTypedExpr returned null for ${className}.${methodName}!');
                                                default:
                                            }
                                        default:
                                    }
                                }
                                built;
                            } else null;
                            
                            // CRITICAL FIX: Check if initialization failed to build or was null
                            if (initExpr == null) {
                                trace('[TBlock] WARNING: Failed to build initialization for variable ${v.name}, generating fallback error tuple');
                                // Generate fallback error tuple to prevent undefined variables
                                initExpr = makeAST(ETuple([
                                    makeAST(EAtom("error")),
                                    makeAST(EString("[Compiler Error] Failed to build initialization for ${baseName}"))
                                ]));
                                
                                // Mark this as a fallback initialization
                                if (initExpr.metadata == null) initExpr.metadata = {};
                                initExpr.metadata.requiresTempVar = true;
                            }
                            
                            var bodyExpr = buildFromTypedExpr(el[1], currentContext);
                            
                            // Debug what the body expression looks like
                            if (v.name == "_g") {
                                trace('[TBlock] Body expression for _g: ${bodyExpr.def}');
                            }

                            // Try to inline immediately when the temp var is used exactly once
                            // BUT: Skip inlining in case clause bodies (statement contexts)
                            // and other contexts where variable declarations should be preserved
                            var isInCaseClause = currentContext.currentClauseContext != null;
                            
                            // CRITICAL FIX: Skip inlining when the body contains nested if statements
                            // This preserves variable declarations that need to be visible in nested scopes
                            var containsNestedIf = containsIfStatement(el[1]);
                            var shouldPreserveDeclaration = isInCaseClause || containsNestedIf;
                            
                            // Check if the body is a switch/case expression that uses the variable
                            var bodyIsSwitch = switch(bodyExpr.def) {
                                case ECase(_): true;
                                default: false;
                            };
                            
                            // Never inline variables that are used in switch expressions
                            // The switch needs the variable to be defined
                            if (!shouldPreserveDeclaration && !bodyIsSwitch) {
                                var usageCount = countVarOccurrencesInAST(bodyExpr, varName);
                                
                                if (usageCount == 1) {
                                    trace('[TBlock] Inlining ${varName} (usage count: 1)');
                                    var inlined = replaceVarInAST(bodyExpr, varName, initExpr);
                                    return inlined.def;
                                }
                            }

                            // Fallback: keep block, will be handled by transformer/printer later
                            // trace('[TBlock] Generating EBlock with EMatch for ${varName}');
                            // trace('[TBlock] initExpr type: ${initExpr.def}');
                            var matchExpr = makeAST(EMatch(PVar(varName), initExpr));
                            // trace('[TBlock] matchExpr: ${matchExpr.def}');
                            return EBlock([
                                matchExpr,
                                bodyExpr
                            ]);
                        default:
                            // Not the pattern we're looking for
                    }
                }
                
                // Build all expressions, filtering out redundant enum extractions
                var expressions = [];

                // CRITICAL: Don't filter TEnumParameter when inside case clauses
                // ClauseContext needs these extractions to build proper variable mappings
                var isInCaseClause = currentContext.currentClauseContext != null;

                for (e in el) {
                    // Check if this is a redundant enum extraction we should skip
                    var shouldSkip = false;

                    // Only filter redundant extractions when NOT in case clauses
                    if (!isInCaseClause) {
                        switch(e.expr) {
                            case TVar(v, init) if (init != null):
                                switch(init.expr) {
                                    case TEnumParameter(_, _, _):
                                        // Check if this is a redundant extraction (temp var like _g, g, g1, g2)
                                        // Check both the original name and the Elixir-converted name
                                        var originalName = v.name;
                                        var tempVarName = VariableAnalyzer.toElixirVarName(v.name);
                                        #if debug_redundant_extraction
                                        #if debug_ast_builder
                                        trace('[TBlock] TEnumParameter found - originalName: $originalName, tempVarName: $tempVarName');
                                        #end
                                        #end
                                        // Check if this matches the temp var pattern (_g, g, g1, g2, etc.)
                                        if (originalName == "_g" || originalName == "g" ||
                                            (originalName.startsWith("_g") && originalName.length > 2) ||
                                            (originalName.startsWith("g") && originalName.length > 1 &&
                                             originalName.charAt(1) >= '0' && originalName.charAt(1) <= '9')) {
                                            // Skip this redundant extraction statement
                                            shouldSkip = true;
                                            #if debug_redundant_extraction
                                            #if debug_ast_builder
                                            trace('[TBlock] *** WILL SKIP *** redundant enum extraction for $originalName (converted to $tempVarName)');
                                            #end
                                            #end
                                        } else {
                                            #if debug_redundant_extraction
                                            #if debug_ast_builder
                                            trace('[TBlock] NOT skipping - $originalName does not match temp var pattern');
                                            #end
                                            #end
                                        }
                                    case _:
                                }
                            case TBinop(OpAssign, {expr: TLocal(lhs)}, {expr: TLocal(rhs)}):
                                var lhsName = VariableAnalyzer.toElixirVarName(lhs.name);
                                var rhsName = VariableAnalyzer.toElixirVarName(rhs.name);

                                if (PatternDetector.isTempPatternVarName(lhsName) || lhsName == rhsName || PatternDetector.isTempPatternVarName(rhsName)) {
                                    shouldSkip = true;
                                    #if debug_redundant_extraction
                                    #if debug_ast_builder
                                    trace('[TBlock] Skipping alias assignment: ${lhsName} = ${rhsName}');
                                    #end
                                    #end
                                }
                            case _:
                        }
                    }

                    if (!shouldSkip) {
                        switch(e.expr) {
                            case TBinop(OpAssign, {expr: TLocal(lhs)}, {expr: TLocal(rhs)}):
                                var lhsName = VariableAnalyzer.toElixirVarName(lhs.name);
                                var rhsName = VariableAnalyzer.toElixirVarName(rhs.name);

                                if (PatternDetector.isTempPatternVarName(lhsName) || lhsName == rhsName || PatternDetector.isTempPatternVarName(rhsName)) {
                                    shouldSkip = true;
                                    #if debug_redundant_extraction
                                    #if debug_ast_builder
                                    trace('[TBlock] Skipping alias assignment (case clause aware): ${lhsName} = ${rhsName}');
                                    #end
                                    #end
                                }
                            case _:
                        }
                    }

                    if (!shouldSkip) {
                        var builtExpr = buildFromTypedExpr(e, currentContext);
                        // Filter out null expressions (returned when skipping redundant assignments)
                        if (builtExpr != null) {
                            #if debug_redundant_extraction
                            // Additional check: if the def is null, skip it
                            if (builtExpr.def == null) {
                                #if debug_ast_builder
                                trace('[TBlock] Filtering out expression with null def');
                                #end
                            } else {
                                expressions.push(builtExpr);
                            }
                            #else
                            expressions.push(builtExpr);
                            #end
                        } else {
                            #if debug_redundant_extraction
                            #if debug_ast_builder
                            trace('[TBlock] Filtering out null expression');
                            #end
                            #end
                        }
                    } else {
                        #if debug_redundant_extraction
                        #if debug_ast_builder
                        trace('[TBlock] *** ACTUALLY SKIPPED *** building expression');
                        #end
                        #end
                    }
                }
                
                // Check if we need to combine inline expansions
                // Look for patterns like: c = index = expr; obj.method(index)
                var needsCombining = false;
                for (i in 0...expressions.length - 1) {
                    var current = expressions[i];
                    var next = expressions[i + 1];

                    // Null safety check
                    if (current == null || next == null || current.def == null || next.def == null) {
                        continue;
                    }

                    // Check for assignment followed by method call pattern
                    switch([current.def, next.def]) {
                        case [EMatch(_, _), ECall(_, _, _)]:
                            needsCombining = true;
                            break;
                        case _:
                    }
                }
                
                if (needsCombining) {
                    // Use the existing InlineExpansionTransforms to combine split patterns
                    // This handles cases where inline expansions are created during AST building
                    var combinedBlock = makeAST(EBlock(expressions));
                    var transformed = reflaxe.elixir.ast.transformers.InlineExpansionTransforms.inlineMethodCallCombinerPass(combinedBlock);
                    
                    // Return the transformed block's definition
                    transformed.def;
                } else {
                    // No combining needed, return regular block
                    EBlock(expressions);
                }
                
            case TReturn(e):
                // Delegate to ReturnBuilder for proper return handling
                var result = ReturnBuilder.build(e, currentContext);
                if (result != null) {
                    return result;
                }
                
                // Fallback to legacy implementation if builder returns null
                // In Elixir, everything is an expression, including returns
                // We don't need a special return statement, just the expression itself
                if (e != null) {
                    #if debug_ast_builder
                    trace('[TReturn] Fallback to legacy implementation');
                    #end
                    var returnExpr = buildFromTypedExpr(e, currentContext);
                    returnExpr.def;
                } else {
                    ENil; // Explicit nil return
                }
                
            case TBreak:
                // Delegate to ExceptionBuilder for break control flow
                ExceptionBuilder.buildBreak();
                
            case TContinue:
                // Delegate to ExceptionBuilder for continue control flow
                ExceptionBuilder.buildContinue();
                
            // ================================================================
            // Pattern Matching (Switch/Case)
            // ================================================================
            case TSwitch(e, cases, edef):
                // Ensure compiler is set before delegation
                if (currentContext.compiler == null && compiler != null) {
                    currentContext.compiler = compiler;
                }
                
                // Delegate to SwitchBuilder for proper handling
                var result = SwitchBuilder.build(e, cases, edef, currentContext);
                if (result != null) {
                    return result;
                }
                
                // If SwitchBuilder fails, return a placeholder to avoid compilation hang
                // This should be investigated and fixed properly
                trace('[ERROR] SwitchBuilder returned null for TSwitch - returning placeholder');
                return ERaw("# ERROR: SwitchBuilder failed to compile switch expression");
                
                
            case TTry(e, catches):
                // Delegate to ExceptionBuilder for proper exception handling
                var result = ExceptionBuilder.buildTry(e, catches, currentContext);
                if (result != null) {
                    return result;
                }
                
                // If ExceptionBuilder fails, return an error placeholder
                trace('[ERROR] ExceptionBuilder returned null for TTry - returning placeholder');
                return ERaw("# ERROR: ExceptionBuilder failed to compile try expression");
                
            // ================================================================
            // Lambda/Anonymous Functions
            // ================================================================
            case TFunction(f):
                // TODO: FunctionBuilder delegation is temporarily disabled due to variable naming issues
                // The extraction broke the variable renaming map integration
                // var result = reflaxe.elixir.ast.builders.FunctionBuilder.build(f, currentContext);
                // if (result != null) {
                //     return result;
                // }
                
                // Use legacy implementation until FunctionBuilder is fixed
                // Debug: Check for abstract method "this" parameter issue
                #if debug_ast_pipeline
                for (arg in f.args) {
                    #if debug_ast_builder
                    trace('[AST Builder] TFunction arg: ${arg.v.name} (id=${arg.v.id})');
                    #end
                }
                #end

                #if debug_everythingisexpr
                // Special debug for ChangesetUtils methods that are failing
                if (currentContext != null && currentModule != null && currentModule.contains("ChangesetUtils")) {
                    #if debug_ast_builder
                    trace('[TFunction] Processing function in module: ${currentModule}');
                    #end
                    if (f.expr != null) {
                        #if debug_ast_builder
                        trace('[TFunction] Function body type: ${Type.enumConstructor(f.expr.expr)}');
                        #end

                        // Check what the function body looks like
                        switch(f.expr.expr) {
                            case TBlock(exprs):
                                #if debug_ast_builder
                                trace('[TFunction] Function body is TBlock with ${exprs.length} expressions');
                                #end
                                for (i in 0...exprs.length) {
                                    #if debug_ast_builder
                                    trace('[TFunction]   Expr[$i]: ${Type.enumConstructor(exprs[i].expr)}');
                                    #end

                                    // Check if it's a TVar with problematic init
                                    switch(exprs[i].expr) {
                                        case TVar(v, init):
                                            #if debug_ast_builder
                                            trace('[TFunction]     TVar ${v.name}');
                                            #end
                                            if (init != null) {
                                                #if debug_ast_builder
                                                trace('[TFunction]       Init type: ${Type.enumConstructor(init.expr)}');
                                                #end

                                                // Check if it's TLocal(value)
                                                switch(init.expr) {
                                                    case TLocal(localVar):
                                                        #if debug_ast_builder
                                                        trace('[TFunction]       Init is TLocal: ${localVar.name}');
                                                        #end
                                                    default:
                                                }
                                            }
                                        default:
                                    }
                                }
                            case TReturn(expr):
                                if (expr != null) {
                                    #if debug_ast_builder
                                    trace('[TFunction] Direct return, expr type: ${Type.enumConstructor(expr.expr)}');
                                    #end
                                }
                            default:
                                #if debug_ast_builder
                                trace('[TFunction] Other body type');
                                #end
                        }
                    }
                }
                #end
                
                // Detect fluent API patterns
                var fluentPattern = PatternDetector.detectFluentAPIPattern(f);
                
                var args = [];
                var paramRenaming = new Map<String, String>();
                
                // Now build the body with awareness of parameter mappings
                // We need to temporarily override the collision detection for these parameters
                var oldTempVarRenameMap = currentContext.tempVarRenameMap;
                currentContext.tempVarRenameMap = new Map();
                for (key in oldTempVarRenameMap.keys()) {
                    currentContext.tempVarRenameMap.set(key, oldTempVarRenameMap.get(key));
                }
                
                // Process all parameters: handle naming, unused prefixing, and registration
                var isFirstParam = true;
                for (arg in f.args) {
                    var originalName = arg.v.name;
                    var idKey = Std.string(arg.v.id);

                    #if debug_variable_renaming
                    #if debug_ast_builder
                    trace('[RENAME DEBUG] TFunction: Processing parameter "$originalName" (ID: ${arg.v.id})');
                    #end
                    #end
                    
                    // Use Reflaxe's metadata to detect unused parameters
                    // First check if parameter has the -reflaxe.unused metadata
                    var isActuallyUnused = if (arg.v.meta != null && arg.v.meta.has("-reflaxe.unused")) {
                        true;  // Parameter is marked as unused by Reflaxe preprocessor
                    } else if (f.expr != null) {
                        // Use our UsageDetector to check if parameter is actually used
                        !reflaxe.elixir.helpers.UsageDetector.isParameterUsed(arg.v, f.expr);
                    } else {
                        false; // If no body, consider parameter as potentially used
                    };
                    
                    // Check if this parameter has a numeric suffix that indicates shadowing
                    var strippedName = originalName;
                    var hasNumericSuffix = false;
                    var renamedPattern = ~/^(.+?)(\d+)$/;
                    if (renamedPattern.match(originalName)) {
                        var baseWithoutSuffix = renamedPattern.matched(1);
                        var suffix = renamedPattern.matched(2);

                        // Only strip suffix if it looks like a shadowing rename (suffix 2 or 3, common field names)
                        var commonFieldNames = ["options", "columns", "name", "value", "type", "data", "fields", "items"];
                        if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(baseWithoutSuffix) >= 0) {
                            strippedName = baseWithoutSuffix;
                            hasNumericSuffix = true;

                            #if debug_variable_renaming
                            #if debug_ast_builder
                            trace('[RENAME DEBUG] TFunction: Detected renamed parameter "$originalName" -> "$strippedName" (suffix: "$suffix", ID: ${arg.v.id})');
                            #end
                            #end
                        }
                    }

                    // Convert to snake_case for Elixir conventions
                    var baseName = ElixirASTHelpers.toElixirVarName(strippedName);
                    
                    // Debug: Check if reserved keyword
                    #if debug_reserved_keywords
                    if (isElixirReservedKeyword(baseName)) {
                        #if debug_ast_builder
                        trace('[AST Builder] Reserved keyword detected in parameter: $baseName -> ${baseName}_param');
                        #end
                    }
                    #end
                    
                    // Prefix with underscore if unused (using TypedExpr-based detection which is more accurate)
                    // This is done here rather than in a transformer because we have full semantic information
                    // Re-enable underscore prefixing for 1.0 quality
                    var finalName = if (isActuallyUnused && !StringTools.startsWith(baseName, "_")) {
                        "_" + baseName;
                    } else {
                        baseName;
                    };
                    
                    // Register the mapping for TLocal references in the body
                    if (!currentContext.tempVarRenameMap.exists(idKey)) {
                        currentContext.tempVarRenameMap.set(idKey, finalName);

                        #if debug_variable_renaming
                        #if debug_ast_builder
                        trace('[RENAME DEBUG] TFunction: Registered in tempVarRenameMap - ID: $idKey -> "$finalName" (original: "$originalName", stripped: "$strippedName")');
                        #end
                        #end
                    }
                    
                    // Track parameter mappings for collision detection
                    if (originalName != finalName) {
                        paramRenaming.set(originalName, finalName);
                        #if debug_ast_pipeline
                        #if debug_ast_builder
                        trace('[AST Builder] Function parameter will be renamed: $originalName -> $finalName');
                        #end
                        #end
                    }

                    // Register the renamed variable mapping if we stripped a suffix
                    // This follows Codex's recommendation to register at the point of emission decision
                    if (hasNumericSuffix && currentContext != null && currentContext.astContext != null) {
                        // Register that this variable ID should use the clean name (without suffix)
                        currentContext.astContext.registerRenamedVariable(arg.v.id, strippedName, originalName);

                        #if debug_variable_renaming
                        #if debug_ast_builder
                        trace('[RENAME DEBUG] TFunction: Registered renamed mapping for id ${arg.v.id}: "$originalName" -> "$strippedName"');
                        #end
                        #end
                    }
                    
                    // Handle special case for abstract "this" parameters
                    if (originalName == "this1") {
                        // The body might try to rename this1 -> this due to collision detection
                        // We need to prevent that and use the parameter name instead
                        paramRenaming.set("this", finalName); // Map "this" to final name as well
                        #if debug_ast_pipeline
                        #if debug_ast_builder
                        trace('[AST Builder] Abstract this parameter detected, mapping both this1 and this to: $finalName');
                        #end
                        #end
                    }
                    
                    // Track the first parameter as the receiver for instance methods
                    // This will be used for TThis references
                    if (isFirstParam && currentContext.isInClassMethodContext) {
                        currentContext.currentReceiverParamName = finalName;
                        isFirstParam = false;
                    }
                    
                    // Add the parameter to the function signature
                    args.push(PVar(finalName));
                    
                    currentContext.functionParameterIds.set(idKey, true); // Mark as function parameter
                    #if debug_ast_pipeline
                    #if debug_ast_builder
                    trace('[AST Builder] Registering parameter in rename map: id=$idKey');
                    #end
                    #end
                }
                
                // Analyze variable usage in the function body
                // TODO: Restore when VariableUsageAnalyzer is available
                // This is critical for proper underscore prefixing of unused variables
                var functionUsageMap: Map<Int, Bool> = null; // if (f.expr != null) {
                    // reflaxe.elixir.helpers.VariableUsageAnalyzer.analyzeUsage(f.expr);
                // } else {
                    // null;
                // };
                
                // Update context with function-specific usage map
                if (functionUsageMap != null) {
                    currentContext.variableUsageMap = functionUsageMap;
                }
                var body = buildFromTypedExpr(f.expr, currentContext);
                
                // Restore the original map and clean up function parameter tracking
                currentContext.tempVarRenameMap = oldTempVarRenameMap;
                for (arg in f.args) {
                    currentContext.functionParameterIds.remove(Std.string(arg.v.id));
                }
                
                // Apply any remaining parameter renaming if needed
                if (paramRenaming.keys().hasNext()) {
                    #if debug_ast_pipeline
                    #if debug_ast_builder
                    trace('[AST Builder] Applying parameter renaming to function body');
                    #end
                    #end
                    body = applyParameterRenaming(body, paramRenaming);
                }
                
                // Create the function AST with fluent API metadata if detected
                var fnAst = makeAST(EFn([{
                    args: args,
                    guard: null,
                    body: body
                }]));
                
                // Add fluent API metadata if patterns were detected
                if (fluentPattern.returnsThis || fluentPattern.fieldMutations.length > 0) {
                    fnAst.metadata.isFluentMethod = true;
                    fnAst.metadata.returnsThis = fluentPattern.returnsThis;
                    
                    if (fluentPattern.fieldMutations.length > 0) {
                        fnAst.metadata.mutatesFields = [];
                        fnAst.metadata.fieldMutations = [];
                        for (mutation in fluentPattern.fieldMutations) {
                            fnAst.metadata.mutatesFields.push(mutation.field);
                            fnAst.metadata.fieldMutations.push({
                                field: mutation.field,
                                expr: buildFromTypedExpr(mutation.expr, currentContext)
                            });
                        }
                    }
                }
                
                fnAst.def;
                
            // ================================================================
            // Object/Anonymous Structure
            // ================================================================
            /**
             * Handles TObjectDecl conversion to either EMap or EKeywordList based on usage context.
             * 
             * Two special patterns are detected and handled:
             * 
             * 1. SUPERVISOR OPTIONS PATTERN:
             *    When an object contains OTP supervisor configuration fields (strategy, max_restarts, max_seconds),
             *    it's compiled to a keyword list instead of a map. This is required because Supervisor.start_link/2
             *    expects options as a keyword list, not a map.
             * 
             *    Example:
             *    ```haxe
             *    // Haxe source
             *    var opts = {strategy: OneForOne, max_restarts: 3, max_seconds: 5};
             *    ```
             *    
             *    ```elixir
             *    # Generated Elixir (keyword list, not map)
             *    opts = [strategy: :OneForOne, max_restarts: 3, max_seconds: 5]
             *    ```
             * 
             * 2. NULL COALESCING IN OBJECT FIELDS:
             *    Haxe generates a specific AST pattern for null coalescing operators (??) in object field values.
             *    This pattern is detected and transformed into idiomatic Elixir inline if-expressions.
             * 
             *    Example:
             *    ```haxe
             *    // Haxe source
             *    {field: someValue ?? defaultValue}
             *    ```
             *    
             *    ```elixir
             *    # Generated Elixir
             *    %{field: if (tmp = some_value) != nil, do: tmp, else: default_value}
             *    ```
             * 
             * @param fields Array of object field declarations from Haxe's TypedExpr
             * @return Either EKeywordList for supervisor options or EMap for regular objects
             */
            case TObjectDecl(fields):
                // Delegate to ObjectBuilder for modular handling
                var result = reflaxe.elixir.ast.builders.ObjectBuilder.build(fields, currentContext);
                if (result != null) return result;
                
                // Fallback to legacy implementation for safety
                #if debug_variable_renaming
                #if debug_ast_builder
                trace('[RENAME DEBUG] TObjectDecl: Processing ${fields.length} fields');
                #end
                for (field in fields) {
                    #if debug_ast_builder
                    trace('[RENAME DEBUG]   Field "${field.name}" expr type: ${Type.enumConstructor(field.expr.expr)}');
                    #end
                    switch(field.expr.expr) {
                        case TLocal(v):
                            #if debug_ast_builder
                            trace('[RENAME DEBUG]     References TLocal: "${v.name}" (id: ${v.id})');
                            #end
                            if (~/^.+\d+$/.match(v.name)) {
                                #if debug_ast_builder
                                trace('[RENAME DEBUG]     WARNING: Field references renamed variable!');
                                #end
                            }
                        case TField(obj, fa):
                            #if debug_ast_builder
                            trace('[RENAME DEBUG]     TField access');
                            #end
                            switch(obj.expr) {
                                case TLocal(v):
                                    #if debug_ast_builder
                                    trace('[RENAME DEBUG]       On object: "${v.name}" (id: ${v.id})');
                                    #end
                                    if (~/^.+\d+$/.match(v.name)) {
                                        #if debug_ast_builder
                                        trace('[RENAME DEBUG]       WARNING: Field access on renamed variable!');
                                        #end
                                    }
                                default:
                            }
                        default:
                    }
                }
                #end

                // First, check if this is a tuple pattern (anonymous structure with _1, _2, etc. fields)
                var isTuplePattern = true;
                var maxTupleIndex = 0;
                
                // Check if all fields follow the tuple naming pattern _1, _2, _3...
                for (field in fields) {
                    if (!~/^_\d+$/.match(field.name)) {
                        isTuplePattern = false;
                        break;
                    }
                    var index = Std.parseInt(field.name.substr(1));
                    if (index > maxTupleIndex) {
                        maxTupleIndex = index;
                    }
                }
                
                // If it's a tuple pattern, generate an Elixir tuple
                if (isTuplePattern && fields.length > 0) {
                    // Sort fields by index to ensure correct order
                    var sortedFields = fields.copy();
                    sortedFields.sort(function(a, b) {
                        var aIndex = Std.parseInt(a.name.substr(1));
                        var bIndex = Std.parseInt(b.name.substr(1));
                        return aIndex - bIndex;
                    });
                    
                    // Build tuple elements in order
                    var tupleElements = [];
                    for (field in sortedFields) {
                        tupleElements.push(buildFromTypedExpr(field.expr, currentContext));
                    }
                    
                    return ETuple(tupleElements);
                }
                
                // Detect supervisor options pattern by checking for characteristic fields
                var hasStrategy = false;
                var hasMaxRestarts = false; 
                var hasMaxSeconds = false;
                
                // Detect child spec pattern
                var hasId = false;
                var hasStart = false;
                var hasType = false;
                
                for (field in fields) {
                    switch(field.name) {
                        case "strategy": hasStrategy = true;
                        case "max_restarts": hasMaxRestarts = true;
                        case "max_seconds": hasMaxSeconds = true;
                        case "id": hasId = true;
                        case "start": hasStart = true;
                        case "type": hasType = true;
                        case _:
                    }
                }
                
                // Supervisor options require keyword list format for Supervisor.start_link/2
                if (hasStrategy && (hasMaxRestarts || hasMaxSeconds)) {
                    var keywordPairs: Array<EKeywordPair> = [];
                    for (field in fields) {
                        // Convert field names to snake_case for idiomatic Elixir atoms
                        var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                        var fieldValue = buildFromTypedExpr(field.expr, currentContext);
                        keywordPairs.push({key: atomName, value: fieldValue});
                    }
                    EKeywordList(keywordPairs);
                } else if (hasId && hasStart) {
                    // Child spec pattern - needs special handling for the start field
                    var pairs = [];
                    for (field in fields) {
                        // Convert camelCase field names to snake_case for Elixir atoms
                        var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                        var key = makeAST(EAtom(atomName));
                        
                        // Special handling for the start field in child specs
                        var fieldValue = if (field.name == "start") {
                            // Check if start is an object with module/func/args
                            switch(field.expr.expr) {
                                case TObjectDecl(startFields):
                                    var moduleField = null;
                                    var funcField = null;
                                    var argsField = null;
                                    
                                    for (sf in startFields) {
                                        switch(sf.name) {
                                            case "module": moduleField = sf;
                                            case "func": funcField = sf;
                                            case "args": argsField = sf;
                                            case _:
                                        }
                                    }
                                    
                                    if (moduleField != null && funcField != null && argsField != null) {
                                        // Convert to tuple format {Module, :func, args}
                                        var moduleAst = switch(moduleField.expr.expr) {
                                            case TConst(TString(s)):
                                                // Convert string module name to atom
                                                makeAST(EVar(s));
                                            case _:
                                                buildFromTypedExpr(moduleField.expr, currentContext);
                                        };
                                        
                                        var funcAst = switch(funcField.expr.expr) {
                                            case TConst(TString(s)):
                                                // Convert string function name to atom
                                                makeAST(EAtom(s));
                                            case _:
                                                buildFromTypedExpr(funcField.expr, currentContext);
                                        };
                                        
                                        var argsAst = buildFromTypedExpr(argsField.expr, currentContext);
                                        
                                        // Create tuple {Module, :func, args}
                                        makeAST(ETuple([moduleAst, funcAst, argsAst]));
                                    } else {
                                        // Not the expected format, compile normally
                                        buildFromTypedExpr(field.expr, currentContext);
                                    }
                                    
                                case _:
                                    // Not an object, compile normally
                                    buildFromTypedExpr(field.expr, currentContext);
                            }
                        } else if (field.name == "type" || field.name == "restart" || field.name == "shutdown") {
                            // These fields should be atoms when they're strings
                            switch(field.expr.expr) {
                                case TConst(TString(s)):
                                    makeAST(EAtom(s));
                                case _:
                                    buildFromTypedExpr(field.expr, currentContext);
                            }
                        } else {
                            // Standard field value compilation
                            buildFromTypedExpr(field.expr, currentContext);
                        };
                        
                        pairs.push({key: key, value: fieldValue});
                    }
                    EMap(pairs);
                } else {
                    // Regular object - generate as map
                    var pairs = [];
                    for (field in fields) {
                        // Convert camelCase field names to snake_case for Elixir atoms
                        var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(field.name);
                        var key = makeAST(EAtom(atomName));
                        
                        /**
                         * Detect and transform null coalescing pattern in object field values.
                         * 
                         * Haxe compiles `field: value ?? default` into a TBlock containing:
                         * 1. TVar(tmpVar, init) - temporary variable assignment
                         * 2. TBinop(OpNullCoal, TLocal(v), defaultExpr) - null coalescing operation
                         * 
                         * This pattern is transformed into Elixir's inline if-expression:
                         * `if (tmp = value) != nil, do: tmp, else: default`
                         */
                        var fieldValue = switch(field.expr.expr) {
                        case TBlock([{expr: TVar(tmpVar, init)}, {expr: TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr)}]) 
                            if (v.id == tmpVar.id && init != null):
                            // Transform null coalescing pattern to idiomatic Elixir
                            var initAst = buildFromTypedExpr(init, currentContext);
                            var defaultAst = buildFromTypedExpr(defaultExpr, currentContext);
                            var tmpVarName = VariableAnalyzer.toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                            
                            var ifExpr = makeAST(EIf(
                                makeAST(EBinary(NotEqual, 
                                    makeAST(EMatch(PVar(tmpVarName), initAst)),
                                    makeAST(ENil)
                                )),
                                makeAST(EVar(tmpVarName)),
                                defaultAst
                            ));
                            // Mark for inline rendering to maintain compact syntax
                            if (ifExpr.metadata == null) ifExpr.metadata = {};
                            ifExpr.metadata.keepInlineInAssignment = true;
                            ifExpr;
                            
                        case _:
                            // Check if the field expression references a renamed variable
                            // When options2 is referenced, we need to use "options" instead
                            var fieldValue = switch(field.expr.expr) {
                                case TLocal(v):
                                    var idKey = Std.string(v.id);

                                    // Check tempVarRenameMap first (Codex's recommendation)
                                    if (currentContext != null && currentContext.tempVarRenameMap.exists(idKey)) {
                                        var mappedName = currentContext.tempVarRenameMap.get(idKey);
                                        #if debug_variable_renaming
                                        #if debug_ast_builder
                                        trace('[RENAME DEBUG] TObjectDecl: Field "${field.name}" using tempVarRenameMap: "${v.name}" -> "${mappedName}"');
                                        #end
                                        #end
                                        makeAST(EVar(mappedName));
                                    } else {
                                        // No mapping, compile normally
                                        buildFromTypedExpr(field.expr, currentContext);
                                    }
                                default:
                                    // Not a local variable reference
                                    buildFromTypedExpr(field.expr, currentContext);
                            };

                            fieldValue;
                    };

                    pairs.push({key: key, value: fieldValue});
                    }
                    EMap(pairs);
                }
                
            // ================================================================
            // Type Operations
            // ================================================================
            case TTypeExpr(m):
                // Check if this is a class with @:native annotation
                var moduleName = moduleTypeToString(m);
                
                // Check if this module has @:native metadata - this applies to both extern and regular classes
                // For schemas with @:native("TodoApp.Todo"), we need to use the full module name
                var isNativeModule = switch(m) {
                    case TClassDecl(c):
                        var cl = c.get();
                        // Check if it has @:native annotation (for extern OR schema classes)
                        if (cl.meta.has(":native")) {
                            // Get the native name from metadata
                            var nativeMeta = cl.meta.extract(":native");
                            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                                switch(nativeMeta[0].params[0].expr) {
                                    case EConst(CString(s, _)):
                                        moduleName = s;
                                        true;
                                    default:
                                        false;
                                }
                            } else {
                                false;
                            }
                        } else {
                            false;
                        }
                    default:
                        false;
                };
                
                // Module references should always be EVar (no colon prefix)
                // This applies to both native Elixir modules and compiled Haxe classes
                EVar(moduleName);  // Module references are just capitalized identifiers
                
            case TCast(e, m):
                // Casts are mostly compile-time in Haxe
                buildFromTypedExpr(e, currentContext).def;
                
            case TParenthesis(e):
                EParen(buildFromTypedExpr(e, currentContext));
                
            case TMeta(m, e):
                // Metadata wrapping - preserve the expression
                #if debug_ast_builder
                trace('[TMeta] Processing metadata: ${m.name}');
                #if debug_ast_builder
                trace('[TMeta] Inner expression type: ${Type.enumConstructor(e.expr)}');
                #end
                #end
                // Special handling for :mergeBlock which wraps null coalescing patterns
                if (m.name == ":mergeBlock") {
                    // Check if this is a null coalescing pattern
                    switch(e.expr) {
                        case TBlock([{expr: TVar(tmpVar, init)}, secondExpr]) if (init != null):
                            // Check if the second expression uses the temp variable
                            switch(secondExpr.expr) {
                                case TIf(condition, thenBranch, elseBranch):
                                    // Check if this is testing the temp variable for null
                                    var isNullCheck = switch(condition.expr) {
                                        case TParenthesis({expr: TBinop(OpNotEq, {expr: TLocal(v)}, {expr: TConst(TNull)})}):
                                            v.id == tmpVar.id;
                                        default: false;
                                    };
                                    
                                    if (isNullCheck) {
                                        // This is null coalescing! Generate inline if expression
                                        var tmpVarName = VariableAnalyzer.toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                                        var initAst = buildFromTypedExpr(init, currentContext);
                                        var elseAst = buildFromTypedExpr(elseBranch, currentContext);
                                        
                                        // Generate: if (tmp = init) != nil, do: tmp, else: default
                                        var ifExpr = makeAST(EIf(
                                            makeAST(EBinary(NotEqual, 
                                                makeAST(EParen(makeAST(EMatch(PVar(tmpVarName), initAst)))),
                                                makeAST(ENil)
                                            )),
                                            makeAST(EVar(tmpVarName)),
                                            elseAst
                                        ));
                                        // Mark as inline for null coalescing
                                        if (ifExpr.metadata == null) ifExpr.metadata = {};
                                        ifExpr.metadata.keepInlineInAssignment = true;
                                        return ifExpr.def;
                                    }
                                default:
                            }
                        default:
                    }
                }
                // Build the inner expression
                var innerAST = buildFromTypedExpr(e, currentContext);
                #if debug_ast_builder
                trace('[TMeta] Returning innerAST.def');
                #end
                innerAST.def;  // Return the def as expected by the switch
                
            // ================================================================
            // Special Cases
            // ================================================================
            case TNew(c, params, el):
                // Delegate to ConstructorBuilder for modular handling
                var result = reflaxe.elixir.ast.builders.ConstructorBuilder.build(c, params, el, currentContext);
                if (result != null) return result;
                
                // Fallback to legacy implementation for safety
                // Constructor call - should call ModuleName.new() for classes with instance methods
                var classType = c.get();
                var className = classType.name;
                var args = [for (e in el) buildFromTypedExpr(e, currentContext)];
                
                // Check if this is an Ecto schema - schemas use struct literals, not constructors
                if (classType.meta.has(":schema")) {
                    // Get the full module name from @:native or use className
                    var moduleName = if (classType.meta.has(":native")) {
                        var nativeMeta = classType.meta.extract(":native");
                        if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                            switch(nativeMeta[0].params[0].expr) {
                                case EConst(CString(s, _)):
                                    s;
                                default:
                                    className;
                            }
                        } else {
                            className;
                        }
                    } else {
                        className;
                    };
                    // Generate struct literal: %ModuleName{}
                    EStruct(moduleName, []);
                } else if (className == "StringMap" || className == "Map" || className.endsWith("Map")) {
                    // Check if this is a Map type (StringMap, IntMap, etc.)
                    // Maps should generate regular Elixir maps %{}, not structs
                    // Generate empty map for Map constructors
                    EMap([]);
                } else {
                    // Check if this class has instance methods (not just a data class)
                    var hasInstanceMethods = false;
                    for (field in classType.fields.get()) {
                        // Instance methods are FMethod that are not in the statics list
                        if (field.kind.match(FMethod(_))) {
                            // Check if this field is NOT in the statics array
                            var isStatic = false;
                            for (staticField in classType.statics.get()) {
                                if (staticField.name == field.name) {
                                    isStatic = true;
                                    break;
                                }
                            }
                            if (!isStatic) {
                                hasInstanceMethods = true;
                                break;
                            }
                        }
                    }
                    
                    // Also check if it has a constructor
                    var hasConstructor = classType.constructor != null;
                    
                    if (hasInstanceMethods || hasConstructor) {
                        // Call the module's new function: ModuleName.new(args)
                        // In Elixir, this is a module function call
                        var moduleRef = makeAST(EVar(className));
                        ECall(moduleRef, "new", args);
                    } else {
                        // Simple data class - create as struct
                        EStruct(className, []);
                    }
                }
                
            case TFor(v, e1, e2):
                #if debug_ast_builder
                trace('[TFor] Processing for loop, var: ${v.name}');
                trace('[TFor] Body expression type: ${Type.enumConstructor(e2.expr)}');
                switch(e2.expr) {
                    case TBlock(exprs):
                        trace('[TFor] Body is TBlock with ${exprs.length} expressions');
                        for (i in 0...exprs.length) {
                            trace('[TFor]   [$i]: ${Type.enumConstructor(exprs[i].expr)}');
                        }
                    case TSwitch(switchExpr, _, _):
                        trace('[TFor] Body is direct TSwitch on: ${Type.enumConstructor(switchExpr.expr)}');
                    default:
                        trace('[TFor] Body is: ${Type.enumConstructor(e2.expr)}');
                }
                #end
                
                // Delegate ALL for loop compilation to LoopBuilder
                // Create adapter for BuildContext interface
                var buildContext: reflaxe.elixir.ast.builders.LoopBuilder.BuildContext = {
                    isFeatureEnabled: function(f) return currentContext.isFeatureEnabled(f),
                    buildFromTypedExpr: function(e, ?ctx) return buildFromTypedExpr(e, currentContext),
                    whileLoopCounter: currentContext.whileLoopCounter
                };
                return LoopBuilder.buildFor(v, e1, e2, expr, buildContext, name -> VariableAnalyzer.toElixirVarName(name));
                
            case TWhile(econd, e, normalWhile):
                // Delegate ALL while loop compilation to LoopBuilder
                // Create adapter for BuildContext interface
                var buildContext: reflaxe.elixir.ast.builders.LoopBuilder.BuildContext = {
                    isFeatureEnabled: function(f) return currentContext.isFeatureEnabled(f),
                    buildFromTypedExpr: function(e, ?ctx) return buildFromTypedExpr(e, currentContext),
                    whileLoopCounter: currentContext.whileLoopCounter
                };
                return LoopBuilder.buildWhileComplete(econd, e, normalWhile, expr, buildContext, name -> VariableAnalyzer.toElixirVarName(name)); 
                
            case TEnumParameter(e, ef, index):
                /**
                 * TEnumParameter extraction for enum constructor parameters
                 *
                 * WHY: When Haxe compiles enum patterns like `case Ok(value):`, it generates
                 *      TEnumParameter expressions to extract the parameters. However, in Elixir
                 *      pattern matching, the pattern `{:ok, value}` already extracts the value.
                 *
                 * PROBLEM: When patterns have ignored parameters like `case Ok(_):`, Haxe still
                 *          generates TEnumParameter which tries to extract from the already-extracted
                 *          value. This causes runtime errors like `elem(nil, 1)` when the extracted
                 *          value is nil.
                 *
                 * SOLUTION: Use the EnumBindingPlan from ClauseContext which provides a single
                 *           source of truth for variable names at each parameter index.
                 *
                 * EDGE CASES:
                 * - Ignored parameters: Pattern extracts to temp var but it's not used
                 * - Nested enums: Multiple levels of extraction
                 * - Abstract types: May not have ClauseContext mappings
                 * - ChangesetUtils: Patterns use canonical names but body expects temp vars
                 */

                // Debug trace to understand the extraction context
                #if debug_enum_extraction
                #if debug_ast_builder
                trace('[TEnumParameter] Attempting extraction:');
                #end
                #if debug_ast_builder
                trace('  - Expression type: ${e.expr}');
                #end
                #if debug_ast_builder
                trace('  - Enum field: ${ef.name}');
                #end
                #if debug_ast_builder
                trace('  - Index: $index');
                #end
                #if debug_ast_builder
                trace('  - Has ClauseContext: ${currentContext.currentClauseContext != null}');
                #end
                if (currentContext.currentClauseContext != null) {
                    #if debug_ast_builder
                    trace('  - Has EnumBindingPlan: ${currentContext.currentClauseContext.enumBindingPlan != null && currentContext.currentClauseContext.enumBindingPlan.keys().hasNext()}');
                    #end
                    if (currentContext.currentClauseContext.enumBindingPlan.exists(index)) {
                        var info = currentContext.currentClauseContext.enumBindingPlan.get(index);
                        #if debug_ast_builder
                        trace('  - Binding plan for index $index: ${info.finalName} (used: ${info.isUsed})');
                        #end
                    }
                }
                #end

                // CRITICAL FIX for ChangesetUtils pattern-body mismatch:
                // When TEnumParameter tries to extract from a variable like 'g' that doesn't exist
                // because the pattern used canonical names directly (like {:ok, value}),
                // we need to detect this and return the correct variable.

                // First, check what variable we're trying to extract from
                var sourceVarName: String = null;
                switch(e.expr) {
                    case TLocal(v):
                        sourceVarName = VariableAnalyzer.toElixirVarName(v.name);
                        #if debug_enum_extraction
                        #if debug_ast_builder
                        trace('[TEnumParameter] Extracting from variable: $sourceVarName');
                        #end
                        #end
                    default:
                        // Not a local variable
                }

                // Check if we have a binding plan for this index
                if (currentContext.currentClauseContext != null && currentContext.currentClauseContext.enumBindingPlan.exists(index)) {
                    // Use the variable name from the binding plan
                    var info = currentContext.currentClauseContext.enumBindingPlan.get(index);

                    #if debug_ast_builder
                    trace('[DEBUG EMBEDDED TEnumParameter] Binding plan says to use: ${info.finalName}, sourceVarName: $sourceVarName');
                    #end

                    #if debug_enum_extraction
                    #if debug_ast_builder
                    trace('  - Binding plan says to use: ${info.finalName}');
                    #end
                    #end

                    // CRITICAL: Check if we're trying to extract from a temp var that doesn't exist
                    // This happens when the pattern used canonical names directly
                    if (sourceVarName != null &&
                        (sourceVarName == "g" || (sourceVarName.startsWith("g") && sourceVarName.length > 1 &&
                         sourceVarName.charAt(1) >= '0' && sourceVarName.charAt(1) <= '9'))) {
                        // We're trying to extract from a temp var like 'g', 'g1', 'g2'
                        // But if the binding plan uses a different name, the pattern already extracted it
                        if (info.finalName != sourceVarName) {
                            #if debug_ast_builder
                            trace('[DEBUG EMBEDDED TEnumParameter] RETURNING DIRECT VAR: ${info.finalName}');
                            #end
                            #if debug_enum_extraction
                            #if debug_ast_builder
                            trace('[TEnumParameter] Pattern used ${info.finalName}, not temp var $sourceVarName');
                            #end
                            #if debug_ast_builder
                            trace('[TEnumParameter] Returning ${info.finalName} directly (already extracted by pattern)');
                            #end
                            #end
                            // The pattern already extracted to the correct variable
                            return EVar(info.finalName);
                        }
                    }

                    // ID-BASED TRACKING: Check if this would create a redundant assignment
                    // If the binding plan says to use the same name as the source, it would create g = g
                    if (info.finalName == sourceVarName && sourceVarName != null) {
                        #if debug_ast_builder
                        trace('[DEBUG g=g FOUND] Self-assignment detected: ${sourceVarName} = ${sourceVarName}, skipping');
                        #end
                        // This would create g = g, skip the assignment by returning null
                        return null;
                    } else {
                        // Normal case: use the binding plan variable
                        #if debug_ast_builder
                        trace('[DEBUG EMBEDDED TEnumParameter] RETURNING BINDING PLAN VAR: ${info.finalName}');
                        #end
                        return EVar(info.finalName);
                    }
                } else {
                    #if debug_ast_builder
                    trace('[DEBUG EMBEDDED TEnumParameter] NO BINDING PLAN! ClauseContext: ${currentContext.currentClauseContext != null}, index: $index, sourceVarName: $sourceVarName');
                    #end

                    // CRITICAL FIX: When there's no binding plan and we're trying to extract from
                    // a temp var that doesn't exist (like 'g'), return null to skip the assignment
                    // This happens in embedded switches where the pattern uses the actual variable name
                    if (sourceVarName != null &&
                        (sourceVarName == "g" || (sourceVarName.startsWith("g") && sourceVarName.length > 1 &&
                         sourceVarName.charAt(1) >= '0' && sourceVarName.charAt(1) <= '9'))) {
                        #if debug_ast_builder
                        trace('[DEBUG EMBEDDED TEnumParameter] Skipping extraction from non-existent temp var: $sourceVarName');
                        #end
                        // Return null to skip the assignment - the pattern already extracted the value
                        return null;
                    }

                    // Fallback to the old logic for backward compatibility

                    // Check if this is extracting from an already-extracted pattern variable
                    var skipExtraction = false;
                    var extractedVarName: String = null;

                    // Check if we're in a switch case context where patterns have already extracted values
                    // This avoids redundant extraction like: case {:ok, g} -> g = elem(result, 1)

                    // Check for local variables that might be extracted pattern variables
                    if (!skipExtraction) {
                        switch(e.expr) {
                            case TLocal(v):
                                var varName = VariableAnalyzer.toElixirVarName(v.name);

                                #if debug_enum_extraction
                                #if debug_ast_builder
                                trace('  - TLocal variable: ${v.name} -> $varName');
                                #end
                                if (currentContext.currentClauseContext != null) {
                                    #if debug_ast_builder
                                    trace('  - ClauseContext has mapping: ${currentContext.currentClauseContext.localToName.exists(v.id)}');
                                    #end
                                    if (currentContext.currentClauseContext.localToName.exists(v.id)) {
                                        #if debug_ast_builder
                                        trace('  - Mapped to: ${currentContext.currentClauseContext.localToName.get(v.id)}');
                                        #end
                                    }
                                }
                                #end

                                // Check if this variable was extracted by the pattern
                                // Pattern extraction creates variables like 'g', 'g1', 'g2' for ignored params
                                // or uses actual names for named params
                                if (currentContext.currentClauseContext != null && currentContext.currentClauseContext.localToName.exists(v.id)) {
                                    // This variable was mapped in the pattern, it's already extracted
                                    extractedVarName = currentContext.currentClauseContext.localToName.get(v.id);
                                    skipExtraction = true;

                                    #if debug_enum_extraction
                                    #if debug_ast_builder
                                    trace('  - SKIPPING extraction, already extracted to: $extractedVarName');
                                    #end
                                    #end
                                } else {
                                    // Check metadata to see if this is truly a temp extraction variable
                                    var isExtractionTemp = false;

                                    // First check if we have VarOrigin metadata
                                    if (currentContext.tempVarRenameMap.exists(Std.string(v.id))) {
                                        // This is a renamed temp variable
                                        isExtractionTemp = true;
                                    } else if (varName == "g" || (varName.startsWith("g") && varName.length > 1 &&
                                              varName.charAt(1) >= '0' && varName.charAt(1) <= '9')) {
                                        // Name pattern suggests temp var, but need more context
                                        // Check if this variable was created from TEnumParameter
                                        // For now, be conservative and only treat as temp if we're sure
                                        // TODO: Use VarOrigin metadata when available
                                        isExtractionTemp = false; // Conservative: avoid false positives
                                    }

                                    if (isExtractionTemp) {
                                        // This is definitely a temp extraction variable
                                        extractedVarName = varName;
                                        skipExtraction = true;

                                        #if debug_enum_extraction
                                        #if debug_ast_builder
                                        trace('  - SKIPPING extraction, detected as pattern temp var: $varName');
                                        #end
                                        #end
                                    }
                                }
                            case _:
                                // Not a local variable, normal extraction needed
                                #if debug_enum_extraction
                                #if debug_ast_builder
                                trace('  - Not a TLocal, proceeding with extraction');
                                #end
                                #end
                        }
                    }

                    if (skipExtraction && extractedVarName != null) {
                        // The pattern already extracted this value, just return the variable reference
                        EVar(extractedVarName);
                    } else {
                        // Normal case: generate the elem() extraction
                        var exprAST = buildFromTypedExpr(e, currentContext);

                        #if debug_enum_extraction
                        #if debug_ast_builder
                        trace('  - Generating elem() extraction');
                        #end
                        #end

                        // Will be transformed to proper pattern extraction
                        // +1 because Elixir tuples are 0-based but first element is the tag
                        ECall(exprAST, "elem", [makeAST(EInteger(index + 1))]);
                    }
                }
                
            case TEnumIndex(e):
                // Get enum tag index - always use the enum value directly for atom-based matching
                // We don't use elem() because we're matching on atom tuples like {:TodoUpdates}
                // The switch will generate patterns like: {:TodoUpdates} -> ... {:UserActivity} -> ...
                var enumExpr = buildFromTypedExpr(e, currentContext);
                if (enumExpr != null) {
                    enumExpr.def;
                } else {
                    // Fallback if the expression couldn't be built
                    EVar("nil");
                }
                
            case TThrow(e):
                // Delegate to ExceptionBuilder for throw expressions
                var result = ExceptionBuilder.buildThrow(e, currentContext);
                if (result != null) {
                    return result;
                }
                // Fallback to legacy implementation
                EThrow(buildFromTypedExpr(e, currentContext));
                
            case TIdent(s):
                // Identifier reference
                EVar(VariableAnalyzer.toElixirVarName(s));
        }
    }
    
    /**
     * Build a switch that pattern matches on object fields
     * 
     * WHY: When Haxe desugars switch(obj.field), we need to generate idiomatic
     *      Elixir pattern matching on the object with field patterns
     * WHAT: Transforms switch(field_value) to case obj do %{field: value} -> ... end
     * HOW: Builds map patterns for each case value and extracts other object fields
     * 
     * @param rootObj The root object to switch on (e.g., msg)
     * @param fieldName The field name being matched (e.g., "type")
     * @param cases The original switch cases
     * @param edef The default case (if any)
     * @param pos Position for error reporting
     * @param context Current build context
     * @return ElixirAST representing the field pattern switch
     */
    static function buildFieldPatternSwitch(rootObj: TypedExpr, fieldName: String, 
                                           cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>,
                                           edef: Null<TypedExpr>, pos: Position, 
                                           context: reflaxe.elixir.CompilationContext): ElixirASTDef {
        #if debug_ast_builder
        trace('[buildFieldPatternSwitch] Building field pattern switch on ${fieldName}');
        trace('[buildFieldPatternSwitch] Root object type: ${Type.enumConstructor(rootObj.expr)}');
        #end
        
        // Build the switch target (the root object)
        var targetAST = buildFromTypedExpr(rootObj, context);
        
        // Check if we got nil (which happens when the rootObj is not properly resolved)
        // This can happen with infrastructure variables where the object is not available
        if (targetAST.def == ENil) {
            #if debug_ast_builder
            trace('[buildFieldPatternSwitch] WARNING: targetAST is nil, falling back to direct switch');
            #end
            // Fallback: generate a simple switch on nil which won't work but at least compiles
            // This should be fixed properly by ensuring rootObj is correctly passed
        }
        
        // Extract all fields from the object type for pattern extraction
        var objectFields: Array<String> = [];
        switch(rootObj.t) {
            case TAnonymous(anonRef):
                var anon = anonRef.get();
                for (field in anon.fields) {
                    objectFields.push(field.name);
                    #if debug_ast_builder
                    trace('[buildFieldPatternSwitch] Found field: ${field.name}');
                    #end
                }
            default:
                // Not an anonymous object - can't extract fields
                #if debug_ast_builder
                trace('[buildFieldPatternSwitch] Root object is not anonymous, cannot extract fields');
                #end
        }
        
        // Build the case clauses with field patterns
        var clauses: Array<ECaseClause> = [];
        
        for (switchCase in cases) {
            for (value in switchCase.values) {
                // Build the pattern - we want %{field: value, other_field: other_field_var}
                var patternPairs: Array<{key: ElixirAST, value: EPattern}> = [];
                
                // Add the main field we're matching on
                var fieldValue = buildFromTypedExpr(value, context);
                
                // Convert the field value to a pattern
                var fieldPattern = switch(fieldValue.def) {
                    case EString(s): PLiteral(makeAST(EString(s)));
                    case EInteger(i): PLiteral(makeAST(EInteger(i)));
                    case EFloat(f): PLiteral(makeAST(EFloat(f)));
                    case EBoolean(b): PLiteral(makeAST(EBoolean(b)));
                    case EAtom(a): PLiteral(makeAST(EAtom(a)));
                    case ENil: PLiteral(makeAST(ENil));
                    default: 
                        // For complex patterns, use a variable
                        PVar("_matched_value");
                };
                
                patternPairs.push({
                    key: makeAST(EAtom(fieldName)),
                    value: fieldPattern
                });
                
                // Add patterns for other fields to extract them
                for (otherField in objectFields) {
                    if (otherField != fieldName) {
                        // Generate a variable name for this field (e.g., msg_data for "data" field)
                        // Extract the root object name
                        var rootName = switch(rootObj.expr) {
                            case TLocal(v): v.name;
                            case TField(_, FAnon(cf)): cf.get().name;
                            case TField(_, FInstance(_, _, cf)): cf.get().name;
                            default: "obj";
                        };
                        
                        var varName = VariableAnalyzer.toElixirVarName(rootName + "_" + otherField);
                        #if debug_ast_builder
                        trace('[buildFieldPatternSwitch] Extracting field ${otherField} as ${varName}');
                        #end
                        
                        patternPairs.push({
                            key: makeAST(EAtom(otherField)),
                            value: PVar(varName)
                        });
                    }
                }
                
                // Build the map pattern (not wrapped in makeAST - it's already a pattern)
                var pattern = PMap(patternPairs);
                
                // Build the body
                var body = buildFromTypedExpr(switchCase.expr, context);
                
                // Create the clause directly as ECaseClause (no makeAST wrapper)
                var clauseDef: ECaseClause = {
                    pattern: pattern,
                    guard: null,
                    body: body
                };
                clauses.push(clauseDef);
            }
        }
        
        // Add default case if present
        if (edef != null) {
            var defaultBody = buildFromTypedExpr(edef, context);
            var defaultClauseDef: ECaseClause = {
                pattern: PWildcard,
                guard: null,
                body: defaultBody
            };
            clauses.push(defaultClauseDef);
        }
        
        #if debug_ast_builder
        trace('[buildFieldPatternSwitch] Generated ${clauses.length} clauses');
        #end
        
        // Return the case expression
        return ECase(targetAST, clauses);
    }
    
    /**
     * Try to detect and optimize array iteration patterns
     * 
     * WHY: Haxe desugars array.map/filter into while loops with index counters
     * WHAT: Detects these patterns and generates idiomatic Enum calls instead
     * HOW: Analyzes condition and body to identify map/filter/reduce patterns
     * 
     * @param econd The while loop condition
     * @param ebody The while loop body
     * @return Optimized ElixirAST using Enum functions, or null if no pattern detected
     */
    static function tryOptimizeArrayPattern(econd: TypedExpr, ebody: TypedExpr): Null<ElixirAST> {
        // Debug: Print the condition to understand its structure
        #if debug_array_patterns
        #if debug_ast_builder
        trace("[Array Pattern] Checking condition: " + haxe.macro.ExprTools.toString(Context.getTypedExpr(econd)));
        #end
        #end
        
        // Simple pattern check for _g1 < _g2.length
        // When Haxe desugars array.map, it creates: _g1 = 0; _g2 = array; while(_g1 < _g2.length)
        var isArrayPattern = false;
        var arrayVarName = "";
        var indexVarName = "";
        
        switch(econd.expr) {
            case TBinop(OpLt, e1, e2):
                switch(e1.expr) {
                    case TLocal(indexVar) if (indexVar.name.startsWith("_g")):
                        switch(e2.expr) {
                            case TField(arrayRef, FInstance(_, _, cf)) if (cf.get().name == "length"):
                                // We have _gX < something.length
                                switch(arrayRef.expr) {
                                    case TLocal(arrayVar) if (arrayVar.name.startsWith("_g")):
                                        // Pattern: _g1 < _g2.length
                                        isArrayPattern = true;
                                        indexVarName = indexVar.name;
                                        arrayVarName = arrayVar.name;
                                        #if debug_array_patterns
                                        #if debug_ast_builder
                                        trace("[Array Pattern] DETECTED: " + indexVarName + " < " + arrayVarName + ".length");
                                        #end
                                        #end
                                    case _:
                                        // Direct array: _g < array.length
                                        isArrayPattern = true;
                                        indexVarName = indexVar.name;
                                }
                            case _:
                        }
                    case _:
                }
            case _:
        }
        
        if (!isArrayPattern) {
            #if debug_array_patterns
            #if debug_ast_builder
            trace("[Array Pattern] No array pattern detected");
            #end
            #end
            return null;
        }
        
        // Delegate to LoopOptimizer for loop body analysis
        var bodyAnalysis = LoopOptimizer.analyzeLoopBody(ebody);
        
        // For _g2 pattern, we need to generate a reference to the actual array variable
        // The actual array should be available as a local variable named _g2
        var arrayExpr = makeAST(EVar(VariableAnalyzer.toElixirVarName(arrayVarName.length > 0 ? arrayVarName : "_g2")));
        
        // Generate appropriate Enum call based on pattern
        if (bodyAnalysis.hasMapPattern) {
            // Generate Enum.map with extracted transformation
            var loopVar = bodyAnalysis.loopVar != null ? VariableAnalyzer.toElixirVarName(bodyAnalysis.loopVar.name) : "item";
            var transformation = LoopOptimizer.extractMapTransformation(ebody, bodyAnalysis.loopVar);
            return EnumHandler.generateEnumMap(arrayExpr, loopVar, transformation, currentContext);
        } else if (bodyAnalysis.hasFilterPattern) {
            // Generate Enum.filter with extracted condition
            var loopVar = bodyAnalysis.loopVar != null ? VariableAnalyzer.toElixirVarName(bodyAnalysis.loopVar.name) : "item";
            var condition = LoopOptimizer.extractFilterCondition(ebody);
            return EnumHandler.generateEnumFilter(arrayExpr, loopVar, condition, currentContext);
        } else if (bodyAnalysis.hasReducePattern) {
            // Reduce patterns are more complex, skip for now
            return null;
        }
        
        // No clear pattern detected, return null to use regular while loop
        return null;
    }
    
    // detectArrayIterationPattern deleted - now delegated to LoopOptimizer
    
    // analyzeLoopBody deleted - now delegated to LoopOptimizer
    
    // extractMapTransformation, extractFilterCondition, containsPush deleted - now delegated to LoopOptimizer
    
    /**
     * Build AST with variable substitution for lambda parameters
     */
    static function buildFromTypedExprWithSubstitution(expr: TypedExpr, loopVar: Null<TVar>): ElixirAST {
        // For now, just use the regular build function
        // TODO: Implement proper variable substitution
        return buildFromTypedExpr(expr, currentContext);
    }
    
    /**
     * Create metadata from TypedExpr
     */
    static function createMetadata(expr: TypedExpr): ElixirMetadata {
        return {
            sourceExpr: expr,
            sourceLine: expr.pos != null ? Context.getPosInfos(expr.pos).min : 0,
            sourceFile: expr.pos != null ? Context.getPosInfos(expr.pos).file : null,
            type: expr.t,
            elixirType: typeToElixir(expr.t),
            purity: PatternDetector.isPure(expr),
            tailPosition: false, // Will be set by transformer
            async: false, // Will be detected by transformer
            requiresReturn: false, // Will be set by context
            requiresTempVar: false, // Will be set by transformer
            inPipeline: false, // Will be set by transformer
            inComprehension: false, // Will be set by context
            inGuard: false, // Will be set by context
            canInline: canBeInlined(expr),
            isConstant: PatternDetector.isConstant(expr),
            sideEffects: hasSideEffects(expr)
        };
    }
    
    /**
     * Convert Haxe values to patterns with extracted parameter names
     * 
     * WHY: Regular enums need access to user-specified variable names from switch cases
     * WHAT: Like convertPattern but uses extractedParams for enum constructor arguments
     * HOW: Delegates to PatternBuilder for centralized pattern handling
     */
    
    
    
    
    /**
    /**
     * Check if an enum has @:elixirIdiomatic metadata
     */
    static function hasIdiomaticMetadata(expr: TypedExpr): Bool {
        // First try the direct field access case
        switch(expr.expr) {
            case TField(_, FEnum(enumRef, _)):
                var enumType = enumRef.get();
                var hasIt = enumType.meta.has(":elixirIdiomatic");
                #if debug_ast_builder
                trace('[AST Builder] Checking @:elixirIdiomatic for ${enumType.name}: $hasIt');
                #end
                return hasIt;
            case TTypeExpr(TEnumDecl(enumRef)):
                var enumType = enumRef.get();
                var hasIt = enumType.meta.has(":elixirIdiomatic");
                #if debug_ast_builder
                trace('[AST Builder] Checking @:elixirIdiomatic for enum type expr: $hasIt');
                #end
                return hasIt;
            default:
        }
        
        // Check the return type if this is a function that returns an enum
        switch(expr.t) {
            case TFun(_, ret):
                switch(ret) {
                    case TEnum(enumRef, _):
                        var enumType = enumRef.get();
                        var hasIt = enumType.meta.has(":elixirIdiomatic");
                        #if debug_ast_builder
                        trace('[AST Builder] Checking @:elixirIdiomatic via return type: $hasIt');
                        #end
                        return hasIt;
                    default:
                }
            case TEnum(enumRef, _):
                var enumType = enumRef.get();
                var hasIt = enumType.meta.has(":elixirIdiomatic");
                #if debug_ast_builder
                trace('[AST Builder] Checking @:elixirIdiomatic via direct enum type: $hasIt');
                #end
                return hasIt;
            default:
        }
        
        return false;
    }
    
    // REMOVED buildEnumConstructor - Builder should NOT transform, only build!
    
    
    /**
     * Convert Haxe identifier to Elixir atom name
     * 
     * GENERAL RULE: When Haxe identifiers become Elixir atoms,
     * they should follow Elixir naming conventions (snake_case).
     * This ensures generated code looks idiomatic.
     * 
     * Examples:
     * - OneForOne → one_for_one
     * - RestForOne → rest_for_one
     * - SimpleOneForOne → simple_one_for_one
     */
    static function toElixirAtomName(name: String): String {
        var result = [];
        for (i in 0...name.length) {
            var c = name.charAt(i);
            if (i > 0 && c == c.toUpperCase() && c != c.toLowerCase()) {
                result.push("_");
                result.push(c.toLowerCase());
            } else {
                result.push(c.toLowerCase());
            }
        }
        return result.join("");
    }
    
    /**
     * Check if a TypedExpr contains an if statement
     * Used to determine when variable declarations should be preserved
     */
    static function containsIfStatement(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TIf(_, _, _): true;
            case TBlock(el): 
                // Check if any expression in the block is an if statement
                for (e in el) {
                    if (containsIfStatement(e)) return true;
                }
                false;
            case TWhile(_, body, _): containsIfStatement(body);
            case TFor(_, _, body): containsIfStatement(body);
            case TSwitch(_, cases, _):
                for (c in cases) {
                    if (containsIfStatement(c.expr)) return true;
                }
                false;
            case TCall(_, args):
                for (arg in args) {
                    if (containsIfStatement(arg)) return true;
                }
                false;
            case TVar(_, init) if (init != null): containsIfStatement(init);
            case TBinop(_, e1, e2): containsIfStatement(e1) || containsIfStatement(e2);
            case TUnop(_, _, e): containsIfStatement(e);
            case TParenthesis(e): containsIfStatement(e);
            case TMeta(_, e): containsIfStatement(e);
            case TCast(e, _): containsIfStatement(e);
            case TTry(e, catches):
                if (containsIfStatement(e)) return true;
                for (c in catches) {
                    if (containsIfStatement(c.expr)) return true;
                }
                false;
            default: false;
        }
    }
    
    /**
     * Check if type is an array type
     */
    static function isArrayType(t: Type): Bool {
        return switch(t) {
            case TInst(c, _):
                var cl = c.get();
                cl.name == "Array";
            case TAbstract(a, _):
                var abs = a.get();
                abs.name == "Array";
            default: false;
        }
    }
    
    /**
     * Try to expand __elixir__() injection from a method body
     * 
     * WHY: When Array methods contain __elixir__(), we want to inline them
     * to generate idiomatic Elixir instead of method calls
     * 
     * @param methodExpr The method body expression
     * @param thisExpr The 'this' object (the array)
     * @param args The arguments passed to the method
     * @return The expanded Elixir AST or null if no __elixir__ found
     */
    static function tryExpandElixirInjection(methodExpr: TypedExpr, thisExpr: TypedExpr, args: Array<TypedExpr>, context: reflaxe.elixir.CompilationContext): Null<ElixirAST> {
        #if debug_ast_builder
        trace('[AST Builder] tryExpandElixirInjection examining: ${Type.enumConstructor(methodExpr.expr)}');
        #end
        
        // First check if this is a function, and if so, extract its body
        switch(methodExpr.expr) {
            case TFunction(tfunc):
                // Method is a function, check its body
                if (tfunc.expr != null) {
                    return tryExpandElixirInjection(tfunc.expr, thisExpr, args, context);
                }
            default:
        }
        
        // Look for return statement with __elixir__()
        switch(methodExpr.expr) {
            case TReturn(retOpt):
                // Check if there's a return value
                if (retOpt != null) {
                    return tryExpandElixirCall(retOpt, thisExpr, args, context);
                }
                
            case TBlock(exprs):
                // Check the last expression (implicit return)
                if (exprs.length > 0) {
                    var lastExpr = exprs[exprs.length - 1];
                    return tryExpandElixirCall(lastExpr, thisExpr, args, context);
                }
                
            case TIf(cond, ifExpr, elseExpr):
                // Handle conditional __elixir__() calls (like in slice method)
                // We need to evaluate the condition and choose the right branch
                // For now, we'll try to detect if both branches have __elixir__
                var ifResult = tryExpandElixirCall(ifExpr, thisExpr, args, context);
                if (ifResult != null) {
                    // Both branches likely have __elixir__, create conditional
                    var elseResult = elseExpr != null ? tryExpandElixirCall(elseExpr, thisExpr, args, context) : null;
                    if (elseResult != null) {
                        // Build conditional with expanded branches
                        var condAst = buildFromTypedExpr(cond, context);
                        return makeAST(EIf(condAst, ifResult, elseResult));
                    }
                    // Only if branch has __elixir__
                    return ifResult;
                }
                
            case TCall(_):
                // Direct call, check if it's __elixir__
                return tryExpandElixirCall(methodExpr, thisExpr, args, context);
                
            default:
        }
        return null;
    }
    
    // detectFluentAPIPattern deleted - now delegated to LoopOptimizer
    
    /**
     * Try to expand a specific __elixir__() call
     */
    static function tryExpandElixirCall(expr: TypedExpr, thisExpr: TypedExpr, methodArgs: Array<TypedExpr>, context: reflaxe.elixir.CompilationContext): Null<ElixirAST> {
        #if debug_elixir_injection
        #if debug_ast_builder
        trace("[XRay] tryExpandElixirCall checking expr type: " + expr.expr);
        #end
        #end
        
        switch(expr.expr) {
            // Handle return statements that wrap the actual call
            case TReturn(retExpr) if (retExpr != null):
                #if debug_elixir_injection
                #if debug_ast_builder
                trace("[XRay] Found TReturn wrapper, checking inner: " + retExpr.expr);
                #end
                #end
                return tryExpandElixirCall(retExpr, thisExpr, methodArgs, context);
                
            // Handle untyped __elixir__() calls (wrapped in metadata)
            case TMeta({name: ":untyped"}, untypedExpr):
                #if debug_elixir_injection
                #if debug_ast_builder
                trace("[XRay] Found untyped metadata, checking inner: " + untypedExpr.expr);
                #end
                #end
                return tryExpandElixirCall(untypedExpr, thisExpr, methodArgs, context);
                
            // Handle if-else statements with __elixir__() in branches
            case TIf(cond, ifExpr, elseExpr):
                #if debug_elixir_injection
                #if debug_ast_builder
                trace("[XRay] Found TIf in tryExpandElixirCall");
                #end
                #end
                var ifResult = tryExpandElixirCall(ifExpr, thisExpr, methodArgs, context);
                var elseResult = elseExpr != null ? tryExpandElixirCall(elseExpr, thisExpr, methodArgs, context) : null;
                if (ifResult != null && elseResult != null) {
                    // Both branches have __elixir__, create conditional
                    var condAst = buildFromTypedExpr(cond, context);
                    return makeAST(EIf(condAst, ifResult, elseResult));
                } else if (ifResult != null) {
                    return ifResult;
                } else if (elseResult != null) {
                    return elseResult;
                }
                
            case TCall(e, callArgs):
                #if debug_elixir_injection
                #if debug_ast_builder
                trace("[XRay] TCall with target: " + e.expr);
                #end
                #end
                switch(e.expr) {
                    case TIdent("__elixir__"):
                        #if debug_elixir_injection
                        #if debug_ast_builder
                        trace("[XRay] Found __elixir__() call!");
                        #end
                        #end
                        // Found __elixir__() call!
                        if (callArgs.length > 0) {
                            // First argument should be the code string
                            switch(callArgs[0].expr) {
                                case TConst(TString(code)):
                                    #if debug_elixir_injection
                                    #if debug_ast_builder
                                    trace('[XRay] Expanding __elixir__ with code: $code');
                                    #end
                                    #end
                                    // Process the injection with parameter substitution
                                    var processedCode = code;
                                    
                                    // Substitute {0} with 'this' (the array)
                                    var thisAst = buildFromTypedExpr(thisExpr, context);
                                    var thisStr = ElixirASTPrinter.printAST(thisAst);
                                    processedCode = StringTools.replace(processedCode, "{0}", thisStr);

                                    // Substitute other parameters
                                    for (i in 1...callArgs.length) {
                                        // Map callArgs[i] to the appropriate method argument
                                        // Usually callArgs[1] refers to the first method parameter
                                        if (i - 1 < methodArgs.length) {
                                            var argAst = buildFromTypedExpr(methodArgs[i - 1], context);
                                            var argStr = ElixirASTPrinter.printAST(argAst);
                                            var placeholder = '{$i}';
                                            processedCode = StringTools.replace(processedCode, placeholder, argStr);
                                        }
                                    }
                                    
                                    #if debug_elixir_injection
                                    #if debug_ast_builder
                                    trace('[XRay] Processed code: $processedCode');
                                    #end
                                    #end
                                    
                                    // Return the expanded raw Elixir code
                                    return makeAST(ERaw(processedCode));
                                    
                                default:
                                    #if debug_elixir_injection
                                    #if debug_ast_builder
                                    trace("[XRay] First arg is not TString: " + callArgs[0].expr);
                                    #end
                                    #end
                            }
                        }
                    default:
                        #if debug_elixir_injection
                        #if debug_ast_builder
                        trace("[XRay] Not __elixir__, it's: " + e.expr);
                        #end
                        #end
                }
            default:
                #if debug_elixir_injection
                #if debug_ast_builder
                trace("[XRay] Not a call, it's: " + expr.expr);
                #end
                #end
        }
        return null;
    }
    
    /**
     * Check if type is a Map type
     */
    static function isMapType(t: Type): Bool {
        return switch(t) {
            case TInst(c, _):
                var cl = c.get();
                cl.name == "StringMap" || cl.name == "IntMap" || cl.name == "ObjectMap" || 
                cl.name == "Map" || cl.name.endsWith("Map");
            case TAbstract(a, params):
                var abs = a.get();
                abs.name == "Map" || abs.name.endsWith("Map");
            default: false;
        }
    }
    
    
    /**
     * Convert assignment operator to binary operator
     */
    static function convertAssignOp(op: Binop): EBinaryOp {
        return switch(op) {
            case OpAdd: Add;
            case OpSub: Subtract;
            case OpMult: Multiply;
            case OpDiv: Divide;
            case OpMod: Remainder;
            case OpAnd: BitwiseAnd;
            case OpOr: BitwiseOr;
            case OpXor: BitwiseXor;
            case OpShl: ShiftLeft;
            case OpShr: ShiftRight;
            default: Add; // Fallback
        }
    }
    
    /**
     * Apply parameter renaming to an AST node
     * This is used when function parameters are renamed (e.g., "this" -> "this_1")
     * to ensure the body references the correct parameter names
     */
    static function applyParameterRenaming(ast: ElixirAST, renaming: Map<String, String>): ElixirAST {
        return switch(ast.def) {
            case EVar(name):
                if (renaming.exists(name)) {
                    makeASTWithMeta(EVar(renaming.get(name)), ast.metadata, ast.pos);
                } else {
                    ast;
                }
            
            // Recursively apply to all child nodes
            case EBlock(exprs):
                makeASTWithMeta(EBlock(exprs.map(e -> applyParameterRenaming(e, renaming))), ast.metadata, ast.pos);
            
            case ECall(target, func, args):
                makeASTWithMeta(
                    ECall(
                        target != null ? applyParameterRenaming(target, renaming) : null,
                        func,
                        args.map(a -> applyParameterRenaming(a, renaming))
                    ),
                    ast.metadata, ast.pos
                );
            
            case EBinary(op, left, right):
                makeASTWithMeta(
                    EBinary(op, applyParameterRenaming(left, renaming), applyParameterRenaming(right, renaming)),
                    ast.metadata, ast.pos
                );
            
            case EUnary(op, expr):
                makeASTWithMeta(EUnary(op, applyParameterRenaming(expr, renaming)), ast.metadata, ast.pos);
            
            case EIf(cond, then, else_):
                makeASTWithMeta(
                    EIf(
                        applyParameterRenaming(cond, renaming),
                        applyParameterRenaming(then, renaming),
                        else_ != null ? applyParameterRenaming(else_, renaming) : null
                    ),
                    ast.metadata, ast.pos
                );
                
            case ECase(expr, clauses):
                makeASTWithMeta(
                    ECase(
                        applyParameterRenaming(expr, renaming),
                        clauses.map(c -> {
                            pattern: c.pattern,  // Don't rename in patterns
                            guard: c.guard != null ? applyParameterRenaming(c.guard, renaming) : null,
                            body: applyParameterRenaming(c.body, renaming)
                        })
                    ),
                    ast.metadata, ast.pos
                );
            
            // For other node types, return as-is (can be extended as needed)
            default:
                ast;
        }
    }
    
    /**
     * Convert variable name to Elixir convention
     * Preserves special Elixir constants like __MODULE__, __FILE__, __ENV__
     */
    /**
     * Check if a variable name looks like a camelCase parameter
     * These are typically function parameters that should remain as-is
     */
    static function isCamelCaseParameter(name: String): Bool {
        if (name.length < 2) return false;
        
        // Check if it starts with lowercase and has uppercase letters
        var firstChar = name.charAt(0);
        if (firstChar != firstChar.toLowerCase()) return false;
        
        // Check if it contains uppercase letters (indicating camelCase)
        for (i in 1...name.length) {
            var char = name.charAt(i);
            if (char == char.toUpperCase() && char != "_" && char != char.toLowerCase()) {
                return true; // Found uppercase letter, it's camelCase
            }
        }
        
        return false;
    }
    

    /**
     * Checks if a variable name is a Haxe compiler-generated temporary variable.
     * 
     * WHY THESE 'G' VARIABLES EXIST:
     * --------------------------------
     * These are NOT created by Reflaxe.Elixir - they're generated by Haxe itself during compilation.
     * When Haxe compiles certain expressions (especially switch expressions that return values),
     * it creates temporary variables to ensure proper evaluation order and prevent side effects.
     * 
     * PATTERN EXPLANATION:
     * - 'g' or '_g': First temporary in a scope
     * - 'g1', 'g2', etc.: Additional temporaries when multiple are needed
     * - '_g1', '_g2': Underscore variants (sometimes for unused values)
     * 
     * EXAMPLE TRANSFORMATION:
     * ```haxe
     * // Original Haxe code:
     * var result = switch(parseMessage(msg)) {
     *     case Some(x): processMessage(x);
     *     case None: defaultValue;
     * }
     * 
     * // Haxe internally transforms to:
     * var _g = parseMessage(msg);  // Temporary to hold switch target
     * var result = switch(_g) {
     *     case Some(x): processMessage(x);
     *     case None: defaultValue;
     * }
     * ```
     * 
     * WHY NOT RENAME THEM:
     * 1. Risk of name collisions with user variables
     * 2. Other Haxe compilation passes expect these names
     * 3. They're recognizable to Haxe developers as compiler-generated
     * 4. They have no semantic meaning - purely mechanical temporaries
     * 
     * @param name The variable name to check
     * @return True if this is a Haxe-generated temporary variable
     */
    public static function isTempPatternVarName(name: String): Bool {
        if (name == null || name.length == 0) {
            return false;
        }

        function isDigits(str: String): Bool {
            if (str == null || str.length == 0) {
                return false;
            }
            for (i in 0...str.length) {
                var c = str.charAt(i);
                if (c < '0' || c > '9') {
                    return false;
                }
            }
            return true;
        }

        function check(candidate: String): Bool {
            if (candidate == null || candidate.length == 0) {
                return false;
            }
            // Standard Haxe temporary variable patterns
            if (candidate == "g" || candidate == "_g") {
                return true;
            }
            // Numbered variants: g1, g2, g3...
            if (candidate.length > 1 && candidate.charAt(0) == "g" && isDigits(candidate.substr(1))) {
                return true;
            }
            // Underscore numbered variants: _g1, _g2, _g3...
            if (candidate.length > 2 && candidate.charAt(0) == "_" && candidate.charAt(1) == "g" && isDigits(candidate.substr(2))) {
                return true;
            }
            return false;
        }

        if (check(name)) {
            return true;
        }

        var canonical = ElixirNaming.toVarName(name);
        if (canonical != name && check(canonical)) {
            return true;
        }

        return false;
    }
    
    /**
     * Extract field name from FieldAccess
     */
    public static function extractFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                cf.get().name;
            case FDynamic(s):
                s;
            case FEnum(_, ef):
                ef.name;
        }
    }
    
    /**
     * Create variable mappings for alpha-renaming in case clauses
     *
     * WHY: Haxe's optimizer creates temporary variables (g, g1, etc.) for enum parameters
     *      but our patterns use canonical names (value, error, etc.). We need to map
     *      the temp var IDs to the canonical names for proper code generation.
     *
     * WHAT: Creates a Map<Int, String> that maps TVar.id to the canonical pattern name
     *
     * HOW: Analyzes the case body to find TVar declarations that extract enum parameters
     *      and builds a mapping from the temp var IDs to the canonical names from the pattern
     *
     * M0.2: Now uses EnumBindingPlan as the authoritative source for variable names
     */
    static function createVariableMappingsForCase(caseExpr: TypedExpr, extractedParams: Array<String>,
                                                   enumType: Null<EnumType>, values: Array<TypedExpr>,
                                                   enumBindingPlan: Map<Int, {finalName: String, isUsed: Bool}> = null): Map<Int, String> {
        var mapping = new Map<Int, String>();
        
        #if debug_ast_pipeline
        #if debug_ast_builder
        trace('[createVariableMappingsForCase] Called with extractedParams: $extractedParams, enumType: ${enumType != null ? enumType.name : "null"}');
        #end
        #end
        
        // For non-enum cases, still need to track variable mappings for abstract types
        // This ensures abstract type methods use the correct renamed variables
        if (enumType == null) {
            // Scan for variable assignments that might be renamings
            // e.g., email = value (where value comes from a pattern)
            function scanForVariableAssignments(expr: TypedExpr): Void {
                switch(expr.expr) {
                    case TBlock(exprs):
                        for (e in exprs) scanForVariableAssignments(e);
                        
                    case TVar(v, init) if (init != null):
                        switch(init.expr) {
                            case TLocal(sourceVar):
                                // For non-enum cases (like array patterns), don't create mappings
                                // Array patterns like [x, y] need to preserve x = g, y = g1
                                // We DON'T want to map g to x, because then we get x = x
                                // Just let the natural variable names flow through
                                #if debug_ast_pipeline
                                #if debug_ast_builder
                                trace('[Alpha-renaming] Skipping mapping for non-enum TLocal: ${v.name} = ${sourceVar.name}');
                                #end
                                #end
                                
                            default:
                        }
                        
                    default:
                        haxe.macro.TypedExprTools.iter(expr, scanForVariableAssignments);
                }
            }
            
            scanForVariableAssignments(caseExpr);
            return mapping;
        }
        
        // For both regular and idiomatic enums, we need to map TEnumParameter extractions
        // The difference is how we determine the target names:
        // - Idiomatic enums: Use extractedParams (generic names like g, g1, g2)
        // - Regular enums: Use canonical names from enum definition (r, g, b)
        
        // Get the constructor for this case
        if (values.length > 0) {
            switch(values[0].expr) {
                case TConst(TInt(index)):
                    // Get constructor at this index
                    var constructors = [];
                    for (name in enumType.constructs.keys()) {
                        var constructor = enumType.constructs.get(name);
                        constructors[constructor.index] = constructor;
                    }
                    
                    if (index >= 0 && index < constructors.length && constructors[index] != null) {
                        var constructor = constructors[index];
                        
                        // Get the canonical parameter names from the constructor
                        var canonicalNames = switch(constructor.type) {
                            case TFun(args, _):
                                [for (arg in args) arg.name];
                            default:
                                [];
                        };
                        
                        // Track which variables come from enum extraction
                        var enumExtractionVars = new Map<Int, Bool>();
                        
                        // Now scan the case body to find TVar declarations
                        function scanForTVars(expr: TypedExpr): Void {
                            switch(expr.expr) {
                                case TBlock(exprs):
                                    for (e in exprs) scanForTVars(e);
                                    
                                case TVar(v, init) if (init != null):
                                    switch(init.expr) {
                                        case TEnumParameter(_, _, paramIndex):
                                            // M0.2 FIX: Use EnumBindingPlan as the single source of truth
                                            // The binding plan already decided the final name for this parameter

                                            var finalName: String;

                                            if (enumBindingPlan != null && enumBindingPlan.exists(paramIndex)) {
                                                // Use the authoritative name from EnumBindingPlan
                                                finalName = enumBindingPlan.get(paramIndex).finalName;

                                                #if debug_ast_pipeline
                                                #if debug_ast_builder
                                                trace('[M0.2] Using EnumBindingPlan name for param ${paramIndex}: ${finalName}');
                                                #end
                                                #end
                                            } else {
                                                // Fallback if no binding plan (shouldn't happen after M0.1)
                                                var varName = VariableAnalyzer.toElixirVarName(v.name);
                                                if (varName.startsWith("_g")) {
                                                    varName = varName.substr(1); // _g -> g
                                                }
                                                finalName = varName;

                                                #if debug_ast_pipeline
                                                #if debug_ast_builder
                                                trace('[M0.2 WARNING] No EnumBindingPlan for param ${paramIndex}, using fallback: ${finalName}');
                                                #end
                                                #end
                                            }

                                            // Map this variable ID to the binding plan's final name
                                            mapping.set(v.id, finalName);

                                            // Mark this variable as coming from enum extraction
                                            enumExtractionVars.set(v.id, true);

                                            #if debug_ast_pipeline
                                            #if debug_ast_builder
                                            trace('[M0.2] Mapping TEnumParameter temp var ${v.name} (id=${v.id}) to binding plan name: ${finalName}');
                                            #end
                                            #end
                                            
                                        case TLocal(tempVar):
                                            // This is assignment from temp var to pattern var
                                            var tempVarName = VariableAnalyzer.toElixirVarName(tempVar.name);
                                            var patternVarName = VariableAnalyzer.toElixirVarName(v.name);
                                            
                                            // Check if the temp var is from enum extraction
                                            // ONLY apply special mapping for enum-related temp vars
                                            if (enumExtractionVars.exists(tempVar.id)) {
                                                // This IS an enum extraction temp var (like g from TEnumParameter)
                                                // The pattern variable should use its own name (data = g, then use 'data')
                                                mapping.set(v.id, patternVarName);
                                                
                                                #if debug_ast_pipeline
                                                #if debug_ast_builder
                                                trace('[Alpha-renaming] Enum pattern var assignment: ${patternVarName} = ${tempVarName}, mapping ${v.id} -> ${patternVarName}');
                                                #end
                                                #end
                                            } else if (mapping.exists(tempVar.id)) {
                                                // For other assignments, propagate the mapping
                                                var canonicalName = mapping.get(tempVar.id);
                                                mapping.set(v.id, canonicalName);
                                                
                                                // Also register in pattern registry if tempVar is registered
                                                if (currentContext.patternVariableRegistry.exists(tempVar.id)) {
                                                    currentContext.patternVariableRegistry.set(v.id, canonicalName);
                                                    #if debug_ast_pipeline
                                                    #if debug_ast_builder
                                                    trace('[Pattern Registry] Propagating pattern name to ${v.name} (id=${v.id}) -> ${canonicalName}');
                                                    #end
                                                    #end
                                                }
                                                
                                                #if debug_ast_pipeline
                                                #if debug_ast_builder
                                                trace('[Alpha-renaming] Mapping TVar ${v.name} (id=${v.id}) from temp ${tempVar.name} to: ${canonicalName}');
                                                #end
                                                #end
                                            } else {
                                                // No existing mapping - DON'T create one for non-enum cases
                                                // Array patterns should use their natural names
                                                // We don't need to map x to anything - it should use its own name
                                                #if debug_ast_pipeline
                                                #if debug_ast_builder
                                                trace('[Alpha-renaming] No mapping needed for TVar ${v.name} from ${tempVar.name}');
                                                #end
                                                #end
                                            }
                                            
                                        default:
                                    }
                                    
                                default:
                                    haxe.macro.TypedExprTools.iter(expr, scanForTVars);
                            }
                        }
                        
                        scanForTVars(caseExpr);
                    }
                    
                default:
            }
        }
        
        return mapping;
    }
    
    /**
     * Convert camelCase to snake_case
     */
    
    /**
     * Collect template content from HXX.hxx() argument
     * 
     * WHY: HXX.hxx() calls with string interpolation (${expr}) get compiled to
     *      string concatenation operations by Haxe. We need to collect all the
     *      pieces to build the complete template for the ~H sigil.
     * 
     * WHAT: Recursively collects and concatenates all string pieces from both
     *       simple strings and binary concatenation operations.
     * 
     * HOW: Handles EString directly and recursively processes EBinary(StringConcat)
     *      to collect all concatenated parts into a single template string.
     * 
     * Example: HXX.hxx('Hello ${name}') becomes concatenation that we collect into one template
     */
    static function collectTemplateContent(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): 
                // Simple string - return as-is
                s;
                
            case EBinary(StringConcat, left, right):
                // String concatenation - collect both sides
                collectTemplateContent(left) + collectTemplateContent(right);
                
            case EVar(name):
                // Variable reference - convert to EEx interpolation
                '<%= ' + name + ' %>';
                
            case ECall(module, func, args):
                // Function call - convert to EEx interpolation
                var callStr = if (module != null) {
                    switch(module.def) {
                        case EVar(m): m + "." + func;
                        default: func;
                    }
                } else {
                    func;
                }
                
                // Build the function call with arguments
                if (args.length > 0) {
                    var argStrs = [];
                    for (arg in args) {
                        argStrs.push(collectTemplateArgument(arg));
                    }
                    callStr += "(" + argStrs.join(", ") + ")";
                } else {
                    callStr += "()";
                }
                '<%= ' + callStr + ' %>';
                
            default:
                // For other expressions, try to convert to a string representation
                // This is a fallback - ideally all cases should be handled explicitly
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Unhandled AST type in template collection: ${ast.def}');
                #end
                #end
                '<%= [unhandled expression] %>';
        }
    }
    
    /**
     * Collect template argument for function calls within templates
     */
    static function collectTemplateArgument(ast: ElixirAST): String {
        return switch(ast.def) {
            case EString(s): '"' + s + '"';
            case EVar(name): name;
            case EAtom(a): ":" + a;
            case EInteger(i): Std.string(i);
            case EFloat(f): Std.string(f);
            case EBoolean(b): b ? "true" : "false";
            case ENil: "nil";
            case EField(obj, field):
                switch(obj.def) {
                    case EVar(v): v + "." + field;
                    default: "[complex]." + field;
                }
            default: "[complex arg]";
        }
    }
    
    /**
     * Check if expression is the HXX module (for Phoenix HEEx template processing)
     * 
     * WHY: HXX.hxx() is a compile-time macro that processes JSX-like template strings
     *      and converts them to Phoenix HEEx format. After macro expansion, we get a 
     *      processed string that needs to be wrapped in a ~H sigil for LiveView.
     * 
     * WHAT: Detects when a TTypeExpr refers to the HXX module class, which indicates
     *       we're about to handle an HXX.hxx() template call that needs special treatment.
     * 
     * HOW: Checks if the module type expression resolves to "HXX" by name.
     * 
     * Example: HXX.hxx("<div>Hello <%= @name %></div>") → ~H"""<div>Hello <%= @name %></div>"""
     */
    static function isHXXModule(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(m):
                // Check if this is the HXX module
                var moduleName = moduleTypeToString(m);
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                #if debug_ast_builder
                trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
                #end
                #end
                false;
        }
    }
    
    /**
     * Check if expression is the Assert class (for ExUnit assertions)
     */
    static function isAssertClass(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(TClassDecl(classRef)):
                // Check if this is haxe.test.Assert
                var classType = classRef.get();
                var pack = classType.pack.join(".");
                var name = classType.name;
                pack == "haxe.test" && name == "Assert";
            default: false;
        }
    }
    
    /**
     * Check if expression is a module call
     */
    static function isModuleCall(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TTypeExpr(_): true;
            default: false;
        }
    }
    
    /**
     * Check if type represents a map/struct
     */
    static function isMapAccess(t: Type): Bool {
        return switch(t) {
            case TAnonymous(_): true;
            case TInst(_.get() => ct, _): ct.isInterface || ct.name.endsWith("Map");
            default: false;
        }
    }

    /**
     * If a type is an extern Elixir class with @:native, return its module name.
     */
    static function getExternNativeModuleNameFromType(t: Type): Null<String> {
        return switch(t) {
            case TInst(cRef, _):
                var c = cRef.get();
                if (c.isExtern && c.meta.has(":native")) {
                    var meta = c.meta.extract(":native");
                    if (meta.length > 0 && meta[0].params != null && meta[0].params.length > 0) {
                        switch(meta[0].params[0].expr) {
                            case EConst(CString(s, _)):
                                s;
                            default:
                                null;
                        }
                    } else null;
                } else null;
            case _:
                null;
        }
    }
    
    /**
     * Convert module type to string
     * Handles package-based module naming (e.g., ecto.Query → Query for non-externs, Ecto.Query for externs)
     */
    static function moduleTypeToString(m: ModuleType): String {
        // Get the basic name first
        var name = switch(m) {
            case TClassDecl(c): c.get().name;
            case TEnumDecl(e): e.get().name;
            case TTypeDecl(t): t.get().name;
            case TAbstract(a): a.get().name;
        }
        
        // Check if this is an extern class - only externs should get package prefixes
        var isExtern = switch(m) {
            case TClassDecl(c): c.get().isExtern;
            default: false;
        };
        
        // Get the package information
        var pack = switch(m) {
            case TClassDecl(c): c.get().pack;
            case TEnumDecl(e): e.get().pack;
            case TTypeDecl(t): t.get().pack;
            case TAbstract(a): a.get().pack;
        }
        
        // Special handling for framework packages that should use proper Elixir module names
        if (pack.length > 0) {
            // Don't add package prefix for implementation classes (_Impl_)
            // These are compiler-generated and should not have the package prefix
            if (name.endsWith("_Impl_") || name.contains("_Impl_")) {
                return name;  // Return just the name without package prefix
            }
            
            // For non-extern classes (like ecto.Query wrapper), just return the name
            // This allows our Query wrapper to be called as Query.from() not Ecto.Query.from()
            if (!isExtern) {
                return name;
            }
            
            // For extern classes, add the package prefix for proper Elixir module references
            switch(pack[0]) {
                case "ecto":
                    // Extern ecto modules should become Ecto.Module
                    return "Ecto." + name;
                case "phoenix":
                    // Extern phoenix modules should become Phoenix.Module
                    return "Phoenix." + name;
                case "plug":
                    // Extern plug modules should become Plug.Module
                    return "Plug." + name;
                default:
                    // Other packages keep their structure
            }
        }
        
        return name;
    }

    /**
     * Count occurrences of a variable name in an ElixirAST tree.
     */
    static function countVarOccurrencesInAST(ast: ElixirAST, name: String): Int {
        var count = 0;
        var _ = reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case EVar(v) if (v == name):
                    count++;
                    return node;
                default:
                    return node;
            }
        });
        return count;
    }

    /**
     * Replace all occurrences of a variable name with a replacement AST (wrapped in parentheses).
     */
    static function replaceVarInAST(ast: ElixirAST, name: String, replacement: ElixirAST): ElixirAST {
        return reflaxe.elixir.ast.ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case EVar(v) if (v == name):
                    return makeAST(EParen(replacement));
                default:
                    return node;
            }
        });
    }
    
    /**
     * Convert Haxe type to Elixir type string
     */
    static function typeToElixir(t: Type): String {
        if (t == null) return "any"; // Handle null types gracefully
        return switch(t) {
            case TInst(_.get() => {name: "String"}, _): "binary";
            case TInst(_.get() => {name: "Array"}, _): "list";
            case TAbstract(_.get() => {name: "Int"}, _): "integer";
            case TAbstract(_.get() => {name: "Float"}, _): "float";
            case TAbstract(_.get() => {name: "Bool"}, _): "boolean";
            case TDynamic(_): "any";
            default: "term";
        }
    }
    
    /**
     * Check if expression is pure (no side effects)
     */
    static function isPure(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_) | TLocal(_) | TTypeExpr(_): true;
            case TBinop(_, e1, e2): isPure(e1) && isPure(e2);
            case TUnop(_, _, e): isPure(e);
            case TField(e, _): isPure(e);
            case TParenthesis(e): isPure(e);
            default: false;
        }
    }
    
    /**
     * Check if expression can be inlined
     */
    static function canBeInlined(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_) | TLocal(_): true;
            case TBinop(_, e1, e2): canBeInlined(e1) && canBeInlined(e2);
            case TUnop(_, _, e): canBeInlined(e);
            default: false;
        }
    }
    
    /**
     * Check if expression is constant
     */
    static function isConstant(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TConst(_): true;
            default: false;
        }
    }
    
    /**
     * Check if expression has side effects
     */
    static function hasSideEffects(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TCall(_, _) | TNew(_, _, _) | TVar(_, _): true;
            case TBinop(OpAssign | OpAssignOp(_), _, _): true;
            case TUnop(OpIncrement | OpDecrement, _, _): true;
            case TThrow(_): true;
            default: false;
        }
    }
    
    /**
     * Check if an initialization expression is simple enough for VariableBuilder
     * 
     * WHY: Complex initializations (blocks, comprehensions) need special handling
     * WHAT: Identifies simple init patterns that VariableBuilder can handle
     * HOW: Checks expression type against simple patterns
     */
    static function isSimpleInit(init: TypedExpr): Bool {
        if (init == null) return true;
        
        return switch(init.expr) {
            case TConst(_): true;
            case TLocal(_): true;
            case TField(_, _): true;
            case TCall(_, _): true;
            case TNew(_, _, _): true;
            case TObjectDecl(_): true;
            case TArrayDecl(_): true;
            case TBinop(_, _, _): true;
            case TUnop(_, _, _): true;
            case TParenthesis(e): isSimpleInit(e);
            case TCast(e, _): isSimpleInit(e);
            case TMeta(_, e): isSimpleInit(e);
            // Complex patterns that need special handling
            case TBlock(_): false;
            case TIf(_, _, _): false;
            case TSwitch(_, _, _): false;
            case TWhile(_, _, _): false;
            case TFor(_, _, _): false;
            case TTry(_, _): false;
            case TFunction(_): false;
            default: true;
        };
    }
    
    /**
     * Check if a variable name is used within an ElixirAST
     * 
     * WHY: Need to detect unused variables in reduce_while patterns to prefix with underscore
     * WHAT: Recursively searches ElixirAST for EVar references to the given variable name
     * HOW: Pattern matches on all ElixirAST node types that can contain variables
     * 
     * @param varName The variable name to search for
     * @param ast The AST to search within
     * @return true if the variable is referenced, false otherwise
     */
    static function isVariableUsedInAST(varName: String, ast: ElixirAST): Bool {
        if (ast == null) return false;
        
        return switch(ast.def) {
            case EVar(name): name == varName;
            case EBlock(exprs): 
                for (e in exprs) {
                    if (isVariableUsedInAST(varName, e)) return true;
                }
                false;
            case EIf(cond, thenBranch, elseBranch):
                isVariableUsedInAST(varName, cond) || 
                isVariableUsedInAST(varName, thenBranch) || 
                (elseBranch != null && isVariableUsedInAST(varName, elseBranch));
            case ETuple(values):
                for (v in values) {
                    if (isVariableUsedInAST(varName, v)) return true;
                }
                false;
            case EList(values):
                for (v in values) {
                    if (isVariableUsedInAST(varName, v)) return true;
                }
                false;
            case EBinary(_, left, right):
                isVariableUsedInAST(varName, left) || isVariableUsedInAST(varName, right);
            case ECall(target, funcName, args):
                if (target != null && isVariableUsedInAST(varName, target)) return true;
                for (a in args) {
                    if (isVariableUsedInAST(varName, a)) return true;
                }
                false;
            case ERemoteCall(module, func, args):
                if (isVariableUsedInAST(varName, module)) return true;
                for (a in args) {
                    if (isVariableUsedInAST(varName, a)) return true;
                }
                false;
            case EFn(clauses):
                for (c in clauses) {
                    if (isVariableUsedInAST(varName, c.body)) return true;
                    if (c.guard != null && isVariableUsedInAST(varName, c.guard)) return true;
                }
                false;
            case ECase(expr, clauses):
                if (isVariableUsedInAST(varName, expr)) return true;
                for (c in clauses) {
                    if (isVariableUsedInAST(varName, c.body)) return true;
                    if (c.guard != null && isVariableUsedInAST(varName, c.guard)) return true;
                }
                false;
            case EAssign(name):
                name == varName;
            case _: false; // Other node types don't contain variable references
        };
    }
    
    /**
     * Detect array operation pattern in while loop body
     * 
     * WHY: Haxe desugars array operations (map/filter) into imperative while loops
     * that manually build arrays with push operations. We need to detect these
     * patterns to generate idiomatic Elixir Enum calls instead of Y-combinator loops.
     * 
     * WHAT: Analyzes the loop body to determine if it's a map, filter, or other
     * array transformation operation.
     * 
     * HOW: Looks for characteristic patterns like:
     * - var v = array[index]; index++; result.push(transform(v)) -> map
     * - var v = array[index]; index++; if(condition) result.push(v) -> filter
     * 
     * @return The type of array operation detected, or null if not an array pattern
     */
    // detectArrayOperationPattern deleted - now delegated to LoopOptimizer
    
    /**
     * Generate idiomatic Enum call for array operation
     * 
     * WHY: Instead of generating Y-combinator recursive functions for array operations,
     * we want to generate clean, idiomatic Elixir Enum.map/filter/reduce calls.
     * 
     * WHAT: Transforms the detected array pattern into the appropriate Enum call.
     * 
     * HOW: Extracts the transformation/filter function from the loop body and
     * generates the corresponding Enum call with a lambda function.
     * 
     * @param arrayRef The array being iterated over (_g2 in the pattern)
     * @param operation The type of operation ("map", "filter", etc.)
     * @param body The loop body containing the transformation logic
     * @return ElixirASTDef for the Enum call
     */
    // TODO: Future version - Use ElixirAST directly to build Enum calls instead of string manipulation
    // This would allow us to properly construct ERemoteCall(EAtom(ElixirAtom.raw("Enum")), "map", [array, lambda])
    // with proper EFn nodes for the lambda functions, giving us better control over the output
    static function generateIdiomaticEnumCall(arrayRef: TypedExpr, operation: String, body: TypedExpr): ElixirASTDef {
        // Extract the actual array from the reference
        // arrayRef is the _g2 variable that holds the array
        var arrayAST = buildFromTypedExpr(arrayRef, currentContext);
        
        // Extract the transformation from the loop body
        var lambdaBody: ElixirAST = null;
        var itemVar = "v"; // Default lambda parameter name
        
        // Analyze the body to extract the transformation
        switch(body.expr) {
            case TBlock(exprs):
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(tvar, _):
                            // Found the loop variable (e.g., var v = _g2[_g1])
                            itemVar = tvar.name;
                            
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, [arg]) if (cf.get().name == "push"):
                            // Found the push operation - extract what's being pushed
                            lambdaBody = buildFromTypedExpr(arg, currentContext);
                            
                        case TIf(cond, thenExpr, _) if (operation == "filter"):
                            // For filter, extract the condition
                            lambdaBody = buildFromTypedExpr(cond, currentContext);
                            
                        case _:
                    }
                }
                
            case _:
        }
        
        // If we couldn't extract a proper transformation, fall back to identity
        if (lambdaBody == null) {
            lambdaBody = makeAST(EVar(itemVar));
        }
        
        // Create the lambda function
        var lambda = makeAST(EFn([{
            args: [PVar(itemVar)],
            guard: null,
            body: lambdaBody
        }]));
        
        // Generate the appropriate Enum call
        switch(operation) {
            case "map":
                return ERemoteCall(
                    makeAST(EAtom(ElixirAtom.raw("Enum"))),
                    "map",
                    [arrayAST, lambda]
                );
                
            case "filter":
                return ERemoteCall(
                    makeAST(EAtom(ElixirAtom.raw("Enum"))),
                    "filter",
                    [arrayAST, lambda]
                );
                
            default:
                // Fallback to map if operation is unknown
                return ERemoteCall(
                    makeAST(EAtom(ElixirAtom.raw("Enum"))),
                    "map",
                    [arrayAST, lambda]
                );
        }
    }
    
    /**
     * Check if an array of AST nodes uses a specific variable
     */
    
    // transformVariableReferences deleted - now delegated to LoopOptimizer
    
    // checkForEarlyReturns, transformReturnsToHalts, wrapWithHaltIfNeeded deleted - now delegated to LoopOptimizer
    
    /**
     * Recursively unwrap TMeta and TParenthesis wrappers from a TypedExpr
     * 
     * WHY: Haxe may add metadata annotations and parenthesis wrappers during compilation
     * WHAT: Strips these wrappers to access the actual expression for pattern matching
     * HOW: Recursively unwraps until finding a non-wrapper expression type
     */
    static function unwrapMetaParens(e: TypedExpr): TypedExpr {
        if (e == null) return null;
        
        return switch(e.expr) {
            case TMeta(_, expr):
                // Strip metadata wrapper and continue unwrapping
                unwrapMetaParens(expr);
            case TParenthesis(expr):
                // Strip parenthesis wrapper and continue unwrapping
                unwrapMetaParens(expr);
            case _:
                // Not a wrapper, return as-is
                e;
        };
    }
    
    
    static function tryBuildMapLiteralFromBlock(blockStmts: Array<TypedExpr>, context: CompilationContext): Null<ElixirAST> {
        if (blockStmts == null || blockStmts.length < 3) {
            return null;
        }

        var tempVar: TVar = null;
        var tempInit: TypedExpr = null;

        switch(blockStmts[0].expr) {
            case TVar(tv, init) if (init != null):
                tempVar = tv;
                tempInit = init;
            default:
                return null;
        }

        if (tempVar == null || tempInit == null) {
            return null;
        }

        var isMapCtor = switch(tempInit.expr) {
            case TNew(c, _, _):
                var className = c.get().name;
                className == "StringMap" || className == "Map" || className.endsWith("Map");
            default:
                false;
        };

        if (!isMapCtor) {
            return null;
        }

        var tempName = tempVar.name;
        var pairs: Array<EMapPair> = [];

        for (i in 1...blockStmts.length - 1) {
            var stmt = blockStmts[i];
            switch(stmt.expr) {
                case TCall({expr: TField({expr: TLocal(local)}, FInstance(_, _, cf))}, callArgs):
                    if (local.name != tempName || cf.get().name != "set" || callArgs.length != 2) {
                        return null;
                    }

                    var keyAst = buildFromTypedExpr(callArgs[0], context);
                    var valueAst = buildFromTypedExpr(callArgs[1], context);
                    pairs.push({key: keyAst, value: valueAst});
                default:
                    return null;
            }
        }

        switch(blockStmts[blockStmts.length - 1].expr) {
            case TLocal(retVar) if (retVar.name == tempName):
                return makeAST(EMap(pairs));
            default:
                return null;
        }
    }
    

    /**
     * Check if a pattern variable is actually used in the case body
     *
     * WHY: Unused pattern variables should become wildcards or have underscore prefix
     * WHAT: Checks if a given variable name appears as used in the usage map
     * HOW: Enhanced with alias awareness - tracks temp variables (g, g1) that represent
     *      pattern variables, since Haxe's optimizer may replace direct references with temps
     *
     * ALIAS TRACKING:
     * - First pass: Build alias sets by finding TEnumParameter extractions and assignments
     * - Second pass: Check if any alias of the pattern variable is used

    /**
     * Check if a case body is effectively empty (only nil or no-op)
     */
    static function isEmptyCaseBody(body: ElixirAST): Bool {
        return PatternBuilder.isEmptyCaseBody(body);
    }
    
    /**
     * Compute a structural pattern key for guard grouping
     * 
     * WHY: Multiple cases with the same pattern but different guards need to be grouped into cond
     * WHAT: Creates a unique key based on the pattern structure (not values or names)
     * HOW: Recursively traverses pattern structure and builds a string key
     * 
     * Examples:
     * - PTuple([PAtom(":rgb"), PVar(_), PVar(_), PVar(_)]) → "tuple:rgb:3"
     * - PTuple([PAtom(":ok"), PVar(_)]) → "tuple:ok:1"
     * - PVar(_) → "var"
     */
    static function computePatternKey(pattern: EPattern): String {
        return PatternBuilder.computePatternKey(pattern);
    }
    
    /**
     * Extract all bound variable names from a pattern
     * 
     * WHY: Variables bound in patterns need to be accessible in guard conditions and body
     * WHAT: Collects all PVar names (except wildcards) from the pattern
     * HOW: Recursively traverses pattern structure collecting variable names
     */
    static function extractBoundVariables(pattern: EPattern): Array<String> {
        return PatternBuilder.extractBoundVariables(pattern);
    }
    
    // collectBoundVarsHelper has been moved to PatternBuilder
    
    /**
     * EXPRESSION PRESERVATION: Captures the textual representation of an expression
     * 
     * WHY: When Haxe evaluates expressions at compile-time (e.g., i * 2 + 1 becomes 1, 3, 5),
     *      we lose the original expression structure. By preserving the text representation,
     *      we can reconstruct idiomatic Elixir code in the transformer phase.
     * 
     * WHAT: Extracts a simplified string representation of the expression that can be
     *       reconstructed with proper variable substitution in generated Elixir code.
     * 
     * HOW: Analyzes the TypedExpr structure and builds a string representation,
     *      replacing loop variable references with placeholders for later substitution.
     * 
     * @param expr The expression to capture
     * @param loopVar The loop variable name to track in the expression
     * @return String representation of the expression, or null if too complex
     */
    // Loop helper functions moved to LoopBuilder.hx
    
    /**
     * Process a LoopIntent and generate corresponding ElixirAST
     * 
     * WHY: The LoopIntent pattern separates semantic intent from implementation.
     * This allows us to capture what the loop does before deciding how to
     * generate it, enabling better optimization and cleaner code generation.
     * 
     * WHAT: Transforms LoopIntent objects into idiomatic Elixir AST nodes,
     * handling variable preservation, accumulator initialization, and
     * infrastructure variable removal.
     * 
     * HOW: Pattern matches on LoopIntent variants and delegates to appropriate
     * generation logic, either using LoopBuilder for compatibility or
     * generating AST directly for simple cases.
     * 
     * @param intent The loop intent to process
     * @param metadata Additional metadata for the loop
     * @param context The current compilation context
     * @return The generated ElixirAST node
     */
    static function processLoopIntent(intent: LoopIntent, metadata: LoopIntentMetadata, context: CompilationContext): ElixirAST {
        // Delegate to LoopOptimizer
        return LoopOptimizer.processLoopIntent(intent, metadata, context);
    }
    
    /**
     * MAP ITERATION PATTERN DETECTION
     * 
     * WHY: Haxe desugars `for (key => value in map)` into complex TBlock+TWhile patterns
     *      with iterator method calls that don't exist in Elixir
     * 
     * WHAT: Detects the specific desugared pattern and extracts key/value variable names
     * 
     * HOW: Looks for:
     *      1. TVar with keyValueIterator() call  
     *      2. TWhile with hasNext() condition
     *      3. Body containing next() call with tuple destructuring
     * 
     * PATTERN:
     * ```
     * var iterator = map.keyValueIterator();
     * while (iterator.hasNext()) {
     *     var kv = iterator.next();
     *     var key = kv.key;
     *     var value = kv.value;
     *     // ... user code using key and value
     * }
     * ```
     */
    // detectMapIterationPattern deleted - now delegated to LoopOptimizer
    
    /**
     * BUILD MAP ITERATION AST
     * 
     * WHY: Generate idiomatic Elixir code for Map iteration instead of invalid iterator calls
     * 
     * WHAT: Transforms detected Map iteration pattern into Enum.each/map with tuple destructuring
     * 
     * HOW: Generates:
     *      - Enum.each for side effects only
     *      - Enum.map for collecting results
     *      - Proper tuple destructuring: fn {key, value} -> ... end
     */
    static function buildMapIteration(pattern: MapIterationPattern, context: CompilationContext): ElixirAST {
        var mapAst = buildFromTypedExpr(pattern.mapExpr, context);
        var bodyAst = buildFromTypedExpr(pattern.body, context);
        
        // Analyze if body collects results
        var isCollecting = analyzesAsExpression(pattern.body);
        
        // Create pattern for destructuring: {key, value}
        var tuplePattern = PTuple([
            PVar(VariableAnalyzer.toElixirVarName(pattern.keyVar)),
            PVar(VariableAnalyzer.toElixirVarName(pattern.valueVar))
        ]);
        
        // Create anonymous function clause
        var fnClause: EFnClause = {
            args: [tuplePattern],
            body: bodyAst
        };
        
        // Choose between Enum.each and Enum.map based on usage
        var enumFunction = isCollecting ? "map" : "each";
        
        return makeAST(ECall(
            makeAST(EVar("Enum")),
            enumFunction,
            [mapAst, makeAST(EFn([fnClause]))]
        ));
    }
    
    /**
     * Simple analysis to determine if expression returns a value
     */
    static function analyzesAsExpression(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TBlock(stmts):
                if (stmts.length > 0) {
                    analyzesAsExpression(stmts[stmts.length - 1]);
                } else {
                    false;
                }
            case TReturn(_): true;
            case TIf(_, _, elseExpr) if (elseExpr != null): true;
            case TSwitch(_, _, _): true;
            case TCall(_, _): true;
            case TBinop(_, _, _): true;
            case TLocal(_): true;
            case TConst(_): true;
            default: false;
        };
    }
}

// Type definition for Map iteration pattern
typedef MapIterationPattern = {
    mapExpr: TypedExpr,
    keyVar: String,
    valueVar: String,
    body: TypedExpr
}

#end
