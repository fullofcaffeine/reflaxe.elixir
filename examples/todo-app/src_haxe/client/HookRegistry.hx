package client;

import client.extern.PhoenixHook;
import haxe.DynamicAccess;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
#end

/**
 * HookRegistry
 *
 * WHAT
 * - Compile-time checked builder for the Phoenix LiveView Hooks map.
 *
 * WHY
 * - Prevent drift between:
 *   - server templates using `phx-hook=${HookName.*}`
 *   - client `window.Hooks` map providing the implementations
 *
 * HOW
 * - Use `HookRegistry.build({ ... })` with an object literal whose keys are HookName *field names*
 *   (e.g. `AutoFocus`, `ThemeToggle`). The macro:
 *   - errors on unknown keys
 *   - errors if any HookName entries are missing
 *   - emits a `DynamicAccess<PhoenixHook>` keyed by the HookName *string values*
 */
class HookRegistry {
  public static macro function build(defs: Expr): ExprOf<DynamicAccess<PhoenixHook>> {
    var pos = defs.pos;

    var provided: Map<String, Expr> = new Map();
    var providedOrder: Array<String> = [];

    switch (defs.expr) {
      case EObjectDecl(fields):
        for (f in fields) {
          if (f == null || f.field == null) continue;
          if (provided.exists(f.field)) {
            Context.error('Duplicate hook key "' + f.field + '" in HookRegistry.build(...)', pos);
          }
          provided.set(f.field, f.expr);
          providedOrder.push(f.field);
        }
      default:
        Context.error("HookRegistry.build(...) expects an object literal", pos);
    }

    var declared = collectHookNameConstants(pos);
    if (declared.length == 0) {
      Context.error("HookRegistry.build(...) could not discover any HookName constants", pos);
    }

    var declaredByName: Map<String, String> = new Map();
    for (d in declared) declaredByName.set(d.name, d.value);

    for (k in provided.keys()) {
      if (!declaredByName.exists(k)) {
        Context.error('Unknown HookName "' + k + '" in HookRegistry.build(...)', pos);
      }
    }

    var missing: Array<String> = [];
    for (d in declared) {
      if (!provided.exists(d.name)) missing.push(d.name);
    }

    if (missing.length > 0) {
      Context.error(
        "Missing hook implementations for HookName: " + missing.join(", ") + " (add them to HookRegistry.build(...))",
        pos
      );
    }

    var statements: Array<Expr> = [];
    statements.push(macro var hooks: DynamicAccess<PhoenixHook> = {});

    // Stable emission order: preserve HookName declaration order
    for (d in declared) {
      var valueExpr = provided.get(d.name);
      statements.push(macro hooks[$v{d.value}] = $valueExpr);
    }

    statements.push(macro hooks);
    return macro { $b{statements}; };
  }

  #if macro
  static function collectHookNameConstants(pos: Position): Array<{ name: String, value: String }> {
    var out: Array<{ name: String, value: String }> = [];

    var t = Context.getType("shared.liveview.HookName");

    switch (TypeTools.follow(t)) {
      case TAbstract(absRef, _):
        var abs = absRef.get();
        if (abs == null || abs.impl == null) return out;
        var impl = abs.impl.get();
        if (impl == null) return out;

        for (f in impl.statics.get()) {
          if (f == null || f.name == null) continue;

          switch (f.kind) {
            case FVar(_, _):
            default:
              continue;
          }

          var e = f.expr();
          if (e == null) continue;

          var s = extractConstString(e);
          if (s == null) {
            Context.error("HookName constant " + f.name + " must be a string literal", pos);
          }

          out.push({name: f.name, value: s});
        }
      default:
        Context.error("HookName must be an enum abstract of String", pos);
    }

    return out;
  }

  static function extractConstString(e: TypedExpr): Null<String> {
    if (e == null) return null;
    return switch (e.expr) {
      case TConst(TString(s)):
        s;
      case TParenthesis(inner):
        extractConstString(inner);
      case TCast(inner, _):
        extractConstString(inner);
      case TMeta(_, inner):
        extractConstString(inner);
      default:
        null;
    }
  }
  #end
}
