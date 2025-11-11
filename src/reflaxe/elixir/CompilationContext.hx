package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.behaviors.BehaviorTransformer;
import reflaxe.elixir.ast.context.ElixirASTContext;
import reflaxe.elixir.ast.context.BuildContext;
import reflaxe.elixir.ast.builders.BuilderFacade;
import reflaxe.elixir.ast.builders.IBuilder;
import reflaxe.elixir.ast.ReentrancyGuard;
import haxe.macro.Expr.Position;
import haxe.ds.ObjectMap;

/**
 * CompilationContext: Instance-based compilation state container
 *
 * WHY: Eliminate static state contamination that causes variable shadowing bugs
 * when running tests in parallel. Static variables in ElixirASTBuilder persist
 * across compilation units, causing cross-contamination when tests run with -j8.
 *
 * WHAT: Holds all compilation state as instance fields that previously were
 * static variables. Each compilation unit gets a fresh context, ensuring
 * complete isolation between parallel compilations.
 *
 * HOW: Created by ElixirCompiler at the start of each compilation unit and
 * threaded through the entire AST pipeline (Builder → Transformer → Printer).
 * All former static state access is replaced with context field access.
 *
 * ARCHITECTURE BENEFITS:
 * - Enables parallel test execution without contamination
 * - Allows metadata to flow through compilation pipeline
 * - Provides clear state ownership and lifecycle
 * - Makes debugging easier with isolated state per compilation
 *
 * @see ElixirASTBuilder for usage patterns
 * @see ARCHITECTURE_ANALYSIS_2025_09.md for design rationale
 */
class CompilationContext implements BuildContext {
    // ========================================================================
    // Context Inheritance (Function-Scoped State)
    // ========================================================================

    /**
     * Parent context for inheritance hierarchy
     *
     * WHY: Function-scoped transformation state must persist across all statements
     *      in the function body to ensure variable renames are consistent
     * WHAT: Points to the parent context (null for top-level contexts)
     * HOW: Child contexts inherit nameMapping from parent, enabling consistent
     *      variable renaming across multiple statements
     *
     * @see compileFunctionWithPersistentContext in ElixirCompiler
     */
    public var parentContext: Null<CompilationContext>;

    // ========================================================================
    // Variable Tracking Maps (Primary cause of shadowing bugs)
    // ========================================================================

    /**
     * Maps temporary variable names to their renamed versions
     * Used for avoiding naming conflicts and maintaining consistency
     *
     * INHERITANCE: When parentContext exists, lookups check parent if not found locally
     */
    public var tempVarRenameMap: Map<String, String>;

    /**
     * Tracks which variables should have underscore prefixes (unused variables)
     * Maps TVar.id to whether it needs underscore prefix
     */
    public var underscorePrefixedVars: Map<Int, Bool>;


    /**
     * Variable usage tracking map for determining if variables are used
     * Maps TVar.id to usage status
     */
    public var variableUsageMap: Null<Map<Int, Bool>>;

    // ========================================================================
    // Function and Class Context
    // ========================================================================

    /**
     * Tracks function parameter IDs to distinguish them from local variables
     * Maps parameter name to existence flag
     */
    public var functionParameterIds: Map<String, Bool>;

    /**
     * Flag indicating if we're currently compiling inside a class method
     * Affects how 'this' references are handled
     */
    public var isInClassMethodContext: Bool;

    /**
     * Current receiver parameter name for methods (e.g., "this", "self")
     * Used for proper struct method compilation
     */
    public var currentReceiverParamName: Null<String>;

    /**
     * Flag indicating if we're currently compiling an ExUnit test method
     * Affects how instance variables are transformed (to context parameters)
     */
    public var isInExUnitTest: Bool;

    /**
     * Flag indicating if we're currently compiling constructor arguments
     * WHY: Prevents parameter renaming in constructor calls (e.g., JsonPrinter.new(replacer, space))
     * WHAT: When true, VariableBuilder preserves original parameter names
     * HOW: Set by ConstructorBuilder before compiling args, checked as Priority 0 in VariableBuilder
     */
    public var isInConstructorArgContext: Bool;

    // ========================================================================
    // Pattern Matching and Clause Context
    // ========================================================================

    /**
     * Registry for pattern variables extracted from enum patterns
     * Maps TVar.id to the pattern variable name
     */
    public var patternVariableRegistry: Map<Int, String>;

