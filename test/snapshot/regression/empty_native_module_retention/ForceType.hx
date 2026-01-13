package;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

class ForceType {
    public static macro function force(): Expr {
        // Force typing of the unreferenced module so DCE has an opportunity to eliminate it.
        Context.getType("PresenceModule");
        return macro null;
    }
}
#end
