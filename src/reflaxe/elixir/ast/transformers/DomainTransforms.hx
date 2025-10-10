package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer; // for transformNode/transformAST/iterateAST
import reflaxe.elixir.ast.NameUtils;

/**
 * DomainTransforms
 *
 * WHAT
 * - Domain helper shaping that makes implicit struct/params usage explicit and idiomatic.
 * - Pass: domainHelperSignatureShapingPass
 *   - Ensure the primary struct arg (first changeset arg) is exposed by name in the function parameters.
 *   - If body uses `params` and it is not declared, prebind `params = Map.from_struct(struct)` at the top.
 *   - Expose a simple scalar like `priority` when referenced but not declared by renaming a non‑critical arg
 *     or appending it as a parameter.
 *
 * WHY
 * - Reduce cognitive overhead in domain helpers by making data flow explicit and Phoenix‑idiomatic.
 * - Prevent late hygiene passes from performing speculative renames that obscure intent.
 *
 * HOW
 * - Scan function body for `changeset` calls to infer primary struct variable name.
 * - Analyze identifiers used/declared in the body and parameter patterns.
 * - Apply conservative rename/insert logic to surface `structName`, `params`, and `priority` when needed.
 *
 * ORDERING
 * - Runs after controller shaping passes in the transformer registry and before hygiene/usage passes.
 */
