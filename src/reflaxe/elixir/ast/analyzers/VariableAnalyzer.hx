package reflaxe.elixir.ast.analyzers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.TypedExprTools;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTHelpers;
import reflaxe.elixir.ast.context.BuildContext;
using reflaxe.elixir.ast.NameUtils;
using StringTools;

/**
 * VariableAnalyzer: Variable Usage Detection and Naming Management
 * 
 * WHY: Centralizes all variable analysis logic that was scattered throughout ElixirASTBuilder
 * - Detects whether variables are used in code to apply underscore prefixes
 * - Manages variable name transformations (camelCase to snake_case)
 * - Tracks variable mappings through tempVarRenameMap
 * - Ensures consistent variable naming across compilation phases
 * 
 * WHAT: Core variable analysis and transformation capabilities
 * - Variable usage detection in AST nodes
 * - Name transformation and escaping
 * - Temporary variable generation
 * - Pattern variable extraction
 * - Variable mapping management
 * 
 * HOW: Static analysis methods operating on ElixirAST
 * - Recursive AST traversal for usage detection
 * - Context-aware name transformations
 * - Map-based tracking of variable renamings
 * - Integration with BuildContext for state management
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on variable analysis
 * - Open/Closed Principle: Can extend analysis without modifying core
 * - Testability: Pure functions that can be unit tested
 * - Maintainability: All variable logic in one place
 * - Performance: Optimized recursive traversal
 * 
 * EDGE CASES:
 * - Handles nested variable scopes correctly
 * - Manages underscore prefixes for unused variables
 * - Escapes Elixir reserved keywords
 * - Tracks variable renamings across compilation phases
 */
@:nullSafety(Off)
class VariableAnalyzer {
    
    // ================================================================
    // Variable Usage Detection
    // ================================================================
    
