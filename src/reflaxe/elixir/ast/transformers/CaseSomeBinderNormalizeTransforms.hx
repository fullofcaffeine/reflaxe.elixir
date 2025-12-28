package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import StringTools;

/**
 * CaseSomeBinderNormalizeTransforms
 *
 * WHAT
 * - In case clauses that match Option-like tuples `{:some, binder}`, promote
 *   a leading-underscore binder (e.g., `_socket`) to a safe identifier and
 *   rewrite body references accordingly.
 *
 * WHY
 * - Avoids warnings "underscored variable used after being set" when the
 *   underscored binder is referenced in expression context.
 *
 * HOW
 * - For each ECase clause, if the pattern is PTuple([PLiteral(:some|"some"), PVar(name)])
 *   and name starts with `_` and is referenced in the clause body/guard, then:
 *     - Rename pattern binder to `payload` (or trimmed name if safe).
 *     - Replace EVar(old) occurrences in the clause body/guard with the new name.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class CaseSomeBinderNormalizeTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    var currentFunc: Null<String> = null;
    var socketArgName: Null<String> = null;
    function transformBody(body: ElixirAST): ElixirAST {
      return ElixirASTTransformer.transformNode(body, function(n: ElixirAST): ElixirAST {
        return switch (n.def) {
          case ECase(expr, clauses):
            var out:Array<ECaseClause> = [];
            for (cl in clauses) {
              var newCl = cl;
              switch (cl.pattern) {
                case PTuple(parts) if (parts.length == 2):
                  var isSome = false;
                  switch (parts[0]) {
                    case PLiteral(l):
                      isSome = switch (l.def) {
                        case EAtom(a) if (a == ":some" || a == "some"): true;
                        default: false;
                      };
                    default:
                  }
                  if (isSome) switch (parts[1]) {
                    case PVar(nm) if (nm != null):
                      // choose safe name
                      var candidate = (nm.length > 1 && nm.charAt(0) == '_') ? nm.substr(1) : nm;
                      if (candidate == null || candidate == "" || candidate == "socket") candidate = "payload";
                      // rewrite clause body
                      var body2 = cl.body;
                      // Drop leading alias `alias = nm` in block/ do
                      inline function dropAlias(b: ElixirAST): ElixirAST {
                        return switch (b.def) {
                          case EBlock(stmts) if (stmts.length > 0):
                            var rest = stmts.copy();
                            // remove first alias if it matches nm
                            while (rest.length > 0) {
                              var s0 = rest[0];
                              var removed = false;
                              switch (s0.def) {
                                case EBinary(Match, {def: EVar(a)}, {def: EVar(bv)}) if (bv == nm):
                                  rest.shift(); removed = true;
                                case EMatch(PVar(a2), {def: EVar(bv2)}) if (bv2 == nm):
                                  rest.shift(); removed = true;
                                default:
                              }
                              if (!removed) break;
                            }
                            makeASTWithMeta(EBlock(rest), b.metadata, b.pos);
                          case EDo(stmts2) if (stmts2.length > 0):
                            var r2 = stmts2.copy();
                            while (r2.length > 0) {
                              var s00 = r2[0];
                              var removed2 = false;
                              switch (s00.def) {
                                case EBinary(Match, {def: EVar(a)}, {def: EVar(bv)}) if (bv == nm):
                                  r2.shift(); removed2 = true;
                                case EMatch(PVar(a2), {def: EVar(bv2)}) if (bv2 == nm):
                                  r2.shift(); removed2 = true;
                                default:
                              }
                              if (!removed2) break;
                            }
                            makeASTWithMeta(EDo(r2), b.metadata, b.pos);
                          default:
                            b;
                        }
                      }
                      body2 = dropAlias(body2);
                      // Rename binder usages and nested case target
                      body2 = ElixirASTTransformer.transformNode(body2, function(x: ElixirAST): ElixirAST {
                        return switch (x.def) {
                          case EVar(v) if (v == nm): makeASTWithMeta(EVar(candidate), x.metadata, x.pos);
                          case ECase(tgt, cls2):
                            switch (tgt.def) {
                              case EVar(v2) if (v2 == nm): makeASTWithMeta(ECase(makeAST(EVar(candidate)), cls2), x.metadata, x.pos);
                              default: x;
                            }
                          // Repair wrong `{:noreply, nm_or_alias}` returns inside handle_info/2 only
                          case ETuple(elems):
                            if ((currentFunc == "handleInfo" || currentFunc == "handle_info") && elems.length == 2) {
                              switch (elems[0].def) {
                                case EAtom(a) if (a == ":noreply" || a == "noreply"):
                                  switch (elems[1].def) {
                                    case EVar(v3) if (v3 == nm || v3 == candidate):
                                      var sockName = socketArgName != null ? socketArgName : "socket";
                                      makeASTWithMeta(ETuple([elems[0], makeAST(EVar(sockName))]), x.metadata, x.pos);
                                    default: x;
                                  }
                                default: x;
                              }
                            } else x;
                          default: x;
                        }
                      });
                      var pattern2 = PTuple([parts[0], PVar(candidate)]);
                      newCl = { pattern: pattern2, guard: cl.guard, body: body2 };
                    default:
                  }
                default:
              }
              out.push(newCl);
            }
            makeASTWithMeta(ECase(expr, out), n.metadata, n.pos);
          default:
            n;
        }
      });
    }
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EDef(name, args, guards, body):
          currentFunc = name; socketArgName = extractSecondArgName(args);
          makeASTWithMeta(EDef(name, args, guards, transformBody(body)), n.metadata, n.pos);
        case EDefp(name, args, guards, body):
          currentFunc = name; socketArgName = extractSecondArgName(args);
          makeASTWithMeta(EDefp(name, args, guards, transformBody(body)), n.metadata, n.pos);
        default:
          currentFunc = null; socketArgName = null; n;
      }
    });
  }

  static function extractSecondArgName(args:Array<EPattern>):Null<String> {
    if (args == null || args.length < 2) return null;
    return switch (args[1]) { case PVar(nm): nm; default: null; };
  }
}

#end
