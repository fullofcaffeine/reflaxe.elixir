package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
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
    
    /**
     * Main entry point: Convert ElixirAST to formatted string
     * 
     * WHY: Single public interface for all printing needs
     * WHAT: Recursively converts AST tree to formatted Elixir code
     * HOW: Delegates to specific handlers based on node type
     */
    public static function print(ast: ElixirAST, indent: Int = 0): String {
        #if debug_ast_printer
        trace('[XRay AST Printer] Printing node: ${ast.def}');
        #end
        
        var result = printNode(ast.def, indent);
        
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
                var argStr = printPatterns(args);
                var guardStr = guards != null ? ' when ' + print(guards, 0) : '';
                'defp ${name}(${argStr})${guardStr} do\n' +
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
                'cond do\n' +
                [for (clause in clauses)
                    indentStr(indent + 1) + print(clause.condition, 0) + ' ->\n' +
                    indentStr(indent + 2) + print(clause.body, indent + 2)
                ].join('\n') + '\n' +
                indentStr(indent) + 'end';
                
            case EMatch(pattern, expr):
                printPattern(pattern) + ' = ' + print(expr, 0);
                
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
                
                if (isInline && elseBranch != null) {
                    // Inline if-else expression: if condition, do: then_val, else: else_val
                    'if ' + print(condition, 0) + ', do: ' + print(thenBranch, 0) + ', else: ' + print(elseBranch, 0);
                } else if (elseBranch != null) {
                    // Multi-line if-else block
                    'if ' + print(condition, 0) + ' do\n' +
                    indentStr(indent + 1) + print(thenBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'else\n' +
                    indentStr(indent + 1) + print(elseBranch, indent + 1) + '\n' +
                    indentStr(indent) + 'end';
                } else if (isInline) {
                    // Inline if without else: if condition, do: then_val
                    'if ' + print(condition, 0) + ', do: ' + print(thenBranch, 0);
                } else {
                    // Multi-line if without else
                    'if ' + print(condition, 0) + ' do\n' +
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
                'throw(' + print(value, 0) + ')';
                
            // ================================================================
            // Data Structures
            // ================================================================
            case EList(elements):
                '[' + [for (e in elements) print(e, 0)].join(', ') + ']';
                
            case ETuple(elements):
                '{' + [for (e in elements) print(e, 0)].join(', ') + '}';
                
            case EMap(pairs):
                '%{' + [for (p in pairs) print(p.key, 0) + ' => ' + print(p.value, 0)].join(', ') + '}';
                
            case EStruct(module, fields):
                '%' + module + '{' + 
                [for (f in fields) f.key + ': ' + print(f.value, 0)].join(', ') + '}';
                
            case EStructUpdate(struct, fields):
                // Struct update syntax: %{struct | field: value, ...}
                '%{' + print(struct, 0) + ' | ' +
                [for (f in fields) f.key + ': ' + print(f.value, 0)].join(', ') + '}';
                
            case EKeywordList(pairs):
                '[' + [for (p in pairs) p.key + ': ' + print(p.value, 0)].join(', ') + ']';
                
            case EBitstring(segments):
                '<<' + [for (s in segments) printBinarySegment(s)].join(', ') + '>>';
                
            // ================================================================
            // Expressions
            // ================================================================
            case ECall(target, funcName, args):
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
                    var argStr = [for (a in args) print(a, 0)].join(', ');
                    if (target != null) {
                        // Check if this is a function variable call (marked with empty funcName)
                        if (funcName == "") {
                            // Function variable call - use .() syntax
                            print(target, 0) + '.(' + argStr + ')';
                        } else {
                            // Method call on object
                            print(target, 0) + '.' + funcName + '(' + argStr + ')';
                        }
                    } else {
                        funcName + '(' + argStr + ')';
                    }
                }
                
            case ERemoteCall(module, funcName, args):
                var argStr = [for (a in args) print(a, 0)].join(', ');
                print(module, 0) + '.' + funcName + '(' + argStr + ')';
                
            case EPipe(left, right):
                print(left, 0) + ' |> ' + print(right, 0);
                
            case EBinary(op, left, right):
                var needsParens = needsParentheses(node);
                var opStr = binaryOpToString(op);
                var result = print(left, 0) + ' ' + opStr + ' ' + print(right, 0);
                needsParens ? '(' + result + ')' : result;
                
            case EUnary(op, expr):
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
                ':' + value;
                
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
            case EFn(clauses):
                if (clauses.length == 1 && clauses[0].guard == null) {
                    var clause = clauses[0];
                    var argStr = printPatterns(clause.args);
                    // Handle empty parameter list properly (no extra space)
                    var paramPart = clause.args.length == 0 ? '' : ' ' + argStr;
                    'fn' + paramPart + ' -> ' + print(clause.body, 0) + ' end';
                } else {
                    'fn\n' +
                    [for (clause in clauses)
                        indentStr(indent + 1) + printPatterns(clause.args) +
                        (clause.guard != null ? ' when ' + print(clause.guard, 0) : '') +
                        ' ->\n' + indentStr(indent + 2) + print(clause.body, indent + 2)
                    ].join('\n') + '\n' +
                    indentStr(indent) + 'end';
                }
                
            case ECapture(expr):
                '&' + print(expr, 0);
                
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
                'use ' + module + 
                    (options.length > 0 ? ', ' + [for (o in options) print(o, 0)].join(', ') : '');
                
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
                'quote' + optStr + ' do: ' + print(expr, 0);
                
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
                    'nil';
                } else if (expressions.length == 1) {
                    print(expressions[0], indent);
                } else {
                    [for (i in 0...expressions.length) {
                        var expr = expressions[i];
                        var str = print(expr, indent);
                        // Add newline between statements
                        if (i < expressions.length - 1) str + '\n' + indentStr(indent);
                        else str;
                    }].join('');
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
            // Documentation
            // ================================================================
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
        // Simple heuristic - can be enhanced
        return false;
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
                 EInteger(_) | EFloat(_) | EBool(_) | 
                 EField(_, _) | ETuple(_) | EList(_) | EMap(_):
                true;
            case ECall(_, _, args):
                // Simple function calls with few arguments
                args.length <= 2;
            case EBinary(_, left, right):
                // Simple binary operations
                isSimpleExpression(left) && isSimpleExpression(right);
            case _:
                false;
        };
    }
}

#end