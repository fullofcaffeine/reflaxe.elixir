package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ValidateLengthOptsAccessRewrite
 *
 * WHAT
 * - In Ecto.Changeset.validate_length/3 calls, convert keyword list values
 *   of the form `opts.min` / `opts.max` / `opts.is` to Map.get(opts, :min) etc.
 *
 * WHY
 * - Dot access on maps causes type warnings in Elixir's dialyzer/typed-ast and
 *   triggers warnings-as-errors in CI. Map.get is idiomatic and warning-free.
 *
 * HOW
 * - Match ERemoteCall(Ecto.Changeset, "validate_length", [cs, field, kw])
 * - Rebuild third argument: traverse keyword pairs and rewrite any values that
 *   access `opts` via field or access into Map.get(opts, :key).
 */
class ValidateLengthOptsAccessRewrite {
    public static function rewritePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case ERemoteCall(mod, fn, args) if (isChangesetValidateLength(mod, fn, args)):
                    var a = args.copy();
                    if (a.length >= 3) {
                        a[2] = rewriteKw(a[2]);
                    }
                    makeASTWithMeta(ERemoteCall(mod, fn, a), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function rewriteKw(arg: ElixirAST): ElixirAST {
        return switch (arg.def) {
            case EKeywordList(pairs):
                var out = [];
                for (p in pairs) {
                    var v = rewriteValue(p.value);
                    out.push({key: p.key, value: v});
                }
                makeAST(EKeywordList(out));
            case ERemoteCall({def: EVar(m)}, f, [listExpr, fun]) if (m == "Enum" && f == "filter"):
                // Recurse into first argument if it is a keyword list
                var newList = rewriteKw(listExpr);
                makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [newList, fun]));
            default:
                arg;
        }
    }

    static function rewriteValue(v: ElixirAST): ElixirAST {
        return switch (v.def) {
            case EField({def: EVar(name)}, fld) if (name == "opts"):
                makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(fld))]));
            case EAccess({def: EVar(name2)}, key) if (name2 == "opts"):
                var atomKey = switch (key.def) { case EAtom(a): a; default: null; };
                if (atomKey != null) makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(atomKey))])) else v;
            default:
                v;
        }
    }

    static inline function isChangesetValidateLength(mod: ElixirAST, fn: String, args: Array<ElixirAST>): Bool {
        if (fn != "validate_length") return false;
        return switch (mod.def) {
            case EVar(name): name != null && (name == "Ecto.Changeset" || name.indexOf("Ecto.Changeset") != -1);
            default: false;
        }
    }
}

#end
