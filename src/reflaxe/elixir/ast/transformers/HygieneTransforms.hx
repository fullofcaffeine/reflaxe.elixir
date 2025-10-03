package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTHelpers.*;
using StringTools;

/**
 * Scope-aware variable tracking for hygiene transformations
 */

// Binding context for variable traversal
enum BindingContext {
    Expr;      // Expression context (reads variables)
    Pattern;   // Pattern context (binds variables)  
    Pinned;    // Pinned context (reads in patterns)
}

// Container context for bindings
enum ContainerContext {
    DefParam;      // Function definition parameter
    FnParam;       // Anonymous function parameter
    CaseClause;    // Case clause pattern
    ReceiveClause; // Receive clause pattern
    WithClause;    // With clause pattern
    MatchLHS;      // Match left-hand side
}

// Variable binding information with precise locator
typedef Binding = {
    name: String,
    used: Bool,
    kind: BindingKind,
    containerId: Int,          // AST ID of the container node
    context: ContainerContext, // Type of container
    slotIndex: Int,           // Which param/clause/side
    path: Array<Int>          // Path to PVar within pattern
}

// Kind of binding
enum BindingKind {
    Param;         // Function parameter
    PatternVar;    // Pattern match variable
    MatchLhs;      // Left-hand side of = match
    CompGen;       // Comprehension generator
    WithGen;       // With clause generator
    RescueVar;     // Rescue clause variable
}

// Scope frame in the scope stack
typedef ScopeFrame = {
    bindings: Map<String, Array<Binding>>,  // Stack of bindings per name
    kind: ScopeKind,
    parent: Null<ScopeFrame>
}

// Kind of scope
enum ScopeKind {
    Module;
    Function;
    Clause;
    Block;
    CompGen;       // Comprehension generator scope
    CompFilter;    // Comprehension filter scope
    Rescue;
    Receive;
    With;
}

// Hygiene analysis state carried through traversal
typedef HygieneState = {
    scopeStack: Array<ScopeFrame>,
    currentContext: BindingContext,
    aliases: Map<String, Bool>,        // Track alias usage
    imports: Map<String, Bool>,        // Track import usage
    requires: Map<String, Bool>        // Track require usage
}

/**
 * HygieneTransforms: Comprehensive Elixir Code Hygiene Transformation System
 * 
 * ## PURPOSE
 * This class implements a sophisticated multi-pass AST transformation system designed to eliminate
 * compilation warnings and generate idiomatic Elixir code from Haxe-generated AST structures.
 * 
 * ## PROBLEM STATEMENT
 * The Reflaxe.Elixir compiler initially generated Elixir code with numerous hygiene issues:
 * - **390+ compilation warnings** per build cycle
 * - **Variable shadowing** causing "variable x is unused" warnings (25+ per file)
 * - **Incorrect underscore prefixing** - actually-used variables marked as unused
 * - **Quoted atoms** where bare atoms would be idiomatic
 * - **Type comparisons** using == instead of pattern matching
 * - **Unused imports/aliases** cluttering generated code
 * 
 * ## ARCHITECTURAL SOLUTION
 * 
 * ### Three-Phase Transformation Pipeline
 * 
 * #### Phase 0: AST ID Assignment
 * - Assigns unique IDs to every AST node via metadata
 * - Enables precise node identification for targeted transformations
 * - Foundation for the container/slot/path locator system
 * 
 * #### Phase 1: Binding Collection & Usage Analysis
 * - **Scope-aware traversal** with context tracking (Expression vs Pattern)
 * - **Binding registration** with precise locators:
 *   - `containerId`: Unique ID of the containing AST node
 *   - `context`: Type of container (DefParam, CaseClause, etc.)
 *   - `slotIndex`: Position within container (parameter index, clause index)
 *   - `path`: Navigation path within nested patterns ([0,1] = first tuple, second element)
 * - **Usage tracking** by resolving variable reads to their bindings
 * 
 * #### Phase 2: Targeted Renaming
 * - **Builds rename index** mapping locators to rename operations
 * - **Applies renames surgically** using the locator system
 * - **Only renames unused bindings** - preserves used variable names
 * 
 * ## KEY INNOVATIONS
 * 
 * ### Container/Slot/Path Locator System
 * Developed in consultation with Codex, this system provides surgical precision for AST modifications:
 * ```
 * def process({a, b, c}, d) do  # Container: def "process", Context: DefParam
 *   # Locator for 'b': {containerId: 42, context: DefParam, slotIndex: 0, path: [1]}
 *   # - containerId 42: The EDef node's unique ID
 *   # - context DefParam: It's a function parameter
 *   # - slotIndex 0: First parameter of the function
 *   # - path [1]: Second element of the tuple pattern
 * end
 * ```
 * 
 * ### Scope-Aware Variable Tracking
 * - Maintains scope stack (Module → Function → Block → Clause)
 * - Distinguishes binding contexts (Pattern vs Expression vs Pinned)
 * - Handles shadowing correctly by tracking binding stacks per name
 * 
 * ## TRANSFORMATION PASSES
 * 
 * ### 1. Usage Analysis Pass (IMPLEMENTED)
 * - Detects unused variables with deep AST traversal
 * - Handles nested usage (e.g., `Std.int(t)` correctly marks `t` as used)
 * - Prefixes only truly unused variables with underscore
 * 
 * ### 2. Hygienic Naming Pass (PLANNED)
 * - Alpha-renaming to eliminate variable shadowing
 * - Generates unique suffixes for shadowed names
 * 
 * ### 3. Atom Normalization Pass (IMPLEMENTED)
 * - Converts quoted atoms to bare atoms where safe
 * - Reduces "atom :foo should be written as :foo" warnings
 * 
 * ### 4. Equality-to-Pattern Pass (IMPLEMENTED)
 * - Transforms `x == :atom` to `match?(:atom, x)`
 * - Generates more idiomatic Elixir code
 * 
 * ## USAGE EXAMPLE
 * ```haxe
 * // In ElixirASTTransformer.hx
 * passes.push({
 *     name: "UsageAnalysis",
 *     description: "Detect and mark unused variables",
 *     enabled: true,
 *     pass: HygieneTransforms.usageAnalysisPass
 * });
 * ```
 * 
 * ## IMPLEMENTATION NOTES
 * 
 * ### Critical Bug Fix: Nested Variable Usage
 * Initial implementation failed to detect variables used in nested contexts.
 * Example: `def from_time(t) do DateTime.from_unix!(Std.int(t), "millisecond") end`
 * - Bug: `t` was marked as unused despite being used in `Std.int(t)`
 * - Fix: Enhanced `isVariableUsedInBody` to use ElixirASTTransformer's recursive traversal
 * 
 * ### Design Decision: Metadata-Driven Approach
 * - All transformations driven by metadata, not hardcoded patterns
 * - Enables extensibility without modifying core logic
 * - Follows Reflaxe framework conventions
 * 
 * ## TESTING STRATEGY
 * - Comprehensive snapshot tests in test/snapshot/HygieneTransformUsageDetection/
 * - Real-world validation via todo-app compilation
 * - Warning count monitoring (reduced from 417 to 371 so far)
 * 
 * ## FUTURE ENHANCEMENTS
 * - Complete hygienic naming pass for shadow elimination
 * - Unused import/alias/require detection and removal
 * - Dead code elimination pass
 * - Format string optimization
 * 
 * @author Reflaxe.Elixir Development Team
 * @since 2025-01-10
 * @see docs/03-compiler-development/HYGIENE_TRANSFORMATIONS.md - Complete documentation
 * @see Codex architectural consultation transcripts for design rationale
 */
