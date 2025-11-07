package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

 /**
  * EctoRequireHoistTransforms
  *
  * WHAT
 * - Hoists any `require Ecto.Query` statements found inside function bodies
 *   to the module top and removes the in-body duplicates. Ensures a single,
 *   idiomatic `require Ecto.Query` per module.
 *
 * WHY
 * - Local insertion may be introduced by late safety passes; tests and idiomatic
 *   Elixir often prefer module-level require.
 *
  * HOW
  * - For EModule/EDefmodule: detect presence of in-body require statements.
  *   If found and module-level require missing, insert at top; remove all in-body
  *   require occurrences.
  *
  * EXAMPLES
  * Haxe:
  *   Ecto.Query.where(users, function(t) return t.age > 10);
  * Elixir (before):
  *   defmodule App.Users do
  *     def list(users) do
  *       require Ecto.Query
  *       Ecto.Query.where(users, [t], t.age > 10)
  *     end
  *   end
  * Elixir (after):
  *   defmodule App.Users do
  *     require Ecto.Query
  *     def list(users) do
  *       Ecto.Query.where(users, [t], t.age > 10)
  *     end
  *   end
  */
class EctoRequireHoistTransforms {
    static function stripInBodyRequires(body:Array<ElixirAST>):Array<ElixirAST> {
        var out:Array<ElixirAST> = [];
        for (b in body) {
            switch (b.def) {
                case EDef(name, args, guards, inner):
                    var newInner = switch (inner.def) {
                        case EBlock(ss): makeAST( EBlock([for (s in ss) switch (s.def) { case ERequire(mod, _) if (mod == "Ecto.Query"): null; default: s; }].filter(x -> x != null)) );
                        case EDo(ss2): makeAST( EDo([for (s in ss2) switch (s.def) { case ERequire(mod, _) if (mod == "Ecto.Query"): null; default: s; }].filter(x -> x != null)) );
                        default: inner;
                    };
                    out.push(makeAST(EDef(name, args, guards, newInner)));
                case EDefp(privateName, privateArgs, privateGuards, inner):
                    var newInner = switch (inner.def) {
                        case EBlock(ss3): makeAST( EBlock([for (s in ss3) switch (s.def) { case ERequire(mod, _) if (mod == "Ecto.Query"): null; default: s; }].filter(x -> x != null)) );
                        case EDo(ss4): makeAST( EDo([for (s in ss4) switch (s.def) { case ERequire(mod, _) if (mod == "Ecto.Query"): null; default: s; }].filter(x -> x != null)) );
                        default: inner;
                    };
                    out.push(makeAST(EDefp(privateName, privateArgs, privateGuards, newInner)));
                default:
                    out.push(b);
            }
        }
        return out;
    }

    static function hasModuleLevelRequire(body:Array<ElixirAST>):Bool {
        for (b in body) switch (b.def) { case ERequire(mod, _) if (mod == "Ecto.Query"): return true; default: }
        return false;
    }
    static function bodyContainsInBodyRequire(body:Array<ElixirAST>):Bool {
        var found = false;
        for (b in body) if (!found) {
            ElixirASTTransformer.transformNode(b, function(x:ElixirAST):ElixirAST {
                if (found) return x;
                switch (x.def) {
                    case ERequire(mod, _) if (mod == "Ecto.Query"): found = true; return x;
                    default: return x;
                }
            });
        }
        return found;
    }

    public static function transformPass(ast: ElixirAST): ElixirAST {
        return ElixirASTTransformer.transformNode(ast, function(n:ElixirAST):ElixirAST {
            return switch (n.def) {
                case EModule(name, attrs, body):
                    var needsHoist = bodyContainsInBodyRequire(body);
                    if (!needsHoist) return n;
                    var newBody = stripInBodyRequires(body);
                    if (!hasModuleLevelRequire(newBody)) newBody = [makeAST(ERequire("Ecto.Query", null))].concat(newBody);
                    makeASTWithMeta(EModule(name, attrs, newBody), n.metadata, n.pos);
                case EDefmodule(name, doBlock):
                    var stmts:Array<ElixirAST> = switch (doBlock.def) { case EBlock(ss): ss; case EDo(ss2): ss2; default: [doBlock]; };
                    var needsHoist2 = bodyContainsInBodyRequire(stmts);
                    if (!needsHoist2) return n;
                    var newStmts = stripInBodyRequires(stmts);
                    if (!hasModuleLevelRequire(newStmts)) newStmts = [makeAST(ERequire("Ecto.Query", null))].concat(newStmts);
                    var newDo: ElixirAST = switch (doBlock.def) {
                        case EBlock(_): makeASTWithMeta(EBlock(newStmts), doBlock.metadata, doBlock.pos);
                        case EDo(_): makeASTWithMeta(EDo(newStmts), doBlock.metadata, doBlock.pos);
                        default: doBlock;
                    };
                    makeASTWithMeta(EDefmodule(name, newDo), n.metadata, n.pos);
                default:
                    n;
            }
        });
    }
}

#end