class DomainTransforms {
    public static function domainHelperSignatureShapingPass(ast: ElixirAST): ElixirAST {
        inline function isSimpleIdent(n:String):Bool return n != null && ~/^[a-z_][a-z0-9_]*$/.match(n);
        function collectParamBinders(patterns:Array<EPattern>):Array<String> {
            var out:Array<String> = [];
            function visit(p:EPattern):Void {
                switch (p) {
                    case PVar(n): out.push(n);
                    case PTuple(l): for (e in l) visit(e);
                    case PList(l): for (e in l) visit(e);
                    case PCons(h,t): visit(h); visit(t);
                    case PMap(ps): for (kv in ps) visit(kv.value);
                    case PStruct(_, fs): for (f in fs) visit(f.value);
                    case PAlias(n, inner): out.push(n); visit(inner);
                    case PPin(inner): visit(inner);
                    case PBinary(segs): for (s in segs) visit(s.pattern);
                    default:
                }
            }
            if (patterns != null) for (p in patterns) visit(p);
            return out;
        }
        function gatherNamesFromPattern(p:EPattern, acc:Map<String,Bool>):Void {
            switch (p) {
                case PVar(name): acc.set(name, true);
                case PTuple(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PList(el): for (e in el) gatherNamesFromPattern(e, acc);
                case PCons(h,t): gatherNamesFromPattern(h, acc); gatherNamesFromPattern(t, acc);
                case PMap(pairs): for (pair in pairs) gatherNamesFromPattern(pair.value, acc);
                case PStruct(_, fields): for (f in fields) gatherNamesFromPattern(f.value, acc);
                case PAlias(n, inner): acc.set(n, true); gatherNamesFromPattern(inner, acc);
                case PPin(inner): gatherNamesFromPattern(inner, acc);
                case PBinary(segs): for (s in segs) gatherNamesFromPattern(s.pattern, acc);
                default:
            }
        }
        function collectBodyDeclaredLocals(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            switch (node.def) {
                case EMatch(pat, expr): gatherNamesFromPattern(pat, acc); collectBodyDeclaredLocals(expr, acc);
                case EBlock(stmts): for (s in stmts) collectBodyDeclaredLocals(s, acc);
                case EIf(c,t,e): collectBodyDeclaredLocals(c, acc); collectBodyDeclaredLocals(t, acc); if (e != null) collectBodyDeclaredLocals(e, acc);
                case ECase(target, clauses): collectBodyDeclaredLocals(target, acc); for (cl in clauses) collectBodyDeclaredLocals(cl.body, acc);
                case ECond(conds): for (c in conds) collectBodyDeclaredLocals(c.body, acc);
                case ECall(target, _, args): if (target != null) collectBodyDeclaredLocals(target, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case ERemoteCall(mod, _, args): collectBodyDeclaredLocals(mod, acc); for (a in args) collectBodyDeclaredLocals(a, acc);
                case EParen(inner): collectBodyDeclaredLocals(inner, acc);
                default:
            }
        }
        function collectUsed(node:ElixirAST, acc:Map<String,Bool>):Void {
            if (node == null) return;
            ElixirASTTransformer.transformNode(node, function(n) {
                switch (n.def) {
                    case EVar(vn): if (isSimpleIdent(vn)) acc.set(vn, true);
                    default:
                }
                return n;
            });
        }
        function renameCandidateTo(p:EPattern, candidate:String, toName:String):EPattern {
            return switch (p) {
                case PVar(n) if (n == candidate): PVar(toName);
                case PTuple(l): PTuple([for (e in l) renameCandidateTo(e, candidate, toName)]);
                case PList(l): PList([for (e in l) renameCandidateTo(e, candidate, toName)]);
                case PCons(h,t): PCons(renameCandidateTo(h, candidate, toName), renameCandidateTo(t, candidate, toName));
                case PMap(ps): PMap([for (kv in ps) {key: kv.key, value: renameCandidateTo(kv.value, candidate, toName)}]);
                case PStruct(mod, fs): PStruct(mod, [for (f in fs) {key: f.key, value: renameCandidateTo(f.value, candidate, toName)}]);
                case PAlias(n, inner): PAlias(n == candidate ? toName : n, renameCandidateTo(inner, candidate, toName));
                case PPin(inner): PPin(renameCandidateTo(inner, candidate, toName));
                case PBinary(segs): PBinary([for (s in segs) {pattern: renameCandidateTo(s.pattern, candidate, toName), size: s.size, type: s.type, modifiers: s.modifiers}]);
                default: p;
            };
        }
        function findFirstChangesetArgName(node:ElixirAST):Null<String> {
            var found:Null<String> = null;
            if (node == null) return null;
            ElixirASTTransformer.transformNode(node, function(n) {
                if (found != null) return n;
                switch (n.def) {
                    case ERemoteCall(_, fname, args) if (fname == "changeset" && args != null && args.length >= 1):
                        switch (args[0].def) { case EVar(v) if (isSimpleIdent(v)): found = v; default: }
                    case ECall(_, fname2, args2) if (fname2 == "changeset" && args2 != null && args2.length >= 1):
                        switch (args2[0].def) { case EVar(v2) if (isSimpleIdent(v2)): found = v2; default: }
                    default:
                }
                return n;
            });
            return found;
        }

        return ElixirASTTransformer.transformNode(ast, function(node) {
            return switch (node.def) {
                case EDef(name, args, guard, body):
                    var params = collectParamBinders(args);
                    var declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
                    collectBodyDeclaredLocals(body, declared);
                    var used = new Map<String,Bool>(); collectUsed(body, used);

                    var structName = findFirstChangesetArgName(body);
                    var newArgs = args != null ? args.copy() : [];
                    var newBody = body;

                    // Ensure structName as parameter if referenced by changeset and not declared
                    if (structName != null && !declared.exists(structName)) {
                        var candidate:Null<String> = null;
                        for (pname in params) {
                            if (pname != null && pname != structName && pname != "conn" && pname != "socket" && pname != "assigns" && pname != "params") { candidate = pname; break; }
                        }
                        if (candidate != null) {
                            newArgs = [for (a in newArgs) renameCandidateTo(a, candidate, structName)];
                            params = collectParamBinders(newArgs);
                            declared = new Map<String,Bool>(); for (p in params) declared.set(p, true);
                            collectBodyDeclaredLocals(body, declared);
                        } else {
                            newArgs.push(PVar(structName));
                            params = collectParamBinders(newArgs);
                            declared.set(structName, true);
                        }
                    }

                    // If body uses params and it is not declared, prebind from structName when available
                    if (used.exists("params") && !declared.exists("params") && structName != null) {
                        var aliasStmt = makeAST(EMatch(PVar("params"), makeAST(ERemoteCall(makeAST(EVar("Map")), "from_struct", [makeAST(EVar(structName))]))));
                        newBody = switch (body.def) {
                            case EBlock(stmts): makeAST(EBlock([aliasStmt].concat(stmts)));
                            default: makeAST(EBlock([aliasStmt, body]));
                        };
                        declared.set("params", true);
                    }

                    // Avoid app-specific scalar exposures (e.g., "priority").
                    // Domain pass focuses on struct arg exposure and params prebinding only.

                    if (newArgs != args || newBody != body) {
                        makeASTWithMeta(EDef(name, newArgs, guard, newBody), node.metadata, node.pos);
                    } else node;
                default:
                    node;
            };
        });
    }
}

#end