class HygieneTransforms {
    
    /**
     * Create initial hygiene state
     */
    static function createInitialState(): HygieneState {
        return {
            scopeStack: [{
                bindings: new Map(),
                kind: Module,
                parent: null
            }],
            currentContext: Expr,
            aliases: new Map(),
            imports: new Map(),
            requires: new Map()
        };
    }
    
    /**
     * Enter a new scope
     */
    static function enterScope(state: HygieneState, kind: ScopeKind): Void {
        var newFrame: ScopeFrame = {
            bindings: new Map(),
            kind: kind,
            parent: state.scopeStack[state.scopeStack.length - 1]
        };
        state.scopeStack.push(newFrame);
        
        #if debug_hygiene
        trace('[XRay Hygiene] Entering scope: $kind (depth: ${state.scopeStack.length})');
        #end
    }
    
    /**
     * Exit current scope
     */
    static function exitScope(state: HygieneState): Void {
        if (state.scopeStack.length > 1) {
            var exitingScope = state.scopeStack.pop();
            
            #if debug_hygiene
            trace('[XRay Hygiene] Exiting scope: ${exitingScope.kind} (depth: ${state.scopeStack.length})');
            #end
        }
    }
    
    /**
     * Assign unique IDs to all AST nodes
     */
    static function assignAstIds(ast: ElixirAST): ElixirAST {
        var idCounter = 0;
        
        return ElixirASTTransformer.transformNode(ast, function(node) {
            // Assign unique ID to this node via metadata
            if (node.metadata == null) {
                node.metadata = {};
            }
            Reflect.setField(node.metadata, "astId", ++idCounter);
            return node;
        });
    }
    
    /**
     * Bind a variable in current scope with precise locator
     */
    static function bindVariable(state: HygieneState, name: String, kind: BindingKind, 
                                 containerId: Int, context: ContainerContext, 
                                 slotIndex: Int, path: Array<Int>): Binding {
        var currentFrame = state.scopeStack[state.scopeStack.length - 1];
        
        var binding: Binding = {
            name: name,
            used: false,
            kind: kind,
            containerId: containerId,
            context: context,
            slotIndex: slotIndex,
            path: path.copy()  // Copy the path array
        };
        
        // Add to binding stack for this name
        if (!currentFrame.bindings.exists(name)) {
            currentFrame.bindings.set(name, []);
        }
        currentFrame.bindings.get(name).push(binding);
        
        #if debug_hygiene
        trace('[XRay Hygiene] Bound variable "$name" as $kind in ${currentFrame.kind} scope (container:$containerId, slot:$slotIndex, path:[${path.join(",")}])');
        #end
        
        return binding;
    }
    
    /**
     * Resolve a variable read to nearest binding
     */
    static function resolveVariable(state: HygieneState, name: String): Null<Binding> {
        // Walk scope stack from innermost to outermost
        var i = state.scopeStack.length - 1;
        while (i >= 0) {
            var frame = state.scopeStack[i];
            if (frame.bindings.exists(name)) {
                var bindings = frame.bindings.get(name);
                if (bindings.length > 0) {
                    var binding = bindings[bindings.length - 1];  // Most recent binding
                    binding.used = true;
                    
                    #if debug_hygiene
                    trace('[XRay Hygiene] Resolved read of "$name" to binding in ${frame.kind} scope');
                    #end
                    
                    return binding;
                }
            }
            i--;
        }
        
        #if debug_hygiene
        trace('[XRay Hygiene] Variable "$name" not found in any scope (might be module attribute)');
        #end
        
        return null;
    }
    
    /**
     * Hygienic Variable Naming Pass
     * 
     * WHY: Eliminate variable shadowing warnings
     * WHAT: Rename variables to ensure unique names within scopes
     * HOW: Alpha-renaming with scope-aware suffix generation
     */
    public static function hygienicNamingPass(ast: ElixirAST): ElixirAST {
        #if debug_hygiene
        trace('[XRay Hygiene] Starting hygienic naming pass');
        #end
        
        // For now, return AST unchanged to avoid stack overflow
        // TODO: Implement proper traversal using visitor pattern
        return ast;
    }
    
