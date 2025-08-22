package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.ElixirCompiler;
using reflaxe.helpers.NameMetaHelper;
using StringTools;

/**
 * SubstitutionCompiler: Variable Name Transformation and Substitution Engine
 * 
 * WHY: Variable handling was scattered across multiple 800+ line functions in ElixirCompiler.
 * This represents a clear domain boundary - ALL variable name transformations, substitutions,
 * and renaming operations belong in one place for maintainability and testability.
 * 
 * WHAT: Centralized variable handling with three primary operations:
 * - TVar-based substitution (object-level variable matching for robust lambda parameters)
 * - String-based substitution (pattern-based variable replacement for legacy compatibility)
 * - Multiple variable renaming (collision resolution in desugared loop code)
 * - Variable pattern detection and filtering (system vs user variables)
 * - Variable extraction from AST patterns (modified variables, collision detection)
 * 
 * HOW: The compiler processes TypedExpr AST recursively, applying variable transformations
 * while preserving expression semantics. Uses both TVar object matching (preferred) and
 * string pattern matching (fallback) to handle different compilation contexts.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: All variable operations in one domain-focused class
 * - Open/Closed Principle: Easy to add new substitution patterns without modifying existing logic
 * - Testability: Variable logic can be tested in isolation from expression compilation
 * - Maintainability: Clear boundaries between variable handling and other compilation concerns
 * - Performance: Centralized caching of variable patterns and optimized matching algorithms
 * 
 * EDGE CASES:
 * - System variable filtering (_g, _g1, temp_*, arg0, etc.)
 * - Variable collision resolution in nested loop contexts
 * - TVar object identity vs string name matching for lambda parameters
 * - Type-aware string concatenation vs numeric addition in substituted expressions
 * - Field access preservation on substituted variables (v.id becomes item.id)
 * 
 * @see docs/03-compiler-development/variable-substitution-patterns.md - Complete substitution patterns
 */
