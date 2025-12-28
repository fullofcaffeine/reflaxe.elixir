package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * UnderscoreParamPromotionFinalTransforms
 *
 * WHAT
 * - Promotes underscored parameters (_name) in def/defp heads to base names (name)
 *   when the parameter is referenced in the body (either as _name or name) and no
 *   conflicting base param exists. This removes underscore-usage warnings in final output.
 *
 * WHY
 * - Some late rewrites preserve underscored param binders even when used. This pass
 *   corrects binder/body agreement structurally without app-specific heuristics.
 *
 * HOW
 * - For each EDef/EDefp, if a PVar starts with '_' and base is not present in the
 *   head, and the body references either the underscored or base name, rename the
 *   parameter to base and rewrite body EVar occurrences from underscored -> base.
 * - Idempotent and generic; runs at absolute-final phase.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class UnderscoreParamPromotionFinalTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    var rename = computeRename(args, body);
                    var nArgs = renameParams(args, rename);
                    var nBody = renameBody(body, rename);
                    makeASTWithMeta(EDef(name, nArgs, guards, nBody), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    var rename2 = computeRename(args2, body2);
                    var nArgs2 = renameParams(args2, rename2);
                    var nBody2 = renameBody(body2, rename2);
                    makeASTWithMeta(EDefp(name2, nArgs2, guards2, nBody2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function computeRename(args:Array<EPattern>, body:ElixirAST):Map<String,String> {
        var have = new Map<String,Bool>();
        var rename = new Map<String,String>();
        if (args != null) for (a in args) switch (a) { case PVar(n) if (n != null): have.set(n, true); default: }
        if (args != null) for (a in args) switch (a) {
            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                var base = n.substr(1);
                if (have.exists(base)) break;
                if (containsVarName(body, n) || containsVarName(body, base)) rename.set(n, base);
            default:
        }
        return rename;
    }

    static function renameParams(args:Array<EPattern>, rename:Map<String,String>):Array<EPattern> {
        if (args == null || Lambda.count(rename) == 0) return args;
        var out:Array<EPattern> = [];
        for (a in args) switch (a) { case PVar(n) if (rename.exists(n)): out.push(PVar(rename.get(n))); default: out.push(a); }
        return out;
    }

    static function renameBody(body:ElixirAST, rename:Map<String,String>):ElixirAST {
        if (Lambda.count(rename) == 0) return body;
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) { case EVar(v) if (rename.exists(v)): makeASTWithMeta(EVar(rename.get(v)), n.metadata, n.pos); default: n; }
        });
    }

    static function containsVarName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (n == null || n.def == null || found) return;
            switch (n.def) {
                case EVar(v) if (v == name): found = true;
                case EPin(inner): walk(inner);
                case EParen(e): walk(e);
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses): walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case EWith(clauses, doBlock, elseBlock): for (wc in clauses) walk(wc.expr); walk(doBlock); if (elseBlock != null) walk(elseBlock);
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(t2,_,as2): walk(t2); if (as2 != null) for (a2 in as2) walk(a2);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                case EKeywordList(pairs): for (p in pairs) walk(p.value);
                case EMap(pairs): for (p in pairs) { walk(p.key); walk(p.value); }
                case EStructUpdate(base,fs): walk(base); for (f in fs) walk(f.value);
                case ETuple(es) | EList(es): for (e in es) walk(e);
                case EFn(clauses): for (cl in clauses) { if (cl.guard != null) walk(cl.guard); walk(cl.body); }
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end