    /**
     * Enhanced Usage Analysis Pass with Scope-Aware Tracking
     * 
     * WHY: Detect and mark unused variables for underscore prefixing
     * WHAT: Analyze variable usage with proper bind/read context distinction
     * HOW: Three-phase approach:
     *      0. Assign unique IDs to all AST nodes
     *      1. Collect all bindings and track usage with scope awareness
     *      2. Rename unused bindings to underscore prefix using precise locators
     */
    /**
     * Usage analysis pass (stateless variant)
     *
     * WHY: Maintains backward compatibility for non-contextual transform() calls
     * WHAT: Creates local nameMapping, does not integrate with compiler context
     * HOW: Standalone analysis and renaming using internal state
     *
     * NOTE: This is the fallback variant. Prefer usageAnalysisPassWithContext when context available.
     */
    public static function usageAnalysisPass(ast: ElixirAST): ElixirAST {
        #if debug_hygiene
        trace('[XRay Hygiene] Starting enhanced usage analysis pass with scope tracking (STATELESS)');
        #end

        // Phase 0: Assign unique IDs to all AST nodes
        var astWithIds = assignAstIds(ast);

        // Phase 1: Collect bindings and track usage
        var state = createInitialState();
        var allBindings: Array<Binding> = [];

        // First pass: collect all bindings and mark usage
        collectBindingsAndUsage(astWithIds, state, allBindings);

        #if debug_hygiene
        trace('[XRay Hygiene] Collected ${allBindings.length} bindings');
        var unusedCount = 0;
        for (binding in allBindings) {
            if (!binding.used) unusedCount++;
        }
        trace('[XRay Hygiene] Found $unusedCount unused bindings to rename');
        #end

        // Phase 2: Apply renaming transformations using collected bindings (local mapping)
        return renameUnusedBindings(astWithIds, allBindings);
    }

    /**
     * Usage analysis pass (contextual variant)
     *
     * WHY: Enables consistent variable naming across compilation phases
     * WHAT: Uses context.tempVarRenameMap instead of local nameMapping
     * HOW: Registers renames in shared context, applies from authoritative source
     *
     * ARCHITECTURE:
     * - Reads existing renames from context.tempVarRenameMap (builder phase decisions)
     * - Adds new renames for unused variables discovered in this pass
     * - Applies renames from the single source of truth (context)
     * - Ensures declarations and references use consistent names
     *
     * BENEFITS:
     * - Fixes variable naming consistency bugs (e.g., _changeset vs changeset)
     * - Coordinates with builder phase variable decisions
     * - Eliminates duplicate mapping systems
     * - Single authoritative source for all variable renames
     *
     * @param ast The AST to analyze
     * @param context Compilation context with shared tempVarRenameMap
     * @return Transformed AST with consistent variable naming
     */
    public static function usageAnalysisPassWithContext(ast: ElixirAST, context: reflaxe.elixir.CompilationContext): ElixirAST {
        #if debug_hygiene
        trace('[XRay Hygiene] Starting enhanced usage analysis pass with scope tracking (CONTEXTUAL)');
        trace('[XRay Hygiene] Context provided: ${context != null}');
        if (context != null) {
            trace('[XRay Hygiene] Existing renames in context: ${[for (k in context.tempVarRenameMap.keys()) k + " -> " + context.tempVarRenameMap.get(k)].join(", ")}');
        }
        #end

        // Phase 0: Assign unique IDs to all AST nodes
        var astWithIds = assignAstIds(ast);

        // Phase 1: Collect bindings and track usage
        var state = createInitialState();
        var allBindings: Array<Binding> = [];

        // First pass: collect all bindings and mark usage
        collectBindingsAndUsage(astWithIds, state, allBindings);

        #if debug_hygiene
        trace('[XRay Hygiene] Collected ${allBindings.length} bindings');
        var unusedCount = 0;
        for (binding in allBindings) {
            if (!binding.used) unusedCount++;
        }
        trace('[XRay Hygiene] Found $unusedCount unused bindings to rename');
        #end

        // Phase 2: Apply renaming transformations using context's shared mapping
        return renameUnusedBindingsWithContext(astWithIds, allBindings, context);
    }
    
    /**
     * Collect all bindings and track their usage
     */
    static function collectBindingsAndUsage(ast: ElixirAST, state: HygieneState, allBindings: Array<Binding>): Void {
        traverseWithContext(ast, state, allBindings);
    }
    
