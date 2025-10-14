package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.analyzers.VariableUsageCollector;

/**
 * ControllerEnsureConnParamTransforms
 *
 * WHAT
 * - Ensures Phoenix controller actions have a `conn` parameter when the body
 *   references `conn` but no parameter named `conn` exists.
 *
 * WHY
 * - Generated controller actions may omit `conn` in the parameter list while
 *   the body uses it (Plug.Conn/Phoenix.Controller calls), causing undefined
 *   variable errors under warnings-as-errors.
 *
 * HOW
 * - For modules whose name ends with "Controller" (shape-based) or have
 *   metadata isPhoenixWeb == true and contain Plug/Phoenix controller calls,
 *   rewrite function definitions so that `conn` is prepended to the parameter list
 *   when the body references `conn` and no existing parameter is named `conn`.
 */
class ControllerEnsureConnParamTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var isController = name != null && name.indexOf("Controller") != -1;
                    if (!isController) return n;
                    var newBody = [for (b in body) ensureConnInDefs(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name2, doBlock):
                    var isController2 = name2 != null && name2.indexOf("Controller") != -1;
                    if (!isController2) return n;
                    var nb = ensureConnInDefs(doBlock);
                    makeASTWithMeta(EDefmodule(name2, nb), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function ensureConnInDefs(node: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(x: ElixirAST): ElixirAST {
            return switch (x.def) {
                case EDef(fname, args, guards, body):
                    #if debug_controller_conn
                    inline function patStr(p:EPattern):String return switch(p){ case PVar(nm): nm; case PAlias(nm,_): nm; default: Std.string(p);} ;
                    var beforeArgs = args != null ? [for (a in args) patStr(a)].join(',') : '';
                    trace('[ControllerEnsureConnParam] visit def ' + fname + '(' + beforeArgs + ')');
                    #end
                    var needsConn = VariableUsageCollector.usedInFunctionScope(body, "conn");
                    var hasConn = false;
                    var hadUnderscored = false;
                    if (args != null) for (a in args) switch (a) { case PVar(nm) if (nm == "conn"): hasConn = true; case PVar(nm2) if (nm2 == "_conn"): hadUnderscored = true; default: }
                    if (hadUnderscored && !hasConn) {
                        // Unconditionally rename _conn -> conn (final shape); Phoenix underscore passes have already run
                        var newArgs:Array<EPattern> = [];
                        for (a in args) switch (a) { case PVar(n) if (n == "_conn"): newArgs.push(PVar("conn")); case PAlias(nm, pat) if (nm == "_conn"): newArgs.push(PAlias("conn", pat)); default: newArgs.push(a); }
                        #if debug_controller_conn
                        var afterArgs = [for (a in newArgs) patStr(a)].join(',');
                        trace('[ControllerEnsureConnParam] ' + fname + '(' + beforeArgs + ') -> (' + afterArgs + ')');
                        #end
                        makeASTWithMeta(EDef(fname, newArgs, guards, body), x.metadata, x.pos);
                    } else if (needsConn && !hasConn) {
                        var newArgs2:Array<EPattern> = args != null ? args.copy() : [];
                        newArgs2.unshift(PVar("conn"));
                        makeASTWithMeta(EDef(fname, newArgs2, guards, body), x.metadata, x.pos);
                    } else x;
                case EDefp(fname2, args2, guards2, body2):
                    var needsConn2 = VariableUsageCollector.usedInFunctionScope(body2, "conn");
                    var hasConn2 = false;
                    var hadUnderscored2 = false;
                    if (args2 != null) for (a2 in args2) switch (a2) { case PVar(nm2) if (nm2 == "conn"): hasConn2 = true; case PVar(nm3) if (nm3 == "_conn"): hadUnderscored2 = true; default: }
                    if (hadUnderscored2 && !hasConn2) {
                        var newArgs3:Array<EPattern> = [];
                        for (a3 in args2) switch (a3) { case PVar(nn) if (nn == "_conn"): newArgs3.push(PVar("conn")); case PAlias(nn2, pat2) if (nn2 == "_conn"): newArgs3.push(PAlias("conn", pat2)); default: newArgs3.push(a3); }
                        makeASTWithMeta(EDefp(fname2, newArgs3, guards2, body2), x.metadata, x.pos);
                    } else if (needsConn2 && !hasConn2) {
                        var newArgs2:Array<EPattern> = args2 != null ? args2.copy() : [];
                        newArgs2.unshift(PVar("conn"));
                        makeASTWithMeta(EDefp(fname2, newArgs2, guards2, body2), x.metadata, x.pos);
                    } else x;
                default:
                    x;
            }
        });
    }
}

#end
