package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.io.Path;
import haxe.macro.PositionTools;

/**
 * TraceEarlyRewrite
 *
 * WHAT
 * - Registers a pre-typing expression modification that rewrites short-form
 *   `trace(v)` calls into `Log.trace(v, %{file_name, line_number, class_name, method_name})`.
 *
 * WHY
 * - With `-D no_traces`, Haxe removes short-form traces during typing. Presence snapshots
 *   assert the existence of Log.trace calls with metadata even under `no_traces`.
 *   By rewriting at the expression-modifier stage (runs before typing), we preserve
 *   the call shape without touching app/generated files.
 *
 * HOW
 * - Uses reflaxe.input.ExpressionModifier.mod(callback) to register a mapper.
 *   The callback runs inside a build macro per-class and receives raw Expr trees.
 *   For any ECall(CIdent("trace"), [arg]), we build a Log.trace(arg, infos) node.
 *   File/line come from Context.getPosInfos; class from Context.getLocalClass();
 *   method from Context.getLocalMethod(). Elixir-only gating lives in CompilerInit.
 */
class TraceEarlyRewrite {
  static var registered = false;

  public static function register():Void {
    if (registered) return;
    registered = true;
    reflaxe.input.ExpressionModifier.mod(rewriteOnce);
  }

  static function rewriteOnce(e:Expr):Null<Expr> {
    switch (e.expr) {
      case ECall(callee, args):
        switch (callee.expr) {
          case EConst(CIdent("trace")):
            var valueExpr = (args != null && args.length > 0) ? args[0] : macro null;
            var infos = buildInfosObject(e.pos);
            var logIdent:Expr = { expr: EConst(CIdent("Log")), pos: e.pos };
            var field:Expr = { expr: EField(logIdent, "trace"), pos: e.pos };
            return { expr: ECall(field, [valueExpr, infos]), pos: e.pos };
          default:
        }
      default:
    }
    return null; // keep walking
  }

  static function buildInfosObject(pos:Position):Expr {
    var file = Context.getPosInfos(pos).file;
    var fileName = Path.withoutDirectory(file);
    var line = PositionTools.toLocation(pos).range.start.line;
    var cls = Context.getLocalClass();
    var className = (cls != null) ? cls.get().name : "";
    var methodName = Context.getLocalMethod();
    if (methodName == null) methodName = "";
    var fields:Array<ObjectField> = [
      { field: "file_name", expr: macro $v{fileName} },
      { field: "line_number", expr: macro $v{line} },
      { field: "class_name", expr: macro $v{className} },
      { field: "method_name", expr: macro $v{methodName} }
    ];
    return { expr: EObjectDecl(fields), pos: pos };
  }
}

#end