    /**
     * Traverse AST with binding context awareness
     */
    static function traverseWithContext(node: ElixirAST, state: HygieneState, allBindings: Array<Binding>): Void {
        if (node == null) return;

        // Get container ID from metadata
        var containerId = node.metadata != null ? Reflect.field(node.metadata, "astId") : 0;

        switch(node.def) {
            case EDef(name, params, guards, body) | EDefp(name, params, guards, body):
                // Enter function scope
                enterScope(state, Function);
                
                // Process parameters in pattern context with locators
                state.currentContext = Pattern;
                for (i in 0...params.length) {
                    processPatternWithLocator(params[i], state, allBindings, 
                                            containerId, DefParam, i, []);
                }
                
                // Process guards in expression context
                if (guards != null) {
                    state.currentContext = Expr;
                    traverseWithContext(guards, state, allBindings);
                }
                
                // Process body in expression context
                state.currentContext = Expr;
                traverseWithContext(body, state, allBindings);
                
                // Exit function scope
                exitScope(state);
                
            case EMatch(pattern, expr):
                // Process RHS in expression context FIRST to mark variable usage
                state.currentContext = Expr;
                traverseWithContext(expr, state, allBindings);

                // CRITICAL FIX: In Elixir, pattern matching with = is REBINDING, not new binding
                // When we have: v = replacer(key, v)
                // The RHS 'v' uses the EXISTING binding
                // The LHS 'v' REBINDS the same variable (not creates new one)
                // So we should NOT create a new binding if variable already exists in scope
                //
                // However, processPatternWithLocator creates bindings unconditionally
                // This causes the parameter 'v' to appear unused when it's actually used in RHS
                //
                // For now, we skip processing the LHS pattern entirely for EMatch
                // because Elixir rebinding doesn't need hygiene tracking
                // The variable is already bound (as parameter) and marked used (from RHS traversal)

                // NOTE: This is correct for Elixir semantics where = is pattern matching/rebinding
                // NOT variable declaration like in imperative languages

                #if debug_hygiene
                trace('[XRay Hygiene] Skipping LHS pattern processing for EMatch - Elixir rebinding semantics');
                #end
                
            case ECase(expr, clauses):
                // Process scrutinee in expression context
                state.currentContext = Expr;
                traverseWithContext(expr, state, allBindings);
                
                // Process each clause
                for (clause in clauses) {
                    enterScope(state, Clause);
                    
                    // Pattern in pattern context with locator for case clause
                    state.currentContext = Pattern;
                    var clauseIndex = clauses.indexOf(clause);
                    processPatternWithLocator(clause.pattern, state, allBindings,
                                            containerId, CaseClause, clauseIndex, []);
                    
                    // Guard in expression context (singular, not plural)
                    if (clause.guard != null) {
                        state.currentContext = Expr;
                        traverseWithContext(clause.guard, state, allBindings);
                    }
                    
                    // Body in expression context
                    state.currentContext = Expr;
                    traverseWithContext(clause.body, state, allBindings);
                    
                    exitScope(state);
                }
                
            case EVar(name):
                // Variable reference - resolve if in expression context
                if (state.currentContext == Expr || state.currentContext == Pinned) {
                    resolveVariable(state, name);
                }
                
            case ECall(target, funcName, args):
                // All arguments are in expression context
                state.currentContext = Expr;
                if (target != null) {
                    traverseWithContext(target, state, allBindings);
                }
                for (arg in args) {
                    #if debug_hygiene
                    // Debug: Check what type of argument we're traversing
                    var argType = switch(arg.def) {
                        case ERaw(_): "ERaw (STRING INTERPOLATION!)";
                        case EString(_): "EString";
                        case EVar(_): "EVar";
                        default: Type.enumConstructor(arg.def);
                    };
                    trace('[XRay Hygiene] ECall arg type: $argType');
                    #end
                    // Each argument needs to be properly traversed to mark variables as used
                    traverseWithContext(arg, state, allBindings);
                }
                
            case EBlock(statements):
                // Enter block scope
                enterScope(state, Block);
                state.currentContext = Expr;
                for (stmt in statements) {
                    traverseWithContext(stmt, state, allBindings);
                }
                exitScope(state);
                
            case ETuple(elements) | EList(elements):
                // Process elements based on current context
                for (elem in elements) {
                    traverseWithContext(elem, state, allBindings);
                }
                
            case EBinary(op, left, right):
                // Both operands in expression context
                state.currentContext = Expr;
                traverseWithContext(left, state, allBindings);
                traverseWithContext(right, state, allBindings);
                
            case EIf(cond, thenBranch, elseBranch):
                // All parts in expression context
                state.currentContext = Expr;
                traverseWithContext(cond, state, allBindings);
                traverseWithContext(thenBranch, state, allBindings);
                if (elseBranch != null) {
                    traverseWithContext(elseBranch, state, allBindings);
                }

            case ERaw(code):
                // Raw Elixir code from __elixir__() injection
                // Parse string interpolations #{variable} to detect variable usage
                #if debug_hygiene
                trace('[XRay Hygiene] Traversing ERaw node with code: ${code.substr(0, 100)}...');
                trace('[XRay Hygiene] Checking for #{...} patterns in code');
                #end

                // Use regex to find all #{variable_name} patterns (including camelCase)
                var interpolationPattern = ~/\\#\\{([a-zA-Z_][a-zA-Z0-9_\.]*)\\}/g;
                var pos = 0;
                var matchCount = 0;
                while (interpolationPattern.matchSub(code, pos)) {
                    matchCount++;
                    var varName = interpolationPattern.matched(1);
                    #if debug_hygiene
                    trace('[XRay Hygiene] MATCH #$matchCount - Found interpolated variable: $varName');
                    #end

                    // Mark variable as used by resolving it in expression context
                    state.currentContext = Expr;
                    resolveVariable(state, varName);

                    pos = interpolationPattern.matchedPos().pos + interpolationPattern.matchedPos().len;
                }

                #if debug_hygiene
                trace('[XRay Hygiene] Total matches found: $matchCount');
                #end

            default:
                // For other node types, traverse children if they exist
                // This is a simplified catch-all
        }
    }
    
    /**
     * Process a pattern with precise locator tracking
     */
    static function processPatternWithLocator(pattern: EPattern, state: HygieneState, allBindings: Array<Binding>,
                                             containerId: Int, context: ContainerContext, 
                                             slotIndex: Int, path: Array<Int>): Void {
        if (pattern == null) return;
        
        switch(pattern) {
            case PVar(name):
                // Create binding with precise locator
                var binding = bindVariable(state, name, PatternVar, 
                                         containerId, context, slotIndex, path);
                allBindings.push(binding);
                
            case PTuple(patterns):
                for (i in 0...patterns.length) {
                    var childPath = path.copy();
                    childPath.push(i);
                    processPatternWithLocator(patterns[i], state, allBindings,
                                            containerId, context, slotIndex, childPath);
                }
                
            case PList(patterns):
                for (i in 0...patterns.length) {
                    var childPath = path.copy();
                    childPath.push(i);
                    processPatternWithLocator(patterns[i], state, allBindings,
                                            containerId, context, slotIndex, childPath);
                }
                
            case PMap(pairs):
                for (i in 0...pairs.length) {
                    var childPath = path.copy();
                    childPath.push(i);
                    childPath.push(1); // Value is at index 1 in the pair
                    processPatternWithLocator(pairs[i].value, state, allBindings,
                                            containerId, context, slotIndex, childPath);
                }
                
            default:
                // Literals and other patterns don't bind variables
        }
    }
    