    /**
     * Current clause context for pattern matching compilation
     * Manages variable mappings within case clauses
     */
    public var currentClauseContext: Null<ClauseContext>;

    /**
     * Stack of clause contexts for nested pattern matching
     * Allows proper scoping of pattern variables
     */
    private var clauseContextStack: Array<ClauseContext>;

    // ========================================================================
    // Loop and Code Generation Counters
    // ========================================================================

    /**
     * Counter for generating unique loop variable names
     * Incremented for each loop to avoid naming conflicts
     */
    public var loopCounter: Int;

    /**
     * Counter for generating unique while loop labels
     * Used for Y-combinator pattern generation
     */
    public var whileLoopCounter: Int;

    /**
     * Infrastructure variable initialization values
     * Maps variable names (like "_g", "_g1") to their initialization AST nodes
     * Used to properly initialize reduce_while accumulator in loop desugaring
     */
    public var infrastructureVarInitValues: Map<String, ElixirAST>;

    /**
     * Infrastructure variable substitutions from TypedExprPreprocessor
     * Maps TVar.id to the TypedExpr that should be substituted
     *
     * WHY: TypedExprPreprocessor successfully eliminates infrastructure variables
     *      at TypedExpr level, but builders re-compile sub-expressions and lose
     *      the substitutions. This map preserves preprocessing results.
     *
     * WHAT: Band-aid fix to pass substitution context through AST building.
     *       TODO: Phase 2 proper fix - refactor builders to accept pre-built AST
     *
     * HOW: Populated by ElixirCompiler after preprocessor runs. Builders check
     *      this map before re-compiling TLocal(_g) references.
     *
     * @see TypedExprPreprocessor.preprocess() - Creates the substitutions
     * @see SwitchBuilder.build() - Checks before re-compiling switch target
     * @see VariableBuilder.buildVariableReference() - Checks before creating EVar
     */
    public var infraVarSubstitutions: Map<Int, TypedExpr>;

    // ========================================================================
    // Module Context
    // ========================================================================

    /**
     * Current module being compiled
     * Used for generating proper module references
     */
    public var currentModule: Null<String>;

    /**
     * Current class being compiled
     * WHY: Enables same-module optimization for static method calls
     * WHAT: Holds the ClassType of the class currently being compiled
     * HOW: Set by ElixirCompiler.compileClassImpl before compiling class body
     */
    public var currentClass: Null<ClassType>;

    /**
     * Flag indicating if current module has Phoenix.Presence behavior
     * Affects how certain method calls are generated
     */
    public var currentModuleHasPresence: Bool;

    // ========================================================================
    // Compiler References
    // ========================================================================

    /**
     * Reference to the main ElixirCompiler instance
     * Provides access to compiler-wide functionality
     */
    public var compiler: Null<reflaxe.elixir.ElixirCompiler>;

    /**
     * Behavior transformer for Phoenix/OTP behaviors
     * Handles behavior-specific transformations
     */
    public var behaviorTransformer: Null<BehaviorTransformer>;

    // ========================================================================
    // AST Modularization Infrastructure (Phase 2 Integration)
    // ========================================================================

    /**
     * Shared AST context for modular builders
     * Provides centralized state management for all AST builders
     */
    public var astContext: ElixirASTContext;

    /**
     * Builder facade for gradual migration to modular architecture
     * Routes compilation to specialized builders based on feature flags
     */
    public var builderFacade: Null<BuilderFacade>;

    /**
     * Current position for error reporting
     * Updated as we traverse the AST
     */
    private var currentPosition: Position;

    /**
     * Reentrancy guard to prevent infinite recursion
     * Used when LoopBuilder and other analyzers need to call buildExpr
     */
    public var reentrancyGuard: ReentrancyGuard;

    /**
     * Builder result cache to avoid repeated conversions of identical TypedExpr nodes
     * Scoped to this context to respect context-sensitive naming decisions.
     */
    public var builderCache: ObjectMap<TypedExpr, ElixirAST>;

    /**
     * Substitution cache for substituteIfNeeded to avoid reprocessing the same TypedExpr
     * during nested transformations (prevents repeated unwrap/substitute cycles).
     */
    public var substitutionCache: ObjectMap<TypedExpr, TypedExpr>;

