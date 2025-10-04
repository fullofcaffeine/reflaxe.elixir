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

        // DEBUG: Log ALL switch compilations
        trace('[SwitchBuilder START] Compiling switch at ${e.pos}');
        trace('[SwitchBuilder START] Switch target: ${Type.enumConstructor(e.expr)}');

        // CRITICAL: Detect TEnumIndex optimization and recover enum type
        // This is the KEY to eliminating integer-based switch cases!
        var enumType: Null<EnumType> = null;
        var isEnumIndexSwitch = false;
        var actualSwitchExpr = e;

        // Look inside TParenthesis and TMeta wrappers to find actual expression
        var innerExpr = e;
        switch(e.expr) {
            case TParenthesis(innerE):
                innerExpr = innerE;
                // Check for TMeta inside
                switch(innerExpr.expr) {
                    case TMeta(_, metaE):
                        innerExpr = metaE;
                    default:
                }
            default:
        }

        switch(innerExpr.expr) {
            case TEnumIndex(enumExpr):
                // Haxe optimizer converted enum pattern matching to integer index comparison

                isEnumIndexSwitch = true;
                actualSwitchExpr = enumExpr;  // Switch on actual enum value, not index

                // Extract enum type from the expression
                enumType = getEnumTypeFromExpression(enumExpr);
                if (enumType != null) {
                } else {
                }
            default:

                // ALTERNATIVE: Check if integer case patterns with enum target type
                enumType = getEnumTypeFromExpression(innerExpr);
                if (enumType != null) {
                    isEnumIndexSwitch = true;
                    actualSwitchExpr = innerExpr;
                }
        }

        // Track switch target for infrastructure variable management
        var targetVarName = extractTargetVarName(actualSwitchExpr);

        // DEBUG: Output switch target info
        trace('[SwitchBuilder DEBUG] Switch target expression type: ${Type.enumConstructor(actualSwitchExpr.expr)}');
        if (targetVarName != null) {
            trace('[SwitchBuilder DEBUG] Extracted variable name: ${targetVarName}');
            trace('[SwitchBuilder DEBUG] Is infrastructure var: ${isInfrastructureVar(targetVarName)}');
        }

        if (targetVarName != null && isInfrastructureVar(targetVarName)) {
            trace('[SwitchBuilder DEBUG] Infrastructure variable detected but not handled!');
        }

        // Build the switch target expression (use actual enum, not index)
        var targetAST = if (context.compiler != null) {
            // Apply infrastructure variable substitution before re-compilation
            var substitutedTarget = context.substituteIfNeeded(actualSwitchExpr);
            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
            // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedTarget, context);
            trace('[SwitchBuilder DEBUG] Compiled target AST: ${Type.enumConstructor(result.def)}');
            // DEBUG: Show exact variable name if it's EVar
            switch(result.def) {
                case EVar(name):
                    trace('[SwitchBuilder DEBUG] EVar variable name: "${name}"');
                default:
            }
            result;
        } else {
            return null;  // Can't proceed without compiler
        }

        if (targetAST == null) {
            trace('[SwitchBuilder ERROR] Target AST compilation returned null!');
            return null;
        }

        // Create clause context for pattern variable scoping
        var clauseContext = new ClauseContext();

        // Store enum type for use in pattern building
        if (isEnumIndexSwitch && enumType != null) {
            clauseContext.enumType = enumType;
        }
        
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
                // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve context
                // Using compiler.compileExpressionImpl creates a NEW context, losing ClauseContext registrations
                reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(edef, context);
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
            #if debug_switch_compilation
            trace('[SwitchBuilder] Compiling case body');
            trace('[SwitchBuilder]   Expr type: ${Type.enumConstructor(switchCase.expr.expr)}');
            #end

            // Apply infrastructure variable substitution before re-compilation
            var substitutedBody = context.substituteIfNeeded(switchCase.expr);

            // CRITICAL FIX: Register pattern variables in ClauseContext AFTER substitution
            // This ensures we get the ACTUAL TVar IDs that will be compiled, not pre-substitution IDs
            if (context.currentClauseContext != null) {
                var patternVars = extractPatternVariables(pattern);
                var bodyVars = extractTVarsFromExpr(substitutedBody);  // Extract from SUBSTITUTED body!

                #if debug_switch_compilation
                trace('[SwitchBuilder] Registering pattern variables');
                trace('[SwitchBuilder]   Pattern vars: ${patternVars}');
                trace('[SwitchBuilder]   Body vars count: ${bodyVars.length}');
                #end

                // Match pattern variables with TVar IDs (positional matching)
                var matchCount = patternVars.length < bodyVars.length ? patternVars.length : bodyVars.length;
                for (i in 0...matchCount) {
                    var tvarId = bodyVars[i].id;
                    var patternName = patternVars[i];

                    #if debug_switch_compilation
                    trace('[SwitchBuilder]   Registering: TVar(${tvarId}) -> ${patternName}');
                    #end

                    context.currentClauseContext.localToName.set(tvarId, patternName);
                }
            }

            // CRITICAL FIX: Call ElixirASTBuilder.buildFromTypedExpr directly to preserve ClauseContext
            // Using compiler.compileExpressionImpl creates a NEW context, losing our pattern variable registrations
            var result = reflaxe.elixir.ast.ElixirASTBuilder.buildFromTypedExpr(substitutedBody, context);

            if (result != null) {
                #if debug_switch_compilation
                trace('[SwitchBuilder]   ✓ Success: Generated AST');
                #end
                result;  // Already an ElixirAST
            } else {
                #if debug_switch_compilation
                trace('[SwitchBuilder]   ❌ ERROR: compileExpressionImpl returned NULL!');
                trace('[SwitchBuilder]   Position: ${switchCase.expr.pos}');
                #end

                // CRITICAL: Don't silently accept failure - throw error to expose root cause
                Context.error('Switch case body compilation failed - compileExpressionImpl returned null', switchCase.expr.pos);
            }
        } else {
            // Empty case body - use nil (this is valid)
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
     * WHAT: Converts Haxe case values to Elixir patterns, handling TEnumIndex optimization
     * HOW: Analyzes value type, generates appropriate pattern, maps integers to enum constructors
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

                        // CRITICAL: Check if this is a TEnumIndex case
                        if (context.currentClauseContext != null && context.currentClauseContext.enumType != null) {
                            var enumType = context.currentClauseContext.enumType;
                            trace('[SwitchBuilder]     *** Mapping integer $i to enum constructor ***');

                            var constructor = getEnumConstructorByIndex(enumType, i);
                            if (constructor != null) {
                                trace('[SwitchBuilder]     *** Found constructor: ${constructor.name} ***');
                                return generateIdiomaticEnumPattern(constructor, context);
                            } else {
                                trace('[SwitchBuilder]     WARNING: No constructor found for index $i');
                            }
                        }

                        // Fallback: regular integer pattern
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
     * Generate idiomatic Elixir pattern for enum constructor
     *
     * WHY: Convert recovered enum constructors to idiomatic {:atom, params} patterns
     * WHAT: Creates tuple patterns with actual parameter names
     * HOW: Extracts parameter names from EnumField.type
     */
    static function generateIdiomaticEnumPattern(ef: EnumField, context: CompilationContext): EPattern {
        var atomName = NameUtils.toSnakeCase(ef.name);

        // Extract parameter names from EnumField.type
        var parameterNames: Array<String> = [];
        switch(ef.type) {
            case TFun(args, _):
                for (arg in args) {
                    parameterNames.push(arg.name);
                }
            default:
                // No parameters
        }

        if (parameterNames.length == 0) {
            // Simple atom pattern: :none
            trace('[SwitchBuilder]     Generated pattern: {:${atomName}}');
            return PLiteral(makeAST(EAtom(atomName)));
        } else {
            // Tuple pattern: {:some, value}
            var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

            for (i in 0...parameterNames.length) {
                var paramName = VariableAnalyzer.toElixirVarName(parameterNames[i]);
                trace('[SwitchBuilder]     Parameter $i: ${paramName}');
                patterns.push(PVar(paramName));
            }

            trace('[SwitchBuilder]     Generated pattern: {:${atomName}, ${parameterNames.join(", ")}}');
            return PTuple(patterns);
        }
    }
    
    /**
     * Build enum constructor pattern
     *
     * WHY: Enum patterns need special handling for parameter extraction
     * WHAT: Creates tuple patterns for enum constructors with ACTUAL parameter names
     * HOW: Extracts parameter names from EnumField.type (TFun args) instead of using Haxe's generated "g" variables
     *
     * CRITICAL FIX: This eliminates generated "g" variables by using the actual parameter
     * names defined in the enum constructor (e.g., "value" for Some(value: T))
     */
    static function buildEnumPattern(constructorExpr: TypedExpr, args: Array<TypedExpr>, context: CompilationContext): Null<EPattern> {
        // Extract constructor name and EnumField
        var ef: EnumField = null;
        var constructorName = switch(constructorExpr.expr) {
            case TField(_, FEnum(_, enumField)):
                ef = enumField;
                enumField.name;
            default: return null;
        };

        // Convert to snake_case atom
        var atomName = NameUtils.toSnakeCase(constructorName);

        // CRITICAL: Extract actual parameter names from EnumField.type
        // This is the KEY to eliminating "g" variables!
        var parameterNames: Array<String> = [];
        if (ef != null) {
            switch(ef.type) {
                case TFun(tfunArgs, _):
                    // Extract actual parameter names from function arguments
                    for (arg in tfunArgs) {
                        parameterNames.push(arg.name);
                    }

                    #if debug_ast_builder
                    trace('[SwitchBuilder] Extracted parameter names from ${ef.name}: ${parameterNames}');
                    #end
                default:
                    // No parameters or non-function type
                    #if debug_ast_builder
                    trace('[SwitchBuilder] EnumField ${ef.name} has no function type, no parameters');
                    #end
            }
        }

        // Build parameter patterns - first element is the atom
        var patterns: Array<EPattern> = [PLiteral(makeAST(EAtom(atomName)))];

        // Use actual parameter names from EnumField instead of Haxe's generated names
        for (i in 0...args.length) {
            var arg = args[i];

            // Get the actual parameter name from EnumField if available
            var actualParamName = i < parameterNames.length ? parameterNames[i] : null;

            switch(arg.expr) {
                case TLocal(v):
                    // Use actual parameter name instead of Haxe's generated "g" variable
                    var varName = if (actualParamName != null) {
                        // Convert to Elixir naming convention
                        VariableAnalyzer.toElixirVarName(actualParamName);
                    } else {
                        // Fallback to Haxe's name (for compatibility)
                        VariableAnalyzer.toElixirVarName(v.name);
                    };

                    #if debug_ast_builder
                    trace('[SwitchBuilder] Parameter $i: Haxe=${v.name}, Actual=${actualParamName}, Using=${varName}');
                    #end

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
     * Extract enum type from a typed expression
     *
     * WHY: Need to recover enum type info after Haxe's TEnumIndex optimization
     * WHAT: Extracts EnumType from expression's type annotation
     * HOW: Pattern matches on Type structure
     */
    static function getEnumTypeFromExpression(expr: TypedExpr): Null<EnumType> {
        return switch(expr.t) {
            case TEnum(ref, _):
                ref.get();
            case TAbstract(ref, _):
                // Check if abstract wraps an enum
                var abs = ref.get();
                switch(abs.type) {
                    case TEnum(enumRef, _): enumRef.get();
                    default: null;
                }
            default:
                null;
        };
    }

    /**
     * Get enum constructor by index
     *
     * WHY: Map integer indices back to enum constructors
     * WHAT: Retrieves EnumField for a given index
     * HOW: Uses constructor's index field
     */
    static function getEnumConstructorByIndex(enumType: EnumType, index: Int): Null<EnumField> {
        for (name in enumType.constructs.keys()) {
            var constructor = enumType.constructs.get(name);
            if (constructor.index == index) {
                return constructor;
            }
        }
        return null;
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

    /**
     * Extract variable names from pattern
     *
     * WHY: Pattern variables must be registered in ClauseContext before body compilation
     * WHAT: Recursively extracts all PVar names from a pattern
     * HOW: Traverses pattern structure, collecting variable names in order
     */
    static function extractPatternVariables(pattern: EPattern): Array<String> {
        var vars: Array<String> = [];

        function traverse(p: EPattern): Void {
            switch(p) {
                case PVar(name):
                    vars.push(name);
                case PTuple(elements):
                    for (elem in elements) {
                        traverse(elem);
                    }
                case PList(elements):
                    for (elem in elements) {
                        traverse(elem);
                    }
                case PCons(head, tail):
                    traverse(head);
                    traverse(tail);
                case PMap(pairs):
                    for (pair in pairs) {
                        traverse(pair.value);
                    }
                case PStruct(_, fields):
                    for (field in fields) {
                        traverse(field.value);
                    }
                case PLiteral(_):
                    // Literals don't bind variables
                case PWildcard:
                    // Underscore doesn't bind
                case PPin(inner):
                    // Pin patterns don't bind new variables
                    traverse(inner);
                case PAlias(varName, pattern):
                    // Alias creates a binding for the variable name
                    vars.push(varName);
                    // But also traverse the inner pattern
                    traverse(pattern);
                case PBinary(segments):
                    // Binary patterns can contain variable bindings in segments
                    for (segment in segments) {
                        traverse(segment.pattern);
                    }
            }
        }

        traverse(pattern);
        return vars;
    }

    /**
     * Extract TVar declarations from case body expression
     *
     * WHY: Need to match TVar IDs with pattern variable names for ClauseContext registration
     * WHAT: Finds all TVar nodes in the expression tree
     * HOW: Recursively traverses TypedExpr, collecting TVar nodes
     */
    static function extractTVarsFromExpr(expr: TypedExpr): Array<{id: Int, name: String}> {
        var tvars: Array<{id: Int, name: String}> = [];

        function traverse(e: TypedExpr): Void {
            switch(e.expr) {
                case TVar(tvar, init):
                    tvars.push({id: tvar.id, name: tvar.name});
                    if (init != null) {
                        traverse(init);
                    }
                case TBlock(el):
                    for (expr in el) {
                        traverse(expr);
                    }
                case TBinop(_, e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TCall(e, el):
                    traverse(e);
                    for (arg in el) {
                        traverse(arg);
                    }
                case TField(e, _):
                    traverse(e);
                case TIf(econd, eif, eelse):
                    traverse(econd);
                    traverse(eif);
                    if (eelse != null) {
                        traverse(eelse);
                    }
                case TSwitch(e, cases, edef):
                    traverse(e);
                    for (c in cases) {
                        for (v in c.values) {
                            traverse(v);
                        }
                        traverse(c.expr);
                    }
                    if (edef != null) {
                        traverse(edef);
                    }
                case TWhile(econd, e, _):
                    traverse(econd);
                    traverse(e);
                case TFor(v, it, expr):
                    traverse(it);
                    traverse(expr);
                case TReturn(e):
                    if (e != null) {
                        traverse(e);
                    }
                case TArrayDecl(el):
                    for (e in el) {
                        traverse(e);
                    }
                case TObjectDecl(fields):
                    for (f in fields) {
                        traverse(f.expr);
                    }
                case TParenthesis(e) | TMeta(_, e) | TCast(e, _):
                    traverse(e);
                case TArray(e1, e2):
                    traverse(e1);
                    traverse(e2);
                case TUnop(_, _, e):
                    traverse(e);
                case TNew(_, _, el):
                    for (e in el) {
                        traverse(e);
                    }
                default:
                    // Other expression types don't contain TVars we care about
            }
        }

        traverse(expr);
        return tvars;
    }
}

#end