    /**
     * Apply renaming to unused bindings using precise locators
     */
    static function renameUnusedBindings(ast: ElixirAST, allBindings: Array<Binding>): ElixirAST {
        // Build index: Map<(containerId, context, slotIndex), Array<{path, oldName, newName}>>
        var renameIndex = new Map<String, Array<{path: Array<Int>, oldName: String, newName: String}>>();

        // ALSO build a simple name mapping for EVar renaming
        var nameMapping = new Map<String, String>();

        for (binding in allBindings) {
            // CRITICAL FIX: Pattern variables should NEVER be renamed with underscore prefix
            // Pattern-bound variables (like 'value' in {:ok, value}) are ALWAYS available in the case body
            // by definition - they're bound by the pattern match, not declared as unused locals.
            // Renaming them breaks the pattern→body coordination.
            if (!binding.used && !binding.name.startsWith("_") && binding.kind != PatternVar) {
                var key = '${binding.containerId}:${binding.context}:${binding.slotIndex}';
                if (!renameIndex.exists(key)) {
                    renameIndex.set(key, []);
                }
                renameIndex.get(key).push({
                    path: binding.path,
                    oldName: binding.name,
                    newName: "_" + binding.name
                });

                // Add to name mapping (oldName -> newName)
                nameMapping.set(binding.name, "_" + binding.name);
            }
        }

        #if debug_hygiene
        trace('[XRay Hygiene] Built rename index with ${Lambda.count(renameIndex)} containers to process');
        trace('[XRay Hygiene] Built name mapping with ${Lambda.count(nameMapping)} entries');
        for (oldName in nameMapping.keys()) {
            trace('[XRay Hygiene]   $oldName -> ${nameMapping.get(oldName)}');
        }
        #end

        // Apply renaming using the index
        return ElixirASTTransformer.transformNode(ast, function(node) {
            if (node.metadata == null) return node;
            
            var containerId = Reflect.field(node.metadata, "astId");
            if (containerId == null) return node;
            
            switch(node.def) {
                case EDef(name, params, guards, body) | EDefp(name, params, guards, body):
                    // Check if we have renames for this container's parameters
                    var hasRenames = false;
                    var newParams = [];
                    
                    for (i in 0...params.length) {
                        var key = '$containerId:DefParam:$i';
                        var renames = renameIndex.get(key);
                        
                        if (renames != null && renames.length > 0) {
                            hasRenames = true;
                            newParams.push(renamePatternWithLocators(params[i], renames, []));
                        } else {
                            newParams.push(params[i]);
                        }
                    }
                    
                    if (hasRenames) {
                        var newDef = switch(node.def) {
                            case EDef(n, _, g, b): EDef(n, newParams, g, b);
                            case EDefp(n, _, g, b): EDefp(n, newParams, g, b);
                            default: node.def;
                        };
                        return make(newDef, node.metadata);
                    }
                    return node;
                    
                case ECase(expr, clauses):
                    // Handle case clause patterns
                    var hasRenames = false;
                    var newClauses = [];
                    
                    for (i in 0...clauses.length) {
                        var key = '$containerId:CaseClause:$i';
                        var renames = renameIndex.get(key);
                        
                        if (renames != null && renames.length > 0) {
                            hasRenames = true;
                            var newPattern = renamePatternWithLocators(clauses[i].pattern, renames, []);
                            newClauses.push({
                                pattern: newPattern,
                                guard: clauses[i].guard,
                                body: clauses[i].body
                            });
                        } else {
                            newClauses.push(clauses[i]);
                        }
                    }
                    
                    if (hasRenames) {
                        return make(ECase(expr, newClauses), node.metadata);
                    }
                    return node;

                case EVar(name):
                    // Rename variable references to match renamed bindings
                    if (nameMapping.exists(name)) {
                        var newName = nameMapping.get(name);
                        #if debug_hygiene
                        trace('[XRay Hygiene] Renaming EVar "$name" to "$newName"');
                        #end
                        return make(EVar(newName), node.metadata);
                    }
                    return node;

                default:
                    return node;
            }
        });
    }

