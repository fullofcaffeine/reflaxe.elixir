package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import reflaxe.elixir.ast.ElixirASTHelpers;
import reflaxe.elixir.helpers.PatternDetector;
import reflaxe.elixir.helpers.UsageDetector;

using StringTools;

/**
 * FunctionBuilder: Handles Lambda and Anonymous Function Compilation
 * 
 * WHY: Functions (lambdas/anonymous functions) need sophisticated handling for:
 * - Parameter naming and unused parameter detection
 * - Fluent API pattern detection
 * - Variable shadowing and renaming
 * - Abstract "this" parameter handling
 * - Function-local variable scope management
 * 
 * WHAT: Builds ElixirAST function nodes (EFn) from Haxe TFunction expressions
 * - Processes function parameters with proper naming conventions
 * - Detects unused parameters and prefixes with underscore
 * - Handles parameter renaming for shadowed variables
 * - Manages function-local variable scope
 * - Detects and annotates fluent API patterns
 * 
 * HOW: Analyzes function structure and generates idiomatic Elixir functions
 * - Extracts parameter information and detects usage
 * - Converts parameter names to snake_case
 * - Applies underscore prefixing for unused parameters
 * - Builds function body with proper variable mappings
 * - Adds metadata for special patterns (fluent API, etc.)
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on function compilation
 * - Reduces ElixirASTBuilder complexity
 * - Centralizes function-specific logic
 * - Testability: Function compilation can be tested independently
 * - Maintainability: Clear boundaries for function handling code
 * 
 * EDGE CASES:
 * - Abstract method "this" parameters (renamed to "this1" by Haxe)
 * - Shadowed parameters with numeric suffixes
 * - Reserved Elixir keywords in parameter names
 * - Empty function bodies
 * - Fluent API patterns returning modified "this"
 */
@:nullSafety(Off)
class FunctionBuilder {
    
    /**
     * Build lambda/anonymous function expression
     * 
     * WHY: Functions are fundamental building blocks that need proper parameter handling
     * WHAT: Converts TFunction to Elixir EFn with proper parameter processing
     * HOW: Analyzes parameters, detects usage, builds body with mappings
     * 
     * @param f The function definition from Haxe
     * @param context Build context with compilation state
     * @return ElixirASTDef for the function or null if cannot build
     */
    public static function build(f: TFunc, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        trace('[FunctionBuilder] Building function with ${f.args.length} parameters');
        #end
        
        // Detect fluent API patterns (for future use when metadata is extended)
        var fluentPattern = PatternDetector.detectFluentAPIPattern(f);
        
        var args = [];
        var paramRenaming = new Map<String, String>();
        
        // Store the old rename map and create new one for function scope
        var oldTempVarRenameMap = context.tempVarRenameMap;
        context.tempVarRenameMap = new Map();
        for (key in oldTempVarRenameMap.keys()) {
            context.tempVarRenameMap.set(key, oldTempVarRenameMap.get(key));
        }
        
        // Process all parameters
        var isFirstParam = true;
        for (arg in f.args) {
            var processedParam = processParameter(arg, f.expr, context, isFirstParam);
            
            // Add to function signature
            args.push(PVar(processedParam.finalName));
            
            // Track parameter mappings
            if (processedParam.originalName != processedParam.finalName) {
                paramRenaming.set(processedParam.originalName, processedParam.finalName);
            }
            
            // Handle abstract "this" parameters
            if (processedParam.originalName == "this1") {
                paramRenaming.set("this", processedParam.finalName);
                // CRITICAL FIX: Set currentReceiverParamName so VariableBuilder can resolve "this" references
                // Pattern reuse from existing infrastructure - VariableBuilder.hx:434 checks this field
                context.currentReceiverParamName = processedParam.finalName;
            }
            
            isFirstParam = false;
        }
        
        // Build function body with context
        var body = if (context.compiler != null) {
            context.compiler.compileExpressionImpl(f.expr, false);
        } else {
            null;
        };
        
        // Restore original rename map and clean up
        context.tempVarRenameMap = oldTempVarRenameMap;
        context.currentReceiverParamName = null; // Clear abstract "this" context after function
        for (arg in f.args) {
            context.functionParameterIds.remove(Std.string(arg.v.id));
        }
        
        // Apply parameter renaming if needed
        if (paramRenaming.keys().hasNext() && body != null) {
            body = applyParameterRenaming(body, paramRenaming);
        }
        
        // Create function AST
        var fnAst = makeAST(EFn([{
            args: args,
            guard: null,
            body: body
        }]));
        
        // Note: Fluent API pattern detection is complete but metadata support needs to be added
        // to ElixirMetadata typedef before we can attach this information to the AST node.
        // For now, the pattern is detected but not used in transformation.
        
        return fnAst.def;
    }
    
