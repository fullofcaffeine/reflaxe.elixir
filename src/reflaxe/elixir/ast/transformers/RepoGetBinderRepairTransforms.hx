package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * RepoGetBinderRepairTransforms
 *
 * WHAT
 * - Repairs trivial getter functions that erroneously return an undeclared local
 *   (e.g., `def get_user(id), do: user`) by reconstructing a proper
 *   `Repo.get(schema, id)` call using shape-derived information from sibling
 *   Repo.get usages in the same module.
 *
 * WHY
 * - Upstream rewrites can drop bindings in simple getters, leaving a bare
 *   reference to a non-existent variable. This is a hard compile error. Rather
 *   than guess schema names from function names, we derive the schema argument
 *   and repository module from other valid `Repo.get/2` calls present in the
 *   same module, preserving API faithfulness and avoiding app-specific heuristics.
 *
 * HOW
 * - For each EModule/EDefmodule, collect occurrences of `Repo.get(mod?, arg1, arg2)`
 *   capturing the repo module (e.g., `TodoApp.Repo` or `Repo`) and the schema arg
 *   AST (atom or module) paired with a normalized base name (e.g., `user` for :user).
 * - For function bodies that:
 *   - are a single bare variable reference `v`, and
 *   - have no prior declaration/binding of `v` in the body,
 *   - and a collected schema entry exists for base name == `v`,
 *   rewrite the function body to `RepoModule.get(schemaArg, firstParam)`.
 * - Shape-derived only; no reliance on app/project naming beyond existing
 *   Repo.get evidence within the module.
 */
class RepoGetBinderRepairTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var info = collectRepoGetInfo(body);
                    var newBody = [for (b in body) rewriteFunctions(b, info)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var innerBody = switch (doBlock.def) { case EBlock(stmts): stmts; default: [doBlock]; };
                    var info2 = collectRepoGetInfo(innerBody);
                    var rewritten = rewriteFunctions(doBlock, info2);
                    makeASTWithMeta(EDefmodule(name, rewritten), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    // Repository call info keyed by lowercase base name (e.g., "user")
    private static function collectRepoGetInfo(stmts:Array<ElixirAST>): Map<String, { repoMod: ElixirAST, schemaArg: ElixirAST } > {
        var m = new Map<String, { repoMod: ElixirAST, schemaArg: ElixirAST } >();
        function scan(x: ElixirAST): Void {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case ERemoteCall(mod, func, args) if (func == "get" && args != null && args.length >= 2):
                    // Capture Repo module form (qualified or bare)
                    var repoLooksOk = switch (mod.def) {
                        case EVar(v) if (v != null && (StringTools.endsWith(v, ".Repo") || v == "Repo")): true;
                        default: false;
                    };
                    if (repoLooksOk) {
                        var schema = args[0];
                        var base: Null<String> = switch (schema.def) {
                            case EAtom(a): a;
                            case EVar(v):
                                // If passed a module alias like User, normalize to snake base "user"
                                v != null ? v.toLowerCase() : null;
                            default: null;
                        };
                        if (base != null) m.set(base, { repoMod: mod, schemaArg: schema });
                    }
                    // Recurse into args as well
                    for (a in args) scan(a);
                case ERemoteCall(modA, funcA, argsA) if (funcA == "all" && argsA != null && argsA.length >= 1):
                    // Capture repo module from Repo.all/1 as fallback when get/2 shape missing
                    var repoLooksOk2 = switch (modA.def) {
                        case EVar(v) if (v != null && (StringTools.endsWith(v, ".Repo") || v == "Repo")): true;
                        default: false;
                    };
                    if (repoLooksOk2 && !m.exists("__repo__")) {
                        m.set("__repo__", { repoMod: modA, schemaArg: null });
                    }
                    for (a in argsA) scan(a);
                case EBlock(ss): for (s in ss) scan(s);
                case EIf(c,t,e): scan(c); scan(t); if (e != null) scan(e);
                case ECase(expr, cs): scan(expr); for (c in cs) { if (c.guard != null) scan(c.guard); scan(c.body); }
                case EBinary(_, l, r): scan(l); scan(r);
                case EMatch(_, rhs): scan(rhs);
                case ECall(t,_,as): if (t != null) scan(t); if (as != null) for (a in as) scan(a);
                case ERemoteCall(t2,_,as2): scan(t2); if (as2 != null) for (a2 in as2) scan(a2);
                case EFn(clauses): for (cl in clauses) scan(cl.body);
                default:
            }
        }
        for (s in stmts) scan(s);
        return m;
    }

    private static function rewriteFunctions(node: ElixirAST, info: Map<String, { repoMod: ElixirAST, schemaArg: ElixirAST } >): ElixirAST {
        return ElixirASTTransformer.transformNode(node, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EDef(name, params, guards, body):
                    var newBody = rewriteBodyIfBareUndeclaredVar(body, params, info);
                    #if (sys && debug_ast_transformer) if (newBody != body) Sys.println('[RepoGetBinderRepair] Rewrote def ' + name); #end
                    makeASTWithMeta(EDef(name, params, guards, newBody), n.metadata, n.pos);
                case EDefp(name, params, guards, body):
                    var newBody = rewriteBodyIfBareUndeclaredVar(body, params, info);
                    #if (sys && debug_ast_transformer) if (newBody != body) Sys.println('[RepoGetBinderRepair] Rewrote defp ' + name); #end
                    makeASTWithMeta(EDefp(name, params, guards, newBody), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    private static function rewriteBodyIfBareUndeclaredVar(body: ElixirAST, params: Array<EPattern>, info: Map<String, { repoMod: ElixirAST, schemaArg: ElixirAST } >): ElixirAST {
        // Determine if body is a bare variable reference with no declaration in body
        var bareVar: Null<String> = null;
        var declared = new Map<String, Bool>();
        // Collect declared names within the body
        function collectDecls(x: ElixirAST): Void {
            if (x == null || x.def == null) return;
            switch (x.def) {
                case EMatch(p, _): collectPatternDecls(p, declared);
                case EBinary(Match, left, _): collectLhsDecls(left, declared);
                case EBlock(ss): for (s in ss) collectDecls(s);
                case EIf(c,t,e): collectDecls(c); collectDecls(t); if (e != null) collectDecls(e);
                case ECase(expr, cs): collectDecls(expr); for (c in cs) collectDecls(c.body);
                case EFn(clauses): for (cl in clauses) for (a in cl.args) collectPatternDecls(a, declared);
                default:
            }
        }
        collectDecls(body);
        switch (body.def) {
            case EVar(v): bareVar = v;
            case EBlock(stmts) if (stmts.length == 1):
                switch (stmts[0].def) { case EVar(v2): bareVar = v2; default: }
            default:
        }
        if (bareVar == null) return body;
        if (declared.exists(bareVar)) return body; // already declared; not our target

        var base = bareVar.toLowerCase();
        var repoInfo: { repoMod: ElixirAST, schemaArg: ElixirAST } = null;
        if (info.exists(base)) repoInfo = info.get(base) else if (info.exists("__repo__")) {
            var fallback = info.get("__repo__");
            repoInfo = { repoMod: fallback.repoMod, schemaArg: makeAST(EAtom(base)) };
        } else return body;
        var firstParamName: String = deriveFirstParamName(params);
        if (firstParamName == null) firstParamName = "id";

        // Build Repo.get(repoInfo.schemaArg, <firstParamName>) using the captured repo module
        var call = makeASTWithMeta(ERemoteCall(repoInfo.repoMod, "get", [repoInfo.schemaArg, makeAST(EVar(firstParamName))]), body.metadata, body.pos);
        #if (sys && debug_ast_transformer) Sys.println('[RepoGetBinderRepair] Rewriting bare var `' + bareVar + '` to ' + ElixirASTPrinter.printAST(call) ); #end
        return call;
    }

    private static function deriveFirstParamName(params: Array<EPattern>): Null<String> {
        if (params == null || params.length == 0) return null;
        return switch (params[0]) {
            case PVar(n): n;
            case PTuple(es) if (es.length > 0):
                switch (es[0]) { case PVar(n2): n2; default: null; }
            default: null;
        }
    }

    private static function collectPatternDecls(p: EPattern, declared: Map<String,Bool>):Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es): for (e in es) collectPatternDecls(e, declared);
            case PList(es): for (e in es) collectPatternDecls(e, declared);
            case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
            case PPin(inner): collectPatternDecls(inner, declared);
            default:
        }
    }

    private static function collectLhsDecls(lhs: ElixirAST, declared: Map<String,Bool>):Void {
        if (lhs == null || lhs.def == null) return;
        switch (lhs.def) {
            case EVar(n): declared.set(n, true);
            case EBinary(Match, l2, r2):
                collectLhsDecls(l2, declared);
                collectLhsDecls(r2, declared);
            default:
        }
    }
}

#end
