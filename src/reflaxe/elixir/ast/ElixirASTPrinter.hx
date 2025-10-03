package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTBuilder;
using StringTools;

/**
 * ElixirASTPrinter: ElixirAST to String Generator (Generation Phase)
 * 
 * WHY: Final phase of the three-phase pipeline, converts AST to code
 * - Pure string generation with no logic or transformation
 * - Maintains Elixir syntax rules and formatting conventions
 * - Separates formatting concerns from compilation logic
 * - Enables consistent output regardless of AST source
 * 
 * WHAT: Converts ElixirAST nodes to properly formatted Elixir code
 * - Handles all AST node types with appropriate syntax
 * - Manages indentation and line breaks for readability
 * - Respects Elixir conventions (snake_case, atoms, etc.)
 * - Produces idiomatic, human-readable Elixir code
 * 
 * HOW: Recursive traversal with string building
 * - Pattern matches on AST node types
 * - Builds strings with proper formatting
 * - Handles operator precedence and parenthesization
 * - Manages indentation state through recursion
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Only handles string generation
 * - Testability: Output can be validated against expected strings
 * - Maintainability: Formatting changes isolated from logic
 * - Flexibility: Can easily adjust output style without touching compiler
 * 
 * @see docs/03-compiler-development/INTERMEDIATE_AST_REFACTORING_PRD.md
 */
class ElixirASTPrinter {

    // Counter for generating unique loop function names
    static var loopIdCounter: Int = 0;

    // Track current module's unused functions for dead code elimination
    static var currentUnusedFunctions: Null<Array<String>> = null;
    
    /**
     * Public API for printing a single AST (used by ElixirASTBuilder for injection)
     *
     * WHY: ElixirASTBuilder needs to convert AST nodes to strings for __elixir__ parameter substitution
     * WHAT: Converts a single ElixirAST node to string without indentation
     * HOW: Calls main print function with zero indentation
     */
    public static function printAST(ast: ElixirAST, ?context: reflaxe.elixir.CompilationContext): String {
        // Context will be used in future for context-aware printing
        return print(ast, 0);
    }
    
    /**
     * Main entry point: Convert ElixirAST to formatted string
     *
     * WHY: Single public interface for all printing needs
     * WHAT: Recursively converts AST tree to formatted Elixir code
     * HOW: Delegates to specific handlers based on node type
     */
    public static function print(ast: ElixirAST, indent: Int = 0): String {
        // Handle null nodes
        if (ast == null) {
            return "";
        }

        #if debug_ast_printer
        trace('[XRay AST Printer] Printing node: ${ast.def}');
        #end

        // Handle EDefmodule and EModule specially to access metadata
        var result = switch(ast.def) {
            case EDefmodule(name, doBlock):
                // Extract unused functions from metadata if available
                if (ast.metadata != null && ast.metadata.unusedPrivateFunctions != null) {
                    currentUnusedFunctions = ast.metadata.unusedPrivateFunctions;
                }

                var moduleContent = '';

                // Add @compile directive for unused functions if any exist
                if (ast.metadata != null && ast.metadata.unusedPrivateFunctionsWithArity != null &&
                    ast.metadata.unusedPrivateFunctionsWithArity.length > 0) {
                    var unusedFuncList = [];
                    for (func in ast.metadata.unusedPrivateFunctionsWithArity) {
                        unusedFuncList.push('{:_${func.name}, ${func.arity}}');
                    }
                    if (unusedFuncList.length > 0) {
                        moduleContent += indentStr(indent + 1) + '@compile [{:nowarn_unused_function, [' + unusedFuncList.join(', ') + ']}]\n\n';
                    }
                }

                moduleContent += indentStr(indent + 1) + print(doBlock, indent + 1);

                var moduleResult = 'defmodule ${name} do\n' +
                    moduleContent + '\n' +
                    indentStr(indent) + 'end';

                // Clear unused functions after module is printed
                currentUnusedFunctions = null;
                moduleResult;

            case EModule(name, attributes, body):
                // Check if this is an exception class
                var isException = ast.metadata != null && ast.metadata.isException == true;
                
                if (isException) {
                    // For exceptions, use defmodule with defexception inside
                    // This is the proper Elixir pattern for custom exceptions
                    var result = 'defmodule ${name} do\n';
                    result += indentStr(indent + 1) + 'defexception [:message]\n';
                    
                    // Print any other methods (like toString)
                    for (expr in body) {
                        // Skip defstruct calls as defexception handles that
                        var exprStr = print(expr, indent + 1);
                        if (!exprStr.startsWith("defstruct")) {
                            result += '\n' + indentStr(indent + 1) + exprStr + '\n';
                        }
                    }
                    
                    result += indentStr(indent) + 'end';
                    result;
                } else {
                    // Regular module
                    var result = 'defmodule ${name} do\n';
                    
                    // Print attributes
                    for (attr in attributes) {
                        result += indentStr(indent + 1) + printAttribute(attr) + '\n';
                    }
                    
                    if (attributes.length > 0 && body.length > 0) {
                        result += '\n';
                    }
                    
                    // Print body
                    for (expr in body) {
                        result += indentStr(indent + 1) + print(expr, indent + 1) + '\n';
                    }
                    
                    result += indentStr(indent) + 'end';
                    result;
                }

            default:
                printNode(ast.def, indent);
        };

        #if debug_ast_printer
        trace('[XRay AST Printer] Generated: ${result.substring(0, 100)}...');
        #end

        return result;
    }
    
