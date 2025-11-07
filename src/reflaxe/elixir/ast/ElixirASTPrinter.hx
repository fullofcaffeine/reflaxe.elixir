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
    // Track current module name to enable context-aware printing (e.g., Repo qualification)
    static var currentModuleName: Null<String> = null;
    static var observedAppPrefix: Null<String> = null;

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

                // Add @compile directive to silence unused private functions (late sweep)
                // Compute defp names/arity directly from doBlock
                var nowarnList: Array<String> = [];
                // Unwrap parentheses around the module do-block to avoid stray parentheses lines
                var doBlockUnwrapped = switch (doBlock.def) { case EParen(inner): inner; default: doBlock; };
                switch (doBlockUnwrapped.def) {
                    case EBlock(stmts):
                        for (s in stmts) switch (s.def) {
                            case EDefp(fnName, fnArgs, _, _):
                                var arity = fnArgs.length;
                                nowarnList.push(fnName + ': ' + arity);
                            default:
                        }
                    default:
                }
                // Printer de-semanticization: do not inject @compile here; handled by transforms if needed

                // Preserve and set current module context
                var prevModule = currentModuleName;
                currentModuleName = name;

                // Capture observed app prefix if this is an <App>.Repo module
                if (observedAppPrefix == null) {
                    var idxCap = name.indexOf(".Repo");
                    if (idxCap > 0) observedAppPrefix = name.substring(0, idxCap);
                    var idxWeb = name.indexOf("Web");
                    if (idxWeb > 0) observedAppPrefix = name.substring(0, idxWeb);
                }

                // Optional alias injection for Repo in non-Web modules
                inline function needsRepoAliasInBlock(block: ElixirAST): Bool {
                    var hasAlias = false;
                    var hasBare = false;
                    switch (block.def) {
                        case EBlock(stmts):
                            for (s in stmts) switch (s.def) {
                                case EAlias(module, as) if ((as == null || as == "Repo")):
                                    if (module != null && module.indexOf(".Repo") > 0) hasAlias = true;
                                default:
                            }
                            // scan for bare repo like above
                            function scan(n: ElixirAST): Void {
                                if (n == null || n.def == null || hasBare) return;
                                switch (n.def) {
                                    case ERemoteCall({def: EVar(m)}, _, _): if (m == "Repo") hasBare = true;
                                    case ECall({def: EVar(m)}, _, _): if (m == "Repo") hasBare = true;
                                    case EBlock(es): for (e in es) scan(e);
                                    case EIf(c, t, e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                                    case ECond(cs): for (cl in cs) { scan(cl.condition); scan(cl.body); }
                                    case EMatch(_, rhs): scan(rhs);
                                    case EBinary(_, l, r): scan(l); scan(r);
                                    case ERemoteCall(m, _, args): scan(m); for (a in args) scan(a);
                                    case ECall(t, _, args): if (t != null) scan(t); for (a in args) scan(a);
                                    default:
                                }
                            }
                            for (s in stmts) scan(s);
                        default:
                    }
                    return (hasBare && !hasAlias);
                }
                // Printer de-semanticization: do not inject Repo alias here

                // Ensure alias Phoenix.SafePubSub as SafePubSub when bare SafePubSub references exist
                inline function needsSafePubSubAliasInBlock(block: ElixirAST): Bool {
                    var hasAlias = false;
                    var needs = false;
                    switch (block.def) {
                        case EBlock(stmts) | EDo(stmts):
                            for (s in stmts) switch (s.def) {
                                case EAlias(module, as) if (as == "SafePubSub" || module == "Phoenix.SafePubSub"): hasAlias = true;
                                default:
                            }
                            function scan(n: ElixirAST): Void {
                                if (n == null || n.def == null || needs) return;
                                switch (n.def) {
                                    case ERemoteCall({def: EVar(m)}, _, _) if (m == "SafePubSub"): needs = true;
                                    case ECall({def: EVar(m2)}, _, _) if (m2 == "SafePubSub"): needs = true;
                                    case EVar(v) if (v == "SafePubSub"): needs = true;
                                    case ERaw(code): if (code != null && code.indexOf("SafePubSub.") != -1) needs = true;
                                    case EDef(_, _, _, b): scan(b);
                                    case EDefp(_, _, _, privateBody): scan(privateBody);
                                    case EBlock(es): for (e in es) scan(e);
                                    case EIf(c, t, e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                                    case EBinary(_, l, r): scan(l); scan(r);
                                    case ERemoteCall(m,_,as): scan(m); if (as != null) for (a in as) scan(a);
                                    case ECall(t,_,argsList): if (t != null) scan(t); if (argsList != null) for (a in argsList) scan(a);
                                    default:
                                }
                            }
                            for (s in stmts) scan(s);
                        default:
                    }
                    return needs && !hasAlias;
                }
                // Printer de-semanticization: SafePubSub alias handled by transforms

                // Ensure `require Ecto.Query` in Web modules (LiveView/Controller often use Ecto DSL)
                // This avoids macro-availability errors; harmless if unused
                // Printer de-semanticization: Ecto.Query require handled by transforms

                // Ensure `require Ecto.Query` when Ecto.Query macros are used in the module body
                inline function needsEctoRequireInBlock(block: ElixirAST): Bool {
                    var needs = false;
                    var has = false;
                    switch (block.def) {
                        case EBlock(stmts) | EDo(stmts):
                            for (s in stmts) switch (s.def) {
                                case ERequire(mod, _): if (mod == "Ecto.Query") has = true;
                                default:
                            }
                            function scan(n: ElixirAST): Void {
                                if (n == null || n.def == null || needs) return;
                                switch (n.def) {
                                    case ERemoteCall({def: EVar(m)}, _, _): if (m == "Ecto.Query") needs = true;
                                    case ECall(t, _, args): if (t != null) scan(t); for (a in args) scan(a);
                                    case EDef(_, _, _, body): scan(body);
                                    case EDefp(_, _, _, body): scan(body);
                                    case EBlock(es): for (e in es) scan(e);
                                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                                    case EBinary(_, l, r): scan(l); scan(r);
                                    case EFn(cs): for (cl in cs) scan(cl.body);
                                    default:
                                }
                            }
                            for (s in stmts) scan(s);
                        default:
                    }
                    return needs && !has;
                }
                // Printer de-semanticization: Ecto.Query require handled by transforms

                // Inject `require Ecto.Query` when remote Ecto.Query macros are present in the body
                if (needsEctoRequireInBlock(doBlockUnwrapped)) {
                    moduleContent += indentStr(indent + 1) + 'require Ecto.Query\n';
                }

                // Special-case: if the do-block is a raw block (EBlock with single ERaw),
                // print its contents directly without extra parentheses or indentation.
                moduleContent += (switch (doBlockUnwrapped.def) {
                    case EBlock(stmts) if (stmts.length == 1):
                        switch (stmts[0].def) {
                            case ERaw(code):
                                var c = code;
                                if (!StringTools.endsWith(c, "\n")) c += "\n";
                                c;
                            default:
                                indentStr(indent + 1) + print(doBlockUnwrapped, indent + 1);
                        }
                    default:
                        indentStr(indent + 1) + print(doBlockUnwrapped, indent + 1);
                });

                // Restore context
                currentModuleName = prevModule;

                var moduleResult = 'defmodule ${name} do\n' +
                    moduleContent + '\n' +
                    indentStr(indent) + 'end\n';

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
                    // Set module context while printing body for proper qualification
                    var prevModuleCtx = currentModuleName;
                    currentModuleName = name;
                    
                    // Print any other methods (like toString)
                    for (expr in body) {
                        // Skip defstruct calls as defexception handles that
                        var exprStr = print(expr, indent + 1);
                        if (!exprStr.startsWith("defstruct")) {
                            result += '\n' + indentStr(indent + 1) + exprStr + '\n';
                        }
                    }
                    // Restore printer module context
                    currentModuleName = prevModuleCtx;
                    
                    result += indentStr(indent) + 'end\n';
                    result;
                } else {
                    // Regular module
                    var result = 'defmodule ${name} do\n';
                    // Printer de-semanticization: do not inject @compile here; handled by transforms if needed
                    // Preserve and set current module context for body printing
                    var prevModuleCtx = currentModuleName;
                    currentModuleName = name;

                    // Inject alias Phoenix.SafePubSub as SafePubSub when bare references exist in EModule body
                    inline function moduleNeedsSafePubSubAlias(stmts: Array<ElixirAST>): Bool {
                        var hasAlias = false;
                        var needs = false;
                        for (s in stmts) switch (s.def) {
                            case EAlias(module, as) if (as == 'SafePubSub' || module == 'Phoenix.SafePubSub'): hasAlias = true;
                            default:
                        }
                        function scan(n: ElixirAST): Void {
                            if (needs || n == null || n.def == null) return;
                            switch (n.def) {
                                case ERemoteCall({def: EVar(m)}, _, _) if (m == 'SafePubSub'): needs = true;
                                case ECall({def: EVar(m2)}, _, _) if (m2 == 'SafePubSub'): needs = true;
                                case EVar(v) if (v == 'SafePubSub'): needs = true;
                                case ERaw(code): if (code != null && code.indexOf('SafePubSub.') != -1) needs = true;
                                case EDef(_, _, _, b): scan(b);
                                case EDefp(_, _, _, privateBody): scan(privateBody);
                                case EBlock(es): for (e in es) scan(e);
                                case EIf(c, t, e): scan(c); scan(t); if (e != null) scan(e);
                                case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                                case EBinary(_, l, r): scan(l); scan(r);
                                case ERemoteCall(m,_,as): scan(m); if (as != null) for (a in as) scan(a);
                                case ECall(t,_,argsList): if (t != null) scan(t); if (argsList != null) for (a in argsList) scan(a);
                                default:
                            }
                        }
                        for (s in stmts) scan(s);
                        return needs && !hasAlias;
                    }
                    // Printer de-semanticization: SafePubSub alias handled by transforms
                    
                    // Print attributes
                    for (attr in attributes) {
                        result += indentStr(indent + 1) + printAttribute(attr) + '\n';
                    }
                    
                    if (attributes.length > 0 && body.length > 0) {
                        result += '\n';
                    }
                    
                    // Capture observed app prefix if this is an <App>.Repo module
                    if (observedAppPrefix == null) {
                        var idxCap2 = name.indexOf(".Repo");
                        if (idxCap2 > 0) observedAppPrefix = name.substring(0, idxCap2);
                        var idxWeb2 = name.indexOf("Web");
                        if (idxWeb2 > 0) observedAppPrefix = name.substring(0, idxWeb2);
                    }
                    // In Web modules, proactively require Ecto.Query for macro usage
                    // Printer de-semanticization: Ecto.Query require handled by transforms
                    // Inject `require Ecto.Query` when remote Ecto.Query macros are present in the body
                    var needsEcto = (function():Bool {
                        // Local helper for EModule body
                        inline function bodyHasEctoRemote(stmts:Array<ElixirAST>): Bool {
                            var found = false;
                            function scan(n: ElixirAST): Void {
                                if (found || n == null || n.def == null) return;
                                switch (n.def) {
                                    case ERequire(mod, _): // ignore existing requires for detection
                                    case ERemoteCall(mod, _, args):
                                        switch (mod.def) { case EVar(m) if (m == 'Ecto.Query'): found = true; default: }
                                        if (args != null) for (a in args) scan(a);
                                    case ERaw(code): if (code != null && code.indexOf('Ecto.Query.') != -1) found = true;
                                    case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                                    case EBlock(es): for (e in es) scan(e);
                                    case EDo(es2): for (e in es2) scan(e);
                                    case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                                    case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                                    case EBinary(_, l, r): scan(l); scan(r);
                                    case EFn(cs): for (cl in cs) scan(cl.body);
                                    case EDef(_,_,_,b): scan(b);
                                    case EDefp(_,_,_,privateBody): scan(privateBody);
                                    default:
                                }
                            }
                            for (s in stmts) scan(s);
                            return found;
                        }
                        return bodyHasEctoRemote(body);
                    })();
                    if (needsEcto) {
                        result += indentStr(indent + 1) + 'require Ecto.Query\n';
                    }

                    // Print body
                    for (expr in body) {
                        // Unwrap raw EBlock([ERaw(...)]) bodies to avoid stray parentheses and double indentation
                        switch (expr.def) {
                            case EBlock(stmts) if (stmts.length == 1):
                                switch (stmts[0].def) {
                                    case ERaw(code):
                                        var c = code;
                                        if (!StringTools.endsWith(c, "\n")) c += "\n";
                                        result += c; // code already contains its own indentation
                                    default:
                                        result += indentStr(indent + 1) + print(expr, indent + 1) + '\n';
                                }
                            default:
                                result += indentStr(indent + 1) + print(expr, indent + 1) + '\n';
                        }
                    }
                    // Restore printer module context
                    currentModuleName = prevModuleCtx;
                    
                    result += indentStr(indent) + 'end\n';
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
                // Preserve and set current module name while printing this module body
                var prevModuleCtx = currentModuleName;
                currentModuleName = name;
                
                // Print attributes
                for (attr in attributes) {
                    result += indentStr(indent + 1) + printAttribute(attr) + '\n';
                }
                
                if (attributes.length > 0 && body.length > 0) {
                    result += '\n';
                }
                
                // Inject alias <App>.Repo as Repo in non-Web modules when bare Repo.* is referenced
                inline function needsRepoAlias(stmts: Array<ElixirAST>): Bool {
                    var hasAlias = false;
                    var hasBare = false;
                    for (s in stmts) switch (s.def) {
                        case EAlias(module, as) if ((as == null || as == "Repo")):
                            // Any alias to *.Repo counts
                            if (module != null && module.indexOf(".Repo") > 0) hasAlias = true;
                        default:
                    }
                    // Scan for bare Repo usage by walking AST
                    function scan(n: ElixirAST): Void {
                        if (n == null || n.def == null || hasBare) return;
                        switch (n.def) {
                            case ERemoteCall({def: EVar(m)}, _, _): if (m == "Repo") hasBare = true;
                            case ECall({def: EVar(m)}, _, _): if (m == "Repo") hasBare = true;
                            case EDef(_, _, _, body): scan(body);
                            case EDefp(_, _, _, body): scan(body);
                            case EBlock(es): for (e in es) scan(e);
                            case EIf(c, t, e): scan(c); scan(t); if (e != null) scan(e);
                            case ECase(e, cs): scan(e); for (cl in cs) { if (cl.guard != null) scan(cl.guard); scan(cl.body); }
                            case ECond(cs): for (cl in cs) { scan(cl.condition); scan(cl.body); }
                            case EMatch(pat, rhs): scan(rhs);
                            case EBinary(_, l, r): scan(l); scan(r);
                            case ERemoteCall(m, _, args): scan(m); for (a in args) scan(a);
                            case ECall(t, _, args): if (t != null) scan(t); for (a in args) scan(a);
                            case ETuple(elts): for (e in elts) scan(e);
                            case EMap(pairs): for (p in pairs) { scan(p.key); scan(p.value); }
                            case EKeywordList(pairs): for (p in pairs) { scan(p.value); }
                            case EStructUpdate(st, fields): scan(st); for (f in fields) scan(f.value);
                            default:
                        }
                    }
                    for (s in stmts) scan(s);
                    return (hasBare && !hasAlias);
                }
                // Printer de-semanticization: Repo alias handled by transforms

                // Print body, unwrapping any top-level parentheses
                for (expr in body) {
                    var e2 = switch (expr.def) { case EParen(inner): inner; default: expr; };
                    result += indentStr(indent + 1) + print(e2, indent + 1) + '\n';
                }
                
                // Restore module context
                currentModuleName = prevModuleCtx;

                result += indentStr(indent) + 'end\n';
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
                '(' + (
                    'case ' + print(expr, 0) + ' do\n' +
                    [for (clause in clauses) 
                        indentStr(indent + 1) + printCaseClause(clause, indent + 1)
                    ].join('\n') + '\n' +
                    indentStr(indent) + 'end'
                ) + ')';
                
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

                // Normalize numeric-sentinel call assigns: `0 = call(...)` → `call(...)`
                var isZeroPat = switch (pattern) { case PLiteral({def: EInteger(v)}) if (v == 0): true; default: false; };
                if (isZeroPat && expr != null) {
                    switch (expr.def) {
                        case ECall(_,_,_) | ERemoteCall(_,_,_): return print(expr, 0);
                        case EParen(inner):
                            switch (inner.def) {
                                case ECall(_,_,_) | ERemoteCall(_,_,_): return print(inner, 0);
                                default:
                            }
                        default:
                    }
                }

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

                // Collapse self-assignment chains in RHS: pattern = (pattern = expr) or pattern = pattern = expr
                // String-level and AST-level guards
                switch (pattern) {
                    case PVar(name):
                        if (expr != null) {
                            switch (expr.def) {
                        case EBinary(Match, innerLeft, rhsExpr):
                            var innerLeftStr = print(innerLeft, 0);
                            if (innerLeftStr == name) {
                                return name + ' = ' + print(rhsExpr, indent);
                            }
                        case EMatch(innerPattern, rhsExpr2):
                            switch (innerPattern) { case PVar(innerName) if (innerName == name): return name + ' = ' + print(rhsExpr2, indent); default: }
                                default:
                            }
                            var rhsPrinted = print(expr, indent);
                            if (rhsPrinted != null) {
                                var trimmed = StringTools.trim(rhsPrinted);
                                var prefix = name + ' = ';
                                if (StringTools.startsWith(trimmed, prefix)) {
                                    var rest = StringTools.trim(trimmed.substr(prefix.length));
                                    return name + ' = ' + rest;
                                }
                            }
                        }
                    default:
                }

                // Numeric-sentinel assignment normalization: `0 = call(...)` → print call only
                var isZeroPat = switch (pattern) { case PLiteral({def: EInteger(v)}) if (v == 0): true; default: false; };
                if (isZeroPat && expr != null) {
                    switch (expr.def) {
                        case ECall(_,_,_) | ERemoteCall(_,_,_): return print(expr, 0);
                        case EParen(inner):
                            switch (inner.def) {
                                case ECall(_,_,_) | ERemoteCall(_,_,_): return print(inner, 0);
                                default:
                            }
                        default:
                    }
                }

                if (keepInline) {
                    // Force inline format for the expression
                    // This ensures null coalescing stays on one line to avoid syntax errors
                    patternStr + ' = ' + print(expr, 0);
                } else {
                    // Regular assignment - pass indent for proper nesting of block expressions (case, cond, etc.)
                    patternStr + ' = ' + print(expr, indent);
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
                // Always parenthesize the condition to avoid parser ambiguity in complex shapes
                var conditionStr = '(' + print(condition, 0) + ')';
                
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
                    // Special-case increment shapes to avoid operator-warning when result is ignored
                    var thenStr = switch (thenBranch.def) {
                        case EBinary(Add, {def: EVar(v)}, rhs): v + ' = ' + v + ' + ' + print(rhs, 0);
                        default: print(thenBranch, 0);
                    };
                    'if ' + conditionStr + ', do: ' + thenStr;
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
                // Attempt to recover list-building blocks into proper list literals
                inline function tryListFromBlock(block: ElixirAST): Null<Array<ElixirAST>> {
                    inline function normalizeName(n:String): String {
                        var i = 0; while (i < n.length && n.charAt(i) == "_") i++;
                        return i > 0 ? n.substr(i) : n;
                    }
                    return switch (block.def) {
                        case EBlock(stmts) if (stmts.length >= 2):
                            var accName: Null<String> = null;
                            // Detect initializer: acc = [] or acc <- []
                            switch (stmts[0].def) {
                                case EBinary(Match, {def: EVar(v)}, {def: EList(initEls)}) if (initEls.length == 0): accName = v;
                                case EMatch(PVar(varName), {def: EList(initElems)}) if (initElems.length == 0): accName = varName;
                                default:
                            }
                            if (accName == null) return null;
                            var accNorm = normalizeName(accName);
                            var outVals: Array<ElixirAST> = [];
                            for (i in 1...stmts.length) {
                                switch (stmts[i].def) {
                                    case EBinary(Match, {def: EVar(lhs)}, rhs) if (normalizeName(lhs) == accNorm):
                                        // acc = Enum.concat(acc, [value]) or acc = acc ++ [value]
                                        switch (rhs.def) {
                                            case ERemoteCall({def: EVar(m)}, "concat", cargs) if (m == "Enum" && cargs.length == 2):
                                                switch (cargs[0].def) {
                                                    case EVar(v) if (normalizeName(v) == accNorm):
                                                        switch (cargs[1].def) {
                                                            case EList(listElts) if (listElts.length == 1):
                                                                outVals.push(listElts[0]);
                                                            default:
                                                        }
                                                    default:
                                                }
                                            case EBinary(Add, {def: EVar(accVar)}, rhsExpr) if (normalizeName(accVar) == accNorm):
                                                switch (rhsExpr.def) {
                                                    case EList(listElements) if (listElements.length == 1):
                                                        outVals.push(listElements[0]);
                                                    default:
                                                }
                                            default:
                                        }
                                    default:
                                }
                            }
                            return outVals.length > 0 ? outVals : null;
                        default:
                            null;
                    }
                }
                '[' + [for (e in elements) {
                    switch (e.def) {
                        // Parenthesize for-comprehensions inside list literals to avoid
                        // ambiguity with keyword arguments (do:) in container contexts.
                        case EFor(_, _, _, _, _):
                            '(' + print(e, 0) + ')';
                        case EBlock(exprs) if (exprs.length > 1):
                            var recovered = tryListFromBlock(e);
                            if (recovered != null) {
                                '[' + [for (v in recovered) print(v, 0)].join(', ') + ']';
                            } else {
                                '(fn -> ' + print(e, 0).rtrim() + ' end).()';
                            }
                        case EParen(inner) if (switch (inner.def) { case EBlock(es) if (es.length > 1): true; default: false; }):
                            // Attempt recovery just like EBlock case
                            var recovered2 = tryListFromBlock(inner);
                            if (recovered2 != null) {
                                '[' + [for (v in recovered2) print(v, 0)].join(', ') + ']';
                            } else {
                                // Fallback: a parenthesized multi-statement block still needs wrapping
                                var innerStr = print(inner, 0).rtrim();
                                if (StringTools.startsWith(innerStr, "(") && StringTools.endsWith(innerStr, ")")) {
                                    innerStr = innerStr.substr(1, innerStr.length - 2);
                                }
                                '(fn -> ' + innerStr + ' end).()';
                            }
                        case EBlock(_):
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
                            '(fn -> ' + print(value, 0).rtrim() + ' end).()';
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
                // Qualify bare struct module with <App> prefix when inside <App>Web.*
                var qualifiedModule = (function() {
                    if (module.indexOf('.') != -1) return module;
                    inline function appPrefix(): Null<String> {
                        if (currentModuleName == null) return observedAppPrefix;
                        var idx = currentModuleName.indexOf("Web");
                        return idx > 0 ? currentModuleName.substring(0, idx) : observedAppPrefix;
                    }
                    var p = appPrefix();
                    return (p != null ? p + '.' + module : module);
                })();
                '%' + qualifiedModule + '{' + 
                [for (f in fields) {
                    var value = f.value;
                    
                    // Check if value is an inline if-else that needs parentheses
                    var valueStr = switch(value.def) {
                        case EBlock(exprs) if (exprs.length > 1):
                            // Fallback for multi-statement in struct field
                            '(fn -> ' + print(value, 0).rtrim() + ' end).()';
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
                            '(fn -> ' + print(value, 0).rtrim() + ' end).()';
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
                            '(fn -> ' + print(value, 0).rtrim() + ' end).()';
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
                    var argStr = (function(){
                        var parts: Array<String> = [];
                        for (a in args) {
                            var printed = printFunctionArg(a, indent + 1);
                            parts.push(sanitizeArgPrinted(printed, indent + 1));
                        }
                        return parts.join(', ');
                    })();
                    if (target != null) {
                        // Fallback: Module.new() -> %<App>.Module{}
                        if (funcName == "new" && args.length == 0) {
                            inline function appPrefix(): Null<String> {
                                if (currentModuleName == null) return observedAppPrefix;
                                var idx = currentModuleName.indexOf("Web");
                                return idx > 0 ? currentModuleName.substring(0, idx) : observedAppPrefix;
                            }
                            switch (target.def) {
                                case EVar(n):
                                    var modStr = (function(){
                                        if (n.indexOf('.') == -1) {
                                            var p = appPrefix();
                                            return (p != null ? p + '.' + n : n);
                                        } else {
                                            return n;
                                        }
                                    })();
                                    return '%'+modStr+'{}';
                                default:
                            }
                        }
                        // Check if this is a function variable call (marked with empty funcName)
                        if (funcName == "") {
                            // Function variable call - ensure target is parenthesized when needed, then use .() syntax
                            var tStr = switch (target.def) {
                                case EFn(_): '(' + print(target, indent) + ')';
                                case EParen(_): print(target, indent);
                                default: print(target, indent);
                            };
                            tStr + '.(' + argStr + ')';
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
                                // Special-case join: ensure first arg is a single expression (wrap via IIFE if needed),
                                // mirroring the remote-call branch handling to avoid leaking multi-statement builders.
                                var receiverPrinted = print(target, indent);
                                var firstArgStr = (function(){
                                    if (funcName == "join") {
                                        var trimmed = StringTools.trim(receiverPrinted);
                                        return StringTools.startsWith(trimmed, '(fn ->') ? receiverPrinted : '(fn -> ' + receiverPrinted + ' end).()';
                                    } else {
                                        return receiverPrinted;
                                    }
                                })();
                                var enumCall = 'Enum.' + funcName + '(' + firstArgStr;
                                if (argStr.length > 0) {
                                    enumCall + ', ' + argStr + ')';
                                } else {
                                    enumCall + ')';
                                }
                            } else {
                                // Special-case: to_iso8601 on Date/NaiveDateTime values
                                if (funcName == "to_iso8601") {
                                    // Generate explicit module call to preserve ISO8601 formatting
                                    // and avoid implicit String.Chars conversions.
                                    // We default to DateTime for runtime Date values.
                                    var tstr = print(target, indent);
                                    return 'DateTime.to_iso8601(' + tstr + ')';
                                }
                                // Special-case: list.push(elem) → list = Enum.concat(list, [elem])
                                if (funcName == "push") {
                                    // Only when target is a simple variable (lowercase start)
                                    switch (target.def) {
                                        case EVar(varName):
                                            var first = varName.charAt(0);
                                            if (first == first.toLowerCase()) {
                                                // Use the first argument only
                                                var printedArg = args.length > 0 ? printFunctionArg(args[0]) : "";
                                                return varName + ' = Enum.concat(' + varName + ', [' + printedArg + '])';
                                            }
                                        default:
                                    }
                                }
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
                                        // Qualify bare Repo.* to <App>.Repo.* within <App>Web modules
                                        var modStr = switch(target.def) {
                                            case EVar(name) if (name == "Repo"):
                                                var idx = (currentModuleName != null) ? currentModuleName.indexOf("Web") : -1;
                                                if (idx > 0) currentModuleName.substring(0, idx) + ".Repo" else {
                                                    if (observedAppPrefix != null) observedAppPrefix + ".Repo" else {
                                                        try {
                                                            var app = reflaxe.elixir.PhoenixMapper.getAppModuleName();
                                                            if (app != null && app.length > 0) app + ".Repo" else name;
                                                        } catch (e:Dynamic) {
                                                            name;
                                                        }
                                                    }
                                                };
                                            case EVar(name):
                                                // If target looks like a module (UpperCamel) and we're inside <App>Web.*,
                                                // qualify to <App>.<Name> (fallback for cases missed by AST pass)
                                                var first = name.charAt(0);
                                                var isUpper = first == first.toUpperCase() && first != first.toLowerCase();
                                                var idx = (currentModuleName != null) ? currentModuleName.indexOf("Web") : -1;
                                                inline function isStdModule(n: String): Bool {
                                                    return switch (n) {
                                                        case "Enum" | "String" | "Map" | "List" | "Tuple" | "DateTime" |
                                                             "Bitwise" | "Kernel" | "IO" | "File" | "Regex" | "Process" |
                                                             "Task" | "Agent" | "GenServer" | "Stream" | "Keyword" | "Access" |
                                                             "Path" | "System" | "Application" | "Logger" | "Ecto" | "Ecto.Query" |
                                                             "Phoenix" | "Phoenix.LiveView" | "Phoenix.Component" | "Phoenix.Controller":
                                                            true;
                                                        default:
                                                            false;
                                                    };
                                                }
                                                if (isUpper && idx > 0 && !isStdModule(name)) currentModuleName.substring(0, idx) + "." + name else name;
                                            default:
                                                print(target, indent);
                                        };
                                        modStr + '.' + funcName;
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
                var unwrappedDo = switch (doBlock.def) { case EParen(inner): inner; default: doBlock; };
                macroName + (args.length > 0 ? ' ' + argStr : '') + ' do\n' +
                indentStr(indent + 1) + print(unwrappedDo, indent + 1) + '\n' +
                indentStr(indent) + 'end';
                
            case ERemoteCall(module, funcName, args):
                // Special remappings before generic remote call printing
                switch (module.def) {
                    case EVar(m) if (m == "Date_Impl_"):
                        // Date_Impl_.get_time(x) -> DateTime.to_unix(x, :millisecond)
                        if (funcName == "get_time" && args.length == 1) {
                            return 'DateTime.to_unix(' + printFunctionArg(args[0], indent) + ', :millisecond)';
                        }
                        // Date_Impl_.from_string(x) -> x
                        if (funcName == "from_string" && args.length == 1) {
                            return printFunctionArg(args[0], indent);
                        }
                    default:
                }
                // Module.new() → %Module{} is handled by AST passes (ModuleNewToStructLiteral)
                // Printer no longer rewrites new/0 to struct literal to avoid generating invalid
                // structs for non-schema modules (e.g., BalancedTree). Rely on AST transform stage.
                // Qualify struct literal in changeset/2 to match remote module
                var argStr = (function(){
                    // Aggressive stabilization for Assert boolean assertions: wrap first arg in IIFE to
                    // guarantee single-expression semantics even when inline expansions introduce multiple statements.
                    // Shape-agnostic and limited to Assert.is_true/2 and Assert.is_false/2.
                    switch (module.def) {
                        case EVar(m) if (m == "Assert" && (funcName == "is_true" || funcName == "is_false") && args.length >= 1):
                            var parts: Array<String> = [];
                            var firstPrinted = '(fn -> ' + print(args[0], indent) + ' end).()';
                            parts.push(firstPrinted);
                            for (i in 1...args.length) parts.push(sanitizeArgPrinted(printFunctionArg(args[i], indent), indent));
                            return parts.join(', ');
                        default:
                    }
                    if (funcName == "changeset" && args.length >= 1) {
                        var parts: Array<String> = [];
                        // Force first arg to %<RemoteModule>{} when it's a bare struct literal
                        // Inspect printed first arg; if it is a bare %Module{} with no prefix,
                        // replace with %<RemoteModule>{} to avoid __struct__/1 undefined.
                        var firstPrinted = print(args[0], 0);
                        var needsQual = false;
                        if (StringTools.startsWith(firstPrinted, "%")) {
                            var open = firstPrinted.indexOf("{");
                            var closeDot = firstPrinted.indexOf(".");
                            needsQual = (open > 1 && (closeDot == -1 || closeDot > open));
                        }
                        if (needsQual) {
                            var remote = printQualifiedModule(module);
                            parts.push('%' + remote + '{}');
                        } else {
                            parts.push(firstPrinted);
                        }
                        for (i in 1...args.length) parts.push(sanitizeArgPrinted(printFunctionArg(args[i], indent), indent));
                        return parts.join(', ');
                    } else {
                        var s: String;
                        // Special handling: ensure Enum.join first argument is a single valid expression
                        // Some upstream shapes produce multi-statement fragments as the first argument.
                        // Wrap such cases in an IIFE at print-time as a last resort for validity.
                        var mstrTmp = printQualifiedModule(module);
                        if (mstrTmp == "Enum" && funcName == "join" && args.length >= 1) {
                            var parts: Array<String> = [];
                            var firstPrintedRaw = print(args[0], indent);
                            var trimmed = StringTools.trim(firstPrintedRaw);
                            var firstPrinted = StringTools.startsWith(trimmed, '(fn ->') ? firstPrintedRaw : '(fn -> ' + firstPrintedRaw + ' end).()';
                            parts.push(firstPrinted);
                            for (i in 1...args.length) parts.push(sanitizeArgPrinted(printFunctionArg(args[i], indent), indent));
                            s = parts.join(', ');
                        } else {
                            s = [for (a in args) sanitizeArgPrinted(printFunctionArg(a, indent), indent)].join(', ');
                        }
                        // Ecto.Query.from(t in :table, ...) -> qualify atom to <App>.CamelCase
                        var mstr = printQualifiedModule(module);
                        if (mstr == "Ecto.Query" && funcName == "from") {
                            inline function camelize(x: String): String {
                                var parts = x.split("_");
                                var out = [];
                                for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
                                return out.join("");
                            }
                            var idxIn = s.indexOf(" in :");
                            if (idxIn != -1) {
                                var start = idxIn + 6; // after " in :"
                                var j = start;
                                while (j < s.length) {
                                    var ch = s.charAt(j);
                                    var isAlnum = ~/^[A-Za-z0-9_]$/.match(ch);
                                    if (!isAlnum) break;
                                    j++;
                                }
                                var raw = s.substr(start, j - start);
                                if (raw.length > 0) {
                                    var app = (function(){
                                        var pfx: Null<String> = null;
                                        if (currentModuleName != null) {
                                            var w = currentModuleName.indexOf("Web");
                                            if (w > 0) pfx = currentModuleName.substring(0, w);
                                        }
                                        if (pfx == null) pfx = observedAppPrefix;
                                        if (pfx == null) { try pfx = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {} }
                                        return pfx;
                                    })();
                                    if (app != null && app.length > 0) {
                                        s = s.substr(0, idxIn + 4) + ' ' + app + '.' + camelize(raw) + s.substr(j);
                                    }
                                }
                            }
                        }
                        // Repo.get/one bare module arg qualification: Repo.get(Todo, id) → Repo.get(<App>.Todo, id)
                        if ((mstr == reflaxe.elixir.PhoenixMapper.getAppModuleName() + ".Repo" || StringTools.endsWith(mstr, ".Repo")) && (funcName == "get" || funcName == "one")) {
                            var comma = s.indexOf(',');
                            var firstArg = comma != -1 ? s.substr(0, comma) : s;
                            var trimmed = StringTools.trim(firstArg);
                            inline function isBareModule(name:String):Bool {
                                return name.length > 0 && name.indexOf('.') == -1 && ~/^[A-Z][A-Za-z0-9_]*$/.match(name);
                            }
                            var app = (function(){
                                var pfx: Null<String> = null;
                                if (currentModuleName != null) {
                                    var w = currentModuleName.indexOf("Web");
                                    if (w > 0) pfx = currentModuleName.substring(0, w);
                                }
                                if (pfx == null) pfx = observedAppPrefix;
                                if (pfx == null) { try pfx = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {} }
                                return pfx;
                            })();
                            if (app != null && isBareModule(trimmed)) {
                                var rest = comma != -1 ? s.substr(comma) : "";
                                s = app + "." + trimmed + rest;
                            }
                        }
                        return s;
                    }
                })();
                var moduleStr = printQualifiedModule(module);
                moduleStr + '.' + funcName + '(' + argStr + ')';
                
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
                    // De-duplication: collapse x = (x = expr) and x = x = expr
                    if (op == Match) {
                        // Normalize numeric-sentinel call assigns: `0 = call(...)` → `call(...)`
                        var isZeroLhs = switch (left.def) { case EInteger(v) if (v == 0): true; default: false; };
                        if (isZeroLhs) {
                            switch (right.def) {
                                case ECall(_,_,_) | ERemoteCall(_,_,_):
                                    return print(right, 0);
                                case EParen(innerP):
                                    switch (innerP.def) {
                                        case ECall(_,_,_) | ERemoteCall(_,_,_): return print(innerP, 0);
                                        default:
                                    }
                                default:
                            }
                        }
                        var leftStr0 = print(left, 0);
                        // Guard against blank/whitespace LHS; normalize to discard `_`
                        if (leftStr0 == null || StringTools.trim(leftStr0).length == 0) leftStr0 = "_";
                        switch (right.def) {
                            case EBinary(Match, innerLeft, rhsExpr):
                                var innerLeftStr = print(innerLeft, 0);
                                if (innerLeftStr == leftStr0) {
                                    return leftStr0 + ' = ' + print(rhsExpr, 0);
                                }
                            case EMatch(innerPattern, rhsExpr2):
                                var lhsName: Null<String> = switch (innerPattern) { case PVar(nm): nm; default: null; };
                                if (lhsName != null && lhsName == leftStr0) {
                                    return leftStr0 + ' = ' + print(rhsExpr2, 0);
                                }
                            default:
                        }
                        // String-level guard: collapse when RHS starts with redundant "<lhs> ="
                        var rightPrinted0 = print(right, 0);
                        if (rightPrinted0 != null) {
                            var trimmed = StringTools.trim(rightPrinted0);
                            var prefix = leftStr0 + ' = ';
                            if (StringTools.startsWith(trimmed, prefix)) {
                                var rest = StringTools.trim(trimmed.substr(prefix.length));
                                return leftStr0 + ' = ' + rest;
                            }
                        }
                    }
                    // Constant folding for simple arithmetic to avoid no-op operator warnings
                    if (op == Add) {
                        switch (left.def) {
                            case EInteger(a):
                                switch (right.def) {
                                    case EInteger(b):
                                        return Std.string(a + b);
                                    default:
                                }
                            default:
                        }
                    }
                    var needsParens = needsParentheses(node);
                    var opStr = binaryOpToString(op);

                    // Check if operands need parentheses (e.g., if expressions in comparisons)
                    var leftStr = switch(left.def) {
                        case EIf(_, _, _) | ECase(_, _) | ECond(_) | EWith(_,_,_):
                            // If expressions in binary operations need parentheses
                            '(' + print(left, 0) + ')';
                        default:
                            print(left, 0);
                    };

                    var rightStr = switch(right) {
                        case null:
                            '0';
                        case _:
                            switch(right.def) {
                        case EIf(_, _, _) | ECase(_, _) | ECond(_) | EWith(_,_,_):
                            // In assignments, prefer no extra parens around case/cond/if on RHS
                            if (op == Match) print(right, 0) else '(' + print(right, 0) + ')';
                        default:
                            print(right, 0);
                            }
                    };
                    
                    // Defensive: avoid invalid syntax if an operand prints empty (or whitespace-only)
                    if (leftStr == null || leftStr.length == 0 || StringTools.trim(leftStr).length == 0) {
                        // For assignments, prefer wildcard '_' instead of numeric sentinel
                        if (op == Match) leftStr = '_'; else leftStr = '0';
                    }
                    if (rightStr == null || rightStr.length == 0) rightStr = '0';
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
                // Special-case: list.length -> length(list)
                if (field == "length") {
                    return 'length(' + print(target, 0) + ')';
                }
                // Special-case: now.to_iso8601 -> DateTime.to_iso8601(now)
                if (field == "to_iso8601") {
                    return 'DateTime.to_iso8601(' + print(target, 0) + ')';
                }
                // If target is an atom, combine into a single atom with proper quoting
                switch (target.def) {
                    case EAtom(atomBase):
                        // Render as a single atom: :"atomBase.Field"
                        var combined = atomBase + '.' + field;
                        // Reuse EAtom printing rules by constructing a synthetic EAtom
                        var tmp = makeAST(EAtom(combined));
                        print(tmp, 0);
                    default:
                        print(target, 0) + '.' + field;
                }
                
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
                // Defensive normalization: strip an accidental leading ':' if present in the atom payload
                if (atomStr != null && atomStr.length > 0 && atomStr.charAt(0) == ':') {
                    atomStr = atomStr.substr(1);
                }
                
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
                // Sanitize interpolated strings that contain Enum.join(<multi-stmt>, sep)
                // by wrapping the first argument in an IIFE to ensure valid syntax.
                inline function sanitizeJoinArgInInterpolatedString(s:String):String {
                    if (s == null || s.indexOf("#{") == -1 || s.indexOf("Enum.join(") == -1) return s;
                    var out = new StringBuf();
                    var i = 0;
                    while (i < s.length) {
                        var open = s.indexOf("#{", i);
                        if (open == -1) { out.add(s.substr(i)); break; }
                        out.add(s.substr(i, open - i));
                        var k = open + 2; var depth = 1;
                        while (k < s.length && depth > 0) {
                            var ch = s.charAt(k);
                            if (ch == '{') depth++; else if (ch == '}') depth--; k++;
                        }
                        var inner = s.substr(open + 2, (k - 1) - (open + 2));
                        // Only wrap when needed and avoid double IIFEs
                        var innerTrim = StringTools.trim(inner);
                        var needsWrap = (inner.indexOf('\n') != -1) || (inner.indexOf('=') != -1 && inner.indexOf("==") == -1);
                        if (needsWrap && !StringTools.startsWith(innerTrim, '(fn ->')) {
                            inner = '(fn -> ' + inner + ' end).()';
                        }
                        out.add("#{" + inner + "}");
                        i = k;
                    }
                    return out.toString();
                }
                // Snapshot parity: wrap all #{...} inner expressions in an IIFE, unless already wrapped.
                inline function sanitizeInterpolationsInString(src:String):String {
                    if (src == null || src.indexOf("#{") == -1) return src;
                    var buf = new StringBuf();
                    var i0 = 0;
                    while (i0 < src.length) {
                        var o = src.indexOf("#{", i0);
                        if (o == -1) { buf.add(src.substr(i0)); break; }
                        buf.add(src.substr(i0, o - i0));
                        var k0 = o + 2; var dep = 1;
                        while (k0 < src.length && dep > 0) {
                            var ch2 = src.charAt(k0);
                            if (ch2 == '{') dep++; else if (ch2 == '}') dep--; k0++;
                        }
                        var inner2 = src.substr(o + 2, (k0 - 1) - (o + 2));
                        var trimmed2 = StringTools.trim(inner2);
                        var already = StringTools.startsWith(trimmed2, '(fn ->');
                        var outInner = already ? inner2 : '(fn -> ' + inner2 + ' end).()';
                        buf.add("#{" + outInner + "}");
                        i0 = k0;
                    }
                    return buf.toString();
                }
                var strVal = sanitizeJoinArgInInterpolatedString(value);
                strVal = sanitizeInterpolationsInString(strVal);
                '"' + escapeString(strVal) + '"';
                
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

                // Normalize preserved switch result name to avoid leading underscores
                inline function safeIdent(nm:String):String {
                    return switch (nm) {
                        case "fn" | "do" | "end" | "case" | "cond" | "try" | "rescue" | "catch" | "after" | "receive" | "quote" | "unquote" | "when" | "and" | "or" | "not": nm + "_";
                        default: nm;
                    }
                }
                var printed = safeIdent(name);
                if (name != null && name.length >= 23 && name.substr(0,23) == "__elixir_switch_result_") {
                    printed = "switch_result_" + name.substr(23);
                }
                printed;
                
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
                    // Remove bare numeric sentinel lines within anonymous function bodies
                    inline function stripBareNumericLines(s: String): String {
                        if (s == null || s.length == 0) return s;
                        var lines = s.split('\n');
                        var cleaned: Array<String> = [];
                        for (ln in lines) {
                            var t = StringTools.trim(ln);
                            if (t == '1' || t == '0') continue;
                            cleaned.push(ln);
                        }
                        return cleaned.join('\n');
                    }
                    bodyStr = stripBareNumericLines(bodyStr);

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
                // Drop standalone numeric sentinels (1/0/0.0) in statement position
                inline function isBareNumericSentinel(e: ElixirAST): Bool {
                    return switch (e.def) {
                        case EInteger(v) if (v == 0 || v == 1): true;
                        case EFloat(f) if (f == 0.0): true;
                        case ERaw(code) if (code != null && (StringTools.trim(code) == '1' || StringTools.trim(code) == '0')): true;
                        default: false;
                    }
                }
                var statements = [for (e in expressions) if (!isBareNumericSentinel(e)) e];
                if (statements.length == 0) {
                    // Empty blocks generate empty string (no code)
                    // This aligns with TypedExprPreprocessor's semantics where TBlock([])
                    // represents "generate nothing" (e.g., eliminated infrastructure variables)
                    '';
                } else if (statements.length == 1) {
                    print(statements[0], indent);
                } else {
                    var parts = [];
                    var printed: Array<String> = [];
                    for (expr in statements) {
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
                inline function isBareNumericSentinelInDo(e: ElixirAST): Bool {
                    return switch (e.def) {
                        case EInteger(v) if (v == 0 || v == 1): true;
                        case EFloat(f) if (f == 0.0): true;
                        case ERaw(code) if (code != null && (StringTools.trim(code) == '1' || StringTools.trim(code) == '0')): true;
                        default: false;
                    }
                }
                var bodyStmts = [for (e in body) if (!isBareNumericSentinelInDo(e)) e];
                'do\n' +
                [for (expr in bodyStmts)
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
                // HEEx indentation normalization
                inline function normalizeHeexIndent(s: String): String {
                    if (s == null || s.length == 0) return s;
                    // Split lines
                    var lines = s.split('\n');
                    // Trim leading/trailing blank lines
                    var start = 0;
                    while (start < lines.length && StringTools.trim(lines[start]) == "") start++;
                    var endIdx = lines.length - 1;
                    while (endIdx >= start && StringTools.trim(lines[endIdx]) == "") endIdx--;
                    if (start > endIdx) return ""; // all blank
                    var slice = lines.slice(start, endIdx + 1);
                    // Compute shared indent (spaces only for HEEx; tabs preserved if present)
                    var minIndent = 1000000;
                    for (ln in slice) {
                        if (StringTools.trim(ln) == "") continue;
                        var i = 0;
                        while (i < ln.length && ln.charAt(i) == ' ') i++;
                        if (i < minIndent) minIndent = i;
                    }
                    if (minIndent == 1000000) minIndent = 0;
                    // Strip shared indent
                    var out = new StringBuf();
                    for (i in 0...slice.length) {
                        var ln = slice[i];
                        if (minIndent > 0 && ln.length >= minIndent) ln = ln.substr(minIndent);
                        out.add(ln);
                        if (i < slice.length - 1) out.add('\n');
                    }
                    return out.toString();
                }
                inline function flattenNestedHeex(s:String):String {
                    if (s == null || s.indexOf("<%=") == -1) return s;
                    var out = new StringBuf(); var i = 0;
                    while (i < s.length) {
                        var o = s.indexOf("<% =".replace(" ",""), i); // '<%='
                        if (o == -1) { out.add(s.substr(i)); break; }
                        out.add(s.substr(i, o - i));
                        var c = s.indexOf("%>", o + 3); if (c == -1) { out.add(s.substr(o)); break; }
                        var inner = StringTools.trim(s.substr(o + 3, c - (o + 3)));
                        if (StringTools.startsWith(inner, "~H\"\"\"")) {
                            var st = inner.indexOf("\"\"\""); if (st != -1) {
                                var bs = st + 3; var be = inner.indexOf("\"\"\"", bs);
                                if (be != -1) { out.add(inner.substr(bs, be - bs)); i = c + 2; continue; }
                            }
                        }
                        // inline-if do/else normalization inside ~H
                        out.add(s.substr(o, (c + 2) - o)); i = c + 2;
                    }
                    return out.toString();
                }
                inline function rewriteInlineIfDoToBlock(s:String):String {
                    if (s == null || s.indexOf(", do:") == -1) return s;
                    var i = 0; var out = new StringBuf();
                    while (i < s.length) {
                        var o = s.indexOf("<% =".replace(" ",""), i); if (o == -1) { out.add(s.substr(i)); break; }
                        out.add(s.substr(i, o - i));
                        var c = s.indexOf("%>", o + 3); if (c == -1) { out.add(s.substr(o)); break; }
                        var inner = StringTools.trim(s.substr(o + 3, c - (o + 3)));
                        if (StringTools.startsWith(inner, "if ")) {
                            var rest = StringTools.trim(inner.substr(3));
                            var idx = rest.indexOf(", do: \""); var q = '"';
                            if (idx == -1) { idx = rest.indexOf(", do: '\'"); q = '\''; }
                            if (idx != -1) {
                            var cond = StringTools.trim(rest.substr(0, idx));
                            var after = rest.substr(idx + 7); if (q == '\'') after = rest.substr(idx + 7);
                                var endMark = (q == '"') ? '\"' + ", else:" : "'" + ", else:";
                                var ei = after.indexOf(endMark);
                                if (ei != -1) {
                                    var th = after.substr(0, ei);
                                    var rem = after.substr(ei + endMark.length);
                                    var el: String = null;
                                    if (rem.length >= 1 && rem.charAt(0) == q) {
                                        rem = rem.substr(1); var e2 = rem.indexOf((q == '"') ? '\"' : "'");
                                        if (e2 != -1) el = rem.substr(0, e2);
                                    }
                                    out.add('<%= if ' + cond + ' do %>'); out.add(th);
                                    if (el != null && el != "") { out.add('<% else %>' + el); }
                                    out.add('<% end %>'); i = c + 2; continue;
                                }
                            }
                        }
                        out.add(s.substr(o, (c + 2) - o)); i = c + 2;
                    }
                    return out.toString();
                }
                var normalized = normalizeHeexIndent(content);
                normalized = flattenNestedHeex(normalized);
                normalized = rewriteInlineIfDoToBlock(normalized);
                '~' + type + '"""' + '\n' + normalized + '\n' + '"""' + modifiers;
                
            case ERaw(code):
                // Raw code injection with conservative Ecto.from atom→module qualification
                inline function camelize(s: String): String {
                    var parts = s.split("_");
                    var out = [];
                    for (p in parts) if (p.length > 0) out.push(p.charAt(0).toUpperCase() + p.substr(1));
                    return out.join("");
                }
                var out = code;
                if (out.indexOf("Ecto.Query.from(") != -1) {
                    var pfx: Null<String> = null;
                    if (currentModuleName != null) {
                        var idxA = currentModuleName.indexOf("Web");
                        if (idxA > 0) pfx = currentModuleName.substring(0, idxA) else {
                            var idxB = currentModuleName.indexOf(".Repo");
                            if (idxB > 0) pfx = currentModuleName.substring(0, idxB);
                        }
                    }
                    if (pfx == null && observedAppPrefix != null) pfx = observedAppPrefix;
                    if (pfx == null) { try pfx = reflaxe.elixir.PhoenixMapper.getAppModuleName() catch (e:Dynamic) {} }
                    if (pfx != null && pfx.length > 0) {
                        var buf = new StringBuf();
                        var i = 0;
                        while (i < out.length) {
                            if (i + 5 < out.length && out.substr(i, 5) == " in :") {
                                var j = i + 5;
                                var name = new StringBuf();
                                while (j < out.length) {
                                    var ch = out.charAt(j);
                                    var isAlnum = ~/^[A-Za-z0-9_]$/.match(ch);
                                    if (!isAlnum) break;
                                    name.add(ch);
                                    j++;
                                }
                                var raw = name.toString();
                                if (raw.length > 0) {
                                    buf.add(" in "); buf.add(pfx); buf.add("."); buf.add(camelize(raw));
                                    i = j; continue;
                                }
                            }
                            buf.add(out.charAt(i));
                            i++;
                        }
                        out = buf.toString();
                    }
                }
                // Sanitize #{...} interpolations so each interpolation is a single valid expression
                inline function sanitizeInterpolationsInRawString(src:String):String {
                    if (src == null || src.indexOf("#{") == -1) return src;
                    var buf = new StringBuf();
                    var i0 = 0;
                    while (i0 < src.length) {
                        var o = src.indexOf("#{", i0);
                        if (o == -1) { buf.add(src.substr(i0)); break; }
                        buf.add(src.substr(i0, o - i0));
                        var k0 = o + 2; var dep = 1;
                        while (k0 < src.length && dep > 0) {
                            var ch = src.charAt(k0);
                            if (ch == '{') dep++; else if (ch == '}') dep--; k0++;
                        }
                        var inner = src.substr(o + 2, (k0 - 1) - (o + 2));
                        var trimmed = StringTools.trim(inner);
                        var alreadyIife = StringTools.startsWith(trimmed, '(fn ->');
                        // Snapshot parity: always wrap interpolation as a single expression via IIFE,
                        // unless it is already IIFE-wrapped.
                        var needsWrap = !alreadyIife;
                        var innerOut = needsWrap ? '(fn -> ' + inner + ' end).()' : inner;
                        buf.add("#{" + innerOut + "}");
                        i0 = k0;
                    }
                    return buf.toString();
                }
                out = sanitizeInterpolationsInRawString(out);
                // Do not add extra parentheses around multi-line strings; Elixir accepts them directly
                out;
                
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
            case PVar(name):
                var nm = name;
                if (nm == null || StringTools.trim(nm).length == 0) nm = '_';
                nm;
            case PLiteral(value): print(value, 0);
            case PTuple(elements):
                #if debug_ast_printer
                trace('[ASTPrinter] Printing PTuple with ${elements.length} elements');
                for (i in 0...elements.length) {
                    var elem = elements[i];
                    switch(elem) {
                        case PVar(name): trace('[ASTPrinter]   Element $i: PVar("$name")');
                        case PLiteral(ast): trace('[ASTPrinter]   Element $i: PLiteral');
                        default: trace('[ASTPrinter]   Element $i: ${Type.enumConstructor(elem)}');
                    }
                }
                #end
                '{' + printPatterns(elements) + '}';
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
        var head = printPattern(clause.pattern);
        if (clause.guard != null) {
            head += ' when ' + print(clause.guard, 0);
        }

        // Prefer single-line format for simple bodies, multi-line for complex ones
        var body = clause.body;
        var bodyStr = print(body, indent + 1);
        if (StringTools.trim(bodyStr) == '') bodyStr = 'nil';

        var isBlock = switch (body.def) { case EBlock(_): true; default: false; };
        var isMulti = switch (body.def) {
            case EIf(_, _, _) | ECase(_, _) | ECond(_) | EWith(_, _, _): true;
            case ECall(_, _, _) | ERemoteCall(_, _, _): true; // prefer multi-line for calls for readability and snapshot parity
            case EBlock(exprs) if (exprs.length > 1): true;
            case _: bodyStr.indexOf('\n') >= 0;
        };
        var preferSingle = !isBlock && !isMulti && (bodyStr.length <= 120);

        if (!preferSingle && isMulti) {
            return head + ' ->\n' + indentStr(indent + 1) + bodyStr;
        } else {
            return head + ' -> ' + bodyStr;
        }
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
        var parts = [];
        for (a in attrs) {
            var rendered = switch (a.value.def) {
                case EString(v): '"' + v + '"';
                default: '{' + print(a.value, 0) + '}';
            };
            parts.push(a.name + '=' + rendered);
        }
        return ' ' + parts.join(' ');
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
            case EBinary(_, left, right):
                // Parenthesize when complex constructs appear; also wrap the entire expression for safety
                var needsLeft = switch (left.def) { case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_): true; default: false; };
                var needsRight = switch (right) { case null: false; case _: switch (right.def) { case ECase(_, _) | ECond(_) | EWith(_,_,_) | EIf(_,_,_): true; default: false; } };
                var leftStr = needsLeft ? '(' + print(left, 0) + ')' : print(left, 0);
                var opStr = binaryOpToString(switch (condition.def) { case EBinary(op, _, _): op; default: Add; });
                var rightStr = (right == null) ? '0' : (needsRight ? '(' + print(right, 0) + ')' : print(right, 0));
                var exprStr = leftStr + ' ' + opStr + ' ' + rightStr;
                // Always parenthesize binary expressions in if/unless conditions to prevent parser ambiguities
                return '(' + exprStr + ')';
            case EParen(inner):
                // If the inner expression is simple, don't add parentheses
                if (isSimpleVariable(inner)) {
                    return print(inner, 0);
                }
                // Otherwise keep the parentheses for complex expressions
                return '(' + print(inner, 0) + ')';
            default:
                var s = print(condition, 0);
                // Last-resort: if a block-form (case/cond/with) appears together with any comparison, parenthesize the entire condition
                var hasComplex = (s.indexOf('case ') != -1 || s.indexOf('cond ') != -1 || s.indexOf('with ') != -1);
                var hasCmpLoose = (s.indexOf('>') != -1 || s.indexOf('<') != -1 || s.indexOf('==') != -1 || s.indexOf('!=') != -1);
                if (hasComplex && hasCmpLoose && !StringTools.startsWith(StringTools.trim(s), '(')) {
                    return '(' + s + ')';
                }
                return s;
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
    static function printFunctionArg(arg: ElixirAST, indentLevel: Int = 0): String {
        if (arg == null) return "";
        
        // Check what kind of expression this is
        switch(arg.def) {
            case ERemoteCall(module, funcName, args) if (funcName == "new" && args.length == 0):
                var moduleStr = printQualifiedModule(module);
                return '%'+moduleStr+'{}';
            case ECall(module, funcName, args) if (module != null && funcName == "new" && args.length == 0):
                var moduleStr = printQualifiedModule(module);
                return '%'+moduleStr+'{}';
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
                    return '(' + print(arg, indentLevel) + ')';
                } else {
                    return print(arg, indentLevel);
                }
            case ECase(_, _) | ECond(_) | EWith(_,_,_):
                // Always parenthesize case/cond/with when used as a function argument
                // to prevent accidental line breaks splitting the call site
                return '(' + print(arg, indentLevel) + ')';
            case EBinary(Match, _, _):
                // Parenthesize assignment when used directly as a function argument
                return '(' + print(arg, indentLevel) + ')';
                
            case EBlock(expressions) if (expressions.length > 1):
                // Multi-statement blocks in function arguments must be wrapped
                // in immediately-invoked anonymous functions
                return '(fn -> ' + print(arg, indentLevel).rtrim() + ' end).()';
            case EDo(stmts) if (stmts.length > 1):
                // Do-end blocks used as function arguments should also be wrapped
                return '(fn -> ' + print(arg, indentLevel).rtrim() + ' end).()';
            case EParen(inner) if (switch (inner.def) { case EBlock(exprs) if (exprs.length > 1): true; default: false; }):
                // Parenthesized multi-statement block as argument → wrap in IIFE too
                return '(fn -> ' + print(inner, indentLevel).rtrim() + ' end).()';
            
            default:
                return print(arg, indentLevel);
        }
    }

    // Ensure printed argument is a single safe expression.
    // If it contains line breaks and is not already wrapped (paren/IIFE),
    // wrap it in an IIFE to prevent splitting the call site.
    static function sanitizeArgPrinted(s: String, indent: Int): String {
        if (s == null) return "";
        var trimmed = StringTools.trim(s);
        if (trimmed.length == 0) return s;
        var hasBreak = (s.indexOf('\n') != -1);
        var alreadyIIFE = StringTools.startsWith(trimmed, "(fn ->");
        // Allow multi-line string literals as arguments without wrapping
        var isStringLiteral = StringTools.startsWith(trimmed, '"');
        if (hasBreak && !alreadyIIFE && !isStringLiteral) {
            return '(fn -> ' + s + ' end).()';
        }
        return s;
    }

    /**
     * Print a module reference with context-aware qualification rules
     * - Qualify bare Repo.* to <App>.Repo inside <App>Web.* modules
     */
    static function printQualifiedModule(module: ElixirAST): String {
        // Compute app prefix from current module name (e.g., TodoAppWeb.* -> TodoApp)
        inline function currentAppPrefix(): Null<String> {
            if (currentModuleName == null) return null;
            var idx = currentModuleName.indexOf("Web");
            return idx > 0 ? currentModuleName.substring(0, idx) : null;
        }

        switch (module.def) {
            case EVar(name) if (name == "Repo"):
                var prefix = currentAppPrefix();
                if (prefix != null) return prefix + ".Repo";
                if (observedAppPrefix != null) return observedAppPrefix + ".Repo";
                try {
                    var app = reflaxe.elixir.PhoenixMapper.getAppModuleName();
                    if (app != null && app.length > 0) return app + ".Repo";
                } catch (e:Dynamic) {}
                return name;
            case EVar(name) if (name == "Presence"):
                var prefix = currentAppPrefix();
                if (prefix != null) return prefix + "Web.Presence"; else return name;
            case EVar(n):
                // Never qualify standard/framework modules
                if (reflaxe.elixir.ast.StdModuleWhitelist.isWhitelistedQualified(n)) {
                    return print(module, 0);
                }
                // In <App>Web.* modules, qualify single-segment CamelCase roots to <App>.<Name>
                if (currentModuleName != null && currentModuleName.indexOf("Web") != -1) {
                    var idx = currentModuleName.indexOf("Web");
                    var app = idx > 0 ? currentModuleName.substring(0, idx) : null;
                    inline function isSingleSegmentCamel(name:String):Bool {
                        if (name == null || name.length == 0) return false;
                        return name.indexOf(".") == -1 && name.charAt(0).toUpperCase() == name.charAt(0) && name.charAt(0).toLowerCase() != name.charAt(0);
                    }
                    // Do not qualify the application web module itself (e.g., TodoAppWeb)
                    if (app != null && (n == app + "Web")) {
                        return n;
                    }
                    if (app != null && isSingleSegmentCamel(n)) {
                        return app + "." + n;
                    }
                }
                // Outside Web.* modules, conservatively qualify well-known Phoenix Web modules
                // e.g., TodoLive, HTML, CoreComponents, Layouts → <App>Web.<Name>
                inline function isSingleSegmentCamel(name:String):Bool {
                    if (name == null || name.length == 0) return false;
                    return name.indexOf(".") == -1 && name.charAt(0).toUpperCase() == name.charAt(0) && name.charAt(0).toLowerCase() != name.charAt(0);
                }
                inline function isPhoenixWebRoot(name:String):Bool {
                    return name == "Routes" || name == "Gettext" || name == "HTML" || name == "CoreComponents" || name == "Components" || name == "Layouts" || StringTools.endsWith(name, "Live");
                }
                var appPrefix = observedAppPrefix;
                if (appPrefix == null && currentModuleName != null) {
                    var idx2 = currentModuleName.indexOf("Web");
                    if (idx2 > 0) appPrefix = currentModuleName.substring(0, idx2);
                }
                if (appPrefix != null && isSingleSegmentCamel(n) && isPhoenixWebRoot(n)) {
                    return appPrefix + "Web." + n;
                }
                return print(module, 0);
            default:
                return print(module, 0);
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
