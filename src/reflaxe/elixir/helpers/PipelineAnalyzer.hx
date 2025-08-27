#if (macro || elixir_runtime)

package reflaxe.elixir.helpers;

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;
import reflaxe.elixir.helpers.PipelineOptimizer.PipelinePattern;
using StringTools;

/**
 * PipelineAnalyzer: Centralized pipeline pattern detection and variable analysis
 * 
 * WHY: Pipeline analysis logic was scattered throughout ElixirCompiler creating maintenance complexity.
 *      Centralized analysis improves code organization and enables systematic pipeline detection.
 *      Separation of concerns: analysis (what patterns exist) vs optimization (how to compile them).
 * WHAT: Provides comprehensive pipeline pattern analysis including variable reference tracking,
 *       statement grouping, terminal operation detection, and function name extraction.
 * HOW: Implements focused analysis methods that examine TypedExpr structure and metadata
 *      to identify pipeline opportunities and boundaries for optimization compilation.
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused entirely on pipeline pattern detection and analysis
 * - Open/Closed Principle: Easy to add new pipeline patterns without modifying existing logic
 * - Testability: Pipeline analysis logic can be tested independently from compilation
 * - Maintainability: Clear separation between analysis and code generation concerns
 * - Performance: Optimized pattern detection with systematic AST traversal
 * 
 * EDGE CASES:
 * - Complex nested variable references in deeply nested expressions
 * - Pipeline patterns mixed with non-pipeline operations
 * - Terminal operations with multiple arguments and complex parameter patterns
 * - Function name extraction from dynamic calls and complex field access
 * - Variable shadowing and scope resolution in pipeline detection
 * 
 * @see docs/03-compiler-development/PIPELINE_ANALYSIS.md - Complete pipeline detection guide
 */
@:nullSafety(Off)
class PipelineAnalyzer {
    var compiler: ElixirCompiler;

    public function new(compiler: ElixirCompiler) {
        this.compiler = compiler;
    }

