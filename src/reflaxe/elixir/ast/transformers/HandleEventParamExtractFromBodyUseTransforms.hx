package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ASTUtils;

/**
 * HandleEventParamExtractFromBodyUseTransforms
 *
 * WHAT
 * - For LiveView handle_event/3 clauses, synthesize parameter extraction statements for
 *   undefined local variables used in the body:
 *     var = Map.get(params, snake_case(var)) with id/_id integer conversion when binary.
 *
 * WHY
 * - Ensures handlers that reference body locals (id, sortBy, priority, query, tag, etc.)
 *   bind them from `params` without relying on app-specific tag heuristics.
 *
 * HOW
 * - Match def handle_event(<string>, params, socket) do ... end. Compute `declared` names
 *   from pattern/LHS inside body, collect `used` simple locals, then:
 *     undefined = used − declared − {params, socket}
 *   For each undefined name n, prepend: n = extract(n).
 * - Runs late so it sees near-final body shapes and avoids being undone by later passes.

 *
 * EXAMPLES
 * - Covered by snapshot tests under `test/snapshot/**`.
 */
class HandleEventParamExtractFromBodyUseTransforms {
  public static function transformPass(ast: ElixirAST): ElixirAST {
    return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
      return switch (node.def) {
        case EModule(name, attrs, body):
          var out:Array<ElixirAST> = [];
          for (s in body) out.push(transformPass(s));
          makeASTWithMeta(EModule(name, attrs, out), node.metadata, node.pos);
        case EDefmodule(modName, doBlock):
          var stmts = switch (doBlock.def) { case EDo(s): s; case EBlock(s2): s2; default: [];} ;
          var out2:Array<ElixirAST> = [];
          for (s in stmts) out2.push(transformPass(s));
          makeASTWithMeta(EDefmodule(modName, makeAST(EBlock(out2))), node.metadata, node.pos);
        case EDef(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar = extractParamsVarName(args);
          var newBody = synthesizeExtractsWithParam(body, paramVar);
          makeASTWithMeta(EDef(name, args, guards, newBody), node.metadata, node.pos);
        case EDefp(name, args, guards, body) if (isHandleEvent3(name, args)):
          var paramVar2 = extractParamsVarName(args);
          var newBody2 = synthesizeExtractsWithParam(body, paramVar2);
          makeASTWithMeta(EDefp(name, args, guards, newBody2), node.metadata, node.pos);
        default:
          node;
      }
    });
  }

  static function isHandleEvent3(name:String, args:Array<EPattern>):Bool {
    if (name != "handle_event" || args == null || args.length != 3) return false;
    // Arg guard: first is string literal, second is params, third is socket
    return switch (args[0]) {
      case PLiteral({def: EString(_)}): true;
      default: false;
    }
  }

  static function toSnake(name:String):String {
    return reflaxe.elixir.ast.NameUtils.toSnakeCase(name);
  }

  static inline function needsIntConversion(varName:String):Bool {
    return varName == "id" || StringTools.endsWith(varName, "_id");
  }

  static function buildExtractWithParam(varName:String, paramVar:String):ElixirAST {
    if (varName == "params") return makeAST(EVar(paramVar));
    var key = toSnake(varName);
    var get = makeAST(ERemoteCall(makeAST(EVar("Map")), "get", [ makeAST(EVar(paramVar)), makeAST(EString(key)) ]));
    if (!needsIntConversion(varName)) return get;
    var isBin = makeAST(ERemoteCall(makeAST(EVar("Kernel")), "is_binary", [ get ]));
    var toInt = makeAST(ERemoteCall(makeAST(EVar("String")), "to_integer", [ get ]));
    return makeAST(EIf(isBin, toInt, get));
  }

  static function extractParamsVarName(args:Array<EPattern>):String {
    if (args == null || args.length < 2) return "params";
    return switch (args[1]) { case PVar(n): n; default: "params"; }
  }

  static function synthesizeExtractsWithParam(body: ElixirAST, paramVar:String): ElixirAST {
    // Compute declared/used inside the body
    var declared = new Map<String,Bool>();
    collectDecls(body, declared);
    var used = collectUsed(body);
    // Remove reserved env vars
    declared.set("params", true);
    declared.set("socket", true);

    var undef:Array<String> = [];
    for (u in used.keys()) if (!declared.exists(u) && allow(u)) undef.push(u);
    if (undef.length == 0) return body;

    // Prepend extraction matches to the body block
    return switch (body.def) {
      case EBlock(stmts):
        var prefix = [for (v in undef) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtractWithParam(v, paramVar)))];
        makeASTWithMeta(EBlock(prefix.concat(stmts)), body.metadata, body.pos);
      case EDo(stmts2):
        var prefix2 = [for (v in undef) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtractWithParam(v, paramVar)))];
        makeASTWithMeta(EDo(prefix2.concat(stmts2)), body.metadata, body.pos);
      default:
        // Wrap single expression into a block
        var prefix3 = [for (v in undef) makeAST(EBinary(Match, makeAST(EVar(v)), buildExtractWithParam(v, paramVar)))];
        makeASTWithMeta(EBlock(prefix3.concat([body])), body.metadata, body.pos);
    }
  }

  static inline function allow(name:String):Bool {
    if (name == null || name.length == 0) return false;
    if (name == "socket" || name == "params" || name == "event" || name == "live_socket") return false;
    // Skip internal/intermediate variables that should NOT be extracted from params
    if (isInternalVariable(name)) return false;
    var c = name.charAt(0);
    return c.toLowerCase() == c && c != '_';
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
    switch (lhs.def) {
      case EVar(n): out.set(n, true);
      case EBinary(Match, l2, _): collectLhs(l2, out);
      default:
    }
  }

  static function collectUsed(ast: ElixirAST): Map<String,Bool> {
    var names = new Map<String,Bool>();
    ASTUtils.walk(ast, function(n: ElixirAST) {
      if (n == null || n.def == null) return;
      switch (n.def) {
        case EVar(v): names.set(v, true);
        case ERaw(code):
          try {
            if (code != null) {
              var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "g");
              var pos = 0;
              while (tok.matchSub(code, pos)) {
                var id = tok.matched(0);
                if (allow(id)) names.set(id, true);
                pos = tok.matchedPos().pos + tok.matchedPos().len;
              }
            }
          } catch (e) {}
        case EString(s):
          // Capture identifiers used in string interpolation (e.g., "id=\#{id}")
          try {
            var block = new EReg("\\#\\{([^}]*)\\}", "g");
            var pos = 0;
            while (block.matchSub(s, pos)) {
              var inner = block.matched(1);
              var tok = new EReg("[A-Za-z_][A-Za-z0-9_]*", "gi");
              var tpos = 0;
              while (tok.matchSub(inner, tpos)) {
                var id = tok.matched(0);
                if (allow(id)) names.set(id, true);
                tpos = tok.matchedPos().pos + tok.matchedPos().len;
              }
              pos = block.matchedPos().pos + block.matchedPos().len;
            }
          } catch (e) {}
        default:
      }
    });
    return names;
  }
}

#end
