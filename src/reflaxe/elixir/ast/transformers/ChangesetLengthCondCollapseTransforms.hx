package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * ChangesetLengthCondCollapseTransforms
 *
 * WHAT
 * - Collapse verbose cond-trees that guard Ecto.Changeset.validate_length/3
 *   into a single validate_length call using a keyword list built from
 *   Map.get(opts, :key) and filtered to remove nil values.
 *
 * WHY
 * - Builder emits exhaustive conds for combinations of min/max/is presence,
 *   which is noisy and triggers typing warnings (opts.is dot access). Generating
 *   a single keyword list with Map.get and filtering nils is idiomatic and
 *   eliminates dot-access typing issues at the source.
 *
 * HOW
 * - Match assignments of the form `cs = cond do ... end` where at least one arm
 *   calls Ecto.Changeset.validate_length(cs, field, kw) and there is a default
 *   arm returning `cs`. Replace the entire cond with:
 *
 *     if Enum.any?([min: Map.get(opts,:min), max: Map.get(opts,:max), is: Map.get(opts,:is)],
 *                  fn {_, v} -> v != nil end) do
 *       Ecto.Changeset.validate_length(cs, field,
 *         Enum.filter([min: Map.get(opts,:min), max: Map.get(opts,:max), is: Map.get(opts,:is)], fn {_, v} -> v != nil end))
 *     else
 *       cs
 *     end
 *
 * - Field atom normalization and EqNil→is_nil are handled by dedicated passes.
 *
 * EXAMPLES
 * Before:
 *   cs = cond do
 *     not Kernel.is_nil(Map.get(opts, :min)) and not Kernel.is_nil(Map.get(opts, :max)) ->
 *       Ecto.Changeset.validate_length(cs, :title, [min: opts.min, max: opts.max])
 *     true -> cs
 *   end
 * After:
 *   cs = (case Enum.filter([min: Map.get(opts,:min), max: Map.get(opts,:max), is: Map.get(opts,:is)], fn {_, v} -> v != nil end) do
 *     [] -> cs
 *     kw -> Ecto.Changeset.validate_length(cs, :title, kw)
 *   end)
 */
class ChangesetLengthCondCollapseTransforms {
    public static function collapsePass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EMatch(lhs, rhs):
                    var newRhs = collapseCond(rhs);
                    if (newRhs == rhs) n else makeASTWithMeta(EMatch(lhs, newRhs), n.metadata, n.pos);
                case EBinary(Match, left, right):
                    var newRight = collapseCond(right);
                    if (newRight == right) n else makeASTWithMeta(EBinary(Match, left, newRight), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function collapseCond(node: ElixirAST): ElixirAST {
        return switch (node.def) {
            case ECond(clauses):
                // Find any validate_length call and its cs/field args; ensure default returns cs
                var csVar: Null<String> = null;
                var fieldArg: Null<ElixirAST> = null;
                var hasDefaultCs = false;
                for (cl in clauses) {
                    if (cl == null || cl.body == null) continue;
                    switch (cl.body.def) {
                        case ERemoteCall(mod, fn, args) if (isChangesetValidateLength(mod, fn, args)):
                            if (args.length >= 2) {
                                // Extract cs var name (best-effort)
                                switch (args[0].def) {
                                    case EVar(name): csVar = csVar == null ? name : csVar;
                                    default:
                                }
                                fieldArg = fieldArg == null ? args[1] : fieldArg;
                            }
                        default:
                    }
                    // Detect `true -> cs` default arm
                    var isDefault = switch (cl.condition.def) {
                        case EBoolean(true): true;
                        case EAtom(a) if (a == "true"): true;
                        default: false;
                    };
                    if (isDefault) {
                        hasDefaultCs = switch (cl.body.def) {
                            case EVar(v) if (csVar != null && v == csVar): true;
                            default: false;
                        };
                    }
                }
                if (csVar == null || fieldArg == null || !hasDefaultCs) return node; // not our pattern

                // Build keyword list [min: Map.get(opts,:min), max: ..., is: ...]
                inline function kwValue(key:String): ElixirAST {
                    return makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [makeAST(EVar("opts")), makeAST(EAtom(key))]));
                }
                var kw = makeAST(EKeywordList([
                    { key: "min", value: kwValue("min") },
                    { key: "max", value: kwValue("max") },
                    { key: "is",  value: kwValue("is")  }
                ]));
                var pred = makeAST(EFn([{
                    args: [PTuple([PWildcard, PVar("v")])],
                    body: makeAST(EBinary(NotEqual, makeAST(EVar("v")), makeAST(ENil)))
                }]));
                var filtered = makeAST(ERemoteCall(makeAST(EVar("Enum")), "filter", [kw, pred]));

                // Use if to avoid introducing a new binder that may be underscored later
                var nonEmpty = makeAST(EBinary(NotEqual, filtered, makeAST(EList([]))));
                var thenCall = makeAST(ERemoteCall(makeAST(EVar("Ecto.Changeset")), "validate_length", [ makeAST(EVar(csVar)), fieldArg, filtered ]));
                var ifDef: ElixirASTDef = EIf(nonEmpty, thenCall, makeAST(EVar(csVar)));
                makeASTWithMeta(ifDef, node.metadata, node.pos);
            default:
                node;
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