    // ========================================================================
    // Constructor and Initialization
    // ========================================================================

    /**
     * Creates a new compilation context with fresh state
     * All maps are initialized empty, flags set to defaults
     */
    public function new() {
        // Initialize context inheritance
        parentContext = null;

        // Initialize all maps
        tempVarRenameMap = new Map();
        underscorePrefixedVars = new Map();
        variableUsageMap = new Map();
        functionParameterIds = new Map();
        patternVariableRegistry = new Map();

        // Initialize clause context stack
        clauseContextStack = [];
        currentClauseContext = null;

        // Set default flags
        isInClassMethodContext = false;
        currentReceiverParamName = null;
        isInExUnitTest = false;
        isInConstructorArgContext = false;
        currentModule = null;
        currentModuleHasPresence = false;

        // Initialize counters
        loopCounter = 0;
        whileLoopCounter = 0;
        infrastructureVarInitValues = new Map();

        // Initialize infrastructure variable substitutions
        // Band-aid fix: Preserve preprocessor substitutions that builders lose
        infraVarSubstitutions = new Map();

        // Compiler references will be set by ElixirCompiler
        compiler = null;
        behaviorTransformer = null;

        // Initialize AST modularization infrastructure
        astContext = new ElixirASTContext();
        builderFacade = null; // Will be initialized when needed
        currentPosition = null;

        // Initialize reentrancy guard
        reentrancyGuard = new ReentrancyGuard();

        // Initialize builder cache
        builderCache = new ObjectMap();
        substitutionCache = new ObjectMap();
    }

    // ========================================================================
    // Clause Context Management
    // ========================================================================

    /**
     * Push a new clause context onto the stack
     * Used when entering a new pattern matching scope
     *
     * @param ctx The clause context to push
     */
    public function pushClauseContext(ctx: ClauseContext): Void {
        clauseContextStack.push(ctx);
        currentClauseContext = ctx;
    }

    /**
     * Pop the current clause context from the stack
     * Used when exiting a pattern matching scope
     *
     * @return The popped clause context, or null if stack was empty
     */
    public function popClauseContext(): Null<ClauseContext> {
        if (clauseContextStack.length == 0) {
            currentClauseContext = null;
            return null;
        }

        var popped = clauseContextStack.pop();
        currentClauseContext = clauseContextStack.length > 0 ?
                               clauseContextStack[clauseContextStack.length - 1] :
                               null;
        return popped;
    }

    /**
     * Get the current clause context without modifying the stack
     *
     * @return The current clause context or null if none
     */
    public function getCurrentClauseContext(): Null<ClauseContext> {
        return currentClauseContext;
    }

    // ========================================================================
    // Context Inheritance Methods
    // ========================================================================

    /**
     * Create a child context that inherits from this context
     *
     * WHY: Function statements need isolated contexts while sharing variable renames
     * WHAT: Creates new context with this as parent
     * HOW: Child contexts can look up inherited state from parent
     *
     * @return New child context with this as parent
     */
    public function createChild(): CompilationContext {
        var child = new CompilationContext();
        child.parentContext = this;

        // Copy compiler references
        child.compiler = this.compiler;
        child.behaviorTransformer = this.behaviorTransformer;

        // Copy module context
        child.currentModule = this.currentModule;
        child.currentModuleHasPresence = this.currentModuleHasPresence;

        // CRITICAL FIX: Copy method context flags for proper "this" resolution
        // These flags determine how TConst(TThis) is compiled in function bodies
        child.isInClassMethodContext = this.isInClassMethodContext;
        child.currentReceiverParamName = this.currentReceiverParamName;
        child.isInExUnitTest = this.isInExUnitTest;
        child.isInConstructorArgContext = this.isInConstructorArgContext;

        return child;
    }

    /**
     * Merge nameMapping from child context back to parent
     *
     * WHY: Variable renames discovered in child must persist to parent
     * WHAT: Copies all tempVarRenameMap entries from child to this
     * HOW: Iterates child map and adds entries to parent map
     *
     * @param child The child context to merge from
     */
    public function mergeNameMappings(child: CompilationContext): Void {
        if (child == null) return;

        // Merge variable rename mappings
        for (key in child.tempVarRenameMap.keys()) {
            var value = child.tempVarRenameMap.get(key);
            tempVarRenameMap.set(key, value);
        }

        // Merge underscore prefix tracking
        for (key in child.underscorePrefixedVars.keys()) {
            var value = child.underscorePrefixedVars.get(key);
            if (value) {
                underscorePrefixedVars.set(key, value);
            }
        }
    }