    /**
     * Process a single function parameter
     * 
     * WHY: Parameters need proper naming, usage detection, and mapping
     * WHAT: Analyzes parameter and returns processing information
     * HOW: Detects usage, handles renaming, applies conventions
     */
    static function processParameter(arg: {v:TVar, value:Null<TypedExpr>}, 
                                    body: Null<TypedExpr>, 
                                    context: CompilationContext,
                                    isFirstParam: Bool): {originalName:String, finalName:String} {
        var originalName = arg.v.name;
        var idKey = Std.string(arg.v.id);
        
        #if debug_variable_renaming
        trace('[FunctionBuilder] Processing parameter "$originalName" (ID: ${arg.v.id})');
        #end
        
        // Detect unused parameters
        var isActuallyUnused = if (arg.v.meta != null && arg.v.meta.has("-reflaxe.unused")) {
            true;  // Marked by Reflaxe preprocessor
        } else if (body != null) {
            !UsageDetector.isParameterUsed(arg.v, body);
        } else {
            false;
        };
        
        // Check for numeric suffix (parameter shadowing)
        var strippedName = stripNumericSuffix(originalName);
        var hasNumericSuffix = (strippedName != originalName);
        
        // Convert to snake_case
        var baseName = ElixirASTHelpers.toElixirVarName(strippedName);
        
        // Check for reserved keywords
        if (isElixirReservedKeyword(baseName)) {
            baseName = baseName + "_param";
        }
        
        // Prefix with underscore if unused
        var finalName = if (isActuallyUnused && !baseName.startsWith("_")) {
            "_" + baseName;
        } else {
            baseName;
        };
        
        // Register mapping in context with dual-key storage
        if (!context.tempVarRenameMap.exists(idKey)) {
            // Dual-key storage: ID for pattern positions, name for EVar references
            context.tempVarRenameMap.set(idKey, finalName);           // ID-based (pattern matching)
            context.tempVarRenameMap.set(originalName, finalName);    // NAME-based (EVar renaming)

            #if debug_hygiene
            trace('[Hygiene] Dual-key registered: id=$idKey name=$originalName -> $finalName');
            #end
        }
        
        // Register renamed variable if suffix was stripped
        if (hasNumericSuffix && context.astContext != null) {
            context.astContext.registerRenamedVariable(arg.v.id, strippedName, originalName);
        }
        
        // Track first parameter as receiver for instance methods
        if (isFirstParam && context.isInClassMethodContext) {
            context.currentReceiverParamName = finalName;
        }
        
        // Mark as function parameter
        context.functionParameterIds.set(idKey, true);
        
        return {
            originalName: originalName,
            finalName: finalName
        };
    }
    
    /**
     * Strip numeric suffix from shadowed parameter names
     * 
     * WHY: Haxe adds numeric suffixes to handle shadowing
     * WHAT: Removes suffixes like "2" or "3" from common field names
     * HOW: Pattern matches and checks against common field names
     */
    static function stripNumericSuffix(name: String): String {
        var pattern = ~/^(.+?)(\d+)$/;
        if (!pattern.match(name)) {
            return name;
        }
        
        var base = pattern.matched(1);
        var suffix = pattern.matched(2);
        
        // Common field names that get shadowed
        var commonFieldNames = ["options", "columns", "name", "value", 
                               "type", "data", "fields", "items"];
        
        // Only strip if it looks like shadowing
        if ((suffix == "2" || suffix == "3") && commonFieldNames.indexOf(base) >= 0) {
            return base;
        }
        
        return name;
    }
    
    /**
     * Check if name is an Elixir reserved keyword
     * 
     * WHY: Reserved keywords cannot be used as variable names
     * WHAT: Checks against list of Elixir reserved words
     * HOW: Simple string comparison
     */
    static function isElixirReservedKeyword(name: String): Bool {
        var reserved = ["and", "or", "not", "in", "fn", "do", "end", 
                       "catch", "rescue", "after", "else", "when"];
        return reserved.indexOf(name) >= 0;
    }
    
    /**
     * Apply parameter renaming to function body
     * 
     * WHY: Parameter names might change, body needs updating
     * WHAT: Replaces variable references with renamed versions
     * HOW: Traverses AST and updates EVar nodes
     */
    static function applyParameterRenaming(ast: ElixirAST, renaming: Map<String, String>): ElixirAST {
        if (ast == null) return null;
        
        var def = switch(ast.def) {
            case EVar(name):
                if (renaming.exists(name)) {
                    EVar(renaming.get(name));
                } else {
                    ast.def;
                }
                
            case EBlock(exprs):
                EBlock([for (e in exprs) applyParameterRenaming(e, renaming)]);
                
            case EIf(cond, then, els):
                EIf(applyParameterRenaming(cond, renaming),
                    applyParameterRenaming(then, renaming),
                    applyParameterRenaming(els, renaming));
                
            default:
                // For other cases, return as-is
                // A more complete implementation would traverse all node types
                ast.def;
        };
        
        return makeAST(def);
    }
}

#end