    /**
     * Check if an expression contains a reference to a specific variable
     * 
     * WHY: Pipeline detection needs to track variable usage across expressions
     * WHAT: Recursively traverses AST to find variable references by name
     * HOW: Pattern matches on TypedExpr variants to examine all sub-expressions
     * 
     * @param expr The expression to analyze
     * @param variableName The variable name to search for
     * @return True if the expression contains the variable reference
     */
    public function containsVariableReference(expr: TypedExpr, variableName: String): Bool {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Checking variable reference: ${variableName} in ${expr.expr}');
        #end
        
        var result = switch(expr.expr) {
            case TLocal(v): v.name == variableName;
            case TField(e, fa): containsVariableReference(e, variableName);
            case TCall(e, el): 
                containsVariableReference(e, variableName) || 
                Lambda.exists(el, arg -> containsVariableReference(arg, variableName));
            case TBinop(op, e1, e2): 
                containsVariableReference(e1, variableName) || 
                containsVariableReference(e2, variableName);
            case TUnop(op, postFix, e): 
                containsVariableReference(e, variableName);
            case TArrayDecl(el): 
                Lambda.exists(el, e -> containsVariableReference(e, variableName));
            case TObjectDecl(fields): 
                Lambda.exists(fields, field -> containsVariableReference(field.expr, variableName));
            case TIf(econd, eif, eelse): 
                containsVariableReference(econd, variableName) || 
                containsVariableReference(eif, variableName) || 
                (eelse != null && containsVariableReference(eelse, variableName));
            case TReturn(e): 
                e != null && containsVariableReference(e, variableName);
            case TBlock(el): 
                Lambda.exists(el, e -> containsVariableReference(e, variableName));
            case TVar(v, e): 
                e != null && containsVariableReference(e, variableName);
            case TMeta(m, e): 
                containsVariableReference(e, variableName);
            case TParenthesis(e): 
                containsVariableReference(e, variableName);
            case TCast(e, m): 
                containsVariableReference(e, variableName);
            default: false;
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Variable reference result: ${result}');
        #end
        
        return result;
    }

    /**
     * Determine which statement indices were processed as part of a pipeline pattern
     * 
     * WHY: Pipeline compilation needs to avoid double-processing statements
     * WHAT: Identifies all statements that operate on the pipeline variable
     * HOW: Iterates through statements and checks for variable targeting
     * 
     * @param statements The statements to analyze
     * @param pattern The pipeline pattern containing the target variable
     * @return Array of indices for statements that are part of the pipeline
     */
    public function getProcessedStatementIndices(statements: Array<TypedExpr>, pattern: PipelinePattern): Array<Int> {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Getting processed statement indices for variable: ${pattern.variable}');
        #end
        
        var processedIndices = [];
        var targetVariable = pattern.variable;
        
        // Find all statements that operate on the pipeline variable
        for (i in 0...statements.length) {
            var stmt = statements[i];
            if (statementTargetsVariable(stmt, targetVariable)) {
                processedIndices.push(i);
            }
        }
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Found ${processedIndices.length} processed statements');
        #end
        
        return processedIndices;
    }

    /**
     * Check if a statement targets a specific variable for pipeline operations
     * 
     * WHY: Pipeline detection needs to identify statements that operate on pipeline variables
     * WHAT: Analyzes assignment and variable declaration patterns for pipeline operations
     * HOW: Pattern matches on assignment and declaration forms with variable reference checks
     * 
     * @param stmt The statement to analyze
     * @param variableName The variable name to check for targeting
     * @return True if the statement targets the variable
     */
    public function statementTargetsVariable(stmt: TypedExpr, variableName: String): Bool {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Checking if statement targets variable: ${variableName}');
        #end
        
        // Skip terminal operations - they consume the variable but aren't part of the pipeline
        if (isTerminalOperation(stmt, variableName)) {
            #if debug_pipeline_analysis
//             trace('[PipelineAnalyzer] Statement is terminal operation, skipping');
            #end
            return false;
        }
        
        var result = switch(stmt.expr) {
            case TVar(v, init) if (init != null):
                // var x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the init expression uses the same variable
                    containsVariableReference(init, variableName);
                } else {
                    false;
                }
                
            case TBinop(OpAssign, {expr: TLocal(v)}, right):
                // x = f(x, ...) pattern
                var varName = v.name;
                if (varName == variableName) {
                    // Check if the right side uses the same variable
                    containsVariableReference(right, variableName);
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Statement targets variable result: ${result}');
        #end
        
        return result;
    }

    /**
     * Check if a statement represents a terminal operation that ends a pipeline
     * 
     * WHY: Terminal operations (like Repo.all) consume variables but don't continue pipelines
     * WHAT: Identifies operations that should end pipeline chains
     * HOW: Checks for known terminal function patterns and variable usage
     * 
     * @param stmt The statement to analyze
     * @param variableName The variable name to check for terminal usage
     * @return True if the statement is a terminal operation on the variable
     */
    public function isTerminalOperation(stmt: TypedExpr, variableName: String): Bool {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Checking if terminal operation on variable: ${variableName}');
        #end
        
        var result = switch(stmt.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        containsVariableReference(args[0], variableName);
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Terminal operation result: ${result}');
        #end
        
        return result;
    }

    /**
     * Check if an expression represents a terminal operation on a specific variable
     * 
     * WHY: Alternative terminal operation check for expression-level analysis
     * WHAT: Similar to isTerminalOperation but works on expressions instead of statements
     * HOW: Duplicates terminal operation logic for expression context
     * 
     * @param expr The expression to analyze
     * @param variableName The variable name to check for terminal usage
     * @return True if the expression is a terminal operation on the variable
     */
    public function isTerminalOperationOnVariable(expr: TypedExpr, variableName: String): Bool {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Checking if expression is terminal operation on variable: ${variableName}');
        #end
        
        var result = switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0) {
                        containsVariableReference(args[0], variableName);
                    } else {
                        false;
                    }
                } else {
                    false;
                }
                
            default:
                false;
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Expression terminal operation result: ${result}');
        #end
        
        return result;
    }

    /**
     * Extract terminal function call from expression, removing pipeline variable reference
     * 
     * WHY: Terminal calls need to be converted from Repo.all(query) to pipeline form
     * WHAT: Extracts function name and non-variable arguments for pipeline compilation
     * HOW: Identifies terminal functions and reconstructs calls without pipeline variable
     * 
     * @param expr The expression to analyze
     * @param variableName The pipeline variable to remove from the call
     * @return Terminal function call string or null if not terminal
     */
    public function extractTerminalCall(expr: TypedExpr, variableName: String): Null<String> {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Extracting terminal call for variable: ${variableName}');
        #end
        
        var result = switch(expr.expr) {
            case TCall(funcExpr, args):
                // Check for Repo operations or other terminal functions
                var funcName = extractFunctionNameFromCall(funcExpr);
                var terminalFunctions = ["Repo.all", "Repo.one", "Repo.get", "Repo.insert", "Repo.update", "Repo.delete"];
                
                if (terminalFunctions.indexOf(funcName) >= 0) {
                    // Check if first argument references our variable
                    if (args.length > 0 && containsVariableReference(args[0], variableName)) {
                        // Extract remaining arguments (if any) after the pipeline variable
                        var remainingArgs = [];
                        for (i in 1...args.length) {
                            remainingArgs.push(compiler.compileExpression(args[i]));
                        }
                        
                        // Generate the terminal function call
                        if (remainingArgs.length > 0) {
                            funcName + "(" + remainingArgs.join(", ") + ")";
                        } else {
                            funcName + "()";
                        }
                    } else {
                        null;
                    }
                } else {
                    null;
                }
                
            default:
                null;
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Terminal call extraction result: ${result}');
        #end
        
        return result;
    }

    /**
     * Extract function name from various call expression patterns
     * 
     * WHY: Function calls can have multiple forms that need consistent name extraction
     * WHAT: Handles Module.function, Type.function, and simple function call patterns
     * HOW: Pattern matches on different call forms and extracts names appropriately
     * 
     * @param funcExpr The function expression to analyze
     * @return Function name string for the call
     */
    public function extractFunctionNameFromCall(funcExpr: TypedExpr): String {
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Extracting function name from call expression');
        #end
        
        var result = switch(funcExpr.expr) {
            case TField({expr: TLocal({name: moduleName})}, fa):
                // Module.function pattern (e.g., Repo.all)
                var funcName = switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                };
                moduleName + "." + funcName;
                
            case TField({expr: TTypeExpr(moduleType)}, fa):
                // Type.function pattern (for static calls like Repo.all)
                switch(fa) {
                    case FStatic(classRef, cf):
                        var moduleName = switch(classRef.get().name) {
                            case "Repo": "Repo";  // Special case for Repo
                            case name: name;  // Keep original for now
                        };
                        var methodName = cf.get().name;
                        moduleName + "." + methodName;
                    case FInstance(_, _, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                }
                
            case TLocal({name: funcName}):
                // Simple function call
                funcName;
                
            case TField(_, fa):
                // Method call without module
                switch(fa) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf) | FClosure(_, cf):
                        cf.get().name;
                    case FDynamic(s):
                        s;
                    case FEnum(_, ef):
                        ef.name;
                }
                
            default:
                "unknown_function";
        };
        
        #if debug_pipeline_analysis
//         trace('[PipelineAnalyzer] Function name extraction result: ${result}');
        #end
        
        return result;
    }
}

#end