    /**
     * Apply renaming to unused bindings using context's shared mapping
     *
     * WHY: Use single source of truth for variable renames across all phases
     * WHAT: Registers renames in context.tempVarRenameMap, applies from that map
     * HOW: Same algorithm as renameUnusedBindings but uses context instead of local map
     *
     * KEY DIFFERENCE:
     * - Original: Creates local nameMapping = new Map()
     * - This: Uses context.tempVarRenameMap
     * - Result: Builder and transformer phases coordinate on variable names
     */
    static function renameUnusedBindingsWithContext(ast: ElixirAST, allBindings: Array<Binding>,
                                                    context: reflaxe.elixir.CompilationContext): ElixirAST {
        // Build index: Map<(containerId, context, slotIndex), Array<{path, oldName, newName}>>
        var renameIndex = new Map<String, Array<{path: Array<Int>, oldName: String, newName: String}>>();

        // CRITICAL FIX: Initialize from context to preserve builder phase decisions
        // Previously created empty map (new Map()), losing all upstream rename information
        // from the builder phase. This caused undefined variable errors when EVar references
        // tried to use names that the builder had detected as unused and renamed.
        //
        // Now follows the cumulative context pattern from mature Reflaxe compilers:
        // - Builder phase: DETECTS unused variables, sets dual-key mappings (ID + name)
        // - Transformer phase: APPLIES renames using builder's decisions
        // - Context: PRESERVES decisions between phases (not lost!)
        //
        // The helper extracts ONLY name-based keys from context (filters out numeric IDs)
        // so EVar reference renaming works correctly.
        var nameMapping = initializeNameMappingFromContext(context);

        #if debug_hygiene
        trace('[XRay Hygiene] Initialized nameMapping with ${Lambda.count(nameMapping)} entries from context');
        for (key in nameMapping.keys()) {
            trace('[XRay Hygiene]   Context mapping: $key -> ${nameMapping.get(key)}');
        }
        #end

        for (binding in allBindings) {
            // CRITICAL FIX: Pattern variables should NEVER be renamed with underscore prefix
            // Pattern-bound variables (like 'value' in {:ok, value}) are ALWAYS available in the case body
            // by definition - they're bound by the pattern match, not declared as unused locals.
            // Renaming them breaks the pattern→body coordination.
            if (!binding.used && !binding.name.startsWith("_") && binding.kind != PatternVar) {
                var key = '${binding.containerId}:${binding.context}:${binding.slotIndex}';
                if (!renameIndex.exists(key)) {
                    renameIndex.set(key, []);
                }
                renameIndex.get(key).push({
                    path: binding.path,
                    oldName: binding.name,
                    newName: "_" + binding.name
                });

                // Register rename in SHARED context mapping (not local)
                nameMapping.set(binding.name, "_" + binding.name);

                #if debug_hygiene
                trace('[XRay Hygiene Context] Registered rename in context: ${binding.name} -> _${binding.name}');
                #end
            }
        }

        #if debug_hygiene
        trace('[XRay Hygiene Context] Built rename index with ${Lambda.count(renameIndex)} containers to process');
        trace('[XRay Hygiene Context] Using context name mapping with ${Lambda.count(nameMapping)} entries');
        for (oldName in nameMapping.keys()) {
            trace('[XRay Hygiene Context]   $oldName -> ${nameMapping.get(oldName)}');
        }
        #end

        // Apply renaming using the shared context mapping
        return ElixirASTTransformer.transformNode(ast, function(node) {
            if (node.metadata == null) return node;

            var containerId = Reflect.field(node.metadata, "astId");
            if (containerId == null) return node;

            switch(node.def) {
                case EDef(name, params, guards, body) | EDefp(name, params, guards, body):
                    // Check if we have renames for this container's parameters
                    var hasRenames = false;
                    var newParams = [];

                    for (i in 0...params.length) {
                        var key = '$containerId:DefParam:$i';
                        var renames = renameIndex.get(key);

                        if (renames != null && renames.length > 0) {
                            hasRenames = true;
                            newParams.push(renamePatternWithLocators(params[i], renames, []));
                        } else {
                            newParams.push(params[i]);
                        }
                    }

                    if (hasRenames) {
                        var newDef = switch(node.def) {
                            case EDef(n, _, g, b): EDef(n, newParams, g, b);
                            case EDefp(n, _, g, b): EDefp(n, newParams, g, b);
                            default: node.def;
                        };
                        return make(newDef, node.metadata);
                    }
                    return node;

                case ECase(expr, clauses):
                    // Handle case clause patterns
                    var hasRenames = false;
                    var newClauses = [];

                    for (i in 0...clauses.length) {
                        var key = '$containerId:CaseClause:$i';
                        var renames = renameIndex.get(key);

                        if (renames != null && renames.length > 0) {
                            hasRenames = true;
                            var newPattern = renamePatternWithLocators(clauses[i].pattern, renames, []);
                            newClauses.push({
                                pattern: newPattern,
                                guard: clauses[i].guard,
                                body: clauses[i].body
                            });
                        } else {
                            newClauses.push(clauses[i]);
                        }
                    }

                    if (hasRenames) {
                        return make(ECase(expr, newClauses), node.metadata);
                    }
                    return node;

                case EVar(name):
                    // Rename variable references to match renamed bindings
                    // Reading from SHARED context mapping ensures consistency
                    if (nameMapping.exists(name)) {
                        var newName = nameMapping.get(name);
                        #if debug_hygiene
                        trace('[XRay Hygiene Context] Renaming EVar "$name" to "$newName" (from context)');
                        #end
                        return make(EVar(newName), node.metadata);
                    }
                    return node;

                default:
                    return node;
            }
        });
    }

    /**
     * HELPER: isNumericId - Detect AST Node ID Strings
     *
     * WHY: Need to filter numeric AST node IDs from variable names in context
     *
     * During compilation, the builder phase registers variables using BOTH:
     * - ID-based keys: Std.string(v.id) → "57694" (numeric AST node ID)
     * - Name-based keys: v.name → "changeset" (actual variable name)
     *
     * When extracting name-based keys from context for transformer phase, we must
     * filter out the numeric ID strings to avoid treating them as variable names.
     *
     * WHAT: Detects strings that are purely numeric (AST node IDs)
     *
     * Returns true for strings like:
     * - "57694" (AST node ID) → true
     * - "123" (numeric ID) → true
     * - "changeset" (variable name) → false
     * - "user_id" (variable name) → false
     * - "_unused" (prefixed variable) → false
     *
     * HOW: Regex pattern matches one or more digits
     *
     * Pattern: ~/^[0-9]+$/
     * - ^ : Start of string
     * - [0-9]+ : One or more digits (0-9)
     * - $ : End of string
     *
     * This ensures ONLY purely numeric strings match, avoiding false positives
     * like "user123" (contains digits but not purely numeric).
     *
     * @param str String to test for numeric ID pattern
     * @return true if string is purely numeric (AST node ID), false otherwise
     */
    static function isNumericId(str: String): Bool {
        return ~/^[0-9]+$/.match(str);
    }

