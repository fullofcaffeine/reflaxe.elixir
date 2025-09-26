#if macro
import haxe.macro.Context;
import haxe.macro.Type;

class DebugMapMacro {
    public static function init() {
        Context.onAfterTyping(function(types) {
            for (mt in types) {
                switch(mt) {
                    case TClassDecl(c) if (c.get().name == "DebugMapIter"):
                        var cl = c.get();
                        for (f in cl.statics.get()) {
                            if (f.name == "main") {
                                switch(f.expr().expr) {
                                    case TFunction(func):
                                        trace("=== ANALYZING MAP ITERATION DESUGARING ===");
                                        dumpExpr(func.expr, 0);
                                    case _:
                                }
                            }
                        }
                    case _:
                }
            }
        });
    }
    
    static function dumpExpr(e: TypedExpr, indent: Int, ?label: String = "") {
        if (e == null) return;
        var prefix = [for (i in 0...indent) "  "].join("");
        var labelStr = label != "" ? label + ": " : "";
        
        switch(e.expr) {
            case TBlock(exprs):
                trace(prefix + labelStr + "TBlock [" + exprs.length + " expressions]");
                for (i in 0...exprs.length) {
                    dumpExpr(exprs[i], indent + 1, "expr[" + i + "]");
                }
                
            case TVar(v, init):
                trace(prefix + labelStr + "TVar(" + v.name + ")" + (init != null ? " with init" : ""));
                if (init != null) dumpExpr(init, indent + 1, "init");
                
            case TWhile(cond, body, normal):
                trace(prefix + labelStr + "TWhile (normalWhile=" + normal + ")");
                dumpExpr(cond, indent + 1, "condition");
                dumpExpr(body, indent + 1, "body");
                
            case TLocal(v):
                trace(prefix + labelStr + "TLocal(" + v.name + ")");
                
            case TField(e, fa):
                var fname = getFieldName(fa);
                trace(prefix + labelStr + "TField(." + fname + ")");
                dumpExpr(e, indent + 1, "object");
                
            case TCall(e, args):
                trace(prefix + labelStr + "TCall with " + args.length + " args");
                dumpExpr(e, indent + 1, "function");
                for (i in 0...args.length) {
                    dumpExpr(args[i], indent + 1, "arg[" + i + "]");
                }
                
            case TIf(econd, eif, eelse):
                trace(prefix + labelStr + "TIf");
                dumpExpr(econd, indent + 1, "condition");
                dumpExpr(eif, indent + 1, "then");
                if (eelse != null) dumpExpr(eelse, indent + 1, "else");
                
            case TBinop(op, e1, e2):
                trace(prefix + labelStr + "TBinop(" + op + ")");
                dumpExpr(e1, indent + 1, "left");
                dumpExpr(e2, indent + 1, "right");
                
            case TConst(c):
                trace(prefix + labelStr + "TConst(" + constToString(c) + ")");
                
            case TBreak:
                trace(prefix + labelStr + "TBreak");
                
            case _:
                trace(prefix + labelStr + Type.enumConstructor(e.expr));
        }
    }
    
    static function getFieldName(fa: FieldAccess): String {
        return switch(fa) {
            case FInstance(_, _, cf): cf.get().name;
            case FStatic(_, cf): cf.get().name;
            case FAnon(cf): cf.get().name;
            case FClosure(_, cf): cf.get().name;
            case FEnum(_, ef): ef.name;
            case FDynamic(s): s;
        }
    }
    
    static function constToString(c: TConstant): String {
        return switch(c) {
            case TInt(i): Std.string(i);
            case TFloat(f): f;
            case TString(s): '"' + s + '"';
            case TBool(b): Std.string(b);
            case TNull: "null";
            case TThis: "this";
            case TSuper: "super";
        }
    }
}
#end