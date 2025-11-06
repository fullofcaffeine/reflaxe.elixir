package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;

/**
 * PromoteUnderscoreAssignToUniqueUndeclaredTransforms
 *
 * WHAT
 * - Promotes `_ = rhs` to `name = rhs` when there is exactly one undeclared
 *   simple variable `name` referenced in a small forward window of statements.
 *
 * WHY
 * - Late hygiene may discard a binder needed by later statements (e.g., `first3`,
 *   `skip2`). If exactly one undeclared var is used soon after, we can safely
 *   restore the binder without relying on app-specific naming.
 *
 * HOW
 * - For each EBlock/EDo: scan statements; when encountering `_ = rhs`, look ahead
 *   up to `WINDOW` statements and collect simple variable references not yet declared.
 *   If there is exactly one candidate and it is not declared before the window ends,
 *   rewrite the assignment to bind that candidate.
 *
 * SAFETY
 * - Usage-driven (unique undeclared reference); no app coupling or heuristics.
 */
class PromoteUnderscoreAssignToUniqueUndeclaredTransforms {
  static inline var WINDOW:Int = 1;

  public static function pass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(n: ElixirAST): ElixirAST {
      return switch (n.def) {
        case EBlock(stmts): makeASTWithMeta(EBlock(process(stmts)), n.metadata, n.pos);
        case EDo(stmts2): makeASTWithMeta(EDo(process(stmts2)), n.metadata, n.pos);
        default: n;
      }
    });
  }

  static function process(stmts:Array<ElixirAST>): Array<ElixirAST> {
    if (stmts == null) return stmts;
    var declared = new Map<String,Bool>();
    inline function addDeclFromStmt(s:ElixirAST):Void {
      switch (s.def) {
        case EMatch(p, _):
          collectPatternDecls(p, declared);
        case EBinary(Match, left, _):
          switch (left.def) { case EVar(n): if (isIdent(n)) declared.set(n, true); default: }
        default:
      }
    }
    // seed declarations from statements seen so far
    var out:Array<ElixirAST> = [];
    for (i in 0...stmts.length) {
      var s = stmts[i];
      var rewritten = s;
      switch (s.def) {
        case EBinary(Match, left, rhs):
          var isWild = switch (left.def) {
            case EVar(v) if (v == "_"): true;
            default: false;
          };
          if (isWild) {
            var cand = findUniqueUndeclaredCandidate(stmts, i+1, declared, WINDOW);
            if (cand != null) {
              rewritten = makeASTWithMeta(EBinary(Match, makeAST( EVar(cand) ), rhs), s.metadata, s.pos);
              declared.set(cand, true);
            }
          }
        case EMatch(PVar("_"), rhs2):
          var cand2 = findUniqueUndeclaredCandidate(stmts, i+1, declared, WINDOW);
          if (cand2 != null) {
            rewritten = makeASTWithMeta(EMatch(PVar(cand2), rhs2), s.metadata, s.pos);
            declared.set(cand2, true);
          }
        default:
      }
      out.push(rewritten);
      addDeclFromStmt(rewritten);
    }
    return out;
  }

  static function findUniqueUndeclaredCandidate(stmts:Array<ElixirAST>, from:Int, declared:Map<String,Bool>, window:Int): Null<String> {
    var refs = new Map<String,Int>();
    inline function bump(name:String):Void {
      if (!isIdent(name) || declared.exists(name)) return;
      refs.set(name, (refs.exists(name) ? (refs.get(name) + 1) : 1));
    }
    inline function scanTokens(src:String):Void {
      if (src == null || src.indexOf("#{") < 0) return;
      var re = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
      var pos = 0;
      while (re.matchSub(src, pos)) {
        bump(re.matched(0));
        var m = re.matchedPos(); pos = m.pos + m.len;
      }
    }
    function walk(n:ElixirAST):Void {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): bump(v);
        case EString(s): scanTokens(s);
        case ERaw(code): scanTokens(code);
        case EBlock(ss): for (e in ss) walk(e);
        case EDo(ss2): for (e in ss2) walk(e);
        case EBinary(_, l, r): walk(l); walk(r);
        case EMatch(_, rhs): walk(rhs);
        case EIf(c,t,e): walk(c); walk(t); if (e != null) walk(e);
        case ECase(expr, cs): walk(expr); for (c in cs) walk(c.body);
        case ECall(t,_,args): if (t != null) walk(t); for (a in args) walk(a);
        case ERemoteCall(t2,_,args2): walk(t2); for (a in args2) walk(a);
        default:
      }
    }
    var upper = Std.int(Math.min(stmts.length, from + window));
    for (j in from...upper) walk(stmts[j]);
    var names:Array<String> = [];
    for (k in refs.keys()) names.push(k);
    return names.length == 1 ? names[0] : null;
  }

  static function collectPatternDecls(p:EPattern, declared:Map<String,Bool>):Void {
    switch (p) {
      case PVar(n): if (isIdent(n)) declared.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPatternDecls(e, declared);
      case PCons(h,t): collectPatternDecls(h, declared); collectPatternDecls(t, declared);
      case PMap(kvs): for (kv in kvs) collectPatternDecls(kv.value, declared);
      case PStruct(_, fs): for (f in fs) collectPatternDecls(f.value, declared);
      case PPin(inner): collectPatternDecls(inner, declared);
      default:
    }
  }

  static inline function isIdent(name:String):Bool {
    if (name == null || name.length == 0) return false;
    var c0 = name.charAt(0);
    if (c0 == '_' || c0.toLowerCase() != c0) return false;
    // Exclude Elixir/Haxe reserved words and common DSL tokens
    var reserved = [
      'fn','end','do','else','case','cond','receive','after','rescue','catch','when',
      'true','false','nil','inspect'
    ];
    return reserved.indexOf(name) == -1;
  }
}

#end