    /**
     * HELPER: initializeNameMappingFromContext - Extract Name-Based Variable Renames
     *
     * WHY: Bridge builder phase decisions to transformer phase
     *
     * ARCHITECTURAL CONTEXT:
     * The root cause of the hygiene bug is that line 795 creates a fresh local Map,
     * losing ALL builder phase rename decisions. This breaks the cumulative context
     * pattern used by mature Reflaxe compilers where:
     * - Builder phase: DETECTS unused variables and registers renames
     * - Transformer phase: APPLIES renames based on builder decisions
     * - Context: SHARED state preserving decisions between phases
     *
     * The builder phase registers variables using DUAL-KEY storage:
     * - ID-based keys: Std.string(v.id) → "57694" (for pattern matching)
     * - Name-based keys: v.name → "changeset" (for EVar reference renaming)
     *
     * This function extracts ONLY the name-based keys from context, enabling the
     * transformer to apply renames that the builder phase detected.
     *
     * WHAT: Extracts name-based variable rename mappings from compilation context
     *
     * Filters context.tempVarRenameMap to extract only name-based entries:
     * - KEEP: "changeset" → "_changeset" (variable name)
     * - KEEP: "user" → "_user" (variable name)
     * - SKIP: "57694" → "_temp" (numeric AST node ID)
     * - SKIP: "_unused" → "_unused" (already prefixed)
     *
     * Returns a Map ready for use in the transformer phase, containing only the
     * variable name → renamed variable mappings that EVar references can use.
     *
     * HOW: Defensive iteration with filtering logic
     *
     * Algorithm:
     * 1. Create empty mapping Map
     * 2. Defensive null check on context.tempVarRenameMap
     * 3. Iterate all keys in context map
     * 4. For each key-value pair:
     *    - Skip if key is numeric ID (isNumericId check)
     *    - Skip if key already has underscore prefix
     *    - Add to mapping for name-based keys
     * 5. Debug trace each loaded rename (XRay pattern)
     * 6. Return filtered mapping
     *
     * PERFORMANCE: O(n) where n = number of entries in context map
     * Typical n < 100, so negligible overhead
     *
     * @param context CompilationContext containing builder phase rename decisions
     * @return Map<String, String> with name-based variable renames only
     */
    static function initializeNameMappingFromContext(context: reflaxe.elixir.CompilationContext): Map<String, String> {
        var mapping = new Map<String, String>();

        // Defensive: context.tempVarRenameMap may be null in early compilation phases
        if (context.tempVarRenameMap == null) {
            #if debug_hygiene
            trace('[XRay Hygiene Context] tempVarRenameMap is null, returning empty mapping');
            #end
            return mapping;
        }

        #if debug_hygiene
        trace('[XRay Hygiene Context] Initializing name mapping from context...');
        trace('[XRay Hygiene Context] Context has ${Lambda.count(context.tempVarRenameMap)} total entries');
        #end

        // Extract name-based keys, filtering out numeric IDs and already-prefixed names
        for (key in context.tempVarRenameMap.keys()) {
            var value = context.tempVarRenameMap.get(key);

            // Filter 1: Skip numeric AST node IDs (e.g., "57694")
            if (isNumericId(key)) {
                #if debug_hygiene
                trace('[XRay Hygiene Context] Skipping numeric ID: $key');
                #end
                continue;
            }

            // Filter 2: Skip already-prefixed names (e.g., "_unused")
            if (key.startsWith("_")) {
                #if debug_hygiene
                trace('[XRay Hygiene Context] Skipping underscore-prefixed: $key');
                #end
                continue;
            }

            // This is a name-based key - preserve it for transformer phase
            mapping.set(key, value);

            #if debug_hygiene
            trace('[XRay Hygiene Context] ✓ Loaded from context: $key -> $value');
            #end
        }

        #if debug_hygiene
        trace('[XRay Hygiene Context] Extracted ${Lambda.count(mapping)} name-based mappings');
        #end

        return mapping;
    }

    /**
     * Rename variables in a pattern using locators
     */
    static function renamePatternWithLocators(pattern: EPattern, renames: Array<{path: Array<Int>, oldName: String, newName: String}>, 
                                             currentPath: Array<Int>): EPattern {
        switch(pattern) {
            case PVar(name):
                // Check if current path matches any rename entry
                for (rename in renames) {
                    if (pathsEqual(currentPath, rename.path) && name == rename.oldName) {
                        #if debug_hygiene
                        trace('[XRay Hygiene] Renaming "$name" to "${rename.newName}" at path [${currentPath.join(",")}]');
                        #end
                        return PVar(rename.newName);
                    }
                }
                return pattern;
                
            case PTuple(patterns):
                var newPatterns = [];
                for (i in 0...patterns.length) {
                    var childPath = currentPath.copy();
                    childPath.push(i);
                    newPatterns.push(renamePatternWithLocators(patterns[i], renames, childPath));
                }
                return PTuple(newPatterns);
                
            case PList(patterns):
                var newPatterns = [];
                for (i in 0...patterns.length) {
                    var childPath = currentPath.copy();
                    childPath.push(i);
                    newPatterns.push(renamePatternWithLocators(patterns[i], renames, childPath));
                }
                return PList(newPatterns);
                
            case PMap(pairs):
                var newPairs = [];
                for (i in 0...pairs.length) {
                    var childPath = currentPath.copy();
                    childPath.push(i);
                    childPath.push(1); // Value is at index 1
                    newPairs.push({
                        key: pairs[i].key,
                        value: renamePatternWithLocators(pairs[i].value, renames, childPath)
                    });
                }
                return PMap(newPairs);
                
            default:
                return pattern;
        }
    }
    
    /**
     * Check if two paths are equal
     */
    static function pathsEqual(path1: Array<Int>, path2: Array<Int>): Bool {
        if (path1.length != path2.length) return false;
        for (i in 0...path1.length) {
            if (path1[i] != path2[i]) return false;
        }
        return true;
    }
    
    /**
     * Check if a pattern is used in the given body and prefix with underscore if not
     */
    static function prefixUnusedPattern(pattern: EPattern, body: ElixirAST): EPattern {
        switch(pattern) {
            case PVar(name):
                // Don't touch already underscored variables
                if (name.charAt(0) == "_") return pattern;
                
                #if debug_hygiene
                trace('[XRay Hygiene] Checking usage of parameter: $name');
                #end
                
                // Check if variable is used in body
                var isUsed = isVariableUsedInBody(name, body);
                
                #if debug_hygiene
                trace('[XRay Hygiene] Parameter $name is ${isUsed ? "USED" : "UNUSED"}');
                #end
                
                if (!isUsed) {
                    #if debug_hygiene
                    trace('[XRay Hygiene] Adding underscore to unused parameter: $name -> _$name');
                    #end
                    return PVar("_" + name);
                }
                return pattern;
                
            default:
                return pattern;
        }
    }
    
