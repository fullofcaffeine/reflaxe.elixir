package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.ds.StringMap;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NilGuardFieldAccessCaseNarrowTransforms
 *
 * WHAT
 * - Rewrites `if other_cond or is_nil(var) do ... else ... var.field ... end` into
 *   a shape that Elixir can flow-narrow without warnings:
 *     if other_cond do
 *       ...
 *     else
 *       case var do
 *         nil -> ...
 *         %{field: var_field} -> ... var_field ...
 *       end
 *     end
 *
 * WHY
 * - Elixir 1.18+ emits WAE warnings when a variable is inferred as `nil | map` from
 *   initializer bindings (e.g. `var = nil`) and later accessed via `var.field`,
 *   even when guarded by boolean conditions (flow narrowing is limited).
 * - Haxe patterns like:
 *     if (errors.length > 0 || validatedEmail == null) return Error(errors);
 *     return Ok({ email: validatedEmail.email });
 *   should compile cleanly without requiring the user to change source structure.
 *
 * HOW
 * - Match EIf whose condition is `EBinary(Or, otherCond, Kernel.is_nil(var))` (either side).
 * - If the else-branch contains one or more `EField(EVar(var), field)` accesses:
 *   - Collect those field names.
 *   - Build a map pattern `%{field: var_field, ...}` that binds extracted values.
 *   - Replace `var.field` uses in the else-branch with the bound `var_field` variables.
 *   - Replace the else-branch with a `case var do nil -> then; %{...} -> else end`.
 *
 * EXAMPLES
 * Haxe:
 *   if (errors.length > 0 || validatedEmail == null) return Error(errors);
 *   return Ok({ email: validatedEmail.email });
 *
 * Elixir (before):
 *   if length(errors) > 0 or Kernel.is_nil(validated_email),
 *     do: {:error, errors},
 *     else: {:ok, %{email: validated_email.email}}
 *
 * Elixir (after):
 *   if length(errors) > 0 do
 *     {:error, errors}
 *   else
 *     case validated_email do
 *       nil -> {:error, errors}
 *       %{email: validated_email_email} -> {:ok, %{email: validated_email_email}}
 *     end
 *   end
 */
class NilGuardFieldAccessCaseNarrowTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EIf(condition, thenBranch, elseBranch) if (elseBranch != null):
                    var rewritten = rewriteIf(condition, thenBranch, elseBranch, n);
                    rewritten != null ? rewritten : n;
                default:
                    n;
            }
        });
    }

    static function rewriteIf(condition: ElixirAST, thenBranch: ElixirAST, elseBranch: ElixirAST, original: ElixirAST): Null<ElixirAST> {
        var condUnwrapped = unwrapParen(condition);
        var nilInfo = extractNilGuardOr(condUnwrapped);
        if (nilInfo == null) return null;

        var varName = nilInfo.varName;
        var otherCond = nilInfo.otherCond;

        var fieldNames = collectDirectFieldAccesses(elseBranch, varName);
        if (fieldNames.length == 0) return null;

        var fieldToBinder = new StringMap<String>();
        for (f in fieldNames) fieldToBinder.set(f, varName + "_" + f);

        var narrowedElse = replaceFieldAccesses(elseBranch, varName, fieldToBinder);

        var mapPairs: Array<{key: ElixirAST, value: EPattern}> = [];
        for (f2 in fieldNames) {
            mapPairs.push({key: makeAST(EAtom(f2)), value: PVar(fieldToBinder.get(f2))});
        }

        var caseExpr = makeASTWithMeta(
            ECase(makeAST(EVar(varName)), [
                {
                    pattern: PLiteral(makeAST(ENil)),
                    guard: null,
                    body: thenBranch
                },
                {
                    pattern: PMap(mapPairs),
                    guard: null,
                    body: narrowedElse
                }
            ]),
            original.metadata,
            original.pos
        );

        return makeASTWithMeta(EIf(otherCond, thenBranch, caseExpr), original.metadata, original.pos);
    }

    static function unwrapParen(e: ElixirAST): ElixirAST {
        return switch (e.def) {
            case EParen(inner): unwrapParen(inner);
            default: e;
        };
    }

    static function extractNilGuardOr(cond: ElixirAST): Null<{ varName: String, otherCond: ElixirAST }> {
        if (cond == null || cond.def == null) return null;
        return switch (cond.def) {
            case EBinary(Or, left, right):
                var leftVar = extractIsNilVar(left);
                if (leftVar != null) {
                    { varName: leftVar, otherCond: right };
                } else {
                    var rightVar = extractIsNilVar(right);
                    rightVar != null ? { varName: rightVar, otherCond: left } : null;
                }
            default:
                null;
        };
    }

    static function extractIsNilVar(expr: ElixirAST): Null<String> {
        var e = unwrapParen(expr);
        if (e == null || e.def == null) return null;
        var arg: Null<ElixirAST> = null;

        switch (e.def) {
            case ERemoteCall(mod, "is_nil", args) if (args != null && args.length == 1 && isKernel(mod)):
                arg = args[0];
            case ECall(target, "is_nil", args2) if (args2 != null && args2.length == 1 && target != null && isKernel(target)):
                arg = args2[0];
            case ECall(null, "is_nil", args3) if (args3 != null && args3.length == 1):
                // Imported Kernel.is_nil/1
                arg = args3[0];
            default:
        }

        if (arg == null) return null;
        return switch (unwrapParen(arg).def) {
            case EVar(v): v;
            default: null;
        };
    }

    static function isKernel(mod: ElixirAST): Bool {
        if (mod == null || mod.def == null) return false;
        return switch (unwrapParen(mod).def) {
            case EVar("Kernel"): true;
            case EAtom(a):
                var s: String = a;
                s == "Kernel" || s == ":Kernel";
            default:
                false;
        };
    }

    static function collectDirectFieldAccesses(expr: ElixirAST, varName: String): Array<String> {
        var seen = new StringMap<Bool>();
        if (expr == null || expr.def == null) return [];

        ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            switch (n.def) {
                case EField(target, fieldName):
                    var t = unwrapParen(target);
                    switch (t.def) {
                        case EVar(v) if (v == varName):
                            if (!seen.exists(fieldName)) seen.set(fieldName, true);
                        default:
                    }
                default:
            }
            return n;
        });

        var out: Array<String> = [];
        for (k in seen.keys()) out.push(k);
        out.sort(Reflect.compare);
        return out;
    }

    static function replaceFieldAccesses(expr: ElixirAST, varName: String, fieldToBinder: StringMap<String>): ElixirAST {
        return ElixirASTTransformer.transformNode(expr, function(n: ElixirAST): ElixirAST {
            if (n == null || n.def == null) return n;
            return switch (n.def) {
                case EField(target, fieldName):
                    var t = unwrapParen(target);
                    switch (t.def) {
                        case EVar(v) if (v == varName && fieldToBinder.exists(fieldName)):
                            makeASTWithMeta(EVar(fieldToBinder.get(fieldName)), n.metadata, n.pos);
                        default:
                            n;
                    }
                default:
                    n;
            };
        });
    }
}

#end