@:nullSafety(Off)
class SubstitutionCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    
    /**
     * Create a new substitution compiler
     * 
     * @param compiler The main ElixirCompiler instance for expression compilation
     */
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Compile expression with TVar-based variable substitution
     * 
     * WHY: TVar object matching is the most robust way to substitute lambda parameters.
     * String-based matching can have false positives, while TVar matching guarantees
     * we're substituting the exact same variable from the AST.
     * 
     * WHAT: Recursively processes TypedExpr AST, replacing TLocal(sourceTVar) with targetVarName
     * while preserving all other expression semantics (field access, method calls, operators, etc.)
     * 
     * HOW:
     * 1. Pattern match on TypedExpr.expr to handle all AST node types
     * 2. For TLocal nodes, compare TVar objects directly (exact match)
     * 3. Fallback to name-based matching for same logical variable
     * 4. Recursively process nested expressions (TBinop, TField, TCall, etc.)
     * 5. Preserve type information for proper string concatenation vs numeric addition
     * 
     * @param expr The expression to process
     * @param sourceTVar The TVar object to substitute
     * @param targetVarName The replacement variable name
     * @return Compiled expression with variable substitution applied
     */
    public function compileExpressionWithTVarSubstitution(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] TVAR SUBSTITUTION START");
        trace('[XRay SubstitutionCompiler] Source TVar: ${compiler.getOriginalVarName(sourceTVar)}');
        trace('[XRay SubstitutionCompiler] Target name: ${targetVarName}');
        #end
        
        switch (expr.expr) {
            case TLocal(v):
                // Debug output to understand what variables we're dealing with
                var varName = compiler.getOriginalVarName(v);
                var sourceVarName = compiler.getOriginalVarName(sourceTVar);
                
                #if debug_substitution_compiler
                trace('[XRay SubstitutionCompiler] Checking TLocal: ${varName} vs ${sourceVarName}');
                #end
                
                // TVar-based variable identification for reliable lambda parameter substitution
                
                // Enhanced matching: try exact object match first, then fallback to more permissive matching
                if (v == sourceTVar) {
                    // Exact object match - this is definitely the same variable
                    #if debug_substitution_compiler
                    trace("[XRay SubstitutionCompiler] ✓ EXACT TVAR MATCH");
                    #end
                    return targetVarName;
                }
                
                // Fallback: check if this is likely the same logical variable
                // If both have the same original name, they're likely the same logical variable
                if (varName == sourceVarName && varName != null && varName != "") {
                    #if debug_substitution_compiler
                    trace("[XRay SubstitutionCompiler] ✓ NAME-BASED FALLBACK MATCH");
                    #end
                    return targetVarName;
                }
                
                // Use helper function for aggressive substitution as fallback
                if (shouldSubstituteVariable(varName, null, true)) {
                    #if debug_substitution_compiler
                    trace("[XRay SubstitutionCompiler] ✓ AGGRESSIVE PATTERN MATCH");
                    #end
                    return targetVarName;
                }
                
                // Not a match - compile normally
                #if debug_substitution_compiler
                trace("[XRay SubstitutionCompiler] ✗ NO MATCH - COMPILE NORMALLY");
                #end
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
                var obj = compileExpressionWithTVarSubstitution(e, sourceTVar, targetVarName);
                var fieldName = compiler.getFieldName(fa);
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
                
                return result;
                
            case _:
                // For other cases, fall back to regular compilation
                return compiler.compileExpression(expr);
        }
    }
    
    /**
     * Compile expression with string-based variable substitution
     * 
     * WHY: Legacy compatibility and pattern-based substitution when TVar matching isn't available.
     * Some compilation contexts only have variable names, not TVar objects.
     * 
     * WHAT: Recursively processes TypedExpr AST, replacing variable names matching sourceVar
     * with targetVar using pattern-based matching rules.
     * 
     * HOW:
     * 1. For TLocal nodes, check if variable name should be substituted
     * 2. Use shouldSubstituteVariable() for pattern-based matching
     * 3. Recursively process all nested expressions
     * 4. Handle special cases like function calls and array access
     * 
     * @param expr The expression to process
     * @param sourceVar The variable name to substitute
     * @param targetVar The replacement variable name
     * @return Compiled expression with variable substitution applied
     */
    public function compileExpressionWithSubstitution(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] STRING SUBSTITUTION START");
        trace('[XRay SubstitutionCompiler] Source var: ${sourceVar} -> Target var: ${targetVar}');
        #end
        
        switch (expr.expr) {
            case TLocal(v):
                var varName = compiler.getOriginalVarName(v);
                // Use helper function for consistent substitution logic
                if (shouldSubstituteVariable(varName, sourceVar, false)) {
                    #if debug_substitution_compiler
                    trace('[XRay SubstitutionCompiler] ✓ SUBSTITUTING: ${varName} -> ${targetVar}');
                    #end
                    return targetVar;
                }
                return compiler.compileExpression(expr);
                
            case TBinop(op, e1, e2):
                var left = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
                var right = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                return '${left} ${compiler.compileBinop(op)} ${right}';
                
            case TField(e, fa):
                var obj = compileExpressionWithSubstitution(e, sourceVar, targetVar);
                var fieldName = compiler.getFieldName(fa);
                return '${obj}.${fieldName}';
                
            case TCall(e, args):
                var func = compileExpressionWithSubstitution(e, sourceVar, targetVar);
                var compiledArgs = args.map(arg -> compileExpressionWithSubstitution(arg, sourceVar, targetVar));
                return '${func}(${compiledArgs.join(", ")})';
                
            case TArray(e1, e2):
                var arr = compileExpressionWithSubstitution(e1, sourceVar, targetVar);
                var index = compileExpressionWithSubstitution(e2, sourceVar, targetVar);
                return 'Enum.at(${arr}, ${index})';
                
            case TIf(econd, eif, eelse):
                var condition = compileExpressionWithSubstitution(econd, sourceVar, targetVar);
                var thenValue = compileExpressionWithSubstitution(eif, sourceVar, targetVar);
                var elseValue = eelse != null ? compileExpressionWithSubstitution(eelse, sourceVar, targetVar) : "nil";
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                
            case TBlock(exprs):
                var compiledExprs = exprs.map(e -> compileExpressionWithSubstitution(e, sourceVar, targetVar));
                return compiledExprs.join('\n');
                
            case TParenthesis(e):
                return "(" + compileExpressionWithSubstitution(e, sourceVar, targetVar) + ")";
                
            case TUnop(op, postFix, e):
                var operand = compileExpressionWithSubstitution(e, sourceVar, targetVar);
                var result = switch (op) {
                    case OpIncrement: '${operand} + 1';
                    case OpDecrement: '${operand} - 1'; 
                    case OpNot: '!${operand}';
                    case OpNeg: '-${operand}';
                    case OpNegBits: 'bnot(${operand})';
                    case _: operand;
                };
                return result;
                
            case _:
                return compiler.compileExpression(expr);
        }
    }
    
    /**
     * Compile expression with multiple variable renamings applied
     * 
     * WHY: Variable collision resolution in desugared loop code requires simultaneous
     * renaming of multiple variables to avoid naming conflicts.
     * 
     * WHAT: Applies a Map of variable renamings to an expression, handling complex cases
     * like variable declarations, array operations, and function calls.
     * 
     * HOW:
     * 1. Check if variable name exists in renamings map
     * 2. Apply appropriate renaming based on expression type
     * 3. Handle special cases like array concatenation and length access
     * 4. Recursively process nested expressions with same renamings
     * 
     * @param expr The expression to process
     * @param renamings Map of original variable names to new names
     * @return Compiled expression with variable renamings applied
     */
    public function compileExpressionWithRenaming(expr: TypedExpr, renamings: Map<String, String>): String {
        if (renamings == null || !renamings.keys().hasNext()) {
            // No renamings - compile normally
            return compiler.compileExpression(expr);
        }
        
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] RENAMING START");
        trace('[XRay SubstitutionCompiler] Renamings: ${[for (k => v in renamings) k + " -> " + v].join(", ")}');
        #end
        
        switch (expr.expr) {
            case TLocal(v):
                var varName = compiler.getOriginalVarName(v);
                // Check if this variable needs renaming
                if (renamings.exists(varName)) {
                    var newName = renamings.get(varName);
                    #if debug_substitution_compiler
                    trace('[XRay SubstitutionCompiler] ✓ RENAMING: ${varName} -> ${newName}');
                    #end
                    return newName;
                }
                // Not renamed - compile normally
                return compiler.compileExpression(expr);
                
            case TVar(v, init):
                var varName = compiler.getOriginalVarName(v);
                // Check if this variable declaration needs renaming
                if (renamings.exists(varName)) {
                    var newName = renamings.get(varName);
                    if (init != null) {
                        var compiledInit = compileExpressionWithRenaming(init, renamings);
                        return '${newName} = ${compiledInit}';
                    } else {
                        return '${newName} = nil';
                    }
                }
                // Not renamed - but still need to apply renamings to the init expression
                if (init != null) {
                    var compiledInit = compileExpressionWithRenaming(init, renamings);
                    return '${varName} = ${compiledInit}';
                } else {
                    return '${varName} = nil';
                }
                
            case TBinop(op, e1, e2):
                // Recursively apply renamings to both sides
                var left = compileExpressionWithRenaming(e1, renamings);
                var right = compileExpressionWithRenaming(e2, renamings);
                
                // Handle the operator
                return switch (op) {
                    case OpAdd: '${left} ++ ${right}'; // Array concatenation in desugared loops
                    case OpAssign: '${left} = ${right}';
                    case OpEq: '${left} == ${right}';
                    case OpNotEq: '${left} != ${right}';
                    case OpLt: '${left} < ${right}';
                    case OpLte: '${left} <= ${right}';
                    case OpGt: '${left} > ${right}';
                    case OpGte: '${left} >= ${right}';
                    case _: compiler.compileExpression(expr); // Fall back for complex operators
                };
                
            case TField(e, fa):
                // Apply renamings to the object being accessed
                var obj = compileExpressionWithRenaming(e, renamings);
                
                // Handle field access
                switch (fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf):
                        var fieldName = cf.get().name;
                        // Check if this is a special array property like 'length'
                        if (fieldName == "length") {
                            // In Elixir, use Enum.count for array length
                            return 'Enum.count(${obj})';
                        }
                        return '${obj}.${fieldName}';
                    case FDynamic(s):
                        return '${obj}.${s}';
                    case FClosure(_, cf):
                        var fieldName = cf.get().name;
                        return '${obj}.${fieldName}';
                    case FEnum(_, ef):
                        return ef.name;
                }
                
            case TCall(e, el):
                // Apply renamings to function and arguments
                var func = compileExpressionWithRenaming(e, renamings);
                var args = el.map(arg -> compileExpressionWithRenaming(arg, renamings));
                return '${func}(${args.join(", ")})';
                
            case TIf(econd, eif, eelse):
                // Handle if-statements in variable renaming context
                var condition = compileExpressionWithRenaming(econd, renamings);
                var thenBranch = compileExpressionWithRenaming(eif, renamings);
                var elseBranch = eelse != null ? compileExpressionWithRenaming(eelse, renamings) : "nil";
                
                return 'if ${condition}, do: ${thenBranch}, else: ${elseBranch}';
                
            case TBlock(exprs):
                // Handle blocks with renaming
                var compiledExprs = exprs.map(e -> compileExpressionWithRenaming(e, renamings));
                return compiledExprs.join('\n');
                
            case TParenthesis(e):
                return "(" + compileExpressionWithRenaming(e, renamings) + ")";
                
            case TUnop(op, postFix, e):
                var operand = compileExpressionWithRenaming(e, renamings);
                var result = switch (op) {
                    case OpIncrement: '${operand} + 1';
                    case OpDecrement: '${operand} - 1'; 
                    case OpNot: '!${operand}';
                    case OpNeg: '-${operand}';
                    case OpNegBits: 'bnot(${operand})';
                    case _: operand;
                };
                return result;
                
            case _:
                // For other expression types, fall back to regular compilation
                return compiler.compileExpression(expr);
        }
    }
    
    /**
     * Determine if a variable should be substituted based on patterns
     * 
     * WHY: Consistent variable substitution rules across all substitution methods.
     * Centralizes the logic for determining when a variable name should be replaced.
     * 
     * WHAT: Pattern-based matching that considers:
     * - Exact string matches
     * - System variable filtering
     * - Aggressive matching for similar patterns
     * - Special cases for loop variables
     * 
     * HOW:
     * 1. Handle null/empty cases
     * 2. Check for exact matches when sourceVar is provided
     * 3. Apply system variable filtering
     * 4. Use aggressive matching patterns when enabled
     * 
     * @param varName The variable name to check
     * @param sourceVar The source variable to match against (can be null)
     * @param aggressive Whether to use aggressive pattern matching
     * @return True if the variable should be substituted
     */
    public function shouldSubstituteVariable(varName: String, sourceVar: String, aggressive: Bool): Bool {
        if (varName == null || varName == "") return false;
        
        // If we have a specific source variable, check for exact match
        if (sourceVar != null && sourceVar != "") {
            return varName == sourceVar;
        }
        
        // Filter out system variables (they should never be substituted)
        if (isSystemVariable(varName)) {
            return false;
        }
        
        // If aggressive matching is enabled, use broader patterns
        if (aggressive) {
            // Match common loop variable patterns
            return varName.length <= 3 ||               // Short variable names (i, v, item)
                   varName.startsWith("loop") ||        // Loop-related variables
                   varName.startsWith("iter") ||        // Iterator variables
                   varName == "element" ||              // Common iteration names
                   varName == "item" ||
                   varName == "value";
        }
        
        // Conservative matching - only substitute if explicitly requested
        return false;
    }
    
    /**
     * Check if a variable name represents a system-generated variable
     * 
     * WHY: System variables should never appear in user-facing generated code.
     * They are implementation details of the Haxe compiler or our transpiler.
     * 
     * WHAT: Pattern matching for common system variable patterns:
     * - Compiler temporaries (_g, _g1, _g2)
     * - Temp variables (temp_*)
     * - This references (_this*)
     * - Function arguments (arg0, arg1)
     * - Generic placeholders (target, value)
     * 
     * HOW: String pattern matching with known system variable conventions
     * 
     * @param varName The variable name to check
     * @return True if this is a system variable that should be filtered out
     */
    public function isSystemVariable(varName: String): Bool {
        if (varName == null) return true;
        
        // Common system variable patterns from Haxe and our compiler
        return varName == "_g" || 
               varName == "_g1" || 
               varName == "_g2" ||
               varName.startsWith("temp_") ||
               varName.startsWith("_this") ||
               varName.startsWith("arg0") ||
               varName.startsWith("arg1") ||
               varName == "target" ||  // Generated target variables
               varName == "value" ||   // Generic value variables
               varName.length <= 1;    // Single character vars are usually system
    }
    
    /**
     * Extract variables that are modified within an expression
     * 
     * WHY: Variable collision detection requires knowing which variables are mutated
     * in loop bodies to generate proper Y combinator state management.
     * 
     * WHAT: AST traversal to find all variables that are assigned to, incremented,
     * or otherwise modified within an expression tree.
     * 
     * HOW:
     * 1. Recursively traverse the expression AST
     * 2. Look for assignment operations (TBinop with OpAssign)
     * 3. Look for increment/decrement operations
     * 4. Look for variable declarations with initialization
     * 5. Return list of modified variables with type information
     * 
     * @param expr The expression to analyze
     * @return Array of VarInfo for variables that are modified
     */
    public function extractModifiedVariables(expr: TypedExpr): Array<{name: String, type: String}> {
        var modifiedVars = new Array<{name: String, type: String}>();
        
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] EXTRACT MODIFIED VARIABLES START");
        #end
        
        extractModifiedVariablesRecursive(expr, modifiedVars);
        
        #if debug_substitution_compiler
        trace('[XRay SubstitutionCompiler] Found modified variables: ${modifiedVars.map(v -> v.name).join(", ")}');
        #end
        
        return modifiedVars;
    }
    
    /**
     * Recursive helper for extractModifiedVariables
     * 
     * WHY: Modular recursive traversal keeps the main function clean and allows
     * for easy extension of new AST node types.
     * 
     * WHAT: Pattern matching on TypedExpr to find variable modifications,
     * adding discovered variables to the modifiedVars array.
     * 
     * HOW: Switch on expr.expr and recursively process nested expressions
     */
    private function extractModifiedVariablesRecursive(expr: TypedExpr, modifiedVars: Array<{name: String, type: String}>): Void {
        switch (expr.expr) {
            case TBinop(OpAssign, {expr: TLocal(v)}, _):
                // Variable assignment: variable = value
                var varName = compiler.getOriginalVarName(v);
                var varType = compiler.typeToString(v.t);
                if (!isSystemVariable(varName)) {
                    modifiedVars.push({name: varName, type: varType});
                }
                
            case TUnop(OpIncrement | OpDecrement, _, {expr: TLocal(v)}):
                // Variable increment/decrement: variable++ or ++variable
                var varName = compiler.getOriginalVarName(v);
                var varType = compiler.typeToString(v.t);
                if (!isSystemVariable(varName)) {
                    modifiedVars.push({name: varName, type: varType});
                }
                
            case TVar(v, init):
                // Variable declaration with initialization
                if (init != null) {
                    var varName = compiler.getOriginalVarName(v);
                    var varType = compiler.typeToString(v.t);
                    if (!isSystemVariable(varName)) {
                        modifiedVars.push({name: varName, type: varType});
                    }
                    // Also check the initialization expression
                    extractModifiedVariablesRecursive(init, modifiedVars);
                }
                
            case TBlock(exprs):
                // Process all expressions in the block
                for (e in exprs) {
                    extractModifiedVariablesRecursive(e, modifiedVars);
                }
                
            case TIf(_, eif, eelse):
                // Process both branches of the if statement
                extractModifiedVariablesRecursive(eif, modifiedVars);
                if (eelse != null) {
                    extractModifiedVariablesRecursive(eelse, modifiedVars);
                }
                
            case TBinop(_, e1, e2):
                // Process both operands
                extractModifiedVariablesRecursive(e1, modifiedVars);
                extractModifiedVariablesRecursive(e2, modifiedVars);
                
            case TCall(e, args):
                // Process function and arguments
                extractModifiedVariablesRecursive(e, modifiedVars);
                for (arg in args) {
                    extractModifiedVariablesRecursive(arg, modifiedVars);
                }
                
            case TField(e, _):
                // Process the object being accessed
                extractModifiedVariablesRecursive(e, modifiedVars);
                
            case TArray(e1, e2):
                // Process array and index
                extractModifiedVariablesRecursive(e1, modifiedVars);
                extractModifiedVariablesRecursive(e2, modifiedVars);
                
            case TUnop(_, _, e):
                // Process the operand
                extractModifiedVariablesRecursive(e, modifiedVars);
                
            case TParenthesis(e):
                // Process the parenthesized expression
                extractModifiedVariablesRecursive(e, modifiedVars);
                
            case _:
                // Other expression types don't modify variables
        }
    }
    
    /**
     * Compile expression with variable mapping for loop variable substitution
     * 
     * WHY: String-based variable mapping was scattered in multiple functions in ElixirCompiler.
     * Centralized here for consistency with aggressive substitution patterns.
     * 
     * WHAT: Compiles expressions with source-to-target variable mapping, using aggressive
     * substitution to ensure all TLocal variables are properly replaced.
     * 
     * HOW: Delegates to compileExpressionWithAggressiveSubstitution to handle the heavy lifting
     * of variable replacement while maintaining expression semantics.
     * 
     * @param expr The expression to compile with variable mapping
     * @param sourceVar The source variable name to replace (for compatibility - not used in aggressive mode)
     * @param targetVar The target variable name to use as replacement
     * @return Compiled expression with variable mapping applied
     */
    public function compileExpressionWithVarMapping(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] VAR MAPPING START");
        trace('[XRay SubstitutionCompiler] Source var: ${sourceVar} -> Target var: ${targetVar}');
        #end
        
        // Simplified: Always use aggressive substitution for consistency
        // This ensures all TLocal variables are properly replaced regardless of the source variable
        return compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }
    
    /**
     * Compile expression with aggressive variable substitution
     * 
     * WHY: Lambda expressions in desugared Haxe code often need ALL local variables
     * replaced with the target variable for proper loop compilation.
     * 
     * WHAT: Aggressively replaces ALL TLocal variables with the target variable,
     * useful for situations where we need complete variable substitution.
     * 
     * HOW: 
     * 1. For TLocal expressions, check if variable should be substituted using helper
     * 2. Replace with target variable if substitution criteria are met
     * 3. Recursively process nested expressions with same target variable
     * 4. Handle special cases like field access, function calls, and operators
     * 
     * @param expr The expression to compile with aggressive substitution
     * @param targetVar The target variable name to use for all substitutions
     * @return Compiled expression with aggressive variable substitution applied
     */
    public function compileExpressionWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] AGGRESSIVE SUBSTITUTION START");
        trace('[XRay SubstitutionCompiler] Target var: ${targetVar}');
        #end
        
        switch (expr.expr) {
            case TLocal(v):
                var varName = compiler.getOriginalVarName(v);
                // Use helper function for clean, maintainable variable substitution logic
                if (shouldSubstituteVariable(varName, null, true)) {
                    #if debug_substitution_compiler
                    trace('[XRay SubstitutionCompiler] ✓ AGGRESSIVE SUBSTITUTING: ${varName} -> ${targetVar}');
                    #end
                    return targetVar;
                }
                return compiler.compileExpression(expr);
                
            case TBinop(op, e1, e2):
                var left = compileExpressionWithAggressiveSubstitution(e1, targetVar);
                var right = compileExpressionWithAggressiveSubstitution(e2, targetVar);
                return '${left} ${compiler.compileBinop(op)} ${right}';
                
            case TField(e, fa):
                var obj = compileExpressionWithAggressiveSubstitution(e, targetVar);
                var fieldName = compiler.getFieldName(fa);
                return '${obj}.${fieldName}';
                
            case TCall(e, args):
                var func = compileExpressionWithAggressiveSubstitution(e, targetVar);
                var compiledArgs = args.map(arg -> compileExpressionWithAggressiveSubstitution(arg, targetVar));
                return '${func}(${compiledArgs.join(", ")})';
                
            case TArray(e1, e2):
                var arr = compileExpressionWithAggressiveSubstitution(e1, targetVar);
                var index = compileExpressionWithAggressiveSubstitution(e2, targetVar);
                return 'Enum.at(${arr}, ${index})';
                
            case TIf(econd, eif, eelse):
                var condition = compileExpressionWithAggressiveSubstitution(econd, targetVar);
                var thenValue = compileExpressionWithAggressiveSubstitution(eif, targetVar);
                var elseValue = eelse != null ? compileExpressionWithAggressiveSubstitution(eelse, targetVar) : "nil";
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                
            case TBlock(exprs):
                var compiledExprs = exprs.map(e -> compileExpressionWithAggressiveSubstitution(e, targetVar));
                return compiledExprs.join('\n');
                
            case TParenthesis(e):
                return "(" + compileExpressionWithAggressiveSubstitution(e, targetVar) + ")";
                
            case TUnop(op, postFix, e):
                var operand = compileExpressionWithAggressiveSubstitution(e, targetVar);
                var result = switch (op) {
                    case OpIncrement: '${operand} + 1';
                    case OpDecrement: '${operand} - 1'; 
                    case OpNot: '!${operand}';
                    case OpNeg: '-${operand}';
                    case OpNegBits: 'bnot(${operand})';
                    case _: operand;
                };
                return result;
                
            case _:
                return compiler.compileExpression(expr);
        }
    }
    
    /**
     * Extract transformation logic from mapping body (TVar-based version)
     * 
     * WHY: Array method transformations (map, filter) need to extract the actual
     * transformation logic from complex loop bodies while preserving variable context.
     * 
     * WHAT: Analyzes expression structure to find transformation patterns and extract
     * the core logic that should be applied to each array element.
     * 
     * HOW:
     * 1. Look through block expressions for transformation patterns
     * 2. Handle assignment patterns like _g = _g ++ [transformation]
     * 3. Extract conditional logic for filter operations
     * 4. Apply TVar-based substitution to maintain variable identity
     * 
     * @param expr The expression containing transformation logic
     * @param sourceTVar The source TVar to replace in the transformation
     * @param targetVarName The target variable name for substitution
     * @return Extracted transformation with variable substitution applied
     */
    public function extractTransformationFromBodyWithTVar(expr: TypedExpr, sourceTVar: TVar, targetVarName: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] EXTRACT TRANSFORMATION (TVAR) START");
        trace('[XRay SubstitutionCompiler] Source TVar: ${compiler.getOriginalVarName(sourceTVar)} -> Target: ${targetVarName}');
        #end
        
        switch (expr.expr) {
            case TBlock(exprs):
                // Look for the actual transformation in the loop body
                for (e in exprs) {
                    switch (e.expr) {
                        case TCall(_, args) if (args.length > 0):
                            // Function call pattern like list.push(transformation)
                            switch (args[0].expr) {
                                case TCall(_, innerArgs) if (innerArgs.length > 0):
                                    // Extract and compile the transformation with variable mapping
                                    return compileExpressionWithTVarSubstitution(args[0], sourceTVar, targetVarName);
                                case _:
                            }
                        case TBinop(OpAssign, eleft, eright):
                            // Assignment pattern like _g = _g ++ [transformation]
                            // Look for list concatenation patterns
                            switch (eright.expr) {
                                case TBinop(OpAdd, _, etransform):
                                    // _g = _g ++ [transformation] pattern
                                    return compileExpressionWithTVarSubstitution(etransform, sourceTVar, targetVarName);
                                case _:
                                    return compileExpressionWithTVarSubstitution(eright, sourceTVar, targetVarName);
                            }
                        case TIf(econd, eif, eelse):
                            // Conditional transformation
                            var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                            var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                            var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                            
                            return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                        case _:
                            // Keep looking through other expressions
                    }
                }
            case TIf(econd, eif, eelse):
                // Direct conditional transformation
                var condition = compileExpressionWithTVarSubstitution(econd, sourceTVar, targetVarName);
                var thenValue = compileExpressionWithTVarSubstitution(eif, sourceTVar, targetVarName);
                var elseValue = eelse != null ? compileExpressionWithTVarSubstitution(eelse, sourceTVar, targetVarName) : targetVarName;
                
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case _:
                // Try to compile the expression directly with variable mapping
                return compileExpressionWithTVarSubstitution(expr, sourceTVar, targetVarName);
        }
        return targetVarName; // Fallback: no transformation
    }
    
    /**
     * Extract transformation logic from mapping body (string-based version)
     * 
     * WHY: Legacy compatibility for string-based variable substitution patterns
     * in loop transformation extraction.
     * 
     * WHAT: Analyzes expression structure to find transformation patterns using
     * string-based variable matching instead of TVar-based matching.
     * 
     * HOW: Similar to TVar version but uses string-based variable mapping for
     * compatibility with older compilation patterns.
     * 
     * @param expr The expression containing transformation logic
     * @param sourceVar The source variable name to replace
     * @param targetVar The target variable name for substitution
     * @return Extracted transformation with string-based variable substitution
     */
    public function extractTransformationFromBody(expr: TypedExpr, sourceVar: String, targetVar: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] EXTRACT TRANSFORMATION (STRING) START");
        trace('[XRay SubstitutionCompiler] Source var: ${sourceVar} -> Target var: ${targetVar}');
        #end
        
        switch (expr.expr) {
            case TBlock(exprs):
                // Look for the actual transformation in the loop body
                for (e in exprs) {
                    switch (e.expr) {
                        case TCall(_, args) if (args.length > 0):
                            // Function call pattern like list.push(transformation)
                            switch (args[0].expr) {
                                case TCall(_, innerArgs) if (innerArgs.length > 0):
                                    // Extract and compile the transformation with variable mapping
                                    return compileExpressionWithVarMapping(args[0], sourceVar, targetVar);
                                case _:
                            }
                        case TBinop(OpAssign, eleft, eright):
                            // Assignment pattern like _g = _g ++ [transformation]
                            // Look for list concatenation patterns
                            switch (eright.expr) {
                                case TBinop(OpAdd, _, etransform):
                                    // _g = _g ++ [transformation] pattern
                                    return compileExpressionWithVarMapping(etransform, sourceVar, targetVar);
                                case _:
                                    return compileExpressionWithVarMapping(eright, sourceVar, targetVar);
                            }
                        case TIf(econd, eif, eelse):
                            // Conditional transformation
                            var condition = compileExpressionWithVarMapping(econd, sourceVar, targetVar);
                            var thenValue = compileExpressionWithVarMapping(eif, sourceVar, targetVar);
                            var elseValue = eelse != null ? compileExpressionWithVarMapping(eelse, sourceVar, targetVar) : targetVar;
                            return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
                        case _:
                            // Keep looking through other expressions
                    }
                }
            case TIf(econd, eif, eelse):
                // Direct conditional transformation
                var condition = compileExpressionWithVarMapping(econd, sourceVar, targetVar);
                var thenValue = compileExpressionWithVarMapping(eif, sourceVar, targetVar);
                var elseValue = eelse != null ? compileExpressionWithVarMapping(eelse, sourceVar, targetVar) : targetVar;
                return 'if ${condition}, do: ${thenValue}, else: ${elseValue}';
            case _:
                // Try to compile the expression directly with variable mapping
                return compileExpressionWithVarMapping(expr, sourceVar, targetVar);
        }
        return targetVar; // Fallback: no transformation
    }
    
    /**
     * Extract transformation from body with aggressive substitution
     * 
     * WHY: Some transformation patterns need aggressive variable substitution
     * where ALL local variables are replaced with the target variable.
     * 
     * WHAT: Simplified transformation extraction that applies aggressive substitution
     * to handle cases where variable identity is less important than replacement.
     * 
     * HOW: Delegates to compileExpressionWithAggressiveSubstitution to ensure
     * all TLocal variables are replaced consistently.
     * 
     * @param expr The expression containing transformation logic
     * @param targetVar The target variable name for all substitutions
     * @return Extracted transformation with aggressive variable substitution
     */
    public function extractTransformationFromBodyWithAggressiveSubstitution(expr: TypedExpr, targetVar: String): String {
        #if debug_substitution_compiler
        trace("[XRay SubstitutionCompiler] EXTRACT TRANSFORMATION (AGGRESSIVE) START");
        trace('[XRay SubstitutionCompiler] Target var: ${targetVar}');
        #end
        
        // Simply compile the expression with aggressive substitution
        // All TLocal variables will be replaced with the target variable
        return compileExpressionWithAggressiveSubstitution(expr, targetVar);
    }
}

#end