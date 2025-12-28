package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * KernelImportExceptThenTransforms
 *
 * WHAT
 * - When a module defines local functions that conflict with auto-imported Kernel functions
 *   (currently: `then/2`, `to_string/1`, `length/1`), inject:
 *     import Kernel, except: [...], warn: false
 *   to avoid compile errors (and to avoid "unused import" warnings).
 *
 * WHY
 * - Elixir auto-imports `Kernel`, and imported functions can conflict with local definitions:
 *     ** (CompileError) imported Kernel.to_string/1 conflicts with local function
 * - Haxe code frequently defines idiomatic helpers like `toString()` and `length()` which
 *   intentionally map to `to_string/1` and `length/1` in Elixir.
 *
 * HOW
 * - Shape-based detection: scan each EModule/EDefmodule for local def/defp/defmacro definitions
 *   of known conflicting names/arity.
 * - If any are present, ensure there is an `import Kernel, except: [...], warn: false` directive:
 *   - If an existing `import Kernel` has an `except` list, append missing entries.
 *   - Always set `warn: false` on the injected/updated Kernel import to avoid "unused import" warnings.
 *   - Otherwise, insert a new import directive near the top of the module body, after any
 *     module docs/attributes and other module directives (alias/import/require/use).
 *
 * EXAMPLES
 * Elixir (before):
 *   defmodule OptionTools do
 *     def then(option, f), do: ...
 *   end
 *
 * Elixir (after):
 *   defmodule OptionTools do
 *     import Kernel, except: [then: 2], warn: false
 *     def then(option, f), do: ...
 *   end
 */
class KernelImportExceptThenTransforms {
    public static function pass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, attrs, body):
                    var updatedBody = ensureKernelThenExcept(body);
                    updatedBody == body
                        ? node
                        : makeASTWithMeta(EModule(name, attrs, updatedBody), node.metadata, node.pos);

                case EDefmodule(name, doBlock):
                    // Some compiler paths still use EDefmodule; normalize by treating the doBlock as a statement list.
                    var stmts: Array<ElixirAST> = switch (doBlock.def) {
                        case EBlock(ss): ss;
                        default: [doBlock];
                    };
                    var updatedStmts = ensureKernelThenExcept(stmts);
                    if (updatedStmts == stmts) {
                        node;
                    } else {
                        makeASTWithMeta(EDefmodule(name, makeAST(EBlock(updatedStmts))), node.metadata, node.pos);
                    }

                default:
                    node;
            }
        });
    }

    static function ensureKernelThenExcept(body: Array<ElixirAST>): Array<ElixirAST> {
        if (body == null || body.length == 0) return body;

        var requiredExcept = collectKernelConflictExcepts(body);
        if (requiredExcept.length == 0) return body;

        // If there's already a Kernel import, prefer extending it.
        for (i in 0...body.length) {
            var stmt = body[i];
            switch (stmt.def) {
                case EImport(module, only, except, warn) if (module == "Kernel"):
                    // If Kernel is imported with `only`, we can't safely "except" a single macro/function.
                    // In that case, add a separate except-import instead.
                    if (only != null) break;

                    var updatedExcept = ensureExceptHasAll(except, requiredExcept);
                    // Always set warn: false to avoid unused import warnings.
                    var updatedWarn: Null<Bool> = false;
                    if (updatedExcept == except && warn == updatedWarn) return body;

                    var updated = makeASTWithMeta(EImport("Kernel", null, updatedExcept, updatedWarn), stmt.metadata, stmt.pos);
                    var out = body.copy();
                    out[i] = updated;
                    return out;
                default:
            }
        }

        // Otherwise, insert a new directive near the top.
        var insertAt = 0;
        while (insertAt < body.length && isTopLevelDirectiveOrDoc(body[insertAt])) {
            insertAt++;
        }

        var importNode = makeAST(EImport("Kernel", null, ensureExceptHasAll(null, requiredExcept), false));
        var updatedBody = body.copy();
        updatedBody.insert(insertAt, importNode);
        return updatedBody;
    }

    static function collectKernelConflictExcepts(body: Array<ElixirAST>): Array<EImportOption> {
        var required = new Map<String, Bool>();
        function add(name: String, arity: Int): Void {
            required.set(name + "/" + arity, true);
        }

        for (stmt in body) {
            if (stmt == null || stmt.def == null) continue;
            switch (stmt.def) {
                case EDef(name, args, _, _)
                    | EDefp(name, args, _, _)
                    | EDefmacro(name, args, _, _)
                    | EDefmacrop(name, args, _, _):
                    var arity = args != null ? args.length : 0;
                    switch ([name, arity]) {
                        case ["then", 2]: add("then", 2);
                        case ["to_string", 1]: add("to_string", 1);
                        case ["length", 1]: add("length", 1);
                        default:
                    }
                default:
            }
        }

        var out: Array<EImportOption> = [];
        if (required.exists("then/2")) out.push({ name: "then", arity: 2 });
        if (required.exists("to_string/1")) out.push({ name: "to_string", arity: 1 });
        if (required.exists("length/1")) out.push({ name: "length", arity: 1 });
        return out;
    }

    static function ensureExceptHasAll(except: Null<Array<EImportOption>>, required: Array<EImportOption>): Array<EImportOption> {
        var options: Array<EImportOption> = except != null ? except.copy() : [];
        var changed = false;
        function has(name: String, arity: Int): Bool {
            for (opt in options) {
                if (opt != null && opt.name == name && opt.arity == arity) return true;
            }
            return false;
        }
        for (req in required) {
            if (!has(req.name, req.arity)) {
                options.push(req);
                changed = true;
            }
        }
        return !changed && except != null ? cast except : options;
    }

    static function isTopLevelDirectiveOrDoc(node: ElixirAST): Bool {
        if (node == null || node.def == null) return false;
        return switch (node.def) {
            case EModuledoc(_) | EDoc(_) | ESpec(_) | ETypeDef(_, _) | EModuleAttribute(_, _):
                true;
            case EAlias(_, _) | EImport(_, _, _, _) | ERequire(_, _) | EUse(_, _):
                true;
            default:
                false;
        };
    }
}

#end
