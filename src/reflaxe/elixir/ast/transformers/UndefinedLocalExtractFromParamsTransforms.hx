package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;
import reflaxe.elixir.ast.naming.ElixirNaming;

/**
 * UndefinedLocalExtractFromParamsTransforms
 *
 * WHAT
 * - For any function that has an argument named `params` (or `_params`), synthesize
 *   bindings for undefined lower-case locals used in the body by extracting from params:
 *     var = Map.get(<paramsVar>, snake_case(var)) (with id/_id integer conversion).
 *
 * WHY
 * - Some generated handlers reference locals that come from request params but were not
 *   bound. This pass provides a generic, shape-based repair without coupling to app names.
 */
class UndefinedLocalExtractFromParamsTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EDef(name, args, guards, body):
          var paramsVar = findParamsVar(args);
          if (paramsVar == null) return node;
          var newBody = synthesize(body, paramsVar, args);
          makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
        case EDefp(name, args, guards, body):
          var paramsVarForPrivate = findParamsVar(args);
          if (paramsVarForPrivate == null) return node;
          var newBodyForPrivate = synthesize(body, paramsVarForPrivate, args);
          makeASTWithMeta(EDefp(name, args, guards, newBodyForPrivate), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function findParamsVar(args:Array<EPattern>): Null<String> {
    if (args == null || args.length == 0) return null;
    for (a in args) switch (a) {
      case PVar(n): if (n == "params" || n == "_params") return n;
      default:
    }
    return null;
  }

  static inline function toSnake(s:String):String {
    return reflaxe.elixir.ast.NameUtils.toSnakeCase(s);
  }
  static inline function isLower(s:String):Bool {
    if (s == null || s.length == 0) return false;
    var c = s.charAt(0);
    return c.toLowerCase() == c;
  }
  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "_params" || name == "event") return false;
    // Skip internal/intermediate variables that should NOT be extracted from params
    if (isInternalVariable(name)) return false;
    // Never synthesize bindings for Elixir reserved keywords (would generate invalid syntax)
    if (ElixirNaming.isReserved(name)) return false;
    return isLower(name) && name.charAt(0) != '_';
  }

  /**
   * Check if a variable name looks like an internal/intermediate variable rather than
   * a form field that should be extracted from params.
   *
   * Internal variables typically have names like:
   * - searchSocket, updatedSocket, resultSocket (socket variants)
   * - newSelected, currentlySelected (computed values)
   * - refreshedTodos, filteredItems (processed collections)
   *
   * Form fields typically have names like:
   * - id, title, description, name, email, query, tag, priority
   */
  static function isInternalVariable(name:String):Bool {
    if (name == null || name.length == 0) return false;
    var lower = name.toLowerCase();
    // Socket-related
    if (StringTools.endsWith(lower, "socket")) return true;
    // Selection/state-related
    if (StringTools.endsWith(lower, "selected")) return true;
    // Processed data
    if (StringTools.startsWith(lower, "refreshed")) return true;
    if (StringTools.startsWith(lower, "filtered")) return true;
    if (StringTools.startsWith(lower, "updated")) return true;
    if (StringTools.startsWith(lower, "new") && lower.length > 3) return true; // "newX" but not "new"
    // Result/temp variables
    if (StringTools.endsWith(lower, "result")) return true;
    if (StringTools.startsWith(lower, "temp")) return true;
    if (StringTools.startsWith(lower, "tmp")) return true;
    return false;
  }

  static function needsIntConversion(varName:String):Bool {
    return varName == "id" || StringTools.endsWith(varName, "_id");
  }

  static function buildExtract(varName:String, paramsVar:String):ElixirAST {
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramsVar)), makeAST(EString(key)) ]));
    if (!needsIntConversion(varName)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }

  static function synthesize(body: ElixirAST, paramsVar:String, args:Array<EPattern>): ElixirAST {
    var declared = new Map<String,Bool>();
    collectDecls(body, declared);
    var used = collectUsed(body);
    // avoid extracting assigns/env names
    declared.set("socket", true); declared.set("params", true); declared.set("_params", true);
    // Function arguments are in-scope bindings; never treat them as missing locals.
    if (args != null) for (a in args) collectPattern(a, declared);

    var missing:Array<String> = [];
    for (u in used.keys()) if (!declared.exists(u) && allow(u)) missing.push(u);
    if (missing.length == 0) return body;

    return switch (body.def) {
      case EBlock(stmts):
        var prefix = [for (v in missing) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtract(v, paramsVar)))];
        makeASTWithMeta(EBlock(prefix.concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2):
        var prefix2 = [for (v in missing) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtract(v, paramsVar)))];
        makeASTWithMeta(EDo(prefix2.concat(stmts2)), body.metadata, body.pos);
      default:
        var prefix3 = [for (v in missing) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtract(v, paramsVar)))];
        makeASTWithMeta(EBlock(prefix3.concat([body])), body.metadata, body.pos);
    }
  }

  static function collectDecls(ast: ElixirAST, out: Map<String,Bool>): Void {
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EMatch(p, _): collectPattern(p, out);
        case EBinary(Match, l, _): collectLhs(l, out);
        case ECase(_, cs): for (c in cs) collectPattern(c.pattern, out);
        default:
      }
    });
  }
  static function collectPattern(p: EPattern, out: Map<String,Bool>): Void {
    switch (p) {
      case PVar(n): out.set(n, true);
      case PTuple(es) | PList(es): for (e in es) collectPattern(e, out);
      case PCons(h,t): collectPattern(h, out); collectPattern(t, out);
      case PMap(kvs): for (kv in kvs) collectPattern(kv.value, out);
      case PStruct(_, fs): for (f in fs) collectPattern(f.value, out);
      case PPin(inner): collectPattern(inner, out);
      default:
    }
  }
  static function collectLhs(lhs: ElixirAST, out: Map<String,Bool>): Void {
    switch (lhs.def) { case EVar(n): out.set(n, true); case EBinary(Match, l2, _): collectLhs(l2, out); default: }
  }
  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): names.set(v, true);
        default:
      }
    });
    return names;
  }
}

#end
