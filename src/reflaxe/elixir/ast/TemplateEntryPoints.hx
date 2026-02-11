package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)

import haxe.macro.Type.ClassType;
import reflaxe.elixir.ast.ElixirAST;

/**
 * TemplateEntryPoints
 *
 * WHAT
 * - Central place to recognize "template producer" call shapes that are intercepted by the AST
 *   pipeline and lowered into Phoenix `~H` sigils.
 *
 * WHY
 * - Several builder/transformer passes need to detect these calls. Keeping the logic in one
 *   module avoids duplicated conditionals and keeps future additions (new entrypoints) safe.
 *
 * HOW
 * - Provides two detection layers:
 *   - Typed AST static-call detection (`ClassType` + method)
 *   - ElixirAST call detection (`ECall(mod, fn, ...)`)
 */
class TemplateEntryPoints {
    public static function isHxxStaticCall(cls: ClassType, methodName: String): Bool {
        return cls != null && cls.name == "HXX" && methodName == "hxx";
    }

    public static function isHeexTemplateRootStaticCall(cls: ClassType, methodName: String): Bool {
        if (cls == null) return false;
        if (methodName != "root" && methodName != "root_ast") return false;
        if (cls.pack == null) return false;
        if (cls.pack.join(".") != "phoenix.hxx") return false;
        return cls.name == "HeexTemplate" || cls.name == "HXX2" || cls.name == "H";
    }

    public static function isTemplateProducerStaticCall(cls: ClassType, methodName: String): Bool {
        return isHxxStaticCall(cls, methodName) || isHeexTemplateRootStaticCall(cls, methodName);
    }

    public static function isTemplateProducerCall(mod: Null<ElixirAST>, fnName: String): Bool {
        if (fnName == null) return false;
        if (mod == null) return false;

        function isNamedModule(m: String, expectedSuffix: String): Bool {
            if (m == expectedSuffix) return true;
            return StringTools.endsWith(m, "." + expectedSuffix);
        }

        return switch (mod.def) {
            case EVar(m):
                (fnName == "hxx" && isNamedModule(m, "HXX"))
                    || ((fnName == "root" || fnName == "root_ast") && (isNamedModule(m, "HeexTemplate") || isNamedModule(m, "HXX2") || isNamedModule(m, "H")));
            case EField(_, fld):
                (fnName == "hxx" && fld == "HXX")
                    || ((fnName == "root" || fnName == "root_ast") && (fld == "HeexTemplate" || fld == "HXX2" || fld == "H"));
            default:
                false;
        }
    }
}

#end