    /**
     * Get variable rename with inheritance lookup
     *
     * WHY: Child contexts must see parent's variable renames
     * WHAT: Checks local map first, then parent recursively
     * HOW: Recursive lookup up the context chain
     *
     * @param varName The variable name to look up
     * @return The renamed version or null if no mapping exists
     */
    public function getInheritedVarRename(varName: String): Null<String> {
        // Check local map first
        if (tempVarRenameMap.exists(varName)) {
            return tempVarRenameMap.get(varName);
        }

        // Check parent if exists
        if (parentContext != null) {
            return parentContext.getInheritedVarRename(varName);
        }

        return null;
    }

    // ========================================================================
    // Variable Tracking Helpers
    // ========================================================================

    /**
     * Check if a variable should have an underscore prefix
     *
     * @param varId The TVar.id to check
     * @return True if the variable should be prefixed with underscore
     */
    public function shouldPrefixWithUnderscore(varId: Int): Bool {
        return underscorePrefixedVars.exists(varId) && underscorePrefixedVars.get(varId);
    }

    /**
     * Register a variable as needing underscore prefix
     *
     * @param varId The TVar.id to register
     */
    public function markAsUnderscorePrefixed(varId: Int): Void {
        underscorePrefixedVars.set(varId, true);
    }

    /**
     * Check if a temporary variable has a rename mapping
     *
     * @param tempName The temporary variable name
     * @return The renamed version or null if no mapping exists
     */
    public function getTempVarRename(tempName: String): Null<String> {
        return tempVarRenameMap.get(tempName);
    }

    /**
     * Register a temporary variable rename mapping
     *
     * @param tempName The temporary variable name
     * @param newName The new name to use
     */
    public function registerTempVarRename(tempName: String, newName: String): Void {
        tempVarRenameMap.set(tempName, newName);
    }

    // ========================================================================
    // Module Context Helpers
    // ========================================================================

    /**
     * Set the current module being compiled
     *
     * @param moduleName The module name
     * @param hasPresence Whether the module has Phoenix.Presence behavior
     */
    public function setCurrentModule(moduleName: String, hasPresence: Bool = false): Void {
        currentModule = moduleName;
        currentModuleHasPresence = hasPresence;
    }

    /**
     * Clear the current module context
     * Called when exiting module compilation
     */
    public function clearModuleContext(): Void {
        currentModule = null;
        currentModuleHasPresence = false;
    }

    // ========================================================================
    // BuildContext Interface Implementation (Phase 2 Integration)
    // ========================================================================

    /**
     * Get the shared AST context
     */
    public function getASTContext(): ElixirASTContext {
        return astContext;
    }

    /**
     * Resolve a variable name using priority hierarchy
     */
    public function resolveVariable(tvarId: Int, defaultName: String): String {
        // Priority 1: Pattern variable registry
        if (patternVariableRegistry.exists(tvarId)) {
            return patternVariableRegistry.get(tvarId);
        }

        // Priority 2: Current clause context
        if (currentClauseContext != null && currentClauseContext.localToName.exists(tvarId)) {
            return currentClauseContext.localToName.get(tvarId);
        }

        // Priority 3: Underscore prefix check
        if (shouldPrefixWithUnderscore(tvarId)) {
            return "_" + defaultName;
        }

        // Priority 4: Default name
        return defaultName;
    }

    /**
     * Register a pattern variable from enum matching
     */
    public function registerPatternVariable(tvarId: Int, patternName: String): Void {
        patternVariableRegistry.set(tvarId, patternName);
    }

    /**
     * Get current position for error reporting
     */
    public function getCurrentPosition(): Position {
        return currentPosition;
    }

    /**
     * Set current position for error tracking
     */
    public function setCurrentPosition(pos: Position): Void {
        currentPosition = pos;
    }

    /**
     * Get the current module type being compiled
     */
    public function getCurrentModule(): Null<ModuleType> {
        // This would need to be added to track the actual ModuleType
        // For now return null as we track module name only
        return null;
    }

