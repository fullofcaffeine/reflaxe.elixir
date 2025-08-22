package reflaxe.elixir.helpers;

import haxe.macro.Type;
import haxe.macro.Type.TypedExpr;
import haxe.macro.Type.TVar;
import reflaxe.elixir.helpers.NamingHelper;

using Lambda;

/**
 * PatternDetectionCompiler: AST Pattern Recognition and Analysis
 * 
 * WHY: Centralize pattern detection logic for improved maintainability
 * - Pattern detection was scattered throughout ElixirCompiler causing duplication
 * - Complex AST analysis patterns needed dedicated focus and optimization
 * - Different compilation strategies depend on accurate pattern identification
 * - Extraction enables comprehensive testing of pattern detection algorithms
 * 
 * WHAT: Comprehensive AST pattern detection and analysis utilities
 * - Detects array building patterns for optimization opportunities
 * - Identifies Reflect.fields iteration patterns requiring special handling
 * - Recognizes temp variable patterns for code generation optimization
 * - Provides structural analysis for various compilation optimization decisions
 * 
 * HOW: Sophisticated AST traversal and pattern matching algorithms
 * - Uses recursive descent parsing to analyze TypedExpr structures
 * - Employs heuristic analysis to identify common code patterns
 * - Provides decision logic for compilation strategy selection
 * - Integrates pattern confidence scoring for optimization decisions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused exclusively on pattern detection
 * - Open/Closed Principle: Extensible for new pattern types without modification
 * - Testability: Isolated pattern logic enables comprehensive unit testing
 * - Maintainability: Clear separation of concerns from compilation logic
 * - Performance: Optimized pattern detection algorithms
 * 
 * EDGE CASES:
 * - Complex nested patterns that may have multiple interpretations
 * - Performance considerations for deep AST traversal
 * - False positive/negative pattern detection scenarios
 * - Integration with multiple compilation strategies based on pattern results
 * 
 * @see documentation/PATTERN_DETECTION_ALGORITHMS.md - Pattern detection reference
 */
@:nullSafety(Off)
class PatternDetectionCompiler {
    var compiler: reflaxe.elixir.ElixirCompiler;
    
    public function new(compiler: reflaxe.elixir.ElixirCompiler) {
        this.compiler = compiler;
    }
    
    /**
     * Detect Reflect.fields pattern in expressions for special handling.
     * 
     * WHY: Reflect.fields requires specific compilation patterns in Elixir
     * WHAT: Identifies dynamic field access patterns that need runtime reflection
     * HOW: Analyzes call expressions to detect Reflect.fields static calls
     * 
     * Reflect.fields generates dynamic field enumeration that requires special
     * handling in Elixir compilation, often leading to Y combinator patterns.
     * 
     * @param econd The condition expression to analyze
     * @param ebody The body expression to analyze
     * @return Module name if Reflect.fields pattern detected, null otherwise
     */
    public function detectReflectFieldsPattern(econd: TypedExpr, ebody: TypedExpr): Null<String> {
        // Check condition first
        var condResult = analyzeForReflectFields(econd);
        if (condResult != null) return condResult;
        
        // Then check body
        return analyzeForReflectFields(ebody);
    }
    