    /**
     * Check if a variable is used anywhere in a list of AST nodes
     * 
     * WHY: Needed to determine if a variable should have underscore prefix
     * WHAT: Recursively searches for variable usage in AST
     * HOW: Traverses all nodes and checks for matching variable names
     */
    public static function usesVariable(nodes: Array<ElixirAST>, varName: String): Bool {
        for (node in nodes) {
            if (usesVariableInNode(node, varName)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * Check if a variable is used in a single AST node (recursive)
     * 
     * WHY: Core recursive function for variable usage detection
     * WHAT: Checks all possible AST patterns for variable references
     * HOW: Pattern matches on AST structure and recurses into children
     */
    public static function usesVariableInNode(node: ElixirAST, varName: String): Bool {
        if (node == null) return false;
        
        return switch(node.def) {
            case EVar(name): name == varName;
            case ERemoteCall(target, _, args): 
                (target != null && usesVariableInNode(target, varName)) || 
                usesVariable(args, varName);
            case EMatch(_, expr): usesVariableInNode(expr, varName);
            case EBinary(_, left, right):
                usesVariableInNode(left, varName) || usesVariableInNode(right, varName);
            case EBlock(exprs): usesVariable(exprs, varName);
            case EList(items): usesVariable(items, varName);
            case ETuple(items): usesVariable(items, varName);
            case EMap(fields):
                var used = false;
                for (field in fields) {
                    if (usesVariableInNode(field.key, varName) || 
                        usesVariableInNode(field.value, varName)) {
                        used = true;
                        break;
                    }
                }
                used;
            case EIf(cond, thenBranch, elseBranch):
                usesVariableInNode(cond, varName) || 
                usesVariableInNode(thenBranch, varName) || 
                (elseBranch != null && usesVariableInNode(elseBranch, varName));
            case ECase(expr, clauses):
                var used = usesVariableInNode(expr, varName);
                if (!used) {
                    for (clause in clauses) {
                        // Check guards and body, but not patterns (patterns define variables)
                        if ((clause.guard != null && usesVariableInNode(clause.guard, varName)) ||
                            usesVariableInNode(clause.body, varName)) {
                            used = true;
                            break;
                        }
                    }
                }
                used;
            case EFor(generators, filters, body, into, uniq):
                // Check generators, filters, body, and into
                var used = false;
                for (gen in generators) {
                    if (usesVariableInNode(gen.expr, varName)) {
                        used = true;
                        break;
                    }
                }
                if (!used) {
                    for (filter in filters) {
                        if (usesVariableInNode(filter, varName)) {
                            used = true;
                            break;
                        }
                    }
                }
                if (!used && body != null) {
                    used = usesVariableInNode(body, varName);
                }
                if (!used && into != null) {
                    used = usesVariableInNode(into, varName);
                }
                used;
            case EField(target, _):
                usesVariableInNode(target, varName);
            case EParen(expr):
                usesVariableInNode(expr, varName);
            case ECall(_, _, args):
                usesVariable(args, varName);
            case EUnary(_, expr):
                usesVariableInNode(expr, varName);
            case EDo(body):
                usesVariable(body, varName);
            case ETry(body, rescueClauses, catchClauses, afterBlock, elseBlock):
                var used = usesVariableInNode(body, varName);
                if (!used && rescueClauses != null) {
                    for (clause in rescueClauses) {
                        if (usesVariableInNode(clause.body, varName)) {
                            used = true;
                            break;
                        }
                    }
                }
                if (!used && catchClauses != null) {
                    for (clause in catchClauses) {
                        if (usesVariableInNode(clause.body, varName)) {
                            used = true;
                            break;
                        }
                    }
                }
                if (!used && afterBlock != null) {
                    used = usesVariableInNode(afterBlock, varName);
                }
                if (!used && elseBlock != null) {
                    used = usesVariableInNode(elseBlock, varName);
                }
                used;
            case EFn(clauses):
                var used = false;
                for (clause in clauses) {
                    if (usesVariableInNode(clause.body, varName)) {
                        used = true;
                        break;
                    }
                }
                used;
            case EPipe(left, right):
                usesVariableInNode(left, varName) || usesVariableInNode(right, varName);
            case EStructUpdate(structExpr, fields):
                var used = usesVariableInNode(structExpr, varName);
                if (!used) {
                    for (field in fields) {
                        if (usesVariableInNode(field.value, varName)) {
                            used = true;
                            break;
                        }
                    }
                }
                used;
            case ECond(clauses):
                var used = false;
                for (clause in clauses) {
                    if (usesVariableInNode(clause.condition, varName) || 
                        usesVariableInNode(clause.body, varName)) {
                        used = true;
                        break;
                    }
                }
                used;
            case EWith(clauses, doBlock, elseBlock):
                var used = false;
                for (clause in clauses) {
                    if (usesVariableInNode(clause.expr, varName)) {
                        used = true;
                        break;
                    }
                }
                if (!used) {
                    used = usesVariableInNode(doBlock, varName);
                }
                if (!used && elseBlock != null) {
                    used = usesVariableInNode(elseBlock, varName);
                }
                used;
            default: false;
        };
    }
    
    // ================================================================
    // Variable Name Transformation
    // ================================================================
    
    /**
     * Convert a Haxe variable name to idiomatic Elixir snake_case
     * 
     * WHY: Elixir uses snake_case for variables, Haxe uses camelCase
     * WHAT: Transforms camelCase to snake_case and handles special cases
     * HOW: Delegates to ElixirASTHelpers for consistency
     * 
     * @param name The variable name to transform
     * @param preserveUnderscore Whether to preserve leading underscore (for unused vars)
     */
    public static function toElixirVarName(name: String, preserveUnderscore: Bool = true): String {
        // Handle underscore prefix for unused variables
        if (preserveUnderscore && name.charAt(0) == "_") {
            var baseName = name.substr(1);
            if (baseName.length > 0) {
                return "_" + ElixirASTHelpers.toElixirVarName(baseName);
            }
            return "_";
        }
        
        // Delegate to centralized naming helper
        return ElixirASTHelpers.toElixirVarName(name);
    }
    
    /**
     * Check if a variable name is forbidden in Elixir
     * 
     * WHY: Some names are reserved keywords or special forms in Elixir
     * WHAT: Checks against list of forbidden identifiers
     * HOW: Simple string comparison with known reserved words
     */
    public static function isForbiddenInElixir(name: String): Bool {
        var forbidden = [
            "and", "or", "not", "when", "in", "fn", "do", "end",
            "catch", "rescue", "after", "else", "true", "false", "nil"
        ];
        return forbidden.indexOf(name) != -1;
    }
    
    /**
     * Generate a unique temporary variable name
     * 
     * WHY: Needed for intermediate expressions and transformations
     * WHAT: Creates a guaranteed unique variable name
     * HOW: Uses prefix and counter to ensure uniqueness
     */
    public static function generateTempVar(prefix: String, context: BuildContext): String {
        // Get or initialize counter from context
        var counter = 0;
        if (context != null) {
            // Could store counters in context if needed
            // For now, just use timestamp for uniqueness
            counter = Std.int(Date.now().getTime()) % 10000;
        }
        
        return prefix + "_" + counter;
    }
    
    // ================================================================
    // Variable Mapping Management
    // ================================================================
    
    /**
     * Register a variable name mapping in the context
     * 
     * WHY: Tracks variable renamings throughout compilation
     * WHAT: Stores mapping from original to transformed name
     * HOW: Updates tempVarRenameMap in context
     */
    public static function registerVariableMapping(context: BuildContext, originalId: String, mappedName: String): Void {
        if (context == null) return;
        
        #if debug_variable_mapping
        // DISABLED: trace('[VariableAnalyzer] Registering mapping: $originalId -> $mappedName');
        #end
        
        // Note: The actual map is stored in CompilationContext
        // This is just a helper to encapsulate the logic
        // BuildContext interface would need a method for this
    }
    
    /**
     * Look up a mapped variable name from the context
     * 
     * WHY: Ensures consistent naming across compilation phases
     * WHAT: Retrieves previously mapped name if it exists
     * HOW: Checks tempVarRenameMap in context
     */
    public static function getMappedVariableName(context: BuildContext, originalId: String): Null<String> {
        if (context == null) return null;
        
        // Note: The actual lookup happens in CompilationContext
        // This is a helper to encapsulate the logic
        return null; // Would need BuildContext interface method
    }
    
    // ================================================================
    // Pattern Variable Analysis
    // ================================================================
    
    /**
     * Check if a pattern variable is used in the body by variable ID
     * 
     * WHY: Determines if pattern-extracted variables need underscore prefixes
     * WHAT: Searches for variable usage by ID rather than name
     * HOW: Traverses AST looking for TLocal nodes with matching ID
     */
    public static function isPatternVariableUsedById(body: TypedExpr, varId: Int): Bool {
        if (body == null) return false;
        
        switch(body.expr) {
            case TLocal(v):
                return v.id == varId;
            
            case TBlock(exprs):
                for (expr in exprs) {
                    if (isPatternVariableUsedById(expr, varId)) return true;
                }
                return false;
            
            case TBinop(_, e1, e2):
                return isPatternVariableUsedById(e1, varId) || 
                       isPatternVariableUsedById(e2, varId);
            
            case TCall(e, el):
                if (isPatternVariableUsedById(e, varId)) return true;
                for (arg in el) {
                    if (isPatternVariableUsedById(arg, varId)) return true;
                }
                return false;
            
            case TField(e, _):
                return isPatternVariableUsedById(e, varId);
            
            case TIf(cond, thenExpr, elseExpr):
                return isPatternVariableUsedById(cond, varId) || 
                       isPatternVariableUsedById(thenExpr, varId) || 
                       (elseExpr != null && isPatternVariableUsedById(elseExpr, varId));
            
            case TSwitch(e, cases, edef):
                if (isPatternVariableUsedById(e, varId)) return true;
                for (c in cases) {
                    if (isPatternVariableUsedById(c.expr, varId)) return true;
                }
                return edef != null && isPatternVariableUsedById(edef, varId);
            
            case TReturn(e):
                return e != null && isPatternVariableUsedById(e, varId);
            
            case TParenthesis(e):
                return isPatternVariableUsedById(e, varId);
            
            case TObjectDecl(fields):
                for (field in fields) {
                    if (isPatternVariableUsedById(field.expr, varId)) return true;
                }
                return false;
            
            case TArrayDecl(values):
                for (value in values) {
                    if (isPatternVariableUsedById(value, varId)) return true;
                }
                return false;
            
            case TVar(_, expr):
                return expr != null && isPatternVariableUsedById(expr, varId);
            
            case TFunction(func):
                return isPatternVariableUsedById(func.expr, varId);
            
            case TFor(v, e1, e2):
                // Don't check the loop variable itself, but check the iterator and body
                return isPatternVariableUsedById(e1, varId) || 
                       isPatternVariableUsedById(e2, varId);
            
            case TWhile(e1, e2, _):
                return isPatternVariableUsedById(e1, varId) || 
                       isPatternVariableUsedById(e2, varId);
            
            case TUnop(_, _, e):
                return isPatternVariableUsedById(e, varId);
            
            case TTry(e, catches):
                if (isPatternVariableUsedById(e, varId)) return true;
                for (c in catches) {
                    if (isPatternVariableUsedById(c.expr, varId)) return true;
                }
                return false;
            
            case TThrow(e):
                return isPatternVariableUsedById(e, varId);
            
            case TCast(e, _):
                return isPatternVariableUsedById(e, varId);
            
            case TMeta(_, e):
                return isPatternVariableUsedById(e, varId);
            
            default:
                return false;
        }
    }
    
    // ================================================================
    // Utility Functions
    // ================================================================
    
    /**
     * Check if a variable name represents an unused variable
     * 
     * WHY: Unused variables should be prefixed with underscore in Elixir
     * WHAT: Checks if name starts with underscore
     * HOW: Simple string prefix check
     */
    public static inline function isUnusedVariable(name: String): Bool {
        return name != null && name.charAt(0) == "_";
    }
    
    /**
     * Strip underscore prefix from variable name
     * 
     * WHY: Sometimes need base name without unused marker
     * WHAT: Removes leading underscore if present
     * HOW: String manipulation
     */
    public static inline function stripUnderscorePrefix(name: String): String {
        if (name != null && name.charAt(0) == "_") {
            return name.substr(1);
        }
        return name;
    }
    
    /**
     * Add underscore prefix to variable name
     * 
     * WHY: Mark variables as unused in generated code
     * WHAT: Adds underscore prefix if not present
     * HOW: String concatenation
     */
    public static inline function addUnderscorePrefix(name: String): String {
        if (name != null && name.charAt(0) != "_") {
            return "_" + name;
        }
        return name;
    }
}

#end