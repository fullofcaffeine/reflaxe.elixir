package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * NestedCaseTupleUnshadowTransforms
 *
 * WHAT
 * - Handles the generic shape where a case binds a variable V (possibly colliding
 *   with an existing name) and the clause body immediately performs `case V do`
 *   matching on tuple patterns `{:tag, V}`. Renames the tuple binder to `value`
 *   and, when a single undefined lower-case local exists in that inner clause body,
 *   prefix-binds it to `value`.
 *
 * WHY
 * - Prevents nested self-shadowing and repairs common “payload” tuple patterns without app coupling.
 */
class NestedCaseTupleUnshadowTransforms {
  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case ECase(outerExpr, outerClauses):
          var out:Array<ECaseClause> = [];
          for (oc in outerClauses) out.push(rewriteNested(oc));
          makeASTWithMeta(ECase(outerExpr, out), n.metadata, n.pos);
        default:
          n;
      }
    });
  }

  static function rewriteNested(oc:ECaseClause): ECaseClause {
    // Look for an inner `case innerExpr do` as the first expression in the body
    var inner: Null<{ expr:ElixirAST, clauses:Array<ECaseClause>, meta:Dynamic, pos:Dynamic, parenDepth:Int }>= null;
    function unwrapParens(e: ElixirAST): { node:ElixirAST, depth:Int, meta:Dynamic, pos:Dynamic } {
      var depth = 0; var cur = e; var m = e.metadata; var p = e.pos;
      while (true) {
        switch (cur.def) {
          case EParen(n): depth++; m = cur.metadata; p = cur.pos; cur = n;
          default: return { node: cur, depth: depth, meta: m, pos: p };
        }
      }
    }
    switch (oc.body.def) {
      case EBlock(sts) if (sts.length > 0):
        var uw = unwrapParens(sts[0]);
        switch (uw.node.def) {
          case ECase(e, cls): inner = { expr:e, clauses:cls, meta:uw.meta, pos:uw.pos, parenDepth: uw.depth };
          default:
        }
      default:
        var uwBody = unwrapParens(oc.body);
        switch (uwBody.node.def) {
          case ECase(e3, cls3): inner = { expr:e3, clauses:cls3, meta:uwBody.meta, pos:uwBody.pos, parenDepth: uwBody.depth };
          default:
        }
    }
    if (inner == null) return oc;
    // For each inner clause, if pattern is {:tag, PVar(b)} where b == printed innerExpr var name, rename b to value and optionally prefix-bind sole undefined local to value.
    var innerVar: Null<String> = switch (inner.expr.def) { case EVar(v): v; default: null; };
    if (innerVar == null) return oc;
    #if debug_ast_transformer Sys.println('[NestedCaseUnshadow] Found inner case over var: ' + innerVar); #end

    var newInnerClauses:Array<ECaseClause> = [];
    for (ic in inner.clauses) {
      var binderRenamed = false;
      var pat2 = switch (ic.pattern) {
        case PTuple(es) if (es.length == 2):
          switch (es[1]) { case PVar(n) if (n == innerVar): binderRenamed = true; PTuple([es[0], PVar("value")]); default: ic.pattern; }
        default: ic.pattern;
      };
      if (!binderRenamed) { newInnerClauses.push(ic); continue; }
      #if debug_ast_transformer Sys.println('[NestedCaseUnshadow] Renaming inner {:tag, ' + innerVar + '} -> {:tag, value}'); #end
      var declared = collectDeclared(pat2, ic.body);
      var used = collectUsed(ic.body);
      var undef:Array<String> = [];
      for (u in used.keys()) if (!declared.exists(u) && allowLocal(u)) undef.push(u);
      if (undef.length == 1) {
        var chosen = undef[0];
        #if debug_ast_transformer Sys.println('[NestedCaseUnshadow] Prefix-bind ' + chosen + ' = value'); #end
        var prefix = makeAST(EBinary(Match, makeAST(EVar(chosen)), makeAST(EVar("value"))));
        var innerBody2 = switch (ic.body.def) {
          case EBlock(sts): makeASTWithMeta(EBlock([prefix].concat(sts)), ic.body.metadata, ic.body.pos);
          case EDo(sts2): makeASTWithMeta(EDo([prefix].concat(sts2)), ic.body.metadata, ic.body.pos);
          default: makeASTWithMeta(EBlock([prefix, ic.body]), ic.body.metadata, ic.body.pos);
        };
        newInnerClauses.push({ pattern: pat2, guard: ic.guard, body: innerBody2 });
      } else {
        newInnerClauses.push({ pattern: pat2, guard: ic.guard, body: ic.body });
      }
    }

    var rebuiltInner = makeASTWithMeta(ECase(inner.expr, newInnerClauses), inner.meta, inner.pos);
    // Re-wrap parentheses to original depth
    var wrapped:ElixirAST = rebuiltInner;
    var d = inner.parenDepth;
    while (d > 0) { wrapped = makeASTWithMeta(EParen(wrapped), wrapped.metadata, wrapped.pos); d--; }
    var newBody = switch (oc.body.def) {
      case EBlock(sts) if (sts.length > 0): makeASTWithMeta(EBlock([wrapped].concat(sts.slice(1))), oc.body.metadata, oc.body.pos);
      default: wrapped;
    };
    return { pattern: oc.pattern, guard: oc.guard, body: newBody };
  }

  static function collectDeclared(p:EPattern, body:ElixirAST): Map<String,Bool> {
    var m = new Map<String,Bool>();
    function pat(pt:EPattern):Void {
      switch (pt) {
        case PVar(n): m.set(n, true);
        case PTuple(es) | PList(es): for (e in es) pat(e);
        case PCons(h,t): pat(h); pat(t);
        case PMap(kvs): for (kv in kvs) pat(kv.value);
        case PStruct(_, fs): for (f in fs) pat(f.value);
        case PPin(inner): pat(inner);
        default:
      }
    }
    pat(p);
    reflaxe.elixir.ast.ASTUtils.walk(body, function(n: ElixirAST) {
      switch (n.def) {
        case EMatch(pt, _): pat(pt);
        case EBinary(Match, {def: EVar(lhs)}, _): m.set(lhs, true);
        default:
      }
    });
    return m;
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    reflaxe.elixir.ast.ASTUtils.walk(ast, function(n: ElixirAST) {
      switch (n.def) {
        case EVar(v): names.set(v, true);
        default:
      }
    });
    return names;
  }

  static inline function allowLocal(name:String): Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c;
  }
}

#end
