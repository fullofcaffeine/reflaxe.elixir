package reflaxe.elixir.ast.context;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;

/**
 * ClauseContext: Variable mapping and synthetic binding management for switch case bodies
 *
 * WHY: Manages the complex variable mapping requirements when compiling Haxe switch
 * statements to Elixir pattern matching. Handles both Haxe variables that need renaming
 * and synthetic Elixir variables that only exist in generated code.
 *
 * WHAT: Provides variable name resolution and synthetic binding generation for case clauses
 * - Maps Haxe TVar IDs to their Elixir names in pattern contexts
 * - Generates unique names for synthetic temporaries to avoid collisions
 * - Wraps clause bodies with necessary variable bindings
 * - Tracks which names are in use to prevent conflicts
 *
 * HOW: Maintains mappings consulted during AST building and transformation
 * - Created fresh for each switch case to ensure isolation
 * - Consulted when compiling TLocal references within case bodies
 * - Accumulates synthetic bindings that wrap the final clause body
 * - Ensures consistent naming throughout each clause
 *
 * ARCHITECTURE BENEFITS:
 * - Encapsulation: Variable mapping logic isolated from main builder
 * - Clarity: Clear responsibility for clause-specific variable handling
 * - Testability: Can test variable mapping independently
 * - Maintainability: Changes to mapping logic don't affect builder
 *
 * @see ElixirASTBuilder for usage in switch statement compilation
 * @see PatternMatchBuilder for future home when modularized
 */
class ClauseContext {
    // Maps Haxe TVar.id to the canonical pattern variable name
    public var localToName: Map<Int, String> = new Map();

    // NEW: EnumBindingPlan for consistent enum parameter naming
    // Maps enum parameter index to {finalName: String, isUsed: Bool}
    public var enumBindingPlan: Map<Int, {finalName: String, isUsed: Bool}> = new Map();

    // Synthetic bindings for variables that only exist in Elixir
    public var syntheticBindings: Array<{name: String, init: ElixirAST}> = [];

    // Variables already in scope to avoid collisions
    public var localsInScope: Map<String, Bool> = new Map();

    // Track which names have been used
    private var usedNames: Map<String, Bool> = new Map();

    public function new(?locals: Map<String, Bool>, ?varMapping: Map<Int, String>, ?enumPlan: Map<Int, {finalName: String, isUsed: Bool}>) {
        if (locals != null) this.localsInScope = locals;
        if (varMapping != null) this.localToName = varMapping;
        if (enumPlan != null) this.enumBindingPlan = enumPlan;
    }

    /**
     * Request a synthetic temporary variable
     *
     * @param name Preferred name for the variable
     * @param buildInit Function to build the initialization expression
     * @return ElixirAST reference to the variable
     */
    public function needTemp(name: String, buildInit: () -> ElixirAST): ElixirAST {
        // Check if already created
        if (usedNames.exists(name)) {
            return {def: EVar(name), metadata: {}, pos: null};
        }

        // Handle name collisions with Haxe locals
        var actualName = name;
        if (localsInScope.exists(name)) {
            var counter = 1;
            while (localsInScope.exists('${name}_${counter}') || usedNames.exists('${name}_${counter}')) {
                counter++;
            }
            actualName = '${name}_${counter}';
        }

        // Register the binding
        syntheticBindings.push({name: actualName, init: buildInit()});
        usedNames.set(actualName, true);

        return {def: EVar(actualName), metadata: {}, pos: null};
    }

    /**
     * Wrap a clause body with synthetic bindings if needed
     */
    public function wrapBody(body: ElixirAST): ElixirAST {
        if (syntheticBindings.length == 0) {
            return body;
        }

        // Create a block with bindings followed by the body
        var statements: Array<ElixirAST> = [];
        for (binding in syntheticBindings) {
            // Create assignment: name = init
            statements.push({
                def: EBinary(Match,
                    {def: EVar(binding.name), metadata: {}, pos: null},
                    binding.init
                ),
                metadata: {},
                pos: null
            });
        }
        statements.push(body);

        return {def: EBlock(statements), metadata: {}, pos: null};
    }
}

#end