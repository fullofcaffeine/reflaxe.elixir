package;

#if macro
import haxe.io.Path;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.io.File;
#end

/** Reads a project-owned external file and declares the dependency to Haxe. */
class ExternalValueMacro {
	public static macro function read():ExprOf<String> {
		final path = Path.join([Sys.getCwd(), "config", "external-value.txt"]);
		Context.registerModuleDependency(Context.getLocalModule(), path);
		return macro $v{StringTools.trim(File.getContent(path))};
	}
}