    /**
     * Check if a variable name is referenced in the body
     * 
     * COMPREHENSIVE TRAVERSAL: Must check ALL node types to find nested variable usage
     * Example: `Std.int(t)` - the `t` is nested inside a call argument
     * 
     * The transformNode function handles recursion, but we must ensure we're
     * checking for EVar in all positions where it could appear.
     */
    static function isVariableUsedInBody(varName: String, body: ElixirAST): Bool {
        var used = false;
        var nodeCount = 0;
        var depth = 0;
        
        // Use transformer to search for variable usage recursively
        // CRITICAL: transformNode DOES traverse all children automatically
        // We just need to check for EVar nodes at any depth
        ElixirASTTransformer.transformNode(body, function(node) {
            nodeCount++;
            
            #if debug_hygiene_verbose
            var indent = [for (i in 0...depth) "  "].join("");
            trace('$indent[XRay Hygiene] Node #$nodeCount: ${Type.enumConstructor(node.def)}');
            #end
            
            // Check if this node is a variable reference
            switch(node.def) {
                case EVar(name):
                    #if debug_hygiene
                    trace('[XRay Hygiene] Found EVar("$name") - checking against "$varName"');
                    #end
                    if (name == varName) {
                        #if debug_hygiene
                        trace('[XRay Hygiene] ✓ MATCH! Variable $varName is USED in the body!');
                        #end
                        used = true;
                    }
                    
                // Log other node types for debugging but don't need special handling
                // since transformNode will recurse into them automatically
                case ECall(target, funcName, args):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] ECall to $funcName with ${args.length} args - will traverse args');
                    #end
                    
                case EBinary(op, left, right):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] EBinary operator - will traverse both operands');
                    #end
                    
                case ETuple(elements):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] ETuple with ${elements.length} elements - will traverse all');
                    #end
                    
                case EList(elements):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] EList with ${elements.length} elements - will traverse all');
                    #end
                    
                case EBlock(statements):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] EBlock with ${statements.length} statements - will traverse all');
                    depth++;
                    #end
                    
                case EIf(cond, thenBranch, elseBranch):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] EIf - will traverse condition and both branches');
                    #end
                    
                case ECase(expr, clauses):
                    #if debug_hygiene_verbose
                    trace('[XRay Hygiene] ECase with ${clauses.length} clauses - will traverse all');
                    #end
                    
                default:
                    // transformNode handles all other cases automatically
                    #if debug_hygiene_verbose
                    if (nodeCount < 20) { // Limit verbose output
                        trace('[XRay Hygiene] Other node type: ${Type.enumConstructor(node.def)}');
                    }
                    #end
            }
            
            // Return node unchanged - we're just searching, not transforming
            return node;
        });
        
        #if debug_hygiene
        if (!used) {
            trace('[XRay Hygiene] Variable "$varName" NOT found after checking $nodeCount nodes');
        } else {
            trace('[XRay Hygiene] Variable "$varName" WAS FOUND (checked $nodeCount nodes)');
        }
        #end
        
        return used;
    }
    
    /**
     * Atom Normalization Pass
     * 
     * WHY: Remove unnecessary atom quoting to reduce warnings
     * WHAT: Convert quoted atoms to bare atoms where safe
     * HOW: Check atom content and unquote if it's a valid identifier
     */
    public static function atomNormalizationPass(ast: ElixirAST): ElixirAST {
        #if debug_hygiene
        trace('[XRay Hygiene] Starting atom normalization pass');
        #end
        
        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case EAtom(value):
                    // Remove quotes if atom is a valid identifier
                    if (isValidBareAtom(value)) {
                        // Return unquoted atom
                        return make(EAtom(unquoteAtom(value)), node.metadata);
                    }
                    return node;
                default:
                    return node;
            }
        });
    }
    
    /**
     * Equality to Pattern Matching Pass
     * 
     * WHY: Transform == comparisons to idiomatic pattern matching
     * WHAT: Convert type/atom comparisons to match? or case expressions
     * HOW: Detect equality patterns and transform to appropriate idiom
     */
    public static function equalityToPatternPass(ast: ElixirAST): ElixirAST {
        #if debug_hygiene
        trace('[XRay Hygiene] Starting equality to pattern pass');
        #end
        
        return ElixirASTTransformer.transformNode(ast, function(node) {
            switch(node.def) {
                case EBinary(Equal, left, right):
                    // Check if this is a type/atom comparison
                    if (isPatternMatchCandidate(left, right)) {
                        // Transform to match? expression
                        return createMatchExpression(left, right, node.metadata);
                    }
                    return node;
                default:
                    return node;
            }
        });
    }
    
    // Helper functions
    
    static function isValidBareAtom(value: String): Bool {
        // Check if atom can be written without quotes
        // Must start with lowercase letter or underscore
        // Can contain letters, numbers, underscores
        if (value.length == 0) return false;
        
        var first = value.charAt(0);
        if (!isLowerCase(first) && first != "_") return false;
        
        for (i in 1...value.length) {
            var char = value.charAt(i);
            if (!isAlphaNumeric(char) && char != "_") return false;
        }
        
        return true;
    }
    
    static function unquoteAtom(value: String): String {
        // Remove surrounding quotes if present
        if (value.startsWith('"') && value.endsWith('"')) {
            return value.substr(1, value.length - 2);
        }
        return value;
    }
    
    static function isPatternMatchCandidate(left: ElixirAST, right: ElixirAST): Bool {
        // Check if this is a comparison that could be pattern matched
        switch(right.def) {
            case EAtom(_): return true;
            case ETuple(_): return true;
            case EInteger(_): return true;
            default: return false;
        }
    }
    
    static function createMatchExpression(left: ElixirAST, right: ElixirAST, metadata: Any): ElixirAST {
        // Create match?/2 expression
        return make(
            ECall(
                null,
                "match?",
                [right, left]
            ),
            metadata
        );
    }
    
    
    static function isLowerCase(char: String): Bool {
        var code = char.charCodeAt(0);
        return code >= 97 && code <= 122; // a-z
    }
    
    static function isAlphaNumeric(char: String): Bool {
        var code = char.charCodeAt(0);
        return (code >= 48 && code <= 57) || // 0-9
               (code >= 65 && code <= 90) || // A-Z
               (code >= 97 && code <= 122);  // a-z
    }
}

#end