    /**
     * Analyze expression for Reflect.fields usage.
     * 
     * WHY: Provide detailed analysis of Reflect.fields usage patterns
     * WHAT: Deep inspection of call expressions for reflection operations
     * HOW: Recursive AST analysis to find static field access patterns
     * 
     * @param expr The expression to analyze
     * @return Module name if found, null otherwise
     */
    private function analyzeForReflectFields(expr: TypedExpr): Null<String> {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            case TCall(callExpr, _):
                switch (callExpr.expr) {
                    case TField(obj, fieldAccess):
                        switch (fieldAccess) {
                            case FStatic(classRef, methodRef):
                                var className = classRef.get().name;
                                var methodName = methodRef.get().name;
                                if (className == "Reflect" && methodName == "fields") {
                                    className; // Return the class name
                                } else {
                                    null;
                                }
                            case _: null;
                        }
                    case _: null;
                }
            case TBlock(expressions):
                // Check all expressions in block
                for (e in expressions) {
                    var result = analyzeForReflectFields(e);
                    if (result != null) return result;
                }
                null;
            case TFor(_, iterator, body):
                // Check iterator and body
                var iterResult = analyzeForReflectFields(iterator);
                if (iterResult != null) return iterResult;
                return analyzeForReflectFields(body);
            case _: null;
        }
    }
    
    /**
     * Detect array building patterns for optimization opportunities.
     * 
     * WHY: Array building patterns can be optimized using Elixir's functional approaches
     * WHAT: Identifies patterns where arrays are built incrementally in loops
     * HOW: Analyzes variable assignments and array operations in expression bodies
     * 
     * Array building patterns can often be replaced with more idiomatic Elixir
     * functional programming constructs like Enum.map, Enum.filter, etc.
     * 
     * @param ebody The expression body to analyze
     * @return Pattern info if detected: {indexVar, accumVar, arrayExpr}
     */
    public function detectArrayBuildingPattern(ebody: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        if (ebody == null) return null;
        
        return switch (ebody.expr) {
            case TBlock(expressions):
                // Look for array building pattern in block statements
                analyzeBlockForArrayBuilding(expressions);
            case TBinop(OpAssign, target, value):
                // Single assignment might be array building
                analyzeAssignmentForArrayBuilding(target, value);
            case _: null;
        }
    }
    
    /**
     * Analyze block statements for array building patterns.
     * 
     * WHY: Array building often occurs across multiple statements in a block
     * WHAT: Sequential analysis of statements to identify array construction patterns
     * HOW: Tracks variable assignments and array operations across statements
     * 
     * @param expressions The block expressions to analyze
     * @return Pattern info if detected
     */
    private function analyzeBlockForArrayBuilding(expressions: Array<TypedExpr>): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        var indexVar: Null<String> = null;
        var accumVar: Null<String> = null;
        var arrayExpr: Null<String> = null;
        
        for (expr in expressions) {
            switch (expr.expr) {
                case TBinop(OpAssign, target, value):
                    var result = analyzeAssignmentForArrayBuilding(target, value);
                    if (result != null) return result;
                case TVar(tvar, init):
                    // Variable declaration might be part of pattern
                    if (init != null) {
                        switch (init.expr) {
                            case TArrayDecl(_):
                                // Array initialization
                                accumVar = tvar.name;
                                arrayExpr = compiler.compileExpression(init);
                            case _:
                        }
                    }
                case _:
            }
        }
        
        // Return pattern if we found the components
        if (indexVar != null && accumVar != null && arrayExpr != null) {
            return {indexVar: indexVar, accumVar: accumVar, arrayExpr: arrayExpr};
        }
        return null;
    }
    
    /**
     * Analyze assignment for array building pattern.
     * 
     * WHY: Array building often involves assignment operations
     * WHAT: Detailed analysis of assignment patterns for array construction
     * HOW: Examines target and value expressions for array operation patterns
     * 
     * @param target The assignment target
     * @param value The assignment value
     * @return Pattern info if detected
     */
    private function analyzeAssignmentForArrayBuilding(target: TypedExpr, value: TypedExpr): Null<{indexVar: String, accumVar: String, arrayExpr: String}> {
        // Look for array[index] = value patterns
        switch (target.expr) {
            case TArray(arrayExpr, indexExpr):
                var arrayName = getVariableName(arrayExpr);
                var indexName = getVariableName(indexExpr);
                if (arrayName != null && indexName != null) {
                    return {
                        indexVar: indexName,
                        accumVar: arrayName,
                        arrayExpr: compiler.compileExpression(arrayExpr)
                    };
                }
            case _:
        }
        return null;
    }
    
    /**
     * Extract variable name from expression if it's a simple variable reference.
     * 
     * WHY: Many pattern detection algorithms need variable name extraction
     * WHAT: Safely extracts variable names from TypedExpr structures
     * HOW: Pattern matches on TLocal expressions to get variable names
     * 
     * @param expr The expression to analyze
     * @return Variable name if expression is a simple variable, null otherwise
     */
    private function getVariableName(expr: TypedExpr): Null<String> {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            case TLocal(tvar): tvar.name;
            case _: null;
        }
    }
    
    /**
     * Detect temporary variable patterns that can be optimized.
     * 
     * WHY: Temporary variables often indicate optimization opportunities
     * WHAT: Identifies patterns where temporary variables are used unnecessarily
     * HOW: Analyzes variable usage patterns and lifetime in expressions
     * 
     * Temporary variable patterns can often be inlined or optimized away
     * for more idiomatic Elixir code generation.
     * 
     * @param expressions The expressions to analyze
     * @return Temporary variable name if pattern detected
     */
    public function detectTempVariablePattern(expressions: Array<TypedExpr>): Null<String> {
        if (expressions.length < 2) return null;
        
        // Look for pattern: var temp = value; return/use temp;
        for (i in 0...expressions.length - 1) {
            var currentExpr = expressions[i];
            var nextExpr = expressions[i + 1];
            
            switch (currentExpr.expr) {
                case TVar(tvar, init) if (init != null):
                    // Check if next expression uses this variable
                    if (usesVariable(nextExpr, tvar.name)) {
                        return tvar.name;
                    }
                case _:
            }
        }
        
        return null;
    }
    
    /**
     * Check if expression uses a specific variable.
     * 
     * WHY: Variable usage analysis is needed for optimization decisions
     * WHAT: Determines if a variable is referenced within an expression
     * HOW: Recursive AST traversal looking for variable references
     * 
     * @param expr The expression to check
     * @param varName The variable name to look for
     * @return True if variable is used in expression
     */
    private function usesVariable(expr: TypedExpr, varName: String): Bool {
        if (expr == null) return false;
        
        return switch (expr.expr) {
            case TLocal(tvar): tvar.name == varName;
            case TBlock(expressions):
                expressions.exists(e -> usesVariable(e, varName));
            case TBinop(_, e1, e2):
                usesVariable(e1, varName) || usesVariable(e2, varName);
            case TCall(callExpr, args):
                usesVariable(callExpr, varName) || args.exists(arg -> usesVariable(arg, varName));
            case TIf(cond, ifExpr, elseExpr):
                usesVariable(cond, varName) || usesVariable(ifExpr, varName) || 
                (elseExpr != null && usesVariable(elseExpr, varName));
            case _: false;
        }
    }
    
    /**
     * Detect temporary variable assignment patterns in conditional expressions.
     * 
     * WHY: Conditional assignments often create temporary variables unnecessarily
     * WHAT: Identifies if-else patterns that assign to temporary variables
     * HOW: Analyzes conditional branches for assignment patterns
     * 
     * These patterns can often be optimized into direct conditional expressions
     * without intermediate variable assignments.
     * 
     * @param ifBranch The if branch expression
     * @param elseBranch The else branch expression (may be null)
     * @return Pattern info if detected: {varName}
     */
    public function detectTempVariableAssignmentPattern(ifBranch: TypedExpr, elseBranch: Null<TypedExpr>): Null<{varName: String}> {
        if (ifBranch == null) return null;
        
        // Look for assignment in if branch
        var ifVarName = getAssignmentTarget(ifBranch);
        if (ifVarName == null) return null;
        
        // Check if else branch assigns to same variable
        if (elseBranch != null) {
            var elseVarName = getAssignmentTarget(elseBranch);
            if (elseVarName != null && elseVarName == ifVarName) {
                return {varName: ifVarName};
            }
        }
        
        return null;
    }
    
    /**
     * Get assignment target variable name from expression.
     * 
     * WHY: Assignment pattern detection needs target variable identification
     * WHAT: Extracts variable name from assignment expressions
     * HOW: Pattern matches on assignment operations to get target variable
     * 
     * @param expr The expression to analyze
     * @return Variable name if expression is assignment, null otherwise
     */
    private function getAssignmentTarget(expr: TypedExpr): Null<String> {
        if (expr == null) return null;
        
        return switch (expr.expr) {
            case TBinop(OpAssign, target, _):
                getVariableName(target);
            case TBlock(expressions):
                // Check last expression in block
                if (expressions.length > 0) {
                    getAssignmentTarget(expressions[expressions.length - 1]);
                } else {
                    null;
                }
            case _: null;
        }
    }
}