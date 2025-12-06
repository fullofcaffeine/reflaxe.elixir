package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnusedLocalAssignUnderscoreFinalTransforms
 *
 * WHAT
 * - In function bodies, find simple local assignments like `g = expr` where
 *   the binder name is not referenced later in the surrounding block and
 *   rename the binder to `_g` to silence compiler warnings.
 *
 * WHY
 * - The compiler intentionally materializes temporary binders (e.g., for
 *   side-effecting expressions) but Elixir warns when those binders are
 *   unused. Renaming to an underscored binder communicates intent without
 *   altering semantics.
 *
 * HOW
 * - Walk blocks; for any top-level `EMatch(PVar(name), rhs)` or
 *   `EBinary(Match, EVar(name), rhs)`, check if `name` is used in any
 *   subsequent sibling statement. If not, rename pattern to `_name`.
 * - Conservative: does not attempt cross-block dataflow; only same-level
 *   block siblings are considered.
 */
class UnusedLocalAssignUnderscoreFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EBlock(stmts):
                    #if debug_underscore_pass
                    // DISABLED: trace('[UnusedLocalAssign] Found EBlock with ${stmts.length} statements');
                    #end
                    makeASTWithMeta(EBlock(processStatements(stmts)), n.metadata, n.pos);
                case EDo(stmts):
                    #if debug_underscore_pass
                    // DISABLED: trace('[UnusedLocalAssign] Found EDo with ${stmts.length} statements');
                    #end
                    makeASTWithMeta(EDo(processStatements(stmts)), n.metadata, n.pos);
                case EFn(clauses):
                    // Explicitly process EFn clause bodies for dead store removal
                    var processedClauses = [for (clause in clauses) {
                        var processedBody = switch (clause.body.def) {
                            case EBlock(bodyStmts):
                                #if debug_underscore_pass
                                // DISABLED: trace('[UnusedLocalAssign] Processing EFn body EBlock with ${bodyStmts.length} statements');
                                #end
                                makeASTWithMeta(EBlock(processStatements(bodyStmts)), clause.body.metadata, clause.body.pos);
                            case EDo(bodyStmts2):
                                #if debug_underscore_pass
                                // DISABLED: trace('[UnusedLocalAssign] Processing EFn body EDo with ${bodyStmts2.length} statements');
                                #end
                                makeASTWithMeta(EDo(processStatements(bodyStmts2)), clause.body.metadata, clause.body.pos);
                            default:
                                clause.body;
                        };
                        {
                            args: clause.args,
                            guard: clause.guard,
                            body: processedBody
                        };
                    }];
                    makeASTWithMeta(EFn(processedClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function processStatements(stmts: Array<ElixirAST>): Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (i in 0...stmts.length) {
            var s = stmts[i];
            inline function canRename(name:String):Bool {
                if (name == null) return false;
                // Never rename core binders
                if (name == "socket" || name == "params" || name == "assigns") return false;
                // Rename only clearly unused compiler temps (g, this1, etc.)
                // NOTE: Removed raw_* and updated_* - they're often used in IIFE patterns
                // and complex expressions that are hard to detect via AST traversal
                return name == "g" || StringTools.startsWith(name, "this");
            }

            // Check for dead store pattern: `x = a; x = b` where x is immediately reassigned
            var varName = getAssignedVarName(s);
            if (varName != null && canRename(varName)) {
                // Check if next statement immediately reassigns the same variable (dead store)
                if (i + 1 < stmts.length) {
                    var nextVarName = getAssignedVarName(stmts[i + 1]);
                    if (nextVarName == varName) {
                        // Dead store - skip this assignment entirely
                        #if debug_underscore_pass
                        // DISABLED: trace('[UnusedLocalAssign] Removing dead store: $varName');
                        #end
                        continue;
                    }
                }
            }

            var renamed = switch (s.def) {
                case EMatch(PVar(vn), rhs) if (canRename(vn) && !usedLater(stmts, i+1, vn)):
                    makeASTWithMeta(EMatch(PVar('_' + vn), rhs), s.metadata, s.pos);
                case EBinary(Match, {def: EVar(v)}, rhs) if (canRename(v) && !usedLater(stmts, i+1, v)):
                    makeASTWithMeta(EBinary(Match, {def: EVar('_' + v), metadata: s.metadata, pos: s.pos}, rhs), s.metadata, s.pos);
                default:
                    s;
            }
            out.push(renamed);
        }
        return out;
    }

    // Extract the variable name from an assignment statement
    static function getAssignedVarName(s: ElixirAST): Null<String> {
        if (s == null || s.def == null) return null;
        return switch (s.def) {
            case EMatch(PVar(name), _): name;
            case EBinary(Match, {def: EVar(name)}, _): name;
            default: null;
        };
    }

    static function usedLater(stmts:Array<ElixirAST>, start:Int, name:String): Bool {
        var found = false;
        for (j in start...stmts.length) if (!found) {
            walk(stmts[j], name, function(){ found = true; });
        }
        return found;
    }

    static function walk(n: ElixirAST, name:String, hit:()->Void): Void {
        if (n == null || n.def == null) return;
        switch (n.def) {
            case EVar(v) if (v == name): hit();
            case ERaw(code):
                // Check for identifier in raw code using word boundary matching
                if (code != null && containsIdentifier(code, name)) hit();
            case EString(s):
                // Check for identifier in string (interpolations or plain text)
                if (s != null && containsIdentifier(s, name)) hit();
            case EBinary(_, l, r): walk(l, name, hit); walk(r, name, hit);
            case EMatch(_, rhs): walk(rhs, name, hit);
            case EBlock(ss): for (s in ss) walk(s, name, hit);
            case EDo(ss2): for (s in ss2) walk(s, name, hit);
            case EIf(c,t,e): walk(c, name, hit); walk(t, name, hit); if (e != null) walk(e, name, hit);
            case ECase(expr, cs):
                walk(expr, name, hit);
                for (c in cs) { if (c.guard != null) walk(c.guard, name, hit); walk(c.body, name, hit); }
            case ECall(t,_,as): if (t != null) walk(t, name, hit); if (as != null) for (a in as) walk(a, name, hit);
            case ERemoteCall(t2,_,as2): walk(t2, name, hit); if (as2 != null) for (a2 in as2) walk(a2, name, hit);
            case EField(obj,_): walk(obj, name, hit);
            case EAccess(obj2,key): walk(obj2, name, hit); walk(key, name, hit);
            // Map, tuple, keyword list, and struct traversal
            case EMap(pairs): for (p in pairs) { walk(p.key, name, hit); walk(p.value, name, hit); }
            case ETuple(els): for (el in els) walk(el, name, hit);
            case EKeywordList(pairs): for (p in pairs) walk(p.value, name, hit);
            case EStruct(_, fields): for (f in fields) walk(f.value, name, hit);
            case EStructUpdate(base, fields2): walk(base, name, hit); for (f in fields2) walk(f.value, name, hit);
            case EList(els2): for (el in els2) walk(el, name, hit);
            case EFn(clauses): for (c in clauses) walk(c.body, name, hit);
            // Unary operators (not, -, !)
            case EUnary(_, expr): walk(expr, name, hit);
            // Parenthesized expressions
            case EParen(expr): walk(expr, name, hit);
            // Pipe operator
            case EPipe(l, r): walk(l, name, hit); walk(r, name, hit);
            // Range expressions
            case ERange(start, endExpr, _): walk(start, name, hit); walk(endExpr, name, hit);
            // Cond expressions
            case ECond(clauses): for (c in clauses) { walk(c.condition, name, hit); walk(c.body, name, hit); }
            // Pin expressions
            case EPin(expr): walk(expr, name, hit);
            // Capture expressions
            case ECapture(expr, _): walk(expr, name, hit);
            // Try/rescue
            case ETry(body, rescue, catchClauses, afterBlock, elseBlock):
                walk(body, name, hit);
                for (r in rescue) walk(r.body, name, hit);
                for (c in catchClauses) walk(c.body, name, hit);
                if (afterBlock != null) walk(afterBlock, name, hit);
                if (elseBlock != null) walk(elseBlock, name, hit);
            default:
        }
    }

    // Check if code string contains the identifier with word boundaries
    static function containsIdentifier(code: String, name: String): Bool {
        if (code == null || name == null) return false;
        // Use simple substring search - word boundary regex causes compiler hang
        // due to string concatenation in macro context
        // Check for: start of string, space, or common delimiters before/after name
        var idx = code.indexOf(name);
        if (idx < 0) return false;
        // Verify it's a word boundary (not part of another identifier)
        var before = idx == 0 || !isIdentifierChar(code.charAt(idx - 1));
        var after = idx + name.length >= code.length || !isIdentifierChar(code.charAt(idx + name.length));
        return before && after;
    }

    static inline function isIdentifierChar(c: String): Bool {
        return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == '_';
    }
}

#end