    /**
     * Print a single AST node
     */
    static function printNode(node: ElixirASTDef, indent: Int): String {
        return switch(node) {
            // ================================================================
            // Modules and Structure
            // ================================================================
            case EModule(name, attributes, body):
                // Check if this is an exception class from metadata
                // Note: We need access to the full AST node to check metadata
                // This is handled in the main print() function, not here
                // For now, generate regular defmodule
                var result = 'defmodule ${name} do\n';
                
                // Print attributes
                for (attr in attributes) {
                    result += indentStr(indent + 1) + printAttribute(attr) + '\n';
                }
                
                if (attributes.length > 0 && body.length > 0) {
                    result += '\n';
                }
                
                // Print body
                for (expr in body) {
                    result += indentStr(indent + 1) + print(expr, indent + 1) + '\n';
                }
                
                result += indentStr(indent) + 'end';
                result;
                
            case EDefmodule(name, doBlock):
                // This case is handled in the main print function to access metadata
                // Should not reach here, but provide fallback
                'defmodule ${name} do\n' +
                indentStr(indent + 1) + print(doBlock, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            // ================================================================
            // Functions
            // ================================================================
            case EDef(name, args, guards, body):
                var argStr = printPatterns(args);
                var guardStr = guards != null ? ' when ' + print(guards, 0) : '';
                'def ${name}(${argStr})${guardStr} do\n' +
                indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            case EDefp(name, args, guards, body):
                // M0 STABILIZATION: Disable underscore prefixing temporarily
                var funcName = name;
                /* Disabled to prevent variable mismatches
                if (currentUnusedFunctions != null && currentUnusedFunctions.indexOf(name) != -1) {
                    // Don't double-prefix if already starts with underscore
                    if (!name.startsWith("_")) {
                        funcName = "_" + name;
                    }
                }
                */

                var argStr = printPatterns(args);
                var guardStr = guards != null ? ' when ' + print(guards, 0) : '';
                'defp ${funcName}(${argStr})${guardStr} do\n' +
                indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            case EDefmacro(name, args, guards, body):
                var argStr = printPatterns(args);
                var guardStr = guards != null ? ' when ' + print(guards, 0) : '';
                'defmacro ${name}(${argStr})${guardStr} do\n' +
                indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            case EDefmacrop(name, args, guards, body):
                var argStr = printPatterns(args);
                var guardStr = guards != null ? ' when ' + print(guards, 0) : '';
                'defmacrop ${name}(${argStr})${guardStr} do\n' +
                indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            // ================================================================
            // Pattern Matching
            // ================================================================
            case ECase(expr, clauses):
                'case ' + print(expr, 0) + ' do\n' +
                [for (clause in clauses) 
                    indentStr(indent + 1) + printCaseClause(clause, indent + 1)
                ].join('\n') + '\n' +
                indentStr(indent) + 'end';
                
            case ECond(clauses):
                var clauseStrs = [];
                for (clause in clauses) {
                    var conditionStr = print(clause.condition, 0);
                    var bodyStr = print(clause.body, indent + 2);
                    
                    // Check if body needs multi-line formatting
                    var isMultiLine = switch(clause.body.def) {
                        case EIf(_, _, _): true;
                        case ECase(_, _): true;
                        case ECond(_): true;
                        case EWith(_, _, _): true;
                        case EBlock(exprs) if (exprs.length > 1): true;
                        case _: bodyStr.indexOf('\n') >= 0;
                    };
                    
                    if (isMultiLine) {
                        // Multi-line format: condition on one line, body indented on next
                        clauseStrs.push(
                            indentStr(indent + 1) + conditionStr + ' ->\n' +
                            indentStr(indent + 2) + bodyStr
                        );
                    } else {
                        // Single-line format: condition and body on same line
                        clauseStrs.push(
                            indentStr(indent + 1) + conditionStr + ' -> ' + bodyStr
                        );
                    }
                }
                'cond do\n' + clauseStrs.join('\n') + '\n' + indentStr(indent) + 'end';
                
            case EMatch(pattern, expr):
                var patternStr = printPattern(pattern);
                // Check if the expression has metadata indicating it should stay inline
                // This is used for null coalescing patterns that need to stay on one line
                var keepInline = expr != null && expr.metadata != null && 
                                expr.metadata.keepInlineInAssignment == true;

                switch(pattern) {
                    case PVar(name):
                        var rhsName = switch(expr != null ? expr.def : null) {
                            case EVar(varName): varName;
                            default: null;
                        };

                        // Only skip printing if the RHS is the same variable (self-assignment)
                        // and NOT a temporary pattern variable that will be used later
                        if (rhsName != null && rhsName == name && !ElixirASTBuilder.isTempPatternVarName(name)) {
                            return '';
                        }

                        // IMPORTANT: Haxe-generated temporary variables (g, g1, _g, etc.) MUST be printed
                        // These are created by Haxe during compilation for switch expressions and other patterns.
                        // Example: switch(parseMessage(msg)) becomes _g = parseMessage(msg); switch(_g)
                        // Without printing these assignments, we get "undefined variable 'g'" errors in Elixir.
                        // See ElixirASTBuilder.isTempPatternVarName for full documentation on these variables.
                    default:
                }

                if (keepInline) {
                    // Force inline format for the expression
                    // This ensures null coalescing stays on one line to avoid syntax errors
                    patternStr + ' = ' + print(expr, 0);
                } else {
                    // Regular assignment
                    patternStr + ' = ' + print(expr, 0);
                }
                
            case EWith(clauses, doBlock, elseBlock):
                var withClauses = [for (clause in clauses)
                    printPattern(clause.pattern) + ' <- ' + print(clause.expr, 0)
                ].join(',\n' + indentStr(indent + 1));
                
                var result = 'with ' + withClauses + ' do\n' +
                    indentStr(indent + 1) + print(doBlock, indent + 1) + '\n';
                
                if (elseBlock != null) {
                    result += indentStr(indent) + 'else\n' +
                        indentStr(indent + 1) + print(elseBlock, indent + 1) + '\n';
                }
                
                result + indentStr(indent) + 'end';
                
            // ================================================================
            // Control Flow
            // ================================================================
            case EIf(condition, thenBranch, elseBranch):
                // Check if this should be an inline if expression
                // Use inline format when the branches are simple expressions
                var isInline = isSimpleExpression(thenBranch) && 
                               (elseBranch == null || isSimpleExpression(elseBranch));
                
                #if debug_inline_if
                trace('[XRay InlineIf] Checking if statement');
                trace('[XRay InlineIf] Then branch def: ${thenBranch.def}');
                trace('[XRay InlineIf] isSimpleExpression(thenBranch): ${isSimpleExpression(thenBranch)}');
                trace('[XRay InlineIf] isInline decision: $isInline');
                #end
                
                // Print condition without unnecessary parentheses
                var conditionStr = printIfCondition(condition);
                
                if (isInline && elseBranch != null) {
                    // Inline if-else expression: if condition, do: then_val, else: else_val
                    'if ' + conditionStr + ', do: ' + print(thenBranch, 0) + ', else: ' + print(elseBranch, 0);
                } else if (elseBranch != null) {
                    // Multi-line if-else block
                    'if ' + conditionStr + ' do\n' +
                    indentStr(indent + 1) + print(thenBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'else\n' +
                    indentStr(indent + 1) + print(elseBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'end';
                } else if (isInline) {
                    // Inline if without else: if condition, do: then_val
                    'if ' + conditionStr + ', do: ' + print(thenBranch, 0);
                } else {
                    // Multi-line if without else
                    'if ' + conditionStr + ' do\n' +
                    indentStr(indent + 1) + print(thenBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'end';
                }
                
            case EUnless(condition, body, elseBranch):
                if (elseBranch != null) {
                    'unless ' + print(condition, 0) + ' do\n' +
                    indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                    indentStr(indent) + 'else\n' +
                    indentStr(indent + 1) + print(elseBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'end';
                } else {
                    'unless ' + print(condition, 0) + ' do\n' +
                    indentStr(indent + 1) + print(body, indent + 1) + '\n' +
                    indentStr(indent) + 'end';
                }
                
            case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
                var result = 'try do\n' +
                    indentStr(indent + 1) + print(body, indent + 1) + '\n';
                
                if (rescue.length > 0) {
                    result += indentStr(indent) + 'rescue\n';
                    for (r in rescue) {
                        result += indentStr(indent + 1) + printRescueClause(r, indent + 1) + '\n';
                    }
                }
                
                if (catchClauses.length > 0) {
                    result += indentStr(indent) + 'catch\n';
                    for (c in catchClauses) {
                        result += indentStr(indent + 1) + printCatchClause(c, indent + 1) + '\n';
                    }
                }
                
                if (elseBlock != null) {
                    result += indentStr(indent) + 'else\n' +
                        indentStr(indent + 1) + print(elseBlock, indent + 1) + '\n';
                }
                
                if (afterBlock != null) {
                    result += indentStr(indent) + 'after\n' +
                        indentStr(indent + 1) + print(afterBlock, indent + 1) + '\n';
                }
                
                result + indentStr(indent) + 'end';
                
            case ERaise(exception, attributes):
                if (attributes != null) {
                    'raise ' + print(exception, 0) + ', ' + print(attributes, 0);
                } else {
                    'raise ' + print(exception, 0);
                }
                
            case EThrow(value):
                // Ensure throw arguments are printed as single-line expressions
                // to avoid syntax errors with complex string concatenation
                var valueStr = switch(value.def) {
                    case EBinary(StringConcat, left, right):
                        // For string concatenation with complex expressions,
                        // ensure everything stays on one line
                        var leftStr = print(left, 0);
                        var rightStr = print(right, 0);
                        // Remove any line breaks that might have been introduced
                        leftStr = leftStr.split('\n').join(' ');
                        rightStr = rightStr.split('\n').join(' ');
                        leftStr + ' <> ' + rightStr;
                    default:
                        // For other expressions, print normally but ensure single line
                        var result = print(value, 0);
                        result.split('\n').join(' ');
                };
                'throw(' + valueStr + ')';
                
            // ================================================================
            // Data Structures
            // ================================================================
            case EList(elements):
                // Multi-statement blocks inside list literals need special handling
                // Invalid Elixir: [g = [], g ++ [0], g]  
                // Valid Elixir: [(fn -> g = []; g = g ++ [0]; g end).()]
                // Even better: Use proper comprehension [for i <- 0..1, do: i]
                '[' + [for (e in elements) {
                    switch(e.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            // Multi-statement block in list context must be wrapped
                            // in immediately-invoked anonymous function for valid Elixir
                            #if debug_ast_printer
                            trace('[Printer] Wrapping block with ${exprs.length} expressions in list');
                            #end
                            '(fn -> ' + print(e, 0) + ' end).()';
                        case EBlock(exprs):
                            #if debug_ast_printer
                            trace('[Printer] Single expression block in list, not wrapping');
                            #end
                            print(e, 0);
                        default:
                            print(e, 0);
                    }
                }].join(', ') + ']';
                
            case ETuple(elements):
                '{' + [for (e in elements) print(e, 0)].join(', ') + '}';
                
            case EMap(pairs):
                '%{' + [for (p in pairs) {
                    var key = print(p.key, 0);
                    var value = p.value;
                    
                    // Check if value is an inline if-else that needs parentheses
                    var valueStr = switch(value.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            // Fallback: ensure single expression in map field
                            // Wrap multi-statement block in zero-arity anonymous function call
                            '(fn -> ' + print(value, 0) + ' end).()';
                        case EIf(cond, thenBranch, elseBranch) if (elseBranch != null && 
                            isSimpleExpression(thenBranch) && isSimpleExpression(elseBranch)):
                            // Wrap inline if-else in parentheses for map context
                            '(' + print(value, 0) + ')';
                        case _:
                            print(value, 0);
                    };
                    
                    key + ' => ' + valueStr;
                }].join(', ') + '}';
                
            case EStruct(module, fields):
                '%' + module + '{' + 
                [for (f in fields) {
                    var value = f.value;
                    
                    // Check if value is an inline if-else that needs parentheses
                    var valueStr = switch(value.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            // Fallback for multi-statement in struct field
                            '(fn -> ' + print(value, 0) + ' end).()';
                        case EIf(cond, thenBranch, elseBranch) if (elseBranch != null && 
                            isSimpleExpression(thenBranch) && isSimpleExpression(elseBranch)):
                            // Wrap inline if-else in parentheses for struct context
                            '(' + print(value, 0) + ')';
                        case _:
                            print(value, 0);
                    };
                    
                    f.key + ': ' + valueStr;
                }].join(', ') + '}';
                
            case EStructUpdate(struct, fields):
                // Struct update syntax: %{struct | field: value, ...}
                '%{' + print(struct, 0) + ' | ' +
                [for (f in fields) {
                    var value = f.value;
                    
                    // Check if value is an inline if-else that needs parentheses
                    var valueStr = switch(value.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            '(fn -> ' + print(value, 0) + ' end).()';
                        case EIf(cond, thenBranch, elseBranch) if (elseBranch != null && 
                            isSimpleExpression(thenBranch) && isSimpleExpression(elseBranch)):
                            // Wrap inline if-else in parentheses for struct update context
                            '(' + print(value, 0) + ')';
                        case _:
                            print(value, 0);
                    };
                    
                    f.key + ': ' + valueStr;
                }].join(', ') + '}';
                
            case EKeywordList(pairs):
                '[' + [for (p in pairs) {
                    var value = p.value;
                    
                    // Check if value is an inline if-else that needs parentheses
                    var valueStr = switch(value.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            '(fn -> ' + print(value, 0) + ' end).()';
                        case EIf(cond, thenBranch, elseBranch) if (elseBranch != null && 
                            isSimpleExpression(thenBranch) && isSimpleExpression(elseBranch)):
                            // Wrap inline if-else in parentheses for keyword list context
                            '(' + print(value, 0) + ')';
                        case _:
                            print(value, 0);
                    };
                    
                    p.key + ': ' + valueStr;
                }].join(', ') + ']';
                
            case EBitstring(segments):
                '<<' + [for (s in segments) printBinarySegment(s)].join(', ') + '>>';
                
            // ================================================================
            // Expressions
            // ================================================================
            case ECall(target, funcName, args):
                /**
                 * CRITICAL BUG FIX (2025-09-01): Method Call Indentation
                 * 
                 * ISSUE: Method calls were losing all indentation, appearing at column 0
                 * regardless of their nesting level. This caused invalid Elixir syntax
                 * when method calls appeared inside blocks, lambdas, or if-statements.
                 * 
                 * ROOT CAUSE: The printer was using `print(target, 0)` which reset
                 * indentation to 0, instead of `print(target, indent)` which preserves
                 * the current indentation level.
                 * 
                 * SYMPTOMS:
                 * - In Bytes module: `s.cca(index)` appeared with no indentation
                 * - Compilation error: "cannot invoke remote function inside a match"
                 * - Method calls inside nested contexts lost their position
                 * 
                 * EXAMPLE OF BUG:
                 * ```elixir
                 * if condition do
                 *   c = index = i = i + 1
                 * s.cca(index)  # <- NO INDENTATION (wrong!)
                 * end
                 * ```
                 * 
                 * FIXED OUTPUT:
                 * ```elixir
                 * if condition do
                 *   c = index = i = i + 1
                 *   s.cca(index)  # <- PROPER INDENTATION
                 * end
                 * ```
                 * 
                 * LESSON LEARNED:
                 * - Always pass the indent parameter through when recursively printing
                 * - Never hardcode indent=0 unless specifically needed for inline contexts
                 * - Test nested expressions thoroughly, especially in lambda bodies
                 * - Indentation bugs can cause syntax errors that seem unrelated
                 * 
                 * This bug affected ALL method calls in nested contexts and was
                 * particularly problematic for inline expansion of standard library
                 * functions like String.charCodeAt.
                 */
                // Special handling for Phoenix function name mappings
                // Transform assign_multiple to assign (Phoenix.Component only has assign/2)
                if (funcName == "assign_multiple" && target == null) {
                    funcName = "assign";
                }
                
                // Special handling for while loop placeholders
                if (funcName == "while_loop" && target == null && args.length == 2) {
                    // Generate an immediately invoked recursive function for while loops
                    // This creates a local recursive function that implements the loop
                    var condition = args[0];
                    var body = args[1];
                    var loopFuncName = "loop_" + (loopIdCounter++);
                    
                    // Generate: (fn -> loop_x = fn -> if condition do body; loop_x.() else :ok end end; loop_x.() end).()
                    var lines = [];
                    lines.push('(fn ->');
                    lines.push('  ' + loopFuncName + ' = fn ' + loopFuncName + ' ->');
                    lines.push('    if ' + print(condition, 0) + ' do');
                    lines.push('      ' + print(body, 3));
                    lines.push('      ' + loopFuncName + '.(' + loopFuncName + ')');
                    lines.push('    else');
                    lines.push('      :ok');
                    lines.push('    end');
                    lines.push('  end');
                    lines.push('  ' + loopFuncName + '.(' + loopFuncName + ')');
                    lines.push('end).()');
                    lines.join('\n' + indentStr(indent));
                } else {
                    // Normal function call
                    var argStr = [for (a in args) printFunctionArg(a)].join(', ');
                    if (target != null) {
                        // Check if this is a function variable call (marked with empty funcName)
                        if (funcName == "") {
                            // Function variable call - use .() syntax
                            print(target, indent) + '.(' + argStr + ')';
                        } else {
                            // Transform method call syntax to proper Elixir module calls
                            // Elixir doesn't support obj.method() - use Module.function(obj, args)

                            // Check if this is an Enum method (map, filter, reduce, etc.)
                            var isEnumMethod = switch(funcName) {
                                case "map" | "filter" | "reduce" | "each" | "find" |
                                     "reject" | "take" | "drop" | "any" | "all" |
                                     "count" | "member" | "sort" | "reverse" | "zip" |
                                     "concat" | "flat_map" | "group_by" | "split" |
                                     "join" | "at" | "fetch" | "empty" | "sum" |
                                     "min" | "max" | "uniq" | "with_index":
                                    true;
                                default:
                                    false;
                            };

                            if (isEnumMethod) {
                                // Transform: list.map(fn) → Enum.map(list, fn)
                                var enumCall = 'Enum.' + funcName + '(' + print(target, indent);
                                if (argStr.length > 0) {
                                    enumCall + ', ' + argStr + ')';
                                } else {
                                    enumCall + ')';
                                }
                            } else {
                                // Check if target is a block expression that needs parentheses
                                var targetStr = switch(target.def) {
                                    case ECase(_, _) | ECond(_) | EWith(_, _, _):
                                        // Block expressions need parentheses when used as method call targets
                                        // Generate: (case...end) |> Module.function()
                                        '(' + print(target, indent) + ') |> Kernel.' + funcName;
                                    case EIf(_, _, elseBranch) if (elseBranch != null):
                                        // If expressions with else branches need parentheses too
                                        '(' + print(target, indent) + ') |> Kernel.' + funcName;
                                    default:
                                        // Regular expressions can be method call targets directly
                                        print(target, indent) + '.' + funcName;
                                };
                                targetStr + '(' + argStr + ')';
                            }
                        }
                    } else {
                        funcName + '(' + argStr + ')';
                    }
                }
                
            case EMacroCall(macroName, args, doBlock):
                // Macro calls with do-blocks don't use parentheses
                // e.g., "schema 'users' do ... end"
                var argStr = [for (a in args) print(a, 0)].join(', ');
                macroName + (args.length > 0 ? ' ' + argStr : '') + ' do\n' +
                indentStr(indent + 1) + print(doBlock, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            case ERemoteCall(module, funcName, args):
                var argStr = [for (a in args) printFunctionArg(a)].join(', ');
                print(module, 0) + '.' + funcName + '(' + argStr + ')';
                
            case EPipe(left, right):
                print(left, 0) + ' |> ' + print(right, 0);
                
            /**
             * BINARY OPERATION PRINTING
             * 
             * WHY: If expressions in binary operations require parentheses in Elixir
             * - Without parentheses: `if x, do: 1, else: 2 > 3` is ambiguous
             * - With parentheses: `(if x, do: 1, else: 2) > 3` is clear
             * - Haxe's inline function expansion creates complex if expressions in comparisons
             * 
             * WHAT: Wrap if expressions when they appear as binary operation operands
             * - Detect if expressions in left/right operands
             * - Add parentheses around if expressions
             * - Preserve existing parenthesization logic for the whole expression
             * 
             * HOW: Check operand types before printing
             * - If operand is EIf: wrap in parentheses
             * - Otherwise: print normally
             * - Apply outer parentheses if needed by context
             * 
             * EXAMPLES:
             * - `(if a, do: 1, else: 2) > (if b, do: 3, else: 4)`
             * - `x + y` (no parentheses needed for simple operands)
             * - `(if cond, do: val1, else: val2) + 5`
             */
            case EBinary(op, left, right):
                // Special handling for operators that are functions in Elixir, not infix
                if (op == Remainder) {
                    // Generate rem(n, 2) instead of n rem 2
                    var leftStr = print(left, 0);
                    var rightStr = print(right, 0);
                    'rem(' + leftStr + ', ' + rightStr + ')';
                } else if (isBitwiseOp(op)) {
                    // Bitwise operators require Bitwise module functions
                    // Generate: Bitwise.band(n, 15) instead of n &&& 15
                    var funcName = bitwiseOpToFunction(op);
                    var leftStr = print(left, 0);
                    var rightStr = print(right, 0);
                    'Bitwise.' + funcName + '(' + leftStr + ', ' + rightStr + ')';
                } else {
                    var needsParens = needsParentheses(node);
                    var opStr = binaryOpToString(op);

                    // Check if operands need parentheses (e.g., if expressions in comparisons)
                    var leftStr = switch(left.def) {
                        case EIf(_, _, _):
                            // If expressions in binary operations need parentheses
                            '(' + print(left, 0) + ')';
                        default:
                            print(left, 0);
                    };

                    var rightStr = switch(right.def) {
                        case EIf(_, _, _):
                            // If expressions in binary operations need parentheses
                            '(' + print(right, 0) + ')';
                        default:
                            print(right, 0);
                    };
                    
                    var result = leftStr + ' ' + opStr + ' ' + rightStr;
                    needsParens ? '(' + result + ')' : result;
                }
                
            case EUnary(op, expr):
                #if debug_ast_printer
                switch(expr.def) {
                    case EBlock(stmts):
                        trace('[XRay Printer] WARNING: EBlock inside EUnary! ${stmts.length} statements');
                    default:
                }
                #end
                unaryOpToString(op) + print(expr, 0);
                
            case EField(target, field):
                print(target, 0) + '.' + field;
                
            case EAccess(target, key):
                print(target, 0) + '[' + print(key, 0) + ']';
                
            case ERange(start, end, exclusive):
                print(start, 0) + (exclusive ? '...' : '..') + print(end, 0);
                
            // ================================================================
            // Literals
            // ================================================================
            case EAtom(value):
                // Atoms need quotes only if they contain special characters or don't follow
                // the simple identifier pattern (letters, numbers, underscore, optionally ending with ! or ?)
                // Examples needing quotes: :"TodoApp.PubSub", :"my-atom", :"123start"
                // Examples NOT needing quotes: :title, :ok, :valid?, :save!
                var atomStr: String = value; // ElixirAtom has implicit to String conversion
                
                // Check if atom needs quotes using Elixir's rules:
                // Valid without quotes: starts with letter or underscore, contains only
                // alphanumeric and underscore, optionally ends with ! or ?
                var needsQuotes = false;
                
                // Special case: empty string always needs quotes
                if (atomStr.length == 0) {
                    needsQuotes = true;
                } else {
                    // Check first character: must be letter or underscore
                    var firstChar = atomStr.charAt(0);
                    if (!isLetter(firstChar) && firstChar != '_') {
                        needsQuotes = true;
                    } else {
                        // Check rest of characters (except possibly last)
                        var i = 1;
                        var len = atomStr.length;
                        
                        // Check if ends with ! or ?
                        var lastChar = atomStr.charAt(len - 1);
                        var endsWithBangOrQuestion = (lastChar == '!' || lastChar == '?');
                        var checkUntil = endsWithBangOrQuestion ? len - 1 : len;
                        
                        // Check middle characters
                        while (i < checkUntil && !needsQuotes) {
                            var c = atomStr.charAt(i);
                            if (!isLetter(c) && !isDigit(c) && c != '_') {
                                needsQuotes = true;
                            }
                            i++;
                        }
                    }
                }
                
                if (needsQuotes) {
                    ':"' + atomStr + '"';
                } else {
                    ':' + atomStr;
                }
                
            case EString(value):
                '"' + escapeString(value) + '"';
                
            case EInteger(value):
                Std.string(value);
                
            case EFloat(value):
                Std.string(value);
                
            case EBoolean(value):
                value ? 'true' : 'false';
                
            case ENil:
                'nil';
                
            case ECharlist(value):
                "'" + escapeString(value) + "'";
                
            // ================================================================
            // Variables and Binding
            // ================================================================
            case EVar(name):
                #if debug_ast_pipeline
                if (name.indexOf("priority") >= 0) {
                    trace('[AST Printer] Printing EVar: ${name}');
                }
                #end

                #if debug_infrastructure_vars
                if (name == "g" || name == "_g" || ~/^_?g\d+$/.match(name)) {
                    trace('[AST Printer EVar] Printing infrastructure variable: $name');
                }
                #end

                name;
                
            case EPin(expr):
                '^' + print(expr, 0);
                
            case EUnderscore:
                '_';
                
            // ================================================================
            // Comprehensions
            // ================================================================
            case EFor(generators, filters, body, into, uniq):
                var genStr = [for (g in generators) 
                    printPattern(g.pattern) + ' <- ' + print(g.expr, 0)
                ].join(', ');
                
                var filterStr = filters.length > 0 
                    ? ', ' + [for (f in filters) print(f, 0)].join(', ')
                    : '';
                
                var options = [];
                if (into != null) options.push('into: ' + print(into, 0));
                if (uniq) options.push('uniq: true');
                var optStr = options.length > 0 ? ', ' + options.join(', ') : '';
                
                'for ' + genStr + filterStr + optStr + ', do: ' + print(body, 0);
                
            // ================================================================
            // Anonymous Functions
            // ================================================================
            /**
             * LESSON LEARNED: Anonymous Function Body Indentation
             * 
             * PROBLEM: When printing anonymous functions with complex bodies (like if statements
             * containing blocks), the body was printed with indent level 0, causing nested
             * expressions to lose their indentation context.
             * 
             * SYMPTOMS:
             * - Method calls inside lambda bodies appeared at column 0
             * - Code like `s.cca(index)` had no indentation inside reduce_while lambdas
             * - Syntax errors in generated Elixir due to improper nesting
             * 
             * ROOT CAUSE: The single-line lambda format used `print(clause.body, 0)` which
             * reset the indentation context to 0, losing all nesting information.
             * 
             * SOLUTION: 
             * 1. Always pass proper indent level to body: `print(clause.body, indent + 1)`
             * 2. Detect when bodies are complex and need multi-line formatting
             * 3. Use multi-line format for if/case/cond/multi-expression blocks
             * 
             * This ensures that nested structures inside lambdas maintain proper indentation
             * throughout the entire AST printing process.
             */
            case EFn(clauses):
                #if debug_loop_builder
                if (clauses.length > 0) {
                    trace('[XRay Printer] Printing EFn with ${clauses.length} clauses');
                    var clause = clauses[0];
                    trace('[XRay Printer]   Clause body type: ${Type.enumConstructor(clause.body.def)}');
                    switch(clause.body.def) {
                        case EIf(cond, thenBranch, elseBranch):
                            trace('[XRay Printer]   Body is EIf - condition type: ${Type.enumConstructor(cond.def)}');
                            trace('[XRay Printer]   Then branch type: ${Type.enumConstructor(thenBranch.def)}');
                        case EBlock(exprs):
                            trace('[XRay Printer]   Body is EBlock with ${exprs.length} expressions');
                        default:
                            trace('[XRay Printer]   Body is: ${Type.enumConstructor(clause.body.def)}');
                    }
                }
                #end

                if (clauses.length == 1 && clauses[0].guard == null) {
                    var clause = clauses[0];
                    var argStr = printPatterns(clause.args);
                    // Handle empty parameter list properly (no extra space)
                    var paramPart = clause.args.length == 0 ? '' : ' ' + argStr;

                    // Check if body is complex and needs multi-line formatting
                    var bodyStr = print(clause.body, indent + 1);

                    #if debug_loop_builder
                    trace('[XRay Printer]   Printed body string (first 200 chars): ${bodyStr.substring(0, bodyStr.length > 200 ? 200 : bodyStr.length)}');
                    #end
                    var isMultiLine = switch(clause.body.def) {
                        case EIf(_, _, _): true;
                        case ECase(_, _): true;
                        case ECond(_): true;
                        case EBlock(exprs) if (exprs.length > 1): true;
                        case _: bodyStr.indexOf('\n') >= 0;
                    };
                    
                    if (isMultiLine) {
                        // Multi-line format for complex bodies
                        'fn' + paramPart + ' ->\n' + 
                        indentStr(indent + 1) + bodyStr + '\n' +
                        indentStr(indent) + 'end';
                    } else {
                        // Single-line format for simple bodies
                        'fn' + paramPart + ' -> ' + bodyStr + ' end';
                    }
                } else {
                    'fn\n' +
                    [for (clause in clauses)
                        indentStr(indent + 1) + printPatterns(clause.args) +
                        (clause.guard != null ? ' when ' + print(clause.guard, 0) : '') +
                        ' ->\n' + indentStr(indent + 2) + print(clause.body, indent + 2)
                    ].join('\n') + '\n' +
                    indentStr(indent) + 'end';
                }
                
            case ECapture(expr, arity):
                // Function reference with arity: &Module.function/arity
                if (arity != null) {
                    '&' + print(expr, 0) + '/' + arity;
                } else {
                    // Regular capture without arity
                    '&' + print(expr, 0);
                }
                
            // ================================================================
            // Module Directives
            // ================================================================
            case EAlias(module, as):
                if (as != null) {
                    'alias ' + module + ', as: ' + as;
                } else {
                    'alias ' + module;
                }
                
            case EImport(module, only, except):
                var result = 'import ' + module;
                if (only != null) {
                    result += ', only: [' + 
                        [for (o in only) o.name + ': ' + o.arity].join(', ') + ']';
                } else if (except != null) {
                    result += ', except: [' +
                        [for (e in except) e.name + ': ' + e.arity].join(', ') + ']';
                }
                result;
                
            case EUse(module, options):
                // Special handling for keyword lists in use statements
                if (options.length == 1) {
                    switch(options[0].def) {
                        case EKeywordList(pairs):
                            // Print keyword list without brackets for use statement
                            'use ' + module + ', ' + [for (p in pairs) {
                                var value = switch(p.value.def) {
                                    case EIf(cond, thenBranch, elseBranch) if (elseBranch != null && 
                                        isSimpleExpression(thenBranch) && isSimpleExpression(elseBranch)):
                                        '(' + print(p.value, 0) + ')';
                                    case _:
                                        print(p.value, 0);
                                };
                                p.key + ': ' + value;
                            }].join(', ');
                        case _:
                            'use ' + module + ', ' + print(options[0], 0);
                    }
                } else if (options.length > 0) {
                    'use ' + module + ', ' + [for (o in options) print(o, 0)].join(', ');
                } else {
                    'use ' + module;
                }
                
            case ERequire(module, as):
                if (as != null) {
                    'require ' + module + ', as: ' + as;
                } else {
                    'require ' + module;
                }
                
            // ================================================================
            // Special Forms
            // ================================================================
            case EQuote(options, expr):
                var optStr = options.length > 0 
                    ? ' ' + [for (o in options) print(o, 0)].join(', ') + ','
                    : '';
                // Use do-end block for multi-line quotes
                switch(expr.def) {
                    case EBlock(_):
                        'quote' + optStr + ' do\n' + indentStr(indent + 1) + print(expr, indent + 1) + '\n' + indentStr(indent) + 'end';
                    case _:
                        'quote' + optStr + ' do: ' + print(expr, 0);
                }
                
            case EUnquote(expr):
                'unquote(' + print(expr, 0) + ')';
                
            case EUnquoteSplicing(expr):
                'unquote_splicing(' + print(expr, 0) + ')';
                
            case EReceive(clauses, after):
                var result = 'receive do\n';
                for (clause in clauses) {
                    result += indentStr(indent + 1) + printCaseClause(clause, indent + 1) + '\n';
                }
                if (after != null) {
                    result += indentStr(indent) + 'after\n' +
                        indentStr(indent + 1) + print(after.timeout, 0) + ' ->\n' +
                        indentStr(indent + 2) + print(after.body, indent + 2) + '\n';
                }
                result + indentStr(indent) + 'end';
                
            case ESend(target, message):
                'send(' + print(target, 0) + ', ' + print(message, 0) + ')';
                
            // ================================================================
            // Blocks and Grouping
            // ================================================================
            case EBlock(expressions):
                if (expressions.length == 0) {
                    // Empty blocks generate empty string (no code)
                    // This aligns with TypedExprPreprocessor's semantics where TBlock([])
                    // represents "generate nothing" (e.g., eliminated infrastructure variables)
                    '';
                } else if (expressions.length == 1) {
                    print(expressions[0], indent);
                } else {
                    var parts = [];
                    var printed: Array<String> = [];
                    for (expr in expressions) {
                        var str = print(expr, indent);
                        if (str != null && str.trim().length > 0) {
                            printed.push(str);
                        }
                    }
                    for (i in 0...printed.length) {
                        parts.push(printed[i]);
                        if (i < printed.length - 1) {
                            parts.push('\n' + indentStr(indent));
                        }
                    }
                    parts.join('');
                }
                
            case EParen(expr):
                '(' + print(expr, 0) + ')';
                
            case EDo(body):
                'do\n' +
                [for (expr in body)
                    indentStr(indent + 1) + print(expr, indent + 1)
                ].join('\n') + '\n' +
                indentStr(indent) + 'end';
                
            // ================================================================
            // Documentation & Module Attributes
            // ================================================================
            case EModuleAttribute(name, value):
                '@' + name + ' ' + print(value, indent);
                
            case EModuledoc(content):
                '@moduledoc """' + '\n' + content + '\n' + '"""';
                
            case EDoc(content):
                '@doc """' + '\n' + content + '\n' + '"""';
                
            case ESpec(signature):
                '@spec ' + signature;
                
            case ETypeDef(name, definition):
                '@type ' + name + ' :: ' + definition;
                
            // ================================================================
            // Phoenix/Framework Specific
            // ================================================================
            case ESigil(type, content, modifiers):
                '~' + type + '"""' + '\n' + content + '\n' + '"""' + modifiers;
                
            case ERaw(code):
                // Raw code injection
                // Check if the code is multi-line and needs wrapping
                // Multi-line Elixir expressions in assignments need parentheses
                if (code.indexOf('\n') != -1 && code.indexOf('=') != -1) {
                    // Multi-line code with assignments needs parentheses for proper scoping
                    '(\n' + code + '\n)';
                } else {
                    // Single line or simple code - output as-is
                    code;
                }
                
            case EAssign(name):
                '@' + name;
                
            case EFragment(tag, attributes, children):
                '<' + tag + printAttributes(attributes) + '>' +
                [for (c in children) print(c, 0)].join('') +
                '</' + tag + '>';
        }
    }
    
    /**
     * Print a pattern
     */
    static function printPattern(pattern: EPattern): String {
        return switch(pattern) {
            case PVar(name): name;
            case PLiteral(value): print(value, 0);
            case PTuple(elements): '{' + printPatterns(elements) + '}';
            case PList(elements): '[' + printPatterns(elements) + ']';
            case PCons(head, tail): '[' + printPattern(head) + ' | ' + printPattern(tail) + ']';
            case PMap(pairs): 
                '%{' + [for (p in pairs) print(p.key, 0) + ' => ' + printPattern(p.value)].join(', ') + '}';
            case PStruct(module, fields):
                '%' + module + '{' + [for (f in fields) f.key + ': ' + printPattern(f.value)].join(', ') + '}';
            case PPin(pattern): '^' + printPattern(pattern);
            case PWildcard: '_';
            case PAlias(varName, pattern): printPattern(pattern) + ' = ' + varName;
            case PBinary(segments): '<<' + [for (s in segments) printPatternBinarySegment(s)].join(', ') + '>>';
        }
    }
    
    /**
     * Print multiple patterns
     */
    static function printPatterns(patterns: Array<EPattern>): String {
        return [for (p in patterns) printPattern(p)].join(', ');
    }
    
    /**
     * Print a case clause
     */
    static function printCaseClause(clause: ECaseClause, indent: Int): String {
        var result = printPattern(clause.pattern);
        if (clause.guard != null) {
            result += ' when ' + print(clause.guard, 0);
        }
        result += ' ->\n' + indentStr(indent + 1) + print(clause.body, indent + 1);
        return result;
    }
    
    /**
     * Print a rescue clause
     */
    static function printRescueClause(clause: ERescueClause, indent: Int): String {
        var result = printPattern(clause.pattern);
        if (clause.varName != null) {
            result += ' -> ' + clause.varName;
        }
        result += ' ->\n' + indentStr(indent + 1) + print(clause.body, indent + 1);
        return result;
    }
    
    /**
     * Print a catch clause
     */
    static function printCatchClause(clause: ECatchClause, indent: Int): String {
        var kindStr = switch(clause.kind) {
            case Error: ':error';
            case Exit: ':exit';
            case Throw: ':throw';
            case Any: '_';
        };
        return kindStr + ', ' + printPattern(clause.pattern) + ' ->\n' +
            indentStr(indent + 1) + print(clause.body, indent + 1);
    }
    
    /**
     * Print an attribute
     */
    static function printAttribute(attr: EAttribute): String {
        return '@' + attr.name + ' ' + print(attr.value, 0);
    }
    
    /**
     * Print HTML-like attributes
     */
    static function printAttributes(attrs: Array<EAttribute>): String {
        if (attrs.length == 0) return '';
        return ' ' + [for (a in attrs) a.name + '="' + print(a.value, 0) + '"'].join(' ');
    }
    
    /**
     * Print a binary segment
     */
    static function printBinarySegment(segment: EBinarySegment): String {
        var result = print(segment.value, 0);
        var specs = [];
        if (segment.size != null) specs.push('size(' + print(segment.size, 0) + ')');
        if (segment.type != null) specs.push(segment.type);
        if (segment.modifiers != null) specs = specs.concat(segment.modifiers);
        if (specs.length > 0) {
            result += '::' + specs.join('-');
        }
        return result;
    }
    
    /**
     * Print a pattern binary segment
     */
    static function printPatternBinarySegment(segment: PBinarySegment): String {
        var result = printPattern(segment.pattern);
        var specs = [];
        if (segment.size != null) specs.push('size(' + print(segment.size, 0) + ')');
        if (segment.type != null) specs.push(segment.type);
        if (segment.modifiers != null) specs = specs.concat(segment.modifiers);
        if (specs.length > 0) {
            result += '::' + specs.join('-');
        }
        return result;
    }
    
    /**
     * Convert binary operator to string
     */
    static function binaryOpToString(op: EBinaryOp): String {
        return switch(op) {
            case Add: '+';
            case Subtract: '-';
            case Multiply: '*';
            case Divide: '/';
            case Remainder: 'rem';
            case Power: '**';
            case Equal: '==';
            case NotEqual: '!=';
            case StrictEqual: '===';
            case StrictNotEqual: '!==';
            case Less: '<';
            case Greater: '>';
            case LessEqual: '<=';
            case GreaterEqual: '>=';
            case And: 'and';
            case Or: 'or';
            case AndAlso: '&&';
            case OrElse: '||';
            case BitwiseAnd: '&&&';
            case BitwiseOr: '|||';
            case BitwiseXor: '^^^';
            case ShiftLeft: '<<<';
            case ShiftRight: '>>>';
            case Concat: '++';
            case ListSubtract: '--';
            case In: 'in';
            case StringConcat: '<>';
            case Match: '=';
            case Pipe: '|>';
            case TypeCheck: '::';
            case When: 'when';
        }
    }
    
    /**
     * Check if operator is a bitwise operation
     *
     * WHY: Elixir doesn't support custom infix bitwise operators like Haxe
     * - The BEAM VM implements bitwise operations as module functions, not operators
     * - Unlike Haxe's & operator, Elixir requires explicit Bitwise.band() calls
     * - This design enables compile-time optimization and consistent function semantics
     *
     * WHAT: Returns true for all bitwise operators (&, |, ^, <<, >>)
     * - BitwiseAnd (&) requires Bitwise.band()
     * - BitwiseOr (|) requires Bitwise.bor()
     * - BitwiseXor (^) requires Bitwise.bxor()
     * - ShiftLeft (<<) requires Bitwise.bsl()
     * - ShiftRight (>>) requires Bitwise.bsr()
     *
     * HOW: Pattern matches on EBinaryOp enum variants
     * - Simple pattern match covers all 5 bitwise operators
     * - Returns false for all other operators (arithmetic, comparison, etc.)
     */
    static function isBitwiseOp(op: EBinaryOp): Bool {
        return switch(op) {
            case BitwiseAnd | BitwiseOr | BitwiseXor | ShiftLeft | ShiftRight: true;
            default: false;
        };
    }

    /**
     * Convert bitwise operator to Bitwise module function name
     *
     * WHY: Elixir/BEAM architectural decision - bitwise ops as functions, not infix operators
     * - BEAM VM design: All bitwise operations implemented as module functions
     * - Type consistency: Functions provide clear integer-only type semantics
     * - Macro expansion: 'use Bitwise' imports these same function names
     * - Historical: Erlang uses 'band', 'bor', etc. - Elixir maintains compatibility
     * - Unlike arithmetic (+, -, *), bitwise ops are less common and don't justify operators
     *
     * WHAT: Maps Haxe bitwise operators to Elixir Bitwise module function names
     * - & (BitwiseAnd) → band (bitwise AND)
     * - | (BitwiseOr) → bor (bitwise OR)
     * - ^ (BitwiseXor) → bxor (bitwise XOR)
     * - << (ShiftLeft) → bsl (bitwise shift left)
     * - >> (ShiftRight) → bsr (bitwise shift right)
     *
     * HOW: Direct string mapping to official Bitwise module API
     * - Returns lowercase function names matching Elixir.Bitwise exports
     * - Throws for non-bitwise operators to catch programming errors
     * - Generated code: Bitwise.band(n, 15) instead of n & 15
     *
     * GENERATED CODE EXAMPLE:
     * ```haxe
     * // Haxe Input
     * var masked = value & 0xFF;
     * ```
     * ```elixir
     * # Generated Elixir
     * masked = Bitwise.band(value, 255)
     * ```
     *
     * ELIXIR DESIGN RATIONALE:
     * The Bitwise module approach provides several benefits:
     * 1. **Explicit imports**: 'use Bitwise' makes bitwise operations visible at module top
     * 2. **Type safety**: Functions enforce integer-only operations at compile-time
     * 3. **Performance**: BEAM can optimize function calls as efficiently as operators
     * 4. **Consistency**: Matches Erlang's band/bor/bxor naming convention
     * 5. **Discoverability**: Bitwise.band() is searchable, & syntax for bitwise is cryptic
     *
     * @see https://hexdocs.pm/elixir/Bitwise.html - Official Bitwise module documentation
     * @see https://www.erlang.org/doc/reference_manual/expressions.html#bitwise-expressions - Erlang bitwise expressions
     * @see test/snapshot/regression/bitwise_operations/ - Comprehensive test suite
     */
    static function bitwiseOpToFunction(op: EBinaryOp): String {
        return switch(op) {
            case BitwiseAnd: 'band';    // Bitwise AND: &
            case BitwiseOr: 'bor';      // Bitwise OR: |
            case BitwiseXor: 'bxor';    // Bitwise XOR: ^
            case ShiftLeft: 'bsl';      // Bitwise Shift Left: <<
            case ShiftRight: 'bsr';     // Bitwise Shift Right: >>
            default: throw 'Not a bitwise operator: $op';
        };
    }

    /**
     * Convert unary operator to string
     */
    static function unaryOpToString(op: EUnaryOp): String {
        return switch(op) {
            case Not: 'not ';
            case Negate: '-';
            case Positive: '+';
            case BitwiseNot: '~~~';
            case Bang: '!';
        }
    }
    
    /**
     * Check if expression needs parentheses
     */
    static function needsParentheses(node: ElixirASTDef): Bool {
        return switch(node) {
            // Subtraction needs parentheses in binary contexts to avoid match errors
            case EBinary(Subtract, _, _): true;
            // Other operations that might need parentheses in certain contexts
            case EBinary(op, _, _): 
                // Add more cases as needed
                false;
            default: false;
        };
    }
    
    /**
     * Escape string for Elixir
     */
    static function escapeString(s: String): String {
        return s.replace('\\', '\\\\')
                .replace('"', '\\"')
                .replace('\n', '\\n')
                .replace('\r', '\\r')
                .replace('\t', '\\t');
    }
    
    /**
     * Generate indentation string
     */
    static function indentStr(level: Int): String {
        var result = '';
        for (i in 0...level) {
            result += '  '; // 2 spaces per level
        }
        return result;
    }
    
    /**
     * Check if an expression is simple enough to be used inline
     */
    static function isSimpleExpression(ast: ElixirAST): Bool {
        if (ast == null) return false;
        
        return switch(ast.def) {
            case EVar(_) | EAtom(_) | ENil | EString(_) | 
                 EInteger(_) | EFloat(_) | EBoolean(_) | 
                 EField(_, _) | ETuple(_) | EList(_) | EMap(_):
                true;
            case ECall(_, _, args):
                // Simple function calls with few arguments
                args.length <= 2;
            case EBinary(op, left, right):
                // Assignment operations cannot be used in inline if-statements
                if (op == Match) {
                    false;
                } else {
                    // Other binary operations are simple if both operands are simple
                    isSimpleExpression(left) && isSimpleExpression(right);
                }
            case EMatch(_, _):
                // Assignments cannot be used in inline if-statements
                false;
            case EBlock(expressions):
                // Empty blocks MUST use block syntax (not inline)
                // This prevents invalid syntax: if c == nil, do: , else:
                if (expressions.length == 0) {
                    return false;  // Force block syntax for empty branches
                }

                // A block is not simple if it contains any assignments
                // This prevents inline if with blocks containing assignments
                for (expr in expressions) {
                    if (containsAssignment(expr)) {
                        return false;
                    }
                }
                // Even without assignments, blocks with multiple statements aren't simple
                expressions.length == 1 && isSimpleExpression(expressions[0]);
            case _:
                false;
        };
    }
    
    /**
     * Check if an expression contains any assignment operations
     */
    static function containsAssignment(ast: ElixirAST): Bool {
        if (ast == null) return false;
        
        return switch(ast.def) {
            case EMatch(_, _): true;
            case EBinary(op, _, _) if (op == Match): true;
            case EBlock(expressions):
                for (expr in expressions) {
                    if (containsAssignment(expr)) return true;
                }
                false;
            case EIf(_, thenBranch, elseBranch):
                containsAssignment(thenBranch) || 
                (elseBranch != null && containsAssignment(elseBranch));
            case _: false;
        };
    }
    
    /**
     * Print an if condition, avoiding unnecessary parentheses
     * In Elixir, simple variables don't need parentheses in if conditions
     */
    static function printIfCondition(condition: ElixirAST): String {
        if (condition == null) return "";
        
        // Check if this is a parenthesized simple expression
        switch(condition.def) {
            case EParen(inner):
                // If the inner expression is simple, don't add parentheses
                if (isSimpleVariable(inner)) {
                    return print(inner, 0);
                }
                // Otherwise keep the parentheses for complex expressions
                return '(' + print(inner, 0) + ')';
            default:
                return print(condition, 0);
        }
    }
    
    /**
     * Check if an expression is a simple variable that doesn't need parentheses
     */
    static function isSimpleVariable(ast: ElixirAST): Bool {
        if (ast == null) return false;
        
        return switch(ast.def) {
            case EVar(_) | ENil | EBoolean(_):
                true;
            default:
                false;
        };
    }
    
    /**
     * Print a function argument, wrapping inline if expressions in parentheses
     * 
     * WHY: Elixir requires parentheses around inline if expressions when used as
     *      function arguments to resolve ambiguity in nested calls
     * WHAT: Detects inline if expressions and wraps them in parentheses
     * HOW: Checks if the argument is an inline if and wraps it if needed
     */
    static function printFunctionArg(arg: ElixirAST): String {
        if (arg == null) return "";
        
        // Check what kind of expression this is
        switch(arg.def) {
            case EIf(condition, thenBranch, elseBranch):
                // An if expression needs parentheses when used as a function argument
                // if it will be printed inline (single line)
                // We consider it inline if:
                // 1. It has the keepInlineInAssignment metadata (null coalescing)
                // 2. Or both branches are simple expressions (ternary operator)
                var needsParens = if (arg.metadata != null && arg.metadata.keepInlineInAssignment == true) {
                    true;
                } else {
                    // Check if branches are simple enough to be printed inline
                    var thenSimple = isSimpleExpression(thenBranch);
                    var elseSimple = elseBranch != null ? isSimpleExpression(elseBranch) : true;
                    thenSimple && elseSimple;
                };
                
                if (needsParens) {
                    return '(' + print(arg, 0) + ')';
                } else {
                    return print(arg, 0);
                }
                
            case EBlock(expressions) if (expressions.length > 1):
                // Multi-statement blocks in function arguments must be wrapped
                // in immediately-invoked anonymous functions
                return '(fn -> ' + print(arg, 0) + ' end).()';
                
            default:
                return print(arg, 0);
        }
    }
    
    /**
     * Check if a string represents a module name
     * Module names start with uppercase and can contain dots
     * Examples: "Phoenix.PubSub", "TodoApp.Repo", "Task.Supervisor"
     */
    static function isModuleName(s: String): Bool {
        if (s.length == 0) return false;
        
        var firstChar = s.charAt(0);
        if (firstChar != firstChar.toUpperCase()) return false;
        
        // Check if all parts start with uppercase
        var parts = s.split('.');
        for (part in parts) {
            if (part.length == 0) return false;
            var first = part.charAt(0);
            if (first != first.toUpperCase() || !~/^[A-Z]/.match(first)) {
                return false;
            }
        }
        
        return true;
    }
    
    /**
     * Check if an atom value is likely an application-specific module name
     * that should not be quoted even with dots.
     * 
     * This is a heuristic for Phoenix apps where module names like
     * TodoApp.PubSub or MyApp.Repo should not be quoted.
     */
    static function isAppModuleName(s: String): Bool {
        // First check if it's a valid module name format
        if (!isModuleName(s)) return false;
        
        // Check for common Phoenix/Elixir app patterns
        // App modules typically contain "App" or end with common suffixes
        return s.indexOf("App") != -1 || 
               s.endsWith(".PubSub") || 
               s.endsWith(".Repo") || 
               s.endsWith(".Endpoint") ||
               s.endsWith(".Telemetry") ||
               s.endsWith(".Supervisor") ||
               s.endsWith(".Application") ||
               s.endsWith("Web");
    }
    
    /**
     * Helper to check if a character is a letter (a-z or A-Z)
     */
    static function isLetter(c: String): Bool {
        if (c.length != 1) return false;
        var code = c.charCodeAt(0);
        return (code >= 65 && code <= 90) || // A-Z
               (code >= 97 && code <= 122);   // a-z
    }
    
    /**
     * Helper to check if a character is a digit (0-9)
     */
    static function isDigit(c: String): Bool {
        if (c.length != 1) return false;
        var code = c.charCodeAt(0);
        return code >= 48 && code <= 57; // 0-9
    }
}

#end