    /**
     * Get the current class type being compiled
     * WHY: Enables same-module optimization for static method calls
     * WHAT: Returns the ClassType of the class currently being compiled
     * HOW: Returns the currentClass field set by ElixirCompiler
     */
    public function getCurrentClass(): Null<ClassType> {
        return currentClass;
    }

    /**
     * Store metadata for an AST node
     */
    public function setNodeMetadata(nodeId: String, metadata: Dynamic): Void {
        // Delegate to astContext
        astContext.setNodeMetadata(nodeId, metadata);
    }

    /**
     * Generate a unique node ID for metadata tracking
     */
    public function generateNodeId(): String {
        return astContext.generateNodeId();
    }

    /**
     * Check if a type is an idiomatic enum
     */
    public function isIdiomaticEnum(enumType: EnumType): Bool {
        return enumType.meta.has(":elixirIdiomatic");
    }

    /**
     * Get or create a clause context for a switch case
     */
    public function getClauseContext(caseIndex: Int): ClauseContext {
        // For now, create a new one each time
        // Could be enhanced to cache by index
        return new ClauseContext();
    }

    /**
     * Get module name with proper transformation
     */
    public function getModuleName(originalName: String): String {
        // Apply snake_case transformation
        return reflaxe.elixir.ast.NameUtils.toSnakeCase(originalName);
    }

    /**
     * Get function name with proper transformation
     */
    public function getFunctionName(originalName: String): String {
        // Apply snake_case transformation
        return reflaxe.elixir.ast.NameUtils.toSnakeCase(originalName);
    }

    /**
     * Check if currently building within a pattern
     */
    public function isInPattern(): Bool {
        return astContext.isInPattern;
    }

    /**
     * Set pattern context state
     */
    public function setInPattern(inPattern: Bool): Void {
        astContext.isInPattern = inPattern;
    }

    /**
     * Get the current function being compiled
     */
    public function getCurrentFunction(): Null<ClassField> {
        // This would need to be tracked
        return null;
    }

    /**
     * Report a compilation warning
     */
    public function warning(message: String, ?pos: Position): Void {
        #if macro
        haxe.macro.Context.warning(message, pos != null ? pos : haxe.macro.Context.currentPos());
        #end
    }

    /**
     * Report a compilation error
     */
    public function error(message: String, ?pos: Position): Void {
        #if macro
        haxe.macro.Context.error(message, pos != null ? pos : haxe.macro.Context.currentPos());
        #end
    }

