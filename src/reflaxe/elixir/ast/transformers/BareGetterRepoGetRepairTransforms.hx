package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * BareGetterRepoGetRepairTransforms
 *
 * WHAT
 * - Repairs functions whose body is a bare variable (e.g., `def get_user(id), do: user`) in modules
 *   that use an Ecto Repo by rewriting the body to `Repo.get(:var, first_param)`.
 *
 * WHY
 * - Some upstream rewrites can drop the binding before a getter and leave a bare return var, which
 *   is undefined. If the module uses a Repo and the function returns a single bare variable, the
 *   intended shape is almost certainly a simple Repo.get by id.
 *
 * HOW
 * - For EModule/EDefmodule bodies, detect presence of a Repo module (any call on a module ending in ".Repo" or "Repo").
 * - For each def/defp:
 *   - If body is EVar(v) or EBlock([EVar(v)]), and v is not declared in the body, rewrite to RepoMod.get(:v, firstParam).
 * - Function-name agnostic; shape- and API-based only.
 */
class BareGetterRepoGetRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var repoMod = detectRepoMod(body);
                    if (repoMod == null) {
                        var derived = deriveRepoVarFromModuleName(name);
                        if (derived != null) repoMod = makeAST(EVar(derived));
                    }
                    if (repoMod == null) return n;
                    var newBody = [for (b in body) rewriteDefs(b, repoMod)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var stmts = switch (doBlock.def) { case EBlock(ss): ss; default: [doBlock]; };
                    var repoMod2 = detectRepoMod(stmts);
                    if (repoMod2 == null) {
                        var derived2 = deriveRepoVarFromModuleName(name);
                        if (derived2 != null) repoMod2 = makeAST(EVar(derived2));
                    }
                    if (repoMod2 == null) return n;
                    var rewritten = rewriteDefs(doBlock, repoMod2);
                    makeASTWithMeta(EDefmodule(name, rewritten), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function deriveRepoVarFromModuleName(moduleName: String): Null<String> {
        if (moduleName == null) return null;
        var dot = moduleName.indexOf(".");
        var app = dot > 0 ? moduleName.substr(0, dot) : null;
        if (app == null || app.length == 0) return null;
        return app + ".Repo";
    }

    static function detectRepoMod(stmts: Array<ElixirAST>): Null<ElixirAST> {
        var found: Null<ElixirAST> = null;
        function scan(x: ElixirAST): Void {
            if (found != null || x == null || x.def == null) return;
            switch (x.def) {
                case ERemoteCall(mod, _, args):
                    switch (mod.def) {
                        case EVar(m) if (m != null && (StringTools.endsWith(m, ".Repo") || m == "Repo")):
                            found = mod;
                        default:
                    }
                    if (found == null && args != null) for (a in args) scan(a);
                case EBlock(ss): for (s in ss) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(t,_,as):
                    if (t != null) scan(t);
                    if (as != null) for (a in as) scan(a);
                case EFn(clauses): for (cl in clauses) scan(cl.body);
                default:
            }
        }
        for (s in stmts) scan(s);
        return found;
    }

    static function rewriteDefs(node: ElixirAST, repoMod: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    // Do not rewrite canonical Ecto changeset builders
                    if (name == "changeset") return n;
                    var newBody = rewriteBody(body, params, repoMod);
                    makeASTWithMeta(EDef(name, params, guards, newBody), n.metadata, n.pos);
                case EDefp(name, params, guards, body):
                    if (name == "changeset") return n;
                    var newBodyp = rewriteBody(body, params, repoMod);
                    makeASTWithMeta(EDefp(name, params, guards, newBodyp), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteBody(body: ElixirAST, params: Array<EPattern>, repoMod: ElixirAST): ElixirAST {
        var bareVar: Null<String> = null;
        switch (body.def) {
            case EVar(v): bareVar = v;
            case EBlock(ss) if (ss.length == 1):
                switch (ss[0].def) { case EVar(v2): bareVar = v2; default: }
            default:
        }
        if (bareVar == null) return body;
        // If the bare var is a function parameter, do not rewrite.
        if (isParamName(params, bareVar)) return body;
        // If the bare var is declared inside the body, not our case either.
        if (declaresVar(body, bareVar)) return body;
        var firstParamName: String = deriveFirstParamName(params);
        if (firstParamName == null) firstParamName = "id";
        var call = makeASTWithMeta(ERemoteCall(repoMod, "get", [ makeAST(EAtom(bareVar.toLowerCase())), makeAST(EVar(firstParamName)) ]), body.metadata, body.pos);
        return call;
    }

    static function isParamName(params: Array<EPattern>, name: String): Bool {
        if (params == null) return false;
        for (p in params) if (patternDeclares(p, name)) return true;
        return false;
    }

    static function declaresVar(b: ElixirAST, name: String): Bool {
        var found = false;
        function walk(n: ElixirAST): Void {
            if (found || n == null || n.def == null) return;
            switch (n.def) {
                case EMatch(p, _): if (patternDeclares(p, name)) { found = true; return; }
                case EBinary(Match, lhs, _): if (lhsDeclares(lhs, name)) { found = true; return; }
                case EBlock(ss): for (s in ss) walk(s);
                case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
                case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
                default:
            }
        }
        walk(b);
        return found;
    }

    static function patternDeclares(p: EPattern, name: String): Bool {
        return switch (p) {
            case PVar(n) if (n == name): true;
            case PTuple(es): for (e in es) if (patternDeclares(e, name)) return true; false;
            case PList(es): for (e in es) if (patternDeclares(e, name)) return true; false;
            case PCons(h, t): patternDeclares(h, name) || patternDeclares(t, name);
            case PMap(kvs): for (kv in kvs) if (patternDeclares(kv.value, name)) return true; false;
            case PStruct(_, fs): for (f in fs) if (patternDeclares(f.value, name)) return true; false;
            case PPin(inner): patternDeclares(inner, name);
            default: false;
        }
    }

    static function lhsDeclares(lhs: ElixirAST, name: String): Bool {
        return switch (lhs.def) {
            case EVar(v) if (v == name): true;
            case EBinary(Match, l2, r2): lhsDeclares(l2, name) || lhsDeclares(r2, name);
            default: false;
        }
    }

    static function deriveFirstParamName(params: Array<EPattern>): Null<String> {
        if (params == null || params.length == 0) return null;
        return switch (params[0]) {
            case PVar(n): n;
            case PTuple(es) if (es.length > 0):
                switch (es[0]) { case PVar(n2): n2; default: null; }
            default: null;
        }
    }
}

#end
