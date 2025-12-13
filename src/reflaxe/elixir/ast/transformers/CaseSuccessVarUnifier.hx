package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * CaseSuccessVarUnifier
 *
 * WHAT
 * - Within `case` expressions that match `{:ok, var}`, rewrite references in the
 *   success clause body to consistently use the bound `var` instead of ad-hoc
 *   placeholder names like `record` or `updated_record` that were never declared.
 *
 * WHY
 * - Code paths often broadcast or reuse the newly inserted/updated record but
 *   reference a placeholder name that isn't bound in the success branch. This
 *   causes undefined variable errors. The tuple `{:ok, u}` already provides the
 *   correct variable; we unify to that variable in the clause body.
 *
 * HOW
 * - Find `case ... do` clauses whose pattern is a tuple `{:ok, PVar(v)}`.
 * - In that clause's body, rewrite any references to undefined variables to the
 *   bound success variable `v` when they only appear as simple variable uses.
 *   This avoids relying on app-specific names and generically fixes undefined
 *   local references that clearly intend to use the success value.
 * - Operates only within the success clause; other clauses unchanged.
 *
 * EXAMPLES
 * Elixir before:
 *   case Repo.update(changeset) do
 *     {:ok, u} ->
 *       PubSub.broadcast(:updates, {:updated, updated_record})
 *       update_record_in_list(updated_record, socket)
 *   end
 *
 * Elixir after:
 *   case Repo.update(changeset) do
 *     {:ok, u} ->
 *       PubSub.broadcast(:updates, {:updated, u})
 *       update_record_in_list(u, socket)
 *   end
 */
class CaseSuccessVarUnifier {
    public static function unifySuccessVarPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EDef(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = unifyInBody(body, defined);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                case EDefp(name, args, guards, body):
                    var defined = collectFunctionDefinedVars(args, body);
                    var newBody = unifyInBody(body, defined);
                    makeASTWithMeta(EDefp(name, args, guards, newBody), node.metadata, node.pos);
                default:
                    node;
            }
        });
    }

    static function unifyInBody(body: ElixirAST, funcDefined: Map<String, Bool>): ElixirAST {
        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ECase(expr, clauses):
                    #if debug_success_unifier
                    #end
                    var newClauses = [];
                    for (c in clauses) {
                        var successVar = extractOkVar(c.pattern);
                        #if debug_success_unifier
                        #end
                        if (successVar != null) {
                            // Promote underscore binder when body uses the trimmed name
                            var pat2 = promoteUnderscoreBinder(c.pattern, c.body);
                            var effectiveVar = extractOkVar(pat2);
                        #if debug_success_unifier
                        #end
                            var newBody = rewritePlaceholders(c.body, effectiveVar, funcDefined);
                            newClauses.push({ pattern: pat2, guard: c.guard, body: newBody });
                        } else newClauses.push(c);
                    }
                    makeASTWithMeta(ECase(expr, newClauses), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function extractOkVar(p: EPattern): Null<String> {
        return switch (p) {
            case PTuple(elements) if (elements.length == 2):
                switch (elements[0]) {
                    case PLiteral(lit) if (isOkAtom(lit)):
                        switch (elements[1]) {
                            case PVar(name): name;
                            default: null;
                        }
                    default: null;
                }
            default: null;
        }
    }

    static inline function isOkAtom(ast: ElixirAST): Bool {
        return switch (ast.def) {
            case EAtom(value): value == ":ok" || value == "ok";
            default: false;
        }
    }

    static function promoteUnderscoreBinder(p: EPattern, body: ElixirAST): EPattern {
        return switch (p) {
            case PTuple(els) if (els.length == 2):
                switch (els[0]) {
                    case PLiteral(l) if (isOkAtom(l)):
                        switch (els[1]) {
                            case PVar(n) if (n != null && n.length > 1 && n.charAt(0) == '_'):
                                var trimmed = n.substr(1);
                                if (bodyUsesName(body, trimmed)) PTuple([els[0], PVar(trimmed)]) else p;
                            default: p;
                        }
                    default: p;
                }
            default: p;
        }
    }

    static function bodyUsesName(body: ElixirAST, name: String): Bool {
        var used = false;
        ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            switch (n.def) {
                case EVar(v) if (v == name): used = true;
                default:
            }
            return n;
        });
        return used;
    }

    static function rewritePlaceholders(body: ElixirAST, successVar: String, funcDefined: Map<String, Bool>): ElixirAST {
        // Collect declared names inside this clause body
        var declared = new Map<String, Bool>();
        var referenced = new Map<String, Bool>();
        reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
            switch (n.def) {
                case EMatch(p, _): collectPatternDecls(p, declared);
                case EBinary(Match, left, _): collectLhsDecls(left, declared);
                case EVar(v): referenced.set(v, true);
                default:
            }
        });

        // Undefined references in body that are simple vars
        var undefined = [for (k in referenced.keys()) if (!declared.exists(k) && !funcDefined.exists(k)) k];
        #if debug_success_unifier
        if (undefined.length > 0) {
        }
        #end
        if (undefined.length == 0) return body;

        return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EVar(name) if (!declared.exists(name) && !funcDefined.exists(name)):
                    // Replace undefined local with successVar
                    makeASTWithMeta(EVar(successVar), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collectPatternDecls(p: EPattern, declared: Map<String, Bool>): Void {
        switch (p) {
            case PVar(n): declared.set(n, true);
            case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, declared);
            case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
            case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
            case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
            case PPin(inner): collectPatternDecls(inner, declared);
            default:
        }
    }

    static function collectLhsDecls(lhs: ElixirAST, declared: Map<String, Bool>): Void {
        switch (lhs.def) {
            case EVar(n): declared.set(n, true);
            case EBinary(Match, l2, r2):
                collectLhsDecls(l2, declared);
                collectLhsDecls(r2, declared);
            default:
        }
    }

    static function collectFunctionDefinedVars(args: Array<EPattern>, body: ElixirAST): Map<String, Bool> {
        var vars = new Map<String, Bool>();
        for (a in args) collectPatternDecls(a, vars);
        reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
            switch (n.def) {
                case EMatch(p, _): collectPatternDecls(p, vars);
                case EBinary(Match, l, _): collectLhsDecls(l, vars);
                default:
            }
        });
        return vars;
    }
}

#end