    /**
     * Get expression builder callback for delegation
     */
    public function getExpressionBuilder(): (TypedExpr) -> ElixirAST {
        // Return a function that calls ElixirASTBuilder
        return function(expr: TypedExpr): ElixirAST {
            return reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, this);
        };
    }

    /**
     * Get type builder callback for delegation
     */
    public function getTypeBuilder(): (Type) -> ElixirAST {
        // Would need implementation
        return function(type: Type): ElixirAST {
            return makeAST(EAtom("todo_type"));
        };
    }

    /**
     * Get pattern builder callback for delegation
     */
    public function getPatternBuilder(clauseContext: ClauseContext): (TypedExpr) -> ElixirAST {
        // Would delegate to pattern building logic
        return function(expr: TypedExpr): ElixirAST {
            var oldContext = currentClauseContext;
            currentClauseContext = clauseContext;
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(expr, this);
            currentClauseContext = oldContext;
            return result;
        };
    }

    /**
     * Register a specialized builder for feature-flagged routing
     */
    public function registerBuilder(builderType: String, builder: IBuilder): Void {
        astContext.registerBuilder(builderType, builder);
    }

    /**
     * Check if a feature flag is enabled
     */
    public function isFeatureEnabled(flag: String): Bool {
        return astContext.isFeatureEnabled(flag);
    }

    /**
     * Enable or disable a feature flag
     */
    public function setFeatureFlag(flag: String, enabled: Bool): Void {
        astContext.setFeatureFlag(flag, enabled);
    }

    // Removed duplicate toSnakeCase - use reflaxe.elixir.ast.NameUtils.toSnakeCase instead

    // ========================================================================
    // Infrastructure Variable Substitution (Band-aid Fix Phase 1)
    // ========================================================================

    /**
     * Check if an expression should be substituted based on preprocessor results
     *
     * WHY: Band-aid fix - Builders re-compile TypedExpr sub-expressions, losing
     *      preprocessor substitutions. This preserves them until Phase 2 refactor.
     * WHAT: If expr is TLocal referring to infrastructure variable that was
     *       substituted, return the substituted expression instead.
     * HOW: Check infraVarSubstitutions map using TVar.id as key
     *
     * @param expr The TypedExpr to potentially substitute
     * @return Original expr or substituted expr if found in map
     */
    public function substituteIfNeeded(expr: TypedExpr): TypedExpr {
        // Fast cache to avoid repeated work on identical nodes
        var cached = substitutionCache.get(expr);
        if (cached != null) return cached;
        if (expr == null) {
            #if debug_preprocessor
            #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded] expr is null, returning'); #end
            #end
            return expr;
        }

        if (infraVarSubstitutions == null) {
            #if debug_preprocessor
            #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded] infraVarSubstitutions map is null!'); #end
            #end
            return expr;
        }

        #if debug_preprocessor
        #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded] Checking expr type: ${Type.enumConstructor(expr.expr)}'); #end
        #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded] Substitution map has ${Lambda.count(infraVarSubstitutions)} entries'); #end
        for (id in infraVarSubstitutions.keys()) {
            #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   Map entry: ID=$id'); #end
        }
        #end

        // Recursively unwrap TParenthesis and TMeta to find TLocal
        // Safety limit to prevent infinite loops from circular references
        var unwrapped = expr;
        var unwrapCount = 0;
        var maxUnwrap = 100;  // Safety limit

        while (unwrapCount < maxUnwrap) {
            var unwrappedNext: Null<TypedExpr> = switch(unwrapped.expr) {
                case TParenthesis(e):
                    #if debug_preprocessor
                    #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   Unwrapping TParenthesis (level ${unwrapCount + 1})'); #end
                    #end
                    e;
                case TMeta(_, e):
                    #if debug_preprocessor
                    #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   Unwrapping TMeta (level ${unwrapCount + 1})'); #end
                    #end
                    e;
                default:
                    null;
            };

            if (unwrappedNext == null) {
                break;  // No more unwrapping needed
            }

            unwrapped = unwrappedNext;
            unwrapCount++;
        }

        if (unwrapCount >= maxUnwrap) {
            #if debug_preprocessor
            #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   WARNING: Hit unwrap limit ${maxUnwrap}, possible circular reference'); #end
            #end
        }

        var result:TypedExpr = switch(unwrapped.expr) {
            case TLocal(tvar):
                #if debug_preprocessor
                    #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   Found TLocal: ${tvar.name} (ID: ${tvar.id})'); #end
                #end
                // Check if this TLocal references a substituted infrastructure variable
                var substituted = infraVarSubstitutions.get(tvar.id);
                if (substituted != null) {
                    #if debug_preprocessor
                    #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   ✓ SUBSTITUTION FOUND! Replacing ${tvar.name}'); #end
                    #end
                    substituted;
                } else {
                    #if debug_preprocessor
                    #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   ✗ No substitution for ${tvar.name} (ID: ${tvar.id})'); #end
                    #end
                    expr;
                }
            default:
                #if debug_preprocessor
                #if debug_compilation_context trace('[CompilationContext.substituteIfNeeded]   After unwrapping: ${Type.enumConstructor(unwrapped.expr)} - not a TLocal'); #end
                #end
                // Don't substitute - the expression is not an infrastructure variable reference
                expr;
        };
        substitutionCache.set(expr, result);
        return result;
    }

    // ========================================================================
    // Debug Support
    // ========================================================================

    #if debug_compilation_context
    /**
     * Dump the current context state for debugging
     */
    public function dumpState(): Void {
        #if debug_compilation_context trace('[CompilationContext] State dump:'); #end
        trace('  tempVarRenameMap entries: ${Lambda.count(tempVarRenameMap)}');
        trace('  underscorePrefixedVars entries: ${Lambda.count(underscorePrefixedVars)}');
        trace('  currentModule: $currentModule');
        trace('  isInClassMethodContext: $isInClassMethodContext');
        trace('  clauseContextStack depth: ${clauseContextStack.length}');
        trace('  AST context initialized: ${astContext != null}');
        trace('  Feature flags: ${astContext.featureFlags}');
    }
    #end
}

#end
