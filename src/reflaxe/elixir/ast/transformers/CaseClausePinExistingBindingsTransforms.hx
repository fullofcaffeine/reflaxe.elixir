package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * CaseClausePinExistingBindingsTransforms
 *
 * WHAT
 * - Pins variables in case clause patterns when they match an existing binding
 *   in the current function/block scope.
 *
 * WHY
 * - In Elixir, reusing a name in a pattern creates a new binding unless pinned (^name).
 *   When Haxe code intends to match an existing value, we must emit a pin to avoid
 *   accidental shadowing and incorrect matches.
 *
 * HOW
 * - For each function body (EDef → EBlock), scan statements in order, tracking
 *   declared names from assignments and prior function arguments.
 * - When encountering a case expression, rewrite its clause patterns so that any
 *   PVar(name) whose name exists in the declared set becomes PPin(PVar(name)).
 * - Scope-based only, no app-specific heuristics.
 *
 * EXAMPLES
 *   before (shadowing):
 *     val = 10
 *     case val do
 *       val -> :same
 *       _ -> :other
 *     end
 *   after (pinned):
 *     val = 10
 *     case val do
 *       ^val -> :same
 *       _ -> :other
 *     end
 */
class CaseClausePinExistingBindingsTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          var declared:Map<String,Bool> = new Map();
          // Seed with function arg names
          for (p in args) collectPatternDecls(p, declared);
          var newBody = rewriteBody(body, declared);
          makeASTWithMeta(EDef(name, args, guards, newBody), n.metadata, n.pos);
        default:
          n;
      };
    });
  }

  static function rewriteBody(body: ElixirAST, declared: Map<String,Bool>): ElixirAST {
    return switch (body.def) {
      case EBlock(stmts):
        var out:Array<ElixirAST> = [];
        for (stmt in stmts) {
          var s = stmt;
          switch (s.def) {
            case ECase(expr, clauses):
              var rewrittenClauses = [];
              for (cl in clauses) {
                var pat = pinPatternIfDeclared(cl.pattern, declared);
                rewrittenClauses.push({ pattern: pat, guard: cl.guard, body: cl.body });
              }
              s = makeASTWithMeta(ECase(expr, rewrittenClauses), s.metadata, s.pos);
            case EWith(clauses, doBlock, elseBlock):
              var rewrittenWithClauses = [];
              for (wc in clauses) {
                var pat = pinPatternIfDeclared(wc.pattern, declared);
                rewrittenWithClauses.push({ pattern: pat, expr: wc.expr });
              }
              var newDo = rewriteBody(doBlock, declared);
              var newElse = elseBlock != null ? rewriteBody(elseBlock, declared) : null;
              s = makeASTWithMeta(EWith(rewrittenWithClauses, newDo, newElse), s.metadata, s.pos);
            case EBinary(Match, left, _):
              // Collect names introduced by assignment
              collectPatternDeclsFromLeft(left, declared);
            case EMatch(pat, _):
              collectPatternDecls(pat, declared);
            default:
          }
          out.push(s);
        }
        makeASTWithMeta(EBlock(out), body.metadata, body.pos);
      default:
        body;
    }
  }

  static function collectPatternDeclsFromLeft(left: ElixirAST, declared: Map<String,Bool>):Void {
    switch (left.def) {
      case EVar(name): declared.set(name, true);
      default:
    }
  }

  static function collectPatternDecls(p: EPattern, declared: Map<String,Bool>):Void {
    switch (p) {
      case PVar(name): declared.set(name, true);
      case PTuple(ps) | PList(ps): for (pp in ps) collectPatternDecls(pp, declared);
      case PCons(h, t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
      case PPin(inner): collectPatternDecls(inner, declared);
      default:
    }
  }

  static function pinPatternIfDeclared(p: EPattern, declared: Map<String,Bool>): EPattern {
    return switch (p) {
      case PVar(name) if (declared.exists(name)):
        PPin(PVar(name));
      case PTuple(ps): PTuple([for (pp in ps) pinPatternIfDeclared(pp, declared)]);
      case PList(ps): PList([for (pp in ps) pinPatternIfDeclared(pp, declared)]);
      case PCons(h, t): PCons(pinPatternIfDeclared(h, declared), pinPatternIfDeclared(t, declared));
      case PMap(kvs): PMap([for (kv in kvs) { key: kv.key, value: pinPatternIfDeclared(kv.value, declared) }]);
      case PStruct(mod, fs): PStruct(mod, [for (f in fs) { key: f.key, value: pinPatternIfDeclared(f.value, declared) }]);
      case PPin(inner): PPin(pinPatternIfDeclared(inner, declared));
      default: p;
    }
  }
}

#end
