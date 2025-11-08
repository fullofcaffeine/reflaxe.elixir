package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.io.Path;
import haxe.macro.PositionTools;

/**
 * TracePreserve
 *
 * WHAT
 * - Build macro applied globally (Elixir target only) that rewrites occurrences of
 *   `trace(expr)` into `Log.trace(expr, %{fileName: ..., lineNumber: ..., className: ..., methodName: ...})`.
 *
 * WHY
 * - Haxe `--no-traces` removes short-form `trace(...)` calls at typing time. Tests expect
 *   Log.trace lines with position metadata even under `-D no_traces`. By rewriting at the
 *   build-macro stage (before typing removes them), we preserve intent and generate the
 *   expected runtime calls without coupling to app code.
 *
 * HOW
 * - For each function field, map its expression and replace `ECall(CIdent("trace"), args)`
 *   with a call to `Log.trace(args[0], infosObject)` where infosObject is built from the
 *   current class name, method name, and expression position.
 */
class TracePreserve {
  public static macro function build():Array<Field> {
    // Only act for Elixir target; otherwise exit quickly
    var isElixir = (haxe.macro.Context.definedValue("target.name") == "elixir") || haxe.macro.Context.defined("elixir_output");
    if (!isElixir) return Context.getBuildFields();
    var cls = Context.getLocalClass();
    if (cls == null) return Context.getBuildFields();
    var className = cls.get().name;
    #if debug_trace_preserve
    // Build-time visibility (file log to avoid console spam)
    #if sys
    try sys.io.File.append('/tmp/trace_preserve.log', true).writeString('[TracePreserve] build for class ' + className + "\n") catch (_:Dynamic) {}
    #end
    #end

    var fields = Context.getBuildFields();
    var out:Array<Field> = [];

    for (f in fields) {
      switch (f.kind) {
        case FFun(fn):
          var methodName = f.name;
          if (fn.expr != null) {
            #if debug_trace_preserve
            #if sys
            try sys.io.File.append('/tmp/trace_preserve.log', true).writeString('[TracePreserve] scanning ' + className + '.' + methodName + "\n") catch (_:Dynamic) {}
            #end
            #end
            fn.expr = mapExpr(fn.expr, className, methodName);
          }
          out.push({
            name: f.name,
            doc: f.doc,
            meta: f.meta,
            access: f.access,
            kind: FFun(fn),
            pos: f.pos
          });
        default:
          out.push(f);
      }
    }

    return out;
  }

  static function mapExpr(e:Expr, className:String, methodName:String):Expr {
    return ExprTools.map(e, function(expr:Expr) {
      return switch (expr.expr) {
        case ECall(callee, args):
          switch (callee.expr) {
            case EConst(CIdent("trace")):
              // Build Log.trace(value, infos)
              var valueExpr = (args != null && args.length > 0) ? args[0] : macro null;
              var infos = buildInfosObject(expr.pos, className, methodName);
              var logIdent:Expr = { expr: EConst(CIdent("Log")), pos: expr.pos };
              var field:Expr = { expr: EField(logIdent, "trace"), pos: expr.pos };
              { expr: ECall(field, [valueExpr, infos]), pos: expr.pos };
            default:
              expr;
          }
        default:
          expr;
      }
    });
  }

  static function buildInfosObject(pos:Position, className:String, methodName:String):Expr {
    var file = Context.getPosInfos(pos).file;
    var fileName = Path.withoutDirectory(file);
    var line = PositionTools.toLocation(pos).range.start.line;

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
