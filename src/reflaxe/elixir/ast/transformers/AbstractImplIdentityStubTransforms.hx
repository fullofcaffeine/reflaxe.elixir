package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;

/**
 * AbstractImplIdentityStubTransforms
 *
 * WHAT
 * - Repairs empty bodies for trivial abstract-impl stubs in `*_Impl_` modules:
 *   `_new/1` and `from_string/1` become identity functions when their body is empty.
 *
 * WHY
 * - Haxe can emit empty bodies for inline abstract constructors / @:from functions after
 *   inlining + DCE. These stubs are typically never called, but they still compile and can
 *   trigger `--warnings-as-errors` (unused argument) in strict Elixir builds.
 *
 * HOW
 * - Detect `EModule` / `EDefmodule` names ending with `_Impl_`.
 * - For `def _new(arg)` and `def from_string(arg)`, if the body prints empty (empty block,
 *   or only numeric sentinels that the printer elides), replace the body with `arg`.
 *
 * EXAMPLES
 * Elixir (before):
 *   defmodule Atom_Impl_ do
 *     def _new(s) do
 *     end
 *   end
 *
 * Elixir (after):
 *   defmodule Atom_Impl_ do
 *     def _new(s) do
 *       s
 *     end
 *   end
 */
class AbstractImplIdentityStubTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body) if (StringTools.endsWith(name, "_Impl_")):
                    var newBody = [for (b in body) fixStubDef(b)];
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(moduleName, doBlock) if (StringTools.endsWith(moduleName, "_Impl_")):
                    var statements: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(stmts): stmts;
                        case EParen(inner):
                            switch (inner.def) {
                                case EBlock(nestedStatements): nestedStatements;
                                default: [inner];
                            }
                        default: [doBlock];
                    };
                    var fixed = [for (s in statements) fixStubDef(s)];
                    var newDo = makeASTWithMeta(EBlock(fixed), doBlock.metadata, doBlock.pos);
                    makeASTWithMeta(EDefmodule(moduleName, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }

    static function fixStubDef(node: ElixirAST): ElixirAST {
        if (node == null || node.def == null) return node;
        return switch (node.def) {
            case EDef(name, args, guards, body):
                var argName = singleVarArgName(args);
                if (argName != null && isTargetStubName(name) && isPrintedEmpty(body)) {
                    var newBody = makeASTWithMeta(EVar(argName), body.metadata, body.pos);
                    makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
                } else {
                    node;
                }
            default:
                node;
        }
    }

    static function isTargetStubName(name: String): Bool {
        return name == "_new" || name == "from_string" || name == "fromString";
    }

    static function singleVarArgName(args: Array<EPattern>): Null<String> {
        if (args == null || args.length != 1) return null;
        return switch (args[0]) {
            case PVar(v): v;
            default: null;
        }
    }

    /**
     * Mimics ElixirASTPrinter's "empty block prints nothing" behavior.
     *
     * The printer elides:
     * - EBlock([]) entirely (prints "")
     * - Bare numeric sentinels (0/1/0.0 and raw "0"/"1") in statement position
     * - Statements that themselves print empty
     */
    static function isPrintedEmpty(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return true;
        return switch (expr.def) {
            case EBlock(stmts):
                isPrintedEmptyStatements(stmts);
            case EParen(inner):
                isPrintedEmpty(inner);
            case EDo(statements):
                isPrintedEmptyStatements(statements);
            case ERaw(code):
                code == null || StringTools.trim(code).length == 0;
            default:
                false;
        }
    }

    static function isPrintedEmptyStatements(stmts: Array<ElixirAST>): Bool {
        if (stmts == null || stmts.length == 0) return true;
        var filtered = [for (s in stmts) if (!isBareNumericSentinel(s)) s];
        if (filtered.length == 0) return true;
        for (s in filtered) {
            if (!isPrintedEmpty(s)) return false;
        }
        return true;
    }

    static function isBareNumericSentinel(expr: ElixirAST): Bool {
        if (expr == null || expr.def == null) return false;
        return switch (expr.def) {
            case EInteger(v) if (v == 0 || v == 1): true;
            case EFloat(f) if (f == 0.0): true;
            case ERaw(code) if (code != null && (StringTools.trim(code) == "1" || StringTools.trim(code) == "0")): true;
            default: false;
        }
    }
}
#end
