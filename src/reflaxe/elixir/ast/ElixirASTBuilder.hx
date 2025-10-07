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
// Helper modules for extracted functions
import reflaxe.elixir.ast.ElixirASTHelpers;
import reflaxe.elixir.ast.TemplateHelpers;
import reflaxe.elixir.ast.LoopHelpers;
import reflaxe.elixir.ast.intent.LoopIntent;
import reflaxe.elixir.ast.intent.LoopIntent.*;  // Import all enum constructors
import reflaxe.elixir.ast.transformers.DesugarredForDetector;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.preprocessor.TypedExprPreprocessor;
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
    // Delegate to SubstitutionHelpers
    static inline function replaceNullCoalVar(expr: TypedExpr, varId: Int, initExpr: TypedExpr): TypedExpr {
        return SubstitutionHelpers.replaceNullCoalVar(expr, varId, initExpr);
    }
    
    /**
     * Substitute all occurrences of a variable with another expression.
     * Used for eliminating infrastructure variables by replacing them with their init expressions.
     */
    // Delegate to SubstitutionHelpers
    static inline function substituteVariable(expr: TypedExpr, varToReplace: TVar, replacement: TypedExpr): TypedExpr {
        return SubstitutionHelpers.substituteVariable(expr, varToReplace, replacement);
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

        #if debug_variable_renaming
        var entriesBeforeSet = Lambda.count(context.tempVarRenameMap);
        var prevEntries = if (previousContext != null) Lambda.count(previousContext.tempVarRenameMap) else 0;
        trace('[ElixirASTBuilder.buildFromTypedExprWithContext] About to set currentContext - incoming: $entriesBeforeSet entries, previous had: $prevEntries');
        #end

        // FIXED: Preserve tempVarRenameMap from previous context when nested calls occur
        // Nested buildFromTypedExpr calls were overwriting currentContext with contexts that had empty maps
        // This was losing the parameter registrations from buildClassAST
        if (previousContext != null && Lambda.count(context.tempVarRenameMap) == 0 && Lambda.count(previousContext.tempVarRenameMap) > 0) {
            #if debug_variable_renaming
            trace('[ElixirASTBuilder.buildFromTypedExprWithContext] PRESERVING ${Lambda.count(previousContext.tempVarRenameMap)} map entries from previous context');
            #end
            // Copy entries from previous context to preserve registrations
            for (key in previousContext.tempVarRenameMap.keys()) {
                context.tempVarRenameMap.set(key, previousContext.tempVarRenameMap.get(key));
            }
        }

        currentContext = context;

        #if debug_variable_renaming
        var entriesAfterSet = Lambda.count(currentContext.tempVarRenameMap);
        trace('[ElixirASTBuilder.buildFromTypedExprWithContext] Set currentContext - now has $entriesAfterSet map entries');
        #end

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

        #if debug_ast_builder
        // DEBUG: Trace TVar expressions at entry point
        var exprType = Type.enumConstructor(expr.expr);
        if (exprType == "TVar") {
            switch(expr.expr) {
                case TVar(tvar, init):
                    trace('[convertExpression ENTRY] 🔍 TVar detected: ${tvar.name}');
                    trace('[convertExpression ENTRY]   TVar init: ${init != null ? Type.enumConstructor(init.expr) : "null"}');
                default:
            }
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
                // CRITICAL FIX: TLocal must check context for renamed variables
                // This ensures references match declarations (e.g., _changeset references use _changeset)
                // Without this check, we get "undefined variable" errors when TVar adds underscore prefix
                // but TLocal uses the original name.

                // Dual-key lookup: Try ID first (pattern matching), then name (EVar reference)
                var idKey = Std.string(v.id);
                var nameKey = v.name;

                // PRIORITY 0: Check ClauseContext for case-local TLocal variables
                // WHY: Guard expressions use TLocal references that need consistent names with patterns
                // WHAT: ClauseContext.localToName maps TLocal IDs to canonical pattern variable names
                // HOW: SwitchBuilder registers mappings when extracting pattern variables
                var clauseMapping: Null<String> = null;
                if (currentContext.currentClauseContext != null) {
                    clauseMapping = currentContext.currentClauseContext.lookupVariable(v.id);
                    if (clauseMapping != null) {
                        #if debug_clause_context
                        trace('[TLocal ClauseContext] Found mapping for ${v.name} (id=${v.id}) -> $clauseMapping');
                        #end
                    }
                }

                var varName = if (clauseMapping != null) {
                    // Use ClauseContext mapping (highest priority)
                    clauseMapping;
                } else if (currentContext.tempVarRenameMap.exists(idKey)) {
                    // ID-based lookup succeeds (builder phase registered this variable)
                    var renamed = currentContext.tempVarRenameMap.get(idKey);
                    #if debug_hygiene
                    trace('[TLocal] Variable ${v.name} (id=${v.id}) found in context via ID: $renamed');
                    #end
                    renamed;
                } else if (currentContext.tempVarRenameMap.exists(nameKey)) {
                    // Name-based lookup succeeds (transformer phase or builder phase)
                    var renamed = currentContext.tempVarRenameMap.get(nameKey);
                    #if debug_hygiene
                    trace('[TLocal] Variable ${v.name} (id=${v.id}) found in context via NAME: $renamed');
                    #end
                    renamed;
                } else if (currentContext.isInConstructorArgContext) {
                    // Constructor argument context - strip Haxe's numeric shadowing suffix
                    // Pattern: replacer2 -> replacer, space3 -> space
                    var pattern = ~/^(.+?)(\d+)$/;
                    var baseName = if (pattern.match(v.name)) {
                        var base = pattern.matched(1);
                        var suffix = pattern.matched(2);
                        #if debug_constructor_args
                        trace('[TLocal Constructor] Stripping shadow suffix: ${v.name} -> $base (removed: $suffix)');
                        #end
                        base;
                    } else {
                        v.name;
                    };
                    // Convert to Elixir variable name
                    VariableAnalyzer.toElixirVarName(baseName);
                } else {
                    // Not in context - use standard snake_case conversion
                    var converted = VariableAnalyzer.toElixirVarName(v.name);
                    #if debug_hygiene
                    trace('[TLocal] Variable ${v.name} (id=${v.id}) NOT in context, using converted: $converted');
                    #end
                    converted;
                };

                EVar(varName);
                
            case TVar(v, init):
                #if debug_ast_builder
                // DEBUG: Track what TVar compilation returns for infrastructure variables
                trace('[DEBUG TVar] Compiling TVar: ${v.name}');
                if (v.name.indexOf("g") >= 0 || v.name.indexOf("_") >= 0) {
                    trace('[DEBUG TVar]   Name contains g or underscore: ${v.name}');
                    trace('[DEBUG TVar]   Init type: ${init != null ? Type.enumConstructor(init.expr) : "null"}');
                    trace('[DEBUG TVar]   Is simple init: ${init == null || isSimpleInit(init)}');
                }
                #end

                // CRITICAL FIX: Skip TVar generation for pattern-bound variables BEFORE delegation
                // When a variable is already bound by the pattern (e.g., {:ok, value}),
                // generating "value = nil" is incorrect - the pattern already provides the value
                #if debug_ast_builder
                trace('[TVar CHECK] var=${v.name} id=${v.id} hasClauseContext=${currentContext.currentClauseContext != null}');
                if (currentContext.currentClauseContext != null) {
                    trace('[TVar CHECK]   localToName has ${v.id}? ${currentContext.currentClauseContext.localToName.exists(v.id)}');
                    trace('[TVar CHECK]   localToName size: ${Lambda.count(currentContext.currentClauseContext.localToName)}');
                }
                #end

                if (currentContext.currentClauseContext != null) {
                    #if sys
                    var debugFile4 = sys.io.File.append("/tmp/enum_debug.log");
                    debugFile4.writeString('[TVar CHECK] var=${v.name} id=${v.id}\n');
                    debugFile4.writeString('[TVar CHECK]   init: ${init != null ? Type.enumConstructor(init.expr) : "null"}\n');
                    debugFile4.writeString('[TVar CHECK]   localToName.exists(${v.id})?: ${currentContext.currentClauseContext.localToName.exists(v.id)}\n');
                    debugFile4.writeString('[TVar CHECK]   localToName keys: [${[for (k in currentContext.currentClauseContext.localToName.keys()) k].join(", ")}]\n');
                    debugFile4.close();
                    #end

                    // Check localToName mapping (pattern variable bindings)
                    // CRITICAL: Check by ID first (exact match)
                    if (currentContext.currentClauseContext.localToName.exists(v.id)) {
                        #if sys
                        var debugFile5 = sys.io.File.append("/tmp/enum_debug.log");
                        debugFile5.writeString('[TVar] ✅ SKIPPING (by ID): Variable ${v.name} (id=${v.id}) already bound by pattern\n');
                        debugFile5.close();
                        #end
                        // Return null to skip this TVar - the pattern already bound the variable
                        return null;
                    }

                    // CRITICAL FIX: Also check by NAME for cases where Haxe creates different IDs
                    // In empty case bodies, Haxe generates new TVars with different IDs but same names
                    var patternVarNames = [for (name in currentContext.currentClauseContext.localToName) name];
                    if (patternVarNames.contains(v.name)) {
                        #if sys
                        var debugFile6 = sys.io.File.append("/tmp/enum_debug.log");
                        debugFile6.writeString('[TVar] ✅ SKIPPING (by NAME): Variable ${v.name} (id=${v.id}) matches pattern variable\n');
                        debugFile6.close();
                        #end
                        // Return null to skip this TVar - the pattern already bound a variable with this name
                        return null;
                    }
                }

                // Skip assignments that simply rebind from infrastructure temps (e.g., x = _g)
                // When a case pattern has already extracted enum parameters, Haxe sometimes emits
                // TVar binders that copy from the temporary infrastructure variables created during
                // matching. These are redundant in Elixir and lead to orphaned assignments in empty
                // case bodies. Suppress them at the source.
                if (init != null) {
                    switch (init.expr) {
                        case TLocal(lv):
                            if (reflaxe.elixir.preprocessor.TypedExprPreprocessor.isInfrastructureVar(lv.name)) {
                                #if debug_enum_extraction
                                #if debug_ast_builder
                                trace('[TVar] Skipping redundant binder assignment from infrastructure var: ' + lv.name + ' -> ' + v.name);
                                #end
                                #end
                                return null;
                            }
                        case _:
                            // continue
                    }
                }

                // Delegate simple variable declarations to VariableBuilder
                // Complex patterns (blocks, comprehensions) are handled below
                if (init == null || isSimpleInit(init)) {
                    var result = VariableBuilder.buildVariableDeclaration(v, init, currentContext);

                    #if debug_ast_builder
                    if (v.name == "_g" || v.name == "g") {
                        trace('[DEBUG TVar]   VariableBuilder result: ${result != null ? Type.enumConstructor(result.def) : "null"}');
                    }
                    #end

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

                                    // FIXED: Don't skip the assignment! We need to generate the variable binding
                                    // The mapping is for pattern matching, but the variable still needs to exist
                                    // for the switch expression to reference it.
                                    // Fall through to let VariableBuilder generate: g = Map.get(msg, :type)
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
                // AND for unrolled comprehension pattern: var doubled = { doubled = n = 1; [] ++ [n*2]; ... }
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

                            // NEW: Check for unrolled array comprehension pattern FIRST
                            // Pattern: var doubled = { doubled = n = 1; [] ++ [expr]; n = 2; ...; [] }
                            #if debug_ast_builder
                            trace('[TVar COMPREHENSION CHECK] Checking if TBlock is unrolled comprehension');
                            trace('[TVar COMPREHENSION CHECK] Block has ${blockStmts.length} statements');
                            #end

                            var comprehensionAST = reflaxe.elixir.ast.builders.ComprehensionBuilder.tryBuildArrayComprehensionFromBlock(blockStmts, currentContext);
                            if (comprehensionAST != null) {
                                #if debug_ast_builder
                                trace('[TVar COMPREHENSION] ✅ Detected unrolled comprehension in TVar initialization!');
                                trace('[TVar COMPREHENSION] Variable: ${v.name}');
                                trace('[TVar COMPREHENSION] Converting to idiomatic Elixir comprehension');
                                #end
                                // Return assignment: doubled = for n <- [1,2,3], do: n * 2
                                var varName = VariableAnalyzer.toElixirVarName(v.name);
                                return EMatch(PVar(varName), comprehensionAST);
                            }

                            // FALLBACK: Check if this is a conditional comprehension pattern
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
                
                // ARCHITECTURAL FIX (January 2025): Remove premature underscore prefixing
                //
                // PROBLEM: The builder was making renaming decisions BEFORE usage analysis ran.
                // This caused:
                // 1. TVar registers "changeset -> _changeset" prematurely
                // 2. TLocal can't find "changeset" (stored as "_changeset")
                // 3. HygieneTransforms sees "_changeset" and marks IT as unused
                // 4. Result: "_changeset = user" then "changeset" (undefined variable!)
                //
                // SOLUTION: Builder phase should ONLY build AST nodes, NOT transform them.
                // Let HygieneTransforms (transformer phase) handle ALL renaming decisions.
                //
                // The builder's job: Convert TypedExpr → ElixirAST faithfully
                // The transformer's job: Analyze usage and apply underscore prefixes
                //
                // See: /docs/03-compiler-development/HYGIENE_TRANSFORM_TLOCAL_BUG.md

                var finalVarName = baseName;  // Just use the snake_case converted name

                #if debug_hygiene
                trace('[Hygiene] TVar built faithfully: id=${v.id} name=${v.name} -> $finalVarName (no premature underscore)');
                #end

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
                                    return null;  // ✅ FIX: Immediate return prevents fallthrough to error code
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

                    // Early-exit for enum parameter extractions bound by the case pattern.
                    // If the initializer resolves to a temporary/infrastructure variable (e.g. g, _g, g1),
                    // the value has already been introduced by the pattern in the case head. Emitting a
                    // follow-up assignment like "x = _g" is redundant and causes orphaned assignments in
                    // empty case bodies. Return null here to suppress the assignment; pattern binding owns it.
                    if (!shouldSkipAssignment && initValue != null) {
                        switch (initValue.def) {
                            case EVar(varName):
                                if (PatternDetector.isTempPatternVarName(varName)) {
                                    #if debug_enum_extraction
                                    #if debug_ast_builder
                                    trace('[TVar] Skipping redundant assignment from infrastructure var: ' + varName + ' -> ' + finalVarName);
                                    #end
                                    #end
                                    return null;
                                }
                            case _:
                                // proceed
                        }
                    }
                    var result = if (shouldSkipAssignment) {
                        // Skip the assignment, return null to be filtered out by TBlock
                        // The TBlock handler at line 3036 filters out null expressions
                        null;
                    } else if (initValue == null) {
                        // Do not fabricate placeholder values. If the initializer failed to build,
                        // return null so upstream builders/transformers can properly elide the
                        // redundant assignment (eg. pattern-bound params or empty bodies).
                        // Any truly unbuildable initializers should be surfaced by the
                        // originating builder path, not patched here.
                        return null;
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
                #if debug_ast_builder
                // DEBUG: Check if this block contains infrastructure variable + switch pattern
                if (el.length == 2) {
                    var hasVar = switch(el[0].expr) { case TVar(_,_): true; default: false; };
                    var hasSwitch = switch(el[1].expr) { case TSwitch(_,_,_): true; default: false; };
                    if (hasVar && hasSwitch) {
                        trace('[ElixirASTBuilder] TBlock with TVar + TSwitch detected!');
                        switch(el[0].expr) {
                            case TVar(tvar, init):
                                trace('[ElixirASTBuilder]   TVar name: ${tvar.name}');
                                trace('[ElixirASTBuilder]   TVar init: ${init != null ? Type.enumConstructor(init.expr) : "null"}');
                            default:
                        }
                        switch(el[1].expr) {
                            case TSwitch(target, _, _):
                                trace('[ElixirASTBuilder]   TSwitch target: ${Type.enumConstructor(target.expr)}');
                            default:
                        }
                    }
                }
                #end

                // Delegate to BlockBuilder for modular handling
                var result = BlockBuilder.build(el, currentContext);
                if (result != null) {
                    return result;
                }
                
                
                // If BlockBuilder fails, return an error placeholder
                trace('[ERROR] BlockBuilder returned null for TBlock - returning placeholder');
                return ERaw("# ERROR: BlockBuilder failed to compile block");
                
            case TReturn(e):
                // Delegate to ReturnBuilder for proper return handling
                var result = ReturnBuilder.build(e, currentContext);
                if (result != null) {
                    return result;
                }
                
                // If ReturnBuilder fails, return an error placeholder
                trace('[ERROR] ReturnBuilder returned null for TReturn - returning placeholder');
                return ERaw("# ERROR: ReturnBuilder failed to compile return statement");
                
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
                
                // FIXED: Don't reset tempVarRenameMap - preserve registrations from buildClassAST
                // ElixirCompiler.buildClassAST already registered parameter mappings in the context
                // Creating a new map here would lose those critical registrations
                // This was causing priority2 bug where registered "priority" mapping was lost

                #if debug_variable_renaming
                var existingEntries = Lambda.count(currentContext.tempVarRenameMap);
                var funcInfo = if (f.args.length > 0) {
                    'with ${f.args.length} args: ${f.args.map(a -> a.v.name).join(", ")}';
                } else {
                    'with no args';
                };
                trace('[ElixirASTBuilder TFunction] Processing function $funcInfo - map has $existingEntries entries');
                #end

                // Keep existing map with buildClassAST registrations instead of creating new one
                var oldTempVarRenameMap = currentContext.tempVarRenameMap;
                // NO RESET: Use the map as-is with all existing registrations
                
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
                        var commonFieldNames = ["options", "columns", "name", "value", "type", "data", "fields", "items", "priority"];
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
                    
                    // Register the mapping for TLocal references in the body with dual-key storage
                    if (!currentContext.tempVarRenameMap.exists(idKey)) {
                        // Dual-key storage: ID for pattern positions, name for EVar references
                        currentContext.tempVarRenameMap.set(idKey, finalName);           // ID-based (pattern matching)
                        currentContext.tempVarRenameMap.set(originalName, finalName);    // NAME-based (EVar renaming)

                        #if debug_hygiene
                        trace('[Hygiene] Dual-key registered (TFunction param): id=$idKey name=$originalName -> $finalName');
                        #end

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

                trace('[TFunction DEBUG] BEFORE body compilation: tempVarRenameMap has ${Lambda.count(currentContext.tempVarRenameMap)} entries');
                if (currentContext.tempVarRenameMap.keys().hasNext()) {
                    trace('[TFunction DEBUG] Map contents:');
                    for (k in currentContext.tempVarRenameMap.keys()) {
                        trace('[TFunction DEBUG]   "$k" -> "${currentContext.tempVarRenameMap.get(k)}"');
                    }
                }

                var body = buildFromTypedExpr(f.expr, currentContext);

                trace('[TFunction DEBUG] AFTER body compilation: tempVarRenameMap has ${Lambda.count(currentContext.tempVarRenameMap)} entries');
                
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
                
                
                // If ObjectBuilder fails, return an error placeholder
                trace('[ERROR] ObjectBuilder returned null for TObjectDecl - returning placeholder');
                return ERaw("# ERROR: ObjectBuilder failed to compile object declaration");
                
            // ================================================================
            case TNew(c, params, el):
                // Delegate to ConstructorBuilder for modular handling
                var result = reflaxe.elixir.ast.builders.ConstructorBuilder.build(c, params, el, currentContext);
                if (result != null) return result;
                
                
                // If ConstructorBuilder fails, return an error placeholder
                trace('[ERROR] ConstructorBuilder returned null for TNew - returning placeholder');
                return ERaw("# ERROR: ConstructorBuilder failed to compile constructor call");
                
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

                // TASK 4.5 FIX: Check if this parameter was already extracted by the pattern
                // If the enum field name is in patternExtractedParams, the pattern already bound it

                // DEBUG: Show what we're checking BEFORE the condition
                #if sys
                var debugFile = sys.io.File.append("/tmp/enum_debug.log");
                debugFile.writeString('[TEnumParameter] *** PRE-CHECK DEBUG ***\n');
                debugFile.writeString('[TEnumParameter]   ef.name: "${ef.name}"\n');
                debugFile.writeString('[TEnumParameter]   Has currentClauseContext: ${currentContext.currentClauseContext != null}\n');
                if (currentContext.currentClauseContext != null) {
                    debugFile.writeString('[TEnumParameter]   patternExtractedParams: [${currentContext.currentClauseContext.patternExtractedParams.join(", ")}]\n');
                    debugFile.writeString('[TEnumParameter]   Contains ef.name?: ${currentContext.currentClauseContext.patternExtractedParams.contains(ef.name)}\n');
                }
                debugFile.close();
                #end

                if (currentContext.currentClauseContext != null &&
                    currentContext.currentClauseContext.patternExtractedParams.contains(ef.name)) {

                    #if sys
                    var debugFile3 = sys.io.File.append("/tmp/enum_debug.log");
                    debugFile3.writeString('[TEnumParameter] ✅ CONDITION MATCHED: Parameter "${ef.name}" already extracted by pattern\n');
                    debugFile3.close();
                    #end

                    // The pattern already extracted this parameter
                    // Use the binding plan to find the actual variable name
                    if (currentContext.currentClauseContext.enumBindingPlan.exists(index)) {
                        var info = currentContext.currentClauseContext.enumBindingPlan.get(index);

                        trace('[TEnumParameter]   *** BINDING PLAN DATA ***');
                        trace('[TEnumParameter]     finalName: "${info.finalName}"');
                        trace('[TEnumParameter]     isUsed: ${info.isUsed}');
                        trace('[TEnumParameter]     charAt(0): "${info.finalName.charAt(0)}"');
                        trace('[TEnumParameter]     charAt(0) == "_": ${info.finalName.charAt(0) == "_"}');

                        // CRITICAL FIX: If parameter is unused (has underscore prefix), return null to skip TVar
                        // This prevents generating: x = _x (where _x is the unused pattern variable)
                        // Instead we skip the assignment entirely since the pattern already has _x
                        if (!info.isUsed || (info.finalName != null && info.finalName.charAt(0) == "_")) {
                            trace('[TEnumParameter]   *** RETURNING NULL - Parameter is UNUSED ***');
                            return null;
                        }

                        // Return the pattern-bound variable directly
                        return EVar(info.finalName);
                    } else {
                        // Fallback: use the enum field name as variable name
                        var varName = VariableAnalyzer.toElixirVarName(ef.name);

                        #if debug_enum_extraction
                        trace('[TEnumParameter]   No binding plan, using enum field name: $varName');
                        #end

                        return EVar(varName);
                    }
                }

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
                    if (sourceVarName != null && TypedExprPreprocessor.isInfrastructureVar(sourceVarName)) {
                        // We're trying to extract from an infrastructure var like 'g', '_g', 'g1', '_g1'
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
                    }

                    // CRITICAL FIX: If the pattern already extracted to a real variable name (not temp var),
                    // return null to skip the redundant TVar assignment entirely.
                    // Example: pattern {:ok, value} already binds 'value', so TVar(value, TEnumParameter(...))
                    // should be skipped - the value is already available from the pattern.
                    //
                    // This prevents generating:
                    //   {:ok, value} ->
                    //     value = value  # or value = nil
                    //
                    // When we should generate:
                    //   {:ok, value} ->
                    //     # value already available from pattern
                    //
                    // Check if the final name is NOT a temporary/infrastructure variable
                    var finalNameIsTemp = (info.finalName != null &&
                                          (info.finalName == "_" ||
                                           TypedExprPreprocessor.isInfrastructureVar(info.finalName)));

                    // ALWAYS skip TVar assignment for pattern-extracted variables
                    // Whether temp var (like "_g") or real var (like "value"),
                    // the pattern already extracted it - no assignment needed
                    #if debug_ast_builder
                    if (finalNameIsTemp) {
                        trace('[TEnumParameter] Temp/infrastructure var ${info.finalName}, returning null to skip TVar assignment');
                    } else {
                        trace('[TEnumParameter] Real variable ${info.finalName}, returning null - pattern already extracted');
                    }
                    #end
                    return null;
                } else {
                    #if debug_ast_builder
                    trace('[DEBUG EMBEDDED TEnumParameter] NO BINDING PLAN! ClauseContext: ${currentContext.currentClauseContext != null}, index: $index, sourceVarName: $sourceVarName');
                    #end

                    // CRITICAL FIX: When there's no binding plan and we're trying to extract from
                    // a temp var that doesn't exist (like 'g', '_g'), return null to skip the assignment
                    // This happens in embedded switches where the pattern uses the actual variable name
                    if (sourceVarName != null && TypedExprPreprocessor.isInfrastructureVar(sourceVarName)) {
                        #if debug_ast_builder
                        trace('[DEBUG EMBEDDED TEnumParameter] Skipping extraction from non-existent infrastructure var: $sourceVarName');
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
                
            case TMeta(_, e):
                // Metadata is compile-time only, transparent at runtime
                // Just process the inner expression
                convertExpression(e);

            case TParenthesis(e):
                // Parentheses are for grouping, just process inner expression
                // No EParens node in ElixirAST - Elixir handles precedence naturally
                convertExpression(e);

            case TCast(e, _):
                // Elixir has no explicit casts - uses pattern matching instead
                // Just process the expression, ignoring the module type hint
                convertExpression(e);

            case TTypeExpr(m):
                // Type expressions become module references (atoms)
                // Reuse existing moduleTypeToString utility function
                var moduleName = moduleTypeToString(m);
                EAtom(moduleName);

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
    // Delegate to ElixirASTHelpers
    static inline function isArrayType(t: Type): Bool {
        return ElixirASTHelpers.isArrayType(t);
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
                                    // Process the injection with proper string interpolation handling
                                    var processedCode = "";
                                    var insideString = false;
                                    var i = 0;

                                    // Process character by character to detect quote state
                                    while (i < code.length) {
                                        var char = code.charAt(i);

                                        // Track string state
                                        if (char == '"' && (i == 0 || code.charAt(i-1) != '\\')) {
                                            insideString = !insideString;
                                            processedCode += char;
                                            i++;
                                            continue;
                                        }

                                        // Check for {N} placeholder
                                        if (char == '{' && i + 1 < code.length) {
                                            var j = i + 1;
                                            var numStr = "";

                                            // Collect digits
                                            while (j < code.length && code.charAt(j) >= '0' && code.charAt(j) <= '9') {
                                                numStr += code.charAt(j);
                                                j++;
                                            }

                                            // Check if we found a valid placeholder
                                            if (numStr != "" && j < code.length && code.charAt(j) == '}') {
                                                final num = Std.parseInt(numStr);
                                                var argStr:String = null;

                                                // Special case: {0} refers to 'this' (the array/object)
                                                if (num == 0) {
                                                    var thisAst = buildFromTypedExpr(thisExpr, context);
                                                    argStr = ElixirASTPrinter.printAST(thisAst);
                                                }
                                                // Other numbers refer to method arguments
                                                else if (num != null && num - 1 < methodArgs.length) {
                                                    var argAst = buildFromTypedExpr(methodArgs[num - 1], context);
                                                    argStr = ElixirASTPrinter.printAST(argAst);
                                                }

                                                // If we got an argument string, substitute it
                                                if (argStr != null) {
                                                    if (insideString) {
                                                        // Inside string: wrap in #{...} for interpolation
                                                        processedCode += '#{$argStr}';
                                                    } else {
                                                        // Outside string: direct substitution
                                                        processedCode += argStr;
                                                    }

                                                    // Skip past the placeholder
                                                    i = j + 1;
                                                    continue;
                                                }
                                            }
                                        }

                                        // Regular character - just append
                                        processedCode += char;
                                        i++;
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
    // Delegate to ElixirASTHelpers (note: simplified implementation there)
    static inline function isMapType(t: Type): Bool {
        return ElixirASTHelpers.isMapType(t);
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
    // Delegate to TemplateHelpers
    static inline function collectTemplateContent(ast: ElixirAST): String {
        return TemplateHelpers.collectTemplateContent(ast);
    }
    
    // Delegate to TemplateHelpers
    static inline function collectTemplateArgument(ast: ElixirAST): String {
        return TemplateHelpers.collectTemplateArgument(ast);
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
    // Delegate to TemplateHelpers
    static inline function isHXXModule(expr: TypedExpr): Bool {
        return TemplateHelpers.isHXXModule(expr);
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
    // Delegate to ElixirASTHelpers (simplified implementation)
    static inline function isMapAccess(t: Type): Bool {
        return ElixirASTHelpers.isMapAccess(t);
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
    // Delegate to ElixirASTHelpers
    static inline function countVarOccurrencesInAST(ast: ElixirAST, name: String): Int {
        return ElixirASTHelpers.countVarOccurrencesInAST(ast, name);
    }

    /**
     * Replace all occurrences of a variable name with a replacement AST (wrapped in parentheses).
     */
    // Delegate to ElixirASTHelpers
    static inline function replaceVarInAST(ast: ElixirAST, name: String, replacement: ElixirAST): ElixirAST {
        return ElixirASTHelpers.replaceVarInAST(ast, name, replacement);
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
    // Delegate to LoopHelpers
    static inline function processLoopIntent(intent: LoopIntent, metadata: LoopIntentMetadata, context: CompilationContext): ElixirAST {
        return LoopHelpers.processLoopIntent(intent, metadata, context);
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
    // Delegate to LoopHelpers (uses optimizers.LoopOptimizer.MapIterationPattern)
    static inline function buildMapIteration(pattern: reflaxe.elixir.ast.optimizers.LoopOptimizer.MapIterationPattern, context: CompilationContext): ElixirAST {
        return LoopHelpers.buildMapIteration(pattern, context);
    }
    
    // Delegate to LoopHelpers
    static inline function analyzesAsExpression(expr: TypedExpr): Bool {
        return LoopHelpers.analyzesAsExpression(expr);
    }
}

// MapIterationPattern typedef is now in LoopOptimizer.hx

#end
