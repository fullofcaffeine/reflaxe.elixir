package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * ParamUnderscoreUsedRepairTransforms
 *
 * WHAT
 * - If a function parameter is underscored (e.g., `_name`) but the body uses
 *   `name`, rename the parameter back to `name`.
 *
 * WHY
 * - Some safe underscore passes may incorrectly underscore parameters later used
 *   in the body (e.g., generated helper modules). This repair ensures correctness
 *   and aligns snapshots that expect non-underscored names when used.
 */
class ParamUnderscoreUsedRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, args, guards, body):
                    makeASTWithMeta(EDef(name, repair(args, body), guards, body), n.metadata, n.pos);
                case EDefp(name2, args2, guards2, body2):
                    makeASTWithMeta(EDefp(name2, repair(args2, body2), guards2, body2), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function repair(args:Array<EPattern>, body:ElixirAST):Array<EPattern> {
        if (args == null) return args;
        return [for (a in args) switch (a) {
            case PVar(nm) if (nm != null && nm.length > 1 && nm.charAt(0) == '_'):
                var base = nm.substr(1);
                // Promote when either the base name is used or the underscored variant string is present as EVar in the body
                if (VariableUsageCollector.usedInFunctionScope(body, base) || usesVarName(body, nm)) PVar(base) else a;
            default: a;
        }];
    }

    static function usesVarName(body: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EVar(v) if (v == name):
                    found = true;
                case EBinary(_, l, r): walk(l); walk(r);
                case EMatch(_, rhs): walk(rhs);
                case EBlock(ss): for (s in ss) walk(s);
                case EDo(ss2): for (s in ss2) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, clauses):
                    walk(expr); for (c in clauses) { if (c.guard != null) walk(c.guard); walk(c.body); }
                case ECall(t,_,as): if (t != null) walk(t); if (as != null) for (a in as) walk(a);
                case ERemoteCall(m,_,as2): walk(m); if (as2 != null) for (a in as2) walk(a);
                case EField(obj,_): walk(obj);
                case EAccess(obj2,key): walk(obj2); walk(key);
                default:
            }
        }
        walk(body);
        return found;
    }
}

#end
