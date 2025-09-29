package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.ECaseClause;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.context.ClauseContext;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.NameUtils;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;

using StringTools;

/**
 * SwitchBuilder: Handles switch/case pattern matching transformations
 * 
 * WHY: Separates complex switch logic from ElixirASTBuilder
 * - Reduces ElixirASTBuilder complexity (500+ lines of switch handling)
 * - Centralizes pattern matching transformations
 * - Manages infrastructure variable tracking for desugared switches
 * - Handles enum destructuring and pattern extraction
 * 
 * WHAT: Builds ElixirAST case expressions from Haxe switch statements
 * - TSwitch expressions with enum patterns
 * - Infrastructure variable management (_g, g, g1, etc.)
 * - Pattern extraction and variable binding
 * - Default case handling
 * - Nested switch support with ClauseContext
 * 
 * HOW: Pattern-based switch compilation with context tracking
 * - Detects desugared switch patterns from Haxe
 * - Creates ClauseContext for variable scoping
 * - Generates idiomatic case expressions
 * - Handles enum parameter extraction
 * - Manages pattern variable naming
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on switch/case
 * - Open/Closed Principle: Can extend pattern matching without modifying core
 * - Testability: Switch logic can be tested independently
 * - Maintainability: Clear boundaries for pattern matching code
 * - Performance: Optimized pattern detection and transformation
 * 
 * EDGE CASES:
 * - Direct field switches (rare, should be desugared)
 * - Infrastructure variable switches (_g from desugaring)
 * - Nested switch expressions
 * - Empty case bodies
 * - Complex enum patterns with multiple parameters
 */
@:nullSafety(Off)
class SwitchBuilder {
    
    /**
     * Build switch/case expression
     * 
     * WHY: Switch statements are central to pattern matching in functional languages
     * WHAT: Converts TSwitch to Elixir case expression
     * HOW: Analyzes patterns, creates clause context, generates case clauses
     * 
     * @param e The expression being switched on
     * @param cases Array of switch cases
     * @param edef Default case expression
     * @param context Build context with compilation state
     * @return ElixirASTDef for the case expression
     */
    public static function build(e: TypedExpr, cases: Array<{values:Array<TypedExpr>, expr:TypedExpr}>, edef: Null<TypedExpr>, context: CompilationContext): Null<ElixirASTDef> {
        // Always trace to debug the issue
        trace('[SwitchBuilder] Building switch expression');
        trace('[SwitchBuilder]   Target expression type: ${Type.enumConstructor(e.expr)}');
        trace('[SwitchBuilder]   Switch has ${cases.length} cases');
        trace('[SwitchBuilder]   Has default: ${edef != null}');
        
        // Track switch target for infrastructure variable management
        var targetVarName = extractTargetVarName(e);
        if (targetVarName != null && isInfrastructureVar(targetVarName)) {
            trace('[SwitchBuilder] Switch target is infrastructure variable: $targetVarName');
        }
        
        // Build the switch target expression
        var targetAST = if (context.compiler != null) {
            trace('[SwitchBuilder] Compiler is available, compiling target expression');
            var result = context.compiler.compileExpressionImpl(e, false);
            trace('[SwitchBuilder] Target AST compiled: ${result != null}');
            result;
        } else {
            trace('[SwitchBuilder] ERROR: context.compiler is null, cannot proceed');
            return null;  // Can't proceed without compiler
        }
        
        if (targetAST == null) {
            #if debug_ast_builder
            trace('[SwitchBuilder] Failed to build switch target expression');
            #end
            return null;
        }
        
        // Create clause context for pattern variable scoping
        var clauseContext = new ClauseContext();
        
        // Store the old context and set new one
        var oldClauseContext = context.currentClauseContext;
        context.currentClauseContext = clauseContext;
        
        // Build case clauses
        var caseClauses: Array<ECaseClause> = [];
        
        for (i in 0...cases.length) {
            var switchCase = cases[i];
            trace('[SwitchBuilder] Building case ${i + 1}/${cases.length}');
            var clause = buildCaseClause(switchCase, targetVarName, context);
            if (clause != null) {
                trace('[SwitchBuilder]   Case clause built successfully');
                caseClauses.push(clause);
            } else {
                trace('[SwitchBuilder]   Case clause build returned null!');
            }
        }
        
        // Add default case if present
        if (edef != null) {
            var defaultBody = if (context.compiler != null) {
                context.compiler.compileExpressionImpl(edef, false);
            } else {
                null;
            }
            
            if (defaultBody != null) {
                caseClauses.push({
                    pattern: PWildcard,  // _ pattern matches anything
                    guard: null,
                    body: defaultBody
                });
            }
        }
        
        // Restore previous clause context
        context.currentClauseContext = oldClauseContext;
        
        // Generate case expression
        if (caseClauses.length == 0) {
            #if debug_ast_builder
            trace('[SwitchBuilder] No case clauses generated');
            #end
            return null;
        }
        
        return ECase(targetAST, caseClauses);
    }
    
