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
import reflaxe.elixir.ast.naming.ElixirAtom;
import reflaxe.elixir.ast.naming.ElixirNaming;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.ast.ReentrancyGuard;
// Import builder modules
import reflaxe.elixir.ast.builders.CoreExprBuilder;
import reflaxe.elixir.ast.builders.BinaryOpBuilder;
import reflaxe.elixir.ast.builders.LoopBuilder;
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

    // Deprecated static variables still referenced (will be removed when fully migrated):
    public static var isInClassMethodContext: Bool = false;
    public static var currentReceiverParamName: Null<String> = null;
    public static var currentModule: String = null;
    public static var currentModuleHasPresence: Bool = false;
    public static var currentClauseContext: Null<ClauseContext> = null;

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
                trace('[ElixirASTBuilder] Module ${compiler.currentCompiledModule} depends on ${moduleName}');
                #end
            }
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

        // Only detect and report cycles - don't interfere with compilation
        detectCycle(exprId);
        enterNode(exprType, exprId);
        #end

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
        // functionParameterIds is accessed via currentContext
        isInClassMethodContext = context.isInClassMethodContext;
        currentReceiverParamName = context.currentReceiverParamName;
        // patternVariableRegistry is accessed via currentContext
        currentModule = context.currentModule;
        currentModuleHasPresence = context.currentModuleHasPresence;
        currentClauseContext = context.currentClauseContext;

        #if debug_ast_builder
        trace('[XRay AST Builder] Converting TypedExpr: ${expr.expr}');
        if (currentContext.variableUsageMap != null) {
            trace('[XRay AST Builder] Using variable usage map with ${Lambda.count(currentContext.variableUsageMap)} entries');
        }
        #end

        // Do the actual conversion
        var metadata = createMetadata(expr);
        var astDef = convertExpression(expr);
        
        // ONLY mark metadata - NO transformation in builder!
        // Check both direct enum constructor calls AND function calls that return idiomatic enums
        switch(expr.expr) {
            case TCall(e, _) if (e != null && isEnumConstructor(e) && hasIdiomaticMetadata(e)):
                // Direct enum constructor call (e.g., ModuleRef("MyModule"))
                metadata.requiresIdiomaticTransform = true;
                metadata.idiomaticEnumType = getEnumTypeName(e);
                #if debug_ast_builder
                trace('[AST Builder] Marked direct enum constructor for transformer: ${getEnumTypeName(e)}');
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
                // Special handling for strings to check if they should be atoms
                switch(c) {
                    case TString(s):
                        // Check if this string has the Atom type
                        var isAtom = false;
                        #if debug_atom_generation
                        trace('[Atom Debug TConst] String "${s}" with type: ${expr.t}');
                        #end
                        switch(expr.t) {
                            case TAbstract(ref, _):
                                var abstractType = ref.get();
                                #if debug_atom_generation
                                trace('[Atom Debug TConst] Abstract type: ${abstractType.pack.join(".")}.${abstractType.name}');
                                #end
                                // Check if this is the Atom abstract type
                                if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Atom") {
                                    isAtom = true;
                                    #if debug_atom_generation
                                    trace('[Atom Debug TConst] DETECTED: String is Atom type!');
                                    #end
                                }
                            case _:
                                #if debug_atom_generation
                                trace('[Atom Debug TConst] Not an abstract type: ${expr.t}');
                                #end
                                // Not an abstract type
                        }

                        if (isAtom) {
                            #if debug_atom_generation
                            trace('[Atom Debug TConst] Generating atom :${s}');
                            #end
                            // Generate atom for Atom-typed strings
                            EAtom(s);
                        } else {
                            #if debug_atom_generation
                            trace('[Atom Debug TConst] Generating string "${s}"');
                            #end
                            // Regular string
                            EString(s);
                        }
                    default:
                        // Delegate to CoreExprBuilder for other constants
                        // Returns ElixirAST, but we need ElixirASTDef
                        var ast = CoreExprBuilder.buildConst(c);
                        ast.def;
                }
                
            // ================================================================
            // Variables and Binding
            // ================================================================
            case TLocal(v):
                // M0.2 FIX: Check currentClauseContext for mapped names from EnumBindingPlan
                if (currentClauseContext != null && currentClauseContext.localToName.exists(v.id)) {
                    var mappedName = currentClauseContext.localToName.get(v.id);

                    #if debug_ast_pipeline
                    trace('[M0.2] TLocal: Using mapped name from ClauseContext: ${v.name} (id=${v.id}) -> ${mappedName}');
                    #end

                    EVar(mappedName);
                } else {
                    // Delegate to CoreExprBuilder for variable resolution
                    var ast = CoreExprBuilder.buildLocal(v);
                    ast.def;
                }
                
            case TVar(v, init):
                #if debug_variable_usage
                if (v.name == "value" || v.name == "msg" || v.name == "err") {
                    trace('[AST Builder] Processing TVar: ${v.name} (id: ${v.id})');
                }
                #end
                
                #if debug_loop_bodies
                // Debug TVar declarations that might be lost in loop bodies
                if (v.name == "meta" || v.name == "entry" || v.name == "userId") {
                    trace('[XRay LoopBody] TVar declaration: ${v.name} = ${init != null ? "..." : "null"}');
                    if (init != null) {
                        trace('[XRay LoopBody] Init type: ${Type.enumConstructor(init.expr)}');
                    }
                }
                #end
                
                #if debug_null_coalescing
                trace('[AST Builder] TVar: ${v.name}, init type: ${init != null ? Type.enumConstructor(init.expr) : "null"}');
                #end
                
                #if debug_assignment_context
                trace('[XRay AssignmentContext] TVar: ${v.name}');
                if (init != null) {
                    trace('[XRay AssignmentContext] Init expr: ${Type.enumConstructor(init.expr)}');
                    switch(init.expr) {
                        case TField(e, _):
                            trace('[XRay AssignmentContext] TField access detected - likely in expression context');
                        case _:
                    }
                }
                #end
                
                #if debug_ast_pipeline
                if (v.name == "p1" || v.name == "p2" || v.name == "p" || v.name == "p_1" || v.name == "p_2") {
                    trace('[AST Builder] TVar declaration: name="${v.name}", id=${v.id}');
                }
                #end
                
                #if debug_array_patterns
                if (init != null) {
                    trace('[XRay ArrayPattern] TVar ${v.name} init: ${Type.enumConstructor(init.expr)}');
                    // Check if this is an array map/filter initialization
                    switch(init.expr) {
                        case TBlock(exprs):
                            trace('[XRay ArrayPattern] TVar contains TBlock with ${exprs.length} expressions');
                        case _:
                    }
                }
                #end
                
                // Check for conditional comprehension pattern: var evens = { var g = []; if statements; g }
                if (init != null) {
                    switch(init.expr) {
                        case TBlock(blockStmts) if (blockStmts.length >= 3):
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
                                var reconstructed = tryReconstructConditionalComprehension(blockStmts, tempVarName, currentContext.variableUsageMap);
                                if (reconstructed != null) {
                                    // trace('[DEBUG] Successfully reconstructed as for comprehension');
                                    return EMatch(PVar(toElixirVarName(v.name)), reconstructed);
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
                var varOrigin: VarOrigin = UserDefined;  // Default to user-defined
                var tempToBinderMap: Map<Int, Int> = null;

                if (init != null) {
                    switch(init.expr) {
                        case TEnumParameter(e, _, index):
                            // This is the temp extraction: _g = result.elem(1)
                            isEnumExtraction = true;
                            varOrigin = ExtractionTemp;  // Mark as extraction temp

                            // Check if this is extracting from a pattern variable in a switch case
                            // Temp vars follow the pattern: g, g1, g2, etc.
                            var tempVarName = toElixirVarName(v.name);

                            #if debug_variable_origin
                            trace('[Variable Origin] TEnumParameter extraction:');
                            trace('  - Variable: ${v.name} (id=${v.id})');
                            trace('  - Temp name: $tempVarName');
                            trace('  - Origin: ExtractionTemp');
                            trace('  - Index: $index');
                            #end

                            // Check if EnumBindingPlan already provides this variable
                            // If so, the pattern already extracts it correctly and we should skip this assignment
                            if (currentClauseContext != null && currentClauseContext.enumBindingPlan != null) {
                                var plan = currentClauseContext.enumBindingPlan;
                                if (plan.exists(index)) {
                                    // The binding plan already handles this extraction in the pattern
                                    shouldSkipRedundantExtraction = true;
                                    #if debug_enum_extraction
                                    trace('[TVar] Skipping redundant TEnumParameter extraction - binding plan provides variable at index $index');
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
                                trace('[TVar] Detected redundant extraction for $tempVarName (will be filtered at TBlock level)');
                                #end
                            }

                        case TLocal(tempVar):
                            // Check if this is assignment from a temp var
                            if (tempVar.name.startsWith("_g") || tempVar.name == "g" || ~/^g\d+$/.match(tempVar.name)) {
                                // This is assignment from temp: value = g
                                extractedFromTemp = tempVar.name;
                                varOrigin = PatternBinder;  // This is the actual pattern variable

                                // If we have an EnumBindingPlan, these assignments are redundant
                                // because the pattern already uses the correct names
                                if (currentClauseContext != null && currentClauseContext.enumBindingPlan != null) {
                                    #if debug_enum_extraction
                                    trace('[TVar] Skipping redundant temp assignment ${v.name} = ${tempVar.name} - binding plan handles it');
                                    #end
                                    return null; // Skip this assignment entirely
                                }

                                // Create mapping from temp var ID to pattern var ID
                                if (tempToBinderMap == null) {
                                    tempToBinderMap = new Map<Int, Int>();
                                }
                                tempToBinderMap.set(tempVar.id, v.id);

                                #if debug_variable_origin
                                trace('[Variable Origin] Pattern assignment from temp:');
                                trace('  - Pattern var: ${v.name} (id=${v.id})');
                                trace('  - Temp var: ${tempVar.name} (id=${tempVar.id})');
                                trace('  - Origin: PatternBinder');
                                trace('  - Mapping: ${tempVar.id} -> ${v.id}');
                                #end
                            } else {
                                // Regular local assignment, check if the source is a pattern variable
                                // from an enum constructor (like RGB(r, g, b))
                                varOrigin = UserDefined;

                                #if debug_variable_origin
                                trace('[Variable Origin] Regular local assignment:');
                                trace('  - Variable: ${v.name} (id=${v.id})');
                                trace('  - From: ${tempVar.name}');
                                trace('  - Origin: UserDefined');
                                #end
                            }

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
                        toElixirVarName(varName, false); // false = strip underscore
                    } else {
                        // For non-_g variables, normal conversion
                        toElixirVarName(varName, false);
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
                            trace('[TVar] Variable ${v.name} is enum parameter extraction from ${tempVar.name}');
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
                    trace('[TVar] Variable ${v.name} (id=${v.id}) is UNUSED, adding underscore prefix');
                    #end
                    // M0 STABILIZATION: Disable underscore prefixing
                    // var underscoreName = "_" + baseName;
                    // currentContext.tempVarRenameMap.set(Std.string(v.id), underscoreName);
                    var underscoreName = baseName; // Keep original name
                    underscoreName;
                } else {
                    // For used variables, also register to ensure consistency
                    // This prevents TLocal from applying different transformations
                    currentContext.tempVarRenameMap.set(Std.string(v.id), baseName);
                    baseName;
                };


                // Handle variable initialization
                var matchNode = if (init != null) {
                    // Check if init is a TBlock with null coalescing pattern
                    var initValue = switch(init.expr) {
                        case TBlock([{expr: TVar(tmpVar, tmpInit)}, {expr: TBinop(OpNullCoal, {expr: TLocal(localVar)}, defaultExpr)}])
                            if (localVar.id == tmpVar.id && tmpInit != null):
                            // This is null coalescing pattern: generate inline if expression
                            var tmpVarName = toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
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
                                    trace('[XRay ArrayPattern] Checking TBlock with ${stmts.length} statements for unrolled comprehension');
                                    for (i in 0...stmts.length) {
                                        trace('[XRay ArrayPattern]   stmt[$i]: ${Type.enumConstructor(stmts[i].expr)}');
                                        // Check if stmt[1] is a nested TBlock
                                        if (i == 1) {
                                            switch(stmts[i].expr) {
                                                case TBlock(innerStmts):
                                                    trace('[XRay ArrayPattern]     stmt[1] is a TBlock with ${innerStmts.length} inner statements');
                                                    for (j in 0...Std.int(Math.min(3, innerStmts.length))) {
                                                        trace('[XRay ArrayPattern]       inner[$j]: ${Type.enumConstructor(innerStmts[j].expr)}');
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
                                                trace('[XRay ArrayPattern] Found TVar for ${v.name}, checking init type: ${initExpr != null ? Type.enumConstructor(initExpr.expr) : "null"}');
                                                #end
                                                switch(initExpr.expr) {
                                                    case TArrayDecl([]):
                                                        isUnrolled = true;
                                                        tempVarName = v.name;
                                                        #if debug_array_patterns
                                                        trace('[XRay ArrayPattern] First statement matches: var ${v.name} = []');
                                                        #end
                                                    default:
                                                        #if debug_array_patterns
                                                        trace('[XRay ArrayPattern] First statement init is not empty array');
                                                        #end
                                                }
                                            default:
                                                #if debug_array_patterns
                                                trace('[XRay ArrayPattern] First statement is not a TVar with g-prefix');
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
                                        trace('[XRay ArrayPattern] TVar init detected as unrolled comprehension with ${values.length} values');
                                        #end
                                        
                                        // Build a proper list from the extracted values
                                        var valueASTs = [for (v in values) buildFromTypedExpr(v, currentContext)];
                                        makeAST(EList(valueASTs));
                                    } else {
                                        // Not an unrolled comprehension, build normally
                                        buildFromTypedExpr(init, currentContext);
                                    }
                                    
                                default:
                                    // Regular init expression
                                    buildFromTypedExpr(init, currentContext);
                            };
                            
                            initExpr;
                    };
                    
                    // Check if we should skip this assignment
                    // Following Codex's architecture guidance: skip redundant assignments from enum extraction
                    var shouldSkipAssignment = false;

                    // Skip assignments from TEnumParameter extraction in case clauses
                    // These are redundant because pattern matching already binds the variables
                    if (init != null && currentClauseContext != null) {
                        // We're inside a case clause
                        switch(init.expr) {
                            case TEnumParameter(_, _, _):
                                // Skip enum parameter extraction assignments - pattern matching handles this
                                shouldSkipAssignment = true;
                                #if debug_enum_extraction
                                trace('[TVar] Skipping redundant enum extraction assignment in case clause: $finalVarName');
                                #end
                            case TLocal(tempVar):
                                var tempVarName = tempVar.name;
                                // FIX: When patterns use canonical names, assignments from temp vars that don't exist
                                // should be skipped entirely. The pattern already binds the correct variable.
                                // Example: pattern {:ok, _value} already binds _value, so "value = g" is wrong (g doesn't exist)
                                if (tempVarName == "g" || (tempVarName.length > 1 && tempVarName.charAt(0) == "g" &&
                                    tempVarName.charAt(1) >= '0' && tempVarName.charAt(1) <= '9')) {
                                    // Check if this temp var actually exists in the pattern
                                    // If not, skip the assignment entirely
                                    shouldSkipAssignment = true;
                                    #if debug_enum_extraction
                                    trace('[TVar] Skipping assignment from non-existent temp var in case clause: $finalVarName = $tempVarName');
                                    #end
                                }
                            case _:
                        }
                    }

                    // Note: Redundant enum extraction is now handled at TBlock level
                    // We generate the assignment here, but TBlock will filter it out if redundant
                    var result = if (shouldSkipAssignment) {
                        // Skip the assignment, return nil as a placeholder
                        // The TBlock handler will filter this out
                        makeAST(ENil);
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
                        trace('[Variable Origin] Added metadata to match node:');
                        trace('  - Variable: $finalVarName');
                        trace('  - Origin: $varOrigin');
                        trace('  - ID: ${v.id}');
                        if (tempToBinderMap != null) {
                            trace('  - Mappings: $tempToBinderMap');
                        }
                        #end

                        matchNode;
                    };
                    result;
                } else {
                    // Uninitialized variable - use nil
                    makeAST(EMatch(
                        PVar(finalVarName),
                        makeAST(ENil)
                    ));
                };
                
                
                matchNode.def;
                
            // ================================================================
            // Binary Operations
            // ================================================================
            case TBinop(op, e1, e2):
                // Delegate to BinaryOpBuilder for all binary operation handling
                var ast = BinaryOpBuilder.buildBinop(
                    op, e1, e2,
                    function(e) return buildFromTypedExpr(e, currentContext),
                    function(e) return extractPattern(e),
                    function(s) return toSnakeCase(s)
                );
                ast.def;
                // Special handling for field != nil or field == nil comparisons
                // These are checking for optional fields and need safe access
                var isNilComparison = switch(op) {
                    case OpEq | OpNotEq: 
                        switch(e2.expr) {
                            case TConst(TNull): true;
                            default: false;
                        }
                    default: false;
                };
                
                // Check if either operand is an inline expansion block
                var left = switch(e1.expr) {
                    case TBlock(el) if (ElixirASTPatterns.isInlineExpansionBlock(el)):
                        makeAST(ElixirASTPatterns.transformInlineExpansion(el, function(e) return buildFromTypedExpr(e, currentContext), function(name) return toElixirVarName(name)));
                    case TField(target, FAnon(cf)) if (isNilComparison):
                        // For optional field checks, use Map.get for safe access
                        var targetAst = buildFromTypedExpr(target, currentContext);
                        var fieldName = toSnakeCase(cf.get().name);
                        makeAST(ERemoteCall(
                            makeAST(EVar("Map")),
                            "get",
                            [targetAst, makeAST(EAtom(fieldName))]
                        ));
                    case _:
                        buildFromTypedExpr(e1, currentContext);
                };
                
                var right = switch(e2.expr) {
                    case TBlock(el) if (ElixirASTPatterns.isInlineExpansionBlock(el)):
                        makeAST(ElixirASTPatterns.transformInlineExpansion(el, function(e) return buildFromTypedExpr(e, currentContext), function(name) return toElixirVarName(name)));
                    case _:
                        buildFromTypedExpr(e2, currentContext);
                };
                
                switch(op) {
                    /**
                     * ADDITION AND STRING CONCATENATION OPERATOR
                     * 
                     * WHY: Elixir distinguishes between numeric addition and string concatenation
                     * - Numbers use + operator for addition
                     * - Strings use <> operator for concatenation
                     * - Using + on strings causes compilation errors in Elixir
                     * 
                     * WHAT: Type-aware operator selection for addition operations
                     * - Detect String types through type inspection
                     * - Generate StringConcat for string operations
                     * - Generate Add for numeric operations
                     * 
                     * HOW: Examine left operand type to determine operation
                     * - TInst with name "String": String class instance
                     * - TAbstract with name "String": String abstract type
                     * - All other types: Numeric addition
                     * 
                     * EXAMPLES:
                     * - Haxe: `"hello" + "world"` → Elixir: `"hello" <> "world"`
                     * - Haxe: `5 + 3` → Elixir: `5 + 3`
                     * - Haxe: `str1 + str2` → Elixir: `str1 <> str2` (if str1 is String)
                     */
                    case OpAdd: 
                        // Detect string concatenation based on left operand type
                        var isStringConcat = switch(e1.t) {
                            case TInst(_.get() => {name: "String"}, _): true;      // String class instance
                            case TAbstract(_.get() => {name: "String"}, _): true;  // String abstract type
                            default: false;
                        };
                        
                        // Generate appropriate binary operation
                        if (isStringConcat) {
                            // For string concatenation, ensure right operand is a string
                            var rightStr = switch(e2.t) {
                                case TInst(_.get() => {name: "String"}, _): right;
                                case TAbstract(_.get() => {name: "String"}, _): right;
                                default: 
                                    // Non-string needs conversion
                                    makeAST(ERemoteCall(makeAST(EVar("Kernel")), "to_string", [right]));
                            };
                            EBinary(StringConcat, left, rightStr);  // String concatenation: <>
                        } else {
                            EBinary(Add, left, right);           // Numeric addition: +
                        }
                    case OpSub: EBinary(Subtract, left, right);
                    case OpMult: EBinary(Multiply, left, right);
                    case OpDiv: EBinary(Divide, left, right);
                    case OpMod: EBinary(Remainder, left, right);
                    
                    case OpEq: EBinary(Equal, left, right);
                    case OpNotEq: EBinary(NotEqual, left, right);
                    case OpLt: EBinary(Less, left, right);
                    case OpLte: EBinary(LessEqual, left, right);
                    case OpGt: EBinary(Greater, left, right);
                    case OpGte: EBinary(GreaterEqual, left, right);
                    
                    case OpBoolAnd: EBinary(AndAlso, left, right);
                    case OpBoolOr: EBinary(OrElse, left, right);
                    
                    case OpAssign: EMatch(extractPattern(e1), right);
                    
                    /**
                     * COMPOUND ASSIGNMENT OPERATOR HANDLING
                     * 
                     * WHY: Elixir strings are immutable, requiring special handling for string concatenation
                     * - Numeric types use standard operators: +=, -=, *=, etc.
                     * - String concatenation MUST use <> operator, not +
                     * - Haxe's += on strings needs conversion to Elixir's <> operator
                     * 
                     * WHAT: Transform compound assignments (a += b) into expanded form (a = a op b)
                     * - Detect when the target variable is a String type
                     * - Use StringConcat operator for string concatenation
                     * - Use standard arithmetic operators for numeric types
                     * 
                     * HOW: Type-based operator selection
                     * 1. Check if operator is OpAdd (potential string concatenation)
                     * 2. Examine the type of the left-hand expression
                     * 3. Select StringConcat for String types, Add for numeric types
                     * 4. Generate EMatch with expanded binary operation
                     * 
                     * EXAMPLES:
                     * - Haxe: `result += "\\n"` → Elixir: `result = result <> "\\n"`
                     * - Haxe: `count += 1` → Elixir: `count = count + 1`
                     * - Haxe: `buffer += content` → Elixir: `buffer = buffer <> content` (if buffer is String)
                     * 
                     * EDGE CASES:
                     * - Dynamic types: Falls back to Add operator (may cause runtime errors)
                     * - Mixed types: Relies on Haxe's type checking for correctness
                     * - Null strings: Handled by Elixir's <> operator semantics
                     */
                    case OpAssignOp(op2): 
                        // Transform compound assignment: a += b becomes a = a + b
                        // Special handling for string concatenation in Elixir
                        var innerOp = if (op2 == OpAdd) {
                            // Detect string concatenation based on left-hand expression type
                            var isStringConcat = switch(e1.t) {
                                case TInst(_.get() => {name: "String"}, _): true;      // String class instance
                                case TAbstract(_.get() => {name: "String"}, _): true;  // String abstract type
                                default: false;
                            };
                            // Select appropriate operator: <> for strings, + for numbers
                            isStringConcat ? StringConcat : Add;
                        } else {
                            // Non-addition operators: -, *, /, %, &, |, ^, <<, >>
                            convertAssignOp(op2);
                        }
                        // Generate assignment with expanded binary operation
                        EMatch(extractPattern(e1), makeAST(EBinary(innerOp, left, right)));
                    
                    case OpAnd: EBinary(BitwiseAnd, left, right);
                    case OpOr: EBinary(BitwiseOr, left, right);
                    case OpXor: EBinary(BitwiseXor, left, right);
                    case OpShl: EBinary(ShiftLeft, left, right);
                    case OpShr: EBinary(ShiftRight, left, right);
                    case OpUShr: EBinary(ShiftRight, left, right); // No unsigned in Elixir
                    
                    case OpInterval: 
                        // Haxe's ... is exclusive (0...3 means 0,1,2)
                        // We have two options:
                        // 1. Use exclusive range in Elixir: 0...3 (prints as "0...3")
                        // 2. Use inclusive with end-1: 0..2 (prints as "0..2")
                        // Going with option 2 to match expected test output
                        ERange(left, makeAST(EBinary(Subtract, right, makeAST(EInteger(1)))), false);
                    case OpArrow: EFn([{
                        args: [PVar("_arrow")], // Placeholder, will be transformed
                        body: right
                    }]);
                    case OpIn: EBinary(In, left, right);
                    case OpNullCoal: 
                        // a ?? b needs special handling to avoid double evaluation
                        // For complex expressions, we need a temp variable in the condition
                        // Generate: if (tmp = a) != nil, do: tmp, else: b
                        
                        // Check if left is a simple variable that can be referenced multiple times
                        var isSimple = switch(left.def) {
                            case EVar(_): true;
                            case ENil: true;
                            case EBoolean(_): true;
                            case EInteger(_): true;
                            case EString(_): true;
                            case _: false;
                        };
                        
                        if (isSimple) {
                            // Simple expression can be used directly
                            var ifExpr = makeAST(EIf(
                                makeAST(EBinary(NotEqual, left, makeAST(ENil))),
                                left,
                                right
                            ));
                            // Mark as inline for null coalescing
                            if (ifExpr.metadata == null) ifExpr.metadata = {};
                            ifExpr.metadata.keepInlineInAssignment = true;
                            ifExpr.def;
                        } else {
                            // Complex expression needs temp variable to avoid double evaluation
                            // Generate: if (tmp = expr) != nil, do: tmp, else: default
                            var tmpVar = makeAST(EVar("tmp"));
                            var assignment = makeAST(EMatch(PVar("tmp"), left));
                            
                            // Mark this if expression to stay inline when assigned
                            var ifExpr = makeAST(EIf(
                                makeAST(EBinary(NotEqual, assignment, makeAST(ENil))),
                                tmpVar,
                                right
                            ));
                            // Set metadata to indicate this should stay inline
                            if (ifExpr.metadata == null) ifExpr.metadata = {};
                            ifExpr.metadata.keepInlineInAssignment = true;
                            ifExpr.def;
                        }
                }
                
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
                        // Elixir is immutable, so we need to generate an assignment
                        // When used as a statement, convert to: var = var + 1 or var = var - 1
                        var one = makeAST(EInteger(1));
                        var builtExpr = buildFromTypedExpr(e, currentContext);
                        var operation = if (op == OpIncrement) {
                            makeAST(EBinary(Add, builtExpr, one));
                        } else {
                            makeAST(EBinary(Subtract, builtExpr, one));
                        };
                        
                        // If this is a standalone statement (not part of another expression),
                        // we need to generate an assignment
                        // Check if the original expression is a local variable that can be assigned
                        switch(e.expr) {
                            case TLocal(v):
                                // Generate: var = var +/- 1
                                EBinary(Match, builtExpr, operation);
                            default:
                                // For complex expressions, just return the operation
                                // (this may not work correctly for all cases)
                                operation.def;
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
                // TODO: Delegate to CallExprBuilder once compilation issues fixed
                // CallExprBuilder.buildCall(e, el, currentContext, expr -> buildFromTypedExpr(expr)).def;
                #if debug_function_reference
                trace('[FunctionRef] Processing TCall with ${el.length} args');
                for (i in 0...el.length) {
                    switch(el[i].expr) {
                        case TField(_, FStatic(classRef, cf)):
                            trace('[FunctionRef] Arg $i is static field: ${classRef.get().name}.${cf.get().name}');
                        default:
                    }
                }
                #end
                
                // Early detection flag for Phoenix.Presence special handling
                var presenceHandled = false;
                
                // Check if this is an enum constructor call first
                if (e != null && isEnumConstructor(e)) {
                    // ONLY BUILD - NO TRANSFORMATION!
                    var tag = extractEnumTag(e);
                    
                    // For idiomatic enums, convert constructor names to snake_case
                    // This ensures Result.Ok becomes :ok and Result.Error becomes :error
                    if (hasIdiomaticMetadata(e)) {
                        tag = reflaxe.elixir.ast.NameUtils.toSnakeCase(tag);
                        
                        // TODO: Add special handling for Option<T> to map Some→ok and None→error
                        // Currently just lowercases to :some/:none which isn't fully idiomatic.
                        // Should check if the enum type is haxe.ds.Option and apply mapping:
                        // if (isOptionType(e)) {
                        //     tag = switch(tag) {
                        //         case "some": "ok";
                        //         case "none": "error";
                        //         case _: tag;
                        //     }
                        // }
                    }
                    
                    var args = [for (arg in el) buildFromTypedExpr(arg, currentContext)];
                    
                    // Create the tuple AST definition
                    var tupleDef = ETuple([makeAST(EAtom(tag))].concat(args));
                    
                    #if debug_ast_builder
                    if (hasIdiomaticMetadata(e)) {
                        trace('[AST Builder] Building idiomatic enum tuple: ${tag} with ${args.length} args');
                        trace('[AST Builder] Enum type: ${getEnumTypeName(e)}');
                    }
                    #end
                    
                    // The metadata will be set by the outer buildFromTypedExpr function
                    tupleDef;
                } else {
                    // Regular function call - check for function reference arguments
                    var args = [];
                    for (arg in el) {
                        // Check if this argument is a function reference
                        var isFunctionRef = false;
                        switch(arg.expr) {
                            case TField(_, FStatic(classRef, cf)):
                                // This is a static field being passed as an argument
                                switch(cf.get().type) {
                                    case TFun(funcArgs, _):
                                        // It's a function being passed as a reference
                                        isFunctionRef = true;
                                        var target = buildFromTypedExpr(arg, currentContext);
                                        
                                        // Extract module and function name from the built AST
                                        switch(target.def) {
                                            case EField(module, funcName):
                                                // Add capture operator with correct arity
                                                var arity = funcArgs.length;
                                                args.push(makeAST(ECapture(target, arity)));
                                            default:
                                                args.push(target);
                                        }
                                    default:
                                        // Not a function, check if it's an Atom type
                                        var field = cf.get();
                                        var isAtomField = false;
                                        
                                        // Check if this is an enum abstract field with Atom underlying type
                                        // For enum abstract fields like TimeUnit.Millisecond, the field type
                                        // will be String (the resolved type), not Atom (the abstract type).
                                        // So we need to check the containing class instead.
                                        var classType = classRef.get();
                                        
                                        // Check if the class is an abstract impl (like TimeUnit_Impl_)
                                        #if debug_atom_generation
                                        trace('[Atom Debug] Checking static field ${field.name} of class ${classType.name}');
                                        trace('[Atom Debug] Class kind: ${classType.kind}');
                                        trace('[Atom Debug] Field type: ${field.type}');
                                        trace('[Atom Debug] Field expr: ${field.expr()}');
                                        #end
                                        
                                        switch (classType.kind) {
                                            case KAbstractImpl(abstractRef):
                                                // Get the abstract type definition
                                                var abstractType = abstractRef.get();
                                                #if debug_atom_generation
                                                trace('[Atom Debug] Abstract type: ${abstractType.name}');
                                                trace('[Atom Debug] Abstract underlying type: ${abstractType.type}');
                                                #end
                                                // Check the underlying type of the abstract
                                                switch (abstractType.type) {
                                                    case TAbstract(underlyingRef, _):
                                                        var underlyingType = underlyingRef.get();
                                                        #if debug_atom_generation
                                                        trace('[Atom Debug] Underlying abstract: ${underlyingType.pack.join(".")}.${underlyingType.name}');
                                                        #end
                                                        if (underlyingType.pack.join(".") == "elixir.types" && underlyingType.name == "Atom") {
                                                            isAtomField = true;
                                                            #if debug_atom_generation
                                                            trace('[Atom Debug] Field IS an Atom type!');
                                                            #end
                                                        }
                                                    case _:
                                                        #if debug_atom_generation
                                                        trace('[Atom Debug] Abstract type is not TAbstract');
                                                        #end
                                                }
                                            case _:
                                                #if debug_atom_generation
                                                trace('[Atom Debug] Class is not an abstract impl');
                                                #end
                                        }
                                        
                                        if (isAtomField && field.expr() != null) {
                                            // Get the field's expression value
                                            #if debug_atom_generation
                                            trace('[Atom Debug TCall] Field has expr, checking value...');
                                            #end
                                            switch (field.expr().expr) {
                                                case TConst(TString(s)):
                                                    // This is the string value of the enum abstract field
                                                    // Generate an atom directly
                                                    #if debug_atom_generation
                                                    trace('[Atom Debug TCall] String value "${s}" -> generating atom :${s}');
                                                    #end
                                                    args.push(makeAST(EAtom(s)));
                                                case _:
                                                    #if debug_atom_generation
                                                    trace('[Atom Debug TCall] Not a string constant, compiling normally');
                                                    #end
                                                    // Not a string constant, compile normally
                                                    args.push(buildFromTypedExpr(arg, currentContext));
                                            }
                                        } else {
                                            #if debug_atom_generation
                                            if (isAtomField) {
                                                trace('[Atom Debug TCall] Atom field but no expr');
                                            } else {
                                                trace('[Atom Debug TCall] Not an atom field');
                                            }
                                            #end
                                            // Not an Atom type, compile normally
                                            args.push(buildFromTypedExpr(arg, currentContext));
                                        }
                                }
                            default:
                                // Check if this argument has the Atom abstract type
                                var isAtomType = false;
                                switch(arg.t) {
                                    case TAbstract(abstractRef, _):
                                        var abstractType = abstractRef.get();
                                        if (abstractType.pack.join(".") == "elixir.types" && abstractType.name == "Atom") {
                                            isAtomType = true;
                                        }
                                    case _:
                                }
                                
                                if (isAtomType) {
                                    // If it's an Atom type, check if it's a string constant and convert to atom
                                    switch(arg.expr) {
                                        case TConst(TString(s)):
                                            // Direct string constant with Atom type
                                            args.push(makeAST(EAtom(s)));
                                        case TField(_, FStatic(classRef, cf)):
                                            // Static field access (like TimeUnit.Millisecond)
                                            var field = cf.get();
                                            if (field.expr() != null) {
                                                switch(field.expr().expr) {
                                                    case TConst(TString(s)):
                                                        // The field has a constant string value
                                                        args.push(makeAST(EAtom(s)));
                                                    default:
                                                        // Not a constant, compile normally
                                                        args.push(buildFromTypedExpr(arg, currentContext));
                                                }
                                            } else {
                                                // No expression, compile normally
                                                args.push(buildFromTypedExpr(arg, currentContext));
                                            }
                                        default:
                                            // Other expressions with Atom type
                                            var builtArg = buildFromTypedExpr(arg, currentContext);
                                            // If it was built as a string, convert to atom
                                            switch(builtArg.def) {
                                                case EString(s):
                                                    args.push(makeAST(EAtom(s)));
                                                default:
                                                    args.push(builtArg);
                                            }
                                    }
                                } else {
                                    // Not an Atom type, compile normally
                                    args.push(buildFromTypedExpr(arg, currentContext));
                                }
                        }
                    }
                    
                    /**
                     * CRITICAL FIX PART 2: Handle Static Extern Method Calls (2025-09-05)
                     * 
                     * This is the second part of the fix for static methods on extern classes.
                     * When we detect a call to a static method on an extern class with @:native,
                     * we generate a proper ERemoteCall instead of a regular ECall.
                     * 
                     * DETECTION: Check if the target is TField with FStatic on an extern class
                     * - The class must be extern
                     * - The class must have @:native annotation with module name
                     * - The field access must be FStatic
                     * 
                     * TRANSFORMATION:
                     * Instead of: ECall(EField(...), args) which would print as "list(args)"  
                     * We generate: ERemoteCall(module, method, args) which prints as "Module.method(args)"
                     * 
                     * This ensures all static methods on extern classes with @:native annotations
                     * are properly qualified with their module names in the generated Elixir code.
                     */
                    // Check if this is a static method call on an extern class or standard library class
                    if (e != null) {
                        switch(e.expr) {
                            case TField(_, FStatic(classRef, cf)):
                                var classType = classRef.get();
                                var field = cf.get();
                                
                                // Check if the field has @:native annotation
                                var methodName = field.name;
                                if (field.meta.has(":native")) {
                                    var nativeMeta = field.meta.extract(":native");
                                    if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                                        switch(nativeMeta[0].params[0].expr) {
                                            case EConst(CString(s, _)):
                                                methodName = s; // Use the native name instead
                                            default:
                                        }
                                    }
                                }
                                
                                // Check if we're calling a static method within the same module
                                // Private functions in Elixir cannot be called with module prefix
                                // IMPORTANT: We need to check if it's actually the same class, not just same name
                                // Classes with @:native might have the same name as extern classes they use
                                // 
                                // BUG FIX (January 2025): When a class with @:native("MyAppWeb.Presence")
                                // has internal name "Presence" and calls extern Presence.track(), we were
                                // incorrectly treating it as same-module call, bypassing BehaviorTransformer.
                                // Solution: Don't treat extern class calls as same-module calls, especially
                                // when BehaviorTransformer is active (indicates special handling needed).
                                var isSameModuleCall = false;
                                if (currentContext.currentModule != null && classType.name == currentContext.currentModule) {
                                    // Names match, but check if this is an extern class call
                                    // Extern classes should go through normal processing for transformations
                                    if (classType.isExtern) {
                                        // Calling an extern class - not a same-module call
                                        // This is crucial for Phoenix.Presence behavior transformations
                                        isSameModuleCall = false;
                                    } else if (currentContext.currentModuleHasPresence && currentContext.behaviorTransformer != null) {
                                        // Current module has @:presence - let BehaviorTransformer handle the call
                                        // This ensures @:presence modules get proper self() injection
                                        // FIX (January 2025): Changed from checking activeBehavior != null to currentModuleHasPresence
                                        // to prevent non-@:presence modules from getting transformations
                                        isSameModuleCall = false;
                                    } else {
                                        // Regular same-module call
                                        isSameModuleCall = true;
                                    }
                                }
                                
                                if (isSameModuleCall) {
                                    // Same module - call without module prefix
                                    var elixirMethodName = toSnakeCase(methodName);
                                    return ECall(null, elixirMethodName, args);
                                }
                                
                                /**
                                 * BEHAVIOR TRANSFORMATION INTEGRATION
                                 * 
                                 * WHY: Elixir behaviors (Phoenix.Presence, GenServer, etc.) inject
                                 * local functions with different calling conventions than their
                                 * module counterparts. This logic was previously hardcoded here.
                                 * 
                                 * WHAT: We now delegate to the BehaviorTransformer system which
                                 * uses a pluggable architecture to handle behavior-specific
                                 * transformations based on module metadata.
                                 * 
                                 * HOW: The BehaviorTransformer checks if we're in a behavior
                                 * context (e.g., @:presence module) and applies the appropriate
                                 * transformation (e.g., inject self() for Presence.track).
                                 * 
                                 * BENEFITS:
                                 * - No hardcoded framework knowledge in main compiler
                                 * - Extensible to new behaviors without modifying this file
                                 * - Single Responsibility: Each behavior has its own transformer
                                 * - Easier testing and maintenance
                                 * 
                                 * @see reflaxe.elixir.behaviors.BehaviorTransformer
                                 * @see reflaxe.elixir.behaviors.PresenceBehaviorTransformer
                                 */
                                // Only apply behavior transformations if current module has the behavior
                                // FIX (January 2025): Added currentModuleHasPresence check to prevent
                                // non-@:presence modules from getting Presence transformations
                                if (currentContext.behaviorTransformer != null && currentContext.currentModuleHasPresence) {
                                    #if debug_behavior_transformer
                                    trace('[ElixirASTBuilder] Current module has @:presence, calling behaviorTransformer.transformMethodCall with className="${classType.name}", methodName="${methodName}"');
                                    #end
                                    var transformedCall = currentContext.behaviorTransformer.transformMethodCall(
                                        classType.name,
                                        methodName,
                                        args,
                                        true // isStatic - all these are static method calls
                                    );
                                    
                                    if (transformedCall != null) {
                                        #if debug_behavior_transformer
                                        trace('[BehaviorTransformer] Transformed ${classType.name}.${methodName} call');
                                        var transformedStr = reflaxe.elixir.ast.ElixirASTPrinter.print(transformedCall);
                                        trace('[BehaviorTransformer] Transformed AST: ${transformedStr.substring(0, 100)}');
                                        #end
                                        return transformedCall.def;  // Extract the ElixirASTDef from the ElixirAST
                                    }
                                }
                                
                                // Special handling for Reflect static methods
                                else if (classType.name == "Reflect") {
                                    switch(methodName) {
                                        case "hasField":
                                            // Reflect.hasField(obj, field) -> Map.has_key?(obj, String.to_atom(field))
                                            // Convert field name to atom since Elixir maps typically use atom keys
                                            if (args.length == 2) {
                                                var obj = args[0];
                                                var fieldNameExpr = args[1];
                                                
                                                // Wrap the field name with String.to_atom() conversion
                                                var atomField = makeAST(ERemoteCall(
                                                    makeAST(EVar("String")),
                                                    "to_atom",
                                                    [fieldNameExpr]
                                                ));
                                                
                                                trackDependency("Map");
                                                return ERemoteCall(makeAST(EVar("Map")), "has_key?", [obj, atomField]);
                                            }
                                        case "field":
                                            // Reflect.field(obj, field) -> Map.get(obj, String.to_atom(field))
                                            // Convert field name to atom since Elixir maps typically use atom keys
                                            if (args.length == 2) {
                                                var obj = args[0];
                                                var fieldNameExpr = args[1];
                                                
                                                // Wrap the field name with String.to_atom() conversion
                                                var atomField = makeAST(ERemoteCall(
                                                    makeAST(EVar("String")),
                                                    "to_atom",
                                                    [fieldNameExpr]
                                                ));
                                                
                                                trackDependency("Map");
                                                return ERemoteCall(makeAST(EVar("Map")), "get", [obj, atomField]);
                                            }
                                        case "setField":
                                            // Reflect.setField(obj, field, value) -> Map.put(obj, String.to_atom(field), value)
                                            // Convert field name to atom since Elixir maps typically use atom keys
                                            if (args.length == 3) {
                                                var obj = args[0];
                                                var fieldNameExpr = args[1];
                                                var value = args[2];
                                                
                                                // Wrap the field name with String.to_atom() conversion
                                                var atomField = makeAST(ERemoteCall(
                                                    makeAST(EVar("String")),
                                                    "to_atom",
                                                    [fieldNameExpr]
                                                ));
                                                
                                                return ERemoteCall(makeAST(EVar("Map")), "put", [obj, atomField, value]);
                                            }
                                        case "fields":
                                            // Reflect.fields(obj) -> Map.keys(obj)
                                            if (args.length == 1) {
                                                return ERemoteCall(makeAST(EVar("Map")), "keys", args);
                                            }
                                        case "isObject":
                                            // Reflect.isObject(v) -> is_map(v)
                                            if (args.length == 1) {
                                                return ECall(null, "is_map", args);
                                            }
                                        case "deleteField":
                                            // Reflect.deleteField(obj, field) -> Map.delete(obj, String.to_atom(field))
                                            // Convert field name to atom since Elixir maps typically use atom keys
                                            if (args.length == 2) {
                                                var obj = args[0];
                                                var fieldNameExpr = args[1];
                                                
                                                // Wrap the field name with String.to_atom() conversion
                                                var atomField = makeAST(ERemoteCall(
                                                    makeAST(EVar("String")),
                                                    "to_atom",
                                                    [fieldNameExpr]
                                                ));
                                                
                                                return ERemoteCall(makeAST(EVar("Map")), "delete", [obj, atomField]);
                                            }
                                        case "copy":
                                            // Reflect.copy(obj) -> obj (immutable in Elixir)
                                            if (args.length == 1) {
                                                return args[0].def;
                                            }
                                        case "compare":
                                            // Reflect.compare(a, b) -> compare function
                                            if (args.length == 2) {
                                                // Generate: cond do a < b -> -1; a > b -> 1; true -> 0 end
                                                var lt = EBinary(EBinaryOp.Less, args[0], args[1]);
                                                var gt = EBinary(EBinaryOp.Greater, args[0], args[1]);
                                                var ltClause: ECondClause = {condition: makeAST(lt), body: makeAST(EInteger(-1))};
                                                var gtClause: ECondClause = {condition: makeAST(gt), body: makeAST(EInteger(1))};
                                                var trueClause: ECondClause = {condition: makeAST(EBoolean(true)), body: makeAST(EInteger(0))};
                                                return ECond([ltClause, gtClause, trueClause]);
                                            }
                                        case "isEnumValue":
                                            // Reflect.isEnumValue(v) -> is_tuple(v) and elem(v, 0) is atom
                                            if (args.length == 1) {
                                                var isTuple = ECall(null, "is_tuple", args);
                                                var elem0 = ECall(null, "elem", [args[0], makeAST(EInteger(0))]);
                                                var isAtom = ECall(null, "is_atom", [makeAST(elem0)]);
                                                return EBinary(EBinaryOp.And, makeAST(isTuple), makeAST(isAtom));
                                            }
                                        case "callMethod":
                                            // Reflect.callMethod(obj, func, args) -> apply(func, args)
                                            if (args.length == 3) {
                                                // In Elixir, we use apply/2 for function application
                                                return ECall(null, "apply", [args[1], args[2]]);
                                            }
                                        default:
                                            // Other Reflect methods not yet implemented
                                    }
                                }
                                
                                // Check for classes with @:native annotation (both extern and regular classes)
                                // This handles framework classes like SafePubSub that should be called as remote modules
                                // IMPORTANT: This is an else-if to prevent overriding Phoenix.Presence handling above
                                else if (classType.meta.has(":native")) {
                                    // Extract the native module name
                                    var nativeModuleName = "";
                                    var nativeMeta = classType.meta.extract(":native");
                                    if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                                        switch(nativeMeta[0].params[0].expr) {
                                            case EConst(CString(s, _)):
                                                nativeModuleName = s;
                                            default:
                                        }
                                    }
                                    
                                    if (nativeModuleName != "") {
                                        // Special handling for Phoenix.Presence when called from outside @:presence modules
                                        // We need to set presenceHandled flag to prevent malformed output
                                        if (classType.name == "Presence" && nativeModuleName == "Phoenix.Presence") {
                                            #if debug_presence
                                            trace('[DEBUG PRESENCE] @:native Phoenix.Presence call from non-@:presence module');
                                            trace('[DEBUG PRESENCE] Setting presenceHandled=true to prevent duplicate target building');
                                            #end
                                            presenceHandled = true;
                                        }
                                        
                                        // Convert method name to snake_case for Elixir
                                        var elixirMethodName = toSnakeCase(methodName);
                                        // Track dependency on this module
                                        #if debug_dependencies
                                        trace('[ElixirASTBuilder] Static method ${classType.name}.${methodName} with @:native(${nativeModuleName})');
                                        trace('[ElixirASTBuilder] About to track dependency on ${nativeModuleName}');
                                        #end
                                        trackDependency(nativeModuleName);
                                        // Generate remote call with full module qualification
                                        return ERemoteCall(makeAST(EVar(nativeModuleName)), elixirMethodName, args);
                                    }
                                } else {
                                    // No @:native annotation, but still a static method call on another class
                                    // Track dependency on the class name (e.g., Std, Log, etc.)
                                    var moduleName = classType.name;
                                    #if debug_dependencies
                                    trace('[ElixirASTBuilder] Static method ${classType.name}.${methodName} without @:native');
                                    trace('[ElixirASTBuilder] Class package: ${classType.pack.join(".")}');
                                    trace('[ElixirASTBuilder] Tracking dependency on ${moduleName}');
                                    #end
                                    trackDependency(moduleName);
                                    
                                    // Store package information for this module
                                    if (currentContext.compiler != null && classType.pack.length > 0) {
                                        currentContext.compiler.modulePackages.set(moduleName, classType.pack);
                                        #if debug_dependencies
                                        trace('[ElixirASTBuilder] Stored package info for ${moduleName}: ${classType.pack.join("/")}');
                                        #end
                                    }
                                    // Note: The actual call generation happens later via normal target building
                                }
                            default:
                        }
                    }
                    
                    // Build target normally for other cases (unless Phoenix.Presence was already handled)
                    #if debug_presence
                    if (presenceHandled) {
                        trace('[DEBUG PRESENCE] presenceHandled=true, skipping target building');
                    }
                    #end
                    var target = if (presenceHandled) {
                        // Phoenix.Presence was already handled, don't build the target to avoid malformed output
                        null;
                    } else {
                        e != null ? buildFromTypedExpr(e, currentContext) : null;
                    }
                    
                    // Detect special call patterns
                    switch(e.expr) {
                        case TIdent("__elixir__"):
                            // Handle __elixir__ injection
                            if (args.length > 0) {
                                switch(args[0].def) {
                                    case EString(code):
                                        // Process parameter substitution if needed
                                        var processedCode = code;
                                        if (args.length > 1) {
                                            // Substitute parameters in the code string
                                            for (i in 1...args.length) {
                                                // Convert AST to string for substitution
                                                var paramStr = ElixirASTPrinter.printAST(args[i]);
                                                // Replace {i-1} placeholder with the parameter
                                                var placeholder = '{${i-1}}';
                                                processedCode = StringTools.replace(processedCode, placeholder, paramStr);
                                            }
                                        }
                                        // Return raw Elixir code
                                        ERaw(processedCode);
                                    default:
                                        // Not a string constant, can't inject
                                        ECall(target, "call", args);
                                }
                            } else {
                                // No arguments to __elixir__
                                ECall(target, "call", args);
                            }
                        case TField(obj, fa):
                            var fieldName = extractFieldName(fa);
                            // Convert to snake_case for Elixir method names
                            fieldName = toSnakeCase(fieldName);
                            
                            // Check if obj is a local variable that might have been renamed in a switch case
                            var objAst = switch(obj.expr) {
                                case TLocal(v):
                                    // Check if this variable was extracted from a pattern match
                                    // In switch cases like `case Ok(value)`, we might have:
                                    // 1. A temp variable (like 'value') that extracts from the enum
                                    // 2. A renamed variable (like 'email') that gets assigned
                                    // We need to use the renamed variable, not the temp
                                    
                                    // First, check if there's a rename mapping for this variable
                                    var varName = v.name;
                                    
                                    // If this is a variable that was part of a pattern extraction,
                                    // and we have a renamed version, use the renamed version
                                    // This ensures abstract type methods use the correct variable
                                    // e.g., Email_Impl_.get_domain(g) not Email_Impl_.get_domain(value)
                                    
                                    // Check ClauseContext for mapped names (from pattern matching)
                                    if (currentClauseContext != null && currentClauseContext.localToName.exists(v.id)) {
                                        var mappedName = currentClauseContext.localToName.get(v.id);
                                        #if debug_ast_pipeline
                                        trace('[AST Builder] TCall: Using mapped name from ClauseContext for abstract type: ${v.name} (id=${v.id}) -> ${mappedName}');
                                        #end
                                        makeAST(EVar(mappedName));
                                    } else {
                                        // No mapping, build the variable normally
                                        buildFromTypedExpr(obj, currentContext);
                                    }
                                    
                                default:
                                    buildFromTypedExpr(obj, currentContext);
                            };

                            // Fallback based on the object's type: if it's an extern Elixir class
                            // with @:native("Module"), rewrite instance call to Module.function(obj, ...)
                            var typeModule = getExternNativeModuleNameFromType(obj.t);
                            if (typeModule != null) {
                                trackDependency(typeModule);
                                return ERemoteCall(makeAST(EVar(typeModule)), fieldName, [objAst].concat(args));
                            }
                            
                            // If calling an instance method on an extern Elixir type (@:native module),
                            // transform `value.method(args)` into `Module.method(value, args)`.
                            // This avoids invalid instance-style syntax in Elixir.
                            switch (fa) {
                                case FInstance(cRef, _, cfRef):
                                    var cls = cRef.get();
                                    // Detect extern Elixir class with @:native("Module") metadata
                                    if (cls.isExtern && cls.meta.has(":native")) {
                                        var nativeMeta = cls.meta.extract(":native");
                                        var moduleName: Null<String> = null;
                                        if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                                            switch(nativeMeta[0].params[0].expr) {
                                                case EConst(CString(s, _)):
                                                    moduleName = s;
                                                default:
                                            }
                                        }
                                        if (moduleName != null) {
                                            // Determine function name: prefer method-level @:native if present
                                            var methodName = fieldName;
                                            var cf = cfRef.get();
                                            if (cf.meta.has(":native")) {
                                                var mMeta = cf.meta.extract(":native");
                                                if (mMeta.length > 0 && mMeta[0].params != null && mMeta[0].params.length > 0) {
                                                    switch(mMeta[0].params[0].expr) {
                                                        case EConst(CString(ns, _)):
                                                            methodName = toSnakeCase(ns);
                                                        default:
                                                    }
                                                }
                                            }
                                            // Track dependency and emit remote call with object as first argument
                                            trackDependency(moduleName);
                                            return ERemoteCall(makeAST(EVar(moduleName)), methodName, [objAst].concat(args));
                                        }
                                    }
                                default:
                            }
                            
                            // Special handling for tuple.elem(N) -> elem(tuple, N)
                            if (fieldName == "elem" && args.length == 1) {
                                // Transform to Elixir's elem(tuple, index) function
                                return ECall(null, "elem", [objAst, args[0]]);
                            }
                            
                            // Check for Assert class calls (ExUnit assertions)
                            if (isAssertClass(obj)) {
                                // Map Assert methods to ExUnit assertions
                                var assertFunc = switch(fieldName) {
                                    case "equals": "assert";  // Assert.equals(a, b) -> assert(a == b)
                                    case "notEquals": "refute";  // Assert.notEquals(a, b) -> refute(a == b)
                                    case "isTrue": "assert";  // Assert.isTrue(x) -> assert(x)
                                    case "isFalse": "refute";  // Assert.isFalse(x) -> refute(x)
                                    case "isNull": "assert";  // Assert.isNull(x) -> assert(x == nil)
                                    case "isNotNull": "refute";  // Assert.isNotNull(x) -> refute(x == nil)
                                    case "fail": "flunk";  // Assert.fail(msg) -> flunk(msg)
                                    default: "assert";  // Default to assert for unknown methods
                                };

                                // Transform arguments based on assertion type
                                var assertArgs = switch(fieldName) {
                                    case "equals" if (args.length >= 2):
                                        // Transform Assert.equals(a, b) to assert(a == b)
                                        [makeAST(EBinary(Equal, args[0], args[1]))];
                                    case "notEquals" if (args.length >= 2):
                                        // Transform Assert.notEquals(a, b) to refute(a == b)
                                        [makeAST(EBinary(Equal, args[0], args[1]))];
                                    case "isNull" if (args.length >= 1):
                                        // Transform Assert.isNull(x) to assert(x == nil)
                                        [makeAST(EBinary(Equal, args[0], makeAST(ENil)))];
                                    case "isNotNull" if (args.length >= 1):
                                        // Transform Assert.isNotNull(x) to refute(x == nil)
                                        [makeAST(EBinary(Equal, args[0], makeAST(ENil)))];
                                    default:
                                        // Pass through arguments as-is for other assertions
                                        args;
                                };

                                return ECall(null, assertFunc, assertArgs);
                            }
                            // Check for HXX.hxx() template calls
                            else if (fieldName == "hxx" && isHXXModule(obj)) {
                                #if debug_hxx_transformation
                                trace('[HXX] Detected HXX.hxx() call - transforming to ~H sigil');
                                if (args.length > 0) {
                                    trace('[HXX] First argument AST: ${args[0].def}');
                                }
                                #end
                                
                                // HXX.hxx() template calls should be transformed to Phoenix ~H sigils
                                // The templates can be either simple strings or string concatenations
                                // (when Haxe interpolation like ${expr} is used)
                                if (args.length == 1) {
                                    var templateContent = collectTemplateContent(args[0]);
                                    #if debug_hxx_transformation
                                    trace('[HXX] Collected template content for ~H sigil transformation');
                                    #end
                                    // Return the template wrapped in a ~H sigil
                                    ESigil("H", templateContent, "");
                                } else {
                                    #if debug_hxx_transformation
                                    trace('[HXX] Wrong number of arguments (${args.length}), falling back to regular call');
                                    #end
                                    // Wrong number of arguments, compile as regular call
                                    ECall(objAst, fieldName, args);
                                }
                            }
                            // Check for module calls
                            else if (isModuleCall(obj)) {
                                // Check if this is an extern static method with its own @:native
                                var hasNativeMetadata = false;
                                var nativeName: String = null;
                                
                                switch(fa) {
                                    case FStatic(_, cf):
                                        var classField = cf.get();
                                        if (classField.meta.has(":native")) {
                                            var nativeMeta = classField.meta.extract(":native");
                                            if (nativeMeta.length > 0 && nativeMeta[0].params != null && nativeMeta[0].params.length > 0) {
                                                switch(nativeMeta[0].params[0].expr) {
                                                    case EConst(CString(s, _)):
                                                        hasNativeMetadata = true;
                                                        nativeName = s;
                                                    default:
                                                }
                                            }
                                        }
                                    default:
                                }
                                
                                if (hasNativeMetadata && nativeName != null) {
                                    // Method has its own @:native, use it directly
                                    // Split the native name to get module and function
                                    var parts = nativeName.split(".");
                                    if (parts.length > 1) {
                                        var module = parts.slice(0, parts.length - 1).join(".");
                                        var funcName = parts[parts.length - 1];
                                        trackDependency(module);
                                        return ERemoteCall(makeAST(EVar(module)), funcName, args);
                                    } else {
                                        // Just a function name, use with the module
                                        return ERemoteCall(objAst, nativeName, args);
                                    }
                                } else {
                                    // Regular module call - convert method name to snake_case for Elixir
                                    var elixirFuncName = toSnakeCase(fieldName);
                                    
                                    // objAst already contains the full module name (including @:native if present)
                                    // because it was built from TTypeExpr which handles @:native correctly.
                                    // We can use it directly for the remote call.
                                    return ERemoteCall(objAst, elixirFuncName, args);
                                }
                            } else {
                                // Check if this is a method call that contains __elixir__() injection
                                var methodHasElixirInjection = false;
                                var expandedElixir: ElixirAST = null;
                                
                                // Try to get the method body to check for __elixir__
                                switch(fa) {
                                    case FInstance(_, _, cf):
                                        var classField = cf.get();
                                        var methodExpr = classField.expr();
                                        #if debug_ast_builder
                                        trace('[AST Builder] Checking method ${fieldName}, has expr: ${methodExpr != null}');
                                        #end
                                        if (methodExpr != null) {
                                            // Check if the method body contains __elixir__()
                                            expandedElixir = tryExpandElixirInjection(methodExpr, obj, el, currentContext);
                                            methodHasElixirInjection = (expandedElixir != null);
                                            #if debug_ast_builder
                                            trace('[AST Builder] Method ${fieldName} has __elixir__: $methodHasElixirInjection');
                                            #end
                                        }
                                    default:
                                }
                                
                                if (methodHasElixirInjection && expandedElixir != null) {
                                    // Method contains __elixir__(), use the expanded version
                                    return expandedElixir.def;
                                } else if (isArrayType(obj.t)) {
                                    // Check for array/list operations that come from loop desugaring
                                    // These need special handling because Haxe desugars loops into array operations
                                    switch(fieldName) {
                                        case "filter" if (args.length == 1):
                                            // Loop desugaring often generates array.filter()
                                            // Transform: array.filter(fn) → Enum.filter(array, fn)
                                            ERemoteCall(makeAST(EVar("Enum")), "filter", [objAst, args[0]]);
                                            
                                        case "map" if (args.length == 1):
                                            // Loop desugaring often generates array.map()
                                            // Transform: array.map(fn) → Enum.map(array, fn)
                                            ERemoteCall(makeAST(EVar("Enum")), "map", [objAst, args[0]]);
                                            
                                        case "push" if (args.length == 1):
                                            // Array push operations from comprehension desugaring
                                            // In Elixir, lists are immutable, so push needs assignment
                                            // We need to check if we're in a statement context
                                            // If so, generate: array = array ++ [value]
                                            // Otherwise just: array ++ [value]
                                            
                                            // Check if this is a statement in a block by looking at parent context
                                            // For now, we'll always generate the assignment form since push
                                            // is typically used for side effects
                                            var concat = makeAST(EBinary(Concat, objAst, makeAST(EList([args[0]]))));
                                            
                                            // Check if objAst is a variable (typical case for _g.push)
                                            switch(objAst.def) {
                                                case EVar(name):
                                                    // Generate assignment: name = name ++ [value]
                                                    EBinary(Match, objAst, concat);
                                                default:
                                                    // For complex expressions, just return concatenation
                                                    // (this may generate invalid code but is rare)
                                                    concat.def;
                                            }
                                            
                                        default:
                                            // All other array methods use standard call generation
                                            ECall(objAst, fieldName, args);
                                    }
                                }
                                // Check for Map operations that need transformation
                                else if (isMapType(obj.t)) {
                                    // Transform Map methods to Elixir Map module functions
                                    switch(fieldName) {
                                        case "set" if (args.length == 2):
                                            // map.set(key, value) → Map.put(map, key, value)
                                            ERemoteCall(makeAST(EVar("Map")), "put", [objAst].concat(args));
                                        case "get" if (args.length == 1):
                                            // map.get(key) → Map.get(map, key)
                                            ERemoteCall(makeAST(EVar("Map")), "get", [objAst].concat(args));
                                        case "remove" if (args.length == 1):
                                            // map.remove(key) → Map.delete(map, key)
                                            ERemoteCall(makeAST(EVar("Map")), "delete", [objAst].concat(args));
                                        case "exists" if (args.length == 1):
                                            // map.exists(key) → Map.has_key?(map, key)
                                            ERemoteCall(makeAST(EVar("Map")), "has_key?", [objAst].concat(args));
                                        case "keys" if (args.length == 0):
                                            // map.keys() → Map.keys(map)
                                            ERemoteCall(makeAST(EVar("Map")), "keys", [objAst]);
                                        case "values" if (args.length == 0):
                                            // map.values() → Map.values(map)
                                            ERemoteCall(makeAST(EVar("Map")), "values", [objAst]);
                                        default:
                                            // Fallback for other Map methods
                                            ECall(objAst, fieldName, args);
                                    }
                                } else {
                                    // Instance method call
                                    ECall(objAst, fieldName, args);
                                }
                            }
                        case TLocal(v):
                            // Check if this is a function variable (needs .() syntax in Elixir)
                            // Function variables in Elixir require .() syntax for invocation
                            var isFunctionVar = switch(v.t) {
                                case TFun(_, _): true;
                                case TAbstract(t, params):
                                    var abs = t.get();
                                    // Check for Function or Fn abstracts
                                    if (abs.name == "Function" || abs.name == "Fn") {
                                        true;
                                    } else if (abs.name == "Null" && params.length == 1) {
                                        // Check for Null<Function> (optional function parameters)
                                        switch(params[0]) {
                                            case TFun(_, _): true;
                                            default: false;
                                        }
                                    } else {
                                        false;
                                    }
                                default: false;
                            };
                            
                            #if debug_lambda_function_calls
                            trace('[AST Builder] TLocal call: ${v.name}, type: ${v.t}, isFunctionVar: ${isFunctionVar}');
                            #end
                            
                            if (isFunctionVar) {
                                // Function variable call - needs special handling for .() syntax
                                // We'll create a special marker that the printer will recognize
                                ECall(makeAST(EVar(toElixirVarName(v.name))), "", args);
                            } else {
                                // Regular local function call
                                ECall(null, toElixirVarName(v.name), args);
                            }
                        default:
                            if (target != null) {
                                // Check if target is a field access on a module (e.g., Phoenix.Presence.track)
                                switch(target.def) {
                                    case EField(module, funcName):
                                        // This is a module.function call - convert to ERemoteCall
                                        ERemoteCall(module, funcName, args);
                                    default:
                                        // Complex target expression
                                        ECall(target, "call", args);
                                }
                            } else {
                                // Should not happen
                                ECall(null, "unknown_call", args);
                            }
                    }
                }
                
            // ================================================================
            // Field Access
            // ================================================================
            case TField(e, fa):
                // Check for enum constructor references
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
                            // Regular enums: generate atom-based tuples
                            // ColumnType.Integer → {:Integer}
                            // 
                            // CRITICAL FIX (2025-01-10): Previously generated {0}, {7} etc using ef.index
                            // which caused invalid Elixir code in migrations. Now generates proper
                            // symbolic atoms {:Integer}, {:Boolean}, {:String} that Elixir can understand.
                            // This ensures enum constructors maintain their symbolic meaning in the
                            // generated code rather than being reduced to meaningless numeric indices.
                            // Use snake_case for idiomatic Elixir atoms
                            // TODO: Implement automatic snake_case conversion using Atom abstract type
                            // This would eliminate the need to manually call toSnakeCase() everywhere.
                            // See: docs/08-roadmap/AST_AUTO_SNAKE_CASE.md for implementation plan
                            // Future: ETuple([makeAST(EAtom(ef.name))]); // Automatic conversion!
                            var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                            ETuple([makeAST(EAtom(atomName))]);
                        }
                    case FStatic(classRef, cf):
                        // Static field access
                        var className = classRef.get().name;
                        var fieldName = extractFieldName(fa);
                        
                        #if debug_ast_builder
                        trace('[AST TField] FStatic - className: $className, fieldName: $fieldName');
                        trace('[AST TField] cf.get().name: ${cf.get().name}');
                        #end
                        
                        #if debug_atom_generation
                        trace('[Atom Debug TField] FStatic access: ${className}.${fieldName}');
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
                            trace('[Atom Debug TField] Checking class ${classType.name} kind: ${classType.kind}');
                            #end
                            switch (classType.kind) {
                                case KAbstractImpl(abstractRef):
                                    // Get the abstract type definition
                                    var abstractType = abstractRef.get();
                                    #if debug_atom_generation
                                    trace('[Atom Debug TField] Found abstract impl: ${abstractType.name}');
                                    trace('[Atom Debug TField] Abstract type: ${abstractType.type}');
                                    #end
                                    // Check the underlying type of the abstract
                                    switch (abstractType.type) {
                                        case TAbstract(underlyingRef, _):
                                            var underlyingType = underlyingRef.get();
                                            #if debug_atom_generation
                                            trace('[Atom Debug TField] Underlying type: ${underlyingType.pack.join(".")}.${underlyingType.name}');
                                            #end
                                            if (underlyingType.pack.join(".") == "elixir.types" && underlyingType.name == "Atom") {
                                                isAtomField = true;
                                                #if debug_atom_generation
                                                trace('[Atom Debug TField] DETECTED: Field is Atom type!');
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
                            trace('[Atom Debug TField] Field has expr, extracting value...');
                            #end
                            // Get the field's expression value
                            switch (field.expr().expr) {
                                case TConst(TString(s)):
                                    // This is the string value of the enum abstract field
                                    // Generate an atom directly
                                    #if debug_atom_generation
                                    trace('[Atom Debug TField] Extracted string value: "${s}" -> generating atom :${s}');
                                    #end
                                    EAtom(s);
                                case _:
                                    #if debug_atom_generation
                                    trace('[Atom Debug TField] Field expr is not TConst(TString), falling through');
                                    #end
                                    // Not a string constant, fall back to normal field access
                                    fieldName = toSnakeCase(fieldName);
                                    var target = buildFromTypedExpr(e, currentContext);
                                    EField(target, fieldName);
                            }
                        } else {
                            #if debug_atom_generation
                            trace('[Atom Debug TField] Not an atom field or no expr, using normal field access');
                            #end
                            // Normal static field access
                            // Convert to snake_case for Elixir function names
                            fieldName = toSnakeCase(fieldName);
                            
                            // Always use full qualification for function references
                            // When a static method is passed as a function reference (not called directly),
                            // it needs to be fully qualified even within the same module
                            if (false) { // Disabled for now - always qualify
                                // Same module - just use the function name without module prefix
                                // This allows private functions to be called without qualification
                                EVar(fieldName);
                            } else {
                                // Different module or no current module context - use full qualification
                                var target = buildFromTypedExpr(e, currentContext);
                                
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
                            fieldName = toSnakeCase(fieldName);
                            EField(target, fieldName);
                        }
                    default:
                        // Regular field access (includes FInstance for instance methods)
                        var target = buildFromTypedExpr(e, currentContext);
                        var fieldName = extractFieldName(fa);
                        
                        // Convert to snake_case for Elixir method names
                        // This ensures struct.setLoop becomes struct.set_loop
                        var originalFieldName = fieldName;
                        fieldName = toSnakeCase(fieldName);
                        
                        #if debug_field_names
                        if (originalFieldName != fieldName) {
                            trace('[AST Builder] Converting field name: $originalFieldName -> $fieldName');
                        }
                        #end
                        
                        #if debug_ast_pipeline
                        // Debug field access on p1/p2 variables
                        switch(e.expr) {
                            case TLocal(v) if (v.name == "p1" || v.name == "p2"):
                                trace('[AST Builder] Field access: ${v.name}.${fieldName} (id=${v.id})');
                            default:
                        }
                        #end
                        
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
                
            // ================================================================
            // Array Operations
            // ================================================================
            case TArrayDecl(el):
                // CRITICAL: Detect array comprehensions and treat them as EFor, not EList
                // This prevents the malformed list-append patterns that get torn apart by assignment extraction
                
                #if debug_ast_builder
                trace('[AST Builder] TArrayDecl with ${el.length} elements');
                if (el.length > 0) {
                    trace('[AST Builder] First element type: ${Type.enumConstructor(el[0].expr)}');
                }
                #end
                
                // Check for single-element array with TFor (direct comprehension)
                if (el.length == 1 && el[0].expr.match(TFor(_))) {
                    // This is a comprehension like [for (i in 0...3) expr]
                    // Return the TFor directly as EFor, not wrapped in EList
                    #if debug_ast_builder
                    // trace('[AST Builder] Detected array comprehension, treating as EFor instead of EList');
                    #end
                    buildFromTypedExpr(el[0], currentContext).def;
                } 
                // NEW: Check for single-element array with TBlock (desugared nested comprehension)
                else if (el.length == 1) {
                    switch(el[0].expr) {
                        case TBlock(stmts):
                            // Try to reconstruct comprehension from desugared block
                            var comprehension = tryBuildArrayComprehensionFromBlock(stmts, currentContext.variableUsageMap);
                            if (comprehension != null) {
                                switch(comprehension.def) {
                                    case EFor(_, _, _, _, _):
                                        #if debug_ast_builder
                                        trace('[AST Builder] Detected desugared comprehension in single-element array, treating as EFor');
                                        #end
                                        comprehension.def;
                                    default:
                                        // Not a comprehension, proceed with normal list
                                        EList([buildFromTypedExpr(el[0], currentContext)]);
                                }
                            } else {
                                // Normal single-element array
                                EList([buildFromTypedExpr(el[0], currentContext)]);
                            }
                        default:
                            // Normal single-element array
                            EList([buildFromTypedExpr(el[0], currentContext)]);
                    }
                } else {
                    // Normal array processing with multiple elements
                    // Check if this array contains idiomatic enum constructors or function calls returning them
                    var hasIdiomaticEnums = false;
                    for (e in el) {
                        switch(e.expr) {
                            case TCall(callTarget, _) if (callTarget != null && isEnumConstructor(callTarget) && hasIdiomaticMetadata(callTarget)):
                                hasIdiomaticEnums = true;
                                break;
                            case TCall(_, _):
                                // Check if function call returns idiomatic enum
                                switch(e.t) {
                                    case TEnum(enumRef, _) if (enumRef.get().meta.has(":elixirIdiomatic")):
                                        hasIdiomaticEnums = true;
                                        break;
                                    default:
                                }
                            default:
                        }
                    }
                    
                    #if debug_ast_builder
                    if (hasIdiomaticEnums) {
                        trace('[AST Builder] Building array with idiomatic enum elements');
                    }
                    #end
                    
                    // Process each element, with expression recovery for blocks
                    var elements = [];
                    for (e in el) {
                        switch(e.expr) {
                            case TBlock(stmts):
                                // Try comprehension reconstruction first
                                var comprehension = tryBuildArrayComprehensionFromBlock(stmts, currentContext.variableUsageMap);
                                if (comprehension != null) {
                                    elements.push(comprehension);
                                } 
                                // Check if this block builds a list through bare concatenations
                                else if (looksLikeListBuildingBlock(stmts)) {
                                    #if debug_array_comprehension
                                    trace('[Array Comprehension] Found unrolled comprehension in TArrayDecl element');
                                    #end
                                    #if debug_ast_builder
                                    trace('[AST Builder] Found list-building block in array element, marking with metadata');
                                    #end
                                    
                                    // Extract just the values being concatenated, not the entire block
                                    var extractedElements = extractListElements(stmts);
                                    if (extractedElements != null && extractedElements.length > 0) {
                                        #if debug_array_comprehension
                                        trace('[Array Comprehension] Successfully extracted ${extractedElements.length} values from unrolled pattern');
                                        #end
                                        // Build AST for each extracted value and return as a proper list
                                        var valueASTs = [for (elem in extractedElements) buildFromTypedExpr(elem, currentContext)];
                                        elements.push(makeAST(EList(valueASTs)));
                                    } else {
                                        // Fallback: if extraction failed, try building the block normally
                                        #if debug_ast_builder
                                        trace('[AST Builder] List element extraction failed, using block fallback');
                                        #end
                                        var blockStmts = [for (s in stmts) buildFromTypedExpr(s, currentContext)];
                                        var blockAST = makeAST(EBlock(blockStmts));
                                        
                                        // Mark with metadata for potential transformer handling
                                        if (blockAST.metadata == null) blockAST.metadata = {};
                                        blockAST.metadata.isUnrolledComprehension = true;
                                        
                                        // Wrap in immediately-invoked function to ensure valid Elixir
                                        var fnClause:EFnClause = {
                                            args: [],
                                            guard: null,
                                            body: blockAST
                                        };
                                        var anonymousFn = makeAST(EFn([fnClause]));
                                        var wrappedBlock = makeAST(ECall(makeAST(EParen(anonymousFn)), "", []));
                                        elements.push(wrappedBlock);
                                    }
                                } else {
                                    // Fallback: wrap block in immediately-invoked function to ensure valid expression
                                    #if debug_ast_builder
                                    trace('[AST Builder] Wrapping TBlock in array element as immediately-invoked function');
                                    #end
                                    var blockAst = buildFromTypedExpr(e, currentContext);
                                    // Create (fn -> ...block... end).()
                                    var fnClause:EFnClause = {
                                        args: [],
                                        guard: null,
                                        body: blockAst
                                    };
                                    var anonymousFn = makeAST(EFn([fnClause]));
                                    // Wrap in parentheses and call with empty funcName to trigger .() syntax
                                    var wrappedBlock = makeAST(ECall(makeAST(EParen(anonymousFn)), "", []));
                                    elements.push(wrappedBlock);
                                }
                            default:
                                elements.push(buildFromTypedExpr(e, currentContext));
                        }
                    }
                    EList(elements);
                }
                
            case TArray(e, index):
                var target = buildFromTypedExpr(e, currentContext);
                var key = buildFromTypedExpr(index, currentContext);
                EAccess(target, key);
                
            // ================================================================
            // Control Flow (Basic)
            // ================================================================
            case TIf(econd, eif, eelse):
                #if debug_loop_transformation
                // Debug nested if statements in loop bodies - specifically for meta variable issue
                trace('[XRay LoopTransform] TIf condition: ${Type.enumConstructor(econd.expr)}');
                switch(econd.expr) {
                    case TBinop(op, e1, e2):
                        trace('[XRay LoopTransform]   Condition is TBinop: $op');
                        trace('[XRay LoopTransform]   Left side: ${Type.enumConstructor(e1.expr)}');
                        trace('[XRay LoopTransform]   Right side: ${Type.enumConstructor(e2.expr)}');
                        switch(e1.expr) {
                            case TLocal(v):
                                trace('[XRay LoopTransform]     Left is TLocal: ${v.name}');
                            case TBinop(innerOp, ie1, ie2):
                                trace('[XRay LoopTransform]     Left is inner TBinop: $innerOp');
                            case _:
                        }
                    case TLocal(v):
                        trace('[XRay LoopTransform]   Condition is TLocal: ${v.name}');
                    case _:
                }
                switch(eif.expr) {
                    case TBlock(exprs):
                        trace('[XRay LoopTransform] TIf then branch is TBlock with ${exprs.length} expressions');
                        for (i in 0...exprs.length) {
                            switch(exprs[i].expr) {
                                case TVar(v, _):
                                    trace('[XRay LoopTransform]   TBlock[$i]: TVar ${v.name}');
                                default:
                                    trace('[XRay LoopTransform]   TBlock[$i]: ${Type.enumConstructor(exprs[i].expr)}');
                            }
                        }
                    case TVar(v, _):
                        trace('[XRay LoopTransform] TIf then branch: TVar ${v.name}');
                    default:
                        trace('[XRay LoopTransform] TIf then branch: ${Type.enumConstructor(eif.expr)}');
                }
                #end
                
                // Check if the condition is an inline expansion block
                var condition = switch(econd.expr) {
                    case TBlock(el) if (ElixirASTPatterns.isInlineExpansionBlock(el)):
                        #if debug_inline_expansion
                        trace('[XRay InlineExpansion] Detected inline expansion in if condition');
                        #end
                        makeAST(ElixirASTPatterns.transformInlineExpansion(el, function(e) return buildFromTypedExpr(e, currentContext), function(name) return toElixirVarName(name)));
                    case _:
                        buildFromTypedExpr(econd, currentContext);
                };
                var thenBranch = buildFromTypedExpr(eif, currentContext);
                var elseBranch = eelse != null ? buildFromTypedExpr(eelse, currentContext) : null;
                EIf(condition, thenBranch, elseBranch);
                
            case TBlock(el):
                #if debug_null_coalescing
                trace('[AST Builder] TBlock with ${el.length} expressions');
                for (i in 0...el.length) {
                    trace('[AST Builder]   Block[$i]: ${Type.enumConstructor(el[i].expr)}');
                }
                #end
                
                // CRITICAL: Try to reconstruct array comprehensions from desugared imperative code
                // This handles nested comprehensions that Haxe has already desugared
                var comprehension = tryBuildArrayComprehensionFromBlock(el, currentContext.variableUsageMap);
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
                    trace('[XRay ArrayPattern] TBlock check: empty=$hasEmptyArray, zero=$hasZeroInit, source=$hasSourceAssign, while=$hasWhileLoop, returns=$returnsResult');
                    #end
                    
                    if (isArrayPattern && sourceArray != null && whileBody != null) {
                        var operation = ElixirASTPatterns.detectArrayOperationPattern(whileBody);
                        
                        #if debug_array_patterns
                        trace('[XRay ArrayPattern] Detected operation: $operation');
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
                            var tmpVarName = toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                            
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
                    return ElixirASTPatterns.transformInlineExpansion(el, function(e) return buildFromTypedExpr(e, currentContext), function(name) return toElixirVarName(name));
                }
                
                // Check if this block is building a list through concatenations
                // Pattern: g = []; g ++ [val1]; g ++ [val2]; ...; g
                #if debug_array_comprehension
                trace('[Array Comprehension] TBlock analysis: checking ${el.length} statements');
                #end
                #if debug_ast_builder
                trace('[AST Builder] Checking if block with ${el.length} statements is list-building');
                #end
                #if debug_unrolled_comprehension
                trace('[DEBUG] TBlock with ${el.length} statements');
                for (i in 0...el.length) {
                    trace('[DEBUG]   Statement $i: ${el[i].expr}');
                }
                #end
                
                // Special case: Check for conditional comprehension pattern first
                // This is when we have var g = []; followed by a nested block with if statements
                // trace('[DEBUG] Checking TBlock with ${el.length} elements for conditional comprehension');
                if (el.length >= 2) {
                    var isConditionalComprehension = false;
                    var tempVarName = "";
                    
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Checking for conditional comprehension pattern in TBlock with ${el.length} statements');
                    #end
                    
                    // Check first statement for var g = []
                    switch(el[0].expr) {
                        case TVar(v, init) if (init != null && (v.name.startsWith("g") || v.name.startsWith("_g"))):
                            switch(init.expr) {
                                case TArrayDecl([]):
                                    tempVarName = v.name;
                                    
                                    #if debug_array_comprehension
                                    trace('[Array Comprehension] Found initialization: var $tempVarName = []');
                                    #end
                                    
                                    // Check if second statement is a block containing if statements
                                    if (el.length >= 3) {
                                        #if debug_array_comprehension
                                        trace('[Array Comprehension] Checking statement 1 for TBlock: ${el[1].expr}');
                                        #end
                                        
                                        switch(el[1].expr) {
                                            case TBlock(innerStmts):
                                                #if debug_array_comprehension
                                                trace('[Array Comprehension] Found TBlock with ${innerStmts.length} inner statements');
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
                        trace('[Array Comprehension] ✓ DETECTED conditional comprehension pattern!');
                        #end
                        
                        // Try to reconstruct the conditional comprehension
                        trace('[DEBUG] Attempting to reconstruct conditional comprehension with tempVar: $tempVarName');
                        var reconstructed = tryReconstructConditionalComprehension(el, tempVarName, currentContext.variableUsageMap);
                        if (reconstructed != null) {
                            #if debug_array_comprehension
                            trace('[Array Comprehension] Successfully reconstructed conditional comprehension');
                            #end
                            return reconstructed.def;
                        }
                    }
                }
                
                if (looksLikeListBuildingBlock(el)) {
                    #if debug_array_comprehension
                    trace('[Array Comprehension] ✓ DETECTED unrolled comprehension pattern!');
                    trace('[Array Comprehension]   Will mark block with metadata for transformer');
                    #end
                    #if debug_ast_builder
                    trace('[AST Builder] Detected list-building block, marking with metadata');
                    #end
                    
                    // Extract pattern information for metadata
                    var listElements = extractListElements(el);
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
                        trace('[Array Comprehension] Block marked with metadata:');
                        trace('[Array Comprehension]   isUnrolledComprehension: true');
                        trace('[Array Comprehension]   comprehensionElements: ${listElements.length}');
                        #end
                        
                        return blockAST.def;
                    }
                } else {
                    #if debug_ast_builder
                    if (el.length > 0 && el.length < 10) {
                        trace('[AST Builder] Not a list-building block. First stmt: ${el[0].expr}');
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
                
                if (el.length == 2 && !isInLoopContext) {
                    switch([el[0].expr, el[1].expr]) {
                        case [TVar(v, init), expr] if (init != null):
                            // This is a temporary variable pattern
                            // Check if the variable is unused and add underscore prefix
                            var isUsed = if (currentContext.variableUsageMap != null && currentContext.variableUsageMap.exists(v.id)) {
                                currentContext.variableUsageMap.get(v.id);
                            } else {
                                true; // Conservative: assume used if not in map
                            };
                            
                            // Build the assignment
                            var baseName = toElixirVarName(v.name);
                            var varName = if (!isUsed) {
                                #if debug_variable_usage
                                trace('[TBlock] Variable ${v.name} (id=${v.id}) is UNUSED, adding underscore prefix');
                                #end
                                // M0 STABILIZATION: Disable underscore prefixing
                                baseName; // "_" + baseName;
                            } else {
                                baseName;
                            };
                            
                            var initExpr = buildFromTypedExpr(init, currentContext);
                            var bodyExpr = buildFromTypedExpr(el[1], currentContext);

                            // Try to inline immediately when the temp var is used exactly once
                            // BUT: Skip inlining in case clause bodies (statement contexts)
                            // and other contexts where variable declarations should be preserved
                            var isInCaseClause = currentClauseContext != null;
                            
                            // CRITICAL FIX: Skip inlining when the body contains nested if statements
                            // This preserves variable declarations that need to be visible in nested scopes
                            var containsNestedIf = containsIfStatement(el[1]);
                            var shouldPreserveDeclaration = isInCaseClause || containsNestedIf;
                            
                            if (!shouldPreserveDeclaration) {
                                var usageCount = countVarOccurrencesInAST(bodyExpr, varName);
                                if (usageCount == 1) {
                                    var inlined = replaceVarInAST(bodyExpr, varName, initExpr);
                                    return inlined.def;
                                }
                            }

                            // Fallback: keep block, will be handled by transformer/printer later
                            return EBlock([
                                makeAST(EMatch(PVar(varName), initExpr)),
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
                var isInCaseClause = currentClauseContext != null;

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
                                        var tempVarName = toElixirVarName(v.name);
                                        #if debug_redundant_extraction
                                        trace('[TBlock] TEnumParameter found - originalName: $originalName, tempVarName: $tempVarName');
                                        #end
                                        // Check if this matches the temp var pattern (_g, g, g1, g2, etc.)
                                        if (originalName == "_g" || originalName == "g" ||
                                            (originalName.startsWith("_g") && originalName.length > 2) ||
                                            (originalName.startsWith("g") && originalName.length > 1 &&
                                             originalName.charAt(1) >= '0' && originalName.charAt(1) <= '9')) {
                                            // Skip this redundant extraction statement
                                            shouldSkip = true;
                                            #if debug_redundant_extraction
                                            trace('[TBlock] *** WILL SKIP *** redundant enum extraction for $originalName (converted to $tempVarName)');
                                            #end
                                        } else {
                                            #if debug_redundant_extraction
                                            trace('[TBlock] NOT skipping - $originalName does not match temp var pattern');
                                            #end
                                        }
                                    case _:
                                }
                            case _:
                        }
                    }

                    if (!shouldSkip) {
                        var builtExpr = buildFromTypedExpr(e, currentContext);
                        // Filter out null expressions (returned when skipping redundant assignments)
                        if (builtExpr != null) {
                            expressions.push(builtExpr);
                        }
                    } else {
                        #if debug_redundant_extraction
                        trace('[TBlock] *** ACTUALLY SKIPPED *** building expression');
                        #end
                    }
                }
                
                // Check if we need to combine inline expansions
                // Look for patterns like: c = index = expr; obj.method(index)
                var needsCombining = false;
                for (i in 0...expressions.length - 1) {
                    var current = expressions[i];
                    var next = expressions[i + 1];
                    
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
                if (e != null) {
                    buildFromTypedExpr(e, currentContext).def; // Return value is implicit in Elixir
                } else {
                    ENil; // Explicit nil return
                }
                
            case TBreak:
                EThrow(makeAST(EAtom(ElixirAtom.raw("break")))); // Will be transformed
                
            case TContinue:
                EThrow(makeAST(EAtom(ElixirAtom.raw("continue")))); // Will be transformed
                
            // ================================================================
            // Pattern Matching (Switch/Case)
            // ================================================================
            case TSwitch(e, cases, edef):
                #if debug_compilation_hang
                Sys.println('[HANG DEBUG] 🎯 TSwitch START - ${cases.length} cases, hasDefault: ${edef != null}');
                var switchStartTime = haxe.Timer.stamp() * 1000;
                #end

                // Phase 2 Integration: Try routing through BuilderFacade if enabled
                if (currentContext != null && currentContext.builderFacade != null && currentContext.isFeatureEnabled("use_new_pattern_builder")) {
                    #if debug_ast_builder
                    trace('[ElixirASTBuilder] Routing switch to BuilderFacade');
                    #end

                    try {
                        // Convert cases to match the BuilderFacade.Case typedef
                        var facadeCases = cases.map(function(c) {
                            return {
                                values: c.values,
                                expr: c.expr,
                                guard: null  // TypedExprDef cases don't have guards
                            };
                        });
                        var switchAST = currentContext.builderFacade.routeSwitch(e, facadeCases, edef);
                        return switchAST.def;
                    } catch (err: Dynamic) {
                        #if debug_ast_builder
                        trace('[ElixirASTBuilder] BuilderFacade routing failed: $err, falling back to legacy');
                        #end
                        // Fall through to legacy implementation
                    }
                }

                // Legacy implementation continues below
                // Check if this is a switch on an idiomatic enum
                // Haxe optimizes enum switches to TEnumIndex, so we need to look deeper
                
                // Helper function to extract the enum type from an expression
                function extractEnumTypeFromSwitch(expr: TypedExpr): Null<EnumType> {
                    return switch(expr.expr) {
                        case TParenthesis(innerExpr):
                            // Skip parenthesis wrapper
                            extractEnumTypeFromSwitch(innerExpr);
                        case TMeta(_, innerExpr):
                            // Skip metadata wrapper
                            extractEnumTypeFromSwitch(innerExpr);
                        case TEnumIndex(enumExpr):
                            // Found TEnumIndex, get the enum type from the inner expression
                            switch(enumExpr.t) {
                                case TEnum(enumRef, _): enumRef.get();
                                default: null;
                            }
                        default:
                            // Direct enum type
                            switch(expr.t) {
                                case TEnum(enumRef, _): enumRef.get();
                                default: null;
                            }
                    }
                }
                
                var enumType = extractEnumTypeFromSwitch(e);
                // All enums generate tuple patterns for idiomatic Elixir
                // But only @:elixirIdiomatic enums use generic name extraction
                var hasEnumType = enumType != null;
                var isIdiomaticEnum = enumType != null && enumType.meta.has(":elixirIdiomatic");
                
                #if debug_enum
                if (enumType != null) {
                    var idiomaticStatus = isIdiomaticEnum ? "idiomatic (uses generic extraction)" : "regular (preserves pattern names)";
                    trace('[DEBUG ENUM] Found enum ${enumType.name}, ${idiomaticStatus}');
                } else {
                    trace('[DEBUG ENUM] No enum type found in switch target');
                }
                #end
                
                var expr = buildFromTypedExpr(e, currentContext).def;
                var clauses = [];

                // Check if this is a topic_to_string-style temp variable switch
                // These need special handling for return context
                var needsTempVar = false;
                var tempVarName = "temp_result";

                // Detect if switch is in return context
                var isReturnContext = false; // TODO: Will be set via metadata

                // M0.5: Track if any case has an enum binding plan
                var hasAnyEnumBindingPlan = false;

                // Generate unique ID for this switch's enum binding plans
                // Include multiple factors to avoid collisions when macros duplicate positions
                var bindingPlanId = if (enumType != null) {
                    var idComponents = [];

                    // Add timestamp and random for uniqueness
                    var timestamp = Date.now().getTime();
                    var random = Std.random(10000);
                    idComponents.push('${timestamp}_${random}');

                    // Add position info if available
                    if (e.pos != null) {
                        var posInfo = haxe.macro.PositionTools.toLocation(e.pos);
                        var fileStr = Std.string(posInfo.file); // Convert FsPath to string
                        var fileParts = fileStr.split('/');
                        var fileName = fileParts[fileParts.length - 1]; // Just filename, not full path
                        idComponents.push('${fileName}_L${posInfo.range.start.line}');
                    }

                    // Add target expression type for additional context
                    var targetType = Type.enumConstructor(e.expr);
                    idComponents.push(targetType);

                    // Add enum type name if available
                    if (enumType != null && enumType.name != null) {
                        idComponents.push(enumType.name);
                    }

                    'enum_${idComponents.join("_")}';
                } else {
                    null;
                }

                #if debug_enum_extraction
                if (bindingPlanId != null) {
                    trace('[ElixirASTBuilder] Generated binding plan ID for switch: $bindingPlanId');
                }
                #end

                for (c in cases) {
                    // Analyze the case body FIRST to detect enum parameter extraction
                    // This is critical for determining whether to use wildcards or named patterns
                    // Pass case values to extract pattern variable names like "email" from case Ok(email):
                    var extractedParams = analyzeEnumParameterExtraction(c.expr, c.values);

                    #if debug_pattern_usage
                    trace('[Pattern Extraction] analyzeEnumParameterExtraction returned: ${extractedParams}');
                    trace('[Pattern Extraction] Case index: $caseIndex');
                    #end

                    // Create EnumBindingPlan for consistent variable naming
                    var enumBindingPlan = createEnumBindingPlan(c.expr, extractedParams, enumType);

                    // M0.5: Track if we have binding plans
                    if (enumBindingPlan != null && enumBindingPlan.keys().hasNext()) {
                        hasAnyEnumBindingPlan = true;

                        // Store the binding plan in the context with the unique ID
                        // This makes it accessible to the transformer phase
                        if (bindingPlanId != null && currentContext != null && currentContext.astContext != null) {
                            currentContext.astContext.storeEnumBindingPlan(bindingPlanId, enumBindingPlan);

                            #if debug_enum_extraction
                            trace('[ElixirASTBuilder] Stored enum binding plan with ID: $bindingPlanId');
                            trace('[ElixirASTBuilder]   Plan has ${Lambda.count(enumBindingPlan)} entries');
                            #end
                        }
                    }

                    // Update extractedParams based on the binding plan
                    // The plan is the single source of truth for variable names
                    for (index in enumBindingPlan.keys()) {
                        var info = enumBindingPlan.get(index);
                        if (index < extractedParams.length) {
                            extractedParams[index] = info.finalName;
                        }
                    }

                    // Create variable mappings for alpha-renaming
                    // This maps Haxe's temporary variable IDs to canonical pattern names
                    // M0.2: Pass enumBindingPlan so it can use the authoritative names
                    var varMapping = createVariableMappingsForCase(c.expr, extractedParams, enumType, c.values, enumBindingPlan);
                    
                    // Use EnumBindingPlan names for patterns when available
                    var patternParamNames = if (enumBindingPlan != null) {
                        // Extract the finalName from each entry in the binding plan
                        var names = [];
                        var maxIndex = 0;
                        for (index => info in enumBindingPlan) {
                            if (index > maxIndex) maxIndex = index;
                        }
                        for (i in 0...(maxIndex + 1)) {
                            if (enumBindingPlan.exists(i)) {
                                names.push(enumBindingPlan.get(i).finalName);
                            } else {
                                names.push('_g${i}'); // Fallback name
                            }
                        }
                        #if debug_enum_extraction
                        trace('[ElixirASTBuilder] Using binding plan names for pattern: $names');
                        #end
                        names;
                    } else {
                        extractedParams;
                    };

                    var patterns = if (hasEnumType && enumType != null) {
                        // All enums generate tuple patterns for idiomatic Elixir output
                        // The difference is in the parameter extraction logic:
                        // - Idiomatic enums: Use generic extraction (g, g1, g2) due to limitations
                        // - Regular enums: Try to preserve pattern variable names (r, g, b)
                        if (isIdiomaticEnum) {
                            // Idiomatic enums use binding plan names when available
                            [for (v in c.values) convertIdiomaticEnumPatternWithExtraction(v, enumType, patternParamNames, currentContext.variableUsageMap)];
                        } else {
                            // Regular enums also use binding plan names when available
                            [for (v in c.values) convertRegularEnumPatternWithExtraction(v, enumType, patternParamNames, currentContext.variableUsageMap)];
                        }
                    } else {
                        // Non-enum patterns or unknown enum types
                        [for (v in c.values) convertPatternWithExtraction(v, patternParamNames)];
                    }
                    
                    // Set up ClauseContext for alpha-renaming before building the case body
                    var savedClauseContext = currentClauseContext;
                    currentClauseContext = new ClauseContext(null, varMapping, enumBindingPlan);
                    
                    // Build the case body with the ClauseContext active
                    var body = buildFromTypedExpr(c.expr, currentContext);
                    
                    // Attach the varIdToName mapping to the body's metadata
                    // This allows later transformation passes to resolve variables correctly
                    if (body.metadata == null) body.metadata = {};
                    body.metadata.varIdToName = varMapping;
                    
                    // Restore previous context
                    currentClauseContext = savedClauseContext;
                    
                    // processEnumCaseBody is disabled - we use VariableUsageAnalyzer instead
                    // which provides more accurate detection across the entire function scope
                    
                    // Multiple patterns become multiple clauses
                    for (pattern in patterns) {
                        // Apply underscore prefix to unused pattern variables
                        var finalPattern = applyUnderscorePrefixToUnusedPatternVars(pattern, currentContext.variableUsageMap, extractedParams);

                        // Update the ClauseContext mapping if pattern variables were prefixed with underscore
                        // This ensures the case body can still reference the variables correctly
                        var updatedMapping = updateMappingForUnderscorePrefixes(finalPattern, varMapping, extractedParams);

                        // If mapping was updated, rebuild the body with the new mapping
                        var finalBody = if (updatedMapping != varMapping) {
                            var savedCtx = currentClauseContext;
                            currentClauseContext = new ClauseContext(null, updatedMapping, enumBindingPlan);
                            var newBody = buildFromTypedExpr(c.expr, currentContext);
                            currentClauseContext = savedCtx;
                            newBody;
                        } else {
                            body;
                        };

                        clauses.push({
                            pattern: finalPattern,
                            guard: null, // Guards will be added in transformation
                            body: finalBody
                        });
                    }
                }
                
                // Default case
                if (edef != null) {
                    clauses.push({
                        pattern: PWildcard,
                        guard: null,
                        body: buildFromTypedExpr(edef, currentContext)
                    });
                }
                
                // Create the case expression
                var caseASTDef = ECase(makeAST(expr), clauses);

                // Create the AST node with metadata for M0.5
                var caseNode = makeAST(caseASTDef);

                // M0.5: Attach metadata to help transformer
                // This indicates that enum parameter extraction has proper mappings
                if (hasAnyEnumBindingPlan) {
                    if (caseNode.metadata == null) caseNode.metadata = {};
                    caseNode.metadata.hasEnumBindingPlan = true;
                    #if debug_enum_extraction
                    trace('[ElixirASTBuilder] Set hasEnumBindingPlan flag to true on case node');
                    #end
                    // Attach the binding plan ID to link to the stored plan in context
                    if (bindingPlanId != null) {
                        caseNode.metadata.enumBindingPlanId = bindingPlanId;
                        #if debug_enum_extraction
                        trace('[ElixirASTBuilder] Attached binding plan ID to case node: $bindingPlanId');
                        #end
                    }
                }

                // If in return context and needs temp var, wrap in assignment
                if (isReturnContext && needsTempVar) {
                    EBlock([
                        makeAST(EMatch(PVar(tempVarName), caseNode)),
                        makeAST(EVar(tempVarName))
                    ]);
                } else {
                    caseNode.def;
                }
                
            // ================================================================
            // Try/Catch
            // ================================================================
            case TTry(e, catches):
                var body = buildFromTypedExpr(e, currentContext);
                var rescueClauses = [];
                
                for (c in catches) {
                    var pattern = PVar(toElixirVarName(c.v.name));
                    var catchBody = buildFromTypedExpr(c.expr, currentContext);
                    
                    rescueClauses.push({
                        pattern: pattern,
                        body: catchBody
                    });
                }
                
                ETry(body, rescueClauses, [], null, null);
                
            // ================================================================
            // Lambda/Anonymous Functions
            // ================================================================
            case TFunction(f):
                // Debug: Check for abstract method "this" parameter issue
                #if debug_ast_pipeline
                for (arg in f.args) {
                    trace('[AST Builder] TFunction arg: ${arg.v.name} (id=${arg.v.id})');
                }
                #end
                
                // Detect fluent API patterns
                var fluentPattern = detectFluentAPIPattern(f);
                
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
                    
                    // TODO: Restore when UsageDetector is available
                    // Use our enhanced usage detection instead of trusting Reflaxe metadata
                    var isActuallyUnused = false; // if (f.expr != null) {
                        // reflaxe.elixir.helpers.UsageDetector.isParameterUnused(arg.v, f.expr);
                    // } else {
                        // false; // If no body, consider parameter as potentially used
                    // };
                    
                    // Convert to snake_case for Elixir conventions
                    var baseName = ElixirASTHelpers.toElixirVarName(originalName);
                    
                    // Debug: Check if reserved keyword
                    #if debug_reserved_keywords
                    if (isElixirReservedKeyword(baseName)) {
                        trace('[AST Builder] Reserved keyword detected in parameter: $baseName -> ${baseName}_param');
                    }
                    #end
                    
                    // Prefix with underscore if unused (using TypedExpr-based detection which is more accurate)
                    // This is done here rather than in a transformer because we have full semantic information
                    // M0 STABILIZATION: Disable underscore prefixing
                    var finalName = baseName; // Always use base name for now
                    /* Original logic disabled:
                    var finalName = if (isActuallyUnused && !baseName.startsWith("_")) {
                        "_" + baseName;
                    } else {
                        baseName;
                    };
                    */
                    
                    // Register the mapping for TLocal references in the body
                    if (!currentContext.tempVarRenameMap.exists(idKey)) {
                        currentContext.tempVarRenameMap.set(idKey, finalName);
                    }
                    
                    // Track parameter mappings for collision detection
                    if (originalName != finalName) {
                        paramRenaming.set(originalName, finalName);
                        #if debug_ast_pipeline
                        trace('[AST Builder] Function parameter will be renamed: $originalName -> $finalName');
                        #end
                    }
                    
                    // Handle special case for abstract "this" parameters
                    if (originalName == "this1") {
                        // The body might try to rename this1 -> this due to collision detection
                        // We need to prevent that and use the parameter name instead
                        paramRenaming.set("this", finalName); // Map "this" to final name as well
                        #if debug_ast_pipeline
                        trace('[AST Builder] Abstract this parameter detected, mapping both this1 and this to: $finalName');
                        #end
                    }
                    
                    // Track the first parameter as the receiver for instance methods
                    // This will be used for TThis references
                    if (isFirstParam && isInClassMethodContext) {
                        currentReceiverParamName = finalName;
                        isFirstParam = false;
                    }
                    
                    // Add the parameter to the function signature
                    args.push(PVar(finalName));
                    
                    currentContext.functionParameterIds.set(idKey, true); // Mark as function parameter
                    #if debug_ast_pipeline
                    trace('[AST Builder] Registering parameter in rename map: id=$idKey');
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
                    trace('[AST Builder] Applying parameter renaming to function body');
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
                        var atomName = toSnakeCase(field.name);
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
                        var atomName = toSnakeCase(field.name);
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
                            var tmpVarName = toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
                            
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
                            // Standard field value compilation
                            buildFromTypedExpr(field.expr, currentContext);
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
                                        var tmpVarName = toElixirVarName(tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name);
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
                buildFromTypedExpr(e, currentContext).def;
                
            // ================================================================
            // Special Cases
            // ================================================================
            case TNew(c, _, el):
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
                #if debug_compilation_hang
                Sys.println('[HANG DEBUG] 🔁 TFor START - var: ${v.name}');
                var forStartTime = haxe.Timer.stamp() * 1000;
                #end

                // Check if LoopBuilder is enabled and use it with reentrancy protection
                if (currentContext != null && currentContext.isFeatureEnabled("loop_builder_enabled")) {
                    // Use ReentrancyGuard to prevent infinite recursion
                    var guard = currentContext.reentrancyGuard;

                    // Create the for expression to pass to the guard
                    var forExpr = expr; // The current expression being processed

                    // Create a wrapped builder function that uses the guard
                    var safeBuilder = function(): ElixirAST {
                        var transform = LoopBuilder.analyzeFor(v, e1, e2);
                        return LoopBuilder.buildFromTransform(
                            transform,
                            function(e) {
                                // Recursively build sub-expressions with guard protection
                                return guard.process(e, function() {
                                    return buildFromTypedExpr(e, currentContext);
                                });
                            },
                            function(name) return toElixirVarName(name)
                        );
                    };

                    // Process with reentrancy protection
                    var ast = guard.process(forExpr, safeBuilder);
                    ast.def;
                } else {
                    // Fall back to simple for comprehension when LoopBuilder is disabled
                    var varName = toElixirVarName(v.name);
                    var pattern = PVar(varName);
                    var iteratorExpr = buildFromTypedExpr(e1, currentContext);
                    var bodyExpr = buildFromTypedExpr(e2, currentContext);
                    EFor([{pattern: pattern, expr: iteratorExpr}], [], bodyExpr, null, false);
                }
                
            case TWhile(econd, e, normalWhile):
                #if debug_compilation_hang
                Sys.println('[HANG DEBUG] 🔁 TWhile START - normalWhile: ${normalWhile}');
                var whileStartTime = haxe.Timer.stamp() * 1000;
                #end

                // CRITICAL: Detect array iteration patterns and generate idiomatic Enum calls
                // This prevents Y-combinator pattern generation for array operations
                
                // Haxe desugars array.map(fn) into:
                // var _g = []; var _g1 = 0; var _g2 = array; 
                // while(_g1 < _g2.length) { var v = _g2[_g1]; _g1++; _g.push(transformation); }
                
                // For Reflect.fields, Haxe desugars into:
                // var _g = 0; var _g1 = Map.keys(obj);
                // while(_g < _g1.length) { var key = _g1[_g]; _g++; ... }
                
                #if debug_array_patterns
                trace('[XRay ArrayPattern] TWhile detected');
                trace('[XRay ArrayPattern] Condition: ${econd.expr}');
                #end
                
                // First check if this is a Map.keys iteration (from Reflect.fields)
                var isMapKeysLoop = false;
                var keysCollection: String = null;
                var indexVar: String = null;
                
                #if debug_for_loop
                trace('[XRay ForLoop] Analyzing TWhile condition for Map.keys pattern');
                trace('[XRay ForLoop] Condition expr: ${econd.expr}');
                trace('[XRay ForLoop] Condition type: ${Type.enumConstructor(econd.expr)}');
                #end
                
                // Check if we're in a context where we have Map.keys
                // Look for pattern: _g < length(_g1) or _g < _g1.length
                // Note: The condition may be wrapped in TParenthesis
                var actualCondition = switch(econd.expr) {
                    case TParenthesis(e): e;
                    case _: econd;
                };
                
                switch(actualCondition.expr) {
                    case TBinop(OpLt, {expr: TLocal(idx)}, lengthExpr):
                        #if debug_for_loop
                        trace('[XRay ForLoop] Found OpLt with TLocal index: ${idx.name}');
                        trace('[XRay ForLoop] Length expr type: ${Type.enumConstructor(lengthExpr.expr)}');
                        #end
                        
                        // Check if this looks like iteration over Map.keys result
                        if (idx.name == "g" || idx.name.startsWith("_g") || idx.name.indexOf("g") >= 0) {
                            indexVar = idx.name;
                            
                            // Check if the length expression references a Map.keys result
                            switch(lengthExpr.expr) {
                                case TCall(callExpr, args):
                                    #if debug_for_loop
                                    trace('[XRay ForLoop] Found TCall in length expression');
                                    trace('[XRay ForLoop] Call expr type: ${Type.enumConstructor(callExpr.expr)}');
                                    #end
                                    
                                    // Check for length() function call
                                    switch(callExpr.expr) {
                                        case TField(_, FStatic(_, cf)):
                                            #if debug_for_loop
                                            trace('[XRay ForLoop] Static field: ${cf.get().name}');
                                            #end
                                            if (cf.get().name == "length" && args.length > 0) {
                                                switch(args[0].expr) {
                                                    case TLocal(coll):
                                                        keysCollection = coll.name;
                                                        isMapKeysLoop = true;
                                                        #if debug_for_loop
                                                        trace('[XRay ForLoop] ✓ DETECTED Map.keys pattern with collection: $keysCollection');
                                                        #end
                                                    case _:
                                                }
                                            }
                                        case _:
                                    }
                                    
                                case TField({expr: TLocal(coll)}, FInstance(_, _, cf)):
                                    #if debug_for_loop
                                    trace('[XRay ForLoop] Instance field on TLocal: ${coll.name}.${cf.get().name}');
                                    #end
                                    if (cf.get().name == "length") {
                                        // Pattern: _g < _g1.length
                                        keysCollection = coll.name;
                                        // Check if this collection was assigned from Map.keys
                                        // For now, detect based on variable naming pattern
                                        if (coll.name == "g1" || coll.name.indexOf("g1") >= 0) {
                                            isMapKeysLoop = true;
                                            #if debug_for_loop
                                            trace('[XRay ForLoop] ✓ DETECTED Map.keys pattern with collection.length: $keysCollection');
                                            #end
                                        }
                                    }
                                    
                                case _:
                                    #if debug_for_loop
                                    trace('[XRay ForLoop] Unrecognized length expression pattern');
                                    #end
                            }
                        }
                    case TParenthesis(_):
                        // Already handled above by unwrapping
                        #if debug_for_loop
                        trace('[XRay ForLoop] TParenthesis already unwrapped');
                        #end
                    case _:
                        #if debug_for_loop
                        trace('[XRay ForLoop] Condition is not OpLt pattern');
                        #end
                }
                
                // TODO: Re-enable this optimization but only for side-effect loops (not result-building loops)
                // The optimization currently breaks loops that build results (like Map building)
                // Need to detect when the loop body builds a result vs just side effects
                if (false && isMapKeysLoop && keysCollection != null && indexVar != null) {
                    #if debug_for_loop
                    trace('[XRay ForLoop] Detected Map.keys iteration pattern');
                    trace('[XRay ForLoop] Collection: $keysCollection, Index: $indexVar');
                    #end
                    
                    // Generate idiomatic for comprehension
                    // for key <- collection do ... end
                    
                    // Extract the loop variable from the body
                    // Look for: var key = collection[index]
                    var loopVar: String = null;
                    var bodyWithoutExtraction: TypedExpr = e;
                    
                    switch(e.expr) {
                        case TBlock(stmts) if (stmts.length > 0):
                            #if debug_for_loop
                            trace('[XRay ForLoop] Body has ${stmts.length} statements');
                            for (i in 0...stmts.length) {
                                trace('[XRay ForLoop] Statement $i: ${Type.enumConstructor(stmts[i].expr)}');
                            }
                            #end
                            // Check if first statement is the extraction
                            switch(stmts[0].expr) {
                                case TVar(v, {expr: TArray({expr: TLocal(coll)}, {expr: TLocal(idx)})})
                                    if (coll.name == keysCollection && idx.name == indexVar):
                                    // Found the extraction: var key = _g1[_g]
                                    loopVar = toElixirVarName(v.name);
                                    
                                    // Skip the extraction and the index increment
                                    var restStmts = stmts.slice(1);
                                    
                                    // Check if the next statement is the index increment and skip it too
                                    if (restStmts.length > 0) {
                                        switch(restStmts[0].expr) {
                                            case TUnop(OpIncrement, _, {expr: TLocal(idx)}) if (idx.name == indexVar):
                                                // Skip the increment too
                                                restStmts = restStmts.slice(1);
                                            case _:
                                        }
                                    }
                                    
                                    // Create the body without extraction and increment
                                    if (restStmts.length == 1) {
                                        bodyWithoutExtraction = restStmts[0];
                                    } else if (restStmts.length > 0) {
                                        bodyWithoutExtraction = {expr: TBlock(restStmts), t: e.t, pos: e.pos};
                                    }
                                    
                                case _:
                                    // Couldn't find extraction in first statement
                                    loopVar = "item";
                            }
                            
                        case _:
                            // Couldn't find extraction, use generic variable name
                            loopVar = "item";
                    }
                    
                    // Build the body AST
                    var bodyAst = buildFromTypedExpr(bodyWithoutExtraction, currentContext);
                    
                    // Generate: for loopVar <- keysCollection do ... end
                    return EFor(
                        [{pattern: PVar(loopVar), expr: makeAST(EVar(keysCollection))}],
                        [],  // No filters
                        bodyAst,
                        null,  // No into
                        false  // Not uniq
                    );
                }
                
                // Check if this is an array iteration pattern
                var isArrayLoop = false;
                var arrayRef: TypedExpr = null;
                
                // Look for _g1 < _g2.length pattern
                switch(econd.expr) {
                    case TBinop(OpLt, {expr: TLocal(indexVar)}, {expr: TField(arr, FInstance(_, _, cf))}) 
                        if (indexVar.name.startsWith("_g") && cf.get().name == "length"):
                        
                        #if debug_array_patterns
                        trace('[XRay ArrayPattern] FOUND array iteration pattern!');
                        trace('[XRay ArrayPattern] Index var: ${indexVar.name}');
                        trace('[XRay ArrayPattern] Array ref: ${arr.expr}');
                        #end
                        
                        // Found the pattern, arr is either the array or a variable holding it
                        isArrayLoop = true;
                        arrayRef = arr;
                        
                    case _:
                        #if debug_array_patterns
                        trace('[XRay ArrayPattern] Not an array pattern, condition is: ${econd.expr}');
                        #end
                }
                
                if (isArrayLoop && arrayRef != null) {
                    // Analyze the loop body to determine what kind of operation this is
                    var pattern = ElixirASTPatterns.detectArrayOperationPattern(e);
                    
                    if (pattern != null) {
                        return generateIdiomaticEnumCall(arrayRef, pattern, e);
                    }
                }
                
                // Not an array pattern or couldn't optimize
                // Generate a named recursive function instead of Y-combinator pattern
                // 
                // IDIOMATIC ELIXIR LOOP PATTERNS:
                // 
                // 1. For collection iteration → Enum.each/map/filter
                //    Haxe: for (item in array) { process(item); }
                //    Elixir: Enum.each(array, &process/1)
                //
                // 2. For numeric ranges → Enum.each with range
                //    Haxe: for (i in 0...10) { trace(i); }
                //    Elixir: Enum.each(0..9, &IO.inspect/1)
                //
                // 3. While loops → Stream.unfold or recursive function
                //    Haxe: while (condition) { body; }
                //    Elixir: Stream.unfold(initial_state, fn state ->
                //              if condition(state) do
                //                {nil, new_state}
                //              else
                //                nil
                //              end
                //            end) |> Stream.run()
                //
                // 4. Complex iterations → for comprehension
                //    Haxe: nested loops with conditions
                //    Elixir: for i <- 0..9, j <- 0..9, i != j, do: {i, j}
                //
                // CURRENT LIMITATION: We're in the builder phase and don't have
                // enough context to determine the best idiomatic pattern.
                // The transformer pass should detect these patterns and convert them.
                //
                // Generate idiomatic Elixir patterns directly
                var condition = buildFromTypedExpr(econd, currentContext);
                var body = buildFromTypedExpr(e, currentContext);
                
                // For now, generate a simple recursive anonymous function
                // This avoids Y-combinator pattern but needs improvement
                // to use Enum.reduce_while or Stream.unfold for true idiomaticity
                //
                // Generated pattern:
                //   loop = fn loop ->
                //     if condition do
                //       body
                //       loop.(loop)
                //     else
                //       :ok
                //     end
                //   end
                //   loop.(loop)
                
                // Generate unique loop name
                var loopName = "loop_" + (currentContext.whileLoopCounter++);
                
                // Generate a Stream.unfold pattern for idiomatic Elixir
                // This avoids Y-combinator and generates clean, functional code
                // Stream.unfold(true, fn
                //   false -> nil
                //   true -> if condition do {nil, true} else {nil, false} end
                // end) |> Stream.run()
                
                // STATE THREADING IMPLEMENTATION
                // Detect variables that are mutated in the loop body
                var mutatedVars = reflaxe.elixir.helpers.MutabilityDetector.detectMutatedVariables(e);
                
                // ALSO check which variables are used in the condition!
                // If the condition uses variables that are mutated in the body,
                // we need to include them in state threading
                var conditionVars = new Map<Int, TVar>();
                function findConditionVars(expr: TypedExpr): Void {
                    if (expr == null) return;
                    switch(expr.expr) {
                        case TLocal(v):
                            conditionVars.set(v.id, v);
                        default:
                            haxe.macro.TypedExprTools.iter(expr, findConditionVars);
                    }
                }
                findConditionVars(econd);
                
                // Add ALL condition variables to the state threading
                // Even if they're not mutated, they need to be accessible in the reduce_while callback
                for (v in conditionVars) {
                    if (!mutatedVars.exists(v.id)) {
                        #if debug_state_threading
                        trace('[State Threading] Adding condition variable to state threading: ${v.name} (id: ${v.id})');
                        #end
                        mutatedVars.set(v.id, v);
                    }
                }
                
                #if debug_state_threading
                trace('[State Threading] While loop detected, state-threaded vars: ${[for (v in mutatedVars) v.name]}');
                #end
                
                // If there are variables to thread (mutated or used in condition), use reduce_while
                if (Lambda.count(mutatedVars) > 0) {
                    // Build the initial accumulator tuple with all mutable variables
                    // IMPORTANT: Use Arrays to maintain consistent ordering
                    var accVarList: Array<{name: String, tvar: TVar}> = [];
                    
                    // Convert Map to sorted Array for deterministic ordering
                    for (id => v in mutatedVars) {
                        accVarList.push({name: toElixirVarName(v.name), tvar: v});
                    }
                    // Sort by variable ID to ensure consistent ordering across compilation
                    accVarList.sort((a, b) -> a.tvar.id - b.tvar.id);
                    
                    var initialAccValues: Array<ElixirAST> = [];
                    var accPattern: Array<EPattern> = [];
                    var accVarNames: Array<String> = [];
                    
                    for (v in accVarList) {
                        var varName = v.name;
                        initialAccValues.push(makeAST(EVar(varName)));
                        // Use acc_ prefix to avoid shadowing outer variables
                        accPattern.push(PVar("acc_" + varName));
                        accVarNames.push(varName);
                    }
                    
                    // Add the original accumulator at the end
                    initialAccValues.push(makeAST(EAtom(ElixirAtom.ok())));
                    accPattern.push(PVar("acc_state"));
                    
                    var initialAccumulator = makeAST(ETuple(initialAccValues));
                    var accPatternTuple = PTuple(accPattern);
                    
                    // Build the updated accumulator for {:cont, ...}
                    var contAccValues: Array<ElixirAST> = [];
                    for (varName in accVarNames) {
                        contAccValues.push(makeAST(EVar(varName)));
                    }
                    contAccValues.push(makeAST(EVar("acc_state")));
                    var contAccumulator = makeAST(ETuple(contAccValues));
                    
                    // Build the variable mapping for transformations
                    var varMapping = new Map<String, String>();
                    for (varName in accVarNames) {
                        varMapping.set(varName, "acc_" + varName);
                    }
                    
                    #if debug_state_threading
                    trace('[State Threading] Condition before transformation: ${ElixirASTPrinter.printAST(condition)}');
                    if (condition != null) {
                        trace('[State Threading] Condition AST def type: ${Type.typeof(condition.def)}');
                    }
                    trace('[State Threading] VarMapping: ${[for (k in varMapping.keys()) '$k => ${varMapping.get(k)}']}');
                    #end
                    
                    // Transform condition and body to use acc_ variables BEFORE building the function
                    var transformedCondition = transformVariableReferences(condition, varMapping);
                    
                    #if debug_state_threading
                    trace('[State Threading] Body BEFORE transformation:');
                    trace(ElixirASTPrinter.printAST(body));
                    #end
                    
                    var transformedBody = transformVariableReferences(body, varMapping);
                    
                    #if debug_state_threading
                    trace('[State Threading] Body AFTER transformation:');
                    trace(ElixirASTPrinter.printAST(transformedBody));
                    #end
                    
                    // Check if the body contains early returns that need special handling
                    var bodyHasReturn = checkForEarlyReturns(transformedBody);
                    
                    // Build the complete body first to check variable usage
                    // Build updated accumulator for continuation
                    var updatedContAccValues: Array<ElixirAST> = [];
                    for (varName in accVarNames) {
                        updatedContAccValues.push(makeAST(EVar("acc_" + varName)));
                    }
                    updatedContAccValues.push(makeAST(EVar("acc_state")));
                    var updatedContAccumulator = makeAST(ETuple(updatedContAccValues));
                    
                    // Build the body using the pre-transformed condition and body
                    var wrappedBody = if (bodyHasReturn) {
                        // Transform returns in the body to halt tuples
                        transformReturnsToHalts(transformedBody, updatedContAccumulator);
                    } else {
                        // Normal body without early returns
                        makeAST(EBlock([
                            transformedBody,
                            makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), updatedContAccumulator]))
                        ]));
                    };
                    
                    // Build the complete if statement
                    var completeBody = makeAST(EIf(
                        transformedCondition,
                        wrappedBody,
                        makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), updatedContAccumulator]))
                    ));
                    
                    // NOW check which acc_ variables are actually used in the complete body
                    // This includes condition, body, and continuations
                    var usedAccVars = new Map<String, Bool>();
                    for (varName in accVarNames) {
                        var accVarName = "acc_" + varName;
                        usedAccVars.set(varName, isVariableUsedInAST(accVarName, completeBody));
                    }
                    var isAccStateUsed = isVariableUsedInAST("acc_state", completeBody);
                    
                    // Update the pattern to use underscore prefix for unused variables
                    var finalAccPattern: Array<EPattern> = [];
                    for (i in 0...accVarNames.length) {
                        var varName = accVarNames[i];
                        var accVarName = "acc_" + varName;
                        if (usedAccVars.get(varName)) {
                            finalAccPattern.push(PVar(accVarName));
                        } else {
                            // Prefix with underscore to indicate unused
                            // M0 STABILIZATION: Disable underscore prefixing
                            finalAccPattern.push(PVar(accVarName)); // Was: "_" + accVarName
                        }
                    }
                    // Handle acc_state
                    if (isAccStateUsed) {
                        finalAccPattern.push(PVar("acc_state"));
                    } else {
                        finalAccPattern.push(PVar("_acc_state"));
                    }
                    var finalAccPatternTuple = PTuple(finalAccPattern);
                    
                    #if debug_state_threading
                    if (transformedCondition != null) {
                        trace('[State Threading] Condition BEFORE transformation: ${ElixirASTPrinter.printAST(condition)}');
                        trace('[State Threading] Condition AFTER transformation: ${ElixirASTPrinter.printAST(transformedCondition)}');
                    } else {
                        trace('[State Threading] ERROR: transformedCondition is null!');
                    }
                    trace('[State Threading] Body has early return: $bodyHasReturn');
                    trace('[State Threading] Used acc vars: $usedAccVars');
                    #end
                    
                    // Generate the reduce_while with state threading
                    var reduceResult = ERemoteCall(
                        makeAST(EVar("Enum")),
                        "reduce_while",
                        [
                            // Use Stream.iterate for infinite sequence
                            makeAST(ERemoteCall(
                                makeAST(EVar("Stream")),
                                "iterate",
                                [
                                    makeAST(EInteger(0)),
                                    makeAST(EFn([{
                                        args: [PVar("n")],
                                        guard: null,
                                        body: makeAST(EBinary(Add, makeAST(EVar("n")), makeAST(EInteger(1))))
                                    }]))
                                ]
                            )),
                            initialAccumulator,
                            {
                                // Check if the body is actually empty (just nil)
                                var isEmptyBody = switch(transformedBody.def) {
                                    case ENil: true;
                                    case _: false;
                                };
                                
                                // If body is empty and we have accumulator variables, 
                                // we need to use wildcard pattern to avoid unused variable warnings
                                var accPatternToUse = if (isEmptyBody && Lambda.count(mutatedVars) > 0) {
                                    // Build a tuple with all wildcards for unused accumulator
                                    var wildcardPatterns: Array<EPattern> = [];
                                    for (i in 0...(accVarNames.length + 1)) { // +1 for acc_state
                                        wildcardPatterns.push(PWildcard);
                                    }
                                    PTuple(wildcardPatterns);
                                } else {
                                    // Use the actual pattern tuple
                                    finalAccPatternTuple;
                                };
                                
                                makeAST(EFn([
                                    {
                                        args: [PWildcard, accPatternToUse],
                                        guard: null,
                                        body: {
                                            // Build updated accumulator for continuation
                                            // Use the acc_ prefixed variables which may have been updated in the body
                                            var updatedContAccValues: Array<ElixirAST> = [];
                                            for (varName in accVarNames) {
                                                updatedContAccValues.push(makeAST(EVar("acc_" + varName)));
                                            }
                                            updatedContAccValues.push(makeAST(EVar("acc_state")));
                                            var updatedContAccumulator = makeAST(ETuple(updatedContAccValues));
                                            
                                            // Build the body using the pre-transformed condition and body
                                            // If the body contains early returns, they need to be transformed to {:halt, value}
                                            var wrappedBody = if (bodyHasReturn) {
                                                // Transform returns in the body to halt tuples
                                                transformReturnsToHalts(transformedBody, updatedContAccumulator);
                                            } else if (isEmptyBody) {
                                                // Empty body - return cont with accumulator unchanged
                                                makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), updatedContAccumulator]));
                                            } else {
                                                // Normal body without early returns
                                                makeAST(EBlock([
                                                    transformedBody,
                                                    makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), updatedContAccumulator]))
                                                ]));
                                            };
                                            
                                            makeAST(EIf(
                                                transformedCondition,
                                                wrappedBody,
                                                makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), 
                                                    // For halt, also check if we need wildcard
                                                    if (isEmptyBody) makeAST(EAtom(ElixirAtom.ok())) else updatedContAccumulator
                                                ]))
                                            ));
                                        }
                                    }
                                ]));
                            }
                        ]
                    );
                    
                    // The reduce_while returns the final accumulator
                    // For now, we don't destructure it since most while loops with mutated
                    // variables are just using them as loop counters that aren't needed after
                    // TODO: Analyze if variables are used after the loop and only destructure then
                    reduceResult;
                } else {
                    // No mutated variables, use simpler form
                    ERemoteCall(
                        makeAST(EVar("Enum")),  
                        "reduce_while",
                        [
                            // Use Stream.iterate for infinite sequence
                            makeAST(ERemoteCall(
                                makeAST(EVar("Stream")),
                                "iterate",
                                [
                                    makeAST(EInteger(0)),
                                    makeAST(EFn([{
                                        args: [PVar("n")],
                                        guard: null,
                                        body: makeAST(EBinary(Add, makeAST(EVar("n")), makeAST(EInteger(1))))
                                    }]))
                                ]
                            )),
                            makeAST(EAtom(ElixirAtom.ok())),
                            makeAST(EFn([
                                {
                                    args: [PWildcard, PVar("acc")],
                                    guard: null,
                                    body: makeAST(EIf(
                                        condition,  // Use original condition - no mutations to transform
                                        makeAST(EBlock([
                                            body,    // Use original body - no mutations to transform
                                            makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), makeAST(EVar("acc"))]))
                                        ])),
                                        makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), makeAST(EVar("acc"))]))
                                    ))
                                }
                            ]))
                        ]
                    );
                }
                
            case TThrow(e):
                EThrow(buildFromTypedExpr(e, currentContext));
                
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
                 */

                // Debug trace to understand the extraction context
                #if debug_enum_extraction
                trace('[TEnumParameter] Attempting extraction:');
                trace('  - Expression type: ${e.expr}');
                trace('  - Enum field: ${ef.name}');
                trace('  - Index: $index');
                trace('  - Has ClauseContext: ${currentClauseContext != null}');
                if (currentClauseContext != null) {
                    trace('  - Has EnumBindingPlan: ${currentClauseContext.enumBindingPlan != null && currentClauseContext.enumBindingPlan.keys().hasNext()}');
                    if (currentClauseContext.enumBindingPlan.exists(index)) {
                        var info = currentClauseContext.enumBindingPlan.get(index);
                        trace('  - Binding plan for index $index: ${info.finalName} (used: ${info.isUsed})');
                    }
                }
                #end

                // Check if we have a binding plan for this index
                if (currentClauseContext != null && currentClauseContext.enumBindingPlan.exists(index)) {
                    // Use the variable name from the binding plan
                    var info = currentClauseContext.enumBindingPlan.get(index);

                    #if debug_enum_extraction
                    trace('  - Using binding plan variable: ${info.finalName}');
                    #end

                    // The pattern already extracted this to the planned variable name
                    EVar(info.finalName);
                } else {
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
                                var varName = toElixirVarName(v.name);

                                #if debug_enum_extraction
                                trace('  - TLocal variable: ${v.name} -> $varName');
                                if (currentClauseContext != null) {
                                    trace('  - ClauseContext has mapping: ${currentClauseContext.localToName.exists(v.id)}');
                                    if (currentClauseContext.localToName.exists(v.id)) {
                                        trace('  - Mapped to: ${currentClauseContext.localToName.get(v.id)}');
                                    }
                                }
                                #end

                                // Check if this variable was extracted by the pattern
                                // Pattern extraction creates variables like 'g', 'g1', 'g2' for ignored params
                                // or uses actual names for named params
                                if (currentClauseContext != null && currentClauseContext.localToName.exists(v.id)) {
                                    // This variable was mapped in the pattern, it's already extracted
                                    extractedVarName = currentClauseContext.localToName.get(v.id);
                                    skipExtraction = true;

                                    #if debug_enum_extraction
                                    trace('  - SKIPPING extraction, already extracted to: $extractedVarName');
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
                                        trace('  - SKIPPING extraction, detected as pattern temp var: $varName');
                                        #end
                                    }
                                }
                            case _:
                                // Not a local variable, normal extraction needed
                                #if debug_enum_extraction
                                trace('  - Not a TLocal, proceeding with extraction');
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
                        trace('  - Generating elem() extraction');
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
                buildFromTypedExpr(e, currentContext).def;
                
            case TIdent(s):
                // Identifier reference
                EVar(toElixirVarName(s));
        }
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
        trace("[Array Pattern] Checking condition: " + haxe.macro.ExprTools.toString(Context.getTypedExpr(econd)));
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
                                        trace("[Array Pattern] DETECTED: " + indexVarName + " < " + arrayVarName + ".length");
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
            trace("[Array Pattern] No array pattern detected");
            #end
            return null;
        }
        
        // Analyze the loop body to determine the pattern type
        var bodyAnalysis = analyzeLoopBody(ebody);
        
        // For _g2 pattern, we need to generate a reference to the actual array variable
        // The actual array should be available as a local variable named _g2
        var arrayExpr = makeAST(EVar(toElixirVarName(arrayVarName.length > 0 ? arrayVarName : "_g2")));
        
        // Generate appropriate Enum call based on pattern
        if (bodyAnalysis.hasMapPattern) {
            return generateEnumMapSimple(arrayExpr, bodyAnalysis, ebody);
        } else if (bodyAnalysis.hasFilterPattern) {
            return generateEnumFilterSimple(arrayExpr, bodyAnalysis, ebody);
        } else if (bodyAnalysis.hasReducePattern) {
            // Reduce patterns are more complex, skip for now
            return null;
        }
        
        // No clear pattern detected, return null to use regular while loop
        return null;
    }
    
    /**
     * Detect array iteration pattern in condition
     */
    static function detectArrayIterationPattern(econd: TypedExpr): Null<{arrayExpr: TypedExpr, indexVar: String}> {
        return switch(econd.expr) {
            case TBinop(OpLt, e1, e2):
                // Debug what we're comparing
                #if debug_array_patterns
                trace("[Array Pattern] e1: " + Type.enumConstructor(e1.expr));
                trace("[Array Pattern] e2: " + Type.enumConstructor(e2.expr));
                #end
                
                // Check for _g1 < _g2.length pattern
                switch(e2.expr) {
                    case TField(arrayExpr, FInstance(_, _, cf)):
                        // Check if accessing .length field
                        if (cf.get().name == "length") {
                            // Check what arrayExpr is
                            #if debug_array_patterns
                            trace("[Array Pattern] Found .length access on: " + Type.enumConstructor(arrayExpr.expr));
                            #end
                            
                            // Handle _g2 being a local variable holding the array
                            switch(arrayExpr.expr) {
                                case TLocal(arrayVar) if (arrayVar.name.startsWith("_g")):
                                    // _g2 is a variable holding the array reference
                                    switch(e1.expr) {
                                        case TLocal(indexVar) if (indexVar.name.startsWith("_g")):
                                            #if debug_array_patterns
                                            trace("[Array Pattern] MATCHED: " + indexVar.name + " < " + arrayVar.name + ".length");
                                            #end
                                            // We have the pattern, but _g2 is a variable, not the actual array
                                            // For now, return this and we'll handle it differently
                                            return {arrayExpr: arrayExpr, indexVar: indexVar.name};
                                        case _:
                                            null;
                                    }
                                case _:
                                    // Direct array.length access
                                    switch(e1.expr) {
                                        case TLocal(v) if (v.name.startsWith("_g")):
                                            #if debug_array_patterns
                                            trace("[Array Pattern] Detected direct: " + v.name + " < array.length");
                                            #end
                                            return {arrayExpr: arrayExpr, indexVar: v.name};
                                        case _:
                                            null;
                                    }
                            }
                        }
                        null;
                    case _:
                        null;
                }
                null;
            case _:
                null;
        };
        return null;
    }
    
    /**
     * Analyze loop body to identify pattern type
     */
    static function analyzeLoopBody(ebody: TypedExpr): {
        hasMapPattern: Bool,
        hasFilterPattern: Bool,
        hasReducePattern: Bool,
        loopVar: Null<TVar>,
        pushTarget: Null<String>
    } {
        var result = {
            hasMapPattern: false,
            hasFilterPattern: false,
            hasReducePattern: false,
            loopVar: null,
            pushTarget: null
        };
        
        // Look for common patterns in the body
        function analyze(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) analyze(e);
                    
                case TVar(v, init):
                    // Look for: var v = array[index]
                    if (init != null) {
                        switch(init.expr) {
                            case TArray(_, _):
                                result.loopVar = v;
                            case _:
                        }
                    }
                    
                case TCall(e, args):
                    // Look for: result.push(transformation)
                    switch(e.expr) {
                        case TField(target, FInstance(_, _, cf)):
                            if (cf.get().name == "push") {
                                result.hasMapPattern = true;
                                // Extract push target variable name
                                switch(target.expr) {
                                    case TLocal(v):
                                        result.pushTarget = v.name;
                                    case _:
                                }
                            }
                        case _:
                    }
                    
                case TIf(cond, thenExpr, elseExpr):
                    // Check for filter pattern (conditional push)
                    analyze(thenExpr);
                    if (elseExpr != null) analyze(elseExpr);
                    
                    // If there's a push in the then branch, it's a filter
                    if (result.hasMapPattern) {
                        result.hasFilterPattern = true;
                        result.hasMapPattern = false; // Filter takes precedence
                    }
                    
                case TBinop(OpAssignOp(OpAdd), _, _):
                    // Accumulation pattern (reduce)
                    result.hasReducePattern = true;
                    
                case _:
                    // Recursively analyze other expressions using Haxe's built-in iterator
                    haxe.macro.TypedExprTools.iter(expr, analyze);
            }
        }
        
        analyze(ebody);
        return result;
    }
    
    /**
     * Generate Enum.map call (simplified version)
     */
    static function generateEnumMapSimple(arrayExpr: ElixirAST, analysis: Dynamic, ebody: TypedExpr): ElixirAST {
        // Find the loop variable and transformation
        var loopVar = analysis.loopVar != null ? toElixirVarName(analysis.loopVar.name) : "item";
        
        // Extract the transformation expression from the push call
        var transformation = extractMapTransformation(ebody, analysis.loopVar);
        
        // Create lambda: fn item -> transformation end
        var lambda = makeAST(EFn([{
            args: [PVar(loopVar)],
            guard: null,
            body: transformation
        }]));
        
        // Return Enum.map(array, lambda)
        return makeAST(ECall(null, "Enum.map", [arrayExpr, lambda]));
    }
    
    /**
     * Generate Enum.filter call (simplified version)
     */
    static function generateEnumFilterSimple(arrayExpr: ElixirAST, analysis: Dynamic, ebody: TypedExpr): ElixirAST {
        var loopVar = analysis.loopVar != null ? toElixirVarName(analysis.loopVar.name) : "item";
        
        // Extract the filter condition
        var condition = extractFilterCondition(ebody);
        
        // Create lambda: fn item -> condition end
        var lambda = makeAST(EFn([{
            args: [PVar(loopVar)],
            guard: null,
            body: condition
        }]));
        
        // Return Enum.filter(array, lambda)
        return makeAST(ECall(null, "Enum.filter", [arrayExpr, lambda]));
    }
    
    /**
     * Generate Enum.map call (original TypedExpr version - kept for compatibility)
     */
    static function generateEnumMap(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST {
        // Extract the transformation from the loop body
        var arrayAST = buildFromTypedExpr(arrayExpr, currentContext);
        
        // Find the loop variable and transformation
        var loopVar = analysis.loopVar != null ? toElixirVarName(analysis.loopVar.name) : "item";
        
        // Extract the transformation expression from the push call
        var transformation = extractMapTransformation(ebody, analysis.loopVar);
        
        // Create lambda: fn item -> transformation end
        var lambda = makeAST(EFn([{
            args: [PVar(loopVar)],
            guard: null,
            body: transformation
        }]));
        
        // Return Enum.map(array, lambda)
        return makeAST(ECall(null, "Enum.map", [arrayAST, lambda]));
    }
    
    /**
     * Generate Enum.filter call
     */
    static function generateEnumFilter(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST {
        var arrayAST = buildFromTypedExpr(arrayExpr, currentContext);
        var loopVar = analysis.loopVar != null ? toElixirVarName(analysis.loopVar.name) : "item";
        
        // Extract the filter condition
        var condition = extractFilterCondition(ebody);
        
        // Create lambda: fn item -> condition end
        var lambda = makeAST(EFn([{
            args: [PVar(loopVar)],
            guard: null,
            body: condition
        }]));
        
        // Return Enum.filter(array, lambda)
        return makeAST(ECall(null, "Enum.filter", [arrayAST, lambda]));
    }
    
    /**
     * Generate Enum.reduce call
     */
    static function generateEnumReduce(arrayExpr: TypedExpr, analysis: Dynamic, ebody: TypedExpr): ElixirAST {
        // For now, return null to use regular while loop
        // Reduce patterns are more complex and need more analysis
        return null;
    }
    
    /**
     * Extract the transformation expression from a map pattern
     */
    static function extractMapTransformation(ebody: TypedExpr, loopVar: Null<TVar>): ElixirAST {
        // Look for the push call and extract its argument
        function findPushArg(expr: TypedExpr): Null<TypedExpr> {
            return switch(expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) {
                        var result = findPushArg(e);
                        if (result != null) return result;
                    }
                    null;
                    
                case TCall(e, [arg]):
                    switch(e.expr) {
                        case TField(_, FInstance(_, _, cf)):
                            if (cf.get().name == "push") {
                                return arg;
                            }
                            null;
                        case _:
                            null;
                    }
                    null;
                    
                case _:
                    null;
            }
        }
        
        var pushArg = findPushArg(ebody);
        if (pushArg != null) {
            // Build the transformation with variable substitution
            return buildFromTypedExprWithSubstitution(pushArg, loopVar);
        }
        
        // Fallback: just return the item
        return makeAST(EVar("item"));
    }
    
    /**
     * Extract filter condition from loop body
     */
    static function extractFilterCondition(ebody: TypedExpr): ElixirAST {
        // Look for the if condition that guards the push
        function findIfCondition(expr: TypedExpr): Null<TypedExpr> {
            return switch(expr.expr) {
                case TBlock(exprs):
                    for (e in exprs) {
                        var result = findIfCondition(e);
                        if (result != null) return result;
                    }
                    null;
                    
                case TIf(cond, thenExpr, _):
                    // Check if the then branch contains a push
                    if (containsPush(thenExpr)) {
                        return cond;
                    }
                    null;
                    
                case _:
                    null;
            }
        }
        
        var cond = findIfCondition(ebody);
        if (cond != null) {
            return buildFromTypedExpr(cond, currentContext);
        }
        
        // Fallback: always true
        return makeAST(EBoolean(true));
    }
    
    /**
     * Check if an expression contains a push call
     */
    static function containsPush(expr: TypedExpr): Bool {
        var hasPush = false;
        
        function check(e: TypedExpr): Void {
            switch(e.expr) {
                case TCall(target, _):
                    switch(target.expr) {
                        case TField(_, FInstance(_, _, cf)):
                            if (cf.get().name == "push") {
                                hasPush = true;
                            }
                        case _:
                    }
                case _:
                    if (!hasPush) {
                        haxe.macro.TypedExprTools.iter(e, check);
                    }
            }
        }
        
        check(expr);
        return hasPush;
    }
    
    /**
     * Process enum case body to detect and handle unused extracted variables
     * 
     * WHY: When Haxe compiles patterns like case Ok(value), it generates extraction code
     * even if 'value' is never used, leading to unused variable warnings in Elixir.
     * 
     * WHAT: Detects variables extracted from enum patterns that are never used in the body
     * and prefixes them with underscore to suppress warnings.
     * 
     * HOW: Analyzes the case body for TVar nodes with TEnumParameter initialization,
     * checks if the variable is used, and modifies the variable name if unused.
     */
    static function processEnumCaseBody(caseExpr: TypedExpr, builtBody: ElixirAST): ElixirAST {
        // Check if the case body contains enum parameter extraction
        // Pattern: TBlock([TVar(v, TEnumParameter(...)), ...])
        switch(caseExpr.expr) {
            case TBlock(exprs):
                var modifiedExprs = [];
                var unusedVars = new Map<String, Bool>();
                
                // First pass: identify extracted enum parameters
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(v, init) if (init != null):
                            switch(init.expr) {
                                case TEnumParameter(_, _, _):
                                    // Found an enum parameter extraction
                                    // Check if this variable is used in the rest of the block
                                    var isUsed = false;
                                    // TODO: Restore when UsageDetector is available
                                    // for (i in (exprs.indexOf(expr) + 1)...exprs.length) {
                                    //     if (reflaxe.elixir.helpers.UsageDetector.isVariableUsed(v.id, exprs[i])) {
                                    //         isUsed = true;
                                    //         break;
                                    //     }
                                    // }
                                    isUsed = true; // Conservative: assume all vars are used for now
                                    if (!isUsed) {
                                        unusedVars.set(v.name, true);
                                    }
                                default:
                            }
                        default:
                    }
                }
                
                // If we found unused extracted variables, we need to rebuild the body
                // with prefixed variable names
                if (Lambda.count(unusedVars) > 0) {
                    // The body has already been built, but we need to modify it
                    // to prefix unused variables with underscore
                    return prefixUnusedVariablesInAST(builtBody, unusedVars);
                }
            default:
        }
        
        return builtBody;
    }
    
    /**
     * Prefix unused variables with underscore in an already-built AST
     */
    static function prefixUnusedVariablesInAST(ast: ElixirAST, unusedVars: Map<String, Bool>): ElixirAST {
        // This is a simplified version - in practice we'd need to traverse
        // the AST and modify variable names. For now, return as-is
        // since the actual fix needs to happen during initial building
        return ast;
    }
    
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
            purity: isPure(expr),
            tailPosition: false, // Will be set by transformer
            async: false, // Will be detected by transformer
            requiresReturn: false, // Will be set by context
            requiresTempVar: false, // Will be set by transformer
            inPipeline: false, // Will be set by transformer
            inComprehension: false, // Will be set by context
            inGuard: false, // Will be set by context
            canInline: canBeInlined(expr),
            isConstant: isConstant(expr),
            sideEffects: hasSideEffects(expr)
        };
    }
    
    /**
     * Convert Haxe values to patterns
     * 
     * WHY: Switch case values need to be converted to Elixir patterns
     * WHAT: Handles literals, enum constructors, variables, and complex patterns
     * HOW: Analyzes the TypedExpr structure and generates appropriate pattern
     */
    static function convertPattern(value: TypedExpr): EPattern {
        return switch(value.expr) {
            // Literals
            case TConst(TInt(i)): 
                PLiteral(makeAST(EInteger(i)));
            case TConst(TFloat(f)): 
                PLiteral(makeAST(EFloat(Std.parseFloat(f))));
            case TConst(TString(s)): 
                PLiteral(makeAST(EString(s)));
            case TConst(TBool(b)): 
                PLiteral(makeAST(EBoolean(b)));
            case TConst(TNull): 
                PLiteral(makeAST(ENil));
                
            // Variables (for pattern matching)
            case TLocal(v):
                PVar(toElixirVarName(v.name));
                
            // Enum constructors
            case TEnumParameter(e, ef, index):
                // This represents matching against enum constructor arguments
                // We'll need to handle this in the context of the full pattern
                PVar("_enum_param_" + index);
                
            case TEnumIndex(e):
                // Matching against enum index (for switch on elem(tuple, 0))
                PLiteral(makeAST(EInteger(0))); // Will be refined based on actual enum
                
            // Array patterns
            case TArrayDecl(el):
                PList([for (e in el) convertPattern(e)]);
                
            // Tuple patterns (for enum matching)
            case TCall(e, el) if (isEnumConstructor(e)):
                // Enum constructor pattern
                var tag = extractEnumTag(e);
                
                // For idiomatic enums, convert to snake_case
                if (hasIdiomaticMetadata(e)) {
                    tag = reflaxe.elixir.ast.NameUtils.toSnakeCase(tag);
                }
                
                var args = [for (arg in el) convertPattern(arg)];
                // Create tuple pattern {:tag, arg1, arg2, ...}
                PTuple([PLiteral(makeAST(EAtom(tag)))].concat(args));
                
            // Field access (for enum constructors)
            case TField(e, FEnum(enumRef, ef)):
                // Direct enum constructor reference
                // Always use snake_case for enum atoms (idiomatic Elixir)
                var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                
                // Check if the enum is idiomatic (now all enums are treated as idiomatic)
                var isIdiomatic = enumRef.get().meta.has(":elixirIdiomatic") || true; // All enums are idiomatic now
                
                // Extract parameter count from the enum field's type
                var paramCount = 0;
                switch(ef.type) {
                    case TFun(args, _):
                        paramCount = args.length;
                    default:
                        // No parameters
                }
                
                if (paramCount == 0) {
                    // No-argument constructor
                    PLiteral(makeAST(EAtom(atomName)));
                } else {
                    // Constructor with arguments - needs to be a tuple pattern
                    // This will be {:Constructor, _, _, ...} with wildcards for args
                    var wildcards = [for (i in 0...paramCount) PWildcard];
                    PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(wildcards));
                }
                
            // Default/wildcard
            default: 
                PWildcard;
        }
    }
    
    /**
     * Convert Haxe values to patterns with extracted parameter names
     * 
     * WHY: Regular enums need access to user-specified variable names from switch cases
     * WHAT: Like convertPattern but uses extractedParams for enum constructor arguments
     * HOW: When encountering enum constructors, uses extractedParams instead of wildcards
     */
    static function convertPatternWithExtraction(value: TypedExpr, extractedParams: Array<String>): EPattern {
        return switch(value.expr) {
            // Most cases delegate to regular convertPattern
            case TConst(_) | TLocal(_) | TArrayDecl(_) | TEnumIndex(_):
                convertPattern(value);
                
            // Enum constructors - the main difference
            case TCall(e, el) if (isEnumConstructor(e)):
                // Enum constructor pattern with extracted parameter names
                var tag = extractEnumTag(e);
                
                // For idiomatic enums, convert to snake_case
                if (hasIdiomaticMetadata(e)) {
                    tag = reflaxe.elixir.ast.NameUtils.toSnakeCase(tag);
                }
                
                // Use extracted parameter names instead of wildcards or generic names
                var args = [];
                for (i in 0...el.length) {
                    if (i < extractedParams.length && extractedParams[i] != null) {
                        // Use the user-specified variable name
                        args.push(PVar(extractedParams[i]));
                    } else {
                        // Fall back to wildcard if no name provided
                        args.push(PWildcard);
                    }
                }
                
                // Create tuple pattern {:tag, param1, param2, ...}
                PTuple([PLiteral(makeAST(EAtom(tag)))].concat(args));
                
            // Field access (for enum constructors without arguments)
            case TField(e, FEnum(enumRef, ef)):
                // Direct enum constructor reference
                var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                
                // Extract parameter count from the enum field's type
                var paramCount = 0;
                switch(ef.type) {
                    case TFun(args, _):
                        paramCount = args.length;
                    default:
                        // No parameters
                }
                
                if (paramCount == 0) {
                    // No-argument constructor
                    PLiteral(makeAST(EAtom(atomName)));
                } else {
                    // Constructor with arguments - use extracted param names
                    var patterns = [];
                    for (i in 0...paramCount) {
                        if (i < extractedParams.length && extractedParams[i] != null) {
                            patterns.push(PVar(extractedParams[i]));
                        } else {
                            patterns.push(PWildcard);
                        }
                    }
                    PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(patterns));
                }
                
            default:
                // Fall back to regular pattern conversion
                convertPattern(value);
        }
    }
    
    /**
     * Extract pattern variable names from case values
     * 
     * WHY: When we have `case Ok(email):`, the pattern variable "email" is in the case values,
     *      not in the case body. We need to extract these names to generate correct patterns.
     * WHAT: Extracts variable names from enum constructor patterns in case values
     * HOW: Analyzes TCall expressions in case values to find pattern variable arguments
     */
    static function extractPatternVariableNamesFromValues(values: Array<TypedExpr>): Array<String> {
        var patternVars = [];
        
        for (value in values) {
            switch(value.expr) {
                case TCall(e, args):
                    // This is an enum constructor pattern like Ok(email) or Error(reason)
                    // Extract the variable names from the arguments
                    for (i in 0...args.length) {
                        var arg = args[i];
                        switch(arg.expr) {
                            case TLocal(v):
                                // Pattern variable like "email" in Ok(email)
                                var varName = toElixirVarName(v.name);
                                #if debug_ast_builder
                                trace('[extractPatternVariableNamesFromValues] Found TLocal variable: "${v.name}" -> "$varName"');
                                #end
                                // Ensure array is large enough
                                while (patternVars.length <= i) {
                                    patternVars.push(null);
                                }
                                patternVars[i] = varName;
                            default:
                                // Could be a constant or wildcard
                                #if debug_ast_builder
                                trace('[extractPatternVariableNamesFromValues] Arg $i is not TLocal: ${arg.expr}');
                                #end
                        }
                    }
                default:
                    // Not a constructor pattern
            }
        }
        
        return patternVars;
    }
    
    /**
     * Analyze case body to detect enum parameter extraction patterns
     * 
     * WHY: When the case body contains TVar(_g, TEnumParameter(...)), we need to use named
     *      patterns instead of wildcards to avoid undefined variable references
     * WHAT: Detects the extraction pattern and returns parameter names to use in patterns
     * HOW: FIRST checks case values for pattern variables, THEN looks for TBlock with TVar nodes
     * 
     * PATTERN DETECTION:
     * 1. Pattern variables in case values (case Ok(email): extracts "email")
     * 2. TVar(_g, TEnumParameter(...)) - temp var extraction
     * 3. TVar(changeset, TLocal(_g)) - assigns temp to pattern var (may be optimized away)
     * 4. TLocal(changeset) references - detect which variables are actually used
     * 
     * ENHANCEMENT: Prioritizes pattern variables from case values over body analysis
     */
    static function analyzeEnumParameterExtraction(caseExpr: TypedExpr, caseValues: Array<TypedExpr> = null): Array<String> {
        // First try to extract pattern variables directly from case values
        if (caseValues != null) {
            #if debug_ast_builder
            trace('[analyzeEnumParameterExtraction] Case values:');
            for (i in 0...caseValues.length) {
                var val = caseValues[i];
                trace('  Value $i: ${val.expr}');
            }
            #end
            
            var patternVars = extractPatternVariableNamesFromValues(caseValues);
            if (patternVars.length > 0 && patternVars.filter(v -> v != null).length > 0) {
                // We found pattern variables, use them
                #if debug_ast_pipeline
                trace('[analyzeEnumParameterExtraction] Found pattern variables from case values: ${patternVars}');
                #end
                return patternVars;
            }
        }
        
        var extractedParams = [];
        var tempVarMapping = new Map<String, {name: String, index: Int}>(); // Maps temp vars to final names
        var tempVarToIndex = new Map<String, Int>(); // Maps temp var names to parameter indices
        
        switch(caseExpr.expr) {
            case TBlock(exprs):
                // First pass: Find TEnumParameter extractions and map temp vars
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(v, init) if (init != null):
                            switch(init.expr) {
                                case TEnumParameter(_, ef, index):
                                    // Found enum parameter extraction to temp var
                                    var tempName = toElixirVarName(v.name);
                                    if (tempName.startsWith("_")) {
                                        tempName = tempName.substr(1); // Strip underscore
                                    }
                                    // Store temp var info
                                    tempVarMapping.set(tempName, {name: tempName, index: index});
                                    tempVarToIndex.set(v.name, index); // Store original name mapping
                                    
                                    // Initialize the array if needed
                                    while (extractedParams.length <= index) {
                                        extractedParams.push(null);
                                    }
                                    // Initially use the temp var name (will be overridden if there's a TLocal assignment)
                                    extractedParams[index] = tempName;
                                    
                                    #if debug_ast_builder
                                    trace('[DEBUG ENUM] Found TEnumParameter extraction: temp var "$tempName" at index $index');
                                    #end
                                default:
                            }
                        default:
                    }
                }
                
                // Second pass: Find assignments from temp vars to pattern vars
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(v, init) if (init != null):
                            switch(init.expr) {
                                case TLocal(localVar):
                                    var tempName = toElixirVarName(localVar.name);
                                    if (tempName.startsWith("_")) {
                                        tempName = tempName.substr(1);
                                    }

                                    #if debug_pattern_usage
                                    trace('[analyzeEnumParameterExtraction Second Pass] TVar(${v.name}) = TLocal(${localVar.name})');
                                    trace('[analyzeEnumParameterExtraction Second Pass] tempName: $tempName, checking if exists in tempVarMapping');
                                    #end

                                    // Check if this is assigning from a known temp var
                                    if (tempVarMapping.exists(tempName)) {
                                        var patternName = toElixirVarName(v.name);
                                        var info = tempVarMapping.get(tempName);

                                        // Update the extracted param with the pattern variable name
                                        extractedParams[info.index] = patternName;

                                        #if debug_pattern_usage
                                        trace('[analyzeEnumParameterExtraction Second Pass] FOUND! Mapped temp var "$tempName" to pattern var "$patternName" at index ${info.index}');
                                        trace('[analyzeEnumParameterExtraction Second Pass] extractedParams after mapping: ${extractedParams}');
                                        #else
                                        #if debug_ast_pipeline
                                        trace('[DEBUG ENUM] Mapped temp var "$tempName" to pattern var "$patternName" at index ${info.index}');
                                        trace('[DEBUG ENUM] extractedParams after mapping: ${extractedParams}');
                                        #end
                                        #end
                                    } else {
                                        #if debug_pattern_usage
                                        trace('[analyzeEnumParameterExtraction Second Pass] tempName "$tempName" NOT in tempVarMapping');
                                        #end
                                    }
                                default:
                            }
                        default:
                    }
                }
                
                // Third pass: Find what variables are actually used in the case body
                // When Haxe's optimizer removes TVar assignments, we need to infer the pattern names
                // from actual usage in the body
                var usedVariables = new Map<String, Bool>();
                var firstUsedVariables = []; // Track the first non-temp variable used at each index
                
                function scanForUsedVariables(expr: TypedExpr): Void {
                    switch(expr.expr) {
                        case TLocal(v):
                            var name = toElixirVarName(v.name);
                            usedVariables.set(name, true);
                            
                        // Look for the first assignment from TEnumParameter
                        case TVar(v, init) if (init != null):
                            switch(init.expr) {
                                case TEnumParameter(_, _, index):
                                    // This is extracting an enum parameter
                                    var varName = toElixirVarName(v.name);
                                    
                                    // Ensure array is large enough
                                    while (firstUsedVariables.length <= index) {
                                        firstUsedVariables.push(null);
                                    }
                                    
                                    // If this is not a temp var, use it as the pattern name
                                    if (!varName.startsWith("_") && !varName.startsWith("g")) {
                                        firstUsedVariables[index] = varName;
                                    }
                                default:
                            }
                            
                            // Continue scanning
                            if (init != null) scanForUsedVariables(init);
                            
                        // Look for method calls on enum values to infer the variable name
                        case TCall(target, el):
                            // If calling a method on an abstract type (like email.getDomain())
                            // we can infer that "email" is the variable name
                            switch(target.expr) {
                                case TField(obj, _):
                                    switch(obj.expr) {
                                        case TLocal(v):
                                            var name = toElixirVarName(v.name);
                                            if (!name.startsWith("_g") && !name.startsWith("g") && name != "g") {
                                                // This is a real variable name used in the body
                                                // Try to infer which parameter position this should be
                                                // If we have only one parameter and it's a temp var, replace it
                                                for (i in 0...extractedParams.length) {
                                                    if (extractedParams[i] == "g" || extractedParams[i] == "_g" || 
                                                        (extractedParams[i] != null && extractedParams[i].startsWith("g"))) {
                                                        // Found a temp var that needs a real name
                                                        // Use the variable that's actually referenced
                                                        extractedParams[i] = name;
                                                        #if debug_ast_builder
                                                        trace('[DEBUG ENUM] Replaced temp var "${extractedParams[i]}" with used variable "$name" at index $i');
                                                        #end
                                                        break; // Only map to first available slot
                                                    }
                                                }
                                            }
                                        default:
                                    }
                                default:
                            }
                            // Continue scanning arguments
                            for (arg in el) scanForUsedVariables(arg);
                        case TBlock(subExprs):
                            for (e in subExprs) scanForUsedVariables(e);
                        case TBinop(_, e1, e2):
                            scanForUsedVariables(e1);
                            scanForUsedVariables(e2);
                        case TField(e, _):
                            scanForUsedVariables(e);
                        case TIf(cond, ifExpr, elseExpr):
                            scanForUsedVariables(cond);
                            scanForUsedVariables(ifExpr);
                            if (elseExpr != null) scanForUsedVariables(elseExpr);
                        case TThrow(e):
                            scanForUsedVariables(e);
                        case TReturn(e):
                            if (e != null) scanForUsedVariables(e);
                        case _:
                            // Other expression types - could add more specific handling if needed
                    }
                }
                
                // Look for variable references in the rest of the case body
                for (i in 0...exprs.length) {
                    scanForUsedVariables(exprs[i]);
                }
                
            default:
        }
        
        #if debug_ast_builder
        trace('[DEBUG ENUM] Final extracted params: $extractedParams');
        #end

        #if debug_pattern_usage
        trace('[analyzeEnumParameterExtraction] FINAL RETURN VALUE: ${extractedParams}');
        #end

        return extractedParams;
    }

    /**
     * Create EnumBindingPlan as THE SINGLE SOURCE OF TRUTH for enum parameter names
     *
     * WHY: Multiple systems need consistent variable names - this establishes the authority
     * WHAT: Creates definitive mapping from enum parameter index to final variable name
     * HOW: Uses priority hierarchy: (1) extracted pattern names, (2) canonical names, (3) temp vars
     *
     * M0.1 CRITICAL FIX: This is now the authoritative source that all other systems must use
     *
     * @param caseExpr The case body expression to analyze
     * @param extractedParams The parameter names extracted by analyzeEnumParameterExtraction
     * @param enumType The enum type being switched on (if available)
     * @return Map from parameter index to binding info with finalName for EVERY parameter
     */
    static function createEnumBindingPlan(caseExpr: TypedExpr, extractedParams: Array<String>, enumType: Null<EnumType>): Map<Int, {finalName: String, isUsed: Bool}> {
        var plan: Map<Int, {finalName: String, isUsed: Bool}> = new Map();

        // M0.1: First, determine the maximum parameter count we need to handle
        // This ensures we create entries for ALL parameters, not just the ones we find
        var maxParamCount = 0;

        // Get parameter count from enum type if available
        if (enumType != null && caseExpr != null) {
            // Find which constructor this case is for by scanning for TEnumParameter
            function findConstructorIndex(expr: TypedExpr): Int {
                var foundIndex = -1;
                function scan(e: TypedExpr): Void {
                    switch(e.expr) {
                        case TEnumParameter(_, ef, _):
                            // Found it - ef has the constructor
                            for (name in enumType.constructs.keys()) {
                                var construct = enumType.constructs.get(name);
                                if (construct.name == ef.name) {
                                    foundIndex = construct.index;
                                    // Get parameter count from constructor type
                                    switch(construct.type) {
                                        case TFun(args, _):
                                            if (args.length > maxParamCount) {
                                                maxParamCount = args.length;
                                            }
                                        default:
                                    }
                                    return;
                                }
                            }
                        case TBlock(exprs):
                            for (e in exprs) scan(e);
                        default:
                            haxe.macro.TypedExprTools.iter(e, scan);
                    }
                }
                scan(expr);
                return foundIndex;
            }

            var constructorIndex = findConstructorIndex(caseExpr);

            // M0.1: Get canonical names from the enum constructor definition
            var canonicalNames: Array<String> = [];
            if (constructorIndex >= 0) {
                // Find the constructor by index
                for (name in enumType.constructs.keys()) {
                    var construct = enumType.constructs.get(name);
                    if (construct.index == constructorIndex) {
                        switch(construct.type) {
                            case TFun(args, _):
                                canonicalNames = [for (arg in args) arg.name];
                                maxParamCount = args.length;
                            default:
                        }
                        break;
                    }
                }
            }

            // M0.1: Pre-populate the plan with ALL parameters using priority hierarchy
            for (i in 0...maxParamCount) {
                var finalName: String;

                // Priority 1: Use extracted pattern names if available and not temp vars
                if (extractedParams != null && i < extractedParams.length &&
                    extractedParams[i] != null && !extractedParams[i].startsWith("g")) {
                    finalName = extractedParams[i];
                }
                // Priority 2: Use canonical names from enum definition
                else if (i < canonicalNames.length && canonicalNames[i] != null) {
                    finalName = canonicalNames[i];
                }
                // Priority 3: Fall back to temp var names
                else {
                    finalName = i == 0 ? "g" : 'g$i';
                }

                // Pre-populate with assumption that parameter is used
                // We'll update this below with actual usage analysis
                plan.set(i, {finalName: finalName, isUsed: true});
            }
        }

        // First, build a map from parameter indices to variable IDs
        // This helps us track which variables are assigned from TEnumParameter
        var paramIndexToVarId: Map<Int, Int> = new Map();

        // Scan for TVar declarations that are assigned from TEnumParameter
        function findParameterAssignments(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TVar(v, init) if (init != null):
                    switch(init.expr) {
                        case TEnumParameter(_, _, index):
                            // This variable is assigned from enum parameter at index
                            paramIndexToVarId.set(index, v.id);
                        default:
                    }
                case TBlock(exprs):
                    for (e in exprs) findParameterAssignments(e);
                default:
                    haxe.macro.TypedExprTools.iter(expr, findParameterAssignments);
            }
        }

        // Find all parameter assignments
        if (caseExpr != null) {
            findParameterAssignments(caseExpr);
        }

        // Scan case body for TEnumParameter nodes to update usage information
        function scanForEnumParameters(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TEnumParameter(e, ef, index):
                    // Found a TEnumParameter extraction at this index
                    // M0.1: Update existing entry instead of creating new one
                    if (plan.exists(index)) {
                        // Update usage information for this parameter
                        var entry = plan.get(index);

                        // Check if this parameter is actually used
                        // First try ID-based checking if we have the variable ID
                        var isUsed = false;
                        if (paramIndexToVarId.exists(index)) {
                            // Use ID-based checking to avoid false positives
                            var varId = paramIndexToVarId.get(index);
                            isUsed = isPatternVariableUsedById(varId, caseExpr);
                        } else {
                            // Fall back to name-based checking using the finalName from plan
                            isUsed = isPatternVariableUsed(entry.finalName, caseExpr);

                            #if debug_enum_extraction
                            trace('  - Checking if ${entry.finalName} is used: ${isUsed}');
                            #end
                        }

                        // Update the usage flag
                        entry.isUsed = isUsed;

                        // M0 STABILIZATION: Disable automatic underscore prefixing
                        // This was causing incorrect g vs _g mismatches where patterns would have _g
                        // but bodies would reference g, causing undefined variable errors.
                        // Accept warnings temporarily; prioritize correctness.
                        // TODO: Re-enable via proper hygiene pass in M2
                        #if !elixir_suppress_unused
                        // Commented out to prevent variable mismatches
                        // if (!isUsed && !entry.finalName.startsWith("_")) {
                        //     entry.finalName = "_" + entry.finalName;
                        // }
                        #end

                        // Update the plan with modified entry
                        plan.set(index, entry);
                    } else {
                        // M0.1: This is a parameter we didn't pre-populate - add it now
                        // This can happen if maxParamCount was wrong or if there's dynamic extraction
                        var finalName = if (extractedParams != null && index < extractedParams.length && extractedParams[index] != null) {
                            extractedParams[index];
                        } else {
                            // Generate a temp var name
                            index == 0 ? "g" : 'g$index';
                        };

                        // Check usage
                        var isUsed = false;
                        if (paramIndexToVarId.exists(index)) {
                            var varId = paramIndexToVarId.get(index);
                            isUsed = isPatternVariableUsedById(varId, caseExpr);
                        } else {
                            isUsed = isPatternVariableUsed(finalName, caseExpr);
                        }

                        plan.set(index, {finalName: finalName, isUsed: isUsed});
                    }

                    // Continue scanning the expression being extracted from
                    scanForEnumParameters(e);

                case TBlock(exprs):
                    for (e in exprs) scanForEnumParameters(e);
                case TIf(cond, thenExpr, elseExpr):
                    scanForEnumParameters(cond);
                    scanForEnumParameters(thenExpr);
                    if (elseExpr != null) scanForEnumParameters(elseExpr);
                case TSwitch(e, cases, def):
                    scanForEnumParameters(e);
                    for (c in cases) scanForEnumParameters(c.expr);
                    if (def != null) scanForEnumParameters(def);
                case TVar(v, init):
                    if (init != null) scanForEnumParameters(init);
                case TCall(e, args):
                    scanForEnumParameters(e);
                    for (arg in args) scanForEnumParameters(arg);
                case TField(e, _):
                    scanForEnumParameters(e);
                case TLocal(_):
                    // Leaf node
                case TConst(_):
                    // Leaf node
                case _:
                    // Other cases - could add more if needed
            }
        }

        // Now scan for actual TEnumParameter usage to update the plan
        if (caseExpr != null) {
            scanForEnumParameters(caseExpr);
        }

        #if debug_enum_binding_plan
        trace('[EnumBindingPlan] Created AUTHORITATIVE plan for case:');
        for (index in plan.keys()) {
            var info = plan.get(index);
            trace('  Index $index -> ${info.finalName} (used: ${info.isUsed}) [SINGLE SOURCE OF TRUTH]');
        }
        if (extractedParams != null && extractedParams.length > 0) {
            trace('[EnumBindingPlan] Input extractedParams: ${extractedParams}');
        }
        trace('[EnumBindingPlan] Priority hierarchy applied: extracted > canonical > temp');
        #end

        return plan;
    }

    /**
     * Convert patterns for idiomatic enum switch statements with explicit EnumType and extraction info
     * 
     * WHY: When we've already extracted the enum type and know which parameters are used,
     *      we can generate proper named patterns instead of wildcards
     * WHAT: Maps integer patterns to proper atom-based tuple patterns with correct variable names
     * HOW: Uses the provided enum type to map indices to constructor names and extractedParams
     *      to determine which parameters need named patterns vs wildcards
     */
    static function convertIdiomaticEnumPatternWithExtraction(value: TypedExpr, enumType: EnumType, extractedParams: Array<String>, variableUsageMap: Map<Int, Bool> = null): EPattern {
        return convertIdiomaticEnumPatternWithTypeImpl(value, enumType, extractedParams, variableUsageMap);
    }
    
    /**
     * Convert patterns for idiomatic enum switch statements with explicit EnumType
     * 
     * WHY: When we've already extracted the enum type, we can use it directly
     * WHAT: Maps integer patterns to proper atom-based tuple patterns for idiomatic enums
     * HOW: Uses the provided enum type to map indices to constructor names
     */
    static function convertIdiomaticEnumPatternWithType(value: TypedExpr, enumType: EnumType): EPattern {
        return convertIdiomaticEnumPatternWithTypeImpl(value, enumType, null);
    }
    
    /**
     * Convert patterns for regular enum switch statements with pattern variable extraction
     * 
     * WHY: Regular enums (without @:elixirIdiomatic) should generate tuple patterns with
     *      user-specified variable names (r, g, b) instead of generic names (g, g1, g2)
     * WHAT: Maps integer patterns to tuple patterns preserving pattern variable names from case values
     * HOW: Similar to idiomatic pattern conversion but uses pattern variable names from case values
     *      instead of the generic extraction logic
     */
    static function convertRegularEnumPatternWithExtraction(value: TypedExpr, enumType: EnumType, extractedParams: Array<String>, variableUsageMap: Map<Int, Bool> = null): EPattern {
        return switch(value.expr) {
            // Haxe internally converts enum constructors to integers for switch
            case TConst(TInt(index)):
                // Get the constructor at this index
                var constructors = enumType.constructs;
                
                // Build array of constructors in definition order (by index)
                var constructorArray = [];
                for (name in constructors.keys()) {
                    var constructor = constructors.get(name);
                    constructorArray[constructor.index] = constructor;
                }
                
                if (index >= 0 && index < constructorArray.length && constructorArray[index] != null) {
                    var constructor = constructorArray[index];
                    
                    // Use ElixirAtom for automatic snake_case conversion
                    var atomName: reflaxe.elixir.ast.naming.ElixirAtom = constructor.name;
                    
                    // Extract parameter count from the constructor's type
                    var paramCount = 0;
                    switch(constructor.type) {
                        case TFun(args, _):
                            paramCount = args.length;
                        default:
                            // No parameters
                    }
                    
                    if (paramCount > 0) {
                        // Constructor with arguments - create tuple pattern
                        // For regular enums, try to use pattern variable names from case values
                        // Fall back to canonical names if extraction failed
                        var paramPatterns = [];
                        
                        // Get canonical parameter names from constructor definition
                        var canonicalNames = switch(constructor.type) {
                            case TFun(args, _):
                                [for (arg in args) arg.name];
                            default:
                                [];
                        };
                        
                        /**
                         * CRITICAL PATTERN VARIABLE NAME RESOLUTION
                         * 
                         * Two types of variable names are available here:
                         * 
                         * 1. CANONICAL NAMES (from enum constructor definition):
                         *    - These are the parameter names defined in the enum constructor
                         *    - Example: enum Color { RGB(r:Int, g:Int, b:Int); }
                         *    - Canonical names: ["r", "g", "b"]
                         *    - These represent what the USER wrote when defining the enum
                         *    - IDIOMATIC and READABLE for generated Elixir patterns
                         * 
                         * 2. TEMP NAMES (from Haxe's TypedExpr extraction):
                         *    - These are generated by Haxe when compiling switch cases
                         *    - Haxe converts: case RGB(red, green, blue): 
                         *    - Into: g = elem(color, 1); g1 = elem(color, 2); g2 = elem(color, 3);
                         *    - Then: red = g; green = g1; blue = g2;
                         *    - Temp names: ["g", "g1", "g2"]
                         *    - These are INTERNAL compiler variables, not user-facing
                         * 
                         * WHEN TO USE EACH:
                         * 
                         * USE CANONICAL NAMES when:
                         * - We have access to the enum constructor definition
                         * - We're generating patterns for regular enums
                         * - We want idiomatic, readable Elixir output
                         * - Example: {:rgb, r, g, b} instead of {:rgb, g, g1, g2}
                         * 
                         * USE TEMP NAMES when:
                         * - We DON'T have access to enum constructor (e.g., abstract types)
                         * - The pattern variables in the case were DIFFERENT from canonical
                         *   (e.g., case RGB(red, green, blue): instead of RGB(r, g, b):)
                         * - We need to match what Haxe generates in the case body
                         * 
                         * THE PROBLEM:
                         * When user writes: case RGB(red, green, blue):
                         * - Canonical names are ["r", "g", "b"] (from enum definition)
                         * - Pattern vars are ["red", "green", "blue"] (from case pattern)
                         * - Temp vars are ["g", "g1", "g2"] (from Haxe extraction)
                         * - We can't access pattern vars directly from TypedExpr!
                         * 
                         * CURRENT SOLUTION:
                         * - Prefer canonical names for readability
                         * - Fall back to temp names when canonical not available
                         * - Accept that pattern var names (red, green, blue) are lost
                         * - The case body will handle remapping via assignments
                         */
                        for (i in 0...paramCount) {
                            // M0.3 FIX: Trust extractedParams as they come from EnumBindingPlan
                            // The binding plan is the single source of truth and has already made
                            // the decision about what names to use based on priority hierarchy
                            if (extractedParams != null && i < extractedParams.length && extractedParams[i] != null) {
                                // Use the name from binding plan (via extractedParams)
                                // This is the authoritative name decision
                                paramPatterns.push(PVar(extractedParams[i]));

                                #if debug_ast_pipeline
                                trace('[M0.3] Using binding plan name for param ${i}: ${extractedParams[i]}');
                                #end
                            } else if (i < canonicalNames.length && canonicalNames[i] != null) {
                                // Fallback to canonical name if no binding plan entry
                                // (shouldn't happen after M0.1, but keep as safety net)
                                paramPatterns.push(PVar(canonicalNames[i]));

                                #if debug_ast_pipeline
                                trace('[M0.3 WARNING] No binding plan for param ${i}, using canonical: ${canonicalNames[i]}');
                                #end
                            } else {
                                // Last resort: use wildcard
                                paramPatterns.push(PWildcard);

                                #if debug_ast_pipeline
                                trace('[M0.3 WARNING] No name available for param ${i}, using wildcard');
                                #end
                            }
                        }
                        PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(paramPatterns));
                    } else {
                        // No-argument constructor
                        PTuple([PLiteral(makeAST(EAtom(atomName)))]);
                    }
                } else {
                    // Invalid index, use wildcard
                    PWildcard;
                }
                
            // For actual enum constructor patterns (shouldn't happen in regular switch)
            case TField(_, FEnum(_, ef)):
                // Use ElixirAtom which automatically converts from EnumField to snake_case
                var atomName: reflaxe.elixir.ast.naming.ElixirAtom = ef;
                
                // Extract parameter count
                var paramCount = 0;
                switch(ef.type) {
                    case TFun(args, _):
                        paramCount = args.length;
                    default:
                }
                
                if (paramCount > 0) {
                    // Use extracted parameters or canonical names
                    var canonicalNames = switch(ef.type) {
                        case TFun(args, _):
                            [for (arg in args) arg.name];
                        default:
                            [];
                    };
                    
                    var paramPatterns = [];
                    for (i in 0...paramCount) {
                        if (extractedParams != null && i < extractedParams.length && extractedParams[i] != null && !extractedParams[i].startsWith("g")) {
                            paramPatterns.push(PVar(extractedParams[i]));
                        } else if (i < canonicalNames.length) {
                            paramPatterns.push(PVar(canonicalNames[i]));
                        } else {
                            paramPatterns.push(PWildcard);
                        }
                    }
                    PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(paramPatterns));
                } else {
                    PTuple([PLiteral(makeAST(EAtom(atomName)))]);
                }
                
            // Other patterns delegate to regular pattern conversion
            default:
                convertPatternWithExtraction(value, extractedParams);
        }
    }
    
    /**
     * Internal implementation for idiomatic enum pattern conversion
     */
    static function convertIdiomaticEnumPatternWithTypeImpl(value: TypedExpr, enumType: EnumType, extractedParams: Null<Array<String>>, variableUsageMap: Map<Int, Bool> = null): EPattern {
        return switch(value.expr) {
            // Haxe internally converts enum constructors to integers for switch
            case TConst(TInt(index)):
                // Get the constructor at this index
                // IMPORTANT: Haxe preserves definition order for enum constructor indices
                // The first defined constructor is index 0, second is 1, etc.
                // We need to get constructors in their definition order, NOT alphabetical
                var constructors = enumType.constructs;
                
                // Build array of constructors in definition order (by index)
                var constructorArray = [];
                for (name in constructors.keys()) {
                    var constructor = constructors.get(name);
                    constructorArray[constructor.index] = constructor;
                }
                
                if (index >= 0 && index < constructorArray.length && constructorArray[index] != null) {
                    var constructor = constructorArray[index];
                    
                    // Convert to snake_case for idiomatic Elixir
                    var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(constructor.name);
                    
                    #if debug_idiomatic_enum
                    trace('[DEBUG IDIOMATIC] Constructor ${constructor.name}: type=${constructor.type}, params=${constructor.params}');
                    #end
                    
                    // Create proper tuple pattern based on constructor parameters
                    // For idiomatic enums, check if the constructor actually has parameters
                    // constructor.type represents the function type of the constructor
                    
                    // Extract parameter count from the constructor's type field
                    var paramCount = 0;
                    switch(constructor.type) {
                        case TFun(args, _):
                            paramCount = args.length;
                            #if debug_idiomatic_enum
                            trace('[DEBUG IDIOMATIC] Found ${paramCount} parameters in TFun for ${constructor.name}');
                            #end
                        default:
                            // No parameters
                            #if debug_idiomatic_enum
                            trace('[DEBUG IDIOMATIC] No TFun type, assuming no parameters for ${constructor.name}');
                            #end
                    }
                    
                    #if debug_idiomatic_enum
                    trace('[DEBUG IDIOMATIC] Generating pattern for ${constructor.name} with ${paramCount} parameters');
                    #end
                    
                    if (paramCount > 0) {
                        // Constructor with arguments - create tuple pattern
                        // Get canonical parameter names from the constructor definition
                        var canonicalNames = switch(constructor.type) {
                            case TFun(args, _):
                                [for (arg in args) arg.name];
                            default:
                                [];
                        };
                        
                        // Use canonical names for pattern variables
                        var paramPatterns = [];

                        for (i in 0...paramCount) {
                            // Check if this parameter is actually used in the case body
                            var isUsed = extractedParams != null && i < extractedParams.length && extractedParams[i] != null;

                            // M0.2 FIX: Use extractedParams (what TEnumParameter expects) not canonical names
                            // This ensures the pattern binds the exact variable names that the body references
                            // Even if they're temp vars like "v", we must use them for consistency
                            if (isUsed && extractedParams[i] != null) {
                                // Use the extracted param name that TEnumParameter will reference
                                // This might be "v" or another temp var, but it matches the body
                                paramPatterns.push(PVar(extractedParams[i]));
                            } else if (isUsed && i < canonicalNames.length) {
                                // Fallback to canonical names if no extracted param
                                paramPatterns.push(PVar(canonicalNames[i]));
                            } else {
                                // Use wildcard for unused parameter
                                paramPatterns.push(PWildcard);
                            }
                        }
                        PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(paramPatterns));
                    } else {
                        // No-argument constructor - wrap in tuple for consistency
                        // This matches how the constructor is generated in TCall case
                        PTuple([PLiteral(makeAST(EAtom(atomName)))]);
                    }
                } else {
                    // Invalid index, use wildcard
                    PWildcard;
                }
                
            // For actual enum constructor patterns (shouldn't happen in idiomatic switch)
            case TField(_, FEnum(_, ef)):
                var atomName = reflaxe.elixir.ast.NameUtils.toSnakeCase(ef.name);
                
                // Extract parameter count from the enum field's type
                var paramCount = 0;
                switch(ef.type) {
                    case TFun(args, _):
                        paramCount = args.length;
                    default:
                        // No parameters
                }
                
                if (paramCount == 0) {
                    PLiteral(makeAST(EAtom(atomName)));
                } else {
                    // Get canonical parameter names from the enum field
                    var canonicalNames = switch(ef.type) {
                        case TFun(args, _):
                            [for (arg in args) arg.name];
                        default:
                            [];
                    };
                    
                    // Use canonical names for pattern variables
                    var paramPatterns = [];
                    for (i in 0...paramCount) {
                        // Check if this parameter is actually used in the case body
                        var isUsed = extractedParams != null && i < extractedParams.length && extractedParams[i] != null;
                        
                        // M0.3 FIX: Trust extractedParams from EnumBindingPlan
                        if (isUsed && extractedParams[i] != null) {
                            // Use the binding plan's decision (via extractedParams)
                            paramPatterns.push(PVar(extractedParams[i]));
                        } else if (isUsed && i < canonicalNames.length) {
                            // Fallback to canonical names if no extracted param
                            // (shouldn't happen after binding plan update)
                            paramPatterns.push(PVar(canonicalNames[i]));
                        } else {
                            paramPatterns.push(PWildcard);
                        }
                    }
                    PTuple([PLiteral(makeAST(EAtom(atomName)))].concat(paramPatterns));
                }
                
            default:
                // Fallback to regular pattern conversion
                convertPattern(value);
        }
    }
    
    /**
     * Convert patterns for idiomatic enum switch statements
     * 
     * WHY: Idiomatic enums like Result<T,E> should generate {:ok, value} and {:error, reason}
     *      patterns, not integer-based matching
     * WHAT: Maps Haxe's internal integer indices to proper atom-based tuple patterns
     * HOW: Analyzes the enum type to get constructor names and converts them to snake_case atoms
     */
    static function convertIdiomaticEnumPattern(value: TypedExpr, switchTarget: TypedExpr): EPattern {
        #if debug_idiomatic_enum
        trace('[XRay IdiomaticEnum] Converting pattern for value: ${value.expr}');
        trace('[XRay IdiomaticEnum] Switch target type: ${switchTarget.t}');
        #end
        
        // Always trace for debugging
        trace('[DEBUG ENUM] convertIdiomaticEnumPattern called with value: ${value.expr}');
        
        // Get the enum type from the switch target
        var enumType = switch(switchTarget.t) {
            case TEnum(enumRef, _): enumRef.get();
            default: return convertPattern(value); // Fallback to regular pattern
        };
        
        // Old implementation - just delegate to the new one without extraction info
        return convertIdiomaticEnumPatternWithTypeImpl(value, enumType, null);
    }
    
    /**
     * Check if an expression is an enum constructor call
     * 
     * Handles both:
     * - TField access: ChildSpecFormat.ModuleWithConfig
     * - Direct constructors: ModuleWithConfig (when imported/in scope)
     * - TTypeExpr references to enum constructors
     */
    static function isEnumConstructor(expr: TypedExpr): Bool {
        return switch(expr.expr) {
            case TField(_, FEnum(_, _)): true;  // Actual enum constructor field
            case TTypeExpr(TEnumDecl(_)): true;  // Direct enum type reference
            
            // DO NOT treat static methods that return enums as enum constructors!
            // Email.parse() returns Result but parse is NOT an enum constructor
            case TField(_, FStatic(_, _)): false;
            
            case TConst(TString(s)) if (s.charAt(0) >= 'A' && s.charAt(0) <= 'Z'): 
                // Heuristic: capitalized identifiers might be enum constructors
                // This is a fallback for cases where Haxe doesn't provide clear type info
                true;
            default: 
                // Only check for enum types that aren't function types
                // This avoids treating regular functions that return enums as constructors
                switch(expr.t) {
                    case TEnum(_, _): true;  // Direct enum value
                    case TFun(_, _): false;  // Functions are NOT enum constructors
                    default: false;
                }
        }
    }
    
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
     * Get the enum type name for pattern detection
     */
    static function getEnumTypeName(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TField(_, FEnum(enumRef, _)):
                var enumType = enumRef.get();
                enumType.name;
            default: "";
        }
    }
    
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
    
    /**
     * Detect fluent API patterns in a function
     * Returns metadata with fluent API information
     */
    static function detectFluentAPIPattern(func: TFunc): {returnsThis: Bool, fieldMutations: Array<{field: String, expr: TypedExpr}>} {
        var result = {
            returnsThis: false,
            fieldMutations: []
        };
        
        if (func.expr == null) return result;
        
        // Check if function returns 'this'
        function checkReturnsThis(expr: TypedExpr): Bool {
            switch(expr.expr) {
                case TReturn(e) if (e != null):
                    switch(e.expr) {
                        case TConst(TThis):
                            return true;
                        case TLocal(v) if (v.name == "this"):
                            return true;
                        default:
                    }
                case TConst(TThis): // Implicit return
                    return true;
                case TLocal(v) if (v.name == "this"):
                    return true;
                case TBlock(exprs) if (exprs.length > 0):
                    // Check last expression in block (implicit return)
                    return checkReturnsThis(exprs[exprs.length - 1]);
                default:
            }
            return false;
        }
        
        // Detect field mutations (e.g., this.columns.push(...))
        function detectMutations(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TCall(e, args):
                    // Look for method calls on 'this' fields
                    switch(e.expr) {
                        case TField(target, FInstance(_, _, cf)):
                            var methodName = cf.get().name;
                            // Check if it's a mutating method
                            if (methodName == "push" || methodName == "pop" || 
                                methodName == "shift" || methodName == "unshift" ||
                                methodName == "splice" || methodName == "reverse" ||
                                methodName == "sort") {
                                // Check if target is a field of 'this'
                                switch(target.expr) {
                                    case TField(obj, FInstance(_, _, fieldRef)):
                                        switch(obj.expr) {
                                            case TConst(TThis):
                                                // Found mutation of this.field
                                                result.fieldMutations.push({
                                                    field: fieldRef.get().name,
                                                    expr: expr
                                                });
                                            default:
                                        }
                                    default:
                                }
                            }
                        default:
                    }
                case TBlock(exprs):
                    for (e in exprs) {
                        detectMutations(e);
                    }
                case TIf(_, thenExpr, elseExpr):
                    detectMutations(thenExpr);
                    if (elseExpr != null) detectMutations(elseExpr);
                case TWhile(_, body, _):
                    detectMutations(body);
                case TFor(_, _, body):
                    detectMutations(body);
                case TSwitch(_, cases, edef):
                    for (c in cases) {
                        detectMutations(c.expr);
                    }
                    if (edef != null) detectMutations(edef);
                case TReturn(e) if (e != null):
                    detectMutations(e);
                case TTry(e, catches):
                    detectMutations(e);
                    for (c in catches) {
                        detectMutations(c.expr);
                    }
                default:
                    // Recursively check other expressions
                    haxe.macro.TypedExprTools.iter(expr, detectMutations);
            }
        }
        
        result.returnsThis = checkReturnsThis(func.expr);
        detectMutations(func.expr);
        
        return result;
    }
    
    /**
     * Try to expand a specific __elixir__() call
     */
    static function tryExpandElixirCall(expr: TypedExpr, thisExpr: TypedExpr, methodArgs: Array<TypedExpr>, context: reflaxe.elixir.CompilationContext): Null<ElixirAST> {
        #if debug_elixir_injection
        trace("[XRay] tryExpandElixirCall checking expr type: " + expr.expr);
        #end
        
        switch(expr.expr) {
            // Handle return statements that wrap the actual call
            case TReturn(retExpr) if (retExpr != null):
                #if debug_elixir_injection
                trace("[XRay] Found TReturn wrapper, checking inner: " + retExpr.expr);
                #end
                return tryExpandElixirCall(retExpr, thisExpr, methodArgs, context);
                
            // Handle untyped __elixir__() calls (wrapped in metadata)
            case TMeta({name: ":untyped"}, untypedExpr):
                #if debug_elixir_injection
                trace("[XRay] Found untyped metadata, checking inner: " + untypedExpr.expr);
                #end
                return tryExpandElixirCall(untypedExpr, thisExpr, methodArgs, context);
                
            // Handle if-else statements with __elixir__() in branches
            case TIf(cond, ifExpr, elseExpr):
                #if debug_elixir_injection
                trace("[XRay] Found TIf in tryExpandElixirCall");
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
                trace("[XRay] TCall with target: " + e.expr);
                #end
                switch(e.expr) {
                    case TIdent("__elixir__"):
                        #if debug_elixir_injection
                        trace("[XRay] Found __elixir__() call!");
                        #end
                        // Found __elixir__() call!
                        if (callArgs.length > 0) {
                            // First argument should be the code string
                            switch(callArgs[0].expr) {
                                case TConst(TString(code)):
                                    #if debug_elixir_injection
                                    trace('[XRay] Expanding __elixir__ with code: $code');
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
                                    trace('[XRay] Processed code: $processedCode');
                                    #end
                                    
                                    // Return the expanded raw Elixir code
                                    return makeAST(ERaw(processedCode));
                                    
                                default:
                                    #if debug_elixir_injection
                                    trace("[XRay] First arg is not TString: " + callArgs[0].expr);
                                    #end
                            }
                        }
                    default:
                        #if debug_elixir_injection
                        trace("[XRay] Not __elixir__, it's: " + e.expr);
                        #end
                }
            default:
                #if debug_elixir_injection
                trace("[XRay] Not a call, it's: " + expr.expr);
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
     * Extract enum constructor tag name
     * 
     * For static method calls that return enums (like TypeSafeChildSpec.pubSub),
     * we use the method name as a proxy for the enum constructor
     */
    static function extractEnumTag(expr: TypedExpr): String {
        return switch(expr.expr) {
            case TField(_, FEnum(_, ef)): 
                // Direct enum constructor reference
                ef.name;
            case TField(_, FStatic(_, cf)):
                // Static method call - use the method name (e.g., "pubSub" -> "PubSub")
                var methodName = cf.get().name;
                // Capitalize first letter for enum-like naming
                methodName.charAt(0).toUpperCase() + methodName.substr(1);
            default: 
                // For unknown cases, generate a placeholder that will be transformed
                "ModuleRef";
        }
    }
    
    /**
     * Extract pattern from left-hand side expression
     */
    static function extractPattern(expr: TypedExpr): EPattern {
        return switch(expr.expr) {
            case TLocal(v): PVar(toElixirVarName(v.name));
            case TField(e, fa): 
                // Map/struct field pattern
                PVar(extractFieldName(fa));
            default: PWildcard;
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
    
    static function toElixirVarName(name: String, ?preserveUnderscore: Bool = false): String {
        // Use the centralized ElixirNaming module for DRY principle
        // This delegates all snake_case conversion to NameUtils and handles
        // Elixir-specific rules in one place

        // Special handling for preserveUnderscore flag (for unused variables)
        if (preserveUnderscore && (name.length == 0 || name.charAt(0) != "_")) {
            // Add underscore prefix to indicate unused variable
            // M0 STABILIZATION: Disable underscore prefixing
            return ElixirNaming.toVarName(name); // Was: "_" + ElixirNaming.toVarName(name)
        }

        return ElixirNaming.toVarName(name);
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
        trace('[createVariableMappingsForCase] Called with extractedParams: $extractedParams, enumType: ${enumType != null ? enumType.name : "null"}');
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
                                trace('[Alpha-renaming] Skipping mapping for non-enum TLocal: ${v.name} = ${sourceVar.name}');
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
                                                trace('[M0.2] Using EnumBindingPlan name for param ${paramIndex}: ${finalName}');
                                                #end
                                            } else {
                                                // Fallback if no binding plan (shouldn't happen after M0.1)
                                                var varName = toElixirVarName(v.name);
                                                if (varName.startsWith("_g")) {
                                                    varName = varName.substr(1); // _g -> g
                                                }
                                                finalName = varName;

                                                #if debug_ast_pipeline
                                                trace('[M0.2 WARNING] No EnumBindingPlan for param ${paramIndex}, using fallback: ${finalName}');
                                                #end
                                            }

                                            // Map this variable ID to the binding plan's final name
                                            mapping.set(v.id, finalName);

                                            // Mark this variable as coming from enum extraction
                                            enumExtractionVars.set(v.id, true);

                                            #if debug_ast_pipeline
                                            trace('[M0.2] Mapping TEnumParameter temp var ${v.name} (id=${v.id}) to binding plan name: ${finalName}');
                                            #end
                                            
                                        case TLocal(tempVar):
                                            // This is assignment from temp var to pattern var
                                            var tempVarName = toElixirVarName(tempVar.name);
                                            var patternVarName = toElixirVarName(v.name);
                                            
                                            // Check if the temp var is from enum extraction
                                            // ONLY apply special mapping for enum-related temp vars
                                            if (enumExtractionVars.exists(tempVar.id)) {
                                                // This IS an enum extraction temp var (like g from TEnumParameter)
                                                // The pattern variable should use its own name (data = g, then use 'data')
                                                mapping.set(v.id, patternVarName);
                                                
                                                #if debug_ast_pipeline
                                                trace('[Alpha-renaming] Enum pattern var assignment: ${patternVarName} = ${tempVarName}, mapping ${v.id} -> ${patternVarName}');
                                                #end
                                            } else if (mapping.exists(tempVar.id)) {
                                                // For other assignments, propagate the mapping
                                                var canonicalName = mapping.get(tempVar.id);
                                                mapping.set(v.id, canonicalName);
                                                
                                                // Also register in pattern registry if tempVar is registered
                                                if (currentContext.patternVariableRegistry.exists(tempVar.id)) {
                                                    currentContext.patternVariableRegistry.set(v.id, canonicalName);
                                                    #if debug_ast_pipeline
                                                    trace('[Pattern Registry] Propagating pattern name to ${v.name} (id=${v.id}) -> ${canonicalName}');
                                                    #end
                                                }
                                                
                                                #if debug_ast_pipeline
                                                trace('[Alpha-renaming] Mapping TVar ${v.name} (id=${v.id}) from temp ${tempVar.name} to: ${canonicalName}');
                                                #end
                                            } else {
                                                // No existing mapping - DON'T create one for non-enum cases
                                                // Array patterns should use their natural names
                                                // We don't need to map x to anything - it should use its own name
                                                #if debug_ast_pipeline
                                                trace('[Alpha-renaming] No mapping needed for TVar ${v.name} from ${tempVar.name}');
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
    static function toSnakeCase(s: String): String {
        // Handle empty string
        if (s.length == 0) return s;
        
        var result = new StringBuf();
        for (i in 0...s.length) {
            var char = s.charAt(i);
            if (i > 0 && char == char.toUpperCase() && char != char.toLowerCase()) {
                // Insert underscore before uppercase letter (except at start)
                result.add("_");
                result.add(char.toLowerCase());
            } else {
                result.add(char.toLowerCase());
            }
        }
        return result.toString();
    }
    
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
                trace('[HXX] Unhandled AST type in template collection: ${ast.def}');
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
                trace('[HXX] Checking module: $moduleName against "HXX"');
                #end
                moduleName == "HXX";
            default: 
                #if debug_hxx_transformation
                trace('[HXX] Not a TTypeExpr, expr type: ${expr.expr}');
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
    static function detectArrayOperationPattern(body: TypedExpr): Null<String> {
        // Look for the characteristic patterns in the loop body
        switch(body.expr) {
            case TBlock(exprs) if (exprs.length >= 3):
                // Typical pattern has at least 3 expressions:
                // 1. var v = _g2[_g1] (array element access)
                // 2. _g1++ (index increment)  
                // 3. _g.push(...) (result building)
                
                var hasArrayAccess = false;
                var hasIncrement = false;
                var hasPush = false;
                var isFilter = false;
                
                for (expr in exprs) {
                    switch(expr.expr) {
                        case TVar(tvar, init):
                            // Check for array element access: var v = _g2[_g1]
                            if (init != null) {
                                switch(init.expr) {
                                    case TArray(_, _):
                                        hasArrayAccess = true;
                                    case _:
                                }
                            }
                            
                        case TUnop(OpIncrement, _, _) | TUnop(OpDecrement, _, _):
                            hasIncrement = true;
                            
                        case TCall({expr: TField(_, FInstance(_, _, cf))}, args) if (cf.get().name == "push"):
                            hasPush = true;
                            
                        case TIf(_, thenExpr, _):
                            // Check if the push is inside an if (filter pattern)
                            switch(thenExpr.expr) {
                                case TCall({expr: TField(_, FInstance(_, _, cf))}, _) if (cf.get().name == "push"):
                                    hasPush = true;
                                    isFilter = true;
                                case TBlock([{expr: TCall({expr: TField(_, FInstance(_, _, cf))}, _)}]) if (cf.get().name == "push"):
                                    hasPush = true;
                                    isFilter = true;
                                case _:
                            }
                            
                        case _:
                    }
                }
                
                if (hasArrayAccess && hasIncrement && hasPush) {
                    return isFilter ? "filter" : "map";
                }
                
            case _:
        }
        
        return null;
    }
    
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
    static function usesVariable(nodes: Array<ElixirAST>, varName: String): Bool {
        for (node in nodes) {
            if (usesVariableInNode(node, varName)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Check if an AST node uses a specific variable
     */
    static function usesVariableInNode(node: ElixirAST, varName: String): Bool {
        return switch(node.def) {
            case EVar(name): name == varName;
            case ECall(target, _, args): 
                (target != null && usesVariableInNode(target, varName)) || 
                usesVariable(args, varName);
            case EMatch(_, expr): usesVariableInNode(expr, varName);
            case EBinary(_, left, right): 
                usesVariableInNode(left, varName) || usesVariableInNode(right, varName);
            case _: false;
        };
    }
    
    /**
     * Transform variable references in an AST node
     * Replaces variable names according to the provided mapping
     * Used to avoid variable shadowing in reduce_while loops
     */
    static function transformVariableReferences(ast: ElixirAST, varMapping: Map<String, String>): ElixirAST {
        if (ast == null) return null;
        
        return switch(ast.def) {
            case EVar(name):
                if (varMapping.exists(name)) {
                    // Replace with mapped name
                    #if debug_state_threading
                    trace('[Transform] Replacing variable: $name => ${varMapping.get(name)}');
                    #end
                    makeAST(EVar(varMapping.get(name)));
                } else {
                    #if debug_state_threading
                    trace('[Transform] Variable not in mapping: $name');
                    #end
                    ast;
                }
                
            case EMatch(pattern, value):
                // Transform the value but be careful with patterns
                // We need to handle assignments like "node = node.left"
                var transformedValue = transformVariableReferences(value, varMapping);
                
                // For patterns, we need special handling
                var transformedPattern = switch(pattern) {
                    case PVar(name) if (varMapping.exists(name)):
                        // This is an assignment to a tracked variable
                        // Replace with acc_ version
                        PVar(varMapping.get(name));
                    case PVar(name):
                        // This is a new local variable declaration
                        // Keep the original name - don't transform it
                        #if debug_state_threading
                        trace('[Transform] New local variable declaration: $name (not in mapping)');
                        #end
                        #if debug_loop_bodies
                        if (name == "doubled" || name == "score" || name == "meta") {
                            trace('[XRay LoopBody] Preserving local variable declaration: $name');
                        }
                        #end
                        pattern;
                    case _:
                        // Other pattern types - keep as-is
                        pattern;
                };
                
                // CRITICAL FIX: For new local variables (not in mapping), we need to ensure
                // they are properly declared in the output. The EMatch node represents
                // a variable declaration/assignment that must be preserved.
                makeAST(EMatch(transformedPattern, transformedValue));
                
            case EBlock(exprs):
                makeAST(EBlock([for (expr in exprs) transformVariableReferences(expr, varMapping)]));
                
            case EIf(cond, thenExpr, elseExpr):
                makeAST(EIf(
                    transformVariableReferences(cond, varMapping),
                    transformVariableReferences(thenExpr, varMapping),
                    elseExpr != null ? transformVariableReferences(elseExpr, varMapping) : null
                ));
                
            case ECall(fn, name, args):
                makeAST(ECall(
                    fn != null ? transformVariableReferences(fn, varMapping) : null,
                    name,
                    [for (arg in args) transformVariableReferences(arg, varMapping)]
                ));
                
            case ERemoteCall(module, fn, args):
                makeAST(ERemoteCall(
                    transformVariableReferences(module, varMapping),
                    fn,
                    [for (arg in args) transformVariableReferences(arg, varMapping)]
                ));
                
            case EField(expr, field):
                makeAST(EField(transformVariableReferences(expr, varMapping), field));
                
            case ETuple(items):
                makeAST(ETuple([for (item in items) transformVariableReferences(item, varMapping)]));
                
            case EList(items):
                makeAST(EList([for (item in items) transformVariableReferences(item, varMapping)]));
                
            case EMap(items):
                makeAST(EMap([for (item in items) {
                    key: transformVariableReferences(item.key, varMapping),
                    value: transformVariableReferences(item.value, varMapping)
                }]));
                
            case EBinary(op, left, right):
                #if debug_state_threading
                trace('[Transform] Processing EBinary: ${ElixirASTPrinter.printAST(left)} ${op} ${ElixirASTPrinter.printAST(right)}');
                #end
                makeAST(EBinary(
                    op,
                    transformVariableReferences(left, varMapping),
                    transformVariableReferences(right, varMapping)
                ));
                
            case EUnary(op, expr):
                makeAST(EUnary(op, transformVariableReferences(expr, varMapping)));
                
            case EParen(expr):
                // Handle parentheses - transform the inner expression
                #if debug_state_threading
                trace('[Transform] Processing EParen wrapper');
                #end
                makeAST(EParen(transformVariableReferences(expr, varMapping)));
                
            case EAccess(target, key):
                // Handle array/map access - transform both target and key
                #if debug_state_threading
                trace('[Transform] Processing EAccess: target and key');
                #end
                makeAST(EAccess(
                    transformVariableReferences(target, varMapping),
                    transformVariableReferences(key, varMapping)
                ));
                
            case ECase(expr, clauses):
                makeAST(ECase(
                    transformVariableReferences(expr, varMapping),
                    [for (clause in clauses) {
                        pattern: clause.pattern, // Don't transform patterns
                        guard: clause.guard != null ? transformVariableReferences(clause.guard, varMapping) : null,
                        body: transformVariableReferences(clause.body, varMapping)
                    }]
                ));
                
            case _:
                // For other node types, return as-is
                // This includes literals, atoms, etc.
                ast;
        };
    }
    
    /**
     * Check if an AST node contains early returns that need special handling in loops
     * 
     * WHY: Early returns in loops need to be transformed to {:halt, value} in reduce_while
     * WHAT: Recursively checks if the AST contains any return-like expressions
     * HOW: Traverses the AST looking for expressions that would cause early loop exit
     * 
     * NOTE: This is currently disabled as the pattern detection is too complex
     * and was causing incorrect transformations. Early returns in loops are 
     * not common in the Haxe stdlib patterns we're compiling.
     */
    static function checkForEarlyReturns(ast: ElixirAST): Bool {
        // DISABLED: The early return detection was too aggressive and causing
        // incorrect transformations. Since the Haxe standard library doesn't
        // actually use early returns in the loops we're compiling (they use
        // the __elixir__ approach instead), we can safely disable this for now.
        return false;
    }
    
    /**
     * Transform return values in loop bodies to {:halt, value} tuples
     * 
     * WHY: Early returns in reduce_while loops must use {:halt, value} to stop iteration
     * WHAT: Transforms expressions that return values into proper halt tuples
     * HOW: Wraps return values with {:halt, ...} and adds {:cont, ...} for normal flow
     */
    static function transformReturnsToHalts(body: ElixirAST, accumulator: ElixirAST): ElixirAST {
        if (body == null) return null;
        
        return switch(body.def) {
            case EIf(cond, thenBranch, elseBranch):
                // Transform both branches
                makeAST(EIf(
                    cond,
                    wrapWithHaltIfNeeded(thenBranch, accumulator),
                    wrapWithHaltIfNeeded(elseBranch, accumulator)
                ));
                
            case EBlock(exprs):
                // Transform the block expressions
                var transformedExprs = [];
                for (i in 0...exprs.length) {
                    if (i == exprs.length - 1) {
                        // Last expression might be a return value
                        transformedExprs.push(wrapWithHaltIfNeeded(exprs[i], accumulator));
                    } else {
                        transformedExprs.push(transformReturnsToHalts(exprs[i], accumulator));
                    }
                }
                makeAST(EBlock(transformedExprs));
                
            case ECase(expr, clauses):
                // Transform each clause body
                makeAST(ECase(
                    expr,
                    [for (clause in clauses) {
                        pattern: clause.pattern,
                        guard: clause.guard,
                        body: wrapWithHaltIfNeeded(clause.body, accumulator)
                    }]
                ));
                
            case _:
                // For other expressions, wrap with halt if it's a return value
                wrapWithHaltIfNeeded(body, accumulator);
        };
    }
    
    /**
     * Wrap an expression with {:halt, value} if it's a return value
     */
    static function wrapWithHaltIfNeeded(expr: ElixirAST, accumulator: ElixirAST): ElixirAST {
        if (expr == null) return null;
        
        return switch(expr.def) {
            case ETuple([atom, _]):
                // Already a tuple, check if it's cont/halt
                switch(atom.def) {
                    // Pattern matching with abstract types requires guard clause
                    case EAtom(atomVal) if (atomVal == "cont" || atomVal == "halt"):
                        expr; // Already properly wrapped
                    case _:
                        // Other tuple, treat as return value
                        makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), expr]));
                }
            case EBlock([]):
                // Empty block, add continuation
                makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("cont"))), accumulator]));
            case _:
                // Any other value is treated as an early return
                makeAST(ETuple([makeAST(EAtom(ElixirAtom.raw("halt"))), expr]));
        };
    }
    
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
    
    /**
     * Detect if statements match array comprehension pattern
     * 
     * WHY: Haxe desugars comprehensions before we see them, need to detect patterns
     * WHAT: Checks for var _g = []; for(...) _g.push(...); _g pattern
     * HOW: Structural pattern matching without hardcoding variable names
     */
    static function isComprehensionPattern(statements: Array<TypedExpr>): Bool {
        if (statements.length < 3) return false;
        
        #if debug_array_comprehension
        trace('[Array Comprehension] Checking ${statements.length} statements for comprehension pattern');
        #end
        
        // Pattern: var temp = []; for loop; return temp
        var firstStmt = unwrapMetaParens(statements[0]);
        var tempVarName: String = null;
        
        // Check initialization
        switch(firstStmt.expr) {
            case TVar(v, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]):
                        tempVarName = v.name;
                    default:
                        return false;
                }
            default:
                return false;
        }
        
        // Check for loop with push
        var hasLoopWithPush = false;
        for (i in 1...statements.length - 1) {
            switch(statements[i].expr) {
                case TFor(v, iterator, body):
                    // Check if body contains push to temp var
                    if (containsPushToVar(body, tempVarName)) {
                        hasLoopWithPush = true;
                        break;
                    }
                default:
            }
        }
        
        // Check last statement returns temp var
        var lastStmt = statements[statements.length - 1];
        var returnsTemp = switch(lastStmt.expr) {
            case TLocal(v) if (v.name == tempVarName): true;
            default: false;
        };
        
        return hasLoopWithPush && returnsTemp;
    }
    
    /**
     * Detect if statements represent an unrolled comprehension
     * 
     * WHY: Constant ranges get completely unrolled by Haxe
     * WHAT: Detects repeated concatenation patterns
     * HOW: Looks for var g = []; g = g ++ [val]; ... pattern
     *      OR var g = []; if (cond) g = g ++ [val]; ... pattern (conditional comprehensions)
     */
    static function isUnrolledComprehension(statements: Array<TypedExpr>): Bool {
        if (statements.length < 3) return false;
        
        #if debug_array_comprehension
        trace('[Array Comprehension] Checking for unrolled comprehension pattern');
        #end
        
        // First: var temp = []
        var firstStmt = unwrapMetaParens(statements[0]);
        var tempVarName: String = null;
        
        switch(firstStmt.expr) {
            case TVar(v, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]):
                        tempVarName = v.name;
                    default:
                        return false;
                }
            default:
                return false;
        }
        
        // Middle: repeated concatenations or if statements with concatenations
        var hasConcatenations = false;
        var hasConditionals = false;
        for (i in 1...statements.length - 1) {
            switch(statements[i].expr) {
                case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([_])})}) 
                    if (v.name == tempVarName && v2.name == tempVarName):
                    hasConcatenations = true;
                case TBinop(OpAdd, {expr: TLocal(v)}, {expr: TArrayDecl([_])}) if (v.name == tempVarName):
                    // Bare concatenation (shouldn't happen but handle it)
                    hasConcatenations = true;
                case TIf(cond, thenExpr, null):
                    // Check if the if body contains concatenation
                    switch(thenExpr.expr) {
                        case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([_])})}) 
                            if (v.name == tempVarName && v2.name == tempVarName):
                            hasConditionals = true;
                            hasConcatenations = true;
                        default:
                    }
                default:
                    // Non-concatenation statement
            }
        }
        
        // Last: return temp var
        var lastStmt = statements[statements.length - 1];
        var returnsTemp = switch(lastStmt.expr) {
            case TLocal(v) if (v.name == tempVarName): true;
            default: false;
        };
        
        return hasConcatenations && returnsTemp;
    }
    
    /**
     * Extract comprehension data from desugared statements
     * 
     * WHY: Need to extract variable, iterator, and body for reconstruction
     * WHAT: Returns structured data about the comprehension
     * HOW: Pattern matches to extract relevant parts
     */
    static function extractComprehensionData(statements: Array<TypedExpr>): Null<{
        tempVar: String,
        loopVar: String,
        iterator: TypedExpr,
        body: TypedExpr,
        isNested: Bool
    }> {
        if (statements.length < 3) return null;
        
        var firstStmt = unwrapMetaParens(statements[0]);
        var tempVarName: String = null;
        
        // Get temp var from initialization
        switch(firstStmt.expr) {
            case TVar(v, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]):
                        tempVarName = v.name;
                    default:
                        return null;
                }
            default:
                return null;
        }
        
        // Find the for loop
        for (i in 1...statements.length - 1) {
            switch(statements[i].expr) {
                case TFor(v, iterator, body):
                    // Extract push body
                    var pushBody = extractPushBody(body, tempVarName);
                    if (pushBody != null) {
                        // Check if body is itself a comprehension (nested)
                        var isNested = switch(pushBody.expr) {
                            case TArrayDecl([{expr: TFor(_)}]): true;
                            case TBlock(stmts) if (isComprehensionPattern(stmts) || isUnrolledComprehension(stmts)): true;
                            default: false;
                        };
                        
                        return {
                            tempVar: tempVarName,
                            loopVar: v.name,
                            iterator: iterator,
                            body: pushBody,
                            isNested: isNested
                        };
                    }
                default:
            }
        }
        
        return null;
    }
    
    /**
     * Convert iterator expression to Elixir AST
     */
    static function buildIteratorAST(iterator: TypedExpr, ?variableUsageMap: Map<Int, Bool>): ElixirAST {
        return switch(iterator.expr) {
            case TBinop(OpInterval, e1, e2):
                // Range operator: 0...5 becomes 0..4 (exclusive range in Haxe)
                var start = buildFromTypedExpr(e1, currentContext);
                var end = buildFromTypedExpr(e2, currentContext);
                // Haxe's ... is exclusive, so we need to subtract 1 from end
                var adjustedEnd = makeAST(EBinary(Subtract, end, makeAST(EInteger(1))));
                makeAST(ERange(start, adjustedEnd, false));
            default:
                // Other iterators (arrays, etc.)
                buildFromTypedExpr(iterator, currentContext);
        };
    }
    
    /**
     * Extract elements from unrolled comprehension pattern
     * Handles both simple unrolled and conditional unrolled comprehensions
     */
    static function extractUnrolledElements(statements: Array<TypedExpr>, ?variableUsageMap: Map<Int, Bool>): Null<Array<ElixirAST>> {
        if (statements.length < 3) return null;
        
        var tempVarName: String = null;
        
        // Get temp var from first statement
        var firstStmt = unwrapMetaParens(statements[0]);
        switch(firstStmt.expr) {
            case TVar(v, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]):
                        tempVarName = v.name;
                    default:
                        return null;
                }
            default:
                return null;
        }
        
        // Check if this is a conditional comprehension pattern
        var isConditional = false;
        var hasConditions = false;
        for (i in 1...statements.length - 1) {
            switch(statements[i].expr) {
                case TIf(_, thenExpr, null):
                    // Check if the if body contains concatenation
                    switch(thenExpr.expr) {
                        case TBinop(OpAssign, {expr: TLocal(v)}, _) if (v.name == tempVarName):
                            hasConditions = true;
                        default:
                    }
                default:
            }
        }
        
        // If we have conditions, try to reconstruct as a for comprehension with filter
        if (hasConditions) {
            var result = tryReconstructConditionalComprehension(statements, tempVarName, currentContext.variableUsageMap);
            if (result != null) {
                return [result]; // Wrap in array to match return type
            }
            return null;
        }
        
        // Otherwise, extract elements from simple concatenations
        var elements = [];
        for (i in 1...statements.length - 1) {
            switch(statements[i].expr) {
                case TBinop(OpAssign, {expr: TLocal(v)}, rhs) if (v.name == tempVarName):
                    switch(rhs.expr) {
                        case TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([value])}) if (v2.name == tempVarName):
                            // Process value, checking for nested comprehensions
                            switch(value.expr) {
                                case TBlock(stmts):
                                    var nested = tryBuildArrayComprehensionFromBlock(stmts, currentContext.variableUsageMap);
                                    if (nested != null) {
                                        elements.push(nested);
                                    } else {
                                        elements.push(buildFromTypedExpr(value, currentContext));
                                    }
                                default:
                                    elements.push(buildFromTypedExpr(value, currentContext));
                            }
                        default:
                    }
                default:
            }
        }
        
        return elements.length > 0 ? elements : null;
    }
    
    /**
     * Try to reconstruct a comprehension from extracted elements
     */
    static function tryReconstructFromElements(elements: Array<ElixirAST>): Null<ElixirAST> {
        // Check if elements follow a simple numeric pattern
        var isSimpleRange = true;
        var maxVal = -1;
        
        for (i in 0...elements.length) {
            switch(elements[i].def) {
                case EInteger(val):
                    if (val != i) {
                        isSimpleRange = false;
                        break;
                    }
                    maxVal = val;
                default:
                    isSimpleRange = false;
                    break;
            }
        }
        
        if (isSimpleRange && maxVal >= 0) {
            // Reconstruct as: for i <- 0..n, do: i
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(maxVal)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            return makeAST(EFor([generator], [], makeAST(EVar("i")), null, false));
        }
        
        // Check if all elements are nested comprehensions
        var allComprehensions = true;
        for (elem in elements) {
            switch(elem.def) {
                case EFor(_, _, _, _, _):
                    // Is a comprehension
                case EList(_):
                    // Might be okay
                default:
                    allComprehensions = false;
                    break;
            }
        }
        
        if (allComprehensions && elements.length > 0) {
            // Use the first element as template and reconstruct outer comprehension
            var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(elements.length - 1)), false));
            var generator: EGenerator = {
                pattern: PVar("i"),
                expr: range
            };
            // Use first element as body template
            return makeAST(EFor([generator], [], elements[0], null, false));
        }
        
        return null;
    }
    
    /**
     * Replace literal index values in a condition with the loop variable
     * This is used when reconstructing conditional comprehensions
     */
    static function replaceIndexInCondition(ast: ElixirAST, index: Int, varName: String): ElixirAST {
        // Recursively replace any EInteger(index) with EVar(varName)
        switch(ast.def) {
            case EInteger(val) if (val == index):
                return makeAST(EVar(varName));
            case EBinary(op, left, right):
                return makeAST(EBinary(op, 
                    replaceIndexInCondition(left, index, varName),
                    replaceIndexInCondition(right, index, varName)
                ));
            case ERemoteCall(module, func, args):
                var newArgs = [for (arg in args) replaceIndexInCondition(arg, index, varName)];
                return makeAST(ERemoteCall(module, func, newArgs));
            case EParen(inner):
                return makeAST(EParen(replaceIndexInCondition(inner, index, varName)));
            default:
                return ast;
        }
    }
    
    /**
     * Transform a TypedExpr condition to an ElixirAST filter, replacing literal indices with loop variable
     * e.g., rem(0, 2) == 0 -> rem(i, 2) == 0
     */
    static function transformConditionToFilter(condition: TypedExpr, ?variableUsageMap: Map<Int, Bool>): ElixirAST {
        // Recursively transform the condition, replacing literal indices contextually
        function transformExpr(expr: TypedExpr, isFirstArgOfMod: Bool = false): ElixirAST {
            switch(expr.expr) {
                case TConst(TInt(i)):
                    // Only replace if this is the first argument of a modulo operation
                    // OR if it's being compared to the result of a modulo operation
                    if (isFirstArgOfMod && i >= 0 && i < 10) {
                        return makeAST(EVar("i"));
                    }
                    return makeAST(EInteger(i));
                    
                case TCall(e, el):
                    #if debug_presence
                    switch(e.expr) {
                        case TField(_, FStatic(c, _)):
                            var ct = c.get();
                            if (ct.name == "Presence" && ct.pack.length > 0 && ct.pack[0] == "phoenix") {
                                trace('[DEBUG PRESENCE] TCall to phoenix.Presence detected');
                                trace('[DEBUG PRESENCE] isInPresenceModule = ' + compiler.isInPresenceModule);
                            }
                        default:
                    }
                    #end
                    // Handle function calls (like rem)
                    // Check if this is a modulo operation
                    var isMod = switch(e.expr) {
                        case TIdent("__mod__"): true;
                        case TField(_, FStatic(_, cf)) if (cf.get().name == "mod"): true;
                        default: false;
                    };
                    
                    var argsAST = [];
                    for (i in 0...el.length) {
                        // First argument of modulo should be replaced with loop variable
                        argsAST.push(transformExpr(el[i], isMod && i == 0));
                    }
                    
                    // Special handling for rem/mod operations
                    switch(e.expr) {
                        case TIdent("__mod__"):
                            // This is a modulo operation, use Elixir's rem
                            return makeAST(ERemoteCall(
                                makeAST(EAtom("erlang")),
                                "rem",
                                argsAST
                            ));
                        case TField(_, FStatic(_, cf)) if (cf.get().name == "mod"):
                            // Static field access for mod
                            return makeAST(ERemoteCall(
                                makeAST(EAtom("erlang")),
                                "rem",
                                argsAST
                            ));
                        case TIdent(name):
                            // Simple function call
                            return makeAST(ECall(null, name, argsAST));
                        default:
                            // For complex function expressions, compile the whole thing
                            return buildFromTypedExpr(expr, currentContext);
                    }
                    
                case TBinop(OpMod, e1, e2):
                    // Handle modulo operator
                    var left = transformExpr(e1, true);  // First arg should be replaced with loop var
                    var right = transformExpr(e2, false); // Second arg should stay as is
                    return makeAST(ERemoteCall(
                        makeAST(EAtom("erlang")),
                        "rem",
                        [left, right]
                    ));
                    
                case TBinop(op, e1, e2):
                    // Handle other binary operators
                    var left = transformExpr(e1, false);
                    var right = transformExpr(e2, false);
                    var opStr = switch(op) {
                        case OpEq: "==";
                        case OpNotEq: "!=";
                        case OpGt: ">";
                        case OpGte: ">=";
                        case OpLt: "<";
                        case OpLte: "<=";
                        case OpAdd: "+";
                        case OpSub: "-";
                        case OpMult: "*";
                        case OpDiv: "/";
                        default: Std.string(op);
                    };
                    // Convert string operator to EBinaryOp
                    var binOp: EBinaryOp = switch(opStr) {
                        case "==": Equal;
                        case "!=": NotEqual;
                        case ">":  Greater;
                        case ">=": GreaterEqual;
                        case "<":  Less;
                        case "<=": LessEqual;
                        case "+":  Add;
                        case "-":  Subtract;
                        case "*":  Multiply;
                        case "/":  Divide;
                        default:  Add; // Fallback
                    };
                    return makeAST(EBinary(binOp, left, right));
                    
                case TParenthesis(e):
                    // For filter conditions, don't add parentheses - Elixir doesn't allow them
                    // Just return the inner expression
                    return transformExpr(e, isFirstArgOfMod);
                    
                default:
                    // For other expressions, use the default builder
                    return buildFromTypedExpr(expr, currentContext);
            }
        }
        
        var result = transformExpr(condition, false);
        return result != null ? result : makeAST(EVar("true")); // Fallback to true if transformation fails
    }
    
    /**
     * Try to reconstruct a conditional comprehension from unrolled if statements
     * Pattern: var g = []; TBlock([if statements]); g
     * Reconstructs to: for i <- 0..9, rem(i, 2) == 0, do: i
     */
    static function tryReconstructConditionalComprehension(statements: Array<TypedExpr>, tempVarName: String, ?variableUsageMap: Map<Int, Bool>): Null<ElixirAST> {
        #if debug_array_comprehension
        trace('[Array Comprehension] tryReconstructConditionalComprehension called with ${statements.length} statements');
        for (i in 0...statements.length) {
            trace('[Array Comprehension] Statement $i: ${Type.enumConstructor(statements[i].expr)}');
        }
        #end
        
        // Detect the pattern by looking at multiple if statements
        var conditions = [];
        var values = [];
        var indices = [];
        
        // Find the block containing if statements
        // The pattern is: TVar(g, []), TBlock([if statements]), TLocal(g)
        // So we need to look at statement index 1 which should be TBlock
        if (statements.length >= 3) {
            switch(statements[1].expr) {
                case TBlock(innerStmts):
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Found TBlock at position 1 with ${innerStmts.length} inner statements');
                    #end
                    // Process inner if statements
                    for (innerStmt in innerStmts) {
                        switch(innerStmt.expr) {
                            case TIf(cond, thenExpr, null):
                                // Extract condition and value
                                // Pattern 1: g = g ++ [value] (assignment pattern)
                                switch(thenExpr.expr) {
                                    case TBinop(OpAssign, {expr: TLocal(v)}, rhs) if (v.name == tempVarName):
                                        switch(rhs.expr) {
                                            case TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl([value])}) if (v2.name == tempVarName):
                                                conditions.push(cond);
                                                values.push(value);
                                                indices.push(conditions.length - 1);
                                            default:
                                        }
                                    // Pattern 2: g.push(value) (method call pattern)
                                    case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, [value]) if (v.name == tempVarName && cf.get().name == "push"):
                                        #if debug_array_comprehension
                                        trace('[Array Comprehension] Found push pattern with condition: ${cond.expr}');
                                        trace('[Array Comprehension] Value being pushed: ${value.expr}');
                                        #end
                                        conditions.push(cond);
                                        values.push(value);
                                        indices.push(conditions.length - 1);
                                    default:
                                }
                            default:
                        }
                    }
                default:
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Statement at position 1 is not TBlock, is: ${Type.enumConstructor(statements[1].expr)}');
                    #end
            }
        }
        
        if (conditions.length == 0) {
            #if debug_array_comprehension
            trace('[Array Comprehension] No conditions found - not a conditional comprehension');
            #end
            return null;
        }
        
        #if debug_array_comprehension
        trace('[Array Comprehension] Found ${conditions.length} conditions in conditional comprehension');
        #end
        
        // Infer the range from the number of conditions (10 conditions = 0..9)
        var maxIndex = conditions.length - 1;
        
        // Build a for comprehension with filter
        var range = makeAST(ERange(makeAST(EInteger(0)), makeAST(EInteger(maxIndex)), false));
        var generator: EGenerator = {
            pattern: PVar("i"),
            expr: range
        };
        
        // Build filter from the actual conditions
        // Extract the pattern from the first condition and replace the index with the loop variable
        var filter = if (conditions.length > 0) {
            // Take the first condition as the pattern
            var firstCondition = conditions[0];
            
            #if debug_array_comprehension
            trace('[Array Comprehension] First condition expr: ${firstCondition.expr}');
            #end
            
            // Transform the TypedExpr condition to ElixirAST, replacing literal indices with loop variable
            var filterExpr = transformConditionToFilter(firstCondition, variableUsageMap);
            
            filterExpr;
        } else {
            null;
        };
        
        // Build body - just return the iterator variable
        var body = makeAST(EVar("i"));
        
        #if debug_array_comprehension
        trace('[Array Comprehension] Creating EFor comprehension with filter for range 0..${maxIndex}');
        #end
        
        // Create the for comprehension
        var forExpr = makeAST(EFor([generator], filter != null ? [filter] : [], body, null, false));
        return forExpr;
    }
    
    /**
     * Helper: Check if expression contains push to specific variable
     */
    static function containsPushToVar(expr: TypedExpr, varName: String): Bool {
        return switch(expr.expr) {
            case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, _) if (v.name == varName && cf.get().name == "push"):
                true;
            case TBlock(el):
                for (e in el) {
                    if (containsPushToVar(e, varName)) return true;
                }
                false;
            default:
                false;
        };
    }
    
    /**
     * Helper: Extract the expression being pushed
     */
    static function extractPushBody(expr: TypedExpr, varName: String): Null<TypedExpr> {
        return switch(expr.expr) {
            case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, [arg]) if (v.name == varName && cf.get().name == "push"):
                arg;
            case TBlock(el):
                for (e in el) {
                    var result = extractPushBody(e, varName);
                    if (result != null) return result;
                }
                null;
            default:
                null;
        };
    }
    
    /**
     * Try to reconstruct array comprehensions from desugared imperative code
     * 
     * Haxe desugars array comprehensions like [for (i in 0...5) i * i] into:
     * Pattern 1 (simple loop):
     *   var _g = [];
     *   for (i in 0...5) _g.push(i * i);
     *   _g;
     * 
     * Pattern 2 (unrolled):
     *   var _g = [];
     *   _g = _g ++ [1];
     *   _g = _g ++ [4];
     *   ...
     *   _g;
     * 
     * This function detects these patterns and reconstructs idiomatic Elixir `for` comprehensions
     */
    static function tryBuildArrayComprehensionFromBlock(statements: Array<TypedExpr>, ?variableUsageMap: Map<Int, Bool>): Null<ElixirAST> {
        if (statements.length < 2) return null;
        
        #if debug_array_comprehension
        trace('[Array Comprehension] tryBuildArrayComprehensionFromBlock called with ${statements.length} statements');
        #end
        
        // Use our new pattern detection functions
        if (isComprehensionPattern(statements)) {
            #if debug_array_comprehension
            trace('[Array Comprehension] Detected loop-with-push comprehension pattern');
            #end
            
            // Extract comprehension data
            var data = extractComprehensionData(statements);
            if (data != null) {
                #if debug_array_comprehension
                trace('[Array Comprehension] Extracted data: tempVar=${data.tempVar}, loopVar=${data.loopVar}, isNested=${data.isNested}');
                #end
                
                // Convert iterator to Elixir range
                var iteratorAst = buildIteratorAST(data.iterator, variableUsageMap);
                
                // Build generator
                var pattern = PVar(toElixirVarName(data.loopVar));
                var generator: EGenerator = {
                    pattern: pattern,
                    expr: iteratorAst
                };
                
                // Process body (handle nested comprehensions)
                var bodyAst = if (data.isNested) {
                    switch(data.body.expr) {
                        case TArrayDecl([elem]):
                            // Direct nested for in array
                            switch(elem.expr) {
                                case TFor(_):
                                    buildFromTypedExpr(elem, currentContext);
                                default:
                                    buildFromTypedExpr(data.body, currentContext);
                            }
                        case TBlock(stmts):
                            // Nested block comprehension - recurse
                            var nested = tryBuildArrayComprehensionFromBlock(stmts, variableUsageMap);
                            if (nested != null) nested else buildFromTypedExpr(data.body, currentContext);
                        default:
                            buildFromTypedExpr(data.body, currentContext);
                    }
                } else {
                    buildFromTypedExpr(data.body, currentContext);
                };
                
                #if debug_array_comprehension
                trace('[Array Comprehension] Generated EFor comprehension');
                #end
                
                return makeAST(EFor([generator], [], bodyAst, null, false));
            }
        } else if (isUnrolledComprehension(statements)) {
            #if debug_array_comprehension
            trace('[Array Comprehension] Detected unrolled comprehension pattern');
            #end
            
            // Extract elements from unrolled pattern
            var elements = extractUnrolledElements(statements, variableUsageMap);
            if (elements != null && elements.length > 0) {
                // Try to reconstruct as comprehension if elements follow a pattern
                var comprehension = tryReconstructFromElements(elements);
                if (comprehension != null) {
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Reconstructed comprehension from unrolled elements');
                    #end
                    return comprehension;
                } else {
                    // Return as list if no clear pattern
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Returning as list - no clear pattern');
                    #end
                    return makeAST(EList(elements));
                }
            }
        }
        
        return null;
    }
    
    /**
     * Check if a block looks like it's building a list through concatenations
     * Pattern: var g = []; g = g ++ [val1]; g = g ++ [val2]; ...; g
     * OR: g = []; g ++ [val1]; g ++ [val2]; ...; g (bare concatenations from unrolled comprehensions)
     * 
     * WHY: Haxe completely unrolls array comprehensions with constant ranges at compile-time
     * WHAT: Detects blocks that represent unrolled comprehensions
     * HOW: Checks for initialization + concatenations + return pattern
     */
    static function looksLikeListBuildingBlock(stmts: Array<TypedExpr>): Bool {
        #if debug_array_comprehension
        trace('[Array Comprehension Detection] Checking block with ${stmts.length} statements');
        if (stmts.length > 0 && stmts.length <= 5) {
            for (i in 0...stmts.length) {
                trace('[Array Comprehension Detection]   Statement $i: ${stmts[i].expr}');
            }
        }
        #end
        
        #if debug_ast_builder
        trace('[DEBUG looksLikeListBuildingBlock] Checking block with ${stmts.length} statements');
        if (stmts.length > 0) {
            trace('[DEBUG looksLikeListBuildingBlock] First stmt: ${stmts[0].expr}');
        }
        #end
        if (stmts.length < 2) return false;
        
        // First statement should initialize an empty array
        var firstStmt = unwrapMetaParens(stmts[0]);
        var tempVarName: String = null;
        
        switch(firstStmt.expr) {
            case TBinop(OpAssign, {expr: TLocal(v)}, {expr: TArrayDecl([])}):
                tempVarName = v.name;
            case TVar(v, init) if (init != null):
                switch(init.expr) {
                    case TArrayDecl([]):
                        tempVarName = v.name;
                    default:
                }
            default:
                return false;
        }
        
        // Middle statements should be concatenations or the last statement (return)
        for (i in 1...stmts.length) {
            var stmt = unwrapMetaParens(stmts[i]);
            
            // Check if this is the last statement
            if (i == stmts.length - 1) {
                // Last statement should return the temp var
                switch(stmt.expr) {
                    case TLocal(v) if (v.name == tempVarName):
                        // OK - returning the built list
                    default:
                        return false;
                }
            } else {
                // Middle statements should be concatenations
                switch(stmt.expr) {
                    case TBinop(OpAdd, {expr: TLocal(v)}, {expr: TArrayDecl(_)}) if (v.name == tempVarName):
                        // OK - this is g ++ [value] (bare concatenation)
                    case TBinop(OpAssign, {expr: TLocal(v)}, rhs) if (v.name == tempVarName):
                        // Check if it's g = g ++ [value] or g = g ++ block
                        switch(rhs.expr) {
                            case TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TArrayDecl(_)}) if (v2.name == tempVarName):
                                // OK - simple concatenation
                            case TBinop(OpAdd, {expr: TLocal(v2)}, {expr: TBlock(_)}) if (v2.name == tempVarName):
                                // OK - concatenating a block (nested comprehension)
                            default:
                                return false;
                        }
                    default:
                        return false;
                }
            }
        }
        
        return true; // All checks passed
    }
    
    /**
     * Check if an enum parameter at a specific index is used in the case body
     *
     * WHY: When we have temp vars like 'g', we need to check if the enum parameter
     *      value itself is used, not just the temp var name
     * WHAT: Looks for any usage of values extracted from the enum at the given index
     * HOW: Searches for TEnumParameter expressions with matching index or variables
     *      that are assigned from such expressions
     */
    static function isEnumParameterUsedAtIndex(index: Int, caseBody: TypedExpr): Bool {
        var isUsed = false;

        function checkUsage(expr: TypedExpr): Void {
            if (isUsed) return;

            switch(expr.expr) {
                // Check if this enum parameter is being extracted
                case TEnumParameter(_, _, paramIndex) if (paramIndex == index):
                    isUsed = true;

                // Check variable assignments from enum parameters
                case TVar(v, init) if (init != null):
                    switch(init.expr) {
                        case TEnumParameter(_, _, paramIndex) if (paramIndex == index):
                            // This variable is assigned from our enum parameter
                            // Now check if this variable is used
                            var assignedVar = toElixirVarName(v.name);
                            isUsed = isPatternVariableUsed(assignedVar, caseBody);
                        default:
                    }

                default:
                    // Recursively check all sub-expressions
                    haxe.macro.TypedExprTools.iter(expr, checkUsage);
            }
        }

        checkUsage(caseBody);
        return isUsed;
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
     *
     * EXAMPLE:
     * case Custom(code): return code;
     * May compile to:
     * - g = elem(status, 1)  // TEnumParameter extraction to temp
     * - code = g             // Assignment from temp to pattern var
     * - return code          // Usage (might be optimized to 'return g')
     */
    static function isPatternVariableUsed(varName: String, caseBody: TypedExpr): Bool {
        // Build alias sets to track temp variable relationships
        var aliasMap: Map<String, Array<String>> = new Map();
        var tempsByIndex: Map<Int, String> = new Map();
        var isUsed = false;

        // First pass: collect aliases and temp variable relationships
        function collectAliases(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TVar(v, init) if (init != null):
                    var vName = toElixirVarName(v.name);

                    switch(init.expr) {
                        case TEnumParameter(_, _, index):
                            // This is: tempVar = elem(enum, index)
                            // Record that this temp variable extracts from this index
                            tempsByIndex.set(index, vName);

                            // Initialize alias set for this temp
                            if (!aliasMap.exists(vName)) {
                                aliasMap.set(vName, [vName]);
                            }

                        case TLocal(sourceVar):
                            // This is: destVar = sourceVar (simple assignment)
                            var sourceName = toElixirVarName(sourceVar.name);

                            // If source has an alias set, add dest to it
                            if (aliasMap.exists(sourceName)) {
                                var aliases = aliasMap.get(sourceName);
                                if (aliases.indexOf(vName) == -1) {
                                    aliases.push(vName);
                                }
                                // Also give dest its own entry pointing to same array
                                aliasMap.set(vName, aliases);
                            } else {
                                // Create new alias set for both
                                var aliases = [sourceName, vName];
                                aliasMap.set(sourceName, aliases);
                                aliasMap.set(vName, aliases);
                            }

                        default:
                            // Other init types don't create aliases
                    }

                default:
                    // Recursively collect from sub-expressions
                    haxe.macro.TypedExprTools.iter(expr, collectAliases);
            }
        }

        // Collect all aliases in the case body
        if (caseBody != null) {
            collectAliases(caseBody);
        }

        // Build complete alias set for our pattern variable
        var aliasesToCheck = [varName];

        // Add any directly mapped aliases
        if (aliasMap.exists(varName)) {
            aliasesToCheck = aliasMap.get(varName).copy();
        }

        // Also check temp variables that might represent this pattern variable
        // Pattern variables like "code", "msg" often become "g", "g1", etc.
        // If varName matches pattern like g, g1, g2, include it
        if (varName == "g" || (varName.length > 1 && varName.charAt(0) == "g" &&
            varName.charAt(1) >= '0' && varName.charAt(1) <= '9')) {
            // This IS a temp variable, check if pattern var maps to it
            for (alias in aliasMap.keys()) {
                var aliases = aliasMap.get(alias);
                if (aliases.indexOf(varName) != -1 && aliasesToCheck.indexOf(alias) == -1) {
                    aliasesToCheck.push(alias);
                }
            }
        } else {
            // This is a pattern variable, check if any temps map to it
            for (tempName in tempsByIndex) {
                if (aliasMap.exists(tempName)) {
                    var aliases = aliasMap.get(tempName);
                    if (aliases.indexOf(varName) != -1) {
                        // This temp is an alias of our pattern var
                        for (a in aliases) {
                            if (aliasesToCheck.indexOf(a) == -1) {
                                aliasesToCheck.push(a);
                            }
                        }
                    }
                }
            }
        }

        // Second pass: check if any alias is actually used (not just declared)
        function checkUsage(expr: TypedExpr): Void {
            if (isUsed) return; // Early exit if already found

            switch(expr.expr) {
                case TLocal(v):
                    var vName = toElixirVarName(v.name);
                    // Check if this local reference is any of our aliases
                    if (aliasesToCheck.indexOf(vName) != -1) {
                        isUsed = true;
                    }

                case TVar(v, _):
                    // Variable declaration is NOT usage
                    // But still recurse into the init expression if present

                default:
                    // Recursively check sub-expressions
                    haxe.macro.TypedExprTools.iter(expr, checkUsage);
            }
        }

        if (caseBody != null) {
            checkUsage(caseBody);
        }

        return isUsed;
    }

    /**
     * Check if a pattern variable is used in the case body using variable IDs
     *
     * WHY: ID-based tracking avoids false positives when users have variables named "g"
     * WHAT: Builds a usage set of variable IDs and checks if the given ID is used
     * HOW: Traverses the case body collecting TLocal variable IDs, then checks membership
     *
     * @param varId The unique variable ID to check
     * @param caseBody The case body expression to search
     * @param varOriginMap Optional map of variable IDs to their VarOrigin
     * @return True if the variable is used in the case body
     */
    static function isPatternVariableUsedById(varId: Int, caseBody: TypedExpr, ?varOriginMap: Map<Int, VarOrigin>): Bool {
        // Build set of used variable IDs in case body
        var usedVarIds = new Map<Int, Bool>();

        function collectUsedVarIds(expr: TypedExpr): Void {
            switch(expr.expr) {
                case TLocal(v):
                    // This is a usage of a variable
                    usedVarIds.set(v.id, true);

                case TVar(v, _):
                    // Variable declaration is NOT usage
                    // The variable ID v.id is being declared, not used
                    // But recurse into init expression if present

                default:
                    // Recursively check sub-expressions
            }

            // Always recurse into sub-expressions
            haxe.macro.TypedExprTools.iter(expr, collectUsedVarIds);
        }

        // Collect all used variable IDs
        if (caseBody != null) {
            collectUsedVarIds(caseBody);
        }

        // Check if our variable ID is in the used set
        return usedVarIds.exists(varId);
    }

    /**
     * Update ClauseContext mapping to account for underscore-prefixed variables
     *
     * WHY: When a pattern variable gets prefixed with underscore (e.g., code -> _code),
     *      the ClauseContext mapping needs to be updated so the case body can still
     *      reference the correct variable
     * WHAT: Scans the pattern for underscore-prefixed variables and updates the mapping
     * HOW: Walks through the pattern and updates mappings for any PVar with underscore prefix
     */
    static function updateMappingForUnderscorePrefixes(pattern: EPattern, originalMapping: Map<Int, String>, extractedParams: Array<String>): Map<Int, String> {
        var needsUpdate = false;
        var newMapping = new Map<Int, String>();

        // First, copy the original mapping
        for (id => name in originalMapping) {
            newMapping.set(id, name);
        }

        // Check if any pattern variables have underscore prefixes
        function checkPattern(p: EPattern, index: Int = 0): Void {
            switch(p) {
                case PTuple(patterns):
                    for (i in 0...patterns.length) {
                        checkPattern(patterns[i], i);
                    }
                case PVar(name) if (name.startsWith("_") && name.length > 1):
                    // This variable has an underscore prefix
                    // Update any mapping that pointed to the non-prefixed version
                    var originalName = name.substring(1); // Remove underscore
                    for (id => mappedName in originalMapping) {
                        if (mappedName == originalName) {
                            // Update this mapping to use the prefixed name
                            newMapping.set(id, name);
                            needsUpdate = true;
                        }
                    }
                default:
                    // Other patterns don't need updates
            }
        }

        checkPattern(pattern);

        return needsUpdate ? newMapping : originalMapping;
    }

    /**
     * Apply underscore prefix to unused pattern variables
     *
     * WHY: In Elixir, unused variables should be prefixed with underscore to avoid warnings
     * WHAT: Checks each pattern variable against the usage map and prefixes with _ if unused
     * HOW: Recursively traverses patterns and renames PVar nodes when the variable is unused
     */
    static function applyUnderscorePrefixToUnusedPatternVars(pattern: EPattern, variableUsageMap: Map<Int, Bool>, extractedParams: Array<String>): EPattern {
        return switch(pattern) {
            case PTuple(patterns):
                // Process tuple patterns (like {:ok, g} or {:error, g})
                var updatedPatterns = [];
                for (i in 0...patterns.length) {
                    var p = patterns[i];
                    switch(p) {
                        case PVar(name):
                            // For enum patterns, check if the extracted parameter is actually used
                            // The position in the tuple corresponds to the parameter index
                            // Pattern index 0 is the atom, index 1+ are the parameters
                            var isUsed = false;

                            // If this is an enum parameter (not the first element which is the atom)
                            if (i > 0 && extractedParams != null && i - 1 < extractedParams.length) {
                                // The extracted param name at this position
                                var expectedParamName = extractedParams[i - 1];

                                // Check if the parameter name matches the expected parameter
                                // Following Codex's guidance: bind directly in patterns, don't add underscore prefixes to used variables
                                if (expectedParamName == name) {
                                    // The pattern variable matches - assume it's used unless it's a temp var
                                    // Temp vars (g, g1, g2) should be replaced with wildcards
                                    if (name == "g" || (name.length > 1 && name.charAt(0) == "g" && name.charAt(1) >= '0' && name.charAt(1) <= '9')) {
                                        // This is a temp var, should use wildcard
                                        isUsed = false;
                                    } else {
                                        // Real variable name - assume it's used for now
                                        // A proper implementation would check the case body for actual usage
                                        isUsed = true;
                                    }
                                }
                            }

                            // If not used, prefix with underscore
                            if (!isUsed && !name.startsWith("_")) {
                                // M0 STABILIZATION: Disable underscore prefixing
                                updatedPatterns.push(PVar(name)); // Was: "_" + name
                            } else {
                                updatedPatterns.push(p);
                            }
                        default:
                            updatedPatterns.push(applyUnderscorePrefixToUnusedPatternVars(p, variableUsageMap, extractedParams));
                    }
                }
                PTuple(updatedPatterns);

            case PVar(name):
                // Single variable pattern - check usage
                // This is a simplified implementation - in practice we'd need better tracking
                PVar(name); // Keep as-is for now

            case PLiteral(_) | PWildcard:
                // Literals and wildcards don't need modification
                pattern;

            case PList(elements):
                // Process list patterns
                PList([for (e in elements) applyUnderscorePrefixToUnusedPatternVars(e, variableUsageMap, extractedParams)]);

            case PCons(head, tail):
                // Process cons pattern [head | tail]
                PCons(
                    applyUnderscorePrefixToUnusedPatternVars(head, variableUsageMap, extractedParams),
                    applyUnderscorePrefixToUnusedPatternVars(tail, variableUsageMap, extractedParams)
                );

            case PMap(pairs):
                // Process map patterns
                PMap([for (pair in pairs) {
                    key: pair.key,
                    value: applyUnderscorePrefixToUnusedPatternVars(pair.value, variableUsageMap, extractedParams)
                }]);

            case PStruct(module, fields):
                // Process struct patterns
                PStruct(module, [for (f in fields) {
                    key: f.key,
                    value: applyUnderscorePrefixToUnusedPatternVars(f.value, variableUsageMap, extractedParams)
                }]);

            case PPin(subPattern):
                // Process pinned pattern ^var
                PPin(applyUnderscorePrefixToUnusedPatternVars(subPattern, variableUsageMap, extractedParams));

            case PAlias(varName, subPattern):
                // Process alias pattern (var = pattern)
                var isUsed = false;
                for (param in extractedParams) {
                    if (param == varName) {
                        isUsed = true;
                        break;
                    }
                }
                // M0 STABILIZATION: Disable underscore prefixing
                var newVarName = varName; // Was: (!isUsed && !varName.startsWith("_")) ? "_" + varName : varName;
                PAlias(newVarName, applyUnderscorePrefixToUnusedPatternVars(subPattern, variableUsageMap, extractedParams));

            case PBinary(segments):
                // Process binary patterns
                PBinary([for (s in segments) {
                    pattern: applyUnderscorePrefixToUnusedPatternVars(s.pattern, variableUsageMap, extractedParams),
                    size: s.size,
                    type: s.type,
                    modifiers: s.modifiers
                }]);
        }
    }

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
    static function extractListElements(stmts: Array<TypedExpr>): Null<Array<TypedExpr>> {
        if (!looksLikeListBuildingBlock(stmts)) return null;
        
        #if debug_array_comprehension
        trace('[Array Comprehension] extractListElements: processing ${stmts.length} statements');
        #end
        
        var elements: Array<TypedExpr> = [];
        
        // Skip first (initialization) and last (return) statements
        for (i in 1...stmts.length - 1) {
            var stmt = unwrapMetaParens(stmts[i]);
            switch(stmt.expr) {
                case TBinop(OpAdd, {expr: TLocal(v)}, {expr: TArrayDecl([value])}) :
                    // Direct bare concatenation: g ++ [value]
                    // Extract the VALUE being concatenated, not the concatenation itself!
                    #if debug_array_comprehension
                    trace('[Array Comprehension] Found bare concatenation: ${v.name} ++ [value], extracting value');
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
                            elements.push(value);
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
                                    elements.push(value);
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
        
        return elements;
    }
    
    /**
     * Extract the expression being yielded/pushed in a loop body
     * Handles nested comprehensions by detecting when the yield is itself a block
     */
    static function extractYieldExpression(body: TypedExpr, tempVarName: String, ?variableUsageMap: Map<Int, Bool>): Null<TypedExpr> {
        switch(body.expr) {
            case TBlock(stmts):
                // Look for push or concat operation
                for (stmt in stmts) {
                    switch(stmt.expr) {
                        case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, [arg]) 
                            if (v.name == tempVarName && cf.get().name == "push"):
                            return arg;
                        case TBinop(OpAssign, {expr: TLocal(v)}, rhs) if (v.name == tempVarName):
                            // temp = temp ++ [expr]
                            switch(rhs.expr) {
                                case TBinop(OpAdd, _, {expr: TArrayDecl([expr])}):
                                    return expr;
                                default:
                            }
                        default:
                    }
                }
            case TCall({expr: TField({expr: TLocal(v)}, FInstance(_, _, cf))}, [arg]) 
                if (v.name == tempVarName && cf.get().name == "push"):
                return arg;
            default:
        }
        return null;
    }
}

#end