    /**
     * Build a single case clause
     * 
     * WHY: Each switch case needs proper pattern extraction and body compilation
     * WHAT: Creates ECaseClause with pattern and body
     * HOW: Analyzes case values, extracts patterns, compiles body
     */
    static function buildCaseClause(switchCase: {values:Array<TypedExpr>, expr:TypedExpr}, targetVarName: String, context: CompilationContext): Null<ECaseClause> {
        // Handle multiple values in one case (fall-through pattern)
        if (switchCase.values.length == 0) {
            return null;
        }
        
        // For now, handle single value cases (most common)
        // TODO: Handle multiple values with pattern alternatives
        var value = switchCase.values[0];
        
        // Build pattern from case value
        var pattern = buildPattern(value, targetVarName, context);
        if (pattern == null) {
            return null;
        }
        
        // Build case body
        var body: ElixirAST = if (switchCase.expr != null && context.compiler != null) {
            var result = context.compiler.compileExpressionImpl(switchCase.expr, false);
            if (result != null) {
                result;  // Already an ElixirAST
            } else {
                // Compilation failed - use nil
                makeAST(ENil);
            }
        } else {
            // Empty case body - use nil
            makeAST(ENil);
        }
        
        return {
            pattern: pattern,
            guard: null,  // TODO: Add guard support if needed
            body: body
        };
    }
    
    /**
     * Build pattern from case value expression
     * 
     * WHY: Patterns need to match Elixir's pattern matching semantics
     * WHAT: Converts Haxe case values to Elixir patterns
     * HOW: Analyzes value type, generates appropriate pattern
     */
    static function buildPattern(value: TypedExpr, targetVarName: String, context: CompilationContext): Null<EPattern> {
        trace('[SwitchBuilder] Building pattern for: ${Type.enumConstructor(value.expr)}');
        switch(value.expr) {
            case TConst(c):
                // Constant patterns
                trace('[SwitchBuilder]   Found constant pattern');
                switch(c) {
                    case TInt(i): 
                        trace('[SwitchBuilder]     Integer constant: $i');
                        return PLiteral(makeAST(EInteger(i)));
                    case TFloat(f): return PLiteral(makeAST(EFloat(Std.parseFloat(Std.string(f)))));
                    case TString(s): return PLiteral(makeAST(EString(s)));
                    case TBool(true): return PLiteral(makeAST(EAtom("true")));
                    case TBool(false): return PLiteral(makeAST(EAtom("false")));
                    case TNull: return PLiteral(makeAST(ENil));
                    default: return null;
                }
                
            case TCall(e, args):
                // Enum constructor patterns
                trace('[SwitchBuilder]   Found TCall, checking if enum constructor');
                if (isEnumConstructor(e)) {
                    trace('[SwitchBuilder]     Confirmed enum constructor, building enum pattern');
                    return buildEnumPattern(e, args, context);
                }
                trace('[SwitchBuilder]     Not an enum constructor');
                return null;
                
            case TLocal(v):
                // Variable pattern (binds the value)
                var varName = VariableAnalyzer.toElixirVarName(v.name);
                return PVar(varName);
                
            default:
                #if debug_ast_builder
                trace('[SwitchBuilder] Unhandled pattern type: ${Type.enumConstructor(value.expr)}');
                #end
                return null;
        }
    }
    
    /**
     * Build enum constructor pattern
     * 
     * WHY: Enum patterns need special handling for parameter extraction
     * WHAT: Creates tuple patterns for enum constructors
     * HOW: Generates {:constructor, param1, param2, ...} patterns
     */
    static function buildEnumPattern(constructorExpr: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): Null<EPattern> {
        // Extract constructor name
        var constructorName = switch(constructorExpr.expr) {
            case TField(_, FEnum(_, ef)): ef.name;
            default: return null;
        };
        
        // Convert to snake_case atom
        var atomName = NameUtils.toSnakeCase(constructorName);
        
        // Build parameter patterns - first element is the atom
        var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];
        
        for (arg in args) {
            // For now, create variable patterns for parameters
            // TODO: Handle complex nested patterns
            switch(arg.expr) {
                case TLocal(v):
                    var varName = VariableAnalyzer.toElixirVarName(v.name);
                    patterns.push(PVar(varName));
                default:
                    // Use underscore for non-variable patterns
                    patterns.push(PWildcard);
            }
        }
        
        // Return tuple pattern for enum constructor
        return PTuple(patterns);
    }
    
    /**
     * Extract target variable name from switch expression
     * 
     * WHY: Infrastructure variables need special tracking
     * WHAT: Gets the variable name being switched on
     * HOW: Pattern matches on expression structure
     */
    static function extractTargetVarName(e: TypedExpr): Null<String> {
        return switch(e.expr) {
            case TLocal(v): v.name;
            case TParenthesis({expr: TLocal(v)}): v.name;
            default: null;
        };
    }
    
    /**
     * Check if variable is an infrastructure variable
     * 
     * WHY: Haxe generates _g, g, g1 etc. for desugared expressions
     * WHAT: Identifies compiler-generated temporary variables
     * HOW: Checks naming patterns
     */
    static function isInfrastructureVar(name: String): Bool {
        return name == "g" || name == "_g" || 
               ~/^g\d+$/.match(name) || ~/^_g\d+$/.match(name);
    }
    
    /**
     * Check if expression is an enum constructor
     * 
     * WHY: Enum constructors need special pattern handling
     * WHAT: Identifies enum constructor calls
     * HOW: Checks field access type
     */
    static function isEnumConstructor(e: TypedExpr): Bool {
        return switch(e.expr) {
            case TField(_, FEnum(_, _)): true;
            default: false;
        };
    }
